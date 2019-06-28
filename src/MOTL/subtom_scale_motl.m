function subtom_scale_motl(varargin)
% SUBTOM_SCALE_MOTL scales a given motive list by a given factor.
%
%     SUBTOM_SCALE_MOTL(
%         'input_motl_fn', INPUT_MOTL_FN,
%         'output_motl_fn', OUTPUT_MOTL_FN,
%         'scale_factor', SCALE_FACTOR)
%
%     Takes the motive list given by INPUT_MOTL_FN, and scales it by
%     SCALE_FACTOR, and then writes the transformed motive list out as
%     OUTPUT_MOTL_FN.

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
    addParameter(fn_parser, 'scale_factor', '1');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    input_motl_fn = fn_parser.Results.input_motl_fn;

    if isempty(input_motl_fn)
        try
            error('subTOM:missingRequired', ...
                'scale_motl:Parameter %s is required.', ...
                'input_motl_fn');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if exist(input_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'scale_motl:File %s does not exist.', input_motl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    input_motl = getfield(tom_emread(input_motl_fn), 'Value');

    if size(input_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'scale_motl:%s is not proper MOTL.', input_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    output_motl_fn = fn_parser.Results.output_motl_fn;

    if isempty(output_motl_fn)
        try
            error('subTOM:missingRequired', ...
                'scale_motl:Parameter %s is required.', ...
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
                'scale_motl:File %s cannot be opened for writing', ...
                output_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    fclose(fid);

    scale_factor = fn_parser.Results.scale_factor;

    if ischar(scale_factor)
        scale_factor = str2double(scale_factor);
    end

    try
        validateattributes(scale_factor, {'numeric'}, ...
            {'scalar', 'nonnan', 'positive'}, ...
            'subtom_scale_motl', 'scale_factor');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Initially copy the output motive list as the input motive list.
    output_motl = input_motl;

    % Set the pre-rotation translations to the full scaled coordinates, this is
    % just as a temporary holding place for them.
    output_motl(11:13, :) = (input_motl(8:10, :) + input_motl(11:13, :)) ...
        .* scale_factor;

    % Set the tomogram coordinates to the integer part of the scaled
    % coordinates.
    output_motl(8:10, :) = floor(output_motl(11:13, :));

    % The pre-rotation translations are then the full scaled coordinates minus
    % the tomogram coordinates.
    output_motl(11:13, :) = output_motl(11:13, :) - output_motl(8:10, :);

    % Write out the scaled motive list.
    tom_emwrite(output_motl_fn, output_motl);
    subtom_check_em_file(output_motl_fn, output_motl);
end
