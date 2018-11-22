function extract_subtomograms(tomogram_dir, scratch_dir, tomo_row, ...
    subtomo_fn_prefix, subtomo_digits, all_motl_fn, boxsize, ...
    stats_fn_prefix, process_idx, reextract, preload_tomogram, use_tom_red, ...
    use_memmap)
% EXTRACT_SUBTOMOGRAMS extract subtomograms on the cluster.
%     EXTRACT_SUBTOMOGRAMS(
%         TOMOGRAM_DIR, 
%         SCRATCH_DIR, 
%         TOMO_ROW, 
%         SUBTOMO_FN_PREFIX, 
%         SUBTOMO_DIGITS, 
%         ALL_MOTL_FN, 
%         BOXSIZE, 
%         STATS_FN_PREFIX, 
%         PROCESS_IDX, 
%         REEXTRACT)
%
%     Takes the tomograms given in TOMOGRAM_DIR and extracts subtomograms
%     specified in ALL_MOTL_FN with size BOXSIZE into SCRATCH_DIR with the name
%     formats SUBTOMO_FN_PREFIX_#.em where # corresponds to the entry in field 4
%     in ALL_MOTL_FN zero-padded to have at least SUBTOMO_DIGITS digits.
%
%     Tomograms are specified by the field TOMO_ROW in motive list ALL_MOTL_FN,
%     and the tomogram that will be processed is selected by PROCESS_IDX. A
%     CSV-format file with the subtomogram ID-number, average, min, max,
%     standard deviation and variance for each subtomogram in the tomogram is
%     also written with the name format STATS_FN_PREFIX_#.em where # corresponds
%     to the tomogram from which subtomograms were extracted. 
%
%     If REEXTRACT evaluates to true as a boolean, than existing subtomograms
%     will be overwritten. Otherwise the program will do nothing and exit if
%     STATS_FN_PREFIX_#.em already exists, or will also skip any subtomogram it
%     is trying to extract that already exists. This is for in the case that the
%     processing crashed at some point in execution and then can just be re-run
%     without any alterations.
%
% Example:
%     EXTRACT_SUBTOMOGRAMS(...
%         '/net/bstore1/bstore1/user/dataset/date/data/tomos/bin1', ...
%         '/net/bstore1/bstore1/user/dataset/date/subtomo/bin1/even', ...
%         7, 'subtomograms/subtomo', 1, 'combinedmotl/allmotl_1.em', ...
%         192, 'subtomograms/stats/subtomo_stats', 1, 0)
%
% See also EXTRACT_NOISE

