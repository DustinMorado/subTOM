function pca_svds(ccmatrix_fn_prefix, eig_vec_fn_prefix, ...
    eig_val_fn_prefix, iteration, num_svs, svds_iterations, svds_tolerance)
% PCA_SVDS uses MATLAB svds to calculate a subset of singular values/vectors
%     PCA_SVDS(
%         CCMATRIX_FN_PREFIX,
%         EIG_VEC_FN_PREFIX,
%         EIG_VAL_FN_PREFIX,
%         ITERATION,
%         NUM_SVS,
%         SVDS_ITERATIONS,
%         SVDS_TOLERANCE)
%
%     Uses the MATLAB function svds to calculate a subset of singular values and
%     vectors given the constrained cross-correlation (covariance) matrix
%     with the filename CCMATRIX_FN_PREFIX_ITERATION.em. NUM_SVS of the largest
%     singular values and vectors will be calculated, and will be written out
%     to EIG_VAL_FN_PREFIX_ITERATION.em and EIG_VEC_FN_PREFIX_ITERATION.em
%     respectively. Two options SVDS_ITERATIONS and SVDS_TOLERANCE are also
%     available to tune how svds is run. If the string 'default' is given for
%     either the default values in eigs will be used.
%
% Example:
%     PCA_SVDS('pca/ccmatrix', 'pca/eigvec', 'pca/eigval', 1, 40, 'default',
%         'default')
%
%     Would calculate the 40 largest singular values and vectors of
%     'pca/ccmatrix_1.em', using the default parameters of the svds command, and
%     the vectors would be written out to 'pca/eigvec_1.em', and the
%     corresponding singular values would be written out to 'pca/eigval_1.em'
%
% See also PCA_EIGS SVDS

% DRM 02-2019
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% ccmatrix_fn_prefix = 'pca/ccmatrix';
% eig_vec_fn_prefix = 'pca/eigvec';
% eig_val_fn_prefix = 'pca/eigval';
% iteration = 1;
% num_svs = 40;
% svds_iterations = 'default';
% svds_tolerance = 'default';
%##############################################################################%
    % Evaluate numeric inputs
    if ischar(iteration)
        iteration = str2double(iteration);
    end

    if isnan(iteration) || rem(iteration, 1) ~= 0
        try
            error('subTOM:argumentError', ...
                'pca_svds:iteration: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(num_svs)
        iteration = str2double(num_svs);
    end

    if isnan(num_svs) || num_svs < 1 || rem(num_svs, 1) ~= 0
        try
            error('subTOM:argumentError', ...
                'pca_svds:num_svs: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(svds_iterations) && ~strcmpi(svds_iterations, 'default') 
        svds_iterations = str2double(svds_iterations);
    elseif strcmpi(svds_iterations, 'default')
        svds_iterations = 100;
    end

    if isnan(svds_iterations) || svds_iterations < 1 || ...
        rem(svds_iterations, 1) ~= 0

        try
            error('subTOM:argumentError', ...
                'pca_svds:svds_iterations: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(svds_tolerance) && ~strcmpi(svds_tolerance, 'default') 
        svds_tolerance = str2double(svds_tolerance);
    elseif strcmpi(svds_tolerance, 'default')
        svds_tolerance = 1e-10;
    end

    if isnan(svds_tolerance) || svds_tolerance < 0
        try
            error('subTOM:argumentError', ...
                'pca_svds:svds_tolerance: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Read in the ccmatrix
    ccmatrix_fn = sprintf('%s_%d.em', ccmatrix_fn_prefix, iteration);

    if exist(fullfile(pwd(), ccmatrix_fn), 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'pca_svds:File %s does not exist.', ccmatrix_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    ccmatrix = getfield(tom_emread(ccmatrix_fn), 'Value');

    if size(ccmatrix, 1) ~= size(ccmatrix, 2)
        try
            error('subTOM:argumentError', ...
                'pca_svds:ccmatrix_fn: Matrix given is not square!');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Calculate the Singular Value Decomposition of the ccmatrix
    [eig_vec, eig_val, ~] = svds(ccmatrix, num_svs, 'largest', ...
        struct('tol', svds_tolerance, 'maxit', svds_iterations));

    % Write out the Eigenvectors and Eigenvalues
    eig_vec_fn = sprintf('%s_%d.em', eig_vec_fn_prefix, iteration);
    tom_emwrite(eig_vec_fn, eig_vec);
    check_em_file(eig_vec_fn, eig_vec);

    eig_val = diag(eig_val);
    eig_val_fn = sprintf('%s_%d.em', eig_val_fn_prefix, iteration);
    tom_emwrite(eig_val_fn, eig_val);
    check_em_file(eig_val_fn, eig_val);
end
