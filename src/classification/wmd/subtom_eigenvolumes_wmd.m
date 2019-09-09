function subtom_eigenvolumes_wmd(varargin)
% SUBTOM_EIGENVOLUMES_WMD computes projections of data onto eigenvectors.
%
%     SUBTOM_PARALLEL_EIGENVOLUMES_WMD(
%         'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX,
%         'ptcl_fn_prefix', PTCL_FN_PREFIX,
%         'dmatrix_fn_prefix', DMATRIX_FN_PREFIX,
%         'eig_val_fn_prefix', EIG_VAL_FN_PREFIX,
%         'eig_vol_fn_prefix', EIG_VOL_FN_PREFIX,
%         'variance_fn_prefix', VARIANCE_FN_PREFIX,
%         'mask_fn', MASK_FN,
%         'iteration', ITERATION,
%         'num_svs', NUM_SVS,
%         'svds_iterations', SVDS_ITERATIONS,
%         'svds_tolerance', SVDS_TOLERANCE)
%
%     Calculates NUM_SVS weighted projections of wedge-masked differences onto
%     the same number of determined Right-Singular Vectors, by means of the
%     Singular Value Decomposition of a previously calculated D-matrix, named as
%     DMATRIX_FN_PREFIX_ITERATION.em to produce Eigenvolumes which can then be
%     used to determine which vectors can best influence classification.  The
%     Eigenvolumes are also masked by the file specified by MASK_FN. The output
%     weighted Eigenvolume will be written out as
%     EIG_VOL_FN_PREFIX_ITERATION_#.em, where the # is the particular
%     Eigenvolume being written out. The calculated Eigenvalues which correspond
%     to the square of the singular vectors are also written oun as
%     EIG_VAL_FN_PREFIX_ITERATION.em, and the variance map of the data is
%     written out as VARIANCE_FN_PREFIX_ITERATION.em.  Two options
%     SVDS_ITERATIONS and SVDS_TOLERANCE are also available to tune how svds is
%     run. If the string 'default' is given for either the default values in
%     svds will be used.

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
    addParameter(fn_parser, 'dmatrix_fn_prefix', 'class/dmatrix_wmd');
    addParameter(fn_parser, 'eig_val_fn_prefix', 'class/eigval_wmd');
    addParameter(fn_parser, 'eig_vol_fn_prefix', 'class/eigvol_wmd');
    addParameter(fn_parser, 'variance_fn_prefix', 'class/variance_wmd');
    addParameter(fn_parser, 'mask_fn', 'none');
    addParameter(fn_parser, 'iteration', '1');
    addParameter(fn_parser, 'num_svs', 40);
    addParameter(fn_parser, 'svds_iterations', 'default');
    addParameter(fn_parser, 'svds_tolerance', 'default');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    all_motl_fn_prefix = fn_parser.Results.all_motl_fn_prefix;
    [all_motl_dir, ~, ~] = fileparts(all_motl_fn_prefix);

    if ~isempty(all_motl_dir) && exist(all_motl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'eigenvolumes_wmd:all_motl_dir: Directory %s %s.', ...
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
                'eigenvolumes_wmd:ptcl_dir: Directory %s %s.', ...
                ptcl_dir, 'does not exist');

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
                'eigenvolumes_wmd:dmatrix_dir: Directory %s %s.', ...
                dmatrix_dir, 'does not exist');

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
                'eigenvolumes_wmd:eig_val_dir: Directory %s %s.', ...
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
                'eigenvolumes_wmd:eig_vol_dir: Directory %s %s.', ...
                eig_vol_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    variance_fn_prefix = fn_parser.Results.variance_fn_prefix;
    [variance_dir, ~, ~] = fileparts(variance_fn_prefix);

    if ~isempty(variance_dir) && exist(variance_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'eigenvolumes_wmd:variance_dir: Directory %s %s.', ...
                variance_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    mask_fn = fn_parser.Results.mask_fn;

    if ~strcmp(mask_fn, 'none') && exist(mask_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'eigenvolumes_wmd:File %s does not exist.', mask_fn);

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
            'subtom_eigenvolumes_wmd', 'iteration');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    num_svs = fn_parser.Results.num_svs;

    if ischar(num_svs)
        num_svs = str2double(num_svs);
    end

    try
        validateattributes(num_svs, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0}, ...
            'subtom_eigenvolumes_wmd', 'num_svs');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    svds_iterations = fn_parser.Results.svds_iterations;

    if ischar(svds_iterations) && ~strcmpi(svds_iterations, 'default') 
        svds_iterations = str2double(svds_iterations);
    elseif strcmpi(svds_iterations, 'default')
        svds_iterations = 100;
    end

    try
        validateattributes(svds_iterations, {'numeric'}, ...
            {'scalar', 'nonnan', 'positive', 'integer'}, ...
            'subtom_eigenvolumes_wmd', 'svds_iterations');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    svds_tolerance = fn_parser.Results.svds_tolerance;

    if ischar(svds_tolerance) && ~strcmpi(svds_tolerance, 'default') 
        svds_tolerance = str2double(svds_tolerance);
    elseif strcmpi(svds_tolerance, 'default')
        svds_tolerance = 1e-10;
    end

    try
        validateattributes(svds_tolerance, {'numeric'}, ...
            {'scalar', 'nonnan', 'positive'}, ...
            'subtom_eigenvolumes_wmd', 'svds_tolerance');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Check if the calculation has already been done and skip if so.
    all_done = 1;

    for sv_idx = 1:num_svs
        eigen_volume_fn = sprintf('%s_%d_%d.em', eig_vol_fn_prefix, ...
            iteration, sv_idx);

        if exist(eigen_volume_fn, 'file') ~= 2
            all_done = 0;
            break
        end
    end

    if all_done
        warning('subTOM:recoverOnFail', ...
            'eigenvolumes_wmd: All Files already exist. SKIPPING!');

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Read in the D-Matrix
    dmatrix_fn = sprintf('%s_%d.em', dmatrix_fn_prefix, iteration);

    if exist(dmatrix_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'eigenvolumes_wmd:File %s does not exist.', dmatrix_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    dmatrix = getfield(tom_emread(dmatrix_fn), 'Value');
    num_voxels = size(dmatrix, 1);
    num_ptcls = size(dmatrix, 2);

    % Calculate the Singular Value Decomposition of the D-Matrix as described in
    % the Heumann 11' paper.
    [U, S, V] = svds(dmatrix, num_svs, 'largest', ...
        struct('tol', svds_tolerance, 'maxit', svds_iterations));

    % From here we calculate the D-Matrix coeffcients SV' which corresponds to
    % equation (5) in the Borland 90' paper where N = I_n and S = L^0.5. We need
    % to transpose the coefficients so that they are in the form in MATLAB's
    % clustering functions where rows correspond to observations (wedge-masked
    % differences) and columns correspond to variables.
    dmatrix_coeffs = (S * V')';

    % We write these coefficients out.
    dmatrix_coeffs_fn = sprintf('%s_coeffs_%d.em', dmatrix_fn_prefix, ...
        iteration);

    tom_emwrite(dmatrix_coeffs_fn, dmatrix_coeffs);
    subtom_check_em_file(dmatrix_coeffs_fn, dmatrix_coeffs);

    % We use equation (11) of the Borland 90' paper to calculate the
    % Eigenvolumes, where S^-1 = L^-0.5.

    % We have to convert S into a linear array and then calculate the inverse to
    % avoid dividing by zero, and then we convert back into diagonal matrix.
    S_inverse = diag(1 ./ diag(S));

    eigen_volumes = dmatrix * dmatrix_coeffs * S_inverse;

    % Read in all_motl file
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(all_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'eigenvolumes_wmd:File %s does not exist.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl = getfield(tom_emread(all_motl_fn), 'Value');

    if size(all_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'eigenvolumes_wmd:%s is not proper MOTL.', all_motl_fn);

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
                'eigenvolumes_wmd:File %s does not exist.', check_fn);

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
                    'eigenvolumes_wmd:File %s does not exist.', ...
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
                    'eigenvolumes_wmd:%s and %s %s.', ...
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
                'eigenvolumes_wmd:%s %s.', dmatrix_fn, ...
                'is not the correct size for given mask');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Place the Eigenvolumes from D-Matrix form into volumes and write them out.
    for sv_idx = 1:num_svs
        eigen_volume = zeros(box_size);
        eigen_volume(mask_idxs) = eigen_volumes(:, sv_idx);
        eig_vol_fn = sprintf('%s_%d_%d.em', eig_vol_fn_prefix, ...
            iteration, sv_idx);

        tom_emwrite(eig_vol_fn, eigen_volume);
        subtom_check_em_file(eig_vol_fn, eigen_volume);
    end

    % Write out the Eigenvalues L, where L = S.^2
    eigen_vals = diag(S).^2;
    eig_val_fn = sprintf('%s_%d.em', eig_val_fn_prefix, iteration);
    tom_emwrite(eig_val_fn, eigen_vals);
    subtom_check_em_file(eig_val_fn, eigen_vals);

    % Write out the corrected variance as described in Table 1 in the Heumann
    % 11' paper.
    US2 = U * (S.^2);
    variance_array = arrayfun(@(voxel) ...
        (US2(voxel, :) * U(voxel, :)') ./ (num_ptcls - 1), 1:num_voxels);

    variance_volume = ones(box_size) .* mean(variance_array(:));
    variance_volume(mask_idxs) = variance_array;
    variance_fn = sprintf('%s_%d.em', variance_fn_prefix, iteration);
    tom_emwrite(variance_fn, variance_volume);
    subtom_check_em_file(variance_fn, variance_volume);

    % Write out montages of the Eigenvolumes which is very useful for
    % visualization
    num_cols = 10;
    num_rows = ceil(num_svs / num_cols);

    % We do a montage in X, Y, and Z orientations
    for montage_idx = 1:3
        montage = zeros(box_size(1) * num_cols, box_size(2) * num_rows, ...
            box_size(3));

        for sv_idx = 1:num_svs
            row_idx = floor((sv_idx - 1) / num_cols) + 1;
            col_idx = sv_idx - ((row_idx - 1) * num_cols);
            start_x = (col_idx - 1) * box_size(1) + 1;
            end_x = start_x + box_size(1) - 1;
            start_y = (row_idx - 1) * box_size(2) + 1;
            end_y = start_y + box_size(2) - 1;
            
            if montage_idx == 1
                montage(start_x:end_x, start_y:end_y, :) = ...
                    getfield(tom_emread(sprintf('%s_%d_%d.em', ...
                    eig_vol_fn_prefix, iteration, sv_idx)), 'Value');

            elseif montage_idx == 2
                montage(start_x:end_x, start_y:end_y, :) = ...
                    tom_rotate(getfield(tom_emread(sprintf('%s_%d_%d.em', ...
                    eig_vol_fn_prefix, iteration, sv_idx)), 'Value'), ...
                    [0, 0, -90]);

            elseif montage_idx == 3
                montage(start_x:end_x, start_y:end_y, :) = ...
                    tom_rotate(getfield(tom_emread(sprintf('%s_%d_%d.em', ...
                    eig_vol_fn_prefix, iteration, sv_idx)), 'Value'), ...
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
