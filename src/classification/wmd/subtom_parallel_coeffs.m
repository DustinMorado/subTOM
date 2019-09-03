function subtom_parallel_coeffs(varargin)
% SUBTOM_PARALLEL_COEFFS computes wedge-masked difference coefficients.
%
%     SUBTOM_PARALLEL_COEFFS(
%         'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX,
%         'dmatrix_fn_prefix', DMATRIX_FN_PREFIX,
%         'ptcl_fn_prefix', PTCL_FN_PREFIX,
%         'ref_fn_prefix',REF_FN_PREFIX,
%         'coeff_fn_prefix', COEFF_FN_PREFIX,
%         'eig_val_fn_prefix', EIG_VAL_FN_PREFIX,
%         'eig_vol_fn_prefix', EIG_VOL_FN_PREFIX,
%         'weight_fn_prefix', WEIGHT_FN_PREFIX,
%         'mask_fn', MASK_FN,
%         'high_pass_fp', HIGH_PASS_FP,
%         'high_pass_sigma', HIGH_PASS_SIGMA,
%         'low_pass_fp', LOW_PASS_FP,
%         'low_pass_sigma', LOW_PASS_SIGMA,
%         'nfold', NFOLD,
%         'prealigned', PREALIGNED,
%         'iteration', ITERATION,
%         'tomo_row', TOMO_ROW,
%         'num_coeff_batch', NUM_COEFF_BATCH,
%         'process_idx', PROCESS_IDX)
%
%     Takes a batch subset of particles described by ALL_MOTL_FN_PREFIX with
%     filenames given by PTCL_FN_PREFIX, band-pass filters them as specified by
%     HIGH_PASS_FP, HIGH_PASS_SIGMA, LOW_PASS_FP, and LOW_PASS_SIGMA, optionally
%     applies NFOLD C-symmetry and calculates their wedge-masked difference with
%     the reference described by REF_FN_PREFIX and WEIGHT_FN_PREFIX and then
%     projects the difference onto the Eigenvolumes specified by
%     EIG_VOL_FN_PREFIX. This determines a set of coefficients describing a
%     low-rank approximation of the data. A subset of this coefficient matrix is
%     written out based on COEFF_FN_PREFIX and PROCESS_IDX, with there being
%     NUM_COEFF_BATCH batches in total.
%
%     References will be reweighted using the correct weight of each particle as
%     described by WEIGHT_FN_PREFIX and TOMO_ROW. If PREALIGNED is set to 1,
%     then it is understood that the particles have been prealigned beforehand
%     and the alignment of the particles can be skipped to save time.  MASK_FN
%     describes the mask used throughout classification and 'NONE' describes a
%     default spherical mask.

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'all_motl_fn_prefix', 'combinedmotl/allmotl');
    addParameter(fn_parser, 'dmatrix_fn_prefix', 'class/dmatrix_wmd');
    addParameter(fn_parser, 'ptcl_fn_prefix', 'subtomograms/subtomo');
    addParameter(fn_parser, 'ref_fn_prefix', 'ref/ref');
    addParameter(fn_parser, 'coeff_fn_prefix', 'class/coeff_wmd');
    addParameter(fn_parser, 'eig_val_fn_prefix', 'class/eigval_wmd');
    addParameter(fn_parser, 'eig_vol_fn_prefix', 'class/eigvol_wmd');
    addParameter(fn_parser, 'weight_fn_prefix', 'otherinputs/ampspec');
    addParameter(fn_parser, 'mask_fn', 'none');
    addParameter(fn_parser, 'high_pass_fp', 0);
    addParameter(fn_parser, 'high_pass_sigma', 0);
    addParameter(fn_parser, 'low_pass_fp', 0);
    addParameter(fn_parser, 'low_pass_sigma', 0);
    addParameter(fn_parser, 'nfold', 1);
    addParameter(fn_parser, 'prealigned', '0');
    addParameter(fn_parser, 'iteration', 1);
    addParameter(fn_parser, 'tomo_row', 7);
    addParameter(fn_parser, 'num_coeff_batch', 1);
    addParameter(fn_parser, 'process_idx', 1);
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    all_motl_fn_prefix = fn_parser.Results.all_motl_fn_prefix;
    [all_motl_dir, ~, ~] = fileparts(all_motl_fn_prefix);

    if ~isempty(all_motl_dir) && exist(all_motl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_coeffs:all_motl_dir: Directory %s %s.', ...
                all_motl_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    dmatrix_fn_prefix = fn_parser.Results.dmatrix_fn_prefix;
    [dmatrix_dir, ~, ~] = fileparts(dmatrix_fn_prefix);

    if ~isempty(dmatrix_dir) && exist(dmatrix_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_coeffs:dmatrix_dir: Directory %s %s.', ...
                dmatrix_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    ptcl_fn_prefix = fn_parser.Results.ptcl_fn_prefix;
    [ptcl_dir, ~, ~] = fileparts(ptcl_fn_prefix);

    if ~isempty(ptcl_dir) && exist(ptcl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_coeffs:ptcl_dir: Directory %s %s.', ...
                ptcl_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    ref_fn_prefix = fn_parser.Results.ref_fn_prefix;
    [ref_dir, ~, ~] = fileparts(ref_fn_prefix);

    if ~isempty(ref_dir) && exist(ref_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_coeffs:ref_dir: Directory %s %s.', ...
                ref_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    coeff_fn_prefix = fn_parser.Results.coeff_fn_prefix;
    [coeff_dir, ~, ~] = fileparts(coeff_fn_prefix);

    if ~isempty(coeff_dir) && exist(coeff_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_coeffs:coeff_dir: Directory %s %s.', ...
                coeff_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    eig_val_fn_prefix = fn_parser.Results.eig_val_fn_prefix;
    [eig_val_dir, ~, ~] = fileparts(eig_val_fn_prefix);

    if ~isempty(eig_val_dir) && exist(eig_val_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_coeffs:eig_val_dir: Directory %s %s.', ...
                eig_val_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    eig_vol_fn_prefix = fn_parser.Results.eig_vol_fn_prefix;
    [eig_vol_dir, ~, ~] = fileparts(eig_vol_fn_prefix);

    if ~isempty(eig_vol_dir) && exist(eig_vol_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_coeffs:eig_vol_dir: Directory %s %s.', ...
                eig_vol_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    weight_fn_prefix = fn_parser.Results.weight_fn_prefix;
    [weight_dir, ~, ~] = fileparts(weight_fn_prefix);

    if ~isempty(weight_dir) && exist(weight_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_coeffs:weight_dir: Directory %s %s.', ...
                weight_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    mask_fn = fn_parser.Results.mask_fn;

    if ~strcmp(mask_fn, 'none') && exist(mask_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_coeffs:File %s does not exist.', mask_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    high_pass_fp = fn_parser.Results.high_pass_fp;

    if ischar(high_pass_fp)
        high_pass_fp = str2double(high_pass_fp);
    end

    try
        validateattributes(high_pass_fp, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_parallel_coeffs', 'high_pass_fp');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    high_pass_sigma = fn_parser.Results.high_pass_sigma;

    if ischar(high_pass_sigma)
        high_pass_sigma = str2double(high_pass_sigma);
    end

    try
        validateattributes(high_pass_sigma, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_parallel_coeffs', 'high_pass_sigma');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    low_pass_fp = fn_parser.Results.low_pass_fp;

    if ischar(low_pass_fp)
        low_pass_fp = str2double(low_pass_fp);
    end

    try
        validateattributes(low_pass_fp, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_parallel_coeffs', 'low_pass_fp');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    low_pass_sigma = fn_parser.Results.low_pass_sigma;

    if ischar(low_pass_sigma)
        low_pass_sigma = str2double(low_pass_sigma);
    end

    try
        validateattributes(low_pass_sigma, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_parallel_coeffs', 'low_pass_sigma');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    nfold = fn_parser.Results.nfold;

    if ischar(nfold)
        nfold = str2double(nfold);
    end

    try
        validateattributes(nfold, {'numeric'}, ...
            {'scalar', 'nonnan', 'positive', 'integer'}, ...
            'subtom_parallel_coeffs', 'nfold');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    prealigned = fn_parser.Results.prealigned;

    if ischar(prealigned)
        prealigned = str2double(prealigned);
    end

    try
        validateattributes(prealigned, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_parallel_coeffs', 'prealigned');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    iteration = fn_parser.Results.iteration;

    if ischar(iteration)
        iteration = str2double(iteration);
    end

    try
        validateattributes(iteration, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer'}, ...
            'subtom_parallel_coeffs', 'iteration');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    tomo_row = fn_parser.Results.tomo_row;

    if ischar(tomo_row)
        tomo_row = str2double(tomo_row);
    end

    try
        validateattributes(tomo_row, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0, '<', 21}, ...
            'subtom_parallel_coeffs', 'tomo_row');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    num_coeff_batch = fn_parser.Results.num_coeff_batch;

    if ischar(num_coeff_batch)
        num_coeff_batch = str2double(num_coeff_batch);
    end

    try
        validateattributes(num_coeff_batch, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0}, ...
            'subtom_parallel_coeffs', 'num_coeff_batch');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    process_idx = fn_parser.Results.process_idx;

    if ischar(process_idx)
        process_idx = str2double(process_idx);
    end

    try
        validateattributes(process_idx, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0, ...
            '<=', num_coeff_batch}, ...
            'subtom_parallel_coeffs', 'process_idx');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Check if the calculation has already been done and skip if so.
    coeff_fn = sprintf('%s_%d.em', coeff_fn_prefix, iteration);

    if exist(coeff_fn, 'file') == 2
        warning('subTOM:recoverOnFail', ...
            'parallel_coeffs:File %s already exists. SKIPPING!', ...
            coeff_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Check if the calculation has already been done and skip if so.
    coeff_fn = sprintf('%s_%d_%d.em', coeff_fn_prefix, iteration, ...
        process_idx);

    if exist(coeff_fn, 'file') == 2
        warning('subTOM:recoverOnFail', ...
            'parallel_coeffs:File %s already exists. SKIPPING!', ...
            coeff_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Read in all_motl file
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(all_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_coeffs:File %s does not exist.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl = getfield(tom_emread(all_motl_fn), 'Value');

    if size(all_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'parallel_coeffs:%s is not proper MOTL.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    num_ptcls = size(all_motl, 2);
    coeff_batch_size = floor(num_ptcls / num_coeff_batch);

    if process_idx > (num_ptcls - (coeff_batch_size * num_coeff_batch))
        ptcl_start_idx = (process_idx - 1) * coeff_batch_size + 1 + ...
            (num_ptcls - (coeff_batch_size * num_coeff_batch));

        ptcl_end_idx = ptcl_start_idx + coeff_batch_size - 1;
    else
        ptcl_start_idx = (process_idx - 1) * (coeff_batch_size + 1) + 1;
        ptcl_end_idx = ptcl_start_idx + coeff_batch_size;
    end
    
    batch_size = ptcl_end_idx - ptcl_start_idx + 1;

    % Get box size from first subtomogram
    if ~prealigned
        check_fn = sprintf('%s_%d.em', ptcl_fn_prefix, ...
            all_motl(4, ptcl_start_idx));
    else
        check_fn = sprintf('%s_%d_%d.em', ptcl_fn_prefix, iteration, ...
            all_motl(4, ptcl_start_idx));
    end

    if exist(check_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_coeffs:File %s does not exist.', check_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Note the transpose, tom_reademheader returns a column vector, but Matlab
    % size function returns a row vector, and ones and zeros need row vector
    box_size = getfield(tom_reademheader(check_fn), 'Header', 'Size')';

    % Create a ones volume thats used a bit
    ones_vol = ones(box_size);

    % Read in the reference
    ref_fn = sprintf('%s_%d.em', ref_fn_prefix, iteration);

    if exist(ref_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_coeffs:File %s does not exist.', ref_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    ref = getfield(tom_emread(ref_fn), 'Value');

    if ~all(size(ref) == box_size)
        try
            error('subTOM:volDimError', ...
                'parallel_coeffs:%s and %s are not same size.', ...
                ref_fn, check_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end
        
    % Read in classification mask
    if ~strcmpi(mask_fn, 'none')
        if exist(mask_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'parallel_coeffs:File %s does not exist.', mask_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        mask = getfield(tom_emread(mask_fn), 'Value');

        if ~all(size(mask) == box_size)
            try
                error('subTOM:volDimError', ...
                    'parallel_coeffs:%s and %s are not same size.', ...
                    mask_fn, check_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end
    else

        % If no mask specified use a hard-coded spherical mask
        mask = tom_spheremask(ones_vol, floor(box_size(1) * 0.4));
    end

    % Find the indices and  the number of voxels in the mask. The mask should be
    % all ones but in case it isn't we threshold it at 1e-6
    mask_idxs = mask > 1e-6;
    num_mask_vox = sum(mask_idxs(:));

    % Read in the D-Matrix mean which we subtract from the particle before
    % projection corresponding to column-centering if the particle was in the
    % D-Matrix.
    dmatrix_mean_fn = sprintf('%s_mean_%d.em', dmatrix_fn_prefix, iteration);

    if exist(dmatrix_mean_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_coeffs:File %s does not exist.', ...
                dmatrix_mean_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    dmatrix_mean = getfield(tom_emread(dmatrix_mean_fn), 'Value');

    if ~all(size(dmatrix_mean) == box_size)
        try
            error('subTOM:volDimError', ...
                'parallel_coeffs:%s and %s are not same size.', ...
                dmatrix_mean_fn, check_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Calculate band-pass mask
    if low_pass_fp > 0
        low_pass_mask = tom_spheremask(ones_vol, low_pass_fp, ...
            low_pass_sigma);
    else
        low_pass_mask = ones_vol;
    end

    if high_pass_fp > 0
        high_pass_mask = tom_spheremask(ones_vol, high_pass_fp, ...
            high_pass_sigma);
    else
        high_pass_mask = zeros(box_size);
    end

    band_pass_mask = low_pass_mask - high_pass_mask;

    eig_val_fn = sprintf('%s_%d.em', eig_val_fn_prefix, iteration);

    if exist(eig_val_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_coeffs:File %s does not exist.', eig_val_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    eigen_values = getfield(tom_emread(eig_val_fn), 'Value');

    num_eigs = length(eigen_values);
    eigen_volume_cell = cell(num_eigs, 1);
    eigen_volume_weights = sqrt(1 ./ abs(eigen_values));

    for eig_idx = 1:num_eigs
        eig_vol_fn = sprintf('%s_%d_%d.em', eig_vol_fn_prefix, iteration, ...
            eig_idx);

        if exist(eig_vol_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'parallel_coeffs:File %s does not exist.', ...
                    eig_vol_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        eigen_volume = getfield(tom_emread(eig_vol_fn), 'Value');

        if ~all(size(eigen_volume) == box_size)
            try
                error('subTOM:volDimError', ...
                    'parallel_coeffs:%s and %s are not same size.', ...
                    eig_vol_fn, check_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        eigen_volume_cell{eig_idx} = eigen_volume;
    end

    coeffs = zeros(batch_size, num_eigs);
    weight_idx = 0;
    batch_idx = 1;

    % Setup the progress bar
    delprog = '';
    timings = [];
    message = sprintf('Calculating Coefficients %d', process_idx);
    op_type = 'WMDs';
    num_ops = batch_size * num_eigs;
    tic;

    for ptcl_idx = ptcl_start_idx:ptcl_end_idx

        % Read in weight if we need to
        if weight_idx ~= all_motl(tomo_row, ptcl_idx)

            % Update weight index
            weight_idx = all_motl(tomo_row, ptcl_idx);

            % Read in the weight
            weight_fn = sprintf('%s_%d.em', weight_fn_prefix, ...
                all_motl(tomo_row, ptcl_idx));

            if exist(weight_fn, 'file') ~= 2
                try
                    error('subTOM:missingFileError', ...
                        'parallel_coeffs:File %s does not exist.', ...
                        weight_fn);

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            weight = getfield(tom_emread(weight_fn), 'Value');

            if ~all(size(weight) == box_size)
                try
                    error('subTOM:volDimError', ...
                        'parallel_coeffs:%s and %s %s.', ...
                        weight_fn, check_fn, 'are not same size');

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            % Perform n-fold symmetrization of reference weight.
            if nfold ~= 1
                weight = tom_symref(weight, nfold);
            end
        end

        % Read in the particle
        if ~prealigned
            ptcl_fn = sprintf('%s_%d.em', ptcl_fn_prefix, ...
                all_motl(4, ptcl_idx));
        else
            ptcl_fn = sprintf('%s_%d_%d.em', ptcl_fn_prefix, iteration, ...
                all_motl(4, ptcl_idx));
        end

        if exist(ptcl_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'parallel_coeffs:File %s does not exist.', ptcl_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        ptcl = getfield(tom_emread(ptcl_fn), 'Value');

        if ~all(size(ptcl) == box_size)
            try
                error('subTOM:volDimError', ...
                    'parallel_coeffs:%s and %s are not same size.', ...
                    ptcl_fn, check_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        % Get the shifts and rotations to align the particle
        ptcl_shift = -all_motl(11:13, ptcl_idx);
        ptcl_rot = -all_motl([18, 17, 19], ptcl_idx);

        % Align the particle
        if ~prealigned
            ptcl = tom_rotate(tom_shift(ptcl, ptcl_shift), ptcl_rot);
        end

        % Apply symmetry if specified.
        if nfold ~= 1
            ptcl = tom_symref(ptcl, nfold);
        end

        % Apply the band-pass filter
        ptcl = ifftn(ifftshift(fftshift(fftn(ptcl)) .* band_pass_mask), ...
            'symmetric');

        % Align the weight
        ptcl_weight = tom_rotate(weight, ptcl_rot);

        % Apply the weight to the reference
        weighted_ref = ifftn(ifftshift(fftshift(fftn(ref)) .* ptcl_weight), ...
            'symmetric');

        % Calculate the Wedge-Masked Difference (wmd) of the particle from the
        % reference.
        wmd = weighted_ref - ptcl;

        % I am applying the mask here in case someone gives a softmask, in
        % practice I should be able to skip that product since I only pass the
        % masked indices to the D-Matrix, but I think that would confuse the
        % user if they saw that result after passing a soft mask.
        wmd = wmd .* mask;

        % We need to normalize the particle under the mask to a mean of zero and
        % standard deviation of one.
        wmd_mean = sum(wmd(:)) / num_mask_vox;
        wmd_stdv = sqrt((sum(sum(sum(wmd .* wmd))) / ...
            num_mask_vox) - (wmd_mean ^ 2));

        wmd = (wmd - (mask .* wmd_mean)) / wmd_stdv;

        % "Center" the difference
        wmd = wmd - dmatrix_mean;

        for eigen_idx = 1:num_eigs
            eigen_volume = eigen_volume_cell{eigen_idx};

            coeffs(batch_idx, eigen_idx) = sum(sum(sum(...
                eigen_volume .* wmd))) .* eigen_volume_weights(eigen_idx);

            % Display some output
            op_idx = (batch_idx - 1) * num_eigs + eigen_idx;
            [delprog, timings] = subtom_display_progress(delprog, timings, ...
                message, op_type, num_ops, op_idx);

        end

        batch_idx = batch_idx + 1;
    end

    coeff_fn = sprintf('%s_%d_%d.em', coeff_fn_prefix, iteration, ...
        process_idx);

    tom_emwrite(coeff_fn, coeffs);
    subtom_check_em_file(coeff_fn, coeffs);
end
