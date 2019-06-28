function region = subtom_window_fread(mrc_fn, header, region_start, region_size)
% SUBTOM_WINDOW_FREAD Window out a region from an MRC file on disk using fread.
%     SUBTOM_WINDOW_FREAD(
%         MRC_FN,
%         HEADER,
%         REGION_START,
%         REGION_SIZE)
%
%    An alternative to the tom_red function to crop out subvolumes from a larger
%    volume array, in this case using fread for a lower memory footprint and
%    without the need to have the entire volume pre-read into memory beforehand.
%    tom_red unfortunately has some dark corners and unaccounted for conditions,
%    which this version attempts to repair. The call is slightly different
%    compared to the call of tom_red, namely in the requirement of passing a
%    structure of the MRC header as HEADER, to determine the type of the data.
%    MRC_FN describes the filename of the volume to be cut from, REGION_START
%    describes the coordinate at which to start the extraction and REGION_SIZE
%    describes the size of the subvolume to extract. If any of the subvolume
%    extends outside the bounds of the volume then this area will be filled in
%    with the mean value of the valid region extracted.
%
% Example:
%     subtom_window_memmap('tomogram.mrc', mrc.Header.MRC, [1, 1, 1],
%         [128, 128, 128]);
%
% See also SUBTOM_WINDOW, SUBTOM_WINDOW_MEMMAP, TOM_RED

    % Create a box of NaNs to hold the data.
    region = nan(region_size);

    % Create a size array for later use of the sub2ind function
    fullsize = [header.nx, header.ny, header.nz];

    % Create a variable for the actual start index in the volume which has data
    % going into the region. This can differ from the given region start when
    % the region hangs off the far left, bottom, or back of the volume assuming
    % the origin is in the back bottom left corner.
    region_start_ = region_start;

    % Create variables for the actual dimensions to be read from volume which
    % has data going into the region. This can differ from the given region size
    % when the region hangs off the far right, top, or front of the volume
    % assuming the origin is in the back bottom left corner. Note the difference
    % between here and subtom_window and subtom_window_memmap where we need end
    % indices in the volume. Here we only need the final dimensions which will
    % be read from the determined starting indices.
    dim_x = region_size(1);
    dim_y = region_size(2);

    % Handle the case when the region hangs off the left.
    if region_start(1) < 1

        % This is the actual start index within the region's indices that
        % overlaps with the volume.
        start_x = 1 - region_start(1) + 1;

        % Handle the case when the region is so far left it doesnt overlap with
        % the volume at all.
        if start_x > region_size(1)
            try
                error('subTOM:outOfBoundsError', ...
                    'window_fread:Region is entirely outside MRC');
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        % We start reading the volume from the far left.
        region_start_(1) = 1;
    else
        start_x = 1;
    end

    % Handle the case when the region hangs off the right.
    if region_start(1) + region_size(1) - 1 > header.nx

        % This is the actual end index within the region's indices that overlaps
        % with the volume.
        end_x = region_size(1) - ...
            (region_start(1) + region_size(1) - 1 - header.nx);

        % Handle the case when the region is so far right that it doesn't
        % overlap with the volume at all.
        if end_x < 1
            try
                error('subTOM:outOfBoundsError', ...
                    'window_fread:Region is entirely outside MRC');
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end
    else
        end_x = region_size(1);
    end

    dim_x = end_x - start_x + 1;

    % Handle the case when the region hangs off the bottom.
    if region_start(2) < 1

        % This is the actual start index within the region's indices that
        % overlaps with the volume.
        start_y = 1 - region_start(2) + 1;

        % Handle the case when the region is so far bottom it doesnt overlap
        % with the volume at all.
        if start_y > region_size(2)
            try
                error('subTOM:outOfBoundsError', ...
                    'window_fread:Region is entirely outside MRC');
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        % We start reading the volume from the far bottom.
        region_start_(2) = 1;
    else
        start_y = 1;
    end
    
    % Handle the case when the region hangs off the top.
    if region_start(2) + region_size(2) - 1 > header.ny

        % This is the actual end index within the region's indices that overlaps
        % with the volume.
        end_y = region_size(2) - ...
            (region_start(2) + region_size(2) - 1 - header.ny);

        % Handle the case when the region is so far top that it doesn't
        % overlap with the volume at all.
        if end_y < 1
            try
                error('subTOM:outOfBoundsError', ...
                    'window_fread:Region is entirely outside MRC');
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end
    else
        end_y = region_size(2);
    end

    dim_y = end_y - start_y + 1;

    % Handle the case when the region hangs off the back.
    if region_start(3) < 1

        % This is the actual start index within the region's indices that
        % overlaps with the volume.
        start_z = 1 - region_start(3) + 1;

        % Handle the case when the region is so far back it doesnt overlap with
        % the volume at all.
        if start_z > region_size(3)
            try
                error('subTOM:outOfBoundsError', ...
                    'window_fread:Region is entirely outside MRC');
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        % We start reading the volume from the far back.
        region_start_(3) = 1;
    else
        start_z = 1;
    end

    % Handle the case when the region hangs off the front.
    if region_start(3) + region_size(3) - 1 > header.nz

        % This is the actual end index within the region's indices that overlaps
        % with the volume.
        end_z = region_size(3) - ...
            (region_start(3) + region_size(3) - 1 - header.nz);

        % Handle the case when the region is so far top front it doesn't
        % overlap with the volume at all.
        if end_z < 1
            try
                error('subTOM:outOfBoundsError', ...
                    'window_fread:Region is entirely outside MRC');
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end
    else
        end_z = region_size(3);
    end

    % Based on the datatype in the MRC-file header field 'Mode', calculate the
    % datatype to read with fread. Based on the dimensions in X and Y that were
    % determined above also calculate how many values to skip reading every row
    % and section. This is all assuming X changes fastest and Z slowest, which
    % can actually differ in the MRC-file format but this capability to differ
    % from X -> Y -> Z has not be seen.
    %
    % precision = the number of values in a row to read, and their type.
    % skip = the number of bytes to skip to go to the next row of X. 
    % seek_skip = the number of bytes to skip to go to the next section in Z.
    % offset = the number of bytes from the file's start to start reading data.
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
            try
                error('subTOM:MRCError', ...
                    'window_fread:%s has unknown datatype %d', mrc_fn, ...
                    header.mode);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
    end

    % Figure out our system endianness.
    [comp_typ, maxsize, endian] = computer;

    switch endian
        case 'L'
            system_format = 'ieee-le';
        case 'B'
            system_format = 'ieee-be';
    end

    % Create a File-Identifier and make sure it can be opened.
    fid = fopen(mrc_fn, 'r', system_format);

    if fid == -1
        try
            error('subTOM:readFileError', ...
                'window_fread:File %s cannot be read', mrc_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Move to the start of the data.
    fseek(fid, offset, -1);

    % Loop over each Z-section
    for i = start_z:end_z

        % Read in correct number of columns and rows using the determined
        % dimensions, datatype, and byte-skips.
        region(start_x:end_x, start_y:end_y, i) = fread(fid, [dim_x, dim_y], ...
            precision, skip);

        % Skip over to the next Z-section
        fseek(fid, seek_skip, 0);
    end

    % Close the File-Identifier
    fclose(fid);

    % Finally set any values in the region that have remained NaNs and
    % unassigned to the mean of read in values from the volume. This should
    % prevent the statistics from changing by filling in with zeros.
    region(isnan(region)) = mean(region(:), 'omitnan');
end
