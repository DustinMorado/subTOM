function quaternion = subtom_matrix_to_quaternion(rotation_matrix)
% SUBTOM_MATRIX_TO_QUATERNION Converts a rotation matrix to unit quaternion.
%     MATRIX_TO_QUATERNION(
%         ROTATION_MATRIX)
%
%     Calculates the unit quaternion format of a given rotation in SO3 for the
%     argument rotation matrix. This is then used to calculate proper metrics
%     over distances between two rotations in SO3 over the geodesic sphere.
%
% Example:
%     subtom_matrix_to_quaterion([1, 0, 0; 0, 1, 0; 0, 0, 1]);
%
% See also SUBTOM_ZXZ_TO_MATRIX SUBTOM_MATRIX_TO_ZXZ

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    try
        validateattributes(rotation_matrix, {'numeric'}, ...
            {'square', 'numel', 9, '>=', -2, '<=', 2}, ...
            'subtom_matrix_to_quaternion', 'rotation_matrix');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    quaternion(1) = sqrt(trace(rotation_matrix) + 1) / 2;

    if imag(quaternion(1)) > 0
        quaternion(1) = 0;
    end

    quaternion(2) = sqrt(1 + rotation_matrix(1, 1) ...
                           - rotation_matrix(2, 2) ...
                           - rotation_matrix(3, 3)) / 2;

    quaternion(3) = sqrt(1 + rotation_matrix(2, 2) ...
                           - rotation_matrix(1, 1) ...
                           - rotation_matrix(3, 3)) / 2;

    quaternion(4) = sqrt(1 + rotation_matrix(3, 3) ...
                           - rotation_matrix(1, 1) ...
                           - rotation_matrix(2, 2)) / 2;

    [~, max_quat_idx] = max(quaternion);

    if max_quat_idx == 1
        quaternion(2) = (rotation_matrix(3, 2) - rotation_matrix(2, 3)) / ...
            (4 * quaternion(1));

        quaternion(3) = (rotation_matrix(1, 3) - rotation_matrix(3, 1)) / ...
            (4 * quaternion(1));

        quaternion(4) = (rotation_matrix(2, 1) - rotation_matrix(1, 2)) / ...
            (4 * quaternion(1));

    elseif max_quat_idx == 2
        quaternion(1) = (rotation_matrix(3, 2) - rotation_matrix(2, 3)) / ...
            (4 * quaternion(2));

        quaternion(3) = (rotation_matrix(1, 2) + rotation_matrix(2, 1)) / ...
            (4 * quaternion(2));

        quaternion(4) = (rotation_matrix(3, 1) + rotation_matrix(1, 3)) / ...
            (4 * quaternion(2));

    elseif max_quat_idx == 3
        quaternion(1) = (rotation_matrix(1, 3) - rotation_matrix(3, 1)) / ...
            (4 * quaternion(3));

        quaternion(2) = (rotation_matrix(1, 2) + rotation_matrix(2, 1)) / ...
            (4 * quaternion(3));

        quaternion(4) = (rotation_matrix(2, 3) + rotation_matrix(3, 2)) / ...
            (4 * quaternion(3));

    else
        quaternion(1) = (rotation_matrix(2, 1) - rotation_matrix(1, 2)) / ...
            (4 * quaternion(4));

        quaternion(2) = (rotation_matrix(3, 1) + rotation_matrix(1, 3)) / ...
            (4 * quaternion(4));

        quaternion(3) = (rotation_matrix(2, 3) + rotation_matrix(3, 2)) / ...
            (4 * quaternion(4));

    end
end
