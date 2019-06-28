function region = subtom_window(vol, region_start, region_size)
% SUBTOM_WINDOW tom_red alternative to box out a region from an array in memory.
%     SUBTOM_WINDOW(
%         VOL,
%         REGION_START,
%         REGION_SIZE)
%
%    An alternative to the tom_red function to crop out subvolumes from a larger
%    volume array. tom_red unfortunately has some dark corners and unaccounted
%    for conditions, which this version attempts to repair. The call is of the
%    same format for tom_red, where VOL describes the volume to be cut from,
%    REGION_START describes the coordinate at which to start the extraction and
%    REGION_SIZE describes the size of the subvolume to extract. If any of the
%    subvolume extends outside the bounds of the volume then this area will be
%    filled in with the mean value of the valid region extracted.
%
% Example:
%     SUBTOM_WINDOW(tomogram, [1, 1, 1], [128, 128, 128]);
%
% See also SUBTOM_WINDOW_FREAD, SUBTOM_WINDOW_MEMMAP, TOM_RED

    % Create a box of NaNs to hold the data.
    region = nan(region_size);

    % Find the box size of the volume to extract from.
    [dim_x, dim_y, dim_z] = size(vol);

    % Create a variable for the actual start index in the volume which has data
    % going into the region. This can differ from the given region start when
    % the region hangs off the far left, bottom, or back of the volume assuming
    % the origin is in the back bottom left corner.
    region_start_ = reshape(region_start, 1, 3);

    % Create a variable for the actual end index in the volume which has data
    % going into the region. This can differ from the given region start and
    % region size when the region hangs off the far right, top, or front of the
    % volume assuming the origin is in the back bottom left corner.
    region_end = region_start_ + reshape(region_size, 1, 3) - 1;

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
                    'window: Region is entirely outside MRC');
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
    if region_start(1) + region_size(1) - 1 > dim_x

        % This is the actual end index within the region's indices that overlaps
        % with the volume.
        end_x = region_size(1) - (region_start(1) + region_size(1) - 1 - dim_x);

        % Handle the case when the region is so far right that it doesn't
        % overlap with the volume at all.
        if end_x < 1
            try
                error('subTOM:outOfBoundsError', ...
                    'window: Region is entirely outside MRC');
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end
    else
        end_x = region_size(1);
    end

    region_end(1) = region_start_(1) + end_x - start_x;

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
                    'window: Region is entirely outside MRC');
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
    if region_start(2) + region_size(2) - 1 > dim_y

        % This is the actual end index within the region's indices that overlaps
        % with the volume.
        end_y = region_size(2) - (region_start(2) + region_size(2) - 1 - dim_y);

        % Handle the case when the region is so far top that it doesn't
        % overlap with the volume at all.
        if end_y < 1
            try
                error('subTOM:outOfBoundsError', ...
                    'window: Region is entirely outside MRC');
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end
    else
        end_y = region_size(2);
    end

    region_end(2) = region_start_(2) + end_y - start_y;

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
                    'window: Region is entirely outside MRC');
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
    if region_start(3) + region_size(3) - 1 > dim_z

        % This is the actual end index within the region's indices that overlaps
        % with the volume.
        end_z = region_size(3) - (region_start(3) + region_size(3) - 1 - dim_z);

        % Handle the case when the region is so far top front it doesn't
        % overlap with the volume at all.
        if end_z < 1
            try
                error('subTOM:outOfBoundsError', ...
                    'window: Region is entirely outside MRC');
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end
    else
        end_z = region_size(3);
    end

    region_end(3) = region_start_(3) + end_z - start_z;

    % Set the indices in the region that overlap the volume with the determined
    % start and end indices in the volume.
    region(start_x:end_x, start_y:end_y, start_z:end_z) = vol(...
        region_start_(1):region_end(1), region_start_(2):region_end(2), ...
        region_start_(3):region_end(3));

    % Finally set any values in the region that have remained NaNs and
    % unassigned to the mean of read in values from the volume. This should
    % prevent the statistics from changing by filling in with zeros.
    region(isnan(region)) = mean(region(:), 'omitnan');
end
