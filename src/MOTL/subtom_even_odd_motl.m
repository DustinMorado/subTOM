function subtom_even_odd_motl(varargin)
% SUBTOM_EVEN_ODD_MOTL split a MOTL file into even odd halves
%
%     SUBTOM_EVEN_ODD_MOTL(
%         'input_motl_fn', INPUT_MOTL_FN,
%         'output_motl_fn', OUTPUT_MOTL_FN)
%         'even_motl_fn', EVEN_MOTL_FN,
%         'odd_motl_fn', ODD_MOTL_FN,
%         'split_row', SPLIT_ROW,
%
%    Takes the MOTL file specified by INPUT_MOTL_FN and writes out seperate MOTL
%    files with EVEN_MOTL_FN and ODD_MOTL_FN where each output file corresponds
%    to roughly half of INPUT_MOTL_FN. The motive list can also write a single
%    motive list file with the half split described using the iclass (20th row
%    of the motive list) where the odd half takes particle's current class
%    number plus 100 and the even half takes the particle's current class number
%    plus 200. The MOTL is split by the values in SPLIT_ROW, initially just
%    taking even/odd halves of the unique values in that given row, and then
%    this is slightly adjusted by naively adding to the lesser half until
%    closest to half is found.
%
% See also SUBTOM_SPLIT_MOTL_BY_ROW

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'input_motl_fn', '');
    addParameter(fn_parser, 'output_motl_fn', '');
    addParameter(fn_parser, 'even_motl_fn', '');
    addParameter(fn_parser, 'odd_motl_fn', '');
    addParameter(fn_parser, 'split_row', '4');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    input_motl_fn = fn_parser.Results.input_motl_fn;

    if isempty(input_motl_fn)
        try
            error('subTOM:missingRequired', ...
                'even_odd_motl:Parameter %s is required.', ...
                'input_motl_fn');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if exist(input_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'even_odd_motl:File %s does not exist.', input_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    input_motl = getfield(tom_emread(input_motl_fn), 'Value');

    if size(input_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'even_odd_motl:%s is not proper MOTL.', input_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    output_motl_fn = fn_parser.Results.output_motl_fn;

    if ~isempty(output_motl_fn)
        fid = fopen(output_motl_fn, 'w');

        if fid == -1
            try
                error('subTOM:writeFileError', ...
                    'even_odd_motl:File %s cannot be opened for writing', ...
                    output_motl_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        fclose(fid);
    end

    even_motl_fn = fn_parser.Results.even_motl_fn;

    if ~isempty(even_motl_fn)
        fid = fopen(even_motl_fn, 'w');

        if fid == -1
            try
                error('subTOM:writeFileError', ...
                    'even_odd_motl:File %s cannot be opened for writing', ...
                    even_motl_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        fclose(fid);
    end

    odd_motl_fn = fn_parser.Results.odd_motl_fn;

    if ~isempty(odd_motl_fn)
        fid = fopen(odd_motl_fn, 'w');

        if fid == -1
            try
                error('subTOM:writeFileError', ...
                    'even_odd_motl:File %s cannot be opened for writing', ...
                    odd_motl_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        fclose(fid);
    end

    if (~isempty(even_motl_fn) && isempty(odd_motl_fn)) || ...
        (isempty(even_motl_fn) && ~isempty(odd_motl_fn))

        try
            error('subTOM:argumentError', ...
                'even_odd_motl:Parameters %s and %s %s.', ...
                'even_motl_fn', 'odd_motl_fn', 'must be given together');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if isempty(output_motl_fn) && isempty(even_motl_fn)
        try
            error('subTOM:missingRequired', ...
                'even_odd_motl:Parameter %s or %s and %s %s.', ...
                'output_motl_fn', 'even_motl_fn', 'odd_motl_fn', ...
                'must be given.');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    split_row = fn_parser.Results.split_row;

    if ischar(split_row)
        split_row = str2double(split_row);
    end

    try
        validateattributes(split_row, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0, '<', 21}, ...
            'subtom_even_odd_motl', 'split_row');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Determine the number of unique values in the requested row to split by.
    split_vals = unique(input_motl(split_row, :));
    num_split_vals = length(split_vals);

    % Make sure there is more than one value to split by.
    if num_split_vals == 1
        try
            error('subTOM:SplitError', ...
                'even_odd_motl:%s only has one value in row %d.', ...
                input_motl_fn, split_row)

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Our initial guess for the odd half motive list is all odd indices of the
    % unique values in the requested split row.
    start_odd = 1;
    odd_idxs = [start_odd:2:num_split_vals];

    % Calculate the odd motive list.
    odd_motl  = input_motl(:, ...
        ismember(input_motl(split_row, :), split_vals(odd_idxs)));

    % Our initial guess for the even half motive list is all even indices of the
    % unique values in the requested split row.
    start_even = 2;
    even_idxs = [start_even:2:num_split_vals];

    % Calculate the odd motive list.
    even_motl = input_motl(:, ...
        ismember(input_motl(split_row, :), split_vals(even_idxs)));

    % Create a cell array of motive lists
    split_cell{1, 1} = odd_motl;
    split_cell{2, 1} = even_motl;

    % Handle the special case when the motive list is odd-sized and is split
    % over a row with all unique values (i.e. row 4) then the loop can go on
    % for a long time swapping odd and even entirely before stopping and
    % none of them improve the ratio.
    if num_split_vals == size(input_motl, 20)

        % Handle the case when we write a single output file with the even and
        % half split described in the class number (row 20), the odd particles
        % inherit their previous class plus 100 and the even particles inherit
        % their previous class pluss 200.
        if ~isempty(output_motl_fn)

            % The output motive list is initially the input motive list.
            output_motl = input_motl;

            % Find the particles that are in the odd half.
            odd_ptcls = ismember(output_motl(4, :), odd_motl(4, :));

            % Add 100 to the odd particles class number.
            output_motl(20, odd_ptcls) = output_motl(20, odd_ptcls) + 100;

            % Find the particles that are in the even half.
            even_ptcls = ismember(output_motl(4, :), even_motl(4, :));

            % Add 200 to the even particles class number.
            output_motl(20, even_ptcls) = output_motl(20, even_ptcls) + 200;

            % Write out the motive list
            tom_emwrite(output_motl_fn, output_motl);
            subtom_check_em_file(output_motl_fn, output_motl);
        end

        % Handle the case when the user wants individual even and odd half
        % motive lists.
        if ~isempty(even_motl_fn)
            tom_emwrite(odd_motl_fn, odd_motl);
            subtom_check_em_file(odd_motl_fn, odd_motl);
            tom_emwrite(even_motl_fn, even_motl);
            subtom_check_em_file(even_motl_fn, even_motl);
        end

        return
    end

    % Iterate until we get to perfectly sized halves or until we force a break.
    while true

        % Handle the case when odd is bigger than even.
        if size(split_cell{1, end}, 2) > size(split_cell{2, end}, 2)

            % Test first if start_odd is bigger than the number of fields to
            % split over and if so we break.
            if start_odd > num_split_vals
                break
            end

            % We try to remove the first odd index from the odd half and add it
            % to the even half.
            odd_idxs = odd_idxs(odd_idxs ~= start_odd);
            even_idxs = [start_odd, even_idxs];
            start_odd = start_odd + 2;

            % Handle the case where the odd half only has one value in it, which
            % we can't remove so we exit out of the loop.
            if isempty(odd_idxs)
                break
            end

            % Calculate the new odd and even half motive lists.
            odd_motl = input_motl(:, ...
                ismember(input_motl(split_row, :), split_vals(odd_idxs)));

            even_motl = input_motl(:, ...
                ismember(input_motl(split_row, :), split_vals(even_idxs)));

            % Add the new half motive lists to the cell array
            split_cell{1, end + 1} = odd_motl;
            split_cell{2, end    } = even_motl;

        % Handle the case when odd is smaller than even.
        elseif size(split_cell{1, end}, 2) < size(split_cell{2, end}, 2)

            % Test first if start_even is bigger than the number of fields to
            % split over and if so we break.
            if start_even > num_split_vals
                break
            end

            % We try to remove the first even index from the even half and add
            % it to the odd half.
            even_idxs = even_idxs(even_idxs ~= start_even);
            odd_idxs = [start_even, odd_idxs];
            start_even = start_even + 2;

            % Handle the case where the even half only has one value in it,
            % which we can't remove so we exit out of the loop.
            if isempty(even_idxs)
                break
            end

            % Calculate the new odd and even half motive lists.
            odd_motl = input_motl(:, ...
                ismember(input_motl(split_row, :), split_vals(odd_idxs)));

            even_motl = input_motl(:, ...
                ismember(input_motl(split_row, :), split_vals(even_idxs)));

            % Add the new half motive lists to the cell array
            split_cell{1, end + 1} = odd_motl;
            split_cell{2, end    } = even_motl;

        % Handle the case when odd is equal to even.
        else
            break
        end
    end

    % Find which of the splits has the closest to half ratio.
    even_odd_ratios = ones(1, size(split_cell, 2));

    % Loop over all of the split attempts
    for split_idx = 1:size(split_cell, 2)

        % Calculate how far off the split is from being perfect. The lower the
        % number the closer to completely halved.
        even_odd_ratios(split_idx) = abs(1 - ...
            size(split_cell{1, split_idx}, 2) / ...
            size(split_cell{2, split_idx}, 2));

    end

    best_split = find(even_odd_ratios == min(even_odd_ratios));

    odd_motl = split_cell{1, best_split};
    even_motl = split_cell{2, best_split};

    % Handle the case when we write a single output file with the even and half
    % split described in the class number (row 20), the odd particles inherit
    % their previous class plus 100 and the even particles inherit their
    % previous class pluss 200.
    if ~isempty(output_motl_fn)

        % The output motive list is initially the input motive list.
        output_motl = input_motl;

        % Find the particles that are in the odd half.
        odd_ptcls = ismember(output_motl(4, :), odd_motl(4, :));

        % Add 100 to the odd particles class number.
        output_motl(20, odd_ptcls) = output_motl(20, odd_ptcls) + 100;

        % Find the particles that are in the even half.
        even_ptcls = ismember(output_motl(4, :), even_motl(4, :));

        % Add 200 to the even particles class number.
        output_motl(20, even_ptcls) = output_motl(20, even_ptcls) + 200;

        % Write out the motive list
        tom_emwrite(output_motl_fn, output_motl);
        subtom_check_em_file(output_motl_fn, output_motl);
    end

    % Handle the case when the user wants individual even and odd half
    % motive lists.
    if ~isempty(even_motl_fn)
        tom_emwrite(odd_motl_fn, odd_motl);
        subtom_check_em_file(odd_motl_fn, odd_motl);
        tom_emwrite(even_motl_fn, even_motl);
        subtom_check_em_file(even_motl_fn, even_motl);
    end
end
