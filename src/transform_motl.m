function transform_motl(input_motl_fn, output_motl_fn, shift_x, shift_y, ...
    shift_z, rotate_phi, rotate_psi, rotate_theta)
% TRANSFORM_MOTL apply a rotation and shift to a MOTL file.
%     TRANSFORM_MOTL(
%         INPUT_MOTL_FN,
%         OUTPUT_MOTL_FN,
%         SHIFT_X,
%         SHIFT_Y,
%         SHIFT_Z,
%         ROTATE_PHI,
%         ROTATE_PSI,
%         ROTATE_THETA)
%
%     Takes the motl given by INPUT_MOTL_FN, and first applies the rotation
%     described by the Euler angles ROTATE_PHI, ROTATE_PSI, ROTATE_THETA, which
%     correspond to an in-plane spin, azimuthal, and zenithal rotation
%     respectively. Then a translation specified by SHIFT_X, SHIFT_Y, SHIFT_Z,
%     is applied to the existing translation. Finally the resulting transformed
%     motive list is written out as OUTPUT_MOTL_FN. Keep in mind that the motive
%     list transforms describe the alignment of the reference to each particle,
%     but that the rotation and shift here describe an affine transform of the
%     reference to a new reference.
%
% Example:
%     TRANSFORM_MOTL('combinedmotl/allmotl_1.em', ...
%         'combinedmotl/allmotl_1_shifted.em, 5, 5, -3, 60, 15, 0.5);

% DRM 08-2018
%
% Explanation of how the transforms are derived:
%     The alignments in the motive list describe the rotation and shift of the
%     reference to each particle. Since this is a rotation followed by a shift
%     we can describe this as an affine transform 4x4 matrix as follows:
%
%     [ R_1   T_1 ]   [ V ]   [ P ]
%     [           ] x [   ] = [   ]                        (1)
%     [  0     1  ]   [ 1 ]   [ 1 ]
%
%     Where R_1 is the rotation matrix described by motl(17:19, 1) and T_1 is
%     the shift column vector described by motl(11:13, 1), and finally V and P
%     are the coordinates in the reference, and the reference in register with
%     the particle respectively.
%
%     Likewise the rotation and shift we apply to the reference to get a new
%     updated reference is also an affine transform as follows:
%
%     [ R_2   T_2 ]   [ V ]   [  V' ]
%     [           ] x [   ] = [     ]                      (2)
%     [  0     1  ]   [ 1 ]   [  1  ]
%
%     Where V' is our new reference. Therefore the affine transform we want to
%     find and place in our updates motive list is:
%
%     [ R_?   T_? ]   [  V' ]   [ P ]
%     [           ] x [     ] = [   ]                      (3)
%     [  0     1  ]   [  1  ]   [ 1 ]
%
%     The most logical path is to go from V' to V and V to P, so we have to
%     invert the affine transform in (2), and then left multiply it by the
%     transform in (1). To find the inverse affine transform of (2) we have
%     that:
%
%     R_2 * V + T_2 = V'
%     R_2 * V = V' - T_2
%     V = R_2^-1 * (V' - T_2)
%     V = (R_2^-1 * V') - (R_2^-1 * T_2)
%
%     [ R_2^-1   -R_2^-1 * T_2 ]   [  V' ]   [ V ]
%     [                        ] x [     ] = [   ]         (4)
%     [    0             1     ]   [  1  ]   [ 1 ]
%
%     So we have that:
%
%     [ R_1  T_1 ]   [ R_2^-1   -R_2^-1 * T_2 ]   [  V' ]   [ P ]
%     [          ] x [                        ] x [     ] = [   ]         (5)
%     [  0    1  ]   [    0             1     ]   [  1  ]   [ 1 ]
%
%     [ R_1 * R_2^-1  -R_1 * R_2^-1 * T_2 + T_1 ]   [  V' ] = [ P ]
%     [                                         ] x [     ] = [   ]       (6)
%     [     0                       1           ]   [  1  ] = [ 1 ]
%
%     And finally:
%
%     R_? = R_1 * R_2^-1
%     T_? = T_1 - R_1 * R_2^-1 * T_2
%
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% input_motl_fn = 'input_motl.em';
% output_motl_fn = 'output_motl.em';
% shift_x = 0;
% shift_y = 0;
% shift_z = 0;
% rotate_phi = 0;
% rotate_psi = 0;
% rotate_theta = 0;
%##############################################################################%
    % Evaluate numeric input
    if ischar(shift_x)
        shift_x = str2double(shift_x);
    end

    if ischar(shift_y)
        shift_y = str2double(shift_y);
    end

    if ischar(shift_z)
        shift_z = str2double(shift_z);
    end

    if ischar(rotate_phi)
        rotate_phi = str2double(rotate_phi);
    end

    if ischar(rotate_psi)
        rotate_psi = str2double(rotate_psi);
    end

    if ischar(rotate_theta)
        rotate_theta = str2double(rotate_theta);
    end

    input_motl = getfield(tom_emread(input_motl_fn), 'Value');
    output_motl = input_motl;

    % Calculate the requested rotation matrix - R_2
    applied_rotation_matrix = euler_to_matrix(...
        [rotate_phi, rotate_psi, rotate_theta]);

    % We care about in the end the rotation that takes our new reference to the
    % particle so we need to invert the requested rotation. Recall that the
    % inverse of a rotation matrix is its transpose since rotation matrices are
    % belong to SO(3), which means they are orthogonal, the inverse is just the
    % transpose of the matrix.
    applied_rotation_matrix = transpose(applied_rotation_matrix);

    for motl_idx = 1:size(input_motl, 2)
        % Get the initial rotation matrix - R_1
        old_rotation_matrix = euler_to_matrix(input_motl(17:19, motl_idx));

        % R_? = R_1 * R_2^-1
        new_rotation_matrix = old_rotation_matrix * applied_rotation_matrix;

        % Get the shift column vectors T_1 and T_2
        old_shift_vector = output_motl(11:13, motl_idx);
        applied_shift_vector = [shift_x; shift_y; shift_z];

        % T_? = T_1 - R_1 * R_2^-1 * T_2
        new_shift_vector = old_shift_vector - new_rotation_matrix * ...
            applied_shift_vector;

        % Finally we update the alignment in the new motive list
        output_motl(11:13, motl_idx) = new_shift_vector;
        output_motl(17:19, motl_idx) = matrix_to_euler(new_rotation_matrix);
    end

    tom_emwrite(output_motl_fn, output_motl);
    check_em_file(output_motl_fn, output_motl);
end

%##############################################################################%
%                               EULER_TO_MATRIX                                %
%##############################################################################%
function rotation_matrix = euler_to_matrix(input_euler)
% EULER_TO_MATRIX converts an AV3 ZXZ Euler triplet to a rotation matrix.
%     EULER_TO_MATRIX(
%         INPUT_EULER)
%
%     A function to take the Euler angles directly from fields 17-19, which are
%     of the form psi, phi, theta that correspond to an azimuthal rotation about
%     the initial Z-axis, an in-plane spin rotation about the final Z-axis, and
%     a zenithal rotation about the intermediary X-axis, respectively, and
%     returns the corresponding rotation matrix of the given rotation transform.
%
% Example:
%     EULER_TO_MATRIX(input_motl(17:19, 1));

% DRM 07-2018
    cos_azimuth = cosd(input_euler(1));
    cos_zenith = cosd(input_euler(3));
    cos_spin = cosd(input_euler(2));
    sin_azimuth = sind(input_euler(1));
    sin_zenith = sind(input_euler(3));
    sin_spin = sind(input_euler(2));

    rotation_matrix(1, 1) =   cos_azimuth * cos_spin ...
                            - sin_azimuth * cos_zenith * sin_spin;

    rotation_matrix(1, 2) =  -sin_azimuth * cos_spin ...
                            - cos_azimuth * cos_zenith * sin_spin;

    rotation_matrix(1, 3) =  sin_zenith * sin_spin;
    rotation_matrix(2, 1) =   cos_azimuth * sin_spin ...
                            + sin_azimuth * cos_zenith * cos_spin;

    rotation_matrix(2, 2) =   cos_azimuth * cos_zenith * cos_spin ...
                            - sin_azimuth * sin_spin;

    rotation_matrix(2, 3) = -sin_zenith * cos_spin;
    rotation_matrix(3, 1) =  sin_azimuth * sin_zenith;
    rotation_matrix(3, 2) =  cos_azimuth * sin_zenith;
    rotation_matrix(3, 3) =  cos_zenith;
end

%##############################################################################%
%                               MATRIX_TO_EULER                                %
%##############################################################################%
function euler_angles = matrix_to_euler(rotation_matrix)
% MATRIX_TO_EULER converts a rotation matrix to an AV3 ZXZ Euler triplet.
%     MATRIX_TO_EULER(
%         ROTATION_MATRIX)
%
%     A function to take a rotation matrix and convert them into the Euler
%     angles directly corresponding to motive list fields 17-19, which are of
%     the form psi, phi, theta that correspond to an azimuthal rotation, an
%     in-plane spin rotation, and a zenithal rotation about the axes ZXZ
%     respectively.
%
% Example:
%     MATRIX_TO_EULER([1 0 0; 0 1 0; 0 0 1]);

% DRM 07-2018
    epsilon = 0.0000005;
    if abs(rotation_matrix(3, 3) - 1) <= epsilon
        azimuth = 0.0;
        zenith = 0.0;
        spin = atan2d(rotation_matrix(2, 1), rotation_matrix(1, 1));
        if abs(spin) < epsilon
            spin = 0.0;
        end
    else
        azimuth = atan2d(rotation_matrix(3, 1), rotation_matrix(3, 2));
        if abs(azimuth) < epsilon
            azimuth = 0.0;
        end

        zenith = acosd(rotation_matrix(3, 3));
        if abs(zenith) < epsilon
            zenith = 0.0;
        end

        spin = atan2d(rotation_matrix(1, 3), -rotation_matrix(2, 3));
        if abs(spin) < epsilon
            spin = 0.0;
        end
    end

    euler_angles = [azimuth, spin, zenith];
end

%##############################################################################%
%                                CHECK_EM_FILE                                 %
%##############################################################################%
function check_em_file(em_fn, em_data)
% CHECK_EM_FILE check that an EM file was correctly written.
%     CHECK_EM_FILE(...
%         EM_FN, ...
%         EM_DATA)
%
%     Tries to verify that the EM-file was correctly written before proceeding,
%     it should always be run following a call to TOM_EMWRITE to make sure that
%     that function call succeeded. If an error is caught here while trying to
%     read the file that was just written, it just tries to write it again.
%
% Example:
%   CHECK_EM_FILE('my_EM_filename.em', my_EM_data);
%
% See also TOM_EMWRITE

% DRM 11-2017
    size_check = numel(em_data) * 4 + 512;
    while true
        listing = dir(em_fn);
        if isempty(listing)
            fprintf('******\nWARNING:\n\tFile %s does not exist!', em_fn);
            tom_emwrite(em_fn, em_data);
        else
            if listing.bytes ~= size_check
                fprintf('******\nWARNING:\n');
                fprintf('\tFile %s is not the correct size!', em_fn);
                tom_emwrite(em_fn, em_data);
            else
                break;
            end
        end
    end
end
