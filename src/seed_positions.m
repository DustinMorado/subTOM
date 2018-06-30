function seed_positions(input_motl_fn_prefix, output_motl_fn, spacing, ...
    do_tubule)
% SEED_POSITIONS place particle positions with alignment to clicker motive list.
%     SEED_POSITIONS(
%         INPUT_MOTL_FN_PREFIX,
%         OUTPUT_MOTL_FN,
%         SPACING,
%         DO_TUBULE)
%
%     Takes in clicker motive lists from the 'Pick Particle' plugin for Chimera
%     with a name in the format INPUT_MOTL_FN_PREFIX_#.em, where # should
%     correspond to the tomogram number the clicker corresponds to. This number
%     will be used to fill in the 5th and 7th field in the output motive list
%     OUTPUT_MOTL_FN.
%
%     Points are added with roughly a pixel distance SPACING apart. These points
%     are also set with Euler angles that place them normal to the surface of
%     the sphere or tube on which they lie. Points take the form of a tube is
%     DO_TUBULE evaluates to true as a boolean otherwise the clickers are
%     assumed to correspond to spheres. In the case of both the radius is
%     encoded in the 3rd field of the clicker motive and carried over to the
%     output motive list. The second field corresponds to the marker set the
%     clicker file was created from, which is not used in placing spheres but is
%     considered in seeding tubules to delineate between multiple tubules in
%     each tomogram. Finally a running index of tube or sphere is added to the
%     6th field of the output motive list.
%
% Example:
%     SEED_POSITIONS('../startset/clicker', 'combinedmotl/allmotl_1.em', 8, 1);

%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
%input_motl_fn_prefix = '../startset/clicker';
%output_motl_fn = 'combinedmotl/allmotl_1.em';
%spacing = 8;
%do_tubule = 0;
%##############################################################################%
    % Evaluate numeric input
    if ischar(spacing)
        spacing = str2double(spacing);
    end

    if ischar(do_tubule)
        do_tubule = str2double(do_tubule);
    end
    do_tubule = logical(do_tubule);

    allmotl = [];
    object_idx = 1;

    for clicker = dir(sprintf('%s_*.em', input_motl_fn_prefix))'
        motl_fn = fullfile(clicker.folder, clicker.name);
        motl = getfield(tom_emread(motl_fn), 'Value');
        tomo_idx = regexp(motl_fn, '(\d+)\.em$', 'tokens');
        tomo_idx = str2double(tomo_idx{1});
        motl(5, :) = tomo_idx;
        motl(7, :) = tomo_idx;
        motl(20, :) = 1;

        if do_tubule
            for tube_idx = unique(motl(2, :))
                tube_motl = motl(:, motl(2, :) == tube_idx);
                tube_motl(6, :) = object_idx;
                seed_motl = seed_tube(tube_motl, spacing);
                allmotl = [allmotl, seed_motl];
                object_idx = object_idx + 1;
            end
        else
            for sphere_idx = 1:size(motl, 2)
                sphere_motl = motl(:, sphere_idx);
                sphere_motl(6, 1) = object_idx;
                seed_motl = seed_sphere(sphere_motl, spacing);
                allmotl = [allmotl, seed_motl];
                object_idx = object_idx + 1;
            end
        end
    end

    tom_emwrite(output_motl_fn, allmotl);
    check_em_file(output_motl_fn, allmotl);
end % END of lmb_seed_positions

%##############################################################################%
%                                  SEED_TUBE                                   %
%##############################################################################%
function seed_motl = seed_tube(tube_motl, spacing)
% SEED_TUBE places oriented vectors on tube with a set spacing.
%     SEED_TUBE(
%         TUBE_MOTL,
%         SPACING)
%
%     Places vectors oriented normal to a tube described by the motive list
%     TUBE_MOTL, roughly separated by SPACING pixels. TUBE_MOTL is assumed to
%     only contain the points of a single tube.
%
% Example:
%     SEED_TUBE(motl(:, motl(2, :) == 1), 8);

