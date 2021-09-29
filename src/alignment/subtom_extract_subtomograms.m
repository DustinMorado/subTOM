function subtom_extract_subtomograms(varargin)
% SUBTOM_EXTRACT_SUBTOMOGRAMS extract subtomograms on the cluster.
%
%     SUBTOM_EXTRACT_SUBTOMOGRAMS(
%         'tomogram_dir', TOMOGRAM_DIR, 
%         'tomo_row', TOMO_ROW, 
%         'subtomo_fn_prefix', SUBTOMO_FN_PREFIX, 
%         'subtomo_digits', SUBTOMO_DIGITS, 
%         'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX, 
%         'stats_fn_prefix', STATS_FN_PREFIX, 
%         'iteration', ITERATION,
%         'box_size', BOX_SIZE, 
%         'process_idx', PROCESS_IDX, 
%         'reextract', REEXTRACT,
%         'preload_tomogram', PRELOAD_TOMOGRAM,
%         'use_tom_red', USE_TOM_RED,
%         'use_memmap', USE_MEMMAP)
%
%     Takes the tomograms given in TOMOGRAM_DIR and extracts subtomograms
%     specified in ALL_MOTL_FN_PREFIX_#.m where # corresponds to ITERATION with
%     size BOX_SIZE into SCRATCH_DIR with the name formats
%     SUBTOMO_FN_PREFIX_#.em where # corresponds to the entry in field 4 in
%     ALL_MOTL_FN_PREFIX_#.em zero-padded to have at least SUBTOMO_DIGITS
%     digits.
%
%     Tomograms are specified by the field TOMO_ROW in motive list
%     ALL_MOTL_FN_PREFIX_#.em, and the tomogram that will be processed is
%     selected by PROCESS_IDX. A CSV-format file with the subtomogram ID-number,
%     average, min, max, standard deviation and variance for each subtomogram in
%     the tomogram is also written with the name format STATS_FN_PREFIX_#.em
%     where # corresponds to the tomogram from which subtomograms were
%     extracted. 
%
%     If REEXTRACT evaluates to true as a boolean, than existing subtomograms
%     will be overwritten. Otherwise the program will do nothing and exit if
%     STATS_FN_PREFIX_#.em already exists, or will also skip any subtomogram it
%     is trying to extract that already exists. This is for in the case that the
%     processing crashed at some point in execution and then can just be re-run
%     without any alterations.
%
%     If PRELOAD_TOMOGRAM evaluates to true as a boolean, then the whole
%     tomogram will be read into memory before extraction begins, otherwise the
%     particles will be read from disk or from a memory-mapped tomogram. If
%     USE_TOM_RED evaluates to true as a boolean the old particle extraction
%     code will be used, but this is only for legacy support and is not
%     suggested for use. Finally if USE_MEMMAP evaluates to true as a boolean
%     then in place of reading each particle from disk a memory-mapped version
%     of the file of will be created to attempt faster access in extraction.
%
% See also SUBTOM_EXTRACT_NOISE

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'tomogram_dir', '');
    addParameter(fn_parser, 'tomo_row', 7);
    addParameter(fn_parser, 'subtomo_fn_prefix', 'subtomograms/subtomo');
    addParameter(fn_parser, 'subtomo_digits', 1);
    addParameter(fn_parser, 'all_motl_fn_prefix', 'combinedmotl/allmotl');
    addParameter(fn_parser, 'stats_fn_prefix', 'subtomograms/stats/tomo');
    addParameter(fn_parser, 'iteration', 1);
    addParameter(fn_parser, 'box_size', -1);
    addParameter(fn_parser, 'process_idx', 1);
    addParameter(fn_parser, 'reextract', 0);
    addParameter(fn_parser, 'preload_tomogram', 1);
    addParameter(fn_parser, 'use_tom_red', 0);
    addParameter(fn_parser, 'use_memmap', 0);
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    tomogram_dir = fn_parser.Results.tomogram_dir;

    if ~isempty(tomogram_dir) && exist(tomogram_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'extract_subtomograms:tomogram_dir: Directory %s %s.', ...
                tomogram_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    tomo_row = fn_parser.Results.tomo_row;

    if ischar(tomo_row)
        tomo_row = str2double(tomo_row);
    end

    try
        validateattributes(tomo_row, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0, '<', 21}, ...
            'subtom_extract_subtomograms', 'tomo_row');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    subtomo_fn_prefix = fn_parser.Results.subtomo_fn_prefix;
    [subtomo_dir, ~, ~] = fileparts(subtomo_fn_prefix);

    if ~isempty(subtomo_dir) && exist(subtomo_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'extract_subtomograms:subtomo_dir: Directory %s %s.', ...
                subtomo_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    subtomo_digits = fn_parser.Results.subtomo_digits;

    if ischar(subtomo_digits)
        subtomo_digits = str2double(subtomo_digits);
    end

    try
        validateattributes(subtomo_digits, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0}, ...
            'subtom_extract_subtomograms', 'subtomo_digits');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    all_motl_fn_prefix = fn_parser.Results.all_motl_fn_prefix;
    [all_motl_dir, ~, ~] = fileparts(all_motl_fn_prefix);

    if ~isempty(all_motl_dir) && exist(all_motl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'extract_subtomograms:all_motl_dir: Directory %s %s.', ...
                all_motl_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    stats_fn_prefix = fn_parser.Results.stats_fn_prefix;
    [stats_dir, ~, ~] = fileparts(stats_fn_prefix);

    if ~isempty(stats_dir) && exist(stats_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'extract_subtomograms:stats_dir: Directory %s %s.', ...
                stats_dir, 'does not exist');

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
            'subtom_extract_subtomograms', 'iteration');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    box_size = fn_parser.Results.box_size;

    if ischar(box_size)
        box_size = str2double(box_size);
    end

    try
        validateattributes(box_size, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0}, ...
            'subtom_extract_subtomograms', 'box_size');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    process_idx = fn_parser.Results.process_idx;

    if ischar(process_idx)
        process_idx = str2double(process_idx);
    end

    try
        validateattributes(process_idx, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0}, ...
            'subtom_extract_subtomograms', 'process_idx');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    reextract = fn_parser.Results.reextract;

    if ischar(reextract)
        reextract = str2double(reextract);
    end

    try
        validateattributes(reextract, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_extract_subtomograms', 'reextract');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    preload_tomogram = fn_parser.Results.preload_tomogram;

    if ischar(preload_tomogram)
        preload_tomogram = str2double(preload_tomogram);
    end

    try
        validateattributes(preload_tomogram, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_extract_subtomograms', 'preload_tomogram');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    use_tom_red = fn_parser.Results.use_tom_red;

    if ischar(use_tom_red)
        use_tom_red = str2double(use_tom_red);
    end

    try
        validateattributes(use_tom_red, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_extract_subtomograms', 'use_tom_red');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    use_memmap = fn_parser.Results.use_memmap;

    if ischar(use_memmap)
        use_memmap = str2double(use_memmap);
    end

    try
        validateattributes(use_memmap, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_extract_subtomograms', 'use_memmap');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    if ~preload_tomogram && use_tom_red
        try
            error('subTOM:argumentError', ...
                'extract_subtomograms: %s specified, but not %s', ...
                'use_tom_red', 'preload_tomogram');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if preload_tomogram && use_memmap
        try
            error('subTOM:argumentError', ...
                'extract_subtomograms: %s and %s specified', ...
                'preload_tomogram', 'use_memmap');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Read in all_motl
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(all_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'extract_subtomograms:File %s does not exist.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl = getfield(tom_emread(all_motl_fn), 'Value');

    if size(all_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'extract_subtomograms:%s is not proper MOTL.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Get a list of all tomograms in the all_motl
    tomograms = unique(all_motl(tomo_row, :));

    if process_idx > length(tomograms)
        try
            error('subTOM:argumentError', ...
                'extract_subtomograms:process_idx: %s', ...
                'argument greater than number of tomograms');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Identify our tomogram number for processing
    tomogram_number = tomograms(process_idx);

    % We just try to open the tomogram with one, two, three, or four digits.
    for tomogram_digits = 1:4
        tomogram_fn = sprintf(sprintf('%%0%dd.rec', tomogram_digits), ...
            tomogram_number);

        tomogram_fn = fullfile(tomogram_dir, tomogram_fn);

        if exist(tomogram_fn, 'file') == 2
            break;
        end
    end

    if exist(tomogram_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'extract_subtomograms:File %s does not exist.', tomogram_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Get tomogram motl
    motl = all_motl(:, all_motl(tomo_row, :) == tomogram_number);

    % We get the number of particles which is the number of columns in the
    % motive list.
    num_ptcls = size(motl, 2);

    % Check if we have already finished the processing for this tomogram
    stats_fn = sprintf('%s_%d.csv', stats_fn_prefix, tomogram_number);

    if ~reextract && exist(stats_fn, 'file') == 2
        stats = csvread(stats_fn);

        if size(stats, 1) == size(motl, 2)
            warning('subTOM:recoverOnFail', ...
                'extract_subtomograms:%s exists is complete and %s', ...
                stats_fn, 'not set to reextract. SKIPPING!');

            [msg, msg_id] = lastwarn;
            fprintf(2, '%s - %s\n', msg_id, msg);
            return
        end
    end

    % Create the array to hold the subtomogram statistics
    stats = zeros(num_ptcls, 6);

    % Read in the tomogram
    if preload_tomogram
        tomogram = getfield(tom_mrcread(tomogram_fn), 'Value');
    else
        header = getfield(getfield(subtom_readmrcheader(tomogram_fn), ...
            'Header'), 'MRC');

    end

    if use_memmap
        switch header.mode
            case 0
                dtype = 'int8';
            case 1
                dtype = 'int16';
            case 2
                dtype = 'single';
            case 6
                dtype = 'uint16';
            otherwise
                try
                    error('subTOM:MRCError', ...
                        'extract_subtomograms:%s has unknown datatype %d', ...
                        tomogram_fn, header.mode);

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
        end

        tomogram = memmapfile(tomogram_fn, 'Offset', 1024 + header.next, ...
            'Format', {dtype, [header.nx, header.ny, header.nz], 'Value'});

    end

    % Setup the progress bar
    delprog = '';
    timings = [];
    message = sprintf('Extract subtomo %d', tomogram_number);
    op_type = 'particles';
    tic;

    subtomo_size = repmat(box_size, 1, 3);
    for subtomo_idx = 1:num_ptcls

        % First check if the subtomogram already exists
        subtomo_fn = sprintf(sprintf('%s_%%0%dd.em', subtomo_fn_prefix, ...
            subtomo_digits), motl(4, subtomo_idx));

        if ~reextract && exist(subtomo_fn, 'file') == 2
            warning('subTOM:recoverOnFail', ...
                'extract_subtomograms:%s exists and %s', ...
                subtomo_fn, 'not set to reextract. SKIPPING!');

            [msg, msg_id] = lastwarn;
            fprintf(2, '%s - %s\n', msg_id, msg);
            continue
        end

        subtomo_position = motl(8:10, subtomo_idx);
        subtomo_start = round(subtomo_position - (box_size / 2));

        if preload_tomogram && use_tom_red
            subtomo = double(tom_red(tomogram, subtomo_start, subtomo_size));
        elseif preload_tomogram
            subtomo = double(subtom_window(tomogram, subtomo_start, ...
                subtomo_size));

        elseif use_memmap
            subtomo = double(subtom_window_memmap(tomogram, header, ...
                subtomo_start, subtomo_size));

        else
            subtomo = double(subtom_window_fread(tomogram_fn, header, ...
                subtomo_start, subtomo_size));

        end

        % Normalize the subtomogram by mean subtraction and division by SD
        subtomo_mean = mean(subtomo(:));
        subtomo_stddev = std(subtomo(:));
        subtomo = (subtomo - subtomo_mean) / subtomo_stddev;

        % Calculate subtomogram stats
        stats(subtomo_idx, 1) = motl(4, subtomo_idx);
        stats(subtomo_idx, 2) = sum(subtomo(:)) / numel(subtomo);
        stats(subtomo_idx, 3) = max(subtomo(:));
        stats(subtomo_idx, 4) = min(subtomo(:));
        stats(subtomo_idx, 5) = std(subtomo(:));
        stats(subtomo_idx, 6) = stats(subtomo_idx, 5)^2;

        % Write out subtomogram
        tom_emwrite(subtomo_fn, subtomo);
        subtom_check_em_file(subtomo_fn, subtomo);

        % Display some output
        [delprog, timings] = subtom_display_progress(delprog, timings, ...
            message, op_type, num_ptcls, subtomo_idx);

    end

    % Write out stats file
    csvwrite(stats_fn, stats);
end
