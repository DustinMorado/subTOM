function subtom_parallel_sums_bfactor(varargin)
% SUBTOM_PARALLEL_SUMS_BFACTOR version of parallel sums for finding B-factor.
%
%     SUBTOM_PARALLEL_SUMS_BFACTOR(
%         'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX,
%         'ref_fn_prefix', REF_FN_PREFIX,
%         'ptcl_fn_prefix', PTCL_FN_PREFIX,
%         'weight_fn_prefix', WEIGHT_FN_PREFIX,
%         'weight_sum_fn_prefix', WEIGHT_SUM_FN_PREFIX,
%         'iteration', ITERATION,
%         'tomo_row', TOMO_ROW,
%         'iclass', ICLASS,
%         'num_avg_batch', NUM_AVG_BATCH,
%         'process_idx', PROCESS_IDX)
%
%     Aligns a subset of particles using the rotations and shifts in
%     ALL_MOTL_FN_PREFIX_ITERATION in NUM_AVG_BATCH chunks to make a raw
%     particle sum REF_FN_PREFIX_ITERATION_PROCESS_IDX. Fourier weight volumes
%     with name prefix WEIGHT_FN_PREFIX will also be aligned and summed to make
%     a weight sum WEIGHT_SUM_FN_PREFIX_ITERATION_PROCESS_IDX. TOMO_ROW
%     describes which row of the motl file is used to determine the correct
%     tomogram fourier weight file. ICLASS describes which class outside of one
%     is included in the averaging. 
%
%     The difference between this function and SUBTOM_PARALLEL_SUMS is that this
%     function creates a number of subsets of the particle and weight sum
%     subsets, so that smaller and smaller populations of data are summed, and
%     these subsets can then be used to estimate the B Factor of the structure.

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'all_motl_fn_prefix', 'combinedmotl/allmotl');
    addParameter(fn_parser, 'ref_fn_prefix', 'ref/ref');
    addParameter(fn_parser, 'ptcl_fn_prefix', 'subtomograms/subtomo');
    addParameter(fn_parser, 'weight_fn_prefix', 'otherinputs/ampspec');
    addParameter(fn_parser, 'weight_sum_fn_prefix', 'otherinputs/wei');
    addParameter(fn_parser, 'iteration', 1);
    addParameter(fn_parser, 'tomo_row', 7);
    addParameter(fn_parser, 'iclass', 0);
    addParameter(fn_parser, 'num_avg_batch', 1);
    addParameter(fn_parser, 'process_idx', 1);
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    all_motl_fn_prefix = fn_parser.Results.all_motl_fn_prefix;
    [all_motl_dir, ~, ~] = fileparts(all_motl_fn_prefix);

    if ~isempty(all_motl_dir) && exist(all_motl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_sums_bfactor:all_motl_dir: Directory %s %s.', ...
                all_motl_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    ref_fn_prefix = fn_parser.Results.ref_fn_prefix;
    [ref_dir, ~, ~] = fileparts(ref_fn_prefix);

    if ~isempty(ref_dir) && exist(ref_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_sums_bfactor:ref_dir: Directory %s %s.', ...
                ref_dir, 'does not exist');

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
                'parallel_sums_bfactor:ptcl_dir: Directory %s %s.', ...
                ptcl_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    weight_fn_prefix = fn_parser.Results.weight_fn_prefix;
    [weight_dir, ~, ~] = fileparts(weight_fn_prefix);

    if ~isempty(weight_dir) && exist(weight_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_sums_bfactor:weight_dir: Directory %s %s.', ...
                weight_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    weight_sum_fn_prefix = fn_parser.Results.weight_sum_fn_prefix;
    [weight_sum_dir, ~, ~] = fileparts(weight_sum_fn_prefix);

    if ~isempty(weight_sum_dir) && exist(weight_sum_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_sums_bfactor:weight_sum_dir: Directory %s %s.', ...
                weight_sum_dir, 'does not exist');

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
            'subtom_parallel_sums_bfactor', 'iteration');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    tomo_row = fn_parser.Results.tomo_row;

    if ischar(tomo_row)
        tomo_row = str2double(tomo_row);
    end

    try
        validateattributes(tomo_row, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0, '<', 21}, ...
            'subtom_parallel_sums_bfactor', 'tomo_row');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    iclass = fn_parser.Results.iclass;

    if ischar(iclass)
        iclass = str2double(iclass);
    end

    try
        validateattributes(iclass, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer'}, ...
            'subtom_parallel_sums_bfactor', 'iclass');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    num_avg_batch = fn_parser.Results.num_avg_batch;

    if ischar(num_avg_batch)
        num_avg_batch = str2double(num_avg_batch);
    end

    try
        validateattributes(num_avg_batch, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0}, ...
            'subtom_parallel_sums_bfactor', 'num_avg_batch');

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
            {'scalar', 'nonnan', 'integer', '>', 0, '<=', num_avg_batch}, ...
            'subtom_parallel_sums_bfactor', 'process_idx');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%
    % Read in all_motl and first subtomo and weight to skip finding box size
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(all_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_sums_bfactor:File %s does not exist.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl = getfield(tom_emread(all_motl_fn), 'Value');

    if size(all_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'parallel_sums_bfactor:%s is not proper MOTL.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Find the number of particles in the motive list and use this to calculate
    % the start and end index of the particles to align.
    num_ptcls = size(all_motl, 2);
    avg_batch_size = floor(num_ptcls / num_avg_batch);

    if process_idx > num_ptcls - num_avg_batch * avg_batch_size
        ptcl_start_idx = (process_idx - 1) * avg_batch_size + 1 + ...
            (num_ptcls - num_avg_batch * avg_batch_size);

        ptcl_end_idx = ptcl_start_idx + avg_batch_size - 1;
    else
        ptcl_start_idx = (process_idx - 1) * (avg_batch_size + 1) + 1;
        ptcl_end_idx = ptcl_start_idx + avg_batch_size;
    end

    batch_size = ptcl_end_idx - ptcl_start_idx + 1;

    % Find out the total number of particles that will go into the average.  All
    % particles with class value of 1 are included in the average as well as
    % particles with class value iclass
    num_good_ptcls = sum(all_motl(20, :) == 1 | all_motl(20, :) == iclass);

    % We calculate subsets in powers of two of the data but limit the smallest
    % subset that contains at least 128 particles.
    num_subsets = floor(log2(num_good_ptcls / 128)) + 1;

    % Now that we know how many subsets need to calculated we can see if they
    % have already been calculated and skip if so.
    all_done = 1;

    for subset_idx = 1:num_subsets
        ref_fn = sprintf('%s_subset_%d_%d_%d.em', ref_fn_prefix, ...
            subset_idx, iteration, process_idx);

        weight_sum_fn = sprintf('%s_subset_%d_%d_%d.em', ...
            weight_sum_fn_prefix, subset_idx, iteration, process_idx);

        if exist(ref_fn, 'file') ~= 2 || exist(weight_sum_fn, 'file') ~= 2
            all_done = 0;
            break
        end
    end

    if all_done
        warning('subTOM:recoverOnFail', ...
            'parallel_sums_bfactor:File %s already exists. SKIPPING!', ref_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Initialize particle sum array
    % Normally you can run one iteration out of the loop to get the box sizes,
    % but it's too complicated with the subsets so we just read the first
    % particle and that gives us the size to initialize the cell arrays.
    ptcl_fn = sprintf('%s_%d.em', ptcl_fn_prefix, all_motl(4, ptcl_start_idx));
    check_fn = ptcl_fn;

    if exist(ptcl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_sums_bfactor:File %s does not exist.', ptcl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Note the transpose, tom_reademheader returns a column vector, but Matlab
    % size function returns a row vector, and ones and zeros need row vector
    box_size = getfield(tom_reademheader(ptcl_fn), 'Header', 'Size')';

    ptcl_average_cell = arrayfun(@(x) zeros(box_size), 1:num_subsets, ...
        'UniformOutput', 0);

    current_weight = 0;
    weight_sum_cell = arrayfun(@(x) zeros(box_size), 1:num_subsets, ...
        'UniformOutput', 0);

    sum_idx = 1;
    good_idx = sum(all_motl(20, 1:(ptcl_start_idx - 1)) == 1 | ...
        all_motl(20, 1:(ptcl_start_idx - 1)) == iclass) + 1;

    % Setup the progress bar
    delprog = '';
    timings = [];
    message = sprintf('Summing Subsets Batch %d', process_idx);
    op_type = 'particles';
    tic;

    % Loop through each subtomogram
    for ptcl_idx = ptcl_start_idx:ptcl_end_idx

        % Check class of current subtomogram and skip if it doesn't belong to
        % iclass 1 or the iclass the user has given.
        if all_motl(20, ptcl_idx) ~= 1 && all_motl(20, ptcl_idx) ~= iclass

            % Display some output
            [delprog, timings] = subtom_display_progress(delprog, timings, ...
                message, op_type, batch_size, sum_idx);

            % increment our count of particles aligned and summed.
            sum_idx = sum_idx + 1;
            continue
        end

        % Read in subtomogram
        ptcl_fn = sprintf('%s_%d.em', ptcl_fn_prefix, all_motl(4, ptcl_idx));

        if exist(ptcl_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'parallel_sums_bfactor:File %s does not exist.', ptcl_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        ptcl = getfield(tom_emread(ptcl_fn), 'Value');

        if ~all(size(ptcl) == box_size)
            try
                error('subTOM:volDimError', ...
                    'parallel_sums_bfactor:%s and %s are not same size.', ...
                    ptcl_fn, check_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        % Parse translations from motl
        % These translations describe the translation of the reference to the
        % particle after rotation has been applied to the reference. In the
        % motl they are ordered: X-axis shift, Y-axis shift, and Z-axis shift.
        % They have the inverse description here in terms of the particle
        % shifting to the reference register.
        ptcl_shift = -all_motl(11:13, ptcl_idx);

        % Parse rotations from motl
        % These rotations describe the rotations of the reference to the
        % particle determined in alignment. In the motl they are ordered;
        % azimuthal rotation, inplane rotation, and zenithal rotation. They
        % have the inverse description here in terms of the particle rotating
        % to the reference orientation.
        ptcl_rot = -all_motl([18, 17, 19], ptcl_idx);

        % Shift and rotate particle
        aligned_ptcl = tom_shift(ptcl, ptcl_shift);
        aligned_ptcl = tom_rotate(aligned_ptcl, ptcl_rot);

        % Read in weight
        if current_weight ~= all_motl(tomo_row, ptcl_idx)
            current_weight = all_motl(tomo_row, ptcl_idx);
            weight_fn = sprintf('%s_%d.em', weight_fn_prefix, current_weight);

            if exist(weight_fn, 'file') ~= 2
                try
                    error('subTOM:missingFileError', ...
                        'parallel_sums_bfactor:File %s does not exist.', ...
                        weight_fn);

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            weight = getfield(tom_emread(weight_fn), 'Value');

            if ~all(size(weight) == box_size)
                try
                    error('subTOM:volDimError', ...
                        'parallel_sums_bfactor:%s and %s %s.', ...
                        weight_fn, check_fn, 'are not same size');

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end
        end

        % Rotate weight (We don't shift because this is Fourier space)
        aligned_weight = tom_rotate(weight, ptcl_rot);

        % Add wedge and particle to sum arrays
        for subset_idx = 1:num_subsets
            if mod(ptcl_idx, 2 ^ (subset_idx - 1)) == 0
                ptcl_average_cell{subset_idx} = ...
                    ptcl_average_cell{subset_idx} + aligned_ptcl; 

                weight_sum_cell{subset_idx} = ...
                    weight_sum_cell{subset_idx} + aligned_weight;

            end
        end

        % Display some output
        [delprog, timings] = subtom_display_progress(delprog, timings, ...
            message, op_type, batch_size, sum_idx);

        % increment our count of particles aligned and summed.
        sum_idx = sum_idx + 1;
        good_idx = good_idx + 1;
    end

    for subset_idx = 1:num_subsets
        % Write out summed wedge-weighting array
        weight_sum_fn = sprintf('%s_subset_%d_%d_%d.em', ...
            weight_sum_fn_prefix, subset_idx, iteration, process_idx);

        tom_emwrite(weight_sum_fn, weight_sum_cell{subset_idx});
        subtom_check_em_file(weight_sum_fn, weight_sum_cell{subset_idx});

        % Write out summed reference
        ref_fn = sprintf('%s_subset_%d_%d_%d.em', ref_fn_prefix, ...
            subset_idx, iteration, process_idx);

        tom_emwrite(ref_fn, ptcl_average_cell{subset_idx});
        subtom_check_em_file(ref_fn, ptcl_average_cell{subset_idx});
    end
end
