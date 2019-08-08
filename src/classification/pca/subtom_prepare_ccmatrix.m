function subtom_prepare_ccmatrix(varargin)
% SUBTOM_PREPARE_CCMATRIX calculates batch of pairwise comparisons of particles.
%
%     SUBTOM_PREPARE_CCMATRIX(
%        'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX,
%        'ccmatrix_fn_prefix', CCMATRIX_FN_PREFIX,
%        'iteration', ITERATION,
%        'num_ccmatrix_batch', NUM_CCMATRIX_BATCH)
%
%     Figures out the pairwise comparisons to make from the motivelist
%     ALL_MOTL_FN_PREFIX_ITERATION.em, and breaks up these comparisons into
%     NUM_CCMATRIX_BATCH batches for parallel computation. Each batch is written
%     out as an array with the 'reference' particle index and 'target' particle
%     index to an EM-file with the name CCMATRIX_FN_PREFIX_ITERATION_#_pairs.em
%     where the # is the batch index.

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'all_motl_fn_prefix', 'combinedmotl/allmotl');
    addParameter(fn_parser, 'ccmatrix_fn_prefix', 'pca/ccmatrix');
    addParameter(fn_parser, 'iteration', '1');
    addParameter(fn_parser, 'num_ccmatrix_batch', '1');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    all_motl_fn_prefix = fn_parser.Results.all_motl_fn_prefix;
    [all_motl_dir, ~, ~] = fileparts(all_motl_fn_prefix);

    if ~isempty(all_motl_dir) && exist(all_motl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'prepare_ccmatrix:all_motl_dir: Directory %s %s.', ...
                all_motl_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    ccmatrix_fn_prefix = fn_parser.Results.ccmatrix_fn_prefix;
    [ccmatrix_dir, ~, ~] = fileparts(ccmatrix_fn_prefix);

    if ~isempty(ccmatrix_dir) && exist(ccmatrix_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'prepare_ccmatrix:ccmatrix_dir: Directory %s %s.', ...
                ccmatrix_dir, 'does not exist');

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
            'subtom_prepare_ccmatrix', 'iteration');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    num_ccmatrix_batch = fn_parser.Results.num_ccmatrix_batch;

    if ischar(num_ccmatrix_batch)
        num_ccmatrix_batch = str2double(num_ccmatrix_batch);
    end

    try
        validateattributes(num_ccmatrix_batch, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0}, ...
            'subtom_prepare_ccmatrix', 'num_ccmatrix_batch');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Check if the calculation has already been done and skip if so.
    all_done = 1;
    for batch_idx = 1:num_ccmatrix_batch
        pairs_fn = sprintf('%s_%d_%d_pairs.em', ccmatrix_fn_prefix, ...
            iteration, batch_idx);

        if exist(pairs_fn, 'file') ~= 2
            all_done = 0;
            break
        end
    end

    if all_done
        warning('subTOM:recoverOnFail', ...
            'prepare_ccmatrix:File %s already exists. SKIPPING!', ...
            pairs_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Read in all_motl.
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(all_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'prepare_ccmatrix:File %s does not exist.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl = getfield(tom_emread(all_motl_fn), 'Value');

    if size(all_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'prepare_ccmatrix:%s is not proper MOTL.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Get the size of the motivelist to find how many particles.
    num_ptcls = size(all_motl, 2);

    % Calculate the number of pairwise comparisons
    % I could use nchoosek but this is a bit faster especially at large N.
    num_pairs = (num_ptcls^2 - num_ptcls) / 2;

    if num_ccmatrix_batch > num_pairs
        try
            error('subTOM:argumentError', ...
                'subtom_prepare_ccmatrix:%s', ...
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
    ptcl_range = 1:num_ptcls;

    % Here is where we get the pairs, it's a bit of MATLAB hackery magic using
    % implicit expansion.
    [ptcl_idxs, ref_idxs] = ind2sub([num_ptcls, num_ptcls], ...
        find(ptcl_range < ptcl_range'));

    % Setup the progress bar
    delprog = '';
    timings = [];
    message = sprintf('Preparing CC-Matrix');
    op_type = 'pairs';
    tic;

    % Loop over and write batches out
    for batch_idx = 1:num_ccmatrix_batch

        % Find out the end of the batch and trim the end if necessary at the end
        % of the comparisons
        if batch_idx > num_pairs - num_ccmatrix_batch * batch_size
            start_idx = (batch_idx - 1) * batch_size + 1 + ...
                (num_pairs - (num_ccmatrix_batch * batch_size));

            end_idx = start_idx + batch_size - 1;
        else
            start_idx = (batch_idx - 1) * (batch_size + 1) + 1;
            end_idx = start_idx + batch_size;
        end

        % Write out an EM-file with the pairs
        pairs = horzcat(ref_idxs(start_idx:end_idx), ...
            ptcl_idxs(start_idx:end_idx));

        pairs_fn = sprintf('%s_%d_%d_pairs.em', ccmatrix_fn_prefix, ...
            iteration, batch_idx);

        tom_emwrite(pairs_fn, pairs);
        subtom_check_em_file(pairs_fn, pairs);

        % Display some output
        [delprog, timings] = subtom_display_progress(delprog, timings, ...
            message, op_type, num_ccmatrix_batch, batch_idx);

    end
end
