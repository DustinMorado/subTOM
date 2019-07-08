function pca_weighted_eigenvolumes(eig_vec_fn_prefix, ...
    xmatrix_weight_fn_prefix, eig_vol_fn_prefix, mask_fn, iteration, ...
    num_xmatrix_batch)
% PCA_WEIGHTED_EIGENVOLUMES computes projections of X-matrix onto eigenvectors.
%     PCA_WEIGHTED_EIGENVOLUMES(
%         EIG_VEC_FN_PREFIX,
%         XMATRIX_WEIGHT_FN_PREFIX,
%         EIG_VOL_FN_PREFIX,
%         MASK_FN,
%         ITERATION,
%         NUM_XMATRIX_BATCH)
%
%     Calculates the weighted averages of previously calculated Eigenvolume
%     partial sums, (projections onto previously determined Eigen (or left
%     singular) vectors), which can then be used to determine which vectors can
%     best influence classification.  The Eigenvectors are named
%     EIG_VEC_FN_PREFIX_ITERATION.em and are used just to determine the number
%     of particles to reweight the average.  The previously calculated X-matrix
%     weights are specified by XMATRIX_WEIGHT_FN_PREFIX are used to reweight the
%     output Eigenvolumes for the missing wedge and other effects. The
%     Eigenvolumes are also masked by the file given in MASK_FN. The
%     Eigenvolumes are expected to have been split into NUM_XMATRIX_BATCH sums.
%     The output averages will be written out as
%     EIG_VOL_FN_PREFIX_ITERATION_#.em. where the # is the particular
%     Eigenvolume being written out. For easier viewing a montage of the
%     Eigenvolumes is made along the X, Y, and Z axes, written out as
%     EIG_VOL_FN_PREFIX_{X,Y,Z}_ITERATION.em
%
% Example:
%     PCA_WEIGHTED_EIGENVOLUMES('pca/eigvec', 'pca/xmatrix_wei, 'pca/eigvol', 
%         'otherinputs/pca_mask.em', 1, 256)
%
%     Would calculate partial eigenvolume sums, the 1st out of 256, from the
%     projection of the particles described in 'pca/xmatrix_1_1.em' and the
%     eigenvectors 'pca/eigvec_1.em'. The file 'pca/xmatrix_wei_1_1.em' will be
%     used to determine the size of the Eigenvolumes, and the mask
%     'otherinputs/pca_mask.em' is intrinsically applied to the Eigenvolumes, by
%     how the X-matrix is constructed of only voxels that lie within the mask.
%     The partial sum would be written out as 'pca/eigvol_1_1.em'.
%
% See also PCA_PARALLEL_EIGENVOLUMES

