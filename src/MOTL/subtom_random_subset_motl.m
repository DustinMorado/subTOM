function subtom_random_subset_motl(varargin)
% SUBTOM_RANDOM_SUBSET_MOTL generates a random subset of a motive list.
%
%     SUBTOM_RANDOM_SUBSET_MOTL(
%         'input_motl_fn', INPUT_MOTL_FN,
%         'output_motl_fn', OUTPUT_MOTL_FN,
%         'subset_size', SUBSET_SIZE,
%         'subset_row', SUBSET_ROW)
%
%     Takes the motive list given by INPUT_MOTL_FN, and generates a random
%     subset of SUBSET_SIZE particles where the subset is distributed equally
%     over the motive list field SUBSET_ROW, and then writes the subset motive
%     list out as OUTPUT_MOTL_FN.

% DRM 09-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'input_motl_fn', '');
    addParameter(fn_parser, 'output_motl_fn', '');
    addParameter(fn_parser, 'subset_size', '1000');
    addParameter(fn_parser, 'subset_row', '7');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    input_motl_fn = fn_parser.Results.input_motl_fn;

    if isempty(input_motl_fn)
        try
            error('subTOM:missingRequired', ...
                'random_subset_motl:Parameter %s is required.', ...
                'input_motl_fn');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if exist(input_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'random_subset_motl:File %s does not exist.', input_motl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    input_motl = getfield(tom_emread(input_motl_fn), 'Value');

    if size(input_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'random_subset_motl:%s is not proper MOTL.', input_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    output_motl_fn = fn_parser.Results.output_motl_fn;

    if isempty(output_motl_fn)
        try
            error('subTOM:missingRequired', ...
                'random_subset_motl:Parameter %s is required.', ...
                'output_motl_fn');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    fid = fopen(output_motl_fn, 'w');

    if fid == -1
        try
            error('subTOM:writeFileError', ...
                'random_subset_motl:File %s cannot be opened for writing', ...
                output_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    fclose(fid);

    num_ptcls = size(input_motl, 2);
    subset_size = fn_parser.Results.subset_size;

    if ischar(subset_size)
        subset_size = str2double(subset_size);
    end

    try
        validateattributes(subset_size, {'numeric'}, ...
            {'scalar', 'nonnan', 'positive', 'integer', '<=', num_ptcls}, ...
            'subtom_random_subset_motl', 'subset_size');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    subset_row = fn_parser.Results.subset_row;

    if ischar(subset_row)
        subset_row = str2double(subset_row);
    end

    try
        validateattributes(subset_row, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0, '<', 21}, ...
            'subtom_random_subset_motl', 'subset_row');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%
    % Figure out if we need to distribute subset particles over the given
    % subset_row.
    row_vals = unique(input_motl(subset_row, :));
    num_row_vals = length(row_vals);

    % If there are more unique values than particles in the subset we ignore the
    % row. We also ignore if there is just one constant value in the row.
    if num_row_vals > subset_size
        use_row = 0;
    elseif num_row_vals == 1
        use_row = 0;
    else
        use_row = 1;
        row_subset_size = floor(subset_size / num_row_vals);
        row_subset_rem = rem(subset_size, num_row_vals);
        rem_idx = 0;
    end

    % Handle the case when we are using the row, followed by the not-used case.
    if use_row
        output_motl = [];

        % We need to handle the case when a field of the given row does not have
        % enough particles to satisfy an even distribution, which is annoying
        % but not terrible. Here we find out the number of particles unique to
        % each field value.
        row_sizes = arrayfun(@(x) size(input_motl(:, ...
            input_motl(subset_row, :) == row_vals(x)), 2), 1:num_row_vals);

        % Here we sort the field values based on their size in increasing order.
        % And we also get the indices of the rows after sorting.
        [sorted_row_sizes, sorted_row_idxs] = sort(row_sizes);

        % Loop over the unique row values.
        for sorted_row_idx = 1:num_row_vals
            % Calculate the actual batch size handling the remainders.
            row_motl_size = sorted_row_sizes(sorted_row_idx);

            % Row value is a bit complicated
            row_val = row_vals(sorted_row_idxs(sorted_row_idx));

            % Handle when there are not enough particles to satisfy the even
            % distribution.
            if row_motl_size <= row_subset_size
                % add all of the particles from the row to the subset
                output_motl = horzcat(output_motl, ...
                    input_motl(:, input_motl(subset_row, :) == row_val));

                % Recalculate the subset size and remainder size.
                subset_size_ = subset_size - size(output_motl, 2);
                num_row_vals_ = num_row_vals - sorted_row_idx;
                row_subset_size = floor(subset_size_ / num_row_vals_);
                row_subset_rem = rem(subset_size_, num_row_vals_);
                rem_idx = 0;
            else
                if rem_idx < row_subset_rem
                    row_subset_size_ = row_subset_size + 1;
                    rem_idx = rem_idx + 1;
                else
                    row_subset_size_ = row_subset_size;
                end

                % Get the particles with the current row value
                row_motl = input_motl(:, ...
                    input_motl(subset_row, :) == row_val);

                row_motl_size = size(row_motl, 2);

                output_motl = horzcat(output_motl, ...
                    row_motl(:, randperm(row_motl_size, row_subset_size_)));

            end
        end
    else
        output_motl = input_motl(:, randperm(num_ptcls, subset_size));
    end

    % Write out the motive list subset.
    tom_emwrite(output_motl_fn, output_motl);
    subtom_check_em_file(output_motl_fn, output_motl);
end
