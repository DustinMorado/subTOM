function subtom_plot_scanned_angles(varargin)
% SUBTOM_PLOT_SCANNED_ANGLES creates a graphic of local search rotations.
%
%     SUBTOM_PLOT_SCANNED_ANGLES(
%         'psi_angle_step', PSI_ANGLE_STEP,
%         'psi_angle_shells', PSI_ANGLE_SHELLS,
%         'phi_angle_step', PHI_ANGLE_STEP,
%         'phi_angle_shells', PHI_ANGLE_SHELLS,
%         'initial_phi', INITIAL_PHI,
%         'initial_psi', INITIAL_PSI,
%         'initial_theta', INITIAL_THETA,
%         'angle_fmt', ANGLE_FMT,
%         'marker_size', MARKER_SIZE,
%         'output_fn_prefix', OUTPUT_FN_PREFIX)
%
%     Takes in the local search parameters used in subTOM PSI_ANGLE_STEP,
%     PSI_ANGLE_SHELLS, PHI_ANGLE_STEP, and PHI_ANGLE_SHELLS; then produces a
%     figure showing the angles that will be searched using an arrow marker. The
%     angles are given in either radians or degrees depending on ANGLE_FMT. The
%     marker represents the X-axis after rotation and placed on the unit sphere.
%     The initial marker position is at the north pole of the unit sphere. The
%     size of the marker is determined by MARKER_SIZE. The rotations can also be
%     displayed centered on an initial rotation given by INITIAL_PHI,
%     INITIAL_PSI, and INITIAL_THETA. If it is non-empty the figure will be
%     written out in MATLAB figure, PDF and PNG format using the filename prefix
%     OUTPUT_FN_PREFIX.

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'psi_angle_step', 0);
    addParameter(fn_parser, 'psi_angle_shells', 0);
    addParameter(fn_parser, 'phi_angle_step', 0);
    addParameter(fn_parser, 'phi_angle_shells', 0);
    addParameter(fn_parser, 'initial_phi', 0);
    addParameter(fn_parser, 'initial_psi', 0);
    addParameter(fn_parser, 'initial_theta', 0);
    addParameter(fn_parser, 'angle_fmt', 'degrees');
    addParameter(fn_parser, 'marker_size', 0.1);
    addParameter(fn_parser, 'output_fn_prefix', '');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    angle_fmt = fn_parser.Results.angle_fmt;

    try
        angle_fmt = validatestring(angle_fmt, [string('degrees'), ...
            string('radians')], 'subtom_plot_scanned_angles', 'angle_fmt');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    psi_angle_step = fn_parser.Results.psi_angle_step;

    if ischar(psi_angle_step)
        psi_angle_step = str2double(psi_angle_step);
    end

    if strcmpi(angle_fmt, 'radians')
        psi_angle_step = rad2deg(psi_angle_step);
    end

    try
        validateattributes(psi_angle_step, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative', '<', 360}, ...
            'subtom_plot_scanned_angles', 'psi_angle_step');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    psi_angle_shells = fn_parser.Results.psi_angle_shells;

    if ischar(psi_angle_shells)
        psi_angle_shells = str2double(psi_angle_shells);
    end

    try
        validateattributes(psi_angle_shells, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative', 'integer'}, ...
            'subtom_plot_scanned_angles', 'psi_angle_shells');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    phi_angle_step = fn_parser.Results.phi_angle_step;

    if ischar(phi_angle_step)
        phi_angle_step = str2double(phi_angle_step);
    end

    if strcmpi(angle_fmt, 'radians')
        phi_angle_step = rad2deg(phi_angle_step);
    end

    try
        validateattributes(phi_angle_step, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative', '<', 360}, ...
            'subtom_plot_scanned_angles', 'phi_angle_step');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    phi_angle_shells = fn_parser.Results.phi_angle_shells;

    if ischar(phi_angle_shells)
        phi_angle_shells = str2double(phi_angle_shells);
    end

    try
        validateattributes(phi_angle_shells, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative', 'integer'}, ...
            'subtom_plot_scanned_angles', 'phi_angle_shells');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    initial_phi = fn_parser.Results.initial_phi;

    if ischar(initial_phi)
        initial_phi = str2double(initial_phi);
    end

    if strcmpi(angle_fmt, 'radians')
        initial_phi = rad2deg(initial_phi);
    end

    try
        validateattributes(initial_phi, {'numeric'}, ...
            {'scalar', 'nonnan'}, ...
            'subtom_plot_scanned_angles', 'initial_phi');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    initial_psi = fn_parser.Results.initial_psi;

    if ischar(initial_psi)
        initial_psi = str2double(initial_psi);
    end

    if strcmpi(angle_fmt, 'radians')
        initial_psi = rad2deg(initial_psi);
    end

    try
        validateattributes(initial_psi, {'numeric'}, ...
            {'scalar', 'nonnan'}, ...
            'subtom_plot_scanned_angles', 'initial_psi');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    initial_theta = fn_parser.Results.initial_theta;

    if ischar(initial_theta)
        initial_theta = str2double(initial_theta);
    end

    if strcmpi(angle_fmt, 'radians')
        initial_theta = rad2deg(initial_theta);
    end

    try
        validateattributes(initial_theta, {'numeric'}, ...
            {'scalar', 'nonnan'}, ...
            'subtom_plot_scanned_angles', 'initial_theta');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    marker_size = fn_parser.Results.marker_size;

    if ischar(marker_size)
        marker_size = str2double(marker_size);
    end

    try
        validateattributes(marker_size, {'numeric'}, ...
            {'scalar', 'nonnan', 'positive'}, ...
            'subtom_plot_scanned_angles', 'marker_size');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    output_fn_prefix = fn_parser.Results.output_fn_prefix;

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Create the vectors used to make the marker
    vx1 = [0, 0, 1];
    vx2 = [marker_size, 0, 1];
    vx3 = [marker_size * 3 / 4,  marker_size / 4, 1];
    vx4 = [marker_size * 3 / 4, -marker_size / 4, 1];
    vx5 = [marker_size, 0, 1];

    % Convert the initial Euler angles into a rotation matrix.
    initial_rot_mat = subtom_zxz_to_matrix(...
        [initial_phi, initial_psi, initial_theta], 'angle_fmt', 'degrees');

    % Set the colors for the plot.
    colors = parula(181);

    % Strangely in AV3 the number of shells is half the number given.
    theta_angle_shells = ceil(psi_angle_shells / 2);

    % Create the figure.
    angles_fig = figure();
    angles_axes = axes(angles_fig);
    hold(angles_axes, 'on');

    % Keep track of how many angles we are searching.
    num_angles = 0;

    for phi_idx = -phi_angle_shells:phi_angle_shells
        for theta_idx = 0:theta_angle_shells

            if sind(theta_idx * psi_angle_step) == 0
                psi_delta = 360;
                psi_range = 0;
            else
                psi_delta = psi_angle_step / sind(theta_idx * psi_angle_step);
                psi_range = 0:(ceil(360 / psi_delta) - 1);
                psi_delta = 360 / ceil(360 / psi_delta);
            end

            for psi_idx = psi_range
                psi = psi_idx * psi_delta;
                theta = theta_idx * psi_angle_step;

                % This is to reset any inplane rotation caused by the initial
                % azimuthal rotation.
                phi_deg0 = atan2d(-sind(psi), cosd(psi) * cosd(theta));

                % Now set the correct inplane rotation from search.
                phi = phi_deg0 + phi_idx * phi_angle_step;

                % Determined the rotation matrix for the search rotation
                search_rot_mat = subtom_zxz_to_matrix([phi, psi, theta], ...
                    'angle_fmt', 'degrees');

                rot_mat = initial_rot_mat * search_rot_mat;

                % Convert the rotation matrix back to Euler angles.
                update_euler = subtom_matrix_to_zxz(rot_mat);
                phi = update_euler(1);
                psi = update_euler(2);
                theta = update_euler(3);

                % Normalize the angles
                if theta < 0
                    theta = -theta;
                    psi = psi + 180;
                end

                phi = mod(phi, 360);
                if phi > 180
                    phi = phi - 360;
                end

                psi = mod(psi, 360);
                if psi > 180
                    psi = psi - 360;
                end

                % Rotate the marker points to their new correct positions
                rx1 = tom_pointrotate(vx1, phi, psi, theta);
                rx2 = tom_pointrotate(vx2, phi, psi, theta);
                rx3 = tom_pointrotate(vx3, phi, psi, theta);
                rx4 = tom_pointrotate(vx4, phi, psi, theta);
                rx5 = tom_pointrotate(vx5, phi, psi, theta);

                % Concatenate the points into a patch for plotting
                vertices = vertcat(rx1, rx2, rx3, rx4, rx5);

                % Points are colored by their angular distance from the initial
                % orientation.
                distance = subtom_euler_diff(...
                    [initial_phi, initial_psi, initial_theta], ...
                    [phi, psi, theta]);

                color_idx = round(distance) + 1;
                patch_color = colors(color_idx, :);

                patch(angles_axes, 'Faces', [1, 2, 3, 4, 5], ...
                    'Vertices', vertices, ...
                    'EdgeColor', patch_color, ...
                    'FaceColor', 'none');

                % Increment the number of angles scanned
                num_angles = num_angles + 1;
            end
        end
    end

    % We also plot the unit sphere to aid in visualization.
    [sphere_x, sphere_y, sphere_z] = sphere(20);
    surf(angles_axes, sphere_x, sphere_y, sphere_z, ...
        'EdgeColor', 'none', 'FaceColor', [0.9, 0.9, 0.9]);

    % We set the axes bounds, since most local searches are near the north pole
    % we set the Z-bounds close to the data, which may need to be adjusted in
    % some cases by the user.
    xlim(angles_axes, [-1.1, 1.1]);
    ylim(angles_axes, [-1.1, 1.1]);
    zlim(angles_axes, [ 0.7, 1.1]);
    axis(angles_axes, 'equal');
    caxis(angles_axes, [0, 180]);
    angles_colorbar = colorbar('Location', 'southoutside', 'Ticks', [0:30:180]);
    angles_colorbar.Label.String = 'Angular distance (degrees)';

    if isempty(output_fn_prefix)
        title(angles_axes, sprintf(['Searched angles for:\n', ...
            '\\Delta_\\phi = %.1f, N_\\phi = %d, ', ...
            '\\Delta_\\psi = %.1f, N_\\psi = %d\n ', ...
            'Number of rotations = %d'], ...
            phi_angle_step, phi_angle_shells, psi_angle_step, ...
            psi_angle_shells, num_angles));

    else
        [~, output_fn_base, ~] = fileparts(output_fn_prefix);
        title(angles_axes, sprintf(['Searched angles for %s:\n', ...
            '\\Delta_\\phi = %.1f, N_\\phi = %d, ', ...
            '\\Delta_\\psi = %.1f, N_\\psi = %d\n ', ...
            'Number of rotations = %d'], ...
            output_fn_base, phi_angle_step, phi_angle_shells, ...
            psi_angle_step, psi_angle_shells, num_angles));

    end

    if ~isempty(output_fn_prefix)
        set(angles_fig, 'PaperPositionMode', 'auto');
        set(angles_fig, 'Position', [0, 0, 800, 600]);
        saveas(angles_fig, sprintf('%s_scanned_angles', output_fn_prefix), ...
            'fig');

        saveas(angles_fig, sprintf('%s_scanned_angles', output_fn_prefix), ...
            'pdf');

        saveas(angles_fig, sprintf('%s_scanned_angles', output_fn_prefix), ...
            'png');
    end
end
