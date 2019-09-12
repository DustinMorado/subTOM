function subtom_unclass_motl(varargin)
% SUBTOM_UNCLASS_MOTL removes the iclass information from a MOTL.
%
%     SUBTOM_UNCLASS_MOTL(
%         'input_motl_fn', INPUT_MOTL_FN,
%         'output_motl_fn', OUTPUT_MOTL_FN)
%
%     Takes the motive list given by INPUT_MOTL_FN, and removes all of the
%     iclass information setting all of the particles to 1, this can be useful
%     when moving from classified motive lists to all-particle alignments.  Then
%     unclassed motive list is written out as OUTPUT_MOTL_FN.

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
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    input_motl_fn = fn_parser.Results.input_motl_fn;

    if isempty(input_motl_fn)
        try
            error('subTOM:missingRequired', ...
                'unclass_motl:Parameter %s is required.', ...
                'input_motl_fn');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if exist(input_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'unclass_motl:File %s does not exist.', input_motl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    input_motl = getfield(tom_emread(input_motl_fn), 'Value');

    if size(input_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'unclass_motl:%s is not proper MOTL.', input_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    output_motl_fn = fn_parser.Results.output_motl_fn;

    if isempty(output_motl_fn)
        try
            error('subTOM:missingRequired', ...
                'unclass_motl:Parameter %s is required.', ...
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
                'unclass_motl:File %s cannot be opened for writing', ...
                output_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    fclose(fid);

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Initially copy the output motive list as the input motive list.
    output_motl = input_motl;

    % Remove the class information, setting all class values to 1. Ideally the
    % more correct value should be 0, but I know this will lead to user errors.
    output_motl(20, :) = 1;

    % Write out the unclassed motive list.
    tom_emwrite(output_motl_fn, output_motl);
    subtom_check_em_file(output_motl_fn, output_motl);
end
