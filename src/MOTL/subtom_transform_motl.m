function transform_motl(varargin)
% SUBTOM_TRANSFORM_MOTL apply a rotation and shift to a MOTL file.
%
%     SUBTOM_TRANSFORM_MOTL(
%         'input_motl_fn', INPUT_MOTL_FN,
%         'output_motl_fn', OUTPUT_MOTL_FN,
%         'shift_x', SHIFT_X,
%         'shift_y', SHIFT_Y,
%         'shift_z', SHIFT_Z,
%         'rotate_phi', ROTATE_PHI,
%         'rotate_psi', ROTATE_PSI,
%         'rotate_theta', ROTATE_THETA,
%         'rand_inplane', RAND_INPLANE)
%
%     Takes the motl given by INPUT_MOTL_FN, and first applies the rotation
%     described by the Euler angles ROTATE_PHI, ROTATE_PSI, ROTATE_THETA, which
%     correspond to an in-plane spin, azimuthal, and zenithal rotation
%     respectively. Then a translation specified by SHIFT_X, SHIFT_Y, SHIFT_Z,
%     is applied to the existing translation. Finally the resulting transformed
%     motive list is written out as OUTPUT_MOTL_FN. Keep in mind that the motive
%     list transforms describe the alignment of the reference to each particle,
%     but that the rotation and shift here describe an affine transform of the
%     reference to a new reference. If RAND_INPLANE evaluates to true as a
%     boolean, then the final Euler angle (phi in AV3 notation, and
%     psi/spin/inplane in other notations) will be randomized after the given
%     transform.

% DRM 05-2019
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
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'input_motl_fn', '');
    addParameter(fn_parser, 'output_motl_fn', '');
    addParameter(fn_parser, 'shift_x', '0');
    addParameter(fn_parser, 'shift_y', '0');
    addParameter(fn_parser, 'shift_z', '0');
    addParameter(fn_parser, 'rotate_phi', '0');
    addParameter(fn_parser, 'rotate_psi', '0');
    addParameter(fn_parser, 'rotate_theta', '0');
    addParameter(fn_parser, 'rand_inplane', '0');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    input_motl_fn = fn_parser.Results.input_motl_fn;

    if exist(input_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'transform_motl:File %s does not exist.', input_motl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    input_motl = getfield(tom_emread(input_motl_fn), 'Value');

    if size(input_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'transform_motl:%s is not proper MOTL.', input_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    output_motl_fn = fn_parser.Results.output_motl_fn;

    fid = fopen(output_motl_fn, 'w');

    if fid == -1
        try
            error('subTOM:writeFileError', ...
                'transform_motl:File %s cannot be opened for writing', ...
                output_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    fclose(fid);
    
    shift_x = fn_parser.Results.shift_x;

    if ischar(shift_x)
        shift_x = str2double(shift_x);
    end

    try
        validateattributes(shift_x, {'numeric'}, ...
            {'scalar', 'nonnan'}, 'subtom_transform_motl', 'shift_x');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    shift_y = fn_parser.Results.shift_y;

    if ischar(shift_y)
        shift_y = str2double(shift_y);
    end

    try
        validateattributes(shift_y, {'numeric'}, ...
            {'scalar', 'nonnan'}, 'subtom_transform_motl', 'shift_y');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    shift_z = fn_parser.Results.shift_z;

    if ischar(shift_z)
        shift_z = str2double(shift_z);
    end

    try
        validateattributes(shift_z, {'numeric'}, ...
            {'scalar', 'nonnan'}, 'subtom_transform_motl', 'shift_z');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    rotate_phi = fn_parser.Results.rotate_phi;

    if ischar(rotate_phi)
        rotate_phi = str2double(rotate_phi);
    end

    try
        validateattributes(rotate_phi, {'numeric'}, ...
            {'scalar', 'nonnan'}, 'subtom_transform_motl', 'rotate_phi');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    rotate_psi = fn_parser.Results.rotate_psi;

    if ischar(rotate_psi)
        rotate_psi = str2double(rotate_psi);
    end

    try
        validateattributes(rotate_psi, {'numeric'}, ...
            {'scalar', 'nonnan'}, 'subtom_transform_motl', 'rotate_psi');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    rotate_theta = fn_parser.Results.rotate_theta;

    if ischar(rotate_theta)
        rotate_theta = str2double(rotate_theta);
    end

    try
        validateattributes(rotate_theta, {'numeric'}, ...
            {'scalar', 'nonnan'}, 'subtom_transform_motl', 'rotate_theta');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    rand_inplane = fn_parser.Results.rand_inplane;

    if ischar(rand_inplane)
        rand_inplane = str2double(rand_inplane);
    end

    try
        validateattributes(rand_inplane, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_transform_motl', 'rand_inplane');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    output_motl = input_motl;

    % Calculate the requested rotation matrix - R_2
    applied_rotation_matrix = subtom_zxz_to_matrix(...
        [rotate_phi, rotate_psi, rotate_theta]);

    % We care about in the end the rotation that takes our new reference to the
    % particle so we need to invert the requested rotation. Recall that the
    % inverse of a rotation matrix is its transpose since rotation matrices are
    % belong to SO(3), which means they are orthogonal, the inverse is just the
    % transpose of the matrix.
    applied_rotation_matrix = transpose(applied_rotation_matrix);

    for motl_idx = 1:size(input_motl, 2)

        % Get the initial rotation matrix - R_1
        old_rotation_matrix = subtom_zxz_to_matrix(input_motl(17:19, motl_idx));

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
        output_motl(17:19, motl_idx) = subtom_matrix_to_zxz(...
            new_rotation_matrix);

        % Additionaly if requested we randomize the phi rotation.
        if rand_inplane
            num_ptcls = size(output_motl, 2);
            output_motl(17, :) = rand([1, num_ptcls]) .* 360.0 - 180.0;
        end
    end

    tom_emwrite(output_motl_fn, output_motl);
    subtom_check_em_file(output_motl_fn, output_motl);
end