% DRM 06-2018
    seed_motl = [];
    n_points = size(tube_motl, 2);
    tube_radius = tube_motl(3, 1);
    tube_angle_step = 2 * pi / round(2 * pi * tube_radius / spacing);
    %tube_angle_step = 2 * atan2(spacing / 2, tube_radius);
    tube_angles = [tube_angle_step:tube_angle_step:2 * pi];
    tube_spline = spline(1:n_points,tube_motl(8:10, :));

    total_steps = 0;
    for pt_idx = 2:n_points
        step_size = 1 / round(sqrt(sum((tube_motl(8:10, pt_idx) - ...
            tube_motl(8:10, pt_idx - 1)).^2)));

        step_array = [pt_idx - 1:step_size:pt_idx];
        tube_points(:, total_steps + 1:total_steps + size(step_array, 2)) = ...
            ppval(tube_spline, step_array);

        total_steps = total_steps + size(step_array, 2);
    end

    pt_idx = 1;
    while pt_idx < size(tube_points, 2)
        dist = sqrt(sum((tube_points(1:3, pt_idx + 1) - ...
            tube_points(1:3, pt_idx)).^2));

        if dist < spacing
            tube_points(:, pt_idx + 1) = [];
        else
            pt_idx = pt_idx + 1;
        end
    end

    for pt_idx = 2:size(tube_points, 2)
        diff = tube_points(1:3, pt_idx) - tube_points(1:3, pt_idx - 1);
        [azimuth, zenith, radius] = cart2sph(diff(1), diff(2), diff(3));

        pt_origin = tube_points(1:3, pt_idx);
        for tube_angle = tube_angles
            % Start with a point on X-axis and on the tube
            pt =   [cos(azimuth) -sin(azimuth) 0; ...
                    sin(azimuth)  cos(azimuth) 0; ...
                    0           0          1] ...
                 * ...
                   [ cos(-zenith - (pi / 2)) 0 sin(-zenith - (pi / 2)); ...
                     0                       1 0; ...
                    -sin(-zenith - (pi / 2)) 0 cos(-zenith - (pi / 2))] ...
                 * ...
                   [cos(tube_angle) -sin(tube_angle) 0; ...
                    sin(tube_angle)  cos(tube_angle) 0; ...
                    0             0            1] ...
                 * [tube_radius; 0; 0];

            pt_azimuth = 90 + atan2d(pt(2), pt(1));
            pt_zenith = atan2d(sqrt(pt(1)^2 + pt(2)^2), pt(3));
            rot_diff = tom_pointrotate(diff', -pt_azimuth, 0, -pt_zenith);
            pt_spin = atan2d(rot_diff(2), rot_diff(1));
            pt_motl = tube_motl(:, 1);
            pt_motl(8:10, 1) = round(pt + pt_origin);
            pt_motl(17, 1) = pt_spin;
            pt_motl(18, 1) = pt_azimuth;
            pt_motl(19, 1) = pt_zenith;
            seed_motl = [seed_motl, pt_motl];
        end
    end
end % END of seed_tube

function seed_motl = seed_sphere(sphere_motl, spacing)
%##############################################################################%
%                                 SEED_SPHERE                                  %
%##############################################################################%
% SEED_SPHERE places oriented vectors on a sphere with a set spacing.
%     SEED_SPHERE(
%         SPHERE_MOTL,
%         SPACING)
%
%     Places vectors oriented normal to a sphere described by the motive list
%     SPHERE_MOTL, roughly separated by SPACING pixels. SPHERE_MOTL is assumed
%     to only contain the point of a single sphere.
%
% Example:
%     SEED_TUBE(motl(:, 1), 8);

% DRM 06-2018
    seed_motl = [];
    sphere_radius = sphere_motl(3, 1);
    zenith_step = pi / round(pi * sphere_radius / spacing);
    for zenith = [zenith_step:zenith_step:pi - zenith_step]
        azimuth_step = 2 * pi / ...
            round(2 * pi * sphere_radius * sin(zenith) / spacing);

        for azimuth = [azimuth_step:azimuth_step:2 * pi]
            [pt_x, pt_y, pt_z] = sph2cart(azimuth, pi / 2 - zenith, ...
                sphere_radius);

            pt = [pt_x; pt_y; pt_z];
            pt_azimuth = 90 + atan2d(pt(2), pt(1));
            pt_zenith = atan2d(sqrt(pt(1)^2 + pt(2)^2), pt(3));
            pt_spin = randi([-180, 180]);
            pt_motl = sphere_motl(:, 1);
            pt_motl(8:10, 1) = round(pt + pt_motl(8:10, 1));
            pt_motl(17, 1) = pt_spin;
            pt_motl(18, 1) = pt_azimuth;
            pt_motl(19, 1) = pt_zenith;
            seed_motl = [seed_motl, pt_motl];
        end
    end

    [np_x, np_y, np_z] = sph2cart(0, pi / 2, sphere_radius);
    [sp_x, sp_y, sp_z] = sph2cart(0, -pi / 2, sphere_radius);
    np = [np_x; np_y; np_z];
    sp = [sp_x; sp_y; sp_z];
    np_azimuth = 90 + atan2d(np(2), np(1));
    sp_azimuth = 90 + atan2d(sp(2), sp(1));
    np_zenith = atan2d(sqrt(np(1)^2 + np(2)^2), np(3));
    sp_zenith = atan2d(sqrt(sp(1)^2 + sp(2)^2), sp(3));
    np_spin = randi([-180, 180]);
    sp_spin = randi([-180, 180]);
    np_motl = sphere_motl(:, 1);
    sp_motl = sphere_motl(:, 1);
    np_motl(8:10, 1) = round(np + np_motl(8:10, 1));
    sp_motl(8:10, 1) = round(sp + sp_motl(8:10, 1));
    np_motl(17, 1) = np_spin;
    sp_motl(17, 1) = sp_spin;
    np_motl(18, 1) = np_azimuth;
    sp_motl(18, 1) = sp_azimuth;
    np_motl(19, 1) = np_zenith;
    sp_motl(19, 1) = sp_zenith;
    seed_motl = [seed_motl, np_motl];
    seed_motl = [seed_motl, sp_motl];
end % END of seed_sphere

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
    while true
        try
            % If this fails, catch command is run
            tom_emread(em_fn);
            break;
        catch ME
            fprintf('******\nWARNING:\n\t%s\n******', ME.message);
            tom_emwrite(em_fn, em_data)
        end
    end
end
