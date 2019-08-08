function subtom_rand_class_motl(varargin)
% SUBTOM_RAND_CLASS_MOTL randomizes a given number of classes in a motive list.
%
%     SUBTOM_RAND_CLASS_MOTL(
%         'input_motl_fn', INPUT_MOTL_FN,
%         'output_motl_fn', OUTPUT_MOTL_FN,
%         'num_classes', NUM_CLASSES)
%
%     Takes the motive list given by INPUT_MOTL_FN, and splits it into
%     NUM_CLASSES even classes using the 20th row of the motive list, and then
%     writes the transformed motive list out as OUTPUT_MOTL_FN. The values that
%     go into the 20th row start at 3 and particles that initially have negative
%     or the value 2 in the 20th row are ignored as described in AV3
%     documentation for the behavior of class numbers.

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
    addParameter(fn_parser, 'num_classes', '2');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    input_motl_fn = fn_parser.Results.input_motl_fn;

    if isempty(input_motl_fn)
        try
            error('subTOM:missingRequired', ...
                'rand_class_motl:Parameter %s is required.', ...
                'input_motl_fn');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if exist(input_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'rand_class_motl:File %s does not exist.', input_motl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    input_motl = getfield(tom_emread(input_motl_fn), 'Value');

    if size(input_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'rand_class_motl:%s is not proper MOTL.', input_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    output_motl_fn = fn_parser.Results.output_motl_fn;

    if isempty(output_motl_fn)
        try
            error('subTOM:missingRequired', ...
                'rand_class_motl:Parameter %s is required.', ...
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
                'rand_class_motl:File %s cannot be opened for writing', ...
                output_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    fclose(fid);

    num_classes = fn_parser.Results.num_classes;

    if ischar(num_classes)
        num_classes = str2double(num_classes);
    end

    try
        validateattributes(num_classes, {'numeric'}, ...
            {'scalar', 'nonnan', 'positive'}, ...
            'subtom_rand_class_motl', 'num_classes');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Initially copy the output motive list as the input motive list.
    output_motl = input_motl;

    % Determine a list of valid particle ID numbers (row 4 in motive list).
    valid_idxs = unique(output_motl(4, :));

    if length(valid_idxs) ~= size(input_motl, 2)
        try
            error('subTOM:MOTLError', ...
                'rand_class_motl:%s contains duplicate particle IDs.', ...
                input_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    valid_idxs = output_motl(4, ...
        output_motl(20, :) >= 0 & output_motl(20, :) ~= 2);

    num_ptcls = length(valid_idxs);
    class_size = floor(num_ptcls / num_classes);
    rem_ptcls = num_ptcls - (class_size * num_classes);

    for class_idx = 1:num_classes
        class = class_idx + 2;

        if class_idx <= rem_ptcls
            class_size_ = class_size + 1;
        else
            class_size_ = class_size;
        end

        for ptcl_idx = 1:class_size_
            ptcl_id = valid_idxs(randi([1, length(valid_idxs)]));
            valid_idxs = valid_idxs(valid_idxs ~= ptcl_id);
            output_motl(20, output_motl(4, :) == ptcl_id) = class;
        end
    end

    % Write out the scaled motive list.
    tom_emwrite(output_motl_fn, output_motl);
    subtom_check_em_file(output_motl_fn, output_motl);
end
