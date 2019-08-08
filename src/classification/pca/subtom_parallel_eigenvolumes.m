function subtom_parallel_eigenvolumes(varargin)
% SUBTOM_PARALLEL_EIGENVOLUMES computes projections of data onto eigenvectors.
%
%     SUBTOM_PARALLEL_EIGENVOLUMES(
%         'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX,
%         'ptcl_fn_prefix', PTCL_FN_PREFIX,
%         'eig_vec_fn_prefix', EIG_VEC_FN_PREFIX,
%         'eig_val_fn_prefix', EIG_VAL_FN_PREFIX,
%         'xmatrix_fn_prefix', XMATRIX_FN_PREFIX,
%         'eig_vol_fn_prefix', EIG_VOL_FN_PREFIX,
%         'mask_fn', MASK_FN,
%         'iteration', ITERATION,
%         'num_xmatrix_batch', NUM_XMATRIX_BATCH,
%         'process_idx', PROCESS_IDX)
%
%     Calculates the summed projections of particles onto previously determined
%     Eigen (or left singular) vectors, by means of an also previously
%     calculated X-matrix to produce Eigenvolumes which can then be used to
%     determine which vectors can best influence classification. The
%     Eigenvectors are named EIG_VEC_FN_PREFIX_ITERATION.em and the X-Matrix is
%     named as XMATRIX_FN_PREFIX_ITERATION_PROCESS_IDX.em. The Eigenvolumes are
%     also masked by the file specified by MASK_FN. The Eigenvolumes are split
%     into NUM_XMATRIX_BATCH sums, which is the same number of batches that the
%     X-Matrix was broken into in its computation. PROCESS_IDX is a counter that
%     designates the current batch being determined. The output sum Eigenvolume
%     will be written out as EIG_VOL_FN_PREFIX_ITERATION_#_PROCESS_IDX.em. where
%     the # is the particular Eigenvolume being written out.

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'all_motl_fn_prefix', 'combinedmotl/allmotl');
    addParameter(fn_parser, 'ptcl_fn_prefix', 'subtomograms/subtomo');
    addParameter(fn_parser, 'eig_vec_fn_prefix', 'pca/eigvec');
    addParameter(fn_parser, 'eig_val_fn_prefix', 'pca/eigval');
    addParameter(fn_parser, 'xmatrix_fn_prefix', 'pca/xmatrix');
    addParameter(fn_parser, 'eig_vol_fn_prefix', 'pca/eigvol');
    addParameter(fn_parser, 'mask_fn', 'none');
    addParameter(fn_parser, 'iteration', '1');
    addParameter(fn_parser, 'num_xmatrix_batch', 1);
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

    eig_vec_fn_prefix = fn_parser.Results.eig_vec_fn_prefix;
    [eig_vec_dir, ~, ~] = fileparts(eig_vec_fn_prefix);

    if ~isempty(eig_vec_dir) && exist(eig_vec_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_eigenvolumes:eig_vec_dir: Directory %s %s.', ...
                eig_vec_dir, 'does not exist');

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
                'parallel_eigenvolumes:eig_val_dir: Directory %s %s.', ...
                eig_val_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    xmatrix_fn_prefix = fn_parser.Results.xmatrix_fn_prefix;
    [xmatrix_dir, ~, ~] = fileparts(xmatrix_fn_prefix);

    if ~isempty(xmatrix_dir) && exist(xmatrix_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_eigenvolumes:xmatrix_dir: Directory %s %s.', ...
                xmatrix_dir, 'does not exist');

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
                'parallel_eigenvolumes:eig_vol_dir: Directory %s %s.', ...
                eig_vol_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    mask_fn = fn_parser.Results.mask_fn;

    if ~strcmp(mask_fn, 'none') && exist(mask_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_eigenvolumes:File %s does not exist.', mask_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    iteration = fn_parser.Results.iteration;

    if ischar(iteration)
        iteration = str2double(iteration);
    end

    try
        validateattributes(iteration, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer'}, ...
            'subtom_parallel_eigenvolumes', 'iteration');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    num_xmatrix_batch = fn_parser.Results.num_xmatrix_batch;

    if ischar(num_xmatrix_batch)
        num_xmatrix_batch = str2double(num_xmatrix_batch);
    end

    try
        validateattributes(num_xmatrix_batch, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0}, ...
            'subtom_parallel_eigenvolumes', 'num_xmatrix_batch');

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
            '<=', num_xmatrix_batch}, ...
            'subtom_parallel_eigenvolumes', 'process_idx');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Read in the Eigenvectors
    eig_vec_fn = sprintf('%s_%d.em', eig_vec_fn_prefix, iteration);

    if exist(eig_vec_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_eigenvolumes:File %s does not exist.', ...
                eig_vec_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    eigen_vectors = getfield(tom_emread(eig_vec_fn), 'Value');

    % We can get the number of particles and Eigenvolumes from the Eigenvectors
    num_ptcls = size(eigen_vectors, 1);
    num_eigs = size(eigen_vectors, 2);

    % Check if the calculation has already been done and skip if so.
    all_done = 1;

    for eigen_idx = 1:num_eigs
        eigen_volume_fn = sprintf('%s_%d_%d.em', eig_vol_fn_prefix, ...
            iteration, eigen_idx);

        if exist(eigen_volume_fn, 'file') ~= 2
            all_done = 0;
            break
        end
    end

    if all_done
        warning('subTOM:recoverOnFail', ...
            'parallel_eigenvolumes: All Files already exist. SKIPPING!');

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    all_done = 1;

    for eigen_idx = 1:num_eigs
        eigen_volume_fn = sprintf('%s_%d_%d_%d.em', eig_vol_fn_prefix, ...
            iteration, eigen_idx, process_idx);

        if exist(eigen_volume_fn, 'file') ~= 2
            all_done = 0;
            break
        end
    end

    if all_done
        warning('subTOM:recoverOnFail', ...
            'parallel_eigenvolumes: All Files already exist. SKIPPING!');

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Read in the X-Matrix chunk
    xmatrix_fn = sprintf('%s_%d_%d.em', xmatrix_fn_prefix, iteration, ...
        process_idx);

    if exist(xmatrix_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_eigenvolumes:File %s does not exist.', ...
                xmatrix_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    xmatrix = getfield(tom_emread(xmatrix_fn), 'Value');

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
                'parallel_eigenvolumes:%s %s.', xmatrix_fn, ...
                'is not the correct size for num_xmatrix_batch');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
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
    check_fn = sprintf('%s_%d.em', ptcl_fn_prefix, all_motl(4, ptcl_start_idx));

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

    % Read in classification mask
    if ~strcmpi(mask_fn, 'none')
        if exist(mask_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'parallel_eigenvolumes:File %s does not exist.', ...
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
                    'parallel_eigenvolumes:%s and %s %s.', ...
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
    num_voxels = sum(mask_idxs(:));

    if size(xmatrix, 1) ~= num_voxels
        try
            error('subTOM:volDimError', ...
                'parallel_eigenvolumes:%s %s.', xmatrix_fn, ...
                'is not the correct size for given mask');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if num_xmatrix_batch > num_ptcls
        try
            error('subTOM:argumentError', ...
                'parallel_eigenvolumes:num_xmatrix_batch is %s.', ...
                'greater than num_ptcls.');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Calculate the projection of the X-Matrix chunk onto the Eigenvectors
    eigen_volumes = xmatrix * eigen_vectors(ptcl_start_idx:ptcl_end_idx, :);

    % Read in the Eigenvalues.
    eig_val_fn = sprintf('%s_%d.em', eig_val_fn_prefix, iteration);

    if exist(eig_val_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_eigenvolumes:File %s does not exist.', ...
                eig_val_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    eigen_values = getfield(tom_emread(eig_val_fn), 'Value');
    
    if length(eigen_values) ~= num_eigs
        try
            error('subTOM:volDimError', ...
                'parallel_eigenvolumes:%s %s %s.', eig_val_fn, ...
                'is not the correct size for ', eig_vec_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % We are using the inverse root for the transition formula so warn about
    % negative Eigenvalues, which should not exist.
    if min(eigen_values(:)) < 0
        warning('subTOM:EigenValueWarning', ...
            'parallel_eigenvolumes: %s %s.', ...
            'Negative Eigen values discovered,', ...
            'maybe try do_algebraic or subtom_svds');

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
    end

    % The transition formula intermediate (V * sqrt(L^-1));
    transition_temp = eigen_vectors * diag(sqrt(1 ./ abs(eigen_values)));

    % Initialize the conjugate space Eigenvectors.
    % The transition formula is: U = X * V * sqrt(L^-1)
    % Where X is the X-Matrix, V is the image space Eigenvectors and L is the
    % diagonal matrix of Eigenvalues.
    eigen_vectors_ = zeros(num_voxels, num_eigs);

    % Setup the progress bar
    delprog = '';
    timings = [];
    message = sprintf('Eigenvolume Sums Batch %d', process_idx);
    op_type = 'volumes';
    tic;

    % Place the Eigenvolumes from X-Matrix form into volumes and write them out.
    for eigen_idx = 1:num_eigs
        eigen_volume = zeros(box_size);
        eigen_volume(mask_idxs) = eigen_volumes(:, eigen_idx);
        eigen_volume_fn = sprintf('%s_%d_%d_%d.em', eig_vol_fn_prefix, ...
            iteration, eigen_idx, process_idx);

        tom_emwrite(eigen_volume_fn, eigen_volume);
        subtom_check_em_file(eigen_volume_fn, eigen_volume);

        batch_idx = 1;

        for ptcl_idx = ptcl_start_idx:ptcl_end_idx

            % Ugh this is hideous. Store at least a shorter name for the value.
            % transition_temp_value = ttv.
            ttv  = transition_temp(ptcl_idx, eigen_idx);

            % Eigen_vectors_ column = ev_c.
            ev_c = arrayfun(@(x) xmatrix(x, batch_idx) * ttv, 1:num_voxels)';

            % From the transition formula we have that:
            % U_{i,j} = \sum_{n = 1}^{N} X_{i, n} * (V * sqrt(L^-1))_{n, j}
            % Where N is the number of particles. Since we are dealing with a
            % subset of particles we only have n from ptcl_start_idx to
            % ptcl_end_idx, but we can get a subset of the final cumulative sum
            % for each entry of U and then in join_eigenvolume we can add
            % all of these together for the final conjugate (pixel-vector) space
            % Eigenvectors.
            eigen_vectors_(:, eigen_idx) = eigen_vectors_(:, eigen_idx) + ev_c;
            batch_idx = batch_idx + 1;
        end

        % Display some output
        [delprog, timings] = subtom_display_progress(delprog, timings, ...
            message, op_type, num_eigs, eigen_idx);

    end

    % Write out the partial conjugate space Eigenvectors
    eig_vec_fn_ = sprintf('%s_conjugate_%d_%d.em', eig_vec_fn_prefix, ...
        iteration, process_idx);

    tom_emwrite(eig_vec_fn_, eigen_vectors_);
    subtom_check_em_file(eig_vec_fn_, eigen_vectors_);
end
