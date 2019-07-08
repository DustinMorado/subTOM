function pca_parallel_eigenvolumes(eig_vec_fn_prefix, xmatrix_fn_prefix, ...
    xmatrix_weight_fn_prefix, eig_vol_fn_prefix, mask_fn, iteration, ...
    num_xmatrix_batch, process_idx)
% PCA_PARALLEL_EIGENVOLUMES computes projections of X-matrix onto eigenvectors.
%     PCA_PARALLEL_EIGENVOLUMES(
%         EIG_VEC_FN_PREFIX,
%         XMATRIX_FN_PREFIX,
%         XMATRIX_WEIGHT_FN_PREFIX,
%         EIG_VOL_FN_PREFIX,
%         MASK_FN,
%         ITERATION,
%         NUM_XMATRIX_BATCH,
%         PROCESS_IDX)
%
%     Calculates the summed projections of particles onto previously determined
%     Eigen (or left singular) vectors, by means of an also previously
%     calculated X-matrix to produce Eigenvolumes which can then be used to
%     determine which vectors can best influence classification. The
%     Eigenvectors are named EIG_VEC_FN_PREFIX_ITERATION.em and the X-Matrix is
%     named as XMATRIX_FN_PREFIX_ITERATION_PROCESS_IDX.em. The previously
%     calculated X-matrix weights are specified by XMATRIX_WEIGHT_FN_PREFIX are
%     used soley to determine size of the output Eigenvolumes. The Eigenvolumes
%     are also masked by the file specified by MASK_FN. The Eigenvolumes are
%     split into NUM_XMATRIX_BATCH sums, which is the same number of batches
%     that the X-Matrix was broken into in its computation. PROCESS_IDX is a
%     counter that designates the current batch being determined. The output sum
%     Eigenvolume will be written out as
%     EIG_VOL_FN_PREFIX_ITERATION_#_PROCESS_IDX.em. where the # is the
%     particular Eigenvolume being written out.
%
% Example:
%     PCA_PARALLEL_EIGENVOLUMES('pca/eigvec', 'pca/xmatrix', 'pca/xmatrix_wei,
%         'pca/eigvol', 'otherinputs/pca_mask.em', 1, 256, 1)
%
%     Would calculate partial eigenvolume sums, the 1st out of 256, from the
%     projection of the particles described in 'pca/xmatrix_1_1.em' and the
%     eigenvectors 'pca/eigvec_1.em'. The file 'pca/xmatrix_wei_1_1.em' will be
%     used to determine the size of the Eigenvolumes, and the mask
%     'otherinputs/pca_mask.em' is intrinsically applied to the Eigenvolumes, by
%     how the X-matrix is constructed of only voxels that lie within the mask.
%     The partial sum would be written out as 'pca/eigvol_1_1.em'.
%
% See also PCA_WEIGHTED_EIGENVOLUME

% DRM 03-2019
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% eig_vec_fn_prefix = 'pca/eigvec';
% xmatrix_fn_prefix = 'pca/xmatrix';
% xmatrix_weight_fn_prefix = 'pca/xmatrix_wei';
% eig_vol_fn_prefix = 'pca/eigvol';
% mask_fn = 'otherinputs/pca_mask.em';
% iteration = 1;
% num_xmatrix_batch = 256;
% process_idx = 1;
%##############################################################################%
    % Evaluate numeric inputs
    if ischar(iteration)
        iteration = str2double(iteration);
    end

    if isnan(iteration) || rem(iteration, 1) ~= 0
        try
            error('subTOM:argumentError', ...
                'pca_parallel_eigenvolumes:iteration: argument invalid');
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
                'pca_parallel_eigenvolumes:num_xmatrix_batch: %s', ...
                'argument invalid');
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
                'pca_parallel_eigenvolumes:process_idx: argument invalid');
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
                'pca_parallel_eigenvolumes:File %s does not exist.', ...
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
        eigen_volume_fn = sprintf('%s_%d_%d_%d.em', eig_vol_fn_prefix, ...
            iteration, eigen_idx, process_idx);

        if exist(fullfile(pwd(), eigen_volume_fn), 'file') == 2
            warning('subTOM:recoverOnFail', ...
                'pca_parallel_eigenvolumes:File %s already exists. %s', ...
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
            'pca_parallel_eigenvolumes: All Files already exist. SKIPPING!');

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Read in the X-Matrix chunk
    xmatrix_fn = sprintf('%s_%d_%d.em', xmatrix_fn_prefix, iteration, ...
        process_idx);

    if exist(fullfile(pwd(), xmatrix_fn), 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'pca_parallel_eigenvolumes:File %s does not exist.', ...
                xmatrix_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    xmatrix = getfield(tom_emread(xmatrix_fn), 'Value');

    % Read in the X-Matrix weight chunk to get the box size for the output
    xmatrix_weight_fn = sprintf('%s_%d_%d.em', xmatrix_weight_fn_prefix, ...
        iteration, process_idx);

    if exist(fullfile(pwd(), xmatrix_weight_fn), 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'pca_parallel_eigenvolumes:File %s does not exist.', ...
                xmatrix_weight_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    check_fn = xmatrix_weight_fn;

    % Note the transpose, tom_reademheader returns a column vector, but Matlab
    % size function returns a row vector, and ones and zeros need row vector
    box_size = getfield(tom_reademheader(xmatrix_weight_fn), 'Header', 'Size')';

    % Read in classification mask
    if ~strcmpi(mask_fn, 'none')
        if exist(fullfile(pwd(), mask_fn), 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'pca_parallel_eigenvolumes:File %s does not exist.', ...
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
                    'pca_parallel_eigenvolumes:%s and %s %s.', ...
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

    % Find the indices of the voxels in the mask. The mask should be
    % all ones but in case it isn't we threshold it at 1e-6
    mask_idxs = mask > 1e-6;

    if num_xmatrix_batch > num_ptcls
        try
            error('subTOM:argumentError', ...
                'pca_parallel_eigenvolumes:num_xmatrix_batch is %s.', ...
                'greater than num_ptcls.');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Calculate the number and indices of particles to process
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

    if size(xmatrix, 2) ~= batch_size
        try
            error('subTOM:volDimError', ...
                'pca_parallel_eigenvolumes:%s %s.', xmatrix_fn, ...
                'is not the correct size for num_xmatrix_batch');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Calculate the projection of the X-Matrix chunk onto the Eigenvectors
    eigen_volumes = xmatrix * eig_vecs(ptcl_start_idx:ptcl_end_idx, :);

    % Some variables for showing progress
    delprog = '';
    delprog_batch = max(floor(num_eigs / 200), 1);
    timings = [];
    tic;

    % Place the Eigenvolumes from X-Matrix form into volumes and write them out.
    for eigen_idx = 1:num_eigs
        eigen_volume = zeros(box_size);
        eigen_volume(mask_idxs) = eigen_volumes(:, eigen_idx);
        eigen_volume_fn = sprintf('%s_%d_%d_%d.em', eig_vol_fn_prefix, ...
            iteration, eigen_idx, process_idx);

        tom_emwrite(eigen_volume_fn, eigen_volume);
        check_em_file(eigen_volume_fn, eigen_volume);

        % Display some output
        if mod(eigen_idx, delprog_batch) == 0
            elapsed_time = toc;
            timings = [timings elapsed_time];
            delprog = disp_progbar(process_idx, num_eigs, eigen_idx, ...
                timings, delprog);
            tic;
        end
    end
end