% DRM 03-2019
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% eig_vec_fn_prefix = 'pca/eigvec';
% xmatrix_weight_fn_prefix = 'pca/xmatrix_wei';
% eig_vol_fn_prefix = 'pca/eigvol';
% mask_fn = 'otherinputs/pca_mask.em';
% iteration = 1;
% num_xmatrix_batch = 256;
%##############################################################################%
    % Evaluate numeric inputs
    if ischar(iteration)
        iteration = str2double(iteration);
    end

    if isnan(iteration) || rem(iteration, 1) ~= 0
        try
            error('subTOM:argumentError', ...
                'pca_weighted_eigenvolumes:iteration: argument invalid');
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
                'pca_weighted_eigenvolumes:num_xmatrix_batch: %s', ...
                'argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Read in the Eigenvectors
    eig_vec_fn = sprintf('%s_%d.em', eig_vec_fn_prefix, iteration);

    if exist(fullfile(pwd(), eig_vec_fn), 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'pca_weighted_eigenvolumes:File %s does not exist.', ...
                eig_vec_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    eig_vecs = getfield(tom_emread(eig_vec_fn), 'Value');

    % We can get the number of particles from the Eigenvectors
    num_ptcls = size(eig_vecs, 1);
    num_eigs = size(eig_vecs, 2);

    %##########################################################################%
    %                         CHECK IF ALREADY CALCULATED                      %
    %##########################################################################%
    for eigen_idx = 1:num_eigs
        eigen_volume_fn = sprintf('%s_%d_%d.em', eig_vol_fn_prefix, ...
            iteration, eigen_idx);

        if exist(fullfile(pwd(), eigen_volume_fn), 'file') == 2
            warning('subTOM:recoverOnFail', ...
                'pca_weighted_eigenvolumes:File %s already exists. %s', ...
                eigen_volume_fn, 'SKIPPING!');

            [msg, msg_id] = lastwarn;
            fprintf(2, '%s - %s\n', msg_id, msg);
            all_exist = 1;
        else
            all_exist = 0;
            break
        end
    end

    if all_exist
        warning('subTOM:recoverOnFail', ...
            'pca_weighted_eigenvolumes: All Files already exist. SKIPPING!');

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Run the first batch of the weight sum outside of a loop to initialize
    % volumes without having to know the box size of weights
    xmatrix_weight_fn = sprintf('%s_%d_1.em', xmatrix_weight_fn_prefix, ...
        iteration);

    if exist(fullfile(pwd(), xmatrix_weight_fn), 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'pca_weighted_eigenvolumes:File %s does not exist.', ...
                xmatrix_weight_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    weight_sum = getfield(tom_emread(xmatrix_weight_fn), 'Value');
    check_fn = xmatrix_weight_fn;

    % Get the size of the weight volume, which for the first is assumed correct.
    box_size = size(weight_sum);

    % Read in classification mask
    if ~strcmpi(mask_fn, 'none')
        if exist(fullfile(pwd(), mask_fn), 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'pca_weighted_eigenvolumes:File %s does not exist.', ...
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
                    'pca_weighted_eigenvolumes:%s and %s %s.', ...
                    mask_fn, check_fn, 'are not same size');
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end
    else
        % If no mask specified use a hard-coded spherical mask
        mask = tom_spheremask(ones(box_size), floor(box_size(1) * 0.4));
    end

    % Loop over the batches and calculate the weight average
    for batch_idx = 2:num_xmatrix_batch
        xmatrix_weight_fn = sprintf('%s_%d_%d.em', xmatrix_weight_fn_prefix, ...
            iteration, batch_idx);

        if exist(fullfile(pwd(), xmatrix_weight_fn), 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'pca_weighted_eigenvolumes:File %s does not exist.', ...
                    xmatrix_weight_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        xmatrix_weight = getfield(tom_emread(xmatrix_weight_fn), 'Value');

        if ~all(size(xmatrix_weight) == box_size)
            try
                error('subTOM:volDimError', ...
                    'pca_weighted_eigenvolumes:%s and %s %s.', ...
                    xmatrix_weight_fn, check_fn, 'are not same size');
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        weight_sum = weight_sum + xmatrix_weight;
    end

    % Calculate the average weight from batches
    weight_average = weight_sum ./ num_ptcls;
    weight_average = weight_average ./ max(weight_average(:));

    % Calculate the average weight inverse that will reweight the average
    weight_average_inverse = 1 ./ weight_average;

    % Find any inf (Infinity) values in the inverse and set them to zero
    inf_idxs = find(weight_average_inverse > 10000);
    if ~isempty(inf_idxs)
        weight_average_inverse(inf_idxs) = 0;
    end

    % Some variables for showing progress
    delprog = '';
    prog_size = num_eigs * num_xmatrix_batch;
    delprog_batch = max(floor(prog_size / 200), 1);
    timings = [];
    tic;

    % Loop over the Eigenvolumes
    for eigen_idx = 1:num_eigs
        % Run the first batch outside of a loop to initialize volumes without
        % having to know the box size of particles and weights
        eig_vol_fn = sprintf('%s_%d_%d_1.em', eig_vol_fn_prefix, iteration, ...
            eigen_idx);

        if exist(fullfile(pwd(), eig_vol_fn), 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'pca_weighted_eigenvolumes:File %s does not exist.', ...
                    eig_vol_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        avg_sum = getfield(tom_emread(eig_vol_fn), 'Value');

        if ~all(size(avg_sum) == box_size)
            try
                error('subTOM:volDimError', ...
                    'pca_weighted_eigenvolumes:%s and %s %s.', ...
                    eig_vol_fn, check_fn, 'are not same size');
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        % Display some output
        prog_idx = ((eigen_idx - 1) * num_xmatrix_batch) + 1;

        if mod(prog_idx, delprog_batch) == 0
            elapsed_time = toc;
            timings = [timings elapsed_time];
            delprog = disp_progbar(prog_size, prog_idx, timings, delprog);
            tic;
        end

        % Sum the remaining batch files
        for batch_idx = 2:num_xmatrix_batch
            eig_vol_fn = sprintf('%s_%d_%d_%d.em', eig_vol_fn_prefix, ...
                iteration, eigen_idx, batch_idx);

            if exist(fullfile(pwd(), eig_vol_fn), 'file') ~= 2
                try
                    error('subTOM:missingFileError', ...
                        'pca_weighted_eigenvolumes:File %s does not exist.', ...
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
                        'pca_weighted_eigenvolumes:%s and %s %s.', ...
                        eig_vol_fn, check_fn, 'are not same size');
                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            avg_sum = avg_sum + eig_vol;

            % Display some output
            prog_idx = ((eigen_idx - 1) * num_xmatrix_batch) + batch_idx;

            if mod(prog_idx, delprog_batch) == 0
                elapsed_time = toc;
                timings = [timings elapsed_time];
                delprog = disp_progbar(prog_size, prog_idx, timings, delprog);
                tic;
            end
        end

        % Determine low pass filter dimensions, this filter takes out the last
        % few high frequency pixels, which dampens interpolation artefacts from
        % rotations etc.
        spheremask_radius = floor(box_size(1) / 2) - 3;

        % Calculate the raw average from batches
        average_raw = avg_sum ./ num_ptcls;

        % Apply the weight to the average
        average_fft = fftshift(fftn(average_raw));
        average_fft = average_fft .* weight_average_inverse;
        average_fft = tom_spheremask(average_fft, spheremask_radius);
        average = real(ifftn(ifftshift(average_fft)));

        % Write-out the raw average from batches
        average_raw_fn = sprintf('%s_debug_raw_%d_%d.em', eig_vol_fn_prefix, ...
            iteration, eigen_idx);

        % The averages come out for some reason inverted in contrast so just
        % make it black density on white background.
        tom_emwrite(average_raw_fn, average .* mask .* -1);
        check_em_file(average_raw_fn, average .* mask .* -1);

        % Write-out the weighted average
        average_fn = sprintf('%s_%d_%d.em', eig_vol_fn_prefix, iteration, ...
            eigen_idx);

        % The averages come out for some reason inverted in contrast so just
        % make it black density on white background.
        tom_emwrite(average_fn, average .* mask .* -1);
        check_em_file(average_fn, average .* mask .* -1);
    end

    % Write-out the average weight from batches
    weight_average_fn = sprintf('%s_debug_%d.em', xmatrix_weight_fn_prefix, ...
        iteration);

    tom_emwrite(weight_average_fn, weight_average);
    check_em_file(weight_average_fn, weight_average);

    % Write-out the average weight inverse that will reweight the average
    weight_average_inverse_fn = sprintf('%s_debug_inv_%d.em', ...
        xmatrix_weight_fn_prefix, iteration);

    tom_emwrite(weight_average_inverse_fn, weight_average_inverse);
    check_em_file(weight_average_inverse_fn, weight_average_inverse);

    % Write out montages of the Eigenvolumes which is very useful for
    % visualization
    num_cols = 10;
    num_rows = ceil(num_eigs / num_cols);

    % We do a montage in X, Y, and Z orientations
    for montage_idx = 1:3
        montage = zeros(box_size(1) * num_cols, box_size(2) * num_rows, ...
            box_size(3));

        for eigen_idx = 1:num_eigs
            row_idx = floor((eigen_idx - 1) / num_cols) + 1;
            col_idx = eigen_idx - ((row_idx - 1) * num_cols);
            start_x = (col_idx - 1) * box_size(1) + 1;
            end_x = start_x + box_size(1) - 1;
            start_y = (row_idx - 1) * box_size(2) + 1;
            end_y = start_y + box_size(2) - 1;
            
            if montage_idx == 1
                montage(start_x:end_x, start_y:end_y, :) = ...
                    getfield(tom_emread(sprintf('%s_%d_%d.em', ...
                    eig_vol_fn_prefix, iteration, eigen_idx)), 'Value');
            elseif montage_idx == 2
                montage(start_x:end_x, start_y:end_y, :) = ...
                    tom_rotate(getfield(tom_emread(sprintf('%s_%d_%d.em', ...
                    eig_vol_fn_prefix, iteration, eigen_idx)), 'Value'), ...
                    [0, 0, -90]);
            elseif montage_idx == 3
                montage(start_x:end_x, start_y:end_y, :) = ...
                    tom_rotate(getfield(tom_emread(sprintf('%s_%d_%d.em', ...
                    eig_vol_fn_prefix, iteration, eigen_idx)), 'Value'), ...
                    [90, 0, -90]);
            end
        end

        if montage_idx == 1
            montage_fn = sprintf('%s_Z_%d.em', eig_vol_fn_prefix, iteration);
        elseif montage_idx == 2
            montage_fn = sprintf('%s_X_%d.em', eig_vol_fn_prefix, iteration);
        elseif montage_idx == 3
            montage_fn = sprintf('%s_Y_%d.em', eig_vol_fn_prefix, iteration);
        end

        tom_emwrite(montage_fn, montage);
        check_em_file(montage_fn, montage);
    end
end
