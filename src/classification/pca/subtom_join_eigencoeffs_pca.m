function subtom_join_eigencoeffs_pca(varargin)
% SUBTOM_JOIN_EIGENCOEFFS_PCA combines chunks of coefficients into final matrix.
%
%     SUBTOM_JOIN_EIGENCOEFFS_PCA(
%         'eig_coeff_fn_prefix', EIG_COEFF_FN_PREFIX,
%         'iteration', ITERATION,
%         'num_coeff_batch', NUM_COEFF_BATCH)
%
%     Looks for partial chunks of the low-rank approximation coefficients of
%     projected particles with the file name EIG_COEFF_FN_PREFIX_ITERATION_#.em
%     where # is from 1 to NUM_COEFF_BATCH, and combines them into a final
%     matrix of coefficients written out as EIG_COEFF_FN_PREFIX_ITERATION.em.

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'eig_coeff_fn_prefix', 'class/eigcoeff_pca');
    addParameter(fn_parser, 'iteration', 1);
    addParameter(fn_parser, 'num_coeff_batch', 1);
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    eig_coeff_fn_prefix = fn_parser.Results.eig_coeff_fn_prefix;
    [eig_coeff_dir, ~, ~] = fileparts(eig_coeff_fn_prefix);

    if ~isempty(eig_coeff_dir) && exist(eig_coeff_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'join_eigencoeffs_pca:eig_coeff_dir: Directory %s %s.', ...
                eig_coeff_dir, 'does not exist');

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
            'subtom_join_eigencoeffs_pca', 'iteration');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    num_coeff_batch = fn_parser.Results.num_coeff_batch;

    if ischar(num_coeff_batch)
        num_coeff_batch = str2double(num_coeff_batch);
    end

    try
        validateattributes(num_coeff_batch, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0}, ...
            'subtom_join_eigencoeffs_pca', 'num_coeff_batch');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Check if the calculation has already been done and skip if so.
    eig_coeff_fn = sprintf('%s_%d.em', eig_coeff_fn_prefix, iteration);

    if exist(eig_coeff_fn, 'file') == 2
        warning('subTOM:recoverOnFail', ...
            'join_eigencoeffs_pca:File %s already exists. SKIPPING!', ...
            eig_coeff_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    check_fn = sprintf('%s_%d_1.em', eig_coeff_fn_prefix, iteration);

    if exist(check_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'join_eigencoeffs_pca:File %s does not exist.', check_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    batch_dims = getfield(tom_reademheader(check_fn), 'Header', 'Size');
    full_eigen_coeffs_size = batch_dims(1);
    num_eigs = batch_dims(2);

    for batch_idx = 2:num_coeff_batch
        eig_coeff_fn = sprintf('%s_%d_%d.em', eig_coeff_fn_prefix, ...
            iteration, batch_idx);

        if exist(eig_coeff_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'join_eigencoeffs_pca:File %s does not exist.', ...
                    eig_coeff_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        batch_dims = getfield(tom_reademheader(eig_coeff_fn), 'Header', 'Size');

        if batch_dims(2) ~= num_eigs
            try
                error('subTOM:volDimError', ...
                    'join_eigencoeffs_pca:%s and %s are not same size.', ...
                    eig_coeff_fn, check_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME)
            end
        end

        full_eigen_coeffs_size = full_eigen_coeffs_size + batch_dims(1);
    end

    full_eigen_coeffs = zeros(full_eigen_coeffs_size, num_eigs);
    start_idx = 1;

    % Setup the progress bar
    delprog = '';
    timings = [];
    message = sprintf('Joining Eigencoefficients');
    op_type = 'batches';
    tic;

    for batch_idx = 1:num_coeff_batch
        eig_coeff_fn = sprintf('%s_%d_%d.em', eig_coeff_fn_prefix, ...
            iteration, batch_idx);

        if exist(eig_coeff_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'join_eigencoeffs_pca:File %s does not exist.', ...
                    eig_coeff_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        eigen_coeffs = getfield(tom_emread(eig_coeff_fn), 'Value');
        batch_size = size(eigen_coeffs, 1);
        end_idx = start_idx + batch_size - 1;
        full_eigen_coeffs(start_idx:end_idx, :) = eigen_coeffs;
        start_idx = start_idx + batch_size;

        % Display some output
        [delprog, timings] = subtom_display_progress(delprog, timings, ...
            message, op_type, num_coeff_batch, batch_idx);

    end

    eig_coeff_fn = sprintf('%s_%d.em', eig_coeff_fn_prefix, iteration);
    tom_emwrite(eig_coeff_fn, full_eigen_coeffs);
    subtom_check_em_file(eig_coeff_fn, full_eigen_coeffs);
end
