function subtom_parallel_dmatrix(varargin)
% SUBTOM_PARALLEL_DMATRIX calculates chunks of the D-matrix for processing.
%
%     SUBTOM_PARALLEL_DMATRIX(
%         'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX,
%         'dmatrix_fn_prefix', XMATRIX_FN_PREFIX,
%         'ptcl_fn_prefix', PTCL_FN_PREFIX,
%         'ref_fn_prefix',REF_FN_PREFIX,
%         'weight_fn_prefix', WEIGHT_FN_PREFIX,
%         'mask_fn', MASK_FN,
%         'high_pass_fp', HIGH_PASS_FP,
%         'high_pass_sigma', HIGH_PASS_SIGMA,
%         'low_pass_fp', LOW_PASS_FP,
%         'low_pass_sigma', LOW_PASS_SIGMA,
%         'nfold', NFOLD,
%         'iteration', ITERATION,
%         'tomo_row', TOMO_ROW,
%         'prealigned', PREALIGNED,
%         'num_dmatrix_batch', NUM_DMATRIX_BATCH,
%         'process_idx', PROCESS_IDX)
%
%     Aligns a subset of particles using the rotations and shifts in
%     ALL_MOTL_FN_PREFIX_ITERATION.em and then subtracts the particle from the
%     reference REF_FN_PREFIX_ITERATION.em and places these voxels of the
%     difference as a 1-D row vector in a data sub-matrix which is denoted as
%     the D-matrix (See Heumann, et al. 2011 J. Struct. Biol.). The particle and
%     reference are also filtered by a bandpass filter specified by
%     HIGH_PASS_FP, HIGH_PASS_SIGMA, LOW_PASS_FP and LOW_PASS_SIGMA before
%     subtracted, and the reference is masked in Fourier space using the weight
%     specified by WEIGHT_FN_PREFIX and TOMO_ROW.  The subset of particles
%     compared is specified by the number of particles in the motive list and
%     the number of requested batches specified by NUM_DMATRIX_BATCH, with the
%     specific subset deteremined by PROCESS_IDX. The D-matrix chunk will be
%     written out as DMATRIX_FN_PREFIX_ITERATION_PROCESS_IDX.em. The location of
%     the particles is specified by PTCL_FN_PREFIX. If PREALIGNED evaluates to
%     true as a boolean then the particles are assumed to be prealigned, which
%     should increase speed of computation of D-Matrix calculations. Particles
%     in the D-matrix will be masked by the file given by MASK_FN. If the string
%     'none' is used in place of MASK_FN, a default spherical mask is applied.
%     This mask should be a binary mask and only voxels within the mask are
%     placed into the D-matrix which can greatly speed up computations.

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'all_motl_fn_prefix', 'combinedmotl/allmotl');
    addParameter(fn_parser, 'dmatrix_fn_prefix', 'wmd/dmatrix');
    addParameter(fn_parser, 'ptcl_fn_prefix', 'subtomograms/subtomo');
    addParameter(fn_parser, 'ref_fn_prefix', 'ref/ref');
    addParameter(fn_parser, 'weight_fn_prefix', 'otherinputs/ampspec');
    addParameter(fn_parser, 'mask_fn', 'none');
    addParameter(fn_parser, 'high_pass_fp', 0);
    addParameter(fn_parser, 'high_pass_sigma', 0);
    addParameter(fn_parser, 'low_pass_fp', 0);
    addParameter(fn_parser, 'low_pass_sigma', 0);
    addParameter(fn_parser, 'nfold', 1);
    addParameter(fn_parser, 'iteration', '1');
    addParameter(fn_parser, 'tomo_row', 7);
    addParameter(fn_parser, 'prealigned', '0');
    addParameter(fn_parser, 'num_dmatrix_batch', '1');
    addParameter(fn_parser, 'process_idx', '1');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    all_motl_fn_prefix = fn_parser.Results.all_motl_fn_prefix;
    [all_motl_dir, ~, ~] = fileparts(all_motl_fn_prefix);

    if ~isempty(all_motl_dir) && exist(all_motl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_dmatrix:all_motl_dir: Directory %s %s.', ...
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
                'parallel_dmatrix:dmatrix_dir: Directory %s %s.', ...
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
                'parallel_dmatrix:ptcl_dir: Directory %s %s.', ...
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
                'parallel_dmatrix:ref_dir: Directory %s %s.', ...
                ref_dir, 'does not exist');

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
                'parallel_dmatrix:weight_dir: Directory %s %s.', ...
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
                'parallel_dmatrix:File %s does not exist.', mask_fn);

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
            'subtom_parallel_dmatrix', 'high_pass_fp');

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
            'subtom_parallel_dmatrix', 'high_pass_sigma');

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
            'subtom_parallel_dmatrix', 'low_pass_fp');

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
            'subtom_parallel_dmatrix', 'low_pass_sigma');

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
            'subtom_parallel_dmatrix', 'nfold');

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
            'subtom_parallel_dmatrix', 'iteration');

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
            'subtom_parallel_dmatrix', 'tomo_row');

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
            'subtom_parallel_dmatrix', 'prealigned');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    num_dmatrix_batch = fn_parser.Results.num_dmatrix_batch;

    if ischar(num_dmatrix_batch)
        num_dmatrix_batch = str2double(num_dmatrix_batch);
    end

    try
        validateattributes(num_dmatrix_batch, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0}, ...
            'subtom_parallel_dmatrix', 'num_dmatrix_batch');

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
            '<=', num_dmatrix_batch}, ...
            'subtom_parallel_dmatrix', 'process_idx');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Check if the calculation has already been done and skip if so.
    dmatrix_fn = sprintf('%s_%d_%d.em', dmatrix_fn_prefix, iteration, ...
        process_idx);

    if exist(dmatrix_fn, 'file') == 2
        warning('subTOM:recoverOnFail', ...
            'parallel_dmatrix:File %s already exists. SKIPPING!', ...
            dmatrix_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Read in all_motl file
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(all_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_dmatrix:File %s does not exist.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl = getfield(tom_emread(all_motl_fn), 'Value');

    if size(all_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'parallel_dmatrix:%s is not proper MOTL.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Calculate the number and indices of particles to process
    num_ptcls = size(all_motl, 2);

    if num_dmatrix_batch > num_ptcls
        try
            error('subTOM:argumentError', ...
                'parallel_dmatrix:num_dmatrix_batch is %s.', ...
                'greater than num_ptcls.');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    dmatrix_batch_size = floor(num_ptcls / num_dmatrix_batch);

    if process_idx > (num_ptcls - (dmatrix_batch_size * num_dmatrix_batch))
        ptcl_start_idx = (process_idx - 1) * dmatrix_batch_size + 1 + ...
            (num_ptcls - (dmatrix_batch_size * num_dmatrix_batch));

        ptcl_end_idx = ptcl_start_idx + dmatrix_batch_size - 1;
    else
        ptcl_start_idx = (process_idx - 1) * (dmatrix_batch_size + 1) + 1;
        ptcl_end_idx = ptcl_start_idx + dmatrix_batch_size;
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
                'parallel_dmatrix:File %s does not exist.', check_fn);

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
                'parallel_dmatrix:File %s does not exist.', ref_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    ref = getfield(tom_emread(ref_fn), 'Value');

    if ~all(size(ref) == box_size)
        try
            error('subTOM:volDimError', ...
                'parallel_dmatrix:%s and %s are not same size.', ...
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
                    'parallel_dmatrix:File %s does not exist.', mask_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        mask = getfield(tom_emread(mask_fn), 'Value');

        if ~all(size(mask) == box_size)
            try
                error('subTOM:volDimError', ...
                    'parallel_dmatrix:%s and %s are not same size.', ...
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

    % Initialize the partial D-Matrix
    dmatrix = zeros(num_mask_vox, batch_size);

    % Setup the progress bar
    delprog = '';
    timings = [];
    message = sprintf('D-Matrix Batch %d', process_idx);
    op_type = 'particles';
    tic;

    % Loop over batch
    dmatrix_idx = 1;
    weight_idx = 0;

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
                        'parallel_dmatrix:File %s does not exist.', weight_fn);

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            weight = getfield(tom_emread(weight_fn), 'Value');

            if ~all(size(weight) == box_size)
                try
                    error('subTOM:volDimError', ...
                        'parallel_dmatrix:%s and %s %s.', ...
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
                    'parallel_dmatrix:File %s does not exist.', ptcl_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        ptcl = getfield(tom_emread(ptcl_fn), 'Value');

        if ~all(size(ptcl) == box_size)
            try
                error('subTOM:volDimError', ...
                    'parallel_dmatrix:%s and %s are not same size.', ...
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
        wmd_mean = sum(ptcl(:)) / num_mask_vox;
        wmd_stdv = sqrt((sum(sum(sum(wmd .* wmd))) / ...
            num_mask_vox) - (wmd_mean ^ 2));

        wmd = (wmd - (mask .* wmd_mean)) / wmd_stdv;

        % Set values in xmatrix and xmatrix weight
        dmatrix(:, dmatrix_idx) = wmd(mask_idxs);

        % Display some output
        [delprog, timings] = subtom_display_progress(delprog, timings, ...
            message, op_type, batch_size, dmatrix_idx);

        % Increment the xmatrix index
        dmatrix_idx = dmatrix_idx + 1;
    end

    % Write out the partial xmatrix and the partial xmatrix weight
    tom_emwrite(dmatrix_fn, dmatrix);
    subtom_check_em_file(dmatrix_fn, dmatrix);
end
