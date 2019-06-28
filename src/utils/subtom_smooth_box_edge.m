function masked_vol = subtom_smooth_box_edge(volume, box_gaussian)
% SUBTOM_SMOOTH_BOX_EDGE Smooths the edges of a volume.
%
%     SUBTOM_SMOOTH_BOX_EDGE(...
%         VOLUME, ...
%         BOX_GAUSSIAN)
%
% A function to take in a volume and smooth the box edges by masking with a
% smaller box with a gaussian dropoff. The function returns a masked
% volume.

% DRM 05-2019

    % Check that the given box_gaussian is valid.
    try
        validateattributes(box_gaussian, {'numeric'}, ...
            {'integer', 'nonnegative'}, 'subtom_smooth_box_edge', ...
            'box_gaussian');
    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    % Get size of volume
    [dim_x, dim_y, dim_z] = size(volume);

    % Initialize box mask
    box_mask = zeros(dim_x, dim_y, dim_z);

    % We actually use twice the given kernel size so that the kernel tapers
    % right to the edge of the volume.
    box_gaussian_ = 2 * box_gaussian;

    % Get start and end indices
    start_x = 1 + box_gaussian_;
    start_y = start_x;
    start_z = start_x;

    end_x = dim_x - box_gaussian_;
    end_y = dim_y - box_gaussian_;
    end_z = dim_z - box_gaussian_;

    if start_x > end_x || start_y > end_y || start_z > end_z
        try
            error('subTOM:argumentError', ...
                'smooth_box_edge:box_gaussian: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Generate binary mask
    box_mask(start_x:end_x, start_y:end_y, start_z:end_z) = 1;

    % Smooth the binary mask with a Gaussian kernel of box_gaussian and a sigma
    % of box_gaussian.
    smooth_mask = smooth3(box_mask, 'gaussian', box_gaussian, box_gaussian);

    % Return masked volume
    masked_vol = smooth_mask .* volume;
end
