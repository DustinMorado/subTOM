function subtom_eigs(varargin)
% SUBTOM_EIGS uses MATLAB eigs to calculate a subset of eigenvalue/vectors.
%
%     SUBTOM_EIGS(
%         'ccmatrix_fn_prefix', CCMATRIX_FN_PREFIX,
%         'eig_vec_fn_prefix', EIG_VEC_FN_PREFIX,
%         'eig_val_fn_prefix', EIG_VAL_FN_PREFIX,
%         'iteration', ITERATION,
%         'num_eigs', NUM_EIGS,
%         'eigs_iterations', EIGS_ITERATIONS,
%         'eigs_tolerance', EIGS_TOLERANCE,
%         'do_algebraic', DO_ALGEBRAIC)
%
%     Uses the MATLAB function eigs to calculate a subset of eigenvalues and
%     eigenvectors given the constrained cross-correlation (covariance) matrix
%     with the filename CCMATRIX_FN_PREFIX_ITERATION.em. NUM_EIGS of the largest
%     eigenvalues and eigenvectors will be calculated, and will be written out
%     to EIG_VAL_FN_PREFIX_ITERATION.em and EIG_VEC_FN_PREFIX_ITERATION.em
%     respectively. Two options EIGS_ITERATIONS and EIGS_TOLERANCE are also
%     available to tune how eigs is run. If the string 'default' is given for
%     either the default values in eigs will be used. If DO_ALGEBRAIC evaluates
%     to true as a boolean 'la' will be used in place of 'lm' in the call to
%     eigs, this could be a valid option in the case when 'lm' returns negative
%     eigenvalues.

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'ccmatrix_fn_prefix', 'class/ccmatrix_pca');
    addParameter(fn_parser, 'eig_vec_fn_prefix', 'class/eigvec_pca');
    addParameter(fn_parser, 'eig_val_fn_prefix', 'class/eigval_pca');
    addParameter(fn_parser, 'iteration', 1);
    addParameter(fn_parser, 'num_eigs', 40);
    addParameter(fn_parser, 'eigs_iterations', 'default');
    addParameter(fn_parser, 'eigs_tolerance', 'default');
    addParameter(fn_parser, 'do_algebraic', 0);
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    ccmatrix_fn_prefix = fn_parser.Results.ccmatrix_fn_prefix;
    [ccmatrix_dir, ~, ~] = fileparts(ccmatrix_fn_prefix);

    if ~isempty(ccmatrix_dir) && exist(ccmatrix_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'eigs:ccmatrix_dir: Directory %s %s.', ...
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
                'eigs:eig_vec_dir: Directory %s %s.', ...
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
                'eigs:eig_val_dir: Directory %s %s.', ...
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

    num_eigs = fn_parser.Results.num_eigs;

    if ischar(num_eigs)
        num_eigs = str2double(num_eigs);
    end

    try
        validateattributes(num_eigs, {'numeric'}, ...
            {'scalar', 'nonnan', 'positive', 'integer'}, ...
            'subtom_eigs', 'num_eigs');

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
            'subtom_eigs', 'eigs_iterations');

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
            'subtom_eigs', 'eigs_tolerance');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    do_algebraic = fn_parser.Results.do_algebraic;

    if ischar(do_algebraic)
        do_algebraic = str2double(do_algebraic);
    end

    try
        validateattributes(do_algebraic, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_eigs', 'do_algebraic');

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
            'eigs:File %s already exists. SKIPPING!', eig_vec_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Read in the ccmatrix
    ccmatrix_fn = sprintf('%s_%d.em', ccmatrix_fn_prefix, iteration);

    if exist(ccmatrix_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'eigs:File %s does not exist.', ccmatrix_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    ccmatrix = getfield(tom_emread(ccmatrix_fn), 'Value');

    if size(ccmatrix, 1) ~= size(ccmatrix, 2)
        try
            error('subTOM:argumentError', ...
                'eigs:ccmatrix_fn: Matrix given is not square!');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Calculate the Eigen decomposition of the ccmatrix
    % Since we know that the ccmatrix is real symmetric we set options to
    % let Matlab know this.
    if do_algebraic
        [eig_vec, eig_val] = eigs(ccmatrix, num_eigs, 'la', ...
            struct('isreal', 1, 'issym', 1, 'tol', eigs_tolerance, ...
            'maxit', eigs_iterations));

    else
        [eig_vec, eig_val] = eigs(ccmatrix, num_eigs, 'lm', ...
            struct('isreal', 1, 'issym', 1, 'tol', eigs_tolerance, ...
            'maxit', eigs_iterations));

    end

    % It turns out that MATLAB doesn't sort the eigenvalues by largest magnitude
    % so we have to go through a bit of a mess to sort it out here.
    eig_val = diag(eig_val);
    [~, sort_idxs] = sort(abs(eig_val), 'descend');
    sorted_eig_vec = eig_vec(:, sort_idxs);
    sorted_eig_val = eig_val(sort_idxs);

    if min(sorted_eig_val(:)) < 0
        warning('subTOM:EigenValueWarning', ...
            'eigs: %s.', ...
            'Negative Eigen values determined, try do_algebraic or subtom_svd');

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
    end

    % Write out the Eigenvectors and Eigenvalues
    tom_emwrite(eig_vec_fn, sorted_eig_vec);
    subtom_check_em_file(eig_vec_fn, sorted_eig_vec);

    tom_emwrite(eig_val_fn, sorted_eig_val);
    subtom_check_em_file(eig_val_fn, sorted_eig_val);

    % Write out the fast version of the Eigencoefficients, which comes from
    % Equation (5) in the Borland 90' paper.
    eig_vec_coeffs = sorted_eig_vec * diag(sqrt(abs(sorted_eig_val)));
    eig_vec_coeffs_fn = sprintf('%s_eigcoeffs_%d.em', eig_vec_fn_prefix, ...
        iteration);

    tom_emwrite(eig_vec_coeffs_fn, eig_vec_coeffs);
    subtom_check_em_file(eig_vec_coeffs_fn, eig_vec_coeffs);
end
