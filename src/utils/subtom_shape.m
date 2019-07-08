function subtom_shape(varargin)
% SUBTOM_SHAPE produces a volume of a simple shape for masking.
%
%     SUBTOM_SHAPE(
%         'shape', SHAPE,
%         'box_size', BOX_SIZE,
%         'radius', RADIUS,
%         'inner_radius', INNER_RADIUS,
%         'outer_radius', OUTER_RADIUS,
%         'radius_x', RADIUS_X,
%         'radius_y', RADIUS_Y,
%         'radius_z', RADIUS_Z,
%         'inner_radius_x', INNER_RADIUS_X,
%         'inner_radius_y', INNER_RADIUS_Y,
%         'inner_radius_z', INNER_RADIUS_Z,
%         'outer_radius_x', OUTER_RADIUS_X,
%         'outer_radius_y', OUTER_RADIUS_Y,
%         'outer_radius_z', OUTER_RADIUS_Z,
%         'length_x', LENGTH_X,
%         'length_y', LENGTH_Y,
%         'length_z', LENGTH_Z,
%         'height', HEIGHT,
%         'center_x', CENTER_X,
%         'center_y', CENTER_Y,
%         'center_z', CENTER_Z,
%         'shift_x', SHIFT_X,
%         'shift_y', SHIFT_Y,
%         'shift_z', SHIFT_Z,
%         'rotate_phi', ROTATE_PHI,
%         'rotate_psi', ROTATE_PSI,
%         'rotate_theta', ROTATE_THETA,
%         'sigma', SIGMA,
%         'ref_fn', REF_FN,
%         'output_fn', OUTPUT_FN)
%
%     Creates a volume of a simple shape, with the volume being a cube of
%     BOX_SIZE length, and writes out the volume as OUTPUT_FN. This volume is
%     generally used for masking.  The shape in the volume is defined by SHAPE
%     and can be one of several strings, the available shapes are 'sphere',
%     'sphere_shell', 'ellipsoid', 'ellipsoid_shell', 'cylinder', 'tube',
%     'elliptic_cylinder', 'elliptic_tube', and 'cuboid'. For each shape there
%     are a number of options available to define the shape.
%
%     For each shape an optional gaussian smooth edge can be added by defining
%     SIGMA.
%
%     For each shape an optional transform can also be applied to the shape by
%     specifying a shift through the options SHIFT_X, SHIFT_Y, and SHIFT_Z, and
%     the shapes initial center can be specified by CENTER_X, CENTER_Y,
%     CENTER_Z.  Rotations to the shape are applied through the options
%     ROTATE_PHI, ROTATE_PSI, and ROTATE_THETA. Rotations are done about the
%     center and shifts are applied after any given rotation.
%
%     Finally another volume can be given by passing the option REF_FN and the
%     shape will be applied to the volume, which can aid in testing how the
%     shape masks the underlying density.
%
%     If shape is 'sphere', the shape is defined by RADIUS.
%
%     If shape is 'sphere_shell', the shape is defined by INNER_RADIUS and
%     OUTER_RADIUS.
%
%     If shape is 'ellipsoid', the shape is defined by RADIUS_X, RADIUS_Y, and
%     RADIUS_Z.
%
%     If shape is 'ellipsoid_shell', the shape is defined by INNER_RADIUS_X,
%     INNER_RADIUS_Y, INNER_RADIUS_Z, OUTER_RADIUS_X, OUTER_RADIUS_Y, and
%     OUTER_RADIUS_Z.
%
%     If shape is 'cylinder', the shape is defined by RADIUS and HEIGHT.
%
%     If shape is 'tube', the shape is defined by INNER_RADIUS, OUTER_RADIUS,
%     and HEIGHT.
%
%     If shape is 'elliptic_cylinder', the shape is defined by RADIUS_X,
%     RADIUS_Y, and HEIGHT.
%
%     If shape is 'elliptic_tube', the shape is defined by INNER_RADIUS_X,
%     INNER_RADIUS_Y, OUTER_RADIUS_X, OUTER_RADIUS_Y, and HEIGHT.
%
%     Finally if shape is 'cuboid', the shape is defined by LENGTH_X, LENGTH_Y,
%     and LENGTH_Z.

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'shape', '');
    addParameter(fn_parser, 'box_size', '');
    addParameter(fn_parser, 'radius', '');
    addParameter(fn_parser, 'inner_radius', '');
    addParameter(fn_parser, 'outer_radius', '');
    addParameter(fn_parser, 'radius_x', '');
    addParameter(fn_parser, 'radius_y', '');
    addParameter(fn_parser, 'radius_z', '');
    addParameter(fn_parser, 'inner_radius_x', '');
    addParameter(fn_parser, 'inner_radius_y', '');
    addParameter(fn_parser, 'inner_radius_z', '');
    addParameter(fn_parser, 'outer_radius_x', '');
    addParameter(fn_parser, 'outer_radius_y', '');
    addParameter(fn_parser, 'outer_radius_z', '');
    addParameter(fn_parser, 'length_x', '');
    addParameter(fn_parser, 'length_y', '');
    addParameter(fn_parser, 'length_z', '');
    addParameter(fn_parser, 'height', '');
    addParameter(fn_parser, 'center_x', '');
    addParameter(fn_parser, 'center_y', '');
    addParameter(fn_parser, 'center_z', '');
    addParameter(fn_parser, 'shift_x', '');
    addParameter(fn_parser, 'shift_y', '');
    addParameter(fn_parser, 'shift_z', '');
    addParameter(fn_parser, 'rotate_phi', '');
    addParameter(fn_parser, 'rotate_psi', '');
    addParameter(fn_parser, 'rotate_theta', '');
    addParameter(fn_parser, 'sigma', '');
    addParameter(fn_parser, 'ref_fn', '');
    addParameter(fn_parser, 'output_fn', '');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    shape = fn_parser.Results.shape;

    if isempty(shape)
        try
            error('subTOM:missingRequired', ...
                'shape:Parameter %s is required.', ...
                'shape');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    try
        shape = validatestring(shape, [string('sphere'), ...
            string('sphere_shell'), string('ellipsoid'), ...
            string('ellipsoid_shell'), string('cylinder'), string('tube'), ...
            string('elliptic_cylinder'), string('elliptic_tube'), ...
            string('cuboid')], 'subtom_shape', 'shape');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    box_size = fn_parser.Results.box_size;

    if isempty(box_size)
        try
            error('subTOM:missingRequired', ...
                'shape:Parameter %s is required.', ...
                'box_size');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(box_size)
        box_size = str2double(box_size);
    end

    try
        validateattributes(box_size, {'numeric'}, ...
            {'scalar', 'nonnan', 'positive', 'integer'}, ...
            'subtom_shape', 'box_size');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    box_size = repmat(box_size, 1, 3);

    switch shape
        case 'sphere'
            radius = fn_parser.Results.radius;

            if isempty(radius)
                radius = floor(box_size(1) / 2);
            end

            if ischar(radius)
                radius = str2double(radius);
            end

            try
                validateattributes(radius, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'radius');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

        case 'sphere_shell'
            outer_radius = fn_parser.Results.outer_radius;

            if isempty(outer_radius)
                outer_radius = floor(box_size(1) / 2);
            end

            if ischar(outer_radius)
                outer_radius = str2double(outer_radius);
            end

            try
                validateattributes(outer_radius, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'outer_radius');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            inner_radius = fn_parser.Results.inner_radius;

            if isempty(inner_radius)
                inner_radius = outer_radius - 2;
            end

            if ischar(inner_radius)
                inner_radius = str2double(inner_radius);
            end

            try
                validateattributes(inner_radius, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'inner_radius');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            if inner_radius >= outer_radius
                try
                    error('subTOM:argumentError', ...
                        'shape: outer_radius is less than inner radius');

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

        case 'ellipsoid'
            radius_x = fn_parser.Results.radius_x;

            if isempty(radius_x)
                radius_x = floor(box_size(1) / 2);
            end

            if ischar(radius_x)
                radius_x = str2double(radius_x);
            end

            try
                validateattributes(radius_x, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'radius_x');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            radius_y = fn_parser.Results.radius_y;

            if isempty(radius_y)
                radius_y = floor(box_size(2) / 2);
            end

            if ischar(radius_y)
                radius_y = str2double(radius_y);
            end

            try
                validateattributes(radius_y, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'radius_y');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            radius_z = fn_parser.Results.radius_z;

            if isempty(radius_z)
                radius_z = floor(box_size(3) / 2);
            end

            if ischar(radius_z)
                radius_z = str2double(radius_z);
            end

            try
                validateattributes(radius_z, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'radius_z');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

        case 'ellipsoid_shell'
            outer_radius_x = fn_parser.Results.outer_radius_x;

            if isempty(outer_radius_x)
                outer_radius_x = floor(box_size(1) / 2);
            end

            if ischar(outer_radius_x)
                outer_radius_x = str2double(outer_radius_x);
            end

            try
                validateattributes(outer_radius_x, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'outer_radius_x');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            inner_radius_x = fn_parser.Results.inner_radius_x;

            if isempty(inner_radius_x)
                inner_radius_x = outer_radius_x - 2;
            end

            if ischar(inner_radius_x)
                inner_radius_x = str2double(inner_radius_x);
            end

            try
                validateattributes(inner_radius_x, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'inner_radius_x');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            if inner_radius_x >= outer_radius_x
                try
                    error('subTOM:argumentError', ...
                        'shape: outer_radius_x is less than inner radius_x');

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            outer_radius_y = fn_parser.Results.outer_radius_y;

            if isempty(outer_radius_y)
                outer_radius_y = floor(box_size(2) / 2);
            end

            if ischar(outer_radius_y)
                outer_radius_y = str2double(outer_radius_y);
            end

            try
                validateattributes(outer_radius_y, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'outer_radius_y');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            inner_radius_y = fn_parser.Results.inner_radius_y;

            if isempty(inner_radius_y)
                inner_radius_y = outer_radius_y - 2;
            end

            if ischar(inner_radius_y)
                inner_radius_y = str2double(inner_radius_y);
            end

            try
                validateattributes(inner_radius_y, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'inner_radius_y');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            if inner_radius_y >= outer_radius_y
                try
                    error('subTOM:argumentError', ...
                        'shape: outer_radius_y is less than inner radius_y');

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            outer_radius_z = fn_parser.Results.outer_radius_z;

            if isempty(outer_radius_z)
                outer_radius_z = floor(box_size(3) / 2);
            end

            if ischar(outer_radius_z)
                outer_radius_z = str2double(outer_radius_z);
            end

            try
                validateattributes(outer_radius_z, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'outer_radius_z');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            inner_radius_z = fn_parser.Results.inner_radius_z;

            if isempty(inner_radius_z)
                inner_radius_z = outer_radius_z - 2;
            end

            if ischar(inner_radius_z)
                inner_radius_z = str2double(inner_radius_z);
            end

            try
                validateattributes(inner_radius_z, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'inner_radius_z');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            if inner_radius_z >= outer_radius_z
                try
                    error('subTOM:argumentError', ...
                        'shape: outer_radius_z is less than inner radius_z');

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

        case 'cylinder'
            radius = fn_parser.Results.radius;

            if isempty(radius)
                radius = floor(box_size(1) / 2);
            end

            if ischar(radius)
                radius = str2double(radius);
            end

            try
                validateattributes(radius, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'radius');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            height = fn_parser.Results.height;

            if isempty(height)
                height = box_size(3);
            end

            if ischar(height)
                height = str2double(height);
            end

            try
                validateattributes(height, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'height');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

        case 'tube'
            outer_radius = fn_parser.Results.outer_radius;

            if isempty(outer_radius)
                outer_radius = floor(box_size(1) / 2);
            end

            if ischar(outer_radius)
                outer_radius = str2double(outer_radius);
            end

            try
                validateattributes(outer_radius, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'outer_radius');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            inner_radius = fn_parser.Results.inner_radius;

            if isempty(inner_radius)
                inner_radius = outer_radius - 2;
            end

            if ischar(inner_radius)
                inner_radius = str2double(inner_radius);
            end

            try
                validateattributes(inner_radius, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'inner_radius');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            if inner_radius >= outer_radius
                try
                    error('subTOM:argumentError', ...
                        'shape: outer_radius is less than inner radius');

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            height = fn_parser.Results.height;

            if isempty(height)
                height = box_size(3);
            end

            if ischar(height)
                height = str2double(height);
            end

            try
                validateattributes(height, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'height');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

        case 'elliptic_cylinder'
            radius_x = fn_parser.Results.radius_x;

            if isempty(radius_x)
                radius_x = floor(box_size(1) / 2);
            end

            if ischar(radius_x)
                radius_x = str2double(radius_x);
            end

            try
                validateattributes(radius_x, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'radius_x');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            radius_y = fn_parser.Results.radius_y;

            if isempty(radius_y)
                radius_y = floor(box_size(2) / 2);
            end

            if ischar(radius_y)
                radius_y = str2double(radius_y);
            end

            try
                validateattributes(radius_y, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'radius_y');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            height = fn_parser.Results.height;

            if isempty(height)
                height = box_size(3);
            end

            if ischar(height)
                height = str2double(height);
            end

            try
                validateattributes(height, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'height');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

        case 'elliptic_tube'
            outer_radius_x = fn_parser.Results.outer_radius_x;

            if isempty(outer_radius_x)
                outer_radius_x = floor(box_size(1) / 2);
            end

            if ischar(outer_radius_x)
                outer_radius_x = str2double(outer_radius_x);
            end

            try
                validateattributes(outer_radius_x, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'outer_radius_x');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            inner_radius_x = fn_parser.Results.inner_radius_x;

            if isempty(inner_radius_x)
                inner_radius_x = outer_radius_x - 2;
            end

            if ischar(inner_radius_x)
                inner_radius_x = str2double(inner_radius_x);
            end

            try
                validateattributes(inner_radius_x, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'inner_radius_x');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            if inner_radius_x >= outer_radius_x
                try
                    error('subTOM:argumentError', ...
                        'shape: outer_radius_x is less than inner radius_x');

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            outer_radius_y = fn_parser.Results.outer_radius_y;

            if isempty(outer_radius_y)
                outer_radius_y = floor(box_size(2) / 2);
            end

            if ischar(outer_radius_y)
                outer_radius_y = str2double(outer_radius_y);
            end

            try
                validateattributes(outer_radius_y, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'outer_radius_y');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            inner_radius_y = fn_parser.Results.inner_radius_y;

            if isempty(inner_radius_y)
                inner_radius_y = outer_radius_y - 2;
            end

            if ischar(inner_radius_y)
                inner_radius_y = str2double(inner_radius_y);
            end

            try
                validateattributes(inner_radius_y, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'inner_radius_y');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            if inner_radius_y >= outer_radius_y
                try
                    error('subTOM:argumentError', ...
                        'shape: outer_radius_y is less than inner radius_y');

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            height = fn_parser.Results.height;

            if isempty(height)
                height = box_size(3);
            end

            if ischar(height)
                height = str2double(height);
            end

            try
                validateattributes(height, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'height');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

        case 'cuboid'
            length_x = fn_parser.Results.length_x;

            if isempty(length_x)
                length_x = box_size(1);
            end

            if ischar(length_x)
                length_x = str2double(length_x);
            end

            try
                validateattributes(length_x, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'length_x');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            length_y = fn_parser.Results.length_y;

            if isempty(length_y)
                length_y = box_size(2);
            end

            if ischar(length_y)
                length_y = str2double(length_y);
            end

            try
                validateattributes(length_y, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'length_y');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end

            length_z = fn_parser.Results.length_z;

            if isempty(length_z)
                length_z = box_size(3);
            end

            if ischar(length_z)
                length_z = str2double(length_z);
            end

            try
                validateattributes(length_z, {'numeric'}, ...
                    {'scalar', 'nonnan', 'positive'}, ...
                    'subtom_shape', 'length_z');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
    end

    center_x = fn_parser.Results.center_x;

    if ~isempty(center_x)
        if ischar(center_x)
            center_x = str2double(center_x);
        end

        try
            validateattributes(center_x, {'numeric'}, ...
                {'scalar', 'nonnan'}, ...
                'subtom_shape', 'center_x');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    else
        center_x = floor(box_size(1) / 2) + 1;
    end

    center_y = fn_parser.Results.center_y;

    if ~isempty(center_y)
        if ischar(center_y)
            center_y = str2double(center_y);
        end

        try
            validateattributes(center_y, {'numeric'}, ...
                {'scalar', 'nonnan'}, ...
                'subtom_shape', 'center_y');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    else
        center_y = floor(box_size(2) / 2) + 1;
    end

    center_z = fn_parser.Results.center_z;

    if ~isempty(center_z)
        if ischar(center_z)
            center_z = str2double(center_z);
        end

        try
            validateattributes(center_z, {'numeric'}, ...
                {'scalar', 'nonnan'}, ...
                'subtom_shape', 'center_z');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    else
        center_z = floor(box_size(3) / 2) + 1;
    end

    shift_x = fn_parser.Results.shift_x;

    if ~isempty(shift_x)
        if ischar(shift_x)
            shift_x = str2double(shift_x);
        end

        try
            validateattributes(shift_x, {'numeric'}, ...
                {'scalar', 'nonnan'}, ...
                'subtom_shape', 'shift_x');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end

        % This is because we shift the coordinates which is opposite to the
        % transform that the user probably expects.
        shift_x = -shift_x;
    else
        shift_x = 0;
    end

    shift_y = fn_parser.Results.shift_y;

    if ~isempty(shift_y)
        if ischar(shift_y)
            shift_y = str2double(shift_y);
        end

        try
            validateattributes(shift_y, {'numeric'}, ...
                {'scalar', 'nonnan'}, ...
                'subtom_shape', 'shift_y');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end

        % This is because we shift the coordinates which is opposite to the
        % transform that the user probably expects.
        shift_y = -shift_y;
    else
        shift_y = 0;
    end

    shift_z = fn_parser.Results.shift_z;

    if ~isempty(shift_z)
        if ischar(shift_z)
            shift_z = str2double(shift_z);
        end

        try
            validateattributes(shift_z, {'numeric'}, ...
                {'scalar', 'nonnan'}, ...
                'subtom_shape', 'shift_z');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end

        % This is because we shift the coordinates which is opposite to the
        % transform that the user probably expects.
        shift_z = -shift_z;
    else
        shift_z = 0;
    end

    rotate_phi = fn_parser.Results.rotate_phi;

    if ~isempty(rotate_phi)
        if ischar(rotate_phi)
            rotate_phi = str2double(rotate_phi);
        end

        try
            validateattributes(rotate_phi, {'numeric'}, ...
                {'scalar', 'nonnan'}, ...
                'subtom_shape', 'rotate_phi');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end

        % This is because we rotate the coordinates which is opposite to the
        % transform that the user probably expects.
        rotate_phi = -rotate_phi;
    else
        rotate_phi = 0;
    end

    rotate_psi = fn_parser.Results.rotate_psi;

    if ~isempty(rotate_psi)
        if ischar(rotate_psi)
            rotate_psi = str2double(rotate_psi);
        end

        try
            validateattributes(rotate_psi, {'numeric'}, ...
                {'scalar', 'nonnan'}, ...
                'subtom_shape', 'rotate_psi');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end

        % This is because we rotate the coordinates which is opposite to the
        % transform that the user probably expects.
        rotate_psi = -rotate_psi;
    else
        rotate_psi = 0;
    end

    rotate_theta = fn_parser.Results.rotate_theta;

    if ~isempty(rotate_theta)
        if ischar(rotate_theta)
            rotate_theta = str2double(rotate_theta);
        end

        try
            validateattributes(rotate_theta, {'numeric'}, ...
                {'scalar', 'nonnan'}, ...
                'subtom_shape', 'rotate_theta');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end

        % This is because we rotate the coordinates which is opposite to the
        % transform that the user probably expects.
        rotate_theta = -rotate_theta;
    else
        rotate_theta = 0;
    end

    sigma = fn_parser.Results.sigma;

    if ~isempty(sigma)
        if ischar(sigma)
            sigma = str2double(sigma);
        end
        
        try
            validateattributes(sigma, {'numeric'}, ...
                {'scalar', 'nonnan', 'nonnegative'}, ...
                'subtom_shape', 'sigma');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    else
        sigma = 0;
    end

    ref_fn = fn_parser.Results.ref_fn;

    if ~isempty(ref_fn)
        if exist(ref_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'shape:File %s does not exist.', ref_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end
    end

    output_fn = fn_parser.Results.output_fn;

    if isempty(output_fn)
        try
            error('subTOM:missingRequired', ...
                'shape:Parameter %s is required.', ...
                'output_fn');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    fid = fopen(output_fn, 'w');

    if fid == -1
        try
            error('subTOM:writeFileError', ...
                'shape:File %s cannot be opened for writing', ...
                output_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    fclose(fid);

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    mask = zeros(box_size);

    [idx_x, idx_y, idx_z] = ndgrid(1:box_size(1), 1:box_size(2), 1:box_size(3));

    % Cartesian coordinates about the given center.
    cart_x = idx_x - center_x;
    cart_y = idx_y - center_y;
    cart_z = idx_z - center_z;

    % Convert the given rotations into a rotation matrix.
    rot_mat = subtom_zxz_to_matrix([rotate_phi, rotate_psi, rotate_theta], ...
        'angle_fmt', 'degrees');

    % Cartesian coordinates after the given rotations and shifts.
    aff_x = (rot_mat(1, 1) .* cart_x) + (rot_mat(1, 2) .* cart_y) + ...
        (rot_mat(1, 3) .* cart_z) + shift_x;

    aff_y = (rot_mat(2, 1) .* cart_x) + (rot_mat(2, 2) .* cart_y) + ...
        (rot_mat(2, 3) .* cart_z) + shift_y;

    aff_z = (rot_mat(3, 1) .* cart_x) + (rot_mat(3, 2) .* cart_y) + ...
        (rot_mat(3, 3) .* cart_z) + shift_z;

    cart_x = aff_x;
    cart_y = aff_y;
    cart_z = aff_z;

    switch shape
        case 'sphere'
            sphere_idxs  = (cart_x ./ radius).^2 + (cart_y ./ radius).^2 ...
                + (cart_z ./ radius).^2 <= 1;

            mask(sphere_idxs) = 1;

            if sigma > 0
                out_idxs = find((cart_x ./ radius).^2 + ...
                    (cart_y ./ radius).^2 + (cart_z ./ radius).^2 > 1);

                out_idxs = reshape(out_idxs, 1, numel(out_idxs));

                for idx = out_idxs
                    d = ellipsoid_distance(cart_x(idx), cart_y(idx), ...
                        cart_z(idx), radius, radius, radius);

                    mask(idx) = exp(-(d^2 / ((2 * sigma)^2)));
                end
            end

        case 'sphere_shell'
            outer_sphere_idxs  = (cart_x ./ outer_radius).^2 + ...
                (cart_y ./ outer_radius).^2 + (cart_z ./ outer_radius).^2 <= 1;

            mask(outer_sphere_idxs) = 1;

            inner_sphere_idxs  = (cart_x ./ inner_radius).^2 + ...
                (cart_y ./ inner_radius).^2 + (cart_z ./ inner_radius).^2 < 1;

            mask(inner_sphere_idxs) = 0;

            if sigma > 0
                outer_idxs = find((cart_x ./ outer_radius).^2 + ...
                    (cart_y ./ outer_radius).^2 + ...
                    (cart_z ./ outer_radius).^2 > 1);

                outer_idxs = reshape(outer_idxs, 1, numel(outer_idxs));

                for idx = outer_idxs
                    d = ellipsoid_distance(cart_x(idx), cart_y(idx), ...
                        cart_z(idx), outer_radius, outer_radius, outer_radius);

                    mask(idx) = exp(-(d^2 / ((2 * sigma)^2)));
                end

                inner_idxs = find((cart_x ./ inner_radius).^2 + ...
                    (cart_y ./ inner_radius).^2 + ...
                    (cart_z ./ inner_radius).^2 < 1);

                inner_idxs = reshape(inner_idxs, 1, numel(inner_idxs));

                for idx = inner_idxs
                    d = ellipsoid_distance(cart_x(idx), cart_y(idx), ...
                        cart_z(idx), inner_radius, inner_radius, inner_radius);

                    mask(idx) = exp(-(d^2 / ((2 * sigma)^2)));
                end
            end

        case 'ellipsoid'
            ellipsoid_idxs  = (cart_x ./ radius_x).^2 + ...
                (cart_y ./ radius_y).^2 + (cart_z ./ radius_z).^2 <= 1;

            mask(ellipsoid_idxs) = 1;

            if sigma > 0
                out_idxs = find((cart_x ./ radius_x).^2 + ...
                    (cart_y ./ radius_y).^2 + (cart_z ./ radius_z).^2 > 1);

                out_idxs = reshape(out_idxs, 1, numel(out_idxs));

                for idx = out_idxs
                    d = ellipsoid_distance(cart_x(idx), cart_y(idx), ...
                        cart_z(idx), radius_x, radius_y, radius_z);

                    mask(idx) = exp(-(d^2 / ((2 * sigma)^2)));
                end
            end

        case 'ellipsoid_shell'
            outer_ellipsoid_idxs  = (cart_x ./ outer_radius_x).^2 + ...
                (cart_y ./ outer_radius_y).^2 + ...
                (cart_z ./ outer_radius_z).^2 <= 1;

            mask(outer_ellipsoid_idxs) = 1;

            inner_ellipsoid_idxs  = (cart_x ./ inner_radius_x).^2 + ...
                (cart_y ./ inner_radius_y).^2 + ...
                (cart_z ./ inner_radius_z).^2 < 1;

            mask(inner_ellipsoid_idxs) = 0;

            if sigma > 0
                outer_idxs = find((cart_x ./ outer_radius_x).^2 + ...
                    (cart_y ./ outer_radius_y).^2 + ...
                    (cart_z ./ outer_radius_z).^2 > 1);

                outer_idxs = reshape(outer_idxs, 1, numel(outer_idxs));

                for idx = outer_idxs
                    d = ellipsoid_distance(cart_x(idx), cart_y(idx), ...
                        cart_z(idx), outer_radius_x, outer_radius_y, ...
                        outer_radius_z);

                    mask(idx) = exp(-(d^2 / ((2 * sigma)^2)));
                end

                inner_idxs = find((cart_x ./ inner_radius_x).^2 + ...
                    (cart_y ./ inner_radius_y).^2 + ...
                    (cart_z ./ inner_radius_z).^2 < 1);

                inner_idxs = reshape(inner_idxs, 1, numel(inner_idxs));

                for idx = inner_idxs
                    d = ellipsoid_distance(cart_x(idx), cart_y(idx), ...
                        cart_z(idx), inner_radius_x, inner_radius_y, ...
                        inner_radius_z);

                    mask(idx) = exp(-(d^2 / ((2 * sigma)^2)));
                end
            end

        case 'cylinder'
            half_height = height / 2;
            cylinder_idxs  = ((cart_x ./ radius).^2 + (cart_y ./ radius).^2 ...
                <= 1) & (abs(cart_z) <= half_height);

            mask(cylinder_idxs) = 1;

            if sigma > 0
                side_idxs = find(((cart_x ./ radius).^2 + ...
                    (cart_y ./ radius).^2 > 1) & (abs(cart_z) <= half_height));

                side_idxs = reshape(side_idxs, 1, numel(side_idxs));

                for idx = side_idxs
                    d = ellipse_distance(cart_x(idx), cart_y(idx), ...
                        radius, radius);

                    mask(idx) = exp(-(d^2 / ((2 * sigma)^2)));
                end

                cap_idxs = ((cart_x ./ radius).^2 + (cart_y ./ radius).^2 ...
                    <= 1) & (abs(cart_z) > half_height);

                mask(cap_idxs) = exp(-(abs(cart_z(cap_idxs)) ...
                    - half_height).^2 ./ ((2 * sigma)^2));

                both_idxs = find(((cart_x ./ radius).^2 + ...
                    (cart_y ./ radius).^2 > 1) & (abs(cart_z) > half_height));

                both_idxs = reshape(both_idxs, 1, numel(both_idxs));

                for idx = both_idxs
                    d = ellipse_distance(cart_x(idx), cart_y(idx), ...
                        radius, radius);

                    mask(idx) = exp(-(d^2 / ((2 * sigma)^2))) .* ...
                        exp(-(abs(cart_z(idx)) - half_height).^2 ./ ...
                        ((2 * sigma)^2));

                end
            end

        case 'tube'
            half_height = height / 2;
            outer_tube_idxs  = ((cart_x ./ outer_radius).^2 + ...
                (cart_y ./ outer_radius).^2 <= 1) & ...
                (abs(cart_z) <= half_height);

            mask(outer_tube_idxs) = 1;

            inner_tube_idxs  = ((cart_x ./ inner_radius).^2 + ...
                (cart_y ./ inner_radius).^2 < 1) & ...
                (abs(cart_z) <= half_height);

            mask(inner_tube_idxs) = 0;

            if sigma > 0
                cap_idxs = ((cart_x ./ inner_radius).^2 + ...
                    (cart_y ./ inner_radius).^2 >= 1) & ...
                    ((cart_x ./ outer_radius).^2 + ...
                    (cart_y ./ outer_radius).^2 <= 1) & ...
                    (abs(cart_z) > half_height);

                mask(cap_idxs) = exp(-(abs(cart_z(cap_idxs)) ...
                    - half_height).^2 ./ ((2 * sigma)^2));

                outer_side_idxs = find(((cart_x ./ outer_radius).^2 + ...
                    (cart_y ./ outer_radius).^2 > 1) & ...
                    (abs(cart_z) <= half_height));

                outer_side_idxs = reshape(outer_side_idxs, 1, ...
                    numel(outer_side_idxs));

                for idx = outer_side_idxs
                    d = ellipse_distance(cart_x(idx), cart_y(idx), ...
                        outer_radius, outer_radius);

                    mask(idx) = exp(-(d^2 / ((2 * sigma)^2)));
                end

                inner_side_idxs = find(((cart_x ./ inner_radius).^2 + ...
                    (cart_y ./ inner_radius).^2 < 1) & ...
                    (abs(cart_z) <= half_height));

                inner_side_idxs = reshape(inner_side_idxs, 1, ...
                    numel(inner_side_idxs));

                for idx = inner_side_idxs
                    d = ellipse_distance(cart_x(idx), cart_y(idx), ...
                        inner_radius, inner_radius);

                    mask(idx) = exp(-(d^2 / ((2 * sigma)^2)));
                end

                outer_both_idxs = find(((cart_x ./ outer_radius).^2 + ...
                    (cart_y ./ outer_radius).^2 > 1) & ...
                    (abs(cart_z) > half_height));

                outer_both_idxs = reshape(outer_both_idxs, 1, ...
                    numel(outer_both_idxs));

                for idx = outer_both_idxs
                    d = ellipse_distance(cart_x(idx), cart_y(idx), ...
                        outer_radius, outer_radius);

                    mask(idx) = exp(-(d^2 / ((2 * sigma)^2))) .* ...
                        exp(-(abs(cart_z(idx)) - half_height).^2 ./ ...
                        ((2 * sigma)^2));

                end

                inner_both_idxs = find(((cart_x ./ inner_radius).^2 + ...
                    (cart_y ./ inner_radius).^2 < 1) & ...
                    (abs(cart_z) > half_height));

                inner_both_idxs = reshape(inner_both_idxs, 1, ...
                    numel(inner_both_idxs));

                for idx = inner_both_idxs
                    d = ellipse_distance(cart_x(idx), cart_y(idx), ...
                        inner_radius, inner_radius);

                    mask(idx) = exp(-(d^2 / ((2 * sigma)^2))) .* ...
                        exp(-(abs(cart_z(idx)) - half_height).^2 ./ ...
                        ((2 * sigma)^2));

                end
            end

        case 'elliptic_cylinder'
            half_height = height / 2;
            cylinder_idxs  = ((cart_x ./ radius_x).^2 + ...
                (cart_y ./ radius_y).^2 <= 1) & (abs(cart_z) <= half_height);

            mask(cylinder_idxs) = 1;

            if sigma > 0
                side_idxs = find(((cart_x ./ radius_x).^2 + ...
                    (cart_y ./ radius_y).^2 > 1) & ...
                    (abs(cart_z) <= half_height));

                side_idxs = reshape(side_idxs, 1, numel(side_idxs));

                for idx = side_idxs
                    d = ellipse_distance(cart_x(idx), cart_y(idx), ...
                        radius_x, radius_y);

                    mask(idx) = exp(-(d^2 / ((2 * sigma)^2)));
                end

                cap_idxs = ((cart_x ./ radius_x).^2 + ...
                    (cart_y ./ radius_y).^2 <= 1) & (abs(cart_z) > half_height);

                mask(cap_idxs) = exp(-(abs(cart_z(cap_idxs)) ...
                    - half_height).^2 ./ ((2 * sigma)^2));

                both_idxs = find(((cart_x ./ radius_x).^2 + ...
                    (cart_y ./ radius_y).^2 > 1) & (abs(cart_z) > half_height));

                both_idxs = reshape(both_idxs, 1, numel(both_idxs));

                for idx = both_idxs
                    d = ellipse_distance(cart_x(idx), cart_y(idx), ...
                        radius_x, radius_y);

                    mask(idx) = exp(-(d^2 / ((2 * sigma)^2))) .* ...
                        exp(-(abs(cart_z(idx)) - half_height).^2 ./ ...
                        ((2 * sigma)^2));

                end
            end

        case 'elliptic_tube'
            half_height = height / 2;
            outer_tube_idxs  = ((cart_x ./ outer_radius_x).^2 + ...
                (cart_y ./ outer_radius_y).^2 <= 1) & ...
                (abs(cart_z) <= half_height);

            mask(outer_tube_idxs) = 1;

            inner_tube_idxs  = ((cart_x ./ inner_radius_x).^2 + ...
                (cart_y ./ inner_radius_y).^2 < 1) & ...
                (abs(cart_z) <= half_height);

            mask(inner_tube_idxs) = 0;

            if sigma > 0
                cap_idxs = ((cart_x ./ inner_radius_x).^2 + ...
                    (cart_y ./ inner_radius_y).^2 >= 1) & ...
                    ((cart_x ./ outer_radius_x).^2 + ...
                    (cart_y ./ outer_radius_y).^2 <= 1) & ...
                    (abs(cart_z) > half_height);

                mask(cap_idxs) = exp(-(abs(cart_z(cap_idxs)) ...
                    - half_height).^2 ./ ((2 * sigma)^2));

                outer_side_idxs = find(((cart_x ./ outer_radius_x).^2 + ...
                    (cart_y ./ outer_radius_y).^2 > 1) & ...
                    (abs(cart_z) <= half_height));

                outer_side_idxs = reshape(outer_side_idxs, 1, ...
                    numel(outer_side_idxs));

                for idx = outer_side_idxs
                    d = ellipse_distance(cart_x(idx), cart_y(idx), ...
                        outer_radius_x, outer_radius_y);

                    mask(idx) = exp(-(d^2 / ((2 * sigma)^2)));
                end

                inner_side_idxs = find(((cart_x ./ inner_radius_x).^2 + ...
                    (cart_y ./ inner_radius_y).^2 < 1) & ...
                    (abs(cart_z) <= half_height));

                inner_side_idxs = reshape(inner_side_idxs, 1, ...
                    numel(inner_side_idxs));

                for idx = inner_side_idxs
                    d = ellipse_distance(cart_x(idx), cart_y(idx), ...
                        inner_radius_x, inner_radius_y);

                    mask(idx) = exp(-(d^2 / ((2 * sigma)^2)));
                end

                outer_both_idxs = find(((cart_x ./ outer_radius_x).^2 + ...
                    (cart_y ./ outer_radius_y).^2 > 1) & ...
                    (abs(cart_z) > half_height));

                outer_both_idxs = reshape(outer_both_idxs, 1, ...
                    numel(outer_both_idxs));

                for idx = outer_both_idxs
                    d = ellipse_distance(cart_x(idx), cart_y(idx), ...
                        outer_radius_x, outer_radius_y);

                    mask(idx) = exp(-(d^2 / ((2 * sigma)^2))) .* ...
                        exp(-(abs(cart_z(idx)) - half_height).^2 ./ ...
                        ((2 * sigma)^2));

                end

                inner_both_idxs = find(((cart_x ./ inner_radius_x).^2 + ...
                    (cart_y ./ inner_radius_y).^2 < 1) & ...
                    (abs(cart_z) > half_height));

                inner_both_idxs = reshape(inner_both_idxs, 1, ...
                    numel(inner_both_idxs));

                for idx = inner_both_idxs
                    d = ellipse_distance(cart_x(idx), cart_y(idx), ...
                        inner_radius_x, inner_radius_y);

                    mask(idx) = exp(-(d^2 / ((2 * sigma)^2))) .* ...
                        exp(-(abs(cart_z(idx)) - half_height).^2 ./ ...
                        ((2 * sigma)^2));

                end
            end

        case 'cuboid'
            length_x = length_x / 2;
            length_y = length_y / 2;
            length_z = length_z / 2;
            cuboid_idxs = (abs(cart_x) <= length_x) & ...
                (abs(cart_y) <= length_y) & (abs(cart_z) <= length_z);

            mask(cuboid_idxs) = 1;

            if sigma > 0
                side_x_idxs = (abs(cart_x) > length_x) & ...
                    (abs(cart_y) <= length_y) & (abs(cart_z) <= length_z);

                mask(side_x_idxs) = exp(-(abs(cart_x(side_x_idxs)) ...
                    - length_x).^2 ./ ((2 * sigma)^2));

                side_y_idxs = (abs(cart_x) <= length_x) & ...
                    (abs(cart_y) > length_y) & (abs(cart_z) <= length_z);

                mask(side_y_idxs) = exp(-(abs(cart_y(side_y_idxs)) ...
                    - length_y).^2 ./ ((2 * sigma)^2));

                side_z_idxs = (abs(cart_x) <= length_x) & ...
                    (abs(cart_y) <= length_y) & (abs(cart_z) > length_z);

                mask(side_z_idxs) = exp(-(abs(cart_z(side_z_idxs)) ...
                    - length_z).^2 ./ ((2 * sigma)^2));

                side_xy_idxs = (abs(cart_x) > length_x) & ...
                    (abs(cart_y) > length_y) & (abs(cart_z) <= length_z);

                mask(side_xy_idxs) = exp(-(abs(cart_x(side_xy_idxs)) ...
                    - length_x).^2 ./ ((2 * sigma)^2)) .* ...
                    exp(-(abs(cart_y(side_xy_idxs)) - length_y).^2 ...
                    ./ ((2 * sigma)^2));

                side_xz_idxs = (abs(cart_x) > length_x) & ...
                    (abs(cart_y) <= length_y) & (abs(cart_z) > length_z);

                mask(side_xz_idxs) = exp(-(abs(cart_x(side_xz_idxs)) ...
                    - length_x).^2 ./ ((2 * sigma)^2)) .* ...
                    exp(-(abs(cart_z(side_xz_idxs)) - length_z).^2 ...
                    ./ ((2 * sigma)^2));

                side_yz_idxs = (abs(cart_x) <= length_x) & ...
                    (abs(cart_y) > length_y) & (abs(cart_z) > length_z);

                mask(side_yz_idxs) = exp(-(abs(cart_y(side_yz_idxs)) ...
                    - length_y).^2 ./ ((2 * sigma)^2)) .* ...
                    exp(-(abs(cart_z(side_yz_idxs)) - length_z).^2 ...
                    ./ ((2 * sigma)^2));

                side_xyz_idxs = (abs(cart_x) > length_x) & ...
                    (abs(cart_y) > length_y) & (abs(cart_z) > length_z);

                mask(side_xyz_idxs) = exp(-(abs(cart_x(side_xyz_idxs)) ...
                    - length_x).^2 ./ ((2 * sigma)^2)) .* ...
                    exp(-(abs(cart_y(side_xyz_idxs)) - length_y).^2 ...
                    ./ ((2 * sigma)^2)) .* exp(-(abs(cart_z(side_xyz_idxs)) ...
                    - length_z).^2 ./ ((2 * sigma)^2));

            end
    end

    % This is to emulate TOM behaviour in tom_sphere and tom_spheremask
    mask(mask < exp(-2)) = 0;

    tom_emwrite(output_fn, mask);
    subtom_check_em_file(output_fn, mask);

    if ~isempty(ref_fn)
        [ref_dir, ref_base, ~] = fileparts(ref_fn);
        masked_ref_fn = sprintf('%s_masked.em', fullfile(ref_dir, ref_base));
        ref = getfield(tom_emread(ref_fn), 'Value');

        if ~all(size(ref) == box_size)
            try
                error('subTOM:volDimError', ...
                    'shape:%s and box_size are not same size.', ref_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        masked_ref = ref .* mask;
        tom_emwrite(masked_ref_fn, masked_ref);
        subtom_check_em_file(masked_ref_fn, masked_ref);
    end
end

function s = get_real_root2(r_1, z_1, z_2, g)
    n_1 = r_1 * z_1;
    s_1 = z_2 - 1;

    if g < 0
        s_2 = 0;
    else
        s_2 = sqrt(n_1^2 + z_2^2) - 1;
    end

    s = -Inf;
    s_ = Inf;

    while abs(s - s_) > eps
        s_ = s;

        s = (s_1 + s_2) / 2;

        if (s == s_1) || (s == s_2)
            break
        end

        ratio_1 = n_1 / (s + r_1);
        ratio_2 = z_2 / (s + 1);
        g = ratio_1^2 + ratio_2^2 - 1;

        if g > 0
            s_1 = s;
        elseif g < 0
            s_2 = s;
        else
            break
        end
    end
end

function d = ellipse_distance(p_x, p_y, radius_x, radius_y)
    if p_x < 0
        p_x_ = -p_x;
    else
        p_x_ = p_x;
    end

    if p_y < 0
        p_y_ = -p_y;
    else
        p_y_ = p_y;
    end

    radii_sorted = sort([radius_x, radius_y], 'descend');
    radius_1 = radii_sorted(1);
    radius_2 = radii_sorted(2);

    if radius_x == radius_1
        p_1 = p_x_;
        p_2 = p_y_;
    else
        p_1 = p_y_;
        p_2 = p_x_;
    end

    if p_2 > 0
        if p_1 > 0
            z_1 = p_1 / radius_1;
            z_2 = p_2 / radius_2;
            g = z_1^2 + z_2^2 - 1;

            if abs(g) <= eps
                d = 0;
            else
                r_1 = (radius_1 / radius_2)^2;
                s_1 = get_real_root2(r_1, z_1, z_2, g);
                e_1 = r_1 * p_1 / (s_1 + r_1);
                e_2 = p_2  / (s_1 + 1);
                d = sqrt((e_1 - p_1)^2 + (e_2 - p_2)^2);
            end

        else
            d = abs(p_2 - radius_2);
        end

    else
        numerator = radius_1 * p_1;
        denomenator = radius_1^2 - radius_2^2;

        if numerator < denomenator
            ratio = numerator / denomenator;
            e_1 = radius_1 * ratio;
            e_2 = radius_2 * sqrt(1 - ratio^2);
            d = sqrt((e_1 - p_1)^2 + e_2^2);
        else
            d = abs(p_1 - radius_1);
        end
    end
end

function s = get_real_root3(r_1, r_2, z_1, z_2, z_3, g)
    n_1 = r_1 * z_1;
    n_2 = r_2 * z_2;
    s_1 = z_3 - 1;

    if g < 0
        s_2 = 0;
    else
        s_2 = sqrt(n_1^2 + n_2^2 + z_3^2) - 1;
    end

    s = -Inf;
    s_ = Inf;

    while abs(s - s_) > eps
        s_ = s;

        s = (s_1 + s_2) / 2;

        if s == s_1 || s== s_2
            break
        end

        ratio_1 = n_1 / (s + r_1);
        ratio_2 = n_2 / (s + r_2);
        ratio_3 = z_3 / (s + 1);
        g = ratio_1^2 + ratio_2^2 + ratio_3^2 - 1;

        if g > 0
            s_1 = s;
        elseif g < 0
            s_2 = s;
        else
            break
        end
    end
end

function d = ellipsoid_distance(p_x, p_y, p_z, radius_x, radius_y, radius_z)
    if p_x < 0
        p_x_ = -p_x;
    else
        p_x_ = p_x;
    end

    if p_y < 0
        p_y_ = -p_y;
    else
        p_y_ = p_y;
    end

    if p_z < 0
        p_z_ = -p_z;
    else
        p_z_ = p_z;
    end

    radii_sorted = sort([radius_x, radius_y, radius_z], 'descend');
    radius_1 = radii_sorted(1);
    radius_2 = radii_sorted(2);
    radius_3 = radii_sorted(3);

    if radius_x == radius_1
        p_1 = p_x_;

        if radius_y == radius_2
            p_2 = p_y_;
            p_3 = p_z_;
        else
            p_3 = p_y_;
            p_2 = p_z_;
        end
    elseif radius_x == radius_2
        p_2 = p_x_;

        if radius_y == radius_1
            p_1 = p_y_;
            p_3 = p_z_;
        else
            p_3 = p_y_;
            p_1 = p_z_;
        end
    else
        p_3 = p_x_;

        if radius_y == radius_1
            p_1 = p_y_;
            p_2 = p_z_;
        else
            p_2 = p_y_;
            p_1 = p_z_;
        end
    end

    if (p_3 > 0)
        if (p_2 > 0)
            if (p_1 > 0)
                z_1 = p_1 / radius_1;
                z_2 = p_2 / radius_2;
                z_3 = p_3 / radius_3;

                g = z_1^2 + z_2^2 + z_3^2 - 1;

                if abs(g) <= eps
                    e_1 = p_1;
                    e_2 = p_2;
                    e_3 = p_3;
                    d = 0;
                else
                    r_1 = (radius_1 / radius_3)^2;
                    r_2 = (radius_2 / radius_3)^2;
                    s_1 = get_real_root3(r_1, r_2, z_1, z_2, z_3, g);
                    e_1 = r_1 * p_1 / (s_1 + r_1);
                    e_2 = r_2 * p_2 / (s_1 + r_2);
                    e_3 = p_3 / (s_1 + 1);
                    d = sqrt((e_1 - p_1)^2 + (e_2 - p_2)^2 + (e_3 - p_3)^2);
                end
            else %p_1 == 0
                d = ellipse_distance(p_2, p_3, radius_2, radius_3);
            end
        else % p_2 == 0
            if(p_1 > 0)
                d = ellipse_distance(p_1, p_3, radius_1, radius_3);
            else % p_1 == 0
                d = abs(p_3 - radius_3);
            end
        end
    else % p_3 == 0
        denomenator_1 = radius_1 * radius_1 - radius_3 * radius_3;
        denomenator_2 = radius_2 * radius_2 - radius_3 * radius_3;
        numerator_1 = radius_1 * p_1;
        numerator_2 = radius_2 * p_2;
        computed = false;

        if (numerator_1 < denomenator_1) && (numerator_2 < denomenator_2)
            ratio_1 = numerator_1 / denomenator_1;
            ratio_2 = numerator_2 / denomenator_2;
            discr = 1 - ratio_1^2 - ratio_2^2;

            if (discr > 0)
                e_1 = radius_1 * ratio_1;
                e_2 = radius_2 * ratio_2;
                e_3 = radius_3 * sqrt(discr);
                d = sqrt((e_1 - p_1) * (e_1 - p_1) + ...
                         (e_2 - p_2) * (e_2 - p_2) + e_3 * e_3);

                computed = true;
            end

        end

        if ~computed
            d = ellipse_distance(p_1, p_2, radius_1, radius_2);
        end
    end
end
