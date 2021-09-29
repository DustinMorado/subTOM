function subtom_extract_noise(varargin)
% SUBTOM_EXTRACT_NOISE extract noise amplitude spectra on the cluster.
%
%     SUBTOM_EXTRACT_NOISE(
%         'tomogram_dir', TOMOGRAM_DIR,
%         'tomo_row', TOMO_ROW,
%         'ampspec_fn_prefix', AMPSPEC_FN_PREFIX,
%         'binary_fn_prefix', BINARY_FN_PREFIX,
%         'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX,
%         'noise_motl_fn_prefix', NOISE_MOTL_FN_PREFIX,
%         'iteration', ITERATION,
%         'box_size', BOX_SIZE,
%         'just_extract', JUST_EXTRACT,
%         'ptcl_overlap_factor', PTCL_OVERLAP_FACTOR,
%         'noise_overlap_factor', NOISE_OVERLAP_FACTOR,
%         'num_noise', NUM_NOISE,
%         'process_idx', PROCESS_IDX,
%         'reextract', REEXTRACT,
%         'preload_tomogram', PRELOAD_TOMOGRAM,
%         'use_tom_red', USE_TOM_RED,
%         'use_memmap', USE_MEMMAP)
%
%     Takes the tomograms given in TOMOGRAM_DIR and extracts average amplitude
%     spectra and binary wedges into SCRATCH_DIR with the name formats
%     AMPSPEC_FN_PREFIX_#.em and BINARY_FN_PREFIX_#.em, respectively where #
%     corresponds to the tomogram from which it was created.
%
%     Tomograms are specified by the field TOMO_ROW in motive list ALL_MOTL_FN,
%     and the tomogram that will be processed is selected by PROCESS_IDX. Motive
%     lists with the positions used to generate the amplitude spectrum are
%     written with the name format NOISE_MOTL_FN_PREFIX_#.em.
%
%     NUM_NOISE Noise volumes of size BOX_SIZE are first identified that do not
%     clash with the subtomogram positions in ALL_MOTL_FN or other already
%     selected noise volumes. PTCL_OVERLAP_FACTOR and NOISE_OVERLAP_FACTOR
%     define how much overlap selected noise volumes can have with subtomograms
%     and other noise volumes respectively with 1 being complete overlap and 0
%     being complete separation.
%
%     If NOISE_MOTL_FN_PREFIX_#.em already exists then if JUST_EXTRACT evaluates
%     to true as a boolean, then noise volume selection is skipped and the
%     positions in the motive list are extracted and the amplitude spectrum is
%     generated, whether or not the length of the motive list is less than
%     NUM_NOISE. Otherwise positions will be added to the motive list up to
%     NUM_NOISE.
%
%     If REEXTRACT evaluates to true as a boolean, than existing amplitude
%     spectra will be overwritten. Otherwise the program will do nothing and
%     exit if the volume already exists. This is for in the case that the
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
% See also SUBTOM_EXTRACT_SUBTOMOGRAMS

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
    addParameter(fn_parser, 'ampspec_fn_prefix', 'otherinputs/ampspec');
    addParameter(fn_parser, 'binary_fn_prefix', 'otherinputs/binary');
    addParameter(fn_parser, 'all_motl_fn_prefix', 'combinedmotl/allmotl');
    addParameter(fn_parser, 'noise_motl_fn_prefix', 'combinedmotl/noisemotl');
    addParameter(fn_parser, 'iteration', 1);
    addParameter(fn_parser, 'box_size', -1);
    addParameter(fn_parser, 'just_extract', 0);
    addParameter(fn_parser, 'ptcl_overlap_factor', 0);
    addParameter(fn_parser, 'noise_overlap_factor', 0);
    addParameter(fn_parser, 'num_noise', 1000);
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

    if exist(tomogram_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'extract_noise:tomogram_dir: Directory %s does not exist.', ...
                tomogram_dir);

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
            'subtom_extract_noise', 'tomo_row');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    ampspec_fn_prefix = fn_parser.Results.ampspec_fn_prefix;
    [ampspec_dir, ~, ~] = fileparts(ampspec_fn_prefix);

    if ~isempty(ampspec_dir) && exist(ampspec_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'extract_noise:ampspec_dir: Directory %s does not exist.', ...
                ampspec_dir);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    binary_fn_prefix = fn_parser.Results.binary_fn_prefix;
    [binary_dir, ~, ~] = fileparts(binary_fn_prefix);

    if ~isempty(binary_dir) && exist(binary_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'extract_noise:binary_dir: Directory %s does not exist.', ...
                binary_dir);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl_fn_prefix = fn_parser.Results.all_motl_fn_prefix;
    [all_motl_dir, ~, ~] = fileparts(all_motl_fn_prefix);

    if ~isempty(all_motl_dir) && exist(all_motl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'extract_noise:all_motl_dir: Directory %s does not exist.', ...
                all_motl_dir);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    noise_motl_fn_prefix = fn_parser.Results.noise_motl_fn_prefix;
    [noise_motl_dir, ~, ~] = fileparts(noise_motl_fn_prefix);

    if ~isempty(noise_motl_dir) && exist(noise_motl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'extract_noise:noise_motl_dir: Directory %s %s.', ...
                noise_motl_dir, 'does not exist');

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
            'subtom_extract_noise', 'iteration');

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
            'subtom_extract_noise', 'box_size');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    just_extract = fn_parser.Results.just_extract;

    if ischar(just_extract)
        just_extract = str2double(just_extract);
    end

    try
        validateattributes(just_extract, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_extract_noise', 'just_extract');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    ptcl_overlap_factor = fn_parser.Results.ptcl_overlap_factor;

    if ischar(ptcl_overlap_factor)
        ptcl_overlap_factor = str2double(ptcl_overlap_factor);
    end

    try
        validateattributes(ptcl_overlap_factor, {'numeric'}, ...
            {'scalar', 'nonnan', '>=', 0, '<', 1}, ...
            'subtom_extract_noise', 'ptcl_overlap_factor');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    noise_overlap_factor = fn_parser.Results.noise_overlap_factor;

    if ischar(noise_overlap_factor)
        noise_overlap_factor = str2double(noise_overlap_factor);
    end

    try
        validateattributes(noise_overlap_factor, {'numeric'}, ...
            {'scalar', 'nonnan', '>=', 0, '<', 1}, ...
            'subtom_extract_noise', 'noise_overlap_factor');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    num_noise = fn_parser.Results.num_noise;

    if ischar(num_noise)
        num_noise = str2double(num_noise);
    end

    try
        validateattributes(num_noise, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0}, ...
            'subtom_extract_noise', 'num_noise');

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
            'subtom_extract_noise', 'process_idx');

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
            'subtom_extract_noise', 'reextract');

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
            'subtom_extract_noise', 'preload_tomogram');

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
            'subtom_extract_noise', 'use_tom_red');

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
            'subtom_extract_noise', 'use_memmap');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    if ~preload_tomogram && use_tom_red
        try
            error('subTOM:argumentError', ...
                'extract_noise: %s specified, but not %s', 'use_tom_red', ...
                'preload_tomogram');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if preload_tomogram && use_memmap
        try
            error('subTOM:argumentError', ...
                'extract_noise: %s and %s specified', 'preload_tomogram', ...
                'use_memmap');

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
                'extract_noise:File %s does not exist.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl = getfield(tom_emread(all_motl_fn), 'Value');

    if size(all_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'extract_noise:%s is not proper MOTL.', all_motl_fn);

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
                'extract_noise:process_idx: %s', ...
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
                'extract_noise:File %s does not exist.', tomogram_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Get tomogram motl
    motl = all_motl(:, all_motl(tomo_row, :) == tomogram_number);

    % Check if we have already finished the processing for this tomogram
    noise_ampspec_fn = sprintf('%s_%d.em', ampspec_fn_prefix, tomogram_number);
    binary_wedge_fn = sprintf('%s_%d.em', binary_fn_prefix, tomogram_number);
    ampspec_exist = exist(noise_ampspec_fn, 'file') == 2;

    if ampspec_exist && ~reextract
        warning('subTOM:recoverOnFail', ...
            'extract_noise:%s exists and not set to reextract. SKIPPING!', ...
            noise_ampspec_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % check if noisemotl has already been calculated and if so read it in or
    % otherwise initialize a new empty one
    noise_motl_fn = sprintf('%s_%d.em', noise_motl_fn_prefix, tomogram_number);

    if exist(noise_motl_fn, 'file') == 2
        noise_motl = getfield(tom_emread(noise_motl_fn), 'Value');
        noise_count = size(noise_motl, 2);

        if just_extract
            num_noise = noise_count;
        end

    else
        noise_motl = zeros(20, num_noise);
        noise_count = 0;
    end

    % If we already have enough noise positions or selected just extract
    if noise_count >= num_noise

        % Extract the subtomograms for each tomogram
        fprintf(1, 'Starting Noise Extraction and Amp. Spec. Calculation\n');
        noise_ampspec = extract_noise_ampspec(box_size, tomogram_fn, ...
            noise_motl, tomo_row, preload_tomogram, use_tom_red, use_memmap);

        tom_emwrite(noise_ampspec_fn, noise_ampspec);
        subtom_check_em_file(noise_ampspec_fn, noise_ampspec);

        binary_wedge = binary_from_ampspec(noise_ampspec);
        tom_emwrite(binary_wedge_fn, binary_wedge);
        subtom_check_em_file(binary_wedge_fn, binary_wedge);
        fprintf(1, 'Finished Noise Extraction and Amp. Spec. Calculation\n');
        return
    end

    % Read in the tomogram to get its dimension
    tomogram_size = getfield(getfield(subtom_readmrcheader(tomogram_fn), ...
        'Header'), 'Size');

    % Make sure that the boxsize is not bigger in any dimension than the
    % tomogram.
    if box_size >= min(tomogram_size)
        try
            error('subTOM:volDimError', ...
                'extract_noise: box_size is too large for given tomogram.');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if max(tomogram_size) <= 512
        bin_factor = 1;
    elseif max(tomogram_size ./ 2) <= 512
        bin_factor = 2;
    elseif max(tomogram_size ./ 4) <= 512
        bin_factor = 4;
    else
        bin_factor = 8;
    end

    % Create a mask volume that will hold possible positions for noise
    noise_mask = ones(round(tomogram_size ./ bin_factor));

    % We avoid taking noise volumes that will extend beyond the tomogram.
    extract_box_size = box_size;
    box_size = max(round(box_size / bin_factor), 1);
    box_center = floor(box_size / 2) + 1;
    upper_limit = box_size - box_center;
    lower_limit = box_center - 1;

    % Noise absolute minimum tomogram limits
    noise_mask(1:lower_limit, :, :) = 0;
    noise_mask(:, 1:lower_limit, :) = 0;
    noise_mask(:, :, 1:lower_limit) = 0;

    % Noise absolute maximum tomogram limits
    noise_mask(size(noise_mask, 1) - (upper_limit - 1):end, :, :) = 0;
    noise_mask(:, size(noise_mask, 2) - (upper_limit - 1):end, :) = 0;
    noise_mask(:, :, size(noise_mask, 3) - (upper_limit - 1):end) = 0;

    % If the box size is too large we might have already removed all the
    % positions and so we should error and let the user know.
    if sum(noise_mask(:)) == 0
        try
            error('subTOM:volDimError', ...
                'extract_noise: box_size is too large to find noise.');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % We define mask size as a factor of the box size which defines the amount
    % of overlap we allow between particles and noise particles. Values less
    % than zero will create extra padding between particles, while values
    % greater than zero will allow some overlap
    ptcl_masksize = max(round(box_size * (1 - ptcl_overlap_factor)), 1);
    noise_masksize = max(round(box_size * (1 - noise_overlap_factor)), 1);

    % For each particle we clear out the mask around the particle
    for ptcl_idx = 1:size(motl, 2)

        % Get the particles position in the tomogram
        ptcl_pos = round((motl(8:10, ptcl_idx) + motl(11:13, ptcl_idx)) ./ ...
            bin_factor);

        % Particles can exist at the boundaries of the tomogram so we need to
        % set their boundaries manually to avoid improper indexing
        ptcl_min = max(round(ptcl_pos - (ptcl_masksize / 2)), 1);
        ptcl_max = min(round(ptcl_pos + (ptcl_masksize / 2 - 1)), ...
            size(noise_mask));

        % Zero out the mask around the particle
        noise_mask(ptcl_min(1):ptcl_max(1), ptcl_min(2):ptcl_max(2), ...
            ptcl_min(3):ptcl_max(3)) = 0;
    end

    % For each existing noise position we clear out the mask around the particle
    if noise_count > 0
        for noise_idx = 1:noise_count

            % Get the noise position in the tomogram
            noise_pos = round(noise_motl(8:10, noise_idx) ./ bin_factor);

            % Noise shouldn't exist at the boundaries of the tomogram, but just
            % in case the user has given some very large overlap factor value.
            noise_min = max(round(noise_pos - (noise_masksize / 2)), 1);
            noise_max = min(round(noise_pos + (noise_masksize / 2 - 1)), ...
                size(noise_mask));

            % Zero out the mask around the particle
            noise_mask(noise_min(1):noise_max(1), noise_min(2):noise_max(2), ...
                noise_min(3):noise_max(3)) = 0;
        end
    end

    % Setup the progress bar
    delprog = '';
    timings = [];
    message = sprintf('Find Noise %d', tomogram_number);
    op_type = 'noise';
    tic;

    rng('shuffle');

    while noise_count < num_noise
        % First we find non-zero indices in our noise_mask volume
        noise_pos_array = find(noise_mask == 1);

        % If we cannot find any suitable noise positions we break
        if isempty(noise_pos_array)
            warning('subTOM:outOfNoiseWarning', ...
                'extract_noise: No more available position for noise. %s', ...
                sprintf(...
                '%d noise found - Consider increasing overlap factors', ...
                noise_count));

            [msg, msg_id] = lastwarn;
            fprintf(2, '%s - %s\n', msg_id, msg);
            break
        end

        % Pick a random position from this list
        noise_pos_idx = noise_pos_array(randi(length(noise_pos_array)));

        [noise_pos_x, noise_pos_y, noise_pos_z] = ind2sub(size(noise_mask), ...
            noise_pos_idx);

        noise_pos = [noise_pos_x, noise_pos_y, noise_pos_z];

        % Add this position to the noise MOTL
        noise_count = noise_count + 1;
        noise_motl(4, noise_count) = ((process_idx - 1) * num_noise) + ...
            noise_count;

        noise_motl(tomo_row, noise_count) = tomogram_number;
        noise_motl(8:10, noise_count) = noise_pos .* bin_factor;
        noise_motl(20, noise_count) = 1;

        % Noise shouldn't exist at the boundaries of the tomogram, but just in
        % case the user has given some very large overlap factor value.
        noise_min = max(round(noise_pos - (noise_masksize / 2)), 1);
        noise_max = min(round(noise_pos + (noise_masksize / 2 - 1)), ...
            size(noise_mask));

        % Zero out the mask around the particle
        noise_mask(noise_min(1):noise_max(1), noise_min(2):noise_max(2), ...
            noise_min(3):noise_max(3)) = 0;

        % Display some output
        [delprog, timings] = subtom_display_progress(delprog, timings, ...
            message, op_type, num_noise, noise_count);

    end

    % Extract the subtomograms for each tomogram
    fprintf(1, 'Starting Noise Extraction and Amp. Spec. Calculation\n');
    noise_motl = noise_motl(:, noise_motl(20, :) == 1);
    noise_ampspec = extract_noise_ampspec(extract_box_size, tomogram_fn, ...
        noise_motl, tomo_row, preload_tomogram, use_tom_red, use_memmap);

    tom_emwrite(noise_ampspec_fn, noise_ampspec);
    subtom_check_em_file(noise_ampspec_fn, noise_ampspec);

    binary_wedge = binary_from_ampspec(noise_ampspec);
    tom_emwrite(binary_wedge_fn, binary_wedge);
    subtom_check_em_file(binary_wedge_fn, binary_wedge);

    tom_emwrite(noise_motl_fn, noise_motl);
    subtom_check_em_file(noise_motl_fn, noise_motl);
    fprintf(1, 'Finished Noise Extraction and Amp. Spec. Calculation\n');
end

%##############################################################################%
%                            EXTRACT_NOISE_AMPSPEC                             %
%##############################################################################%
function noise_ampspec_avg = extract_noise_ampspec(box_size, tomogram_fn, ...
    motl_vec, tomo_row, preload_tomogram, use_tom_red, use_memmap)
% EXTRACT_NOISE_AMPSPEC Calculate average noise amplitude spectrum.
%     EXTRACT_NOISE_AMPSPEC(
%         BOX_SIZE,
%         TOMOGRAM_FN,
%         MOTL_VEC,
%         TOMO_ROW,
%         PRELOAD_TOMOGRAM,
%         USE_TOM_RED,
%         USE_MEMMAP)
%
%     Extracts subvolumes with the cube length BOX_SIZE from the tomogram given
%     by the filename TOMOGRAM_FN. The positions of the subvolumes is given in
%     the motive list MOTL_VEC. PRELOAD_TOMOGRAM, USE_TOM_RED, and USE_MEMMAP
%     describe flags that describe how the subvolumes are extracted using
%     different stratgies in terms of file I/O etc.

    % Initialize amplitude spectrum volume
    noise_ampspec_sum = zeros(box_size, box_size, box_size);
    num_noise = size(motl_vec, 2);

    if num_noise == 0
        try
            error('subTOM:MOTLError', ...
                'extract_noise:Noise MOTL is completely empty.');

        catch ME
            fprintf('%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    tomogram_number = motl_vec(tomo_row, 1);

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
                        'extract_noise:%s has unknown datatype %d', ...
                        tomogram_fn, header.mode);

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
        end

        tomogram = memmapfile(tomogram_fn, 'Offset', 1024 + header.next, ...
            'Format', {dtype, [header.nx, header.ny, header.nz], 'Value'});
    end

    delprog = '';
    timings = [];
    message = sprintf('Extract Noise %d', tomogram_number);
    op_type = 'particles';
    tic;

    noise_size = repmat(box_size, 1, 3);

    for idx = 1:num_noise
        noise_pos = transpose(motl_vec(8:10, idx));
        noise_start = round(noise_pos - (box_size / 2));

        % Input the bottom,left,rear corner of the box and the box edge
        % dimensions. The extact the volume and convert to double.
        if preload_tomogram && use_tom_red
            noise_vol = double(tom_red(tomogram, noise_start, noise_size));
        elseif preload_tomogram
            noise_vol = double(subtom_window(tomogram, noise_start, ...
                noise_size));
        elseif use_memmap
            noise_vol = double(subtom_window_memmap(tomogram, header, ...
                noise_start, noise_size));
        else
            noise_vol = double(subtom_window_fread(tomogram_fn, header, ...
                noise_start, noise_size));
        end

        % Normalize the volume by mean subtraction and division by SD
        noise_mean = mean(noise_vol(:));
        noise_stddev = std(noise_vol(:));
        noise_vol = (noise_vol - noise_mean) / noise_stddev;

        noise_ampspec = fftshift(fftn(noise_vol));
        noise_ampspec = sqrt(noise_ampspec .* conj(noise_ampspec));
        noise_ampspec_sum = noise_ampspec_sum + noise_ampspec;

        % Display some output
        [delprog, timings] = subtom_display_progress(delprog, timings, ...
            message, op_type, num_noise, idx);

    end

    noise_ampspec_avg = noise_ampspec_sum ./ num_noise;
    noise_ampspec_avg = noise_ampspec_avg ./ max(noise_ampspec_avg(:));

    % Relion gets unhappy with the origin of the FFT having a zero value so we
    % apply a 3x3 median filter in the origin plane to the origin
    center = box_size / 2 + 1;
    noise_ampspec_avg(center, center, center) = (...
          noise_ampspec_avg(center    , center    , center) ...
        + noise_ampspec_avg(center    , center + 1, center) ...
        + noise_ampspec_avg(center + 1, center + 1, center) ...
        + noise_ampspec_avg(center + 1, center    , center) ...
        + noise_ampspec_avg(center + 1, center - 1, center) ...
        + noise_ampspec_avg(center    , center - 1, center) ...
        + noise_ampspec_avg(center - 1, center - 1, center) ...
        + noise_ampspec_avg(center - 1, center    , center) ...
        + noise_ampspec_avg(center - 1, center + 1, center)) ./ 9;
end

%##############################################################################%
%                             BINARY_FROM_AMPSPEC                              %
%##############################################################################%
function binary_wedge = binary_from_ampspec(ampspec)
% BINARY_FROM_AMPSPEC Create binary wedge from the amplitude spectrum.
%     BINARY_FROM_AMPSPEC(
%         AMPSPEC)
%
%     Determines an approximation for the binary wedge given the amplitude
%     spectrum wedge weight AMPSPEC. This is done by downsampling the input
%     weight and then going through each of the angle possibilities and
%     correlates the estimated binay wedge with the amplitude spectrum. The best
%     correlating binary wedge is then returned.
%
% Example:
%     binary_from_ampspec(ampspec);

    if size(ampspec, 1) <= 32
        crop_size = size(ampspec, 1);
    elseif round(size(ampspec, 1) / 2) <= 32
        crop_size = round(size(ampspec, 1) / 2);
    elseif round(size(ampspec, 1) / 4) <= 32
        crop_size = round(size(ampspec, 1) / 4);
    else
        crop_size = round(size(ampspec, 1) / 8);
    end

    if mod(crop_size, 2) == 1
        crop_size = crop_size + 1;
    end

    crop_start = size(ampspec) / 2 + 1 - (crop_size / 2);
    norm_ampspec = tom_red(ampspec, crop_start, repmat(crop_size, 1, 3));
    norm_ampspec = (norm_ampspec - mean(norm_ampspec(:))) ./ ...
        std(norm_ampspec(:), 1);

    best_ccc = [-1, -60, 60, 0];
    n_voxels = numel(norm_ampspec);

    for min_angle = -60:-1
        for max_angle = 1:60
            wedge = av3_wedge(norm_ampspec, min_angle, max_angle);
            wedge = min(wedge, norm_ampspec);
            norm_wedge = (wedge - mean(wedge(:))) ./ std(wedge(:), 1);
            ccc = norm_ampspec .* norm_wedge;
            ccc = sum(ccc(:)) ./ n_voxels;
            ccc_ = norm_ampspec .* tom_rotate(norm_wedge, [0, 0, -90]);
            ccc_ = sum(ccc_(:)) ./ n_voxels;

            if ccc >= best_ccc(1)
                best_ccc = [ccc, min_angle, max_angle, 0];
            elseif ccc_ >= best_ccc(1)
                best_ccc = [ccc, min_angle, max_angle, 1];
            end
        end
    end

    binary_wedge = av3_wedge(ampspec, best_ccc(2), best_ccc(3));

    if best_ccc(4) == 1
        binary_wedge = tom_rotate(binary_wedge, [0, 0, -90]);
    end
end
