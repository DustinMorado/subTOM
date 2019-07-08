function pca_parallel_eigencoeffs(all_motl_fn_prefix, eig_vec_fn_prefix, ...
    eig_val_fn_prefix, xmatrix_fn_prefix, weight_fn_prefix, ...
    eig_vol_fn_prefix, mask_fn, eig_coeff_fn_prefix, use_fast, use_eig_vec, ...
    use_eig_val, nfold, iteration, tomo_row, num_xmatrix_batch, process_idx)
% PCA_PARALLEL_EIGENCOEFFS computes projections of subvolumes onto eigenvectors.
%     PCA_PARALLEL_EIGENCOEFFS(
%         ALL_MOTL_FN_PREFIX,
%         EIG_VEC_FN_PREFIX,
%         EIG_VAL_FN_PREFIX,
%         XMATRIX_FN_PREFIX,
%         WEIGHT_FN_PREFIX,
%         EIG_VOL_FN_PREFIX,
%         MASK_FN,
%         EIG_COEFF_FN_PREFIX,
%         USE_FAST,
%         USE_EIG_VEC,
%         USE_EIG_VAL,
%         NFOLD,
%         ITERATION,
%         TOMO_ROW,
%         NUM_XMATRIX_BATCH,
%         PROCESS_IDX)
%
%     TODO: Fill in info here
%
% Example:
%     PCA_PARALLEL_EIGENCOEFFS('combinedmotl/allmotl', 'pca/eig_vec',
%         'pca/eig_val', 'pca/xmatrix', 'otherinputs/ampspec', 'pca/eig_vol',
%         'otherinputs/pca_mask.em', 'pca/eig_coeff', 1, 0, 1, 1, 1, 7, 256, 1);
%
%     TODO: Fill in info here

