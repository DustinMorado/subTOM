function pca_parallel_ccmatrix(all_motl_fn_prefix, ccmatrix_fn_prefix, ...
    weight_fn_prefix, ptcl_fn_prefix, mask_fn, high_pass_fp, ...
    high_pass_sigma, low_pass_fp, low_pass_sigma, nfold, iteration, ...
    tomo_row, prealigned, num_ccmatrix_batch, process_idx)
% PCA_PARALLEL_CCMATRIX calculates pairwise CCCs of aligned particles in batchs.
%     PCA_PARALLEL_CCMATRIX(
%         ALL_MOTL_FN_PREFIX,
%         CCMATRIX_FN_PREFIX,
%         WEIGHT_FN_PREFIX,
%         PTCL_FN_PREFIX,
%         MASK_FN,
%         HIGH_PASS_FP,
%         HIGH_PASS_SIGMA,
%         LOW_PASS_FP,
%         LOW_PASS_SIGMA,
%         NFOLD,
%         ITERATION,
%         TOMO_ROW,
%         PREALIGNED,
%         NUM_CCMATRIX_BATCH,
%         PROCESS_IDX)
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
%
% Example:
%     PCA_PARALLEL_CCMATRIX('combinedmotl/allmotl', 'pca/ccmatrix',
%         'otherinputs/ampspec', 'subtomograms/subtomo',
%         'otherinputs/pca_mask.em', 1, 2, 32, 3, 1, 1, 7, 0, 500, 1)
%
%     Would compare the particles specified in 'pca/ccmatrix_1_1_pairs.em',
%     using the Fourier weights 'otherinputs/ampspec_?.em' where the ? is the
%     tomogram number which belongs to each particle. Particles are not
%     prealigned and so will be aligned here. Each particle is then band
%     pass filtered with the highpass filter at 1 Fourier pixel with a falloff
%     (up) over 2 pixels and a lowpass filter cutoff at 32 Fourier pixels with a
%     falloff over 3 pixels. The function will write out the follwing
%     files:
%         * 'pca/ccmatrix_1_1.em' - The constrained cross-correlation
%             coefficients
%
% See also PCA_PREPARE_CCMATRIX, PCA_JOIN_CCMATRIX

