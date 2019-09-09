function subtom_weighted_average_cls(varargin)
% SUBTOM_WEIGHTED_AVERAGE_CLS joins and weights parallel average subsets.
%
%     SUBTOM_WEIGHTED_AVERAGE_CLS(
%         'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX,
%         'ref_fn_prefix', REF_FN_PREFIX,
%         'weight_sum_fn_prefix', WEIGHT_SUM_FN_PREFIX,
%         'iteration', ITERATION,
%         'num_avg_batch', NUM_AVG_BATCH)
%
%     Takes the NUM_AVG_BATCH parallel sum subsets with the name prefix
%     REF_FN_PREFIX, the all_motl file with name prefix MOTL_FN_PREFIX and
%     weight volume subsets with the name prefix WEIGHT_SUM_FN_PREFIX to
%     generate the final average, which should then be used as the reference for
%     iteration number ITERATION. In this multi-reference version of weighted
%     average, each unique value of iclass (row 20 in the motive list) will be
%     averaged and written out (excluding non-positive values).
%
% See also SUBTOM_PARALLEL_SUMS_CLS

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
                'weighted_average_cls:all_motl_dir: Directory %s %s.', ...
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
                'weighted_average_cls:ref_dir: Directory %s %s.', ...
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
                'weighted_average_cls:weight_sum_dir: Directory %s %s.', ...
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
            'subtom_weighted_average_cls', 'iteration');

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
            'subtom_weighted_average_cls', 'num_avg_batch');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%
    % We need to read in the all_motl for the next part
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(all_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'weighted_average_cls:File %s does not exist.', all_motl_fn);

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
                'weighted_average_cls:%s is not proper MOTL.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Find the number of valid classes in the motive list.
    classes = unique(all_motl(20, :));
    classes = classes(classes > 0);
    num_classes = length(classes);

    % Check if the average already exists and if so we exit early.
    all_complete = 1;

    for class = classes
        sum_fn = sprintf('%s_class_%d_%d.em', ref_fn_prefix, class, iteration);

        weight_sum_fn = sprintf('%s_class_%d_%d.em', weight_sum_fn_prefix, ...
            class, iteration);

        if exist(sum_fn, 'file') ~= 2 || exist(weight_sum_fn, 'file') ~= 2
            all_complete = 0;
            break
        end
    end

    if all_complete
        warning('subTOM:recoverOnFail', ...
            'weighted_average_cls:File %s already exists. SKIPPING!', sum_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Read the first sum from the first class to get the box size.
    check_fn = sprintf('%s_class_%d_%d_1.em', ref_fn_prefix, classes(1), ...
        iteration);

    if exist(check_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'weighted_average_cls:File %s does not exist.', check_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Note the transpose, tom_reademheader returns a column vector, but Matlab
    % size function returns a row vector, and ones and zeros need row vector
    box_size = getfield(tom_reademheader(check_fn), 'Header', 'Size')';

    % Determine low pass filter dimensions, this filter takes out the last few
    % high frequency pixels, which dampens interpolation artefacts from
    % rotations etc.
    spheremask_radius = floor(max(box_size) / 2) - 3;

    avg_sum = arrayfun(@(x) zeros(box_size), 1:num_classes, ...
        'UniformOutput', 0);

    weight_avg_sum = arrayfun(@(x) zeros(box_size), 1:num_classes, ...
        'UniformOutput', 0);

    % Loop over the classes and generate each weighted average
    for class_idx = 1:num_classes
        class = classes(class_idx);

        % Setup the progress bar
        delprog = '';
        timings = [];
        message = sprintf('Weighted Averaging Class %d', class);
        op_type = 'batches';
        tic;

        % Sum the batch files
        for batch_idx = 1:num_avg_batch
            sum_fn = sprintf('%s_class_%d_%d_%d.em', ref_fn_prefix, class, ...
                iteration, batch_idx);

            if exist(sum_fn, 'file') ~= 2
                try
                    error('subTOM:missingFileError', ...
                        'weighted_average_cls:File %s does not exist.', sum_fn);

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            sum_vol = getfield(tom_emread(sum_fn), 'Value');

            if ~all(size(sum_vol) == box_size)
                try
                    error('subTOM:volDimError', ...
                        'weighted_average_cls:%s and %s are not same size.', ...
                        sum_fn, check_fn);

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            avg_sum{class_idx} = avg_sum{class_idx} + sum_vol;

            weight_sum_fn = sprintf('%s_class_%d_%d_%d.em', ...
                weight_sum_fn_prefix, class, iteration, batch_idx);

            if exist(weight_sum_fn, 'file') ~= 2
                try
                    error('subTOM:missingFileError', ...
                        'weighted_average_cls:File %s does not exist.', ...
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
                        'weighted_average_cls:%s and %s are not same size.', ...
                        weight_sum_fn, check_fn);

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            weight_avg_sum{class_idx} = weight_avg_sum{class_idx} + weight_sum;

            % Display some output
            [delprog, timings] = subtom_display_progress(delprog, timings, ...
                message, op_type, num_avg_batch, batch_idx);

        end

        % Find number of motls from each class.
        num_good_ptcls = sum(all_motl(20, :) == class);

        % Calculate raw average from batches
        average_raw = avg_sum{class_idx} ./ num_good_ptcls;

        % Calculate the average weight from batches
        weight_average = weight_avg_sum{class_idx} ./ num_good_ptcls;
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
        average_raw_fn = sprintf('%s_class_%d_debug_raw_%d.em', ...
            ref_fn_prefix, class, iteration);

        tom_emwrite(average_raw_fn, average_raw);
        subtom_check_em_file(average_raw_fn, average_raw);

        weight_average_fn = sprintf('%s_class_%d_debug_%d.em', ...
            weight_sum_fn_prefix, class, iteration);

        tom_emwrite(weight_average_fn, weight_average);
        subtom_check_em_file(weight_average_fn, weight_average);

        weight_average_inverse_fn = sprintf('%s_class_%d_debug_inv_%d.em', ...
            weight_sum_fn_prefix, class, iteration);

        tom_emwrite(weight_average_inverse_fn, weight_average_inverse);
        subtom_check_em_file(weight_average_inverse_fn, weight_average_inverse);

        average_fn = sprintf('%s_class_%d_%d.em', ref_fn_prefix, class, ...
            iteration);

        tom_emwrite(average_fn, average);
        subtom_check_em_file(average_fn, average);
    end

    % Write out montages of the averages which is very useful for
    % visualization
    num_cols = 10;
    num_rows = ceil(num_classes / num_cols);

    % We do a montage in X, Y, and Z orientations
    for montage_idx = 1:3
        montage = zeros(box_size(1) * num_cols, box_size(2) * num_rows, ...
            box_size(3));

        for class_idx = 1:num_classes
            row_idx = floor((class_idx - 1) / num_cols) + 1;
            col_idx = class_idx - ((row_idx - 1) * num_cols);
            start_x = (col_idx - 1) * box_size(1) + 1;
            end_x = start_x + box_size(1) - 1;
            start_y = (row_idx - 1) * box_size(2) + 1;
            end_y = start_y + box_size(2) - 1;
            
            class = classes(class_idx);

            if montage_idx == 1
                montage(start_x:end_x, start_y:end_y, :) = ...
                    getfield(tom_emread(sprintf('%s_class_%d_%d.em', ...
                    ref_fn_prefix, class, iteration)), 'Value');

            elseif montage_idx == 2
                montage(start_x:end_x, start_y:end_y, :) = ...
                    tom_rotate(getfield(tom_emread(sprintf(...
                    '%s_class_%d_%d.em', ref_fn_prefix, class, iteration)), ...
                    'Value'), [0, 0, -90]);

            elseif montage_idx == 3
                montage(start_x:end_x, start_y:end_y, :) = ...
                    tom_rotate(getfield(tom_emread(sprintf(...
                    '%s_class_%d_%d.em', ref_fn_prefix, class, iteration)), ...
                    'Value'), [90, 0, -90]);

            end
        end

        if montage_idx == 1
            montage_fn = sprintf('%s_Z_%d.em', ref_fn_prefix, iteration);

        elseif montage_idx == 2
            montage_fn = sprintf('%s_X_%d.em', ref_fn_prefix, iteration);

        elseif montage_idx == 3
            montage_fn = sprintf('%s_Y_%d.em', ref_fn_prefix, iteration);

        end

        tom_emwrite(montage_fn, montage);
        subtom_check_em_file(montage_fn, montage);
    end
end
