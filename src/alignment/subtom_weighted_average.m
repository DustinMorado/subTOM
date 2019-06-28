function subtom_weighted_average(varargin)
% SUBTOM_WEIGHTED_AVERAGE joins and weights parallel average subsets.
%
%     SUBTOM_WEIGHTED_AVERAGE(
%         'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX,
%         'ref_fn_prefix', REF_FN_PREFIX,
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
% See also SUBTOM_PARALLEL_SUMS

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
                'weighted_average:all_motl_dir: Directory %s %s.', ...
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
                'weighted_average:ref_dir: Directory %s %s.', ...
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
                'weighted_average:weight_sum_dir: Directory %s %s.', ...
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
            'subtom_weighted_average', 'iteration');

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
            'subtom_weighted_average', 'iclass');

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
            'subtom_weighted_average', 'num_avg_batch');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Check if the average already exists and if so we exit early.
    average_fn = sprintf('%s_%d.em', ref_fn_prefix, iteration);

    if exist(average_fn, 'file') == 2
        warning('subTOM:recoverOnFail', ...
            'weighted_average:File %s already exists. SKIPPING!', average_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Run the first batch outside of a loop to initialize volumes without having
    % to know the box size of particles and weights
    ref_fn = sprintf('%s_%d_1.em', ref_fn_prefix, iteration);
    weight_sum_fn = sprintf('%s_%d_1.em', weight_sum_fn_prefix, iteration);

    if exist(ref_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'weighted_average:File %s does not exist.', ref_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    check_fn = ref_fn;

    if exist(weight_sum_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'weighted_average:File %s does not exist.', weight_sum_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    avg_sum = getfield(tom_emread(ref_fn), 'Value');
    weight_avg_sum = getfield(tom_emread(weight_sum_fn), 'Value');
    box_size = size(avg_sum);

    if ~all(size(weight_avg_sum) == box_size)
        try
            error('subTOM:volDimError', ...
                'weighted_average:%s and %s are not same size.', ...
                weight_sum_fn, check_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Setup the progress bar
    delprog = '';
    timings = [];
    message = sprintf('Weighted Averaging');
    op_type = 'batches';
    tic;

    % Sum the remaining batch files
    for batch_idx = 2:num_avg_batch
        ref_fn = sprintf('%s_%d_%d.em', ref_fn_prefix, iteration, ...
            batch_idx);

        if exist(ref_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'weighted_average:File %s does not exist.', ref_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        ref = getfield(tom_emread(ref_fn), 'Value');

        if ~all(size(ref) == box_size)
            try
                error('subTOM:volDimError', ...
                    'weighted_average:%s and %s are not same size.', ...
                    ref_fn, check_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        avg_sum = avg_sum + ref;

        weight_sum_fn = sprintf('%s_%d_%d.em', weight_sum_fn_prefix, ...
            iteration, batch_idx);

        if exist(weight_sum_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'weighted_average:File %s does not exist.', weight_sum_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        weight_sum = getfield(tom_emread(weight_sum_fn), 'Value');

        if ~all(size(weight_sum) == box_size)
            try
                error('subTOM:volDimError', ...
                    'weighted_average:%s and %s are not same size.', ...
                    weight_sum_fn, check_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        weight_avg_sum = weight_avg_sum + weight_sum;

        % Display some output
        [delprog, timings] = subtom_display_progress(delprog, timings, ...
            message, op_type, num_avg_batch, batch_idx);

    end

    % We need to read in the all_motl for the next part
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(all_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'weighted_average:File %s does not exist.', all_motl_fn);

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
                'weighted_average:%s is not proper MOTL.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Find motls with the good classes and number of motls used in sums
    % When iclass is not zero then all particles with class value of 1 are
    % included in the average as well as particles with class value iclass
    num_good_ptcls = sum(all_motl(20, :) == 1 | all_motl(20, :) == iclass);

    % Determine low pass filter dimensions, this filter takes out the last few
    % high frequency pixels, which dampens interpolation artefacts from
    % rotations etc.
    spheremask_radius = floor(size(avg_sum, 1) / 2) - 3;

    % Calculate raw average from batches
    average_raw = avg_sum ./ num_good_ptcls;

    % Calculate the average weight from batches
    weight_average = weight_avg_sum ./ num_good_ptcls;
    weight_average = weight_average ./ max(weight_average(:));

    % Calculate the average weight inverse that will reweight the average
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

    % Write-out average and debug files
    average_raw_fn = sprintf('%s_debug_raw_%d.em', ref_fn_prefix, iteration);
    tom_emwrite(average_raw_fn, average_raw);
    subtom_check_em_file(average_raw_fn, average_raw);

    weight_average_fn = sprintf('%s_debug_%d.em', weight_sum_fn_prefix, ...
        iteration);

    tom_emwrite(weight_average_fn, weight_average);
    subtom_check_em_file(weight_average_fn, weight_average);

    weight_average_inverse_fn = sprintf('%s_debug_inv_%d.em', ...
        weight_sum_fn_prefix, iteration);

    tom_emwrite(weight_average_inverse_fn, weight_average_inverse);
    subtom_check_em_file(weight_average_inverse_fn, weight_average_inverse);

    tom_emwrite(average_fn, average);
    subtom_check_em_file(average_fn, average);
end