% DRM 02-2019
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% all_motl_fn_prefix = 'combined/allmotl';
% ccmatrix_fn_prefix = 'pca/ccmatrix';
% weight_fn_prefix = 'otherinputs/ampspec';
% ptcl_fn_prefix = 'subtomograms/subtomo';
% mask_fn = 'otherinputs/pca_mask.em';
% high_pass_fp = 1;
% high_pass_sigma = 2;
% low_pass_fp = 32;
% low_pass_sigma = 3;
% nfold = 1;
% iteration = 1;
% tomo_row = 7;
% prealigned = 1;
% num_ccmatrix_batch = 500;
% process_idx = 1;
%##############################################################################%
    % Evaluate numeric inputs
    if ischar(high_pass_fp)
        high_pass_fp = str2double(high_pass_fp);
    end

    if isnan(high_pass_fp) || high_pass_fp < 0
        try
            error('subTOM:argumentError', ...
                'pca_parallel_ccmatrix:high_pass_fp: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(high_pass_sigma)
        high_pass_sigma = str2double(high_pass_sigma);
    end

    if isnan(high_pass_sigma) || high_pass_sigma < 0
        try
            error('subTOM:argumentError', ...
                'pca_parallel_ccmatrix:high_pass_sigma: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(low_pass_fp)
        low_pass_fp = str2double(low_pass_fp);
    end

    if isnan(low_pass_fp) || low_pass_fp < 0
        try
            error('subTOM:argumentError', ...
                'pca_parallel_ccmatrix:low_pass_fp: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(low_pass_sigma)
        low_pass_sigma = str2double(low_pass_sigma);
    end

    if isnan(low_pass_sigma) || low_pass_sigma < 0
        try
            error('subTOM:argumentError', ...
                'pca_parallel_ccmatrix:low_pass_sigma: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(nfold)
        nfold = str2double(nfold);
    end

    if isnan(nfold) || nfold < 1 || rem(nfold, 1) ~= 0
        try
            error('subTOM:argumentError', ...
                'pca_parallel_ccmatrix:nfold: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(iteration)
        iteration = str2double(iteration);
    end

    if isnan(iteration) || rem(iteration, 1) ~= 0
        try
            error('subTOM:argumentError', ...
                'pca_parallel_ccmatrix:iteration: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(tomo_row)
        tomo_row = str2double(tomo_row);
    end

    if isnan(tomo_row) || tomo_row < 1 || tomo_row > 20 || rem(tomo_row, 1) ~= 0
        try
            error('subTOM:argumentError', ...
                'pca_parallel_ccmatrix:tomo_row: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(prealigned)
        prealigned = str2double(prealigned);
    end

    if isnan(prealigned)
        try
            error('subTOM:argumentError', ...
                'pca_parallel_ccmatrix:prealigned: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ~ (prealigned == 1 || prealigned == 0)
        warning('subTOM:argumentWarning', ...
            'pca_parallel_ccmatrix:prealigned: argument unexpected');
        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
    end

    prealigned = logical(prealigned);

    if ischar(num_ccmatrix_batch)
        num_ccmatrix_batch = str2double(num_ccmatrix_batch);
    end

    if isnan(num_ccmatrix_batch) || num_ccmatrix_batch < 1 || ...
        rem(num_ccmatrix_batch, 1) ~= 0

        try
            error('subTOM:argumentError', ...
                'pca_parallel_ccmatrix:num_ccmatrix_batch: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(process_idx)
        process_idx = str2double(process_idx);
    end

    if isnan(process_idx) || process_idx < 1 || ...
        process_idx > num_ccmatrix_batch || rem(process_idx, 1) ~= 0

        try
            error('subTOM:argumentError', ...
                'pca_parallel_ccmatrix:process_idx: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    %##########################################################################%
    %                         CHECK IF ALREADY CALCULATED                      %
    %##########################################################################%
    ccmatrix_fn = sprintf('%s_%d_%d.em', ccmatrix_fn_prefix, iteration, ...
        process_idx);

    if exist(fullfile(pwd(), ccmatrix_fn), 'file') == 2
        warning('subTOM:recoverOnFail', ...
            'pca_parallel_ccmatrix:File %s already exists. SKIPPING!', ...
            ccmatrix_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    %##########################################################################%
    %                              PREPARE ALL MOTL                            %
    %##########################################################################%
    % Read in all_motl file
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(fullfile(pwd(), all_motl_fn), 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'pca_parallel_ccmatrix:File %s does not exist.', all_motl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl = getfield(tom_emread(all_motl_fn), 'Value');

    if size(all_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'pca_parallel_ccmatrix:%s is not proper MOTL.', all_motl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Get box size from first subtomogram
    if ~prealigned
        ptcl_fn = sprintf('%s_%d.em', ptcl_fn_prefix, all_motl(4, 1));
    else
        ptcl_fn = sprintf('%s_%d_%d.em', ptcl_fn_prefix, iteration, ...
            all_motl(4, 1));
    end

    check_fn = ptcl_fn;

    if exist(fullfile(pwd(), ptcl_fn), 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'pca_parallel_ccmatrix:File %s does not exist.', ptcl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Note the transpose, tom_reademheader returns a column vector, but Matlab
    % size function returns a row vector, and ones and zeros need row vector
    box_size = getfield(tom_reademheader(ptcl_fn), 'Header', 'Size')';

    % Create a ones volume thats used a bit
    ones_vol = ones(box_size);

    % Read in classification mask
    if ~strcmpi(mask_fn, 'none')
        if exist(fullfile(pwd(), mask_fn), 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'pca_parallel_ccmatrix:File %s does not exist.', mask_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        mask = getfield(tom_emread(mask_fn), 'Value');

        if ~all(size(mask) == box_size)
            try
                error('subTOM:volDimError', ...
                    'pca_parallel_ccmatrix:%s and %s are not same size.', ...
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

    if exist(fullfile(pwd(), pairs_fn), 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'pca_parallel_ccmatrix:File %s does not exist.', pairs_fn);
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

    % Some variables for showing progress
    delprog = '';
    delprog_batch = max(floor(num_pairs / 200), 1);
    timings = [];
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

            if exist(fullfile(pwd(), ref_fn), 'file') ~= 2
                try
                    error('subTOM:missingFileError', ...
                        'pca_parallel_ccmatrix:File %s does not exist.', ...
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
                        'pca_parallel_ccmatrix:%s and %s %s.', ...
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

                if exist(fullfile(pwd(), ref_weight_fn), 'file') ~= 2
                    try
                        error('subTOM:missingFileError', ...
                            'pca_parallel_ccmatrix:File %s does not exist.', ...
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
                            'pca_parallel_ccmatrix:%s and %s %s.', ...
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

        if exist(fullfile(pwd(), ptcl_fn), 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'pca_parallel_ccmatrix:File %s does not exist.', ...
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
                    'pca_parallel_ccmatrix:%s and %s are not same size.', ...
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

                if exist(fullfile(pwd(), ptcl_weight_fn), 'file') ~= 2
                    try
                        error('subTOM:missingFileError', ...
                            'pca_parallel_ccmatrix:File %s does not exist.', ...
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
                            'pca_parallel_ccmatrix:%s and %s %s.', ...
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
        % Realized that for 64k particles split into 512 chunks there are still
        % ~4M comparisons to make so updating constantly can lead to massive log
        % files. So we only update the bar every %0.5, which is in the example a
        % very slow 21251 particles
        if mod(pair_idx, delprog_batch) == 0
            elapsed_time = toc;
            timings = [timings elapsed_time];
            delprog = disp_progbar(process_idx, num_pairs, pair_idx, ...
                timings, delprog);
            tic;
        end
    end

    % Finally we write out the ccmatrix values
    tom_emwrite(ccmatrix_fn, ccc);
    check_em_file(ccmatrix_fn, ccc);
end
