function subtom_join_eigenvolumes(varargin)
% SUBTOM_JOIN_EIGENVOLUMES computes projections of data onto eigenvectors.
%
%     SUBTOM_JOIN_EIGENVOLUMES(
%         'eig_vec_fn_prefix', EIG_VEC_FN_PREFIX,
%         'eig_vol_fn_prefix', EIG_VOL_FN_PREFIX,
%         'mask_fn', MASK_FN,
%         'iteration', ITERATION,
%         'num_xmatrix_batch', NUM_XMATRIX_BATCH)
%
%     Calculates the sum of previously calculated Eigenvolume
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

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'eig_vec_fn_prefix', 'pca/eigvec');
    addParameter(fn_parser, 'eig_vol_fn_prefix', 'pca/eigvol');
    addParameter(fn_parser, 'mask_fn', 'none');
    addParameter(fn_parser, 'iteration', '1');
    addParameter(fn_parser, 'num_xmatrix_batch', 1);
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    eig_vec_fn_prefix = fn_parser.Results.eig_vec_fn_prefix;
    [eig_vec_dir, ~, ~] = fileparts(eig_vec_fn_prefix);

    if ~isempty(eig_vec_dir) && exist(eig_vec_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'join_eigenvolumes:eig_vec_dir: Directory %s %s.', ...
                eig_vec_dir, 'does not exist');

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
                'join_eigenvolumes:eig_vol_dir: Directory %s %s.', ...
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
                'join_eigenvolumes:File %s does not exist.', mask_fn);

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
            'subtom_join_eigenvolumes', 'iteration');

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
            'subtom_join_eigenvolumes', 'num_xmatrix_batch');

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
                'join_eigenvolumes:File %s does not exist.', ...
                eig_vec_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    eig_vecs = getfield(tom_emread(eig_vec_fn), 'Value');

    % We can get the number of particles and Eigenvolumes from the Eigenvectors
    num_ptcls = size(eig_vecs, 1);
    num_eigs = size(eig_vecs, 2);

    % Check if the calculation has already been done and skip if so.
    all_done = 1;

    for eigen_idx = 1:num_eigs
        eig_vol_fn = sprintf('%s_%d_%d.em', eig_vol_fn_prefix, ...
            iteration, eigen_idx);

        if exist(eig_vol_fn, 'file') ~= 2
            all_done = 0;
            break
        end
    end

    if all_done
        warning('subTOM:recoverOnFail', ...
            'join_eigenvolumes: All Files already exist. SKIPPING!');

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Run the first batch of the first Eigenvolume to get the box size.
    check_fn = sprintf('%s_%d_1_1.em', eig_vol_fn_prefix, iteration);

    if exist(check_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'join_eigenvolumes:File %s does not exist.', ...
                check_fn);

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
                    'join_eigenvolumes:File %s does not exist.', ...
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
                    'join_eigenvolumes:%s and %s %s.', ...
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

    % Find the number of voxels passed by the mask which we need to initialize
    % the conjugate space Eigenvectors. The mask should be all ones but in case
    % it isn't we threshold it at 1e-6
    mask_idxs = mask > 1e-6;
    num_voxels = sum(mask_idxs(:));

    % Initialize the conjugate space Eigenvectors matrix
    full_eigen_vectors_ = zeros(num_voxels, num_eigs);
    full_eigen_volumes = zeros(num_voxels, num_eigs);

    % Loop over the batches and calculate the conjugate space Eigenvectors.
    for batch_idx = 1:num_xmatrix_batch
        eig_vec_fn_ = sprintf('%s_conjugate_%d_%d.em', eig_vec_fn_prefix, ...
            iteration, batch_idx);

        if exist(eig_vec_fn_, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'join_eigenvolumes:File %s does not exist.', ...
                    eig_vec_fn_);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        eigen_vectors_ = getfield(tom_emread(eig_vec_fn_), 'Value');

        if ~all(size(eigen_vectors_) == [num_voxels, num_eigs])
            try
                error('subTOM:volDimError', ...
                    'join_eigenvolumes:%s is not the correct size.', ...
                    eig_vec_fn_);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        full_eigen_vectors_ = full_eigen_vectors_ + eigen_vectors_;
    end

    % Setup the progress bar
    delprog = '';
    timings = [];
    message = sprintf('Joining Eigenvolumes');
    num_prog_batch = num_eigs * num_xmatrix_batch;
    op_type = 'batches';
    tic;

    % Loop over the Eigenvolumes
    for eigen_idx = 1:num_eigs

        % Initialize the raw sum average.
        full_eigen_volume = zeros(box_size);

        % Sum the batch files
        for batch_idx = 1:num_xmatrix_batch
            eig_vol_fn = sprintf('%s_%d_%d_%d.em', eig_vol_fn_prefix, ...
                iteration, eigen_idx, batch_idx);

            if exist(eig_vol_fn, 'file') ~= 2
                try
                    error('subTOM:missingFileError', ...
                        'join_eigenvolumes:File %s does not exist.', ...
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
                        'join_eigenvolumes:%s and %s %s.', ...
                        eig_vol_fn, check_fn, 'are not same size');

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            full_eigen_volume = full_eigen_volume + eigen_volume;
            full_eigen_volumes(:, eigen_idx) = full_eigen_volume(mask_idxs);

            % Display some output
            prog_idx = (eigen_idx - 1) * num_xmatrix_batch + batch_idx;
            [delprog, timings] = subtom_display_progress(delprog, timings, ...
                message, op_type, num_prog_batch, prog_idx);

        end

        % Write-out the Eigenvolume
        eig_vol_fn = sprintf('%s_%d_%d.em', eig_vol_fn_prefix, iteration, ...
            eigen_idx);

        % I am applying the mask here in case someone gives a softmask, in
        % practice I should be able to skip that product since I only pass the
        % masked indices to the x-matrix, but I think that would confuse the
        % user if they saw that result after passing a soft mask.
        full_eigen_volume = full_eigen_volume .* mask;

        tom_emwrite(eig_vol_fn, full_eigen_volume);
        subtom_check_em_file(eig_vol_fn, full_eigen_volume);

        % We can technically write out the conjugate space Eigenvectors, so why
        % not?
        eigen_vector_volume_ = zeros(box_size);
        eigen_vector_volume_(mask_idxs) = full_eigen_vectors_(:, eigen_idx);
        eigen_vector_volume_ = eigen_vector_volume_ .* mask;

        eig_vec_vol_fn_ = sprintf('%s_conjugate_vol_%d_%d.em', ...
            eig_vec_fn_prefix, iteration, eigen_idx);

        tom_emwrite(eig_vec_vol_fn_, eigen_vector_volume_);
        subtom_check_em_file(eig_vec_vol_fn_, eigen_vector_volume_);
    end

    % Write-out the conjugate space Eigenvectors.
    full_eig_vec_fn_ = sprintf('%s_conjugate_%d.em', eig_vec_fn_prefix, ...
        iteration);

    tom_emwrite(full_eig_vec_fn_, full_eigen_vectors_);
    subtom_check_em_file(full_eig_vec_fn_, full_eigen_vectors_);

    % Write-out the Eigenvolumes matrix
    full_eig_vol_fn = sprintf('%s_%d.em', eig_vol_fn_prefix, ...
        iteration);

    tom_emwrite(full_eig_vol_fn, full_eigen_volumes);
    subtom_check_em_file(full_eig_vol_fn, full_eigen_volumes);

    % Write out montages of the Eigenvolumes and conjugate space Eigenvector
    % volumes which is very useful for visualization
    num_cols = 10;
    num_rows = ceil(num_eigs / num_cols);

    % We do a montage in X, Y, and Z orientations
    for montage_idx = 1:3
        montage = zeros(box_size(1) * num_cols, box_size(2) * num_rows, ...
            box_size(3));

        montage_ = zeros(box_size(1) * num_cols, box_size(2) * num_rows, ...
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

                montage_(start_x:end_x, start_y:end_y, :) = ...
                    getfield(tom_emread(sprintf('%s_conjugate_vol_%d_%d.em', ...
                    eig_vec_fn_prefix, iteration, eigen_idx)), 'Value');

            elseif montage_idx == 2
                montage(start_x:end_x, start_y:end_y, :) = ...
                    tom_rotate(getfield(tom_emread(sprintf('%s_%d_%d.em', ...
                    eig_vol_fn_prefix, iteration, eigen_idx)), 'Value'), ...
                    [0, 0, -90]);

                montage_(start_x:end_x, start_y:end_y, :) = ...
                    tom_rotate(getfield(tom_emread(sprintf(...
                    '%s_conjugate_vol_%d_%d.em', eig_vec_fn_prefix, ...
                    iteration, eigen_idx)), 'Value'), [0, 0, -90]);

            elseif montage_idx == 3
                montage(start_x:end_x, start_y:end_y, :) = ...
                    tom_rotate(getfield(tom_emread(sprintf('%s_%d_%d.em', ...
                    eig_vol_fn_prefix, iteration, eigen_idx)), 'Value'), ...
                    [90, 0, -90]);

                montage_(start_x:end_x, start_y:end_y, :) = ...
                    tom_rotate(getfield(tom_emread(sprintf(...
                    '%s_conjugate_vol_%d_%d.em', eig_vec_fn_prefix, ...
                    iteration, eigen_idx)), 'Value'), [90, 0, -90]);

            end
        end

        if montage_idx == 1
            montage_fn = sprintf('%s_Z_%d.em', eig_vol_fn_prefix, iteration);
            montage_fn_ = sprintf('%s_conjugate_vol_Z_%d.em', ...
                eig_vec_fn_prefix, iteration);

        elseif montage_idx == 2
            montage_fn = sprintf('%s_X_%d.em', eig_vol_fn_prefix, iteration);
            montage_fn_ = sprintf('%s_conjugate_vol_X_%d.em', ...
                eig_vec_fn_prefix, iteration);

        elseif montage_idx == 3
            montage_fn = sprintf('%s_Y_%d.em', eig_vol_fn_prefix, iteration);
            montage_fn_ = sprintf('%s_conjugate_vol_Y_%d.em', ...
                eig_vec_fn_prefix, iteration);

        end

        tom_emwrite(montage_fn, montage);
        subtom_check_em_file(montage_fn, montage);
        tom_emwrite(montage_fn_, montage_);
        subtom_check_em_file(montage_fn_, montage_);
    end
end
