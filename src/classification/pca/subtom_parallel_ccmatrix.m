function subtom_parallel_ccmatrix(varargin)
% SUBTOM_PARALLEL_CCMATRIX calculates pairwise CCCs of aligned particles.
%
%     SUBTOM_PARALLEL_CCMATRIX(
%         'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX,
%         'ccmatrix_fn_prefix', CCMATRIX_FN_PREFIX,
%         'weight_fn_prefix', WEIGHT_FN_PREFIX,
%         'ptcl_fn_prefix', PTCL_FN_PREFIX,
%         'mask_fn', MASK_FN,
%         'high_pass_fp', HIGH_PASS_FP,
%         'high_pass_sigma', HIGH_PASS_SIGMA,
%         'low_pass_fp', LOW_PASS_FP,
%         'low_pass_sigma', LOW_PASS_SIGMA,
%         'nfold', NFOLD,
%         'iteration', ITERATION,
%         'tomo_row', TOMO_ROW,
%         'prealigned', PREALIGNED,
%         'num_ccmatrix_batch', NUM_CCMATRIX_BATCH,
%         'process_idx', PROCESS_IDX)
%
%     Aligns a subset of particles using the rotations and shifts in
%     ALL_MOTL_FN_PREFIX_ITERATION. If PREALIGNED evaluates to true as boolean,
%     then the particles in PTCL_FN_PREFIX are assumed to be prealigned, which
%     should increase the speed of the processing. The subset of particles
%     compared is specified by the file
%     CCMATRIX_FN_PREFIX_ITERATION_PROCESS_IDX_pairs.em, and the output list of
%     cross-correlation coefficients will be written out to the file
%     CCMATRIX_FN_PREFIX_ITERATION_PROCESS_IDX.em. Fourier weight volumes with
%     name prefix WEIGHT_FN_PREFIX will also be aligned so that the
%     cross-correlation cofficient can be constrained to only overlapping shared
%     regions of Fourier space. TOMO_ROW describes which row of the MOTL file is
%     used to determine the correct tomogram Fourier weight file. The
%     correlation is also constrained by a bandpass filter specified by
%     HIGH_PASS_FP, HIGH_PASS_SIGMA, LOW_PASS_FP and LOW_PASS_SIGMA.

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'all_motl_fn_prefix', 'combinedmotl/allmotl');
    addParameter(fn_parser, 'ccmatrix_fn_prefix', 'pca/ccmatrix');
    addParameter(fn_parser, 'weight_fn_prefix', 'otherinputs/ampspec');
    addParameter(fn_parser, 'ptcl_fn_prefix', 'subtomograms/subtomo');
    addParameter(fn_parser, 'mask_fn', 'none');
    addParameter(fn_parser, 'high_pass_fp', 0);
    addParameter(fn_parser, 'high_pass_sigma', 0);
    addParameter(fn_parser, 'low_pass_fp', 0);
    addParameter(fn_parser, 'low_pass_sigma', 0);
    addParameter(fn_parser, 'nfold', 1);
    addParameter(fn_parser, 'iteration', 1);
    addParameter(fn_parser, 'tomo_row', 7);
    addParameter(fn_parser, 'prealigned', 0);
    addParameter(fn_parser, 'num_ccmatrix_batch', 1);
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
                'parallel_ccmatrix:all_motl_dir: Directory %s %s.', ...
                all_motl_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    ccmatrix_fn_prefix = fn_parser.Results.ccmatrix_fn_prefix;
    [ccmatrix_dir, ~, ~] = fileparts(ccmatrix_fn_prefix);

    if ~isempty(ccmatrix_dir) && exist(ccmatrix_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_ccmatrix:ccmatrix_dir: Directory %s %s.', ...
                ccmatrix_dir, 'does not exist');

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
                'parallel_ccmatrix:weight_dir: Directory %s %s.', ...
                weight_dir, 'does not exist');

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
                'parallel_ccmatrix:ptcl_dir: Directory %s %s.', ...
                ptcl_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    mask_fn = fn_parser.Results.mask_fn;

    if ~strcmp(mask_fn, 'none') && exist(mask_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_ccmatrix:File %s does not exist.', mask_fn);

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
            'subtom_parallel_ccmatrix', 'high_pass_fp');

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
            'subtom_parallel_ccmatrix', 'high_pass_sigma');

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
            'subtom_parallel_ccmatrix', 'low_pass_fp');

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
            'subtom_parallel_ccmatrix', 'low_pass_sigma');

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
            'subtom_parallel_ccmatrix', 'nfold');

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
            'subtom_parallel_ccmatrix', 'iteration');

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
            'subtom_parallel_ccmatrix', 'tomo_row');

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
            'subtom_parallel_ccmatrix', 'prealigned');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    num_ccmatrix_batch = fn_parser.Results.num_ccmatrix_batch;

    if ischar(num_ccmatrix_batch)
        num_ccmatrix_batch = str2double(num_ccmatrix_batch);
    end

    try
        validateattributes(num_ccmatrix_batch, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0}, ...
            'subtom_parallel_ccmatrix', 'num_ccmatrix_batch');

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
            '<=', num_ccmatrix_batch}, ...
            'subtom_parallel_ccmatrix', 'process_idx');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Check if the calculation has already been done and skip if so.
    full_ccmatrix_fn = sprintf('%s_%d.em', ccmatrix_fn_prefix, iteration);

    if exist(full_ccmatrix_fn, 'file') == 2
        warning('subTOM:recoverOnFail', ...
            'parallel_ccmatrix:File %s already exists. SKIPPING!', ...
            full_ccmatrix_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    ccmatrix_fn = sprintf('%s_%d_%d.em', ccmatrix_fn_prefix, iteration, ...
        process_idx);

    if exist(ccmatrix_fn, 'file') == 2
        warning('subTOM:recoverOnFail', ...
            'parallel_ccmatrix:File %s already exists. SKIPPING!', ...
            ccmatrix_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Read in all_motl file
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(all_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_ccmatrix:File %s does not exist.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl = getfield(tom_emread(all_motl_fn), 'Value');

    if size(all_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'parallel_ccmatrix:%s is not proper MOTL.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Get box size from first subtomogram
    if ~prealigned
        check_fn = sprintf('%s_%d.em', ptcl_fn_prefix, all_motl(4, 1));
    else
        check_fn = sprintf('%s_%d_%d.em', ptcl_fn_prefix, iteration, ...
            all_motl(4, 1));
    end

    if exist(check_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_ccmatrix:File %s does not exist.', check_fn);

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

    % Read in classification mask
    if ~strcmpi(mask_fn, 'none')
        mask = getfield(tom_emread(mask_fn), 'Value');

        if ~all(size(mask) == box_size)
            try
                error('subTOM:volDimError', ...
                    'parallel_ccmatrix:%s and %s are not same size.', ...
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

    % Find the number of voxels in the mask. The mask should be all ones but in
    % case it isn't we threshold it at 1e-6
    num_mask_vox = sum(sum(sum(mask > 1e-6)));

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

    % Read in the list of pairs to calculate
    pairs_fn = sprintf('%s_%d_%d_pairs.em', ccmatrix_fn_prefix, iteration, ...
        process_idx);

    if exist(pairs_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_ccmatrix:File %s does not exist.', pairs_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    pairs = getfield(tom_emread(pairs_fn), 'Value');
    num_pairs = size(pairs, 1);

    % Create an array to hold the CCCs
    ccc = zeros(1, num_pairs);

    % Set the initial reference index
    ref_idx = 0;

    % Set the initial weight index for both a particle and the reference
    ref_weight_idx = 0;
    ptcl_weight_idx = 0;

    % Setup the progress bar
    delprog = '';
    timings = [];
    message = sprintf('CC-Matrix Batch %d', process_idx);
    op_type = 'Comparisons';
    tic;

    for pair_idx = 1:num_pairs
        % Check if we need to load in a new reference particle
        if ref_idx ~= pairs(pair_idx, 1)

            % Update reference index
            ref_idx = pairs(pair_idx, 1);

            % Read in reference particle
            if ~prealigned
                ref_fn = sprintf('%s_%d.em', ptcl_fn_prefix, ...
                    all_motl(4, ref_idx));
            else
                ref_fn = sprintf('%s_%d_%d.em', ptcl_fn_prefix, iteration, ...
                    all_motl(4, ref_idx));
            end

            if exist(ref_fn, 'file') ~= 2
                try
                    error('subTOM:missingFileError', ...
                        'parallel_ccmatrix:File %s does not exist.', ...
                        ref_fn);

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            ref = getfield(tom_emread(ref_fn), 'Value');

            if ~all(size(ref) == box_size)
                try
                    error('subTOM:volDimError', ...
                        'parallel_ccmatrix:%s and %s %s.', ...
                        ref_fn, check_fn, 'are not same size');

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            % Read in reference weight if we need to
            if ref_weight_idx ~= all_motl(tomo_row, ref_idx)

                % Update reference weight index
                ref_weight_idx = all_motl(tomo_row, ref_idx);

                % Read in the weight
                ref_weight_fn = sprintf('%s_%d.em', weight_fn_prefix, ...
                    all_motl(tomo_row, ref_idx));

                if exist(ref_weight_fn, 'file') ~= 2
                    try
                        error('subTOM:missingFileError', ...
                            'parallel_ccmatrix:File %s does not exist.', ...
                            ref_weight_fn);

                    catch ME
                        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                        rethrow(ME);
                    end
                end

                ref_weight = getfield(tom_emread(ref_weight_fn), 'Value');

                if ~all(size(ref_weight) == box_size)
                    try
                        error('subTOM:volDimError', ...
                            'parallel_ccmatrix:%s and %s %s.', ...
                            ref_weight_fn, check_fn, 'are not same size');

                    catch ME
                        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                        rethrow(ME);
                    end
                end

                % Perform n-fold symmetrization of reference weight.
                if nfold ~= 1
                    ref_weight = tom_symref(ref_weight, nfold);
                end
            end

            % Get the shifts and rotations to align the reference
            ref_shift = -all_motl(11:13, ref_idx);
            ref_rot = -all_motl([18, 17, 19], ref_idx);

            if ~prealigned
                % Align the reference and its weight
                ref = tom_rotate(tom_shift(ref, ref_shift), ref_rot);
            end

            % Perform n-fold symmetrization of reference.
            if nfold ~= 1
                ref = tom_symref(ref, nfold);
            end

            ref_rot_weight = tom_rotate(ref_weight, ref_rot);

            % Calculate the Fourier transform of the reference
            ref_fft = fftshift(fftn(ref));
        end

        % Handle the particle the reference is compared against
        ptcl_idx = pairs(pair_idx, 2);

        % Read in particle
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
                    'parallel_ccmatrix:File %s does not exist.', ...
                    ptcl_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        ptcl = getfield(tom_emread(ptcl_fn), 'Value');

        if ~all(size(ptcl) == box_size)
            try
                error('subTOM:volDimError', ...
                    'parallel_ccmatrix:%s and %s are not same size.', ...
                    ptcl_fn, check_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        % Read in particle weight if we need to
        if ptcl_weight_idx ~= all_motl(tomo_row, ptcl_idx)

            % Check if we can use the ref_weight
            if ref_weight_idx == all_motl(tomo_row, ptcl_idx)

                % Update particle weight index as the reference weight index
                ptcl_weight_idx = ref_weight_idx;

                % Copy the reference weight to the particle weight
                ptcl_weight = ref_weight;

            else

                % Update particle weight index
                ptcl_weight_idx = all_motl(tomo_row, ptcl_idx);

                % Read in the weight
                ptcl_weight_fn = sprintf('%s_%d.em', weight_fn_prefix, ...
                    all_motl(tomo_row, ptcl_idx));

                if exist(ptcl_weight_fn, 'file') ~= 2
                    try
                        error('subTOM:missingFileError', ...
                            'parallel_ccmatrix:File %s does not exist.', ...
                            ptcl_weight_fn);

                    catch ME
                        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                        rethrow(ME);
                    end
                end

                ptcl_weight = getfield(tom_emread(ptcl_weight_fn), 'Value');

                if ~all(size(ptcl_weight) == box_size)
                    try
                        error('subTOM:volDimError', ...
                            'parallel_ccmatrix:%s and %s %s.', ...
                            ptcl_weight_fn, check_fn, 'are not same size');

                    catch ME
                        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                        rethrow(ME);
                    end
                end

                % Perform n-fold symmetrization of particle weight.
                if nfold ~= 1
                    ptcl_weight = tom_symref(ptcl_weight, nfold);
                end
            end
        end

        % Get the shifts and rotations to align the particle
        ptcl_shift = -all_motl(11:13, ptcl_idx);
        ptcl_rot = -all_motl([18, 17, 19], ptcl_idx);

        % Align the particle and its weight
        if ~prealigned
            ptcl = tom_rotate(tom_shift(ptcl, ptcl_shift), ptcl_rot);
        end

        % Perform n-fold symmetrization of particle.
        if nfold ~= 1
            ptcl = tom_symref(ptcl, nfold);
        end

        ptcl_rot_weight = tom_rotate(ptcl_weight, ptcl_rot);

        % Calculate the Fourier transform of the particle
        ptcl_fft = fftshift(fftn(ptcl));

        % Apply the constrained shared region of Fourier space to each particle
        % I am applying the mask here in case someone gives a softmask, in
        % practice I should be able to skip the product and only consider the
        % thresholded masked indices, but I think that would confuse the user if
        % they saw that result after passing a soft mask.
        ccc_weight = band_pass_mask .* ref_rot_weight .* ptcl_rot_weight;
        ccc_ref = ifftn(ifftshift(ref_fft .* ccc_weight), ...
            'symmetric') .* mask;

        ccc_ptcl = ifftn(ifftshift(ptcl_fft .* ccc_weight), ...
            'symmetric') .* mask;

        % We need to normalize each the particle and the reference under the
        % mask to a mean of zero and standard deviation of one.
        ccc_ref_mean = sum(ccc_ref(:)) / num_mask_vox;
        ccc_ref_stdv = sqrt((sum(sum(sum(ccc_ref .* ccc_ref))) / ...
            num_mask_vox) - (ccc_ref_mean ^ 2));

        ccc_ref = (ccc_ref - (mask .* ccc_ref_mean)) / ccc_ref_stdv;

        ccc_ptcl_mean = sum(ccc_ptcl(:)) / num_mask_vox;
        ccc_ptcl_stdv = sqrt((sum(sum(sum(ccc_ptcl .* ccc_ptcl))) / ...
            num_mask_vox) - (ccc_ptcl_mean ^ 2));

        ccc_ptcl = (ccc_ptcl - (mask .* ccc_ptcl_mean)) / ccc_ptcl_stdv;

        % Calculate the Cross-Correlation Coefficient in real-space so that we
        % can use hard edged masks and since we don't need to do any alignment.
        % Note that the division by num_mask_vox is appropriate here because of
        % the fact that the mean is zero and the standard deviation is one.
        ccc(pair_idx) = sum(sum(sum(ccc_ref .* ccc_ptcl))) / num_mask_vox;

        % Display some output
        [delprog, timings] = subtom_display_progress(delprog, timings, ...
            message, op_type, num_pairs, pair_idx);

    end

    % Finally we write out the ccmatrix values
    tom_emwrite(ccmatrix_fn, ccc);
    subtom_check_em_file(ccmatrix_fn, ccc);
end
