function subtom_join_ccmatrix(varargin)
% SUBTOM_JOIN_CCMATRIX combines chunks of the ccmatrix into the final matrix.
%
%     SUBTOM_JOIN_CCMATRIX(
%         'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX,
%         'ccmatrix_fn_prefix', CCMATRIX_FN_PREFIX,
%         'iteration', ITERATION,
%         'num_ccmatrix_batch', NUM_CCMATRIX_BATCH)
%
%     Looks for partial chunks of the CC-matrix with the file name
%     CCMATRIX_FN_PREFIX_ITERATION_#.em where # is from 1 to NUM_CCMATRIX_BATCH,
%     and then combines these chunks into the final ccmatrix and writes it out
%     to CCMATRIX_FN_PREFIX_ITERATION.em. The motive list of the particles
%     compared with the filename ALL_MOTL_FN_PREFIX_ITERATION.em is used just to
%     get the number of particles compared to determine the size of the matrix.

% DRM 02-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'all_motl_fn_prefix', 'combinedmotl/allmotl');
    addParameter(fn_parser, 'ccmatrix_fn_prefix', 'class/ccmatrix_pca');
    addParameter(fn_parser, 'iteration', 1);
    addParameter(fn_parser, 'num_ccmatrix_batch', 1);
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    all_motl_fn_prefix = fn_parser.Results.all_motl_fn_prefix;
    [all_motl_dir, ~, ~] = fileparts(all_motl_fn_prefix);

    if ~isempty(all_motl_dir) && exist(all_motl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'join_ccmatrix:all_motl_dir: Directory %s %s.', ...
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
                'join_ccmatrix:ccmatrix_dir: Directory %s %s.', ...
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
            'subtom_join_ccmatrix', 'iteration');

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
            'subtom_join_ccmatrix', 'num_ccmatrix_batch');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Check if the calculation has already been done and skip if so.
    full_ccmatrix_fn = sprintf('%s_%d.em', ccmatrix_fn_prefix, iteration);

    if exist(full_ccmatrix_fn, 'file') == 2
        warning('subTOM:recoverOnFail', ...
            'join_ccmatrix:File %s already exists. SKIPPING!', ...
            full_ccmatrix_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Read in all_motl file
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(all_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'join_ccmatrix:File %s does not exist.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl_size = getfield(tom_reademheader(all_motl_fn), 'Header', 'Size');

    if all_motl_size(1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'join_ccmatrix:%s is not proper MOTL.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    num_ptcls = all_motl_size(2);

    % Create the ccmatrix
    ccmatrix = eye(num_ptcls);

    % Setup the progress bar
    delprog = '';
    timings = [];
    message = sprintf('Joining CC-Matrix');
    op_type = 'batches';
    tic;

    % Loop over batches
    for batch_idx = 1:num_ccmatrix_batch
        % Read in the pairs that make up the CCC list
        pairs_fn = sprintf('%s_%d_%d_pairs.em', ccmatrix_fn_prefix, ...
            iteration, batch_idx);

        if exist(pairs_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'join_ccmatrix:File %s does not exist.', pairs_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        pairs = getfield(tom_emread(pairs_fn), 'Value');

        % Read in the list of CCCs
        cccs_fn = sprintf('%s_%d_%d.em', ccmatrix_fn_prefix, iteration, ...
            batch_idx);

        if exist(cccs_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'join_ccmatrix:File %s does not exist.', cccs_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        cccs = getfield(tom_emread(cccs_fn), 'Value');

        % Set the upper triangular values
        ccmatrix(sub2ind([num_ptcls, num_ptcls], pairs(:, 1), ...
            pairs(:, 2))) = cccs;

        % Set the lower triangular values
        ccmatrix(sub2ind([num_ptcls, num_ptcls], pairs(:, 2), ...
            pairs(:, 1))) = cccs;

        % Display some output
        [delprog, timings] = subtom_display_progress(delprog, timings, ...
            message, op_type, num_ccmatrix_batch, batch_idx);

    end

    % Finally write out the ccmatrix
    ccmatrix_fn = sprintf('%s_%d.em', ccmatrix_fn_prefix, iteration);
    tom_emwrite(ccmatrix_fn, ccmatrix);
    subtom_check_em_file(ccmatrix_fn, ccmatrix);
end
