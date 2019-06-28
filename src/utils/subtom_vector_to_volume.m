function output_volume = subtom_vector_to_volume(varargin)
% SUBTOM_VECTOR_TO_VOLUME convert a vector to a 3D volume.
%
%     SUBTOM_VECTOR_TO_VOLUME(
%         'input_vector', INPUT_VECTOR,
%         'interp_method', INTERP_METHOD)
%
% TODO: Add more information here
%
% Example:
%     subtom_vector_to_volume(FSC_curve)
%
% See also TOM_SPH2CART

% DRM 01-2019

%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%
    fn_parser = inputParser;
    addParameter(fn_parser, 'input_vector', '');
    addParameter(fn_parser, 'method', 'nearest');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    input_vector = fn_parser.Results.input_vector;

    % First verify that the input_vector given is actually a vector.
    try
        validateattributes(input_vector, {'numeric'}, ...
            {'vector'}, ...
            'subtom_vector_to_volume', 'input_vector');
    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    valid_methods = {'linear', 'nearest', 'next', 'previous', 'pchip', ...
        'cubic', 'v5cubic', 'makima', 'spline'};

    method = fn_parser.Results.method;

    % Verify that method given is one accepted by interp1
    if ~any(strcmp(method, valid_methods))
        try
            error('subTOM:argumentError', ...
                'vector_to_volume:method: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Get the length of the vector which is the radius of the output volume.
    radius = length(input_vector);

    % Here we figure out the spatial index boundaries which depend on whether
    % the input_vector has an even or odd length.
    %
    % For vectors with odd length = N the grid runs from -(N - 1):(N - 2)
    % For vectors with even length = M the grid runs from -(M - 1):(M - 1)
    % i.e. length = 17 -> -16:15 which makes a 32x32x32 volume
    %      length = 24 -> -23:23 which makes a 47x47x47 volume
    grid_start = -(radius - 1);
    
    if mod(radius, 2) == 0
        grid_end = radius - 1;
    else
        grid_end = radius - 2;
    end

    % Create the cartesian grid of points in X, Y, and Z
    [grid_x, grid_y, grid_z] = ndgrid(grid_start:grid_end);

    % Calculate the spatial radius at each point in the volume. The plus one
    % here is to handle the MATLAB indexing style from one.
    radii_vol = sqrt(grid_x.^2 + grid_y.^2 + grid_z.^2) + 1;

    % Find which radii are within our vector
    valid_idxs = find(radii_vol <= radius);

    % Convert the calculated valid radii into a sorted vector of unique values
    radii_vals = sort(unique(radii_vol(valid_idxs)));

    % Interpolate the vector over the determined radii values above using linear
    % interpolation and setting all values outside the original vector to 0,
    % although there should be any extrapolation.
    interp_vector = interp1(input_vector, radii_vals, method, 0);

    % Create the final output volume which has the same size as the volume
    % containing the radii.
    output_volume = zeros(size(radii_vol));

    % Finally fill in the volume using the interpolated vector the unique radii
    % values and the radii volume.
    output_volume(valid_idxs) = arrayfun(...
        @(x) interp_vector(radii_vals == x), radii_vol(valid_idxs));
end