% DRM 02-2019
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% all_motl_fn_prefix = 'combinedmotl/allmotl';
% eig_vec_fn_prefix = 'pca/eig_vec';
% eig_val_fn_prefix = 'pca/eig_val';
% xmatrix_fn_prefix = 'pca/xmatrix';
% weight_fn_prefix = 'otherinputs/ampspec';
% eig_vol_fn_prefix = 'pca/eig_vol';
% mask_fn = 'otherinputs/pca_mask.em';
% eig_coeff_fn_prefix = 'pca/pca_coeff';
% use_fast = 1;
% use_eig_vec = 0;
% use_eig_val = 1;
% nfold = 1;
% iteration = 1
% tomo_row = 7;
% num_xmatrix_batch = 256;
% process_idx = 1;
%##############################################################################%
    if ischar(use_fast)
        use_fast = str2double(use_fast);
    end

    if isnan(use_fast)
        try
            error('subTOM:argumentError', ...
                'pca_parallel_eigencoeffs:use_fast: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ~ (use_fast == 1 || use_fast == 0)
        warning('subTOM:argumentWarning', ...
            'pca_parallel_eigencoeffs:use_fast: argument unexpected');
        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
    end

    use_fast = logical(use_fast);

    if ischar(use_eig_vec)
        use_eig_vec = str2double(use_eig_vec);
    end

    if isnan(use_eig_vec)
        try
            error('subTOM:argumentError', ...
                'pca_parallel_eigencoeffs:use_eig_vec: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ~ (use_eig_vec == 1 || use_eig_vec == 0)
        warning('subTOM:argumentWarning', ...
            'pca_parallel_eigencoeffs:use_eig_vec: argument unexpected');
        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
    end

    use_eig_vec = logical(use_eig_vec);

    if use_fast && use_eig_vec
        try
            error('subTOM:argumentError', ...
                'pca_parallel_eigencoeffs: %s and %s %s.', ...
                'use_fast', 'use_eig_vec', 'are mutually exclusive');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(use_eig_val)
        use_eig_val = str2double(use_eig_val);
    end

    if isnan(use_eig_val)
        try
            error('subTOM:argumentError', ...
                'pca_parallel_eigencoeffs:use_eig_val: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ~ (use_eig_val == 1 || use_eig_val == 0)
        warning('subTOM:argumentWarning', ...
            'pca_parallel_eigencoeffs:use_eig_val: argument unexpected');
        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
    end

    use_eig_val = logical(use_eig_val);

    if ischar(nfold)
        nfold = str2double(nfold);
    end

    if isnan(nfold) || nfold < 1 || rem(nfold, 1) ~= 0
        try
            error('subTOM:argumentError', ...
                'pca_parallel_eigencoeffs:nfold: argument invalid');
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
                'pca_parallel_eigencoeffs:iteration: argument invalid');
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
                'pca_parallel_eigencoeffs:tomo_row: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(num_xmatrix_batch)
        num_xmatrix_batch = str2double(num_xmatrix_batch);
    end

    if isnan(num_xmatrix_batch) || num_xmatrix_batch < 1 || ...
        rem(num_xmatrix_batch, 1) ~= 0

        try
            error('subTOM:argumentError', ...
                'pca_parallel_eigencoeffs:num_xmatrix_batch: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(process_idx)
        process_idx = str2double(process_idx);
    end

    if isnan(process_idx) || process_idx < 1 || ...
        process_idx > num_xmatrix_batch || rem(process_idx, 1) ~= 0

        try
            error('subTOM:argumentError', ...
                'pca_parallel_eigencoeffs:process_idx: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    %##########################################################################%
    %                         CHECK IF ALREADY CALCULATED                      %
    %##########################################################################%
    eig_coeff_fn = sprintf('%s_%d.em', eig_coeff_fn_prefix, iteration);

    if exist(fullfile(pwd(), eig_coeff_fn), 'file') == 2
        warning('subTOM:recoverOnFail', ...
            'pca_parallel_eigencoeffs:File %s already exists. %s', ...
            eig_coeff_fn, 'SKIPPING!');

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    eig_coeff_fn = sprintf('%s_%d_%d.em', eig_coeff_fn_prefix, iteration, ...
        process_idx);

    if exist(fullfile(pwd(), eig_coeff_fn), 'file') == 2
        warning('subTOM:recoverOnFail', ...
            'pca_parallel_eigencoeffs:File %s already exists. %s', ...
            eig_coeff_fn, 'SKIPPING!');

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    %##########################################################################%
    %                          CHECK IF BATCH NECESSARY                        %
    %##########################################################################%
    if (use_fast || use_eig_vec) && (process_idx > 1)
        warning('subTOM:skipCalculationWarning', ...
            'pca_parallel_eigencoeffs:%s and %s %s', ...
            'use_fast', 'use_eig_vec', ...
            'only require a single process. SKIPPING!');

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    %##########################################################################%
    %                                USE_EIG_VEC                               %
    %##########################################################################%
    if use_eig_vec
        eig_vec_fn = sprintf('%s_%d.em', eig_vec_fn_prefix, iteration);

        if exist(fullfile(pwd(), eig_vec_fn), 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'pca_parallel_eigencoeffs:File %s does not exist.', ...
                    eig_vec_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        eig_vec = getfield(tom_emread(eig_vec_fn), 'Value');

        eig_coeff_fn = sprintf('%s_%d.em' , eig_coeff_fn_prefix, iteration);
        tom_emwrite(eig_coeff_fn, eig_vec);
        check_em_file(eig_coeff_fn, eig_vec);
        return
    end

    %##########################################################################%
    %                                  USE_FAST                                %
    %##########################################################################%
    if use_fast
        eig_vec_fn = sprintf('%s_%d.em', eig_vec_fn_prefix, iteration);

        if exist(fullfile(pwd(), eig_vec_fn), 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'pca_parallel_eigencoeffs:File %s does not exist.', ...
                    eig_vec_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        eig_vec = getfield(tom_emread(eig_vec_fn), 'Value');

        eig_val_fn = sprintf('%s_%d.em', eig_val_fn_prefix, iteration);

        if exist(fullfile(pwd(), eig_val_fn), 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'pca_parallel_eigencoeffs:File %s does not exist.', ...
                    eig_val_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        eig_val = getfield(tom_emread(eig_val_fn), 'Value');

        if size(eig_vec, 2) ~= size(eig_val, 1)
            try
                error('subTOM:volDimError', ...
                    'pca_parallel_eigencoeffs:%s and %s %s.', ...
                    eig_vec_fn, eig_val_fn, ...
                    'are incompatible for multiplication');
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        if min(eig_val(:)) < 0
            warning('subTOM:EigenValueWarning', ...
                'pca_parallel_eigencoeffs: %s %s.', ...
                'Negative Eigen values discovered,', ...
                'maybe try do_algebraic or pca_svd');
            [msg, msg_id] = lastwarn;
            fprintf(2, '%s - %s\n', msg_id, msg);
        end

        eig_coeff = eig_vec * diag(sqrt(abs(eig_val)));
        eig_coeff_fn = sprintf('%s_%d.em' , eig_coeff_fn_prefix, iteration);
        tom_emwrite(eig_coeff_fn, eig_vec);
        check_em_file(eig_coeff_fn, eig_vec);
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
                'pca_parallel_eigencoeffs:File %s does not exist.', ...
                all_motl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl = getfield(tom_emread(all_motl_fn), 'Value');

    if size(all_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'pca_parallel_eigencoeffs:%s is not proper MOTL.', all_motl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Calculate the number and indices of particles to process
    num_ptcls = size(all_motl, 2);

    if num_xmatrix_batch > num_ptcls
        try
            error('subTOM:argumentError', ...
                'pca_parallel_eigencoeffs:num_xmatrix_batch is %s.', ...
                'greater than num_ptcls.');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    xmatrix_batch_size = floor(num_ptcls / num_xmatrix_batch);

    if process_idx > (num_ptcls - (xmatrix_batch_size * num_xmatrix_batch))
        ptcl_start_idx = (process_idx - 1) * xmatrix_batch_size + 1 + ...
            (num_ptcls - (xmatrix_batch_size * num_xmatrix_batch));

        ptcl_end_idx = ptcl_start_idx + xmatrix_batch_size - 1;
    else
        ptcl_start_idx = (process_idx - 1) * (xmatrix_batch_size + 1) + 1;
        ptcl_end_idx = ptcl_start_idx + xmatrix_batch_size;
    end
    
    batch_size = ptcl_end_idx - ptcl_start_idx + 1;

    % Get box size from first subtomogram weight
    weight_fn = sprintf('%s_%d.em', weight_fn_prefix, ...
        all_motl(tomo_row, ptcl_start_idx));

    if exist(fullfile(pwd(), weight_fn), 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'pca_parallel_eigencoeffs:File %s does not exist.', weight_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    check_fn = weight_fn;

    % Note the transpose, tom_reademheader returns a column vector, but Matlab
    % size function returns a row vector, and ones and zeros need row vector
    box_size = getfield(tom_reademheader(weight_fn), 'Header', 'Size')';

    % Read in classification mask
    if ~strcmpi(mask_fn, 'none')
        if exist(fullfile(pwd(), mask_fn), 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'pca_parallel_eigencoeffs:File %s does not exist.', ...
                    mask_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        mask = getfield(tom_emread(mask_fn), 'Value');

        if ~all(size(mask) == box_size)
            try
                error('subTOM:volDimError', ...
                    'pca_parallel_eigencoeffs:%s and %s are not same size.', ...
                    mask_fn, check_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end
    else
        % If no mask specified use a hard-coded spherical mask
        mask = tom_spheremask(ones(box_size), floor(box_size(1) * 0.4));
    end

    % Find the indices and  the number of voxels in the mask. The mask should be
    % all ones but in case it isn't we threshold it at 1e-6
    mask_idxs = mask > 1e-6;
    num_mask_vox = sum(mask_idxs(:));

    % Read in Eigen vectors header to get the number of Eigen coefficients
    eig_vec_fn = sprintf('%s_%d.em', eig_vec_fn_prefix, iteration);

    if exist(fullfile(pwd(), eig_vec_fn), 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'pca_parallel_eigencoeffs:File %s does not exist.', ...
                eig_vec_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    num_eigs = getfield(tom_reademheader(eig_vec_fn), 'Header', 'Size');
    num_eigs = num_eigs(2);

    % If we are going to scale the projections of the particles onto Eigen
    % volumes by their Eigen values we read in the Eigen values here.
    if use_eig_val
        eig_val_fn = sprintf('%s_%d.em', eig_val_fn_prefix, iteration);

        if exist(fullfile(pwd(), eig_val_fn), 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'pca_parallel_eigencoeffs:File %s does not exist.', ...
                    eig_val_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        eig_val = getfield(tom_emread(eig_val_fn), 'Value');

        if size(eig_val, 1) ~= num_eigs
            try
                error('subTOM:volDimError', ...
                    'pca_parallel_eigencoeffs:%s %s %s.', ...
                    eig_val_fn, ...
                    'does not have same number Eigen values as', eig_vec_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        if min(eig_val(:)) < 0
            warning('subTOM:EigenValueWarning', ...
                'pca_parallel_eigencoeffs: %s %s.', ...
                'Negative Eigen values discovered,', ...
                'maybe try do_algebraic or pca_svd');
            [msg, msg_id] = lastwarn;
            fprintf(2, '%s - %s\n', msg_id, msg);
        end
    end

    % Read in the X-Matrix batch (chunk) which is used to find the coefficients
    xmatrix_fn = sprintf('%s_%d_%d.em', xmatrix_fn_prefix, iteration, ...
        process_idx);

    if exist(fullfile(pwd(), xmatrix_fn), 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'pca_parallel_eigencoeffs:File %s does not exist.', ...
                xmatrix_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    xmatrix = getfield(tom_emread(xmatrix_fn), 'Value');

    % Make sure that the same mask was used here and to calculate X-Matrix
    if size(xmatrix, 1) ~= num_mask_vox
            try
                error('subTOM:volDimError', ...
                    'pca_parallel_eigencoeffs:%s %s %s.', ...
                    'The number of voxels in', xmatrix_fn, ...
                    'and under the mask are not same size.');
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
    elseif size(xmatrix, 2) ~= batch_size
            try
                error('subTOM:volDimError', ...
                    'pca_parallel_eigencoeffs:%s %s %s.', ...
                    'The number of particles in', xmatrix_fn, ...
                    'and specified by num_xmatrix_batch are not same size.');
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
    end
    
    % Create a cell array to load in all of the Eigen volumes
    eig_vols = cell(1, num_eigs);

    for eigen_idx = 1:num_eigs
        eig_vol_fn = sprintf('%s_%d_%d.em', eig_vol_fn_prefix, iteration, ...
            eigen_idx);

        if exist(fullfile(pwd(), eig_vol_fn), 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'pca_parallel_eigencoeffs:File %s does not exist.', ...
                    eig_vol_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        eig_vol = getfield(tom_emread(eig_vol_fn), 'Value');

        if ~all(size(eig_vol) == box_size)
            try
                error('subTOM:volDimError', ...
                    'pca_parallel_eigencoeffs:%s and %s are not same size.', ...
                    eig_vol_fn, check_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        eig_vols{eigen_idx} = eig_vol;
    end

    % Initialize the partial Eigen coefficients array
    eig_coeff = zeros(batch_size, num_eigs);

    % Some variables for showing progress
    delprog = '';
    prog_size = batch_size * num_eigs;
    delprog_batch = max(floor(prog_size / 200), 1);
    timings = [];
    tic;

    % Loop over batch
    xmatrix_idx = 1;
    weight_idx = 0;
    ptcl = zeros(box_size);
    for ptcl_idx = ptcl_start_idx:ptcl_end_idx
        % Create the particle from the X-Matrix
        ptcl(mask_idxs) = xmatrix(:, xmatrix_idx);

        % Perform n-fold symmetrization of the ptcl.
        if nfold ~= 1
            ptcl = tom_symref(ptcl, nfold);

            % We need to normalize the particle after symmetrizing under the
            % mask to a mean of zero and standard deviation of one.
            ptcl_mean = sum(ptcl(:)) / num_mask_vox;
            ptcl_stdv = sqrt((sum(sum(sum(ptcl .* ptcl))) / ...
                num_mask_vox) - (ptcl_mean ^ 2));

            ptcl = (ptcl - (mask .* ptcl_mean)) / ptcl_stdv;
        end

        % Read in particle weight
        if weight_idx ~= all_motl(tomo_row, ptcl_idx)
            weight_idx = all_motl(tomo_row, ptcl_idx);
            weight_fn = sprintf('%s_%d.em', weight_fn_prefix, ...
                all_motl(tomo_row, ptcl_idx));

            if exist(fullfile(pwd(), weight_fn), 'file') ~= 2
                try
                    error('subTOM:missingFileError', ...
                        'pca_parallel_eigencoeffs:File %s does not exist.', ...
                        weight_fn);
                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            weight_vol = getfield(tom_emread(weight_fn), 'Value');

            if ~all(size(weight_vol) == box_size)
                try
                    error('subTOM:volDimError', ...
                        'pca_parallel_eigencoeffs:%s and %s %s.', ...
                        weight_fn, check_fn, 'are not same size');
                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            % Perform n-fold symmetrization of the weight.
            if nfold ~= 1
                weight_vol = tom_symref(weight_vol, nfold);
            end
        end

        % Get the rotation to align the weight
        ptcl_rot = -all_motl([18, 17, 19], ptcl_idx);
        ptcl_weight = tom_rotate(weight_vol, ptcl_rot);

        % Calculate the coefficients
        for eigen_idx = 1:num_eigs
            eig_vol = real(ifftn(ifftshift(...
                fftshift(fftn(eig_vols{eigen_idx})) .* ptcl_weight)));

            % We need to normalize each Eigen volume under the mask to a mean of
            % zero and standard deviation of one.
            eig_vol_mean = sum(eig_vol(:)) / num_mask_vox;
            eig_vol_stdv = sqrt((sum(sum(sum(eig_vol .* eig_vol))) / ...
                num_mask_vox) - (eig_vol_mean ^ 2));

            eig_vol = (eig_vol - (mask .* eig_vol_mean)) / eig_vol_stdv;

            % Calculate the Cross-Correlation Coefficient in real-space since we
            % don't need to do any alignment.  Note that the division by
            % num_mask_vox is appropriate here because of the fact that the mean
            % is zero and the standard deviation is one.
            eig_coeff(xmatrix_idx, eigen_idx) = sum(sum(sum(...
                ptcl .* eig_vol))) / num_mask_vox;

            % If requested we scale the coefficient by the root of the Eigen
            % value
            if use_eig_val
                eig_coeff(xmatrix_idx, eigen_idx) = eig_coeff(xmatrix_idx, ...
                    eigen_idx) .* sqrt(1 / abs(eig_val(eigen_idx)));
            end

            % Display some output
            prog_idx = ((xmatrix_idx - 1) * num_eigs) + eigen_idx;

            if mod(prog_idx, delprog_batch) == 0
                elapsed_time = toc;
                timings = [timings elapsed_time];
                delprog = disp_progbar(process_idx, prog_size, prog_idx, ...
                    timings, delprog);

                tic;
            end
        end

        xmatrix_idx = xmatrix_idx + 1;
    end

    % Write out the coefficients
    eig_coeff_fn = sprintf('%s_%d_%d.em', eig_coeff_fn_prefix, iteration, ...
        process_idx);

    tom_emwrite(eig_coeff_fn, eig_coeff);
    check_em_file(eig_coeff_fn, eig_coeff);
end
