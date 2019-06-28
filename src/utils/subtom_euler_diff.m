function distance = subtom_euler_distance(zxz_euler_1, zxz_euler_2, varargin);
% SUBTOM_EULER_DISTANCE The geodesic distance between two ZXZ Euler angles.
%     SUBTOM_EULER_DISTANCE(
%         ZXZ_EULER_1,
%         ZXZ_EULER_2,
%         ANGLE_FMT,
%         NO_INPLANE)
%
%     Calculates the rotation required to bring the Euler angles in ZXZ_EULER_1
%     specified as a list of [phi, psi, theta], into alignment with the Euler
%     angles in ZXZ_EULER_2. This is a metric on the group of rotations SO3
%     which uses the method of unit quaternions. If NO_INPLANE is logically true
%     then the inplane angles will be fixed to point in the same direction
%     before calculating the distance
%
% Example:
%     subtom_euler_distance([135, 35, 45], [-90, -15, 150]);

%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addRequired(fn_parser, 'zxz_euler_1');
    addRequired(fn_parser, 'zxz_euler_2');
    addParameter(fn_parser, 'angle_fmt', 'degrees');
    addParameter(fn_parser, 'no_inplane', 0);
    parse(fn_parser, zxz_euler_1, zxz_euler_2, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    zxz_euler_1_ = fn_parser.Results.zxz_euler_1;

    try
        validateattributes(zxz_euler_1_, {'numeric'}, ...
            {'vector', 'numel', 3, 'nonnan', 'finite'}, ...
            'subtom_euler_distance', 'zxz_euler_1');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    zxz_euler_2_ = fn_parser.Results.zxz_euler_2;

    try
        validateattributes(zxz_euler_2_, {'numeric'}, ...
            {'vector', 'numel', 3, 'nonnan', 'finite'}, ...
            'subtom_euler_distance', 'zxz_euler_2');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    angle_fmt = fn_parser.Results.angle_fmt;

    if ~strcmp(angle_fmt, 'degrees') && ~strcmp(angle_fmt, 'radians')
        try
            error('subTOM:argumentError', ...
                'euler_distance:angle_fmt: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    degrees_fmt = strcmp(angle_fmt, 'degrees');

    no_inplane = fn_parser.Results.no_inplane;

    if ischar(no_inplane)
        no_inplane = str2double(no_inplane);
    end

    try
        validateattributes(no_inplane, {'numeric'}, ...
            {'nonnan', 'binary', 'scalar'}, ...
            'subtom_euler_distance', 'no_inplane');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    rotation_matrix_1 = subtom_zxz_to_matrix(zxz_euler_1_, ...
        'angle_fmt', angle_fmt);

    rotation_matrix_2 = subtom_zxz_to_matrix(zxz_euler_2_, ...
        'angle_fmt', angle_fmt);

    rotation_matrix_3 = rotation_matrix_1' * rotation_matrix_2;

    quaternion_1 = subtom_matrix_to_quaternion(eye(3));

    if no_inplane
        zxz_euler_3 = subtom_matrix_to_zxz(rotation_matrix_3, ...
            'angle_fmt', angle_fmt);

        if degrees_fmt
            zxz_euler_3(1) = atan2d(-sind(zxz_euler_3(2)), ...
                cosd(zxz_euler_3(2)) * cosd(zxz_euler_3(3)));
        else
            zxz_euler_3(1) = atan2(-sin(zxz_euler_3(2)), ...
                cos(zxz_euler_3(2)) * cos(zxz_euler_3(3)));
        end

        rotation_matrix_4 = subtom_zxz_to_matrix(zxz_euler_3, ...
            'angle_fmt', angle_fmt);

        quaternion_2 = subtom_matrix_to_quaternion(rotation_matrix_4);
    else
        quaternion_2 = subtom_matrix_to_quaternion(rotation_matrix_3);
    end

    if degrees_fmt
        distance = real(acosd(abs(dot(quaternion_1, quaternion_2))) * 2);
    else
        distance = real(acos(abs(dot(quaternion_1, quaternion_2))) * 2);
    end
end
