function pca_join_ccmatrix(all_motl_fn_prefix, ccmatrix_fn_prefix, ...
    iteration, num_ccmatrix_batch)
% PCA_JOIN_CCMATRIX combines chunks of the ccmatrix into the full final matrix
%     PCA_JOIN_CCMATRIX(
%         ALL_MOTL_FN_PREFIX,
%         CCMATRIX_FN_PREFIX,
%         ITERATION,
%         NUM_CCMATRIX_BATCH
%
%     Looks for partial chunks of the ccmatrix with the file name
%     CCMATRIX_FN_PREFIX_ITERATION_#.em where # is from 1 to NUM_CCMATRIX_BATCH,
%     and then combines these chunks into the final ccmatrix and writes it out
%     to CCMATRIX_FN_PREFIX_ITERATION.em
%
% Example:
%     PCA_JOIN_CCMATRIX('combinedmotl/allmotl', 'pca/ccmatrix', 1, 100)
%
%     Would take all the files with the name pca/ccmatrix_1_{1..100}.em and
%     combine them into the final ccmatrix file pca/ccmatrix_1.em
%
% See also PCA_PREPARE_CCMATRIX PCA_PARALLEL_CCMATRIX

% DRM 02-2019
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% all_motl_fn_prefix = 'combinedmotl/allmotl';
% ccmatrix_fn_prefix = 'pca/ccmatrix';
% iteration = 1;
% num_ccmatrix_batch = 100;
%##############################################################################%
    % Evaluate numeric inputs
    if ischar(iteration)
        iteration = str2double(iteration);
    end

    if isnan(iteration) || rem(iteration, 1) ~= 0
        try
            error('subTOM:argumentError', ...
                'pca_join_ccmatrix:iteration: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(num_ccmatrix_batch)
        iteration = str2double(num_ccmatrix_batch);
    end

    if isnan(num_ccmatrix_batch) || num_ccmatrix_batch < 1 || ...
        rem(num_ccmatrix_batch, 1) ~= 0

        try
            error('subTOM:argumentError', ...
                'pca_join_ccmatrix:num_ccmatrix_batch: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Get the size of the motivelist to find how many particles.
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(fullfile(pwd(), all_motl_fn), 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'pca_join_ccmatrix:File %s does not exist.', all_motl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl_size = getfield(tom_emread(all_motl_fn), 'Header', 'Size');

    if all_motl_size(1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'pca_join_ccmatrix:%s is not proper MOTL.', all_motl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl_size = all_motl_size(2);

    % Create the ccmatrix
    ccmatrix = eye(all_motl_size);

    % Loop over batches
    for batch_idx = 1:num_ccmatrix_batch
        % Read in the pairs that make up the CCC list
        pairs_fn = sprintf('%s_%d_%d_pairs.em', ccmatrix_fn_prefix, ...
            iteration, batch_idx);

        if exist(fullfile(pwd(), pairs_fn), 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'pca_join_ccmatrix:File %s does not exist.', pairs_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        pairs = getfield(tom_emread(pairs_fn), 'Value');

        % Read in the list of CCCs
        cccs_fn = sprintf('%s_%d_%d.em', ccmatrix_fn_prefix, iteration, ...
            batch_idx);

        if exist(fullfile(pwd(), cccs_fn), 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'pca_join_ccmatrix:File %s does not exist.', cccs_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        cccs = getfield(tom_emread(cccs_fn), 'Value');

        % Set the upper triangular values
        ccmatrix(sub2ind([all_motl_size, all_motl_size], pairs(:, 1), ...
            pairs(:, 2))) = cccs;

        % Set the lower triangular values
        ccmatrix(sub2ind([all_motl_size, all_motl_size], pairs(:, 2), ...
            pairs(:, 1))) = cccs;

    end

    % Finally write out the ccmatrix
    ccmatrix_fn = sprintf('%s_%d.em', ccmatrix_fn_prefix, iteration);
    tom_emwrite(ccmatrix_fn, ccmatrix);
    check_em_file(ccmatrix_fn, ccmatrix);
end
