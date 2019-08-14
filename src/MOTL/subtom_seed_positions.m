function subtom_seed_positions(varargin)
% SUBTOM_SEED_POSITIONS place particle positions from clicker motive list.
%
%     SUBTOM_SEED_POSITIONS(
%         'input_motl_fn_prefix', INPUT_MOTL_FN_PREFIX,
%         'output_motl_fn', OUTPUT_MOTL_FN,
%         'spacing', SPACING,
%         'do_tubule', DO_TUBULE,
%         'rand_inplane', RAND_INPLANE)
%
%     Takes in clicker motive lists from the 'Pick Particle' plugin for Chimera
%     with a name in the format INPUT_MOTL_FN_PREFIX_#.em, where # should
%     correspond to the tomogram number the clicker corresponds to. This number
%     will be used to fill in the 7th field in the output motive list
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
%     6th field of the output motive list. If both DO_TUBULE and RAND_INPLANE
%     evaluate to true as a boolean, then the final Euler angle (phi in AV3
%     notation, and psi/spin/inplane in other notations) will be randomized as
%     opposed to directed along the tubular axis.

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'input_motl_fn_prefix', '../startset/clicker');
    addParameter(fn_parser, 'output_motl_fn', 'combinedmotl/allmotl_1.em');
    addParameter(fn_parser, 'spacing', '8');
    addParameter(fn_parser, 'do_tubule', '0');
    addParameter(fn_parser, 'rand_inplane', '0');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    input_motl_fn_prefix = fn_parser.Results.input_motl_fn_prefix;

    if isempty(input_motl_fn_prefix)
        try
            error('subTOM:missingRequired', ...
                'seed_positions:Parameter %s is required.', ...
                'input_motl_fn_prefix');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    input_motl_fn_list = dir(sprintf('%s_*.em', input_motl_fn_prefix))';

    if isempty(input_motl_fn_list)
        try
            error('subTOM:missingFileError', ...
                'seed_positions:Files %s_*.em do not exist.', ...
                input_motl_fn_prefix);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    output_motl_fn = fn_parser.Results.output_motl_fn;

    if isempty(output_motl_fn)
        try
            error('subTOM:missingRequired', ...
                'seed_positions:Parameter %s is required.', ...
                'output_motl_fn');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    fid = fopen(output_motl_fn, 'w');

    if fid == -1
        try
            error('subTOM:writeFileError', ...
                'seed_positions:File %s cannot be opened for writing', ...
                output_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    fclose(fid);

    spacing = fn_parser.Results.spacing;

    if ischar(spacing)
        spacing = str2double(spacing);
    end

    try
        validateattributes(spacing, {'numeric'}, ...
            {'scalar', 'nonnan', 'positive'}, ...
            'subtom_seed_positions', 'spacing');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    do_tubule = fn_parser.Results.do_tubule;

    if ischar(do_tubule)
        do_tubule = str2double(do_tubule);
    end

    try
        validateattributes(do_tubule, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_seed_positions', 'do_tubule');

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
            'subtom_seed_positions', 'rand_inplane');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Initialize the all motive list.
    all_motl = [];

    % Initialize a counter to keep track of individual spheres or tubules.
    object_idx = 1;

    % MATLAB's dir command doesn't do sorting so we need to sort the clicker
    % motive list names by their tomogram file number, and then use this sorted
    % list to generate a running number of tomograms, which used to be used for
    % old wedgelist calculations, but could be useful in other contexts in the
    % future.

    % Get the number of clicker files, which should correspond to the number of
    % tomograms.
    num_tomo = length(input_motl_fn_list);

    % Initialize an array of input motive list filenames.
    input_motl_fns = cell(1, num_tomo);

    % Initialize an array of numbers corresponding to tomogram names
    %(motive list row 7).
    tomo_nums = zeros(1, num_tomo);

    % Loop over the list of input clicker motive lists.
    for list_idx = 1:num_tomo

        % Get the filename from the structure returned from MATLAB's dir.
        input_motl_fns{list_idx} = fullfile(...
            input_motl_fn_list(list_idx).folder, ...
            input_motl_fn_list(list_idx).name);

        % The clicker file has to have a specific name, e.g. clicker_01.em where
        % the 01 is the tomogram that the clicker corresponds to. This number is
        % then placed into both rows 5 and 7 of the output motive list.
        tomo_num = regexp(input_motl_fns{list_idx}, '(\d+)\.em$', 'tokens');

        % Make sure that we found a number
        if isempty(tomo_num)
            try
                error('subTOM:clickerError', ...
                    'seed_positions:Cannot find tomogram number in %s.', ...
                    input_motl_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        tomo_nums(list_idx) = str2double(tomo_num{1});
    end

    % Sort the tomogram numbers and adjust the file name list accordingly
    [tomo_nums, sort_idxs] = sort(tomo_nums);
    input_motl_fns = input_motl_fns(sort_idxs);

    % Loop over the input clicker motive lists and do the actual seeding.
    for tomo_idx = 1:num_tomo
        input_motl = getfield(tom_emread(input_motl_fns{tomo_idx}), 'Value');

        if size(input_motl, 1) ~= 20
            try
                error('subTOM:MOTLError', ...
                    'seed_positions:%s is not proper MOTL.', input_motl_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        % Set the running tomogram index field.
        input_motl(5, :) = tomo_idx;

        % Set the tomogram name number field.
        input_motl(7, :) = tomo_nums(tomo_idx);

        % Initialize the class field.
        input_motl(20, :) = 0;

        if do_tubule

            % Loop over each tubule in the clicker motive list.
            for tube_idx = unique(input_motl(2, :))

                % Get all of the points for the current tubule.
                tube_motl = input_motl(:, input_motl(2, :) == tube_idx);

                % Set the running object index field (motive list row 6).
                tube_motl(6, :) = object_idx;

                % Do the actual seeding.
                seed_motl = subtom_seed_tube(tube_motl, spacing);

                % Randomize phi if requested.
                if rand_inplane
                    num_seeds = size(seed_motl, 2);
                    seed_motl(17, :) = rand([1, num_seeds]) .* 360.0 - 180.0;
                end

                % Add the seeded positions to the all motive list.
                all_motl = [all_motl, seed_motl];

                % Increment the object index.
                object_idx = object_idx + 1;
            end
        else

            % Loop over each sphere in the clicker motive list.
            for sphere_idx = 1:size(input_motl, 2)

                % Get the point for the current sphere.
                sphere_motl = input_motl(:, sphere_idx);

                % Set the running object index field (motive list row 6).
                sphere_motl(6, 1) = object_idx;

                % Do the actual seeding.
                seed_motl = subtom_seed_sphere(sphere_motl, spacing);

                % Add the seeded positions to the all motive list.
                all_motl = [all_motl, seed_motl];

                % Increment the object index.
                object_idx = object_idx + 1;
            end
        end
    end

    % Set the running particle index field (motive list row 4).
    all_motl(4, :) = 1:size(all_motl, 2);

    % Write out the all motive list.
    tom_emwrite(output_motl_fn, all_motl);
    subtom_check_em_file(output_motl_fn, all_motl);
end

%##############################################################################%
%                               SUBTOM_SEED_TUBE                               %
%##############################################################################%
function seed_motl = subtom_seed_tube(tube_motl, spacing)
% SUBTOM_SEED_TUBE places oriented vectors on tube with a set spacing.
%
%     SUBTOM_SEED_TUBE(
%         TUBE_MOTL,
%         SPACING)
%
%     Places vectors oriented normal to a tube described by the motive list
%     TUBE_MOTL, roughly separated by SPACING pixels. TUBE_MOTL is assumed to
%     only contain the points of a single tube.

% DRM 05-2019
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
        [azimuth, elevation, radius] = cart2sph(diff(1), diff(2), diff(3));
        pt_origin = tube_points(1:3, pt_idx);

        for tube_angle = tube_angles
            zenith = -elevation - (pi / 2);

            % Start with a point on X-axis and on the tube
            pt =   [ cos(azimuth),    -sin(azimuth),    0; ...
                     sin(azimuth),     cos(azimuth),    0; ...
                     0,                0,               1] ...
                 * [ cos(zenith),      0,     sin(zenith); ...
                     0,                1,               0; ...
                    -sin(zenith),      0,     cos(zenith)] ...
                 * [ cos(tube_angle), -sin(tube_angle), 0; ...
                     sin(tube_angle),  cos(tube_angle), 0; ...
                     0,                0,               1] ...
                 * [tube_radius;       0;               0];

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
end

%##############################################################################%
%                              SUBTOM_SEED_SPHERE                              %
%##############################################################################%
function seed_motl = subtom_seed_sphere(sphere_motl, spacing)
% SUBTOM_SEED_SPHERE places oriented vectors on a sphere with a set spacing.
%
%     SUBTOM_SEED_SPHERE(
%         SPHERE_MOTL,
%         SPACING)
%
%     Places vectors oriented normal to a sphere described by the motive list
%     SPHERE_MOTL, roughly separated by SPACING pixels. SPHERE_MOTL is assumed
%     to only contain the point of a single sphere.

% DRM 05-2019
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
end
