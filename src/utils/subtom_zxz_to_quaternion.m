function quaternion = subtom_zxz_to_quaternion(zxz_euler, varargin)
% SUBTOM_ZXZ_TO_QUATERNION Converts ZXZ Euler angles to a unit quaternion.
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
%     subtom_zxz_to_quaternion([135, 35, 45]);
%
% See also SUBTOM_ZXZ_TO_MATRIX SUBTOM_MATRIX_TO_QUATERNION

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
            'subtom_zxz_to_quaternion', 'zxz_euler');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    angle_fmt = fn_parser.Results.angle_fmt;

    if ~strcmp(angle_fmt, 'degrees') && ~strcmp(angle_fmt, 'radians')
        try
            error('subTOM:argumentError', ...
                'zxz_to_quaternion:angle_fmt: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    quaternion = subtom_matrix_to_quaternion(...
        subtom_zxz_to_matrix(zxz_euler, 'angle_fmt', angle_fmt));

end
