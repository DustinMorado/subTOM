function subtom_svds(varargin)
% SUBTOM_SVDS uses MATLAB svds to calculate a subset of singular values/vectors.
%
%     SUBTOM_SVDS(
%         'ccmatrix_fn_prefix', CCMATRIX_FN_PREFIX,
%         'eig_vec_fn_prefix', EIG_VEC_FN_PREFIX,
%         'eig_val_fn_prefix', EIG_VAL_FN_PREFIX,
%         'iteration', ITERATION,
%         'num_svs', NUM_SVS,
%         'svds_iterations', SVDS_ITERATIONS,
%         'svds_tolerance', SVDS_TOLERANCE)
%
%     Uses the MATLAB function svds to calculate a subset of singular values and
%     vectors given the constrained cross-correlation (covariance) matrix
%     with the filename CCMATRIX_FN_PREFIX_ITERATION.em. NUM_SVS of the largest
%     singular values and vectors will be calculated, and will be written out
%     to EIG_VAL_FN_PREFIX_ITERATION.em and EIG_VEC_FN_PREFIX_ITERATION.em
%     respectively. Two options SVDS_ITERATIONS and SVDS_TOLERANCE are also
%     available to tune how svds is run. If the string 'default' is given for
%     either the default values in eigs will be used.

% DRM 02-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'ccmatrix_fn_prefix', 'pca/ccmatrix');
    addParameter(fn_parser, 'eig_vec_fn_prefix', 'pca/eigvec');
    addParameter(fn_parser, 'eig_val_fn_prefix', 'pca/eigval');
    addParameter(fn_parser, 'iteration', 1);
    addParameter(fn_parser, 'num_svs', 40);
    addParameter(fn_parser, 'svds_iterations', 'default');
    addParameter(fn_parser, 'svds_tolerance', 'default');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    ccmatrix_fn_prefix = fn_parser.Results.ccmatrix_fn_prefix;
    [ccmatrix_dir, ~, ~] = fileparts(ccmatrix_fn_prefix);

    if ~isempty(ccmatrix_dir) && exist(ccmatrix_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'svds:ccmatrix_dir: Directory %s %s.', ...
                ccmatrix_dir, 'does not exist');

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
                'svds:eig_vec_dir: Directory %s %s.', ...
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
                'svds:eig_val_dir: Directory %s %s.', ...
                eig_val_dir, 'does not exist');

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
            {'scalar', 'nonnan', 'positive', 'integer'}, ...
            'subtom_eigs', 'iteration');

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
            {'scalar', 'nonnan', 'positive', 'integer'}, ...
            'subtom_eigs', 'num_svs');

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
            'subtom_svds', 'svds_iterations');

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
            'subtom_svds', 'svds_tolerance');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Check if the calculation has already been done and skip if so.
    eig_vec_fn = sprintf('%s_%d.em', eig_vec_fn_prefix, iteration);
    eig_val_fn = sprintf('%s_%d.em', eig_val_fn_prefix, iteration);

    if exist(eig_vec_fn, 'file') == 2 && exist(eig_val_fn, 'file') == 2
        warning('subTOM:recoverOnFail', ...
            'svds:File %s already exists. SKIPPING!', eig_vec_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Read in the ccmatrix
    ccmatrix_fn = sprintf('%s_%d.em', ccmatrix_fn_prefix, iteration);

    if exist(ccmatrix_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'svds:File %s does not exist.', ccmatrix_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    ccmatrix = getfield(tom_emread(ccmatrix_fn), 'Value');

    if size(ccmatrix, 1) ~= size(ccmatrix, 2)
        try
            error('subTOM:argumentError', ...
                'svds:ccmatrix_fn: Matrix given is not square!');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Calculate the Singular Value Decomposition of the ccmatrix
    [eig_vec, eig_val, ~] = svds(ccmatrix, num_svs, 'largest', ...
        struct('tol', svds_tolerance, 'maxit', svds_iterations));

    % Write out the Eigenvectors and Eigenvalues
    tom_emwrite(eig_vec_fn, eig_vec);
    subtom_check_em_file(eig_vec_fn, eig_vec);

    eig_val = diag(eig_val);
    tom_emwrite(eig_val_fn, eig_val);
    subtom_check_em_file(eig_val_fn, eig_val);
end
