function pca_eigs(ccmatrix_fn_prefix, eig_vec_fn_prefix, ...
    eig_val_fn_prefix, iteration, num_eigs, eigs_iterations, ...
    eigs_tolerance, do_algebraic)
% PCA_EIGS uses MATLAB eigs to calculate a subset of eigenvalue/vectors
%     PCA_EIGS(
%         CCMATRIX_FN_PREFIX,
%         EIG_VEC_FN_PREFIX,
%         EIG_VAL_FN_PREFIX,
%         ITERATION,
%         NUM_EIGS,
%         EIGS_ITERATIONS,
%         EIGS_TOLERANCE,
%         DO_ALGEBRAIC)
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
%
% Example:
%     PCA_EIGS('pca/ccmatrix', 'pca/eigvec', 'pca/eigval', 1, 40, 'default',
%         'default', 0)
%
%     Would calculate the 40 largest eigenvectors and eigenvalues of
%     'pca/ccmatrix_1.em', using the default parameters of the eigs command, and
%     the vectors would be written out to 'pca/eigvec_1.em', and the
%     corresponding eigenvalues would be written out to 'pca/eigval_1.em'
%
% See also PCA_SVDS EIGS

% DRM 02-2019
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% ccmatrix_fn_prefix = 'pca/ccmatrix';
% eig_vec_fn_prefix = 'pca/eigvec';
% eig_val_fn_prefix = 'pca/eigval';
% iteration = 1;
% num_eigs = 40;
% eigs_iterations = 'default';
% eigs_tolerance = 'default';
% do_algebraic
%##############################################################################%
    % Evaluate numeric inputs
    if ischar(iteration)
        iteration = str2double(iteration);
    end

    if isnan(iteration) || rem(iteration, 1) ~= 0
        try
            error('subTOM:argumentError', ...
                'pca_eigs:iteration: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(num_eigs)
        iteration = str2double(num_eigs);
    end

    if isnan(num_eigs) || num_eigs < 1 || rem(num_eigs, 1) ~= 0
        try
            error('subTOM:argumentError', ...
                'pca_eigs:num_eigs: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(eigs_iterations) && ~strcmpi(eigs_iterations, 'default') 
        eigs_iterations = str2double(eigs_iterations);
    elseif strcmpi(eigs_iterations, 'default')
        eigs_iterations = 300;
    end

    if isnan(eigs_iterations) || eigs_iterations < 1 || ...
        rem(eigs_iterations, 1) ~= 0

        try
            error('subTOM:argumentError', ...
                'pca_eigs:eigs_iterations: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(eigs_tolerance) && ~strcmpi(eigs_tolerance, 'default') 
        eigs_tolerance = str2double(eigs_tolerance);
    elseif strcmpi(eigs_tolerance, 'default')
        eigs_tolerance = eps;
    end

    if isnan(eigs_tolerance) || eigs_tolerance < 0
        try
            error('subTOM:argumentError', ...
                'pca_eigs:eigs_tolerance: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(do_algebraic)
        do_algebraic = str2double(do_algebraic);
    end
    
    if isnan(do_algebraic)
        try
            error('subTOM:argumentError', ...
                'pca_eigs:do_algebraic: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ~ (do_algebraic == 1 || do_algebraic == 0)
        warning('subTOM:argumentWarning', ...
            'pca_eigs:do_algebraic: argument unexpected');
        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
    end

    do_algebraic = logical(do_algebraic);

    % Read in the ccmatrix
    ccmatrix_fn = sprintf('%s_%d.em', ccmatrix_fn_prefix, iteration);

    if exist(fullfile(pwd(), ccmatrix_fn), 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'pca_eigs:File %s does not exist.', ccmatrix_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    ccmatrix = getfield(tom_emread(ccmatrix_fn), 'Value');

    if size(ccmatrix, 1) ~= size(ccmatrix, 2)
        try
            error('subTOM:argumentError', ...
                'pca_eigs:ccmatrix_fn: Matrix given is not square!');
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
            'pca_eigs: %s.', ...
            'Negative Eigen values determined, try do_algebraic or pca_svd');
        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
    end

    % Write out the Eigenvectors and Eigenvalues
    eig_vec_fn = sprintf('%s_%d.em', eig_vec_fn_prefix, iteration);
    tom_emwrite(eig_vec_fn, sorted_eig_vec);
    check_em_file(eig_vec_fn, sorted_eig_vec);

    eig_val_fn = sprintf('%s_%d.em', eig_val_fn_prefix, iteration);
    tom_emwrite(eig_val_fn, sorted_eig_val);
    check_em_file(eig_val_fn, sorted_eig_val);
end
