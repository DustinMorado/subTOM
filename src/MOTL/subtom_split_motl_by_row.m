function subtom_split_motl_by_row(varargin)
% SUBTOM_SPLIT_MOTL_BY_ROW split a MOTL file by a given row.
%
%     SUBTOM_SPLIT_MOTL_BY_ROW(
%         'input_motl_fn', INPUT_MOTL_FN,
%         'output_motl_fn_prefix', OUTPUT_MOTL_FN_PREFIX,
%         'split_row', SPLIT_ROW)
%
%    Takes the MOTL file specified by INPUT_MOTL_FN and writes out a seperate
%    MOTL file with OUTPUT_MOTL_FN_PRFX as the prefix where each output file
%    corresponds to a unique value of the row SPLIT_ROW in INPUT_MOTL_FN.
%
% See also SUBTOM_SCALE_MOTL

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'input_motl_fn', '');
    addParameter(fn_parser, 'output_motl_fn_prefix', '');
    addParameter(fn_parser, 'split_row', '7');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    input_motl_fn = fn_parser.Results.input_motl_fn;

    if isempty(input_motl_fn)
        try
            error('subTOM:missingRequired', ...
                'split_motl_by_row:Parameter %s is required.', ...
                'input_motl_fn');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if exist(input_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'split_motl_by_row:File %s does not exist.', input_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    input_motl = getfield(tom_emread(input_motl_fn), 'Value');

    if size(input_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'split_motl_by_row:%s is not proper MOTL.', input_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    output_motl_fn_prefix = fn_parser.Results.output_motl_fn_prefix;

    if isempty(output_motl_fn_prefix)
        try
            error('subTOM:missingRequired', ...
                'split_motl_by_row:Parameter %s is required.', ...
                'output_motl_fn_prefix');

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
            'subtom_split_motl_by_row', 'split_row');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Find the unique values with the requested row in the motive list.
    row_values = unique(input_motl(split_row, :));

    % Find the number of unique values within the request row.
    num_outputs = length(row_values);

    % Create an initial format string for the eventual output filenames.
    output_motl_fmt = sprintf('%s_%%0%dd.em', output_motl_fn_prefix, ...
        length(num2str(num_outputs)));

    % Loop over the unique values within the requested row.
    for row_value = row_values

        % Determine the motive list subset.
        split_motl = input_motl(:, input_motl(split_row, :) == row_value);

        % Determine the filename for the subset
        split_motl_fn = sprintf(output_motl_fmt, row_value);

        % Make sure we can open the file for writing.
        fid = fopen(split_motl_fn, 'w');

        if fid == -1
            try
                error('subTOM:writeFileError', ...
                    'split_motl_by_row:File %s %s.', ...
                    split_motl_fn, 'cannot be opened for writing');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        fclose(fid);

        % Write out the subset motive list.
        tom_emwrite(split_motl_fn, split_motl);
        subtom_check_em_file(split_motl_fn, split_motl);
    end
end