% DRM 11-2017
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% tomogram_dir = 'tomogram_dir';
% scratch_dir = 'scratch_dir';
% tomo_row = 7;
% subtomo_fn_prefix = 'subtomograms/subtomo';
% subtomo_digits = 1;
% all_motl_fn = 'combinedmotl/allmotl_1.em';
% boxsize = 128;
% stats_fn_prefix = 'subtomograms/stats/subtomo_stats';
% process_idx = 1;
% reextract = 0
%##############################################################################%
    % Evaluate numeric inputs
    if ischar(tomo_row)
        tomo_row = str2double(tomo_row);
    end

    if ischar(subtomo_digits)
        subtomo_digits = str2double(subtomo_digits);
    end

    if ischar(boxsize)
        boxsize = str2double(boxsize);
    end

    if ischar(process_idx)
        process_idx = str2double(process_idx);
    end

    if ischar(reextract)
        reextract = str2double(reextract);
    end

    reextract = logical(reextract);

    if ischar(preload_tomogram)
        preload_tomogram = str2double(preload_tomogram);
    end

    preload_tomogram = logical(preload_tomogram);

    if ischar(use_tom_red)
        use_tom_red = str2double(use_tom_red);
    end

    use_tom_red = logical(use_tom_red);

    if ischar(use_memmap)
        use_memmap = str2double(use_memmap);
    end

    use_memmap = logical(use_memmap);

    % Read in allmotl
    allmotl = getfield(tom_emread(all_motl_fn), 'Value');

    % Get a list of all tomograms in the allmotl
    tomograms = unique(allmotl(tomo_row, :));

    % Identify our tomogram number for processing
    tomogram_number = tomograms(process_idx);

    % We just try to open the tomogram with one, two, three, or four digits.
    for tomogram_digits = 1:4
        tomogram_fn = sprintf(sprintf('%%0%dd.rec', tomogram_digits), ...
            tomogram_number);
        tomogram_fn = fullfile(tomogram_dir, tomogram_fn);
        if isfile(tomogram_fn)
            break;
        end
    end

    % Get tomogram motl
    motl = allmotl(:, allmotl(tomo_row, :) == tomogram_number);

    % Go to root folder
    cd(scratch_dir);

    % Check if we have already finished the processing for this tomogram
    stats_fn = sprintf('%s_%d.csv', stats_fn_prefix, tomogram_number);
    if ~reextract && exist(fullfile(pwd(), stats_fn), 'file') == 2
        stats = csvread(stats_fn);
        if size(stats, 1) == size(motl, 2)
            fprintf('Found stats file with all %d subvolumes. SKIPPING.\n', ...
                size(motl, 2));

            fprintf('Turn on reextract if you want to re-extract particles.\n');
            return
        end
    end

    % Create the array to hold the subtomogram statistics
    stats = zeros(size(motl, 2), 6);

    % Read in the tomogram
    if preload_tomogram
        tomogram = getfield(tom_mrcread(tomogram_fn), 'Value');
    else
        header = getfield(getfield(tom_readmrcheader(tomogram_fn), ...
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
                error('Sorry, I cannot read this as an MRC-File !!!');
        end

        tomogram = memmapfile(tomogram_fn, 'Offset', 1024 + header.next, ...
            'Format', {dtype, [header.nx, header.ny, header.nz], 'Value'});
    end

    delprog = '';
    subtomo_size = repmat(boxsize, 1, 3);
    for subtomo_idx = 1:size(motl, 2)
        % First check if the subtomogram already exists
        subtomo_fn = sprintf(sprintf('%s_%%0%dd.em', subtomo_fn_prefix, ...
            subtomo_digits), motl(4, subtomo_idx));

        if ~reextract && exist(fullfile(pwd(), subtomo_fn), 'file') == 2
            fprintf('Found particle: %s. SKIPPING.\n', subtomo_fn);
            fprintf('Turn on reextract if you want to re-extract particles.\n');
            continue
        end

        subtomo_position = motl(8:10, subtomo_idx);
        subtomo_start = round(subtomo_position - (boxsize / 2));

        if preload_tomogram && use_tom_red
            subtomo = double(tom_red(tomogram, subtomo_start, subtomo_size));
        elseif preload_tomogram
            subtomo = double(window(tomogram, subtomo_start, subtomo_size));
        elseif use_memmap
            subtomo = double(window_memmap(tomogram, header, subtomo_start, ...
                subtomo_size));
        else
            subtomo = double(window_fread(tomogram_fn, header, ...
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
        check_em_file(subtomo_fn, subtomo);

        % Display some output
        delprog = disp_progbar(tomogram_number, subtomo_idx, size(motl, 2), ...
            delprog);
    end

    % Write out stats file
    csvwrite(stats_fn, stats);
end

%##############################################################################%
%                                CHECK_EM_FILE                                 %
%##############################################################################%
function check_em_file(em_fn, em_data)
% CHECK_EM_FILE check that an EM file was correctly written.
%     CHECK_EM_FILE(...
%         EM_FN, ...
%         EM_DATA)
%
%     Tries to verify that the EM-file was correctly written before proceeding,
%     it should always be run following a call to TOM_EMWRITE to make sure that
%     that function call succeeded. If an error is caught here while trying to
%     read the file that was just written, it just tries to write it again.
%
% Example:
%   CHECK_EM_FILE('my_EM_filename.em', my_EM_data);
%
% See also TOM_EMWRITE

% DRM 11-2017
    size_check = numel(em_data) * 4 + 512;
    while true
        listing = dir(em_fn);
        if isempty(listing)
            fprintf('******\nWARNING:\n\tFile %s does not exist!', em_fn);
            tom_emwrite(em_fn, em_data);
        else
            if listing.bytes ~= size_check
                fprintf('******\nWARNING:\n');
                fprintf('\tFile %s is not the correct size!', em_fn);
                tom_emwrite(em_fn, em_data);
            else
                break;
            end
        end
    end
end

%% Display a progress bar
function new_delprog = disp_progbar(tomogram_number, subtomo_count, ...
        num_subtomo, delprog)
    fmtstr = 'Tomogram %d: [%s%s] - %d%% - %d subtomograms\n';
    count = round(subtomo_count / num_subtomo * 40);
    percent = round(subtomo_count / num_subtomo * 100);
    left = repmat('#', 1, count);
    right = repmat(' ', 1, 40 - count);
    fprintf(delprog);
    fprintf(fmtstr, tomogram_number, left, right, percent, subtomo_count);
    new_delprog = repmat('\b', 1, ...
        length(sprintf(fmtstr, tomogram_number, left, right, percent, ...
        subtomo_count)));
end

%% Test if file exists
function file_exists = isfile(filename)
    [status, attrib] = fileattrib(filename);
    file_exists = status;
end

%% Window out a subvolume from a volume array in memory. tom_red alternative
function region = window(vol, region_start, region_size)
    region = nan(region_size);
    [dim_x, dim_y, dim_z] = size(vol);
    region_start_ = region_start;

    if region_start(1) < 1
        start_x = 1 - region_start(1) + 1;
        if start_x > region_size(1)
            error('Region is entirely outside MRC');
        end
        region_start_(1) = 1;
    else
        start_x = 1;
    end

    if region_start(1) + region_size(1) - 1 > dim_x
        end_x = region_size(1) - (region_start(1) + region_size(1) - 1 - dim_x);
        if end_x < 1
            error('Region is entirely outside MRC');
        end
    else
        end_x = region_size(1);
    end

    region_end(1) = region_start_(1) + end_x - start_x;

    if region_start(2) < 1
        start_y = 1 - region_start(2) + 1;
        if start_y > region_size(2)
            error('Region is entirely outside MRC');
        end
        region_start_(2) = 1;
    else
        start_y = 1;
    end
    
    if region_start(2) + region_size(2) - 1 > dim_y
        end_y = region_size(2) - (region_start(2) + region_size(2) - 1 - dim_y);
        if end_y < 1
            error('Region is entirely outside MRC');
        end
    else
        end_y = region_size(2);
    end

    region_end(2) = region_start_(2) + end_y - start_y;

    if region_start(3) < 1
        start_z = 1 - region_start(3) + 1;
        if start_z > region_size(3)
            error('Region is entirely outside MRC');
        end
        region_start_(3) = 1;
    else
        start_z = 1;
    end

    if region_start(3) + region_size(3) - 1 > dim_z
        end_z = region_size(3) - (region_start(3) + region_size(3) - 1 - dim_z);
        if end_z < 1
            error('Region is entirely outside MRC');
        end
    else
        end_z = region_size(3);
    end

    region_end(3) = region_start_(3) + end_z - start_z;

    region(start_x:end_x, start_y:end_y, start_z:end_z) = vol(...
        region_start_(1):region_end(1), region_start_(2):region_end(2), ...
        region_start_(3):region_end(3));

    region(isnan(region)) = mean(region(:), 'omitnan');
end

%% Window out a subvolume from a memory-map of an MRC File
function region = window_memmap(tomogram, header, region_start, region_size)
    region = nan(region_size);
    region_start_ = region_start;

    if region_start(1) < 1
        start_x = 1 - region_start(1) + 1;
        if start_x > region_size(1)
            error('Region is entirely outside MRC');
        end
        region_start_(1) = 1;
    else
        start_x = 1;
    end

    if region_start(1) + region_size(1) - 1 > header.nx
        end_x = region_size(1) - ...
            (region_start(1) + region_size(1) - 1 - header.nx);
        if end_x < 1
            error('Region is entirely outside MRC');
        end
    else
        end_x = region_size(1);
    end

    region_end(1) = region_start_(1) + end_x - start_x;

    if region_start(2) < 1
        start_y = 1 - region_start(2) + 1;
        if start_y > region_size(2)
            error('Region is entirely outside MRC');
        end
        region_start_(2) = 1;
    else
        start_y = 1;
    end
    
    if region_start(2) + region_size(2) - 1 > header.ny
        end_y = region_size(2) - ...
            (region_start(2) + region_size(2) - 1 - header.ny);
        if end_y < 1
            error('Region is entirely outside MRC');
        end
    else
        end_y = region_size(2);
    end

    region_end(2) = region_start_(2) + end_y - start_y;

    if region_start(3) < 1
        start_z = 1 - region_start(3) + 1;
        if start_z > region_size(3)
            error('Region is entirely outside MRC');
        end
        region_start_(3) = 1;
    else
        start_z = 1;
    end

    if region_start(3) + region_size(3) - 1 > header.nz
        end_z = region_size(3) - ...
            (region_start(3) + region_size(3) - 1 - header.nz);
        if end_z < 1
            error('Region is entirely outside MRC');
        end
    else
        end_z = region_size(3);
    end

    region_end(3) = region_start_(3) + end_z - start_z;

    region(start_x:end_x, start_y:end_y, start_z:end_z) = ...
        tomogram.Data.Value(region_start_(1):region_end(1), ...
        region_start_(2):region_end(2), ...
        region_start_(3):region_end(3));

    region(isnan(region)) = mean(region(:), 'omitnan');
end

%% Window out a subvolume from an MRC File on disk using fread
function region = window_fread(mrc_fn, header, region_start, region_size)
    region = nan(region_size);
    fullsize = [header.nx, header.ny, header.nz];
    region_start_ = region_start;

    if region_start(1) < 1
        start_x = 1 - region_start(1) + 1;
        if start_x > region_size(1)
            error('Region is entirely outside MRC');
        end
        region_start_(1) = 1;
    else
        start_x = 1;
    end

    if region_start(1) + region_size(1) - 1 > header.nx
        end_x = region_size(1) - ...
            (region_start(1) + region_size(1) - 1 - header.nx);
        if end_x < 1
            error('Region is entirely outside MRC');
        end
    else
        end_x = region_size(1);
    end

    dim_x = end_x - start_x + 1;

    if region_start(2) < 1
        start_y = 1 - region_start(2) + 1;
        if start_y > region_size(2)
            error('Region is entirely outside MRC');
        end
        region_start_(2) = 1;
    else
        start_y = 1;
    end
    
    if region_start(2) + region_size(2) - 1 > header.ny
        end_y = region_size(2) - ...
            (region_start(2) + region_size(2) - 1 - header.ny);
        if end_y < 1
            error('Region is entirely outside MRC');
        end
    else
        end_y = region_size(2);
    end

    dim_y = end_y - start_y + 1;

    if region_start(3) < 1
        start_z = 1 - region_start(3) + 1;
        if start_z > region_size(3)
            error('Region is entirely outside MRC');
        end
        region_start_(3) = 1;
    else
        start_z = 1;
    end

    if region_start(3) + region_size(3) - 1 > header.nz
        end_z = region_size(3) - ...
            (region_start(3) + region_size(3) - 1 - header.nz);
        if end_z < 1
            error('Region is entirely outside MRC');
        end
    else
        end_z = region_size(3);
    end

    switch header.mode
        case 0
            precision = sprintf('%d*int8=>int8', dim_x);
            skip = (header.nx - dim_x);
            seek_skip = ((header.ny - dim_y) * header.nx);
            offset = 1024 + header.next ...
                + (sub2ind(fullsize, region_start_(1), region_start_(2), ...
                region_start_(3)) - 1);
        case 1
            precision = sprintf('%d*int16=>int16', dim_x);
            skip = (header.nx - dim_x) * 2;
            seek_skip = ((header.ny - dim_y) * header.nx) * 2;
            offset = 1024 + header.next ...
                + ((sub2ind(fullsize, region_start_(1), region_start_(2), ...
                region_start_(3)) - 1) * 2);
        case 2
            precision = sprintf('%d*single=>single', dim_x);
            skip = (header.nx - dim_x) * 4;
            seek_skip = ((header.ny - dim_y) * header.nx) * 4;
            offset = 1024 + header.next ...
                + ((sub2ind(fullsize, region_start_(1), region_start_(2), ...
                region_start_(3)) - 1) * 4);
        case 6
            precision = sprintf('%d*uint16=>uint16', dim_x);
            skip = (header.nx - dim_x) * 2;
            seek_skip = ((header.ny - dim_y) * header.nx) * 2;
            offset = 1024 + header.next ...
                + ((sub2ind(fullsize, region_start_(1), region_start_(2), ...
                region_start_(3)) - 1) * 2);
        case 8
            precision = sprintf('%d*uint32=>uint32', dim_x);
            skip = (header.nx - dim_x) * 4;
            seek_skip = ((header.ny - dim_y) * header.nx) * 4;
            offset = 1024 + header.next ...
                + ((sub2ind(fullsize, region_start_(1), region_start_(2), ...
                region_start_(3)) - 1) * 4);
        otherwise
            error('Sorry, I cannot read this as an MRC-File !!!');
    end

    [comp_typ, maxsize, endian] = computer;
    switch endian
        case 'L'
            system_format = 'ieee-le';
        case 'B'
            system_format = 'ieee-be';
    end

    fid = fopen(mrc_fn, 'r', system_format);
    if fid == -1
        error(['Cannot open: ' input_fn ' file']);
    end;

    fseek(fid, offset, -1);
    for i = start_z:end_z
        region(start_x:end_x, start_y:end_y, i) = fread(fid, [dim_x, dim_y], ...
            precision, skip);
        fseek(fid, seek_skip, 0);
    end
    fclose(fid);

    region(isnan(region)) = mean(region(:), 'omitnan');
end
