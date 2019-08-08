function subtom_parallel_prealign(varargin)
% SUBTOM_PARALLEL_PREALIGN prealigns particles to speed up ccmatrix calculation.
%
%     SUBTOM_PARALLEL_PREALIGN(
%         'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX,
%         'ptcl_fn_prefix', PTCL_FN_PREFIX,
%         'prealign_fn_prefix', PREALIGN_FN_PREFIX,
%         'iteration', ITERATION,
%         'num_prealign_batch', NUM_PREALIGN_BATCH,
%         'process_idx', PROCESS_IDX)
%
%     Prerotates and translates particles into alignment as precalculation on
%     disk to speed up the calculation of the constrained cross-correlation
%     matrix. The alignments are given in the motive list,
%     ALL_MOTL_FN_PREFIX_ITERATION.em, and the particles are specified as
%     PTCL_FN_PREFIX_#.em where # is described in row 4 of the motive list.
%     Pre-aligned particles will be written as
%     PREALIGN_FN_PREFIX_ITERATION_#.em. The process is designed to be run in
%     parallel on a cluster. The particles will be processed in
%     NUM_PREALIGN_BATCH chunks, with the specific chunk being processed
%     described by PROCESS_IDX.

% DRM 03-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'all_motl_fn_prefix', 'combinedmotl/allmotl');
    addParameter(fn_parser, 'ptcl_fn_prefix', 'subtomograms/subtomo');
    addParameter(fn_parser, 'prealign_fn_prefix', 'subtomograms/subtomo');
    addParameter(fn_parser, 'iteration', '1');
    addParameter(fn_parser, 'num_prealign_batch', '1');
    addParameter(fn_parser, 'process_idx', '1');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    all_motl_fn_prefix = fn_parser.Results.all_motl_fn_prefix;
    [all_motl_dir, ~, ~] = fileparts(all_motl_fn_prefix);

    if ~isempty(all_motl_dir) && exist(all_motl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_prealign:all_motl_dir: Directory %s %s.', ...
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
                'parallel_prealign:ptcl_dir: Directory %s %s.', ...
                ptcl_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    prealign_fn_prefix = fn_parser.Results.prealign_fn_prefix;
    [prealign_dir, ~, ~] = fileparts(prealign_fn_prefix);

    if ~isempty(prealign_dir) && exist(prealign_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_prealign:prealign_dir: Directory %s %s.', ...
                prealign_dir, 'does not exist');

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
            'subtom_parallel_prealign', 'iteration');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    num_prealign_batch = fn_parser.Results.num_prealign_batch;

    if ischar(num_prealign_batch)
        num_prealign_batch = str2double(num_prealign_batch);
    end

    try
        validateattributes(num_prealign_batch, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0}, ...
            'subtom_parallel_prealign', 'num_prealign_batch');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    process_idx = fn_parser.Results.process_idx;

    if ischar(process_idx)
        process_idx = str2double(process_idx);
    end

    try
        validateattributes(process_idx, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0, ...
            '<=', num_prealign_batch}, ...
            'subtom_parallel_prealign', 'process_idx');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%
    % Read in motive list
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(all_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_prealign:File %s does not exist.', ...
                all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl = getfield(tom_emread(all_motl_fn), 'Value');

    if size(all_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'parallel_prealign:%s is not proper MOTL.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    num_ptcls = size(all_motl, 2);

    if num_prealign_batch > num_ptcls
        try
            error('subTOM:argumentError', ...
                'parallel_prealign:%s', ...
                'num_prealign_batch is greater than num_ptcls.');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Get box size from first subtomogram
    ptcl_fn = sprintf('%s_%d.em', ptcl_fn_prefix, all_motl(4, 1));
    check_fn = ptcl_fn;

    if exist(ptcl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_prealign:File %s does not exist.', ptcl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Note the transpose, tom_reademheader returns a column vector, but Matlab
    % size function returns a row vector, and ones and zeros need row vector
    box_size = getfield(tom_reademheader(ptcl_fn), 'Header', 'Size')';

    % Calculate the number and indices of particles to process
    prealign_batch_size = floor(num_ptcls / num_prealign_batch);

    if process_idx > (num_ptcls - (prealign_batch_size * num_prealign_batch))
        ptcl_start_idx = (process_idx - 1) * prealign_batch_size + 1 + ...
            (num_ptcls - (prealign_batch_size * num_prealign_batch));

        ptcl_end_idx = ptcl_start_idx + prealign_batch_size - 1;
    else
        ptcl_start_idx = (process_idx - 1) * (prealign_batch_size + 1) + 1;
        ptcl_end_idx = ptcl_start_idx + prealign_batch_size;
    end
    
    batch_size = ptcl_end_idx - ptcl_start_idx + 1;

    % Setup the progress bar
    delprog = '';
    timings = [];
    message = sprintf('Prealign Batch %d', process_idx);
    op_type = 'particles';
    batch_idx = 1;
    tic;

    for ptcl_idx = ptcl_start_idx:ptcl_end_idx
        % Make sure that the particle hasn't already been done
        ptcl_fn = sprintf('%s_%d_%d.em', prealign_fn_prefix, iteration, ...
            all_motl(4, ptcl_idx));

        if exist(ptcl_fn, 'file') == 2
            warning('subTOM:recoverOnFail', ...
                'parallel_prealign:%s exists. SKIPPING!', ptcl_fn);

            % Display some output
            [delprog, timings] = subtom_display_progress(delprog, timings, ...
                message, op_type, batch_size, batch_idx);

            batch_idx = batch_idx + 1;
            continue;
        end

        % Read in the particle
        ptcl_fn = sprintf('%s_%d.em', ptcl_fn_prefix, all_motl(4, ptcl_idx));

        if exist(ptcl_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'parallel_prealign:File %s does not exist.', ptcl_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        ptcl = getfield(tom_emread(ptcl_fn), 'Value');

        if ~all(size(ptcl) == box_size)
            try
                error('subTOM:volDimError', ...
                    'parallel_prealign:%s and %s are not same size.', ...
                    ptcl_fn, check_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        % Get the shifts and rotations to align the particle
        ptcl_shift = -all_motl(11:13, ptcl_idx);
        ptcl_rot = -all_motl([18, 17, 19], ptcl_idx);

        % Align the particle
        aligned_ptcl = tom_rotate(tom_shift(ptcl, ptcl_shift), ptcl_rot);

        % Write out the aligned particle
        aligned_fn = sprintf('%s_%d_%d.em', prealign_fn_prefix, iteration, ...
            all_motl(4, ptcl_idx));

        tom_emwrite(aligned_fn, aligned_ptcl);
        subtom_check_em_file(aligned_fn, aligned_ptcl);

        % Display some output
        [delprog, timings] = subtom_display_progress(delprog, timings, ...
            message, op_type, batch_size, batch_idx);

        batch_idx = batch_idx + 1;
    end
end
