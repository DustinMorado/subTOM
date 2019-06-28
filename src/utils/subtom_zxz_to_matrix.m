function rotation_matrix = subtom_zxz_to_matrix(zxz_euler, varargin)
% SUBTOM_ZXZ_TO_MATRIX Converts ZXZ Euler angles to a rotation matrix.
%     SUBTOM_ZXZ_TO_MATRIX(
%         ZXZ_EULER,
%         ANGLE_FMT)
%
%     Calculates the equivalent rotation matrix given a set of ZXZ Euler angles
%     in the AV3 format [phi, psi, theta]. Where phi is the inplane angle about
%     the Z-axis and corresponds to the rightmost Z in ZXZ; where psi is the
%     azimuthal angle about the Z-axis and corresponds to the leftmost Z in ZXZ;
%     where theta is the zenith angle about the X-axis and corresponds to the
%     middle X in ZXZ. 
%
% Example:
%     subtom_zxz_to_matrix([135, 35, 45]);

%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addRequired(fn_parser, 'zxz_euler');
    addParameter(fn_parser, 'angle_fmt', 'degrees');
    parse(fn_parser, zxz_euler, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    zxz_euler_ = fn_parser.Results.zxz_euler;

    try
        validateattributes(zxz_euler_, {'numeric'}, ...
            {'vector', 'numel', 3, 'nonnan', 'finite'}, ...
            'subtom_zxz_to_matrix', 'zxz_euler');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    angle_fmt = fn_parser.Results.angle_fmt;

    if ~strcmp(angle_fmt, 'degrees') && ~strcmp(angle_fmt, 'radians')
        try
            error('subTOM:argumentError', ...
                'zxz_to_matrix:angle_fmt: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    degrees_fmt = strcmp(angle_fmt, 'degrees');

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    if degrees_fmt
        cos_phi = cosd(zxz_euler_(1));
        sin_phi = sind(zxz_euler_(1));

        cos_psi = cosd(zxz_euler_(2));
        sin_psi = sind(zxz_euler_(2));

        cos_theta = cosd(zxz_euler_(3));
        sin_theta = sind(zxz_euler_(3));
    else
        cos_phi = cos(zxz_euler_(1));
        sin_phi = sin(zxz_euler_(1));

        cos_psi = cos(zxz_euler_(2));
        sin_psi = sin(zxz_euler_(2));

        cos_theta = cos(zxz_euler_(3));
        sin_theta = sin(zxz_euler_(3));
    end

    rotation_matrix(1, 1) =  cos_phi * cos_psi - sin_phi * cos_theta * sin_psi;
    rotation_matrix(1, 2) = -sin_phi * cos_psi - cos_phi * cos_theta * sin_psi;
    rotation_matrix(1, 3) =  sin_theta * sin_psi;
    rotation_matrix(2, 1) =  cos_phi * sin_psi + sin_phi * cos_theta * cos_psi;
    rotation_matrix(2, 2) =  cos_phi * cos_theta * cos_psi - sin_phi * sin_psi;
    rotation_matrix(2, 3) = -sin_theta * cos_psi;
    rotation_matrix(3, 1) =  sin_phi * sin_theta;
    rotation_matrix(3, 2) =  cos_phi * sin_theta;
    rotation_matrix(3, 3) =  cos_theta;
end
