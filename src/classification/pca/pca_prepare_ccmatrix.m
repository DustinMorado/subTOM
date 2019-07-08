function pca_prepare_ccmatrix(all_motl_fn_prefix, ccmatrix_fn_prefix, ...
    iteration, num_ccmatrix_batch)
% PCA_PREPARE_CCMATRIX calculates batches of pairwise comparisons of particles
%     PCA_PREPARE_CCMATRIX(
%         ALL_MOTL_FN_PREFIX,
%         CCMATRIX_FN_PREFIX,
%         ITERATION,
%         NUM_CCMATRIX_BATCH)
%
%     Figures out the pairwise comparisons to make from the motivelist
%     ALL_MOTL_FN_PREFIX_ITERATION.em, and breaks up these comparisons into
%     NUM_CCMATRIX_BATCH batches for parallel computation. Each batch is written
%     out as an array with the 'reference' particle index and 'target' particle
%     index to an EM-file with the name CCMATRIX_FN_PREIX_ITERATION_#_pairs.em
%     where the # is the batch index.
%
% Example:
%     PCA_PREPARE_CCMATRIX('combinedmotl/allmotl', 'pca/ccmatrix', 1, 100)
%
%     Would calculate the pairwise comparisons that need to be made with the
%     particles in combinedmotl/allmotl_1.em and write out the files
%     pca/ccmatrix_1_{1..100}_pairs.em
%
% See also PCA_PARALLEL_CCMATRIX PCA_JOIN_CCMATRIX

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
                'pca_prepare_ccmatrix:iteration: argument invalid');
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
                'pca_prepare_ccmatrix:num_ccmatrix_batch: argument invalid');
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
                'pca_prepare_ccmatrix:File %s does not exist.', all_motl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl_size = getfield(tom_emread(all_motl_fn), 'Header', 'Size');

    if all_motl_size(1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'pca_prepare_ccmatrix:%s is not proper MOTL.', all_motl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl_size = all_motl_size(2);

    % Calculate the number of pairwise comparisons
    % I could use nchoosek but this is a bit faster especially at large N.
    num_pairs = (all_motl_size^2 - all_motl_size) / 2;

    if num_ccmatrix_batch > num_pairs
        try
            error('subTOM:argumentError', ...
                'pca_prepare_ccmatrix:%s', ...
                'num_ccmatrix_batch is greater than num_pairs.')
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Calculate number of comparisons in each batch
    batch_size = floor(num_pairs / num_ccmatrix_batch);

    % Create a linear range that we will use with implicit expansion to find
    % pairs as opposed to using ndgrid or meshgrid. This uses "slightly" less
    % memory, but not much less.
    ptcl_range = 1:all_motl_size;

    % Here is where we get the pairs, it's a bit of MATLAB hackery magic using
    % implicit expansion.
    [ptcl_idxs, ref_idxs] = ind2sub([all_motl_size, all_motl_size], ...
        find(ptcl_range < ptcl_range'));

    % Some variables for showing progress
    delprog = '';
    delprog_batch = max(floor(num_ccmatrix_batch / 200), 1);
    timings = [];
    tic;

    % Loop over and write batches out
    for batch_idx = 1:num_ccmatrix_batch

        % Find out the end of the batch and trim the end if necessary at the end
        % of the comparisons
        if batch_idx > (num_pairs - (num_ccmatrix_batch * batch_size))
            ptcl_start_idx = (batch_idx - 1) * batch_size + 1 + ...
                (num_pairs - (num_ccmatrix_batch * batch_size));

            ptcl_end_idx = ptcl_start_idx + batch_size - 1;
        else
            ptcl_start_idx = (process_idx - 1) * (batch_size + 1) + 1;
            ptcl_end_idx = ptcl_start_idx + batch_size;
        end

        % Write out an EM-file with the pairs
        pairs = horzcat(ref_idxs(ptcl_start_idx:ptcl_end_idx), ...
            ptcl_idxs(ptcl_start_idx:ptcl_end_idx));

        pairs_fn = sprintf('%s_%d_%d_pairs.em', ccmatrix_fn_prefix, ...
            iteration, batch_idx);

        tom_emwrite(pairs_fn, pairs);
        check_em_file(pairs_fn, pairs);

        % Display some output
        if mod(batch_idx, delprog_batch) == 0
            elapsed_time = toc;
            timings = [timings elapsed_time];
            delprog = disp_progbar(num_ccmatrix_batch, batch_idx, timings, ...
                delprog);

            tic;
        end
    end
end
