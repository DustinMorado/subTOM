function subtom_cat_motls(varargin)
% SUBTOM_CAT_MOTLS concatenate motive lists and print on the standard ouput.
%
%     SUBTOM_CAT_MOTLS(
%         'write_motl', WRITE_MOTL,
%         'output_motl_fn', OUTPUT_MOTL_FN,
%         'write_star', WRITE_STAR,
%         'output_star_fn', OUTPUT_STAR_FN,
%         'sort_row', SORT_ROW,
%         'do_quiet', DO_QUIET,
%         INPUT_MOTL_FNS)
%
%     Takes the motive lists given in INPUT_MOTL_FNS, and concatenates them all
%     together.  If WRITE_MOTL evaluates to True as a boolean then the joined
%     motive lists are written out as OUPUT_MOTL_FN. The function writes the
%     motive list information in STAR format and if WRITE_STAR evaluates to True
%     as a boolean then the joined motive lists are also written out as
%     OUTPUT_STAR_FN. Since the input motive lists can be in any order and this
%     does not guarantee that the output motive list will have any form of
%     sorting, if SORT_ROW is a valid field number the output motive list will
%     be sorted by SORT_ROW.
%
%     The motive list is also printed to standard ouput. An arbitrary choice has
%     been made to ouput the motive list in STAR format, since it is used in
%     other more well-known EM software packages. If this screen output is not
%     desired set DO_QUIET to evaluate to true as a boolean.
%

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'write_motl', 0);
    addParameter(fn_parser, 'output_motl_fn', '');
    addParameter(fn_parser, 'write_star', 0);
    addParameter(fn_parser, 'output_star_fn', '');
    addParameter(fn_parser, 'sort_row', 0);
    addParameter(fn_parser, 'do_quiet', 0);

    % Because MATLAB is horrible and doesn't let you easily add variable length
    % arguments with the parser we have to do this kludgey thing here.
    parameters = {};
    input_motl_fns = {};
    varargin_idx = 1;

    while varargin_idx <= length(varargin)
        if ismember(varargin{varargin_idx}, fn_parser.Parameters)
            parameters((end + 1):(end + 2)) = ...
                varargin(varargin_idx:(varargin_idx + 1));

            varargin_idx = varargin_idx + 2;
        else
            input_motl_fns = varargin(varargin_idx:end);
            break
        end
    end

    parse(fn_parser, parameters{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    write_motl = fn_parser.Results.write_motl;

    if ischar(write_motl)
        write_motl = str2double(write_motl);
    end

    try
        validateattributes(write_motl, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_cat_motls', 'write_motl');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    output_motl_fn = fn_parser.Results.output_motl_fn;

    if ~write_motl && ~isempty(output_motl_fn)
        try
            error('subTOM:argumentError', ...
                'cat_motls: %s specified, but not %s', 'output_motl_fn', ...
                'write_motl');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    elseif write_motl && isempty(output_motl_fn)
        try
            error('subTOM:argumentError', ...
                'cat_motls: %s specified, but not %s', 'write_motl', ...
                'output_motl_fn');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    elseif ~isempty(output_motl_fn)
        fid = fopen(output_motl_fn, 'w');

        if fid == -1
            try
                error('subTOM:writeFileError', ...
                    'cat_motls:File %s cannot be opened for writing', ...
                    output_motl_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        fclose(fid);
    end

    write_star = fn_parser.Results.write_star;

    if ischar(write_star)
        write_star = str2double(write_star);
    end

    try
        validateattributes(write_star, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_cat_motls', 'write_star');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    output_star_fn = fn_parser.Results.output_star_fn;

    if ~write_star && ~isempty(output_star_fn)
        try
            error('subTOM:argumentError', ...
                'cat_motls: %s specified, but not %s', 'output_star_fn', ...
                'write_star');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    elseif write_star && isempty(output_star_fn)
        try
            error('subTOM:argumentError', ...
                'cat_motls: %s specified, but not %s', 'write_star', ...
                'output_star_fn');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    elseif ~isempty(output_star_fn)
        fid = fopen(output_star_fn, 'w');

        if fid == -1
            try
                error('subTOM:writeFileError', ...
                    'cat_motls:File %s cannot be opened for writing', ...
                    output_star_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        fclose(fid);
    end

    sort_row = fn_parser.Results.sort_row;

    if ischar(sort_row)
        sort_row = str2double(sort_row);
    end

    try
        validateattributes(sort_row, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>=', 0, '<', 21}, ...
            'subtom_cat_motls', 'sort_row');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    do_quiet = fn_parser.Results.do_quiet;

    if ischar(do_quiet)
        do_quiet = str2double(do_quiet);
    end

    try
        validateattributes(do_quiet, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_cat_motls', 'do_quiet');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    if isempty(input_motl_fns)
        try
            error('subTOM:argumentError', ...
                'cat_motls: no motive lists given');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    all_motl = [];

    for input_motl_fn_idx = 1:length(input_motl_fns)
        input_motl_fn = input_motl_fns{input_motl_fn_idx};

        if exist(input_motl_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'cat_motls:File %s does not exist.', input_motl_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        input_motl = getfield(tom_emread(input_motl_fn), 'Value');

        if size(input_motl, 1) ~= 20
            try
                error('subTOM:MOTLError', ...
                    'cat_motls:%s is not proper MOTL.', input_motl_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        all_motl = [all_motl input_motl];
    end

    if logical(sort_row)
        all_motl_sorted = transpose(sortrows(all_motl', sort_row));
        all_motl = all_motl_sorted;
    end

    if write_motl
        tom_emwrite(output_motl_fn, all_motl);
        subtom_check_em_file(output_motl_fn, all_motl);
    end

    if ~do_quiet
        fprintf(1, '\ndata_MOTL\n\nloop_\n');
        fprintf(1, '_motlCCC #1\n');
        fprintf(1, '_motlMarkerSet #2\n');
        fprintf(1, '_motlPickParticleRadius #3\n');
        fprintf(1, '_motlParticleNumber #4\n');
        fprintf(1, '_motlTomogramNumber #5\n');
        fprintf(1, '_motlPickParticleObject #6\n');
        fprintf(1, '_motlTomogramID #7\n');
        fprintf(1, '_motlCoordinateX #8\n');
        fprintf(1, '_motlCoordinateY #9\n');
        fprintf(1, '_motlCoordinateZ #10\n');
        fprintf(1, '_motlPostShiftX #11\n');
        fprintf(1, '_motlPostShiftY #12\n');
        fprintf(1, '_motlPostShiftZ #13\n');
        fprintf(1, '_motlPreShiftX #14\n');
        fprintf(1, '_motlPreShiftY #15\n');
        fprintf(1, '_motlPreShiftZ #16\n');
        fprintf(1, '_motlPhiSpin #17\n');
        fprintf(1, '_motlPsiRot #18\n');
        fprintf(1, '_motlThetaTilt #19\n');
        fprintf(1, '_motlClassNumber #20\n');

        for motl_idx = 1:size(all_motl, 2)
            fprintf(1, '%-12.6f ', all_motl(1, motl_idx));
            fprintf(1, '%-8d ', all_motl(2, motl_idx));
            fprintf(1, '%-8d ', all_motl(3, motl_idx));
            fprintf(1, '%-8d ', all_motl(4, motl_idx));
            fprintf(1, '%-8d ', all_motl(5, motl_idx));
            fprintf(1, '%-8d ', all_motl(6, motl_idx));
            fprintf(1, '%-8d ', all_motl(7, motl_idx));
            fprintf(1, '%-12.6f ', all_motl(8, motl_idx));
            fprintf(1, '%-12.6f ', all_motl(9, motl_idx));
            fprintf(1, '%-12.6f ', all_motl(10, motl_idx));
            fprintf(1, '%-12.6f ', all_motl(11, motl_idx));
            fprintf(1, '%-12.6f ', all_motl(12, motl_idx));
            fprintf(1, '%-12.6f ', all_motl(13, motl_idx));
            fprintf(1, '%-12.6f ', all_motl(14, motl_idx));
            fprintf(1, '%-12.6f ', all_motl(15, motl_idx));
            fprintf(1, '%-12.6f ', all_motl(16, motl_idx));
            fprintf(1, '%-12.6f ', all_motl(17, motl_idx));
            fprintf(1, '%-12.6f ', all_motl(18, motl_idx));
            fprintf(1, '%-12.6f ', all_motl(19, motl_idx));
            fprintf(1, '%-8d\n', all_motl(20, motl_idx));
        end

        fprintf(1, '\n');
    end

    if write_star
        fid = fopen(output_star_fn, 'w');

        if fid == -1
            try
                error('subTOM:writeFileError', ...
                    'cat_motls:File %s cannot be opened for writing', ...
                    output_star_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        fprintf(fid, '\ndata_MOTL\n\nloop_\n');
        fprintf(fid, '_motlCCC #1\n');
        fprintf(fid, '_motlMarkerSet #2\n');
        fprintf(fid, '_motlPickParticleRadius #3\n');
        fprintf(fid, '_motlParticleNumber #4\n');
        fprintf(fid, '_motlTomogramNumber #5\n');
        fprintf(fid, '_motlPickParticleObject #6\n');
        fprintf(fid, '_motlTomogramID #7\n');
        fprintf(fid, '_motlCoordinateX #8\n');
        fprintf(fid, '_motlCoordinateY #9\n');
        fprintf(fid, '_motlCoordinateZ #10\n');
        fprintf(fid, '_motlPostShiftX #11\n');
        fprintf(fid, '_motlPostShiftY #12\n');
        fprintf(fid, '_motlPostShiftZ #13\n');
        fprintf(fid, '_motlPreShiftX #14\n');
        fprintf(fid, '_motlPreShiftY #15\n');
        fprintf(fid, '_motlPreShiftZ #16\n');
        fprintf(fid, '_motlPhiSpin #17\n');
        fprintf(fid, '_motlPsiRot #18\n');
        fprintf(fid, '_motlThetaTilt #19\n');
        fprintf(fid, '_motlClassNumber #20\n');
        for motl_idx = 1:size(all_motl, 2)
            fprintf(fid, '%-12.6f ', all_motl(1, motl_idx));
            fprintf(fid, '%-8d ', all_motl(2, motl_idx));
            fprintf(fid, '%-8d ', all_motl(3, motl_idx));
            fprintf(fid, '%-8d ', all_motl(4, motl_idx));
            fprintf(fid, '%-8d ', all_motl(5, motl_idx));
            fprintf(fid, '%-8d ', all_motl(6, motl_idx));
            fprintf(fid, '%-8d ', all_motl(7, motl_idx));
            fprintf(fid, '%-12.6f ', all_motl(8, motl_idx));
            fprintf(fid, '%-12.6f ', all_motl(9, motl_idx));
            fprintf(fid, '%-12.6f ', all_motl(10, motl_idx));
            fprintf(fid, '%-12.6f ', all_motl(11, motl_idx));
            fprintf(fid, '%-12.6f ', all_motl(12, motl_idx));
            fprintf(fid, '%-12.6f ', all_motl(13, motl_idx));
            fprintf(fid, '%-12.6f ', all_motl(14, motl_idx));
            fprintf(fid, '%-12.6f ', all_motl(15, motl_idx));
            fprintf(fid, '%-12.6f ', all_motl(16, motl_idx));
            fprintf(fid, '%-12.6f ', all_motl(17, motl_idx));
            fprintf(fid, '%-12.6f ', all_motl(18, motl_idx));
            fprintf(fid, '%-12.6f ', all_motl(19, motl_idx));
            fprintf(fid, '%-8d\n', all_motl(20, motl_idx));
        end
        fprintf(fid, '\n');
    end
end
