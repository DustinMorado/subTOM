function subtom_eigenvolumes_msa(varargin)
% SUBTOM_EIGENVOLUMES_MSA computes projections of data onto Eigenvectors.
%
%     SUBTOM_EIGENVOLUMES_MSA(
%         'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX,
%         'ptcl_fn_prefix', PTCL_FN_PREFIX,
%         'eig_vec_fn_prefix', EIG_VEC_FN_PREFIX,
%         'eig_val_fn_prefix', EIG_VAL_FN_PREFIX,
%         'xmatrix_fn_prefix', XMATRIX_FN_PREFIX,
%         'eig_vol_fn_prefix', EIG_VOL_FN_PREFIX,
%         'mask_fn', MASK_FN,
%         'iteration', ITERATION,
%         'num_eigs', NUM_EIGS,
%         'eigs_iterations', EIGS_ITERATIONS,
%         'eigs_tolerance', EIGS_TOLERANCE)
%
%     Calculates NUM_EIGS weighted projections of particles onto the same number
%     of determined Eigenvectors, by means of a previously calculated X-matrix,
%     named as XMATRIX_FN_PREFIX_ITERATION.em to produce Eigenvolumes which can
%     then be used to determine which vectors can best influence classification.
%     The Eigenvectors and Eigenvalues are also written out as
%     EIG_VEC_FN_PREFIX_ITERATION.em and EIG_VAL_FN_PREFIX_ITERATION.em The
%     Eigenvolumes are also masked by the file specified by MASK_FN.  The output
%     weighted Eigenvolume will be written out as
%     EIG_VOL_FN_PREFIX_ITERATION_#.em. where the # is the particular
%     Eigenvolume being written out. Two options EIGS_ITERATIONS and
%     EIGS_TOLERANCE are also available to tune how eigs is run. If the string
%     'default' is given for either the default values in eigs will be used.

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
    addParameter(fn_parser, 'eig_vec_fn_prefix', 'class/eigvec_msa');
    addParameter(fn_parser, 'eig_val_fn_prefix', 'class/eigval_msa');
    addParameter(fn_parser, 'xmatrix_fn_prefix', 'class/xmatrix_msa');
    addParameter(fn_parser, 'eig_vol_fn_prefix', 'class/eigvol_msa');
    addParameter(fn_parser, 'mask_fn', 'none');
    addParameter(fn_parser, 'iteration', '1');
    addParameter(fn_parser, 'num_eigs', 40);
    addParameter(fn_parser, 'eigs_iterations', 'default');
    addParameter(fn_parser, 'eigs_tolerance', 'default');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    all_motl_fn_prefix = fn_parser.Results.all_motl_fn_prefix;
    [all_motl_dir, ~, ~] = fileparts(all_motl_fn_prefix);

    if ~isempty(all_motl_dir) && exist(all_motl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'eigenvolumes_msa:all_motl_dir: Directory %s %s.', ...
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
                'eigenvolumes_msa:ptcl_dir: Directory %s %s.', ...
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
                'eigenvolumes_msa:eig_vec_dir: Directory %s %s.', ...
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
                'eigenvolumes_msa:eig_val_dir: Directory %s %s.', ...
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
                'eigenvolumes_msa:xmatrix_dir: Directory %s %s.', ...
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
                'eigenvolumes_msa:eig_vol_dir: Directory %s %s.', ...
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
                'eigenvolumes_msa:File %s does not exist.', mask_fn);

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
            'subtom_eigenvolumes_msa', 'iteration');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    num_eigs = fn_parser.Results.num_eigs;

    if ischar(num_eigs)
        num_eigs = str2double(num_eigs);
    end

    try
        validateattributes(num_eigs, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0}, ...
            'subtom_eigenvolumes_msa', 'num_eigs');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    eigs_iterations = fn_parser.Results.eigs_iterations;

    if ischar(eigs_iterations) && ~strcmpi(eigs_iterations, 'default') 
        eigs_iterations = str2double(eigs_iterations);
    elseif strcmpi(eigs_iterations, 'default')
        eigs_iterations = 300;
    end

    try
        validateattributes(eigs_iterations, {'numeric'}, ...
            {'scalar', 'nonnan', 'positive', 'integer'}, ...
            'subtom_eigenvolumes_msa', 'eigs_iterations');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    eigs_tolerance = fn_parser.Results.eigs_tolerance;

    if ischar(eigs_tolerance) && ~strcmpi(eigs_tolerance, 'default') 
        eigs_tolerance = str2double(eigs_tolerance);
    elseif strcmpi(eigs_tolerance, 'default')
        eigs_tolerance = eps;
    end

    try
        validateattributes(eigs_tolerance, {'numeric'}, ...
            {'scalar', 'nonnan', 'positive'}, ...
            'subtom_eigenvolumes_msa', 'eigs_tolerance');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

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
            'eigenvolumes_msa: All Files already exist. SKIPPING!');

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Read in the X-Matrix
    xmatrix_fn = sprintf('%s_%d.em', xmatrix_fn_prefix, iteration);

    if exist(xmatrix_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'eigenvolumes_msa:File %s does not exist.', xmatrix_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    xmatrix = getfield(tom_emread(xmatrix_fn), 'Value');
    num_voxels = size(xmatrix, 1);
    num_ptcls = size(xmatrix, 2);

    % Create particle weights. This is the N-Matrix in the Borland 90' paper.
    n_diag = arrayfun(@(x) 1 ./ sqrt(sum(xmatrix(:, x).^2)), 1:num_ptcls);
    n_matrix = spdiags(n_diag', 0, num_ptcls, num_ptcls);

    % Create pixel-vector weights. This is the M-Matrix in the same paper.
    m_diag = arrayfun(@(x) 1 ./ sqrt(sum(xmatrix(x, :).^2)), 1:num_voxels);
    m_matrix = spdiags(m_diag', 0, num_voxels, num_voxels);

    % Calculate the initial Eigenvectors and Eigenvalues. This is equation (2)
    % from the same paper (except that our form of X has been transposed):
    %
    % X' * M * X * N * V = V * L
    [eigen_vecs, eigen_vals] = eigs(...
        (xmatrix' * m_matrix * xmatrix * n_matrix), num_eigs, 'lm', ...
        struct('isreal', 1, 'issym', 1, 'tol', eigs_tolerance, ...
        'maxit', eigs_iterations));

    % Orthonormalize the Eigenvectors V under the constraint:
    %
    % V' * N * V = I
    eigen_vecs = spdiags(1 ./ sqrt(spdiags(n_matrix, 0)), ...
        0, num_ptcls, num_ptcls) * eigen_vecs;

    % We only need the diagonal of the Eigenvalues matrix
    eigen_vals = diag(eigen_vals);

    % Calculate the Eigenvolumes in matrix form using the formula
    %
    % Eigenvolumes = M * X * N * V
    eigen_volumes = m_matrix * xmatrix * n_matrix * eigen_vecs;

    % Read in all_motl file
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(all_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'eigenvolumes_msa:File %s does not exist.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl = getfield(tom_emread(all_motl_fn), 'Value');

    if size(all_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'eigenvolumes_msa:%s is not proper MOTL.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Get box size from first subtomogram
    check_fn = sprintf('%s_%d.em', ptcl_fn_prefix, all_motl(4, 1));

    if exist(check_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'eigenvolumes_msa:File %s does not exist.', check_fn);

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
                    'eigenvolumes_msa:File %s does not exist.', ...
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
                    'eigenvolumes_msa:%s and %s %s.', ...
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

    if sum(mask_idxs(:)) ~= num_voxels
        try
            error('subTOM:volDimError', ...
                'eigenvolumes_msa:%s %s.', xmatrix_fn, ...
                'is not the correct size for given mask');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Place the Eigenvolumes from X-Matrix form into volumes and write them out.
    for eigen_idx = 1:num_eigs
        eigen_volume = zeros(box_size);
        eigen_volume(mask_idxs) = eigen_volumes(:, eigen_idx);
        eig_vol_fn = sprintf('%s_%d_%d.em', eig_vol_fn_prefix, ...
            iteration, eigen_idx);

        tom_emwrite(eig_vol_fn, eigen_volume);
        subtom_check_em_file(eig_vol_fn, eigen_volume);
    end

    % Write out the Eigenvectors V, and the Eigenvalues L.
    eig_vec_fn = sprintf('%s_%d.em', eig_vec_fn_prefix, iteration);
    tom_emwrite(eig_vec_fn, eigen_vecs);
    subtom_check_em_file(eig_vec_fn, eigen_vecs);

    eig_val_fn = sprintf('%s_%d.em', eig_val_fn_prefix, iteration);
    tom_emwrite(eig_val_fn, eigen_vals);
    subtom_check_em_file(eig_val_fn, eigen_vals);

    % Write out montages of the Eigenvolumes which is very useful for
    % visualization
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
        subtom_check_em_file(montage_fn, montage);
    end
end
