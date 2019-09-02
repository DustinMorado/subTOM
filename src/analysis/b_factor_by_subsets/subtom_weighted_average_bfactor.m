function subtom_weighted_average_bfactor(varargin)
% SUBTOM_WEIGHTED_AVERAGE_BFACTOR joins and weights subsets of average subsets.
%
%     SUBTOM_WEIGHTED_AVERAGE_BFACTOR(
%         'ref_fn_prefix', REF_FN_PREFIX,
%         'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX,
%         'weight_sum_fn_prefix', WEIGHT_SUM_FN_PREFIX,
%         'iteration', ITERATION,
%         'iclass', ICLASS,
%         'num_avg_batch', NUM_AVG_BATCH)
%
%     Takes the NUM_AVG_BATCH parallel sum subsets with the name prefix
%     REF_FN_PREFIX, the all_motl file with name prefix MOTL_FN_PREFIX and
%     weight volume subsets with the name prefix WEIGHT_SUM_FN_PREFIX to
%     generate the final average, which should then be used as the reference for
%     iteration number ITERATION.  ICLASS describes which class outside of one
%     is included in the final average and is used to correctly scale the
%     average and weights.
%
%     The difference between this function and LMB_WEIGHTED_AVERAGE is that this
%     function expects there to be a number of subsets of the average subsets,
%     so that smaller and smaller populations of data are averaged, and these
%     subsets can then be used to estimate the B Factor of the structure.

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
    addParameter(fn_parser, 'weight_sum_fn_prefix', 'otherinputs/wei');
    addParameter(fn_parser, 'iteration', 1);
    addParameter(fn_parser, 'iclass', 0);
    addParameter(fn_parser, 'num_avg_batch', 1);
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    all_motl_fn_prefix = fn_parser.Results.all_motl_fn_prefix;
    [all_motl_dir, ~, ~] = fileparts(all_motl_fn_prefix);

    if ~isempty(all_motl_dir) && exist(all_motl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'weighted_average_bfactor:all_motl_dir: Directory %s %s.', ...
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
                'weighted_average_bfactor:ref_dir: Directory %s %s.', ...
                ref_dir, 'does not exist');

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
                'weighted_average_bfactor:weight_sum_dir: Directory %s %s.', ...
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
            'subtom_weighted_average_bfactor', 'iteration');

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
            'subtom_weighted_average_bfactor', 'iclass');

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
            'subtom_weighted_average_bfactor', 'num_avg_batch');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(all_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'weighted_average_bfactor:File %s does not exist.', ...
                all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl = getfield(tom_emread(sprintf('%s_%d.em', all_motl_fn_prefix, ...
        iteration)), 'Value');

    if size(all_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'weighted_average_bfactor:%s is not proper MOTL.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Find motls with the good classes and number of motls used in sums
    % When iclass is not zero then all particles with class value of 1 are
    % included in the average as well as particles with class value iclass
    num_good_ptcls = sum(all_motl(20, :) == 1 | all_motl(20, :) == iclass);

    % We calculate subsets in powers of two of the data but limit the smallest
    % subset that contains at least 128 particles.
    num_subsets = floor(log2(num_good_ptcls / 128)) + 1;

    % Now that we know how many subsets need to calculated we can see if they
    % have already been calculated and skip if so.
    all_done = 1;

    for subset_idx = 1:num_subsets
        ref_fn = sprintf('%s_subset_%d_%d.em', ref_fn_prefix, subset_idx, ...
            iteration);

        if exist(ref_fn, 'file') ~= 2
            all_done = 0;
            break
        end
    end

    if all_done
        warning('subTOM:recoverOnFail', ...
            'weighted_average_bfactor:File %s already exists. SKIPPING!', ...
            ref_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Initialize particle average array Normally you can run one iteration out
    % of the loop to get the box sizes, but it's too complicated with the
    % subsets so we just read the first subset reference batch and that gives us
    % the size to initialize the cell arrays.
    check_fn = sprintf('%s_subset_1_%d_1.em', ref_fn_prefix, iteration);

    if exist(check_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'weighted_average_bfactor:File %s does not exist.', check_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Note the transpose, tom_reademheader returns a column vector, but Matlab
    % size function returns a row vector, and ones and zeros need row vector
    box_size = getfield(tom_reademheader(check_fn), 'Header', 'Size')';

    avg_sum_cell = arrayfun(@(x) zeros(box_size), 1:num_subsets, ...
        'UniformOutput', 0);

    weight_sum_cell = arrayfun(@(x) zeros(box_size), 1:num_subsets, ...
        'UniformOutput', 0);

    % Setup the progress bar
    delprog = '';
    timings = [];
    message = sprintf('Weighted Subsets Averaging');
    op_type = 'batches';
    tic;

    % Sum remaining reference files
    for batch_idx = 1:num_avg_batch

        % Handle each subset
        for subset_idx = 1:num_subsets
            ref_fn = sprintf('%s_subset_%d_%d_%d.em', ref_fn_prefix, ...
                subset_idx, iteration, batch_idx);

            if exist(ref_fn, 'file') ~= 2
                try
                    error('subTOM:missingFileError', ...
                        'weighted_average_bfactor:File %s does not exist.', ...
                        ref_fn);

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            ref = getfield(tom_emread(ref_fn), 'Value');

            if ~all(size(ref) == box_size)
                try
                    error('subTOM:volDimError', ...
                        'weighted_average_bfactor:%s and %s %s.', ...
                        ref_fn, check_fn, 'are not same size');

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            avg_sum_cell{subset_idx} = avg_sum_cell{subset_idx} + ref;

            weight_sum_fn = sprintf('%s_subset_%d_%d_%d.em', ...
                weight_sum_fn_prefix, subset_idx, iteration, batch_idx);

            if exist(weight_sum_fn, 'file') ~= 2
                try
                    error('subTOM:missingFileError', ...
                        'weighted_average_bfactor:File %s does not exist.', ...
                        weight_sum_fn);

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            weight_sum = getfield(tom_emread(weight_sum_fn), 'Value');

            if ~all(size(weight_sum) == box_size)
                try
                    error('subTOM:volDimError', ...
                        'weighted_average_bfactor:%s and %s %s.', ...
                        weight_sum_fn, check_fn, 'are not same size');

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            weight_sum_cell{subset_idx} = weight_sum_cell{subset_idx} + ...
                weight_sum;

        end

        % Display some output
        [delprog, timings] = subtom_display_progress(delprog, timings, ...
            message, op_type, num_avg_batch, batch_idx);

    end

    % Determine low pass filter dimensions, this filter takes out the last few
    % high frequency pixels, which dampens interpolation artefacts from
    % rotations etc.
    spheremask_radius = floor(box_size(1) / 2) - 3;

    % Do the final weighted average for each subset.
    for subset_idx = 1:num_subsets

        % The number of good particles that went into the subset
        subset_num_good_ptcls = sum(mod(1:num_good_ptcls, ...
            2^(subset_idx - 1) == 0));

        % Calculate raw subset average from batches.
        average_raw = avg_sum_cell{subset_idx} ./ subset_num_good_ptcls;

        % Calculate the average weight subset from batches.
        weight_average = weight_sum_cell{subset_idx} ./ subset_num_good_ptcls;
        weight_average = weight_average ./ max(weight_average(:));

        % Calculate the average weight inverse subset that will reweight the
        % average.
        weight_average_inverse = 1 ./ weight_average;

        % Find any inf (Infinity) values in the inverse and set them to zero
        inf_idxs = find(weight_average_inverse > 10000);

        if ~isempty(inf_idxs)
            weight_average_inverse(inf_idxs) = 0;
        end

        % Apply the weight to the average
        average_fft = fftshift(fftn(average_raw));
        average_fft = average_fft .* weight_average_inverse;
        average_fft = tom_spheremask(average_fft, spheremask_radius);
        average = ifftn(ifftshift(average_fft), 'symmetric');

        % Write-out subset average and debug files
        average_raw_fn = sprintf('%s_subset_%d_debug_raw_%d.em', ...
            ref_fn_prefix, subset_idx, iteration);

        tom_emwrite(average_raw_fn, average_raw);
        subtom_check_em_file(average_raw_fn, average_raw);

        weight_average_fn = sprintf('%s_subset_%d_debug_%d.em', ...
            weight_sum_fn_prefix, subset_idx, iteration);

        tom_emwrite(weight_average_fn, weight_average);
        subtom_check_em_file(weight_average_fn, weight_average);

        weight_average_inverse_fn = sprintf('%s_subset_%d_debug_inv_%d.em', ...
            weight_sum_fn_prefix, subset_idx, iteration);

        tom_emwrite(weight_average_inverse_fn, weight_average_inverse);
        subtom_check_em_file(weight_average_inverse_fn, weight_average_inverse);

        average_fn = sprintf('%s_subset_%d_%d.em', ref_fn_prefix, ...
            subset_idx, iteration);

        tom_emwrite(average_fn, average);
        subtom_check_em_file(average_fn, average);
    end
end
