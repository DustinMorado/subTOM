function zxz_euler = subtom_matrix_to_zxz(rotation_matrix, varargin)
% SUBTOM_MATRIX_TO_ZXZ Converts a rotation matrix to ZXZ Euler angles.
%     SUBTOM_MATRIX_TO_MATRIX(
%         ROTATION_MATRIX,
%         ANGLE_FMT)
%
%     Calculates the equivalent ZXZ Euler angles given a 3x3 rotation matrix.
%     The returned set of ZXZ Euler angles are in the AV3 format [phi, psi,
%     theta]. Where phi is the inplane angle about the Z-axis and corresponds to
%     the rightmost Z in ZXZ; where psi is the azimuthal angle about the Z-axis
%     and corresponds to the leftmost Z in ZXZ; where theta is the zenith angle
%     about the X-axis and corresponds to the middle X in ZXZ. 
%     
% Example:
%     subtom_matrix_to_zxz([1, 0, 0; 0, -1, 0; 0, 0, -1]);

%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addRequired(fn_parser, 'rotation_matrix');
    addParameter(fn_parser, 'angle_fmt', 'degrees');
    parse(fn_parser, rotation_matrix, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    rotation_matrix_ = fn_parser.Results.rotation_matrix;

    try
        validateattributes(rotation_matrix_, {'numeric'}, ...
            {'square', 'numel', 9, '>=', -2, '<=', 2}, ...
            'subtom_matrix_to_zxz', 'rotation_matrix');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    angle_fmt = fn_parser.Results.angle_fmt;

    if ~strcmp(angle_fmt, 'degrees') && ~strcmp(angle_fmt, 'radians')
        try
            error('subTOM:argumentError', ...
                'matrix_to_zxz:angle_fmt: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    degrees_fmt = strcmp(angle_fmt, 'degrees');

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Handle the case when theta is 0, and hence the cosine(theta) at 3,3 is 1.
    % In this case the rotation about phi and psi are degenerate and we only
    % need to solve the singular Z-axis rotation which is the sum of phi and
    % psi.
    if abs(rotation_matrix(3, 3) - 1) <= eps

        if degrees_fmt
            zxz_euler(1) = atan2d(rotation_matrix(2, 1), rotation_matrix(1, 1));
        else
            zxz_euler(1) = atan2(rotation_matrix(2, 1), rotation_matrix(1, 1));
        end

        zxz_euler(2) = 0.0;
        zxz_euler(3) = 0.0;

        if abs(zxz_euler(1)) < eps
            zxz_euler(1) = 0.0;
        end

    % Handle when theta is 180, and hence the cosine(theta) at 3,3 is -1.
    % In this case the rotation about phi and psi are again degenerate and we
    % only need to solve the singular Z-axis rotation which is the sum of phi
    % and psi, while also considering that the orientation is facing in the
    % oppsite direction after being rotated 180 degrees about X.
    elseif abs(rotation_matrix(3, 3) + 1) <= eps

        if degrees_fmt
            zxz_euler(1) = -atan2d(rotation_matrix(2, 1), ...
                rotation_matrix(1, 1));

            zxz_euler(2) = 0.0;
            zxz_euler(3) = 180.0;
        else
            zxz_euler(1) = -atan2(rotation_matrix(2, 1), ...
                rotation_matrix(1, 1));

            zxz_euler(2) = 0.0;
            zxz_euler(3) = pi;
        end

        if abs(zxz_euler(1)) < eps
            zxz_euler(1) = 0.0;
        end

    else

        if degrees_fmt
            zxz_euler(1) = atan2d(rotation_matrix(3, 1), ...
                rotation_matrix(3, 2));
        else
            zxz_euler(1) = atan2(rotation_matrix(3, 1), ...
                rotation_matrix(3, 2));
        end

        if abs(zxz_euler(1)) < eps
            zxz_euler(1) = 0.0;
        end

        if degrees_fmt
            zxz_euler(2) = atan2d(rotation_matrix(1, 3), ...
                -rotation_matrix(2, 3));
        else
            zxz_euler(2) = atan2(rotation_matrix(1, 3), ...
                -rotation_matrix(2, 3));
        end

        if abs(zxz_euler(2)) < eps
            zxz_euler(2) = 0.0;
        end

        if degrees_fmt
            zxz_euler(3) = acosd(rotation_matrix(3, 3));
        else
            zxz_euler(3) = acos(rotation_matrix(3, 3));
        end

        if abs(zxz_euler(3)) < eps
            zxz_euler(3) = 0.0;
        end
    end
end
