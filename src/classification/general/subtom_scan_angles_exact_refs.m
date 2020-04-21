function subtom_scan_angles_exact_refs(varargin)
% SUBTOM_SCAN_ANGLES_EXACT_REFS align particle classes to a single reference.
%
%     SUBTOM_SCAN_ANGLES_EXACT_REFS(
%         'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX,
%         'ref_fn_prefix', REF_FN_PREFIX,
%         'align_mask_fn', ALIGN_MASK_FN,
%         'cc_mask_fn', CC_MASK_FN,
%         'output_motl_fn_prefix', OUTPUT_MOTL_FN_PREFIX,
%         'apply_mask', APPLY_MASK,
%         'ref_class', REF_CLASS,
%         'psi_angle_step', PSI_ANGLE_STEP,
%         'psi_angle_shells', PSI_ANGLE_SHELLS,
%         'phi_angle_step', PHI_ANGLE_STEP,
%         'phi_angle_shells', PHI_ANGLE_SHELLS,
%         'high_pass_fp', HIGH_PASS_FP,
%         'high_pass_sigma', HIGH_PASS_SIGMA,
%         'low_pass_fp', LOW_PASS_FP,
%         'low_pass_sigma', LOW_PASS_SIGMA,
%         'nfold', NFOLD,
%         'iteration', ITERATION)
%
%     Aligns class averages from the collective motive list with the name format
%     ALL_MOTL_FN_PREFIX _#.em where # is the number ITERATION. A motive list
%     for the best determined alignment parameters against the class average
%     specified by REF_CLASS is written out in two motive lists as given by
%     OUTPUT_MOTL_FN_PREFIX. The first with 'classed' keeps the class
%     information to generate new class averages. The second with 'unclassed'
%     discards the class information so a cumulative average can be generated.
%
%     Class averages, with the name format REF_FN_PREFX _class_#_#.em where the
%     first # is the iclass number, and the the second # is ITERATION, are
%     aligned against the reference class average.  Before the comparison is
%     made a number of alterations are made to both the class average and
%     reference:
%
%         - If NFOLD is greater than 1 then C#-symmetry is applied along the
%         Z-axis to the reference where # is NFOLD.
%
%         - The reference is masked in real space with the mask ALIGN_MASK_FN,
%         and if APPLY_MASK evaluates to true as a boolean, then this mask is
%         also applied to the class average. A sphere mask is applied to the
%         particle to reduces the artifacts caused by the box-edges on the
%         comparison. This sphere has a diameter that is 80% the box size and
%         falls of with a sigma that is 15% half the box size.
%
%             - APPLY_MASK can help alignment and suppress alignment to other
%             features when the particle is well-centered or already reasonably
%             well aligned, but if this is not the case there is the risk that a
%             tight alignment will cutoff parts of the particle.
%
%         - Both the particle and the reference are bandpass filtered in the
%         Fourier domain defined by HIGH_PASS_FP, HIGH_PASS_SIGMA, LOW_PASS_FP,
%         and LOW_PASS_SIGMA which are all in the units of Fourier pixels.
%
%     The local rotations searched during alignment are deteremined by the four
%     parameters PSI_ANGLE_STEP, PSI_ANGLE_SHELLS, PHI_ANGLE_STEP, and
%     PHI_ANGLE_SHELLS. They describe a search where the currently existing
%     alignment parameters for azimuth and zenith are used to define a "pole" to
%     search about in the ceiling of half PSI_ANGLE_SHELLS cones.  The change in
%     zenith between each cone is PSI_ANGLE_STEP and the azimuth around the cone
%     is close to the same angle but is adjusted slightly to account for bias
%     near the pole. The final spin angle of the search is done with a change in
%     spin of PHI_ANGLE_STEP in PHI_ANGLE_SHELLS steps. The spin is applied in
%     both clockwise and counter-clockwise fashion.
%
%         - The angles phi, and psi here are flipped in their sense of every
%         other package for EM image processing, which is absolutely infuriating
%         and confusing, but maintained for historical reasons, however most
%         descriptions use the words azimuth, zenith, and spin to avoid
%         ambiguity.
%
%     Finally after the constrained cross-correlation function is calculated it
%     is masked with CC_MASK_FN to limit the shifts to inside this volume, and a
%     peak is found and it's location is determined to sub-pixel accuracy using
%     interpolation. The rotations and shifts that gives the highest
%     cross-correlation coefficient are then chosen as the new alignments
%     parameters.

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'all_motl_fn_prefix', 'combinedmotl/allmotl');
    addParameter(fn_parser, 'ref_fn_prefix', 'ref/ref');
    addParameter(fn_parser, 'align_mask_fn', 'none');
    addParameter(fn_parser, 'cc_mask_fn', 'noshift');
    addParameter(fn_parser, 'output_motl_fn_prefix', 'combinedmotl/allmotl');
    addParameter(fn_parser, 'apply_mask', 0);
    addParameter(fn_parser, 'ref_class', 3);
    addParameter(fn_parser, 'psi_angle_step', 0);
    addParameter(fn_parser, 'psi_angle_shells', 0);
    addParameter(fn_parser, 'phi_angle_step', 0);
    addParameter(fn_parser, 'phi_angle_shells', 0);
    addParameter(fn_parser, 'high_pass_fp', 0);
    addParameter(fn_parser, 'high_pass_sigma', 0);
    addParameter(fn_parser, 'low_pass_fp', 0);
    addParameter(fn_parser, 'low_pass_sigma', 0);
    addParameter(fn_parser, 'nfold', 1);
    addParameter(fn_parser, 'iteration', 1);
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    all_motl_fn_prefix = fn_parser.Results.all_motl_fn_prefix;
    [all_motl_dir, ~, ~] = fileparts(all_motl_fn_prefix);

    if ~isempty(all_motl_dir) && exist(all_motl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'scan_angles_exact_refs:all_motl_dir: Directory %s %s.', ...
                all_motl_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    ref_fn_prefix = fn_parser.Results.ref_fn_prefix;
    [ref_dir, ~, ~] = fileparts(ref_fn_prefix);

    if ~isempty(ref_dir) && exist(ref_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'scan_angles_exact_refs:ref_dir: Directory %s %s.', ...
                ref_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    align_mask_fn = fn_parser.Results.align_mask_fn;

    if ~strcmp(align_mask_fn, 'none') && exist(align_mask_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'scan_angles_exact_refs:File %s does not exist.', ...
                align_mask_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    cc_mask_fn = fn_parser.Results.cc_mask_fn;

    if ~strcmp(cc_mask_fn, 'noshift') && exist(cc_mask_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'scan_angles_exact_refs:File %s does not exist.', ...
                cc_mask_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    output_motl_fn_prefix = fn_parser.Results.output_motl_fn_prefix;
    [output_motl_dir, ~, ~] = fileparts(output_motl_fn_prefix);

    if ~isempty(output_motl_dir) && exist(output_motl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'scan_angles_exact_refs:output_motl_dir: Directory %s %s.', ...
                output_motl_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    apply_mask = fn_parser.Results.apply_mask;

    if ischar(apply_mask)
        apply_mask = str2double(apply_mask);
    end

    try
        validateattributes(apply_mask, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_scan_angles_exact_refs', 'apply_mask');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    ref_class = fn_parser.Results.ref_class;

    if ischar(ref_class)
        ref_class = str2double(ref_class);
    end

    try
        validateattributes(ref_class, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', 'positive'}, ...
            'subtom_scan_angles_exact_refs', 'ref_class');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    psi_angle_step = fn_parser.Results.psi_angle_step;

    if ischar(psi_angle_step)
        psi_angle_step = str2double(psi_angle_step);
    end

    try
        validateattributes(psi_angle_step, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_scan_angles_exact_refs', 'psi_angle_step');

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
            'subtom_scan_angles_exact_refs', 'psi_angle_shells');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    phi_angle_step = fn_parser.Results.phi_angle_step;

    if ischar(phi_angle_step)
        phi_angle_step = str2double(phi_angle_step);
    end

    try
        validateattributes(phi_angle_step, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_scan_angles_exact_refs', 'phi_angle_step');

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
            'subtom_scan_angles_exact_refs', 'phi_angle_shells');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    high_pass_fp = fn_parser.Results.high_pass_fp;

    if ischar(high_pass_fp)
        high_pass_fp = str2double(high_pass_fp);
    end

    try
        validateattributes(high_pass_fp, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_scan_angles_exact_refs', 'high_pass_fp');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    high_pass_sigma = fn_parser.Results.high_pass_sigma;

    if ischar(high_pass_sigma)
        high_pass_sigma = str2double(high_pass_sigma);
    end

    try
        validateattributes(high_pass_sigma, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_scan_angles_exact_refs', 'high_pass_sigma');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    low_pass_fp = fn_parser.Results.low_pass_fp;

    if ischar(low_pass_fp)
        low_pass_fp = str2double(low_pass_fp);
    end

    try
        validateattributes(low_pass_fp, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_scan_angles_exact_refs', 'low_pass_fp');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    low_pass_sigma = fn_parser.Results.low_pass_sigma;

    if ischar(low_pass_sigma)
        low_pass_sigma = str2double(low_pass_sigma);
    end

    try
        validateattributes(low_pass_sigma, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_scan_angles_exact_refs', 'low_pass_sigma');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    nfold = fn_parser.Results.nfold;

    if ischar(nfold)
        nfold = str2double(nfold);
    end

    try
        validateattributes(nfold, {'numeric'}, ...
            {'scalar', 'nonnan', 'positive', 'integer'}, ...
            'subtom_scan_angles_exact_refs', 'nfold');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    iteration = fn_parser.Results.iteration;

    if ischar(iteration)
        iteration = str2double(iteration);
    end

    try
        validateattributes(iteration, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer'}, ...
            'subtom_scan_angles_exact_refs', 'iteration');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%
    % Read in all_motl file
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(all_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'scan_angles_exact_refs:File %s does not exist.', ...
                all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl = getfield(tom_emread(all_motl_fn), 'Value');

    if size(all_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'scan_angles_exact_refs:%s is not proper MOTL.', ...
                all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Find the number of valid classes in the motive list.
    classes = unique(all_motl(20, :));
    classes = classes(classes > 0);
    num_classes = length(classes);

    % Check if the calculation has already been done and skip if so.
    output_motl_fn = sprintf('%s_classed_%d.em', output_motl_fn_prefix, ...
        iteration);

    output_motl_fn_ = sprintf('%s_unclassed_%d.em', output_motl_fn_prefix, ...
        iteration);

    if exist(output_motl_fn, 'file') == 2 && ...
        exist(output_motl_fn_, 'file') == 2

        warning('subTOM:recoverOnFail', ...
            'scan_angles_exact_refs:MOTL %s and %s already exist. %s!', ...
            output_motl_fn, output_motl_fn_, 'SKIPPING');

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Read in the alignment reference to get the initial box size
    check_fn = sprintf('%s_class_%d_%d.em', ref_fn_prefix, ref_class, ...
        iteration);

    if exist(check_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'scan_angles_exact_refs:File %s does not exist.', check_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Note the transpose, tom_reademheader returns a column vector, but Matlab
    % size function returns a row vector, and ones and zeros need row vector
    box_size = getfield(tom_reademheader(check_fn), 'Header', 'Size')';

    % Read in alignment masks
    if strcmp(align_mask_fn, 'none')
        radius = floor(max(box_size) / 2) * 0.8;
        sigma = floor(max(box_size) / 2) * 0.15;
        align_mask = tom_spheremask(ones(box_size), radius, sigma);
    else
        align_mask = getfield(tom_emread(align_mask_fn), 'Value');

        if ~all(size(align_mask) == box_size)
            try
                error('subTOM:volDimError', ...
                    'scan_angles_exact_refs:%s and %s %s.', ...
                    align_mask_fn, check_fn, 'are not same size');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end
    end

    % Read in CC mask if shifts are being refined
    if ~strcmp(cc_mask_fn, 'noshift')
        cc_mask = getfield(tom_emread(cc_mask_fn), 'Value');

        if ~all(size(cc_mask) == box_size)
            try
                error('subTOM:volDimError', ...
                    'scan_angles_exact_refs:%s and %s %s.', ...
                    cc_mask_fn, check_fn, 'are not same size');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end
    end

    % Calculate band-pass mask
    if low_pass_fp > 0
        low_pass_mask = tom_spheremask(ones(box_size), low_pass_fp, ...
            low_pass_sigma);

    else
        low_pass_mask = ones(box_size);
    end

    if high_pass_fp > 0
        high_pass_mask = tom_spheremask(ones(box_size), high_pass_fp, ...
            high_pass_sigma);

    else
        high_pass_mask = zeros(box_size);
    end

    band_pass_mask = low_pass_mask - high_pass_mask;

    % Mask for box-edges for class averages if align mask is not applied
    if ~apply_mask
        radius = floor(max(box_size) / 2) * 0.8;
        sigma = floor(max(box_size) / 2) * 0.15;
        class_avg_spheremask = tom_spheremask(ones(box_size), radius, sigma);
    end

    % Prepare the alignment reference.
    ref_fn = sprintf('%s_class_%d_%d.em', ref_fn_prefix, ref_class, ...
        iteration);

    ref = getfield(tom_emread(ref_fn), 'Value');

    % Perform n-fold symmetrization of reference. If a volume VOL is assumed
    % to have a n-fold symmtry axis along Z it can be rotationally
    % symmetrized
    if nfold ~= 1
        ref = tom_symref(ref, nfold);
    end

    % Mask reference
    masked_ref = ref .* align_mask;

    % Subtract mean of the masked reference under the align mask
    masked_ref = subtom_subtract_mean_under_mask(masked_ref, align_mask);

    % Prepare the output motive list.
    output_motl = all_motl;

    % Since the azimuthal angle can range over the full 360 degrees while the
    % zenithal angle can only range over 180 degrees, the number of cones to
    % search is defined as the ceiling of half of the azimuthal segments
    theta_angle_shells = ceil(psi_angle_shells / 2);

    % Calculate the center coordinates of the box for interpreting the shifts
    box_center = floor(box_size / 2) + 1;

    % Setup the progress bar
    delprog = '';
    timings = [];
    message = sprintf('Class Average Alignment');
    op_type = 'class averages';
    tic;

    for class_idx = 1:num_classes

        % Get the class number
        class = classes(class_idx);

        % Check if motl should be procesed based on class, as we skip the
        % alignment reference.
        if class == ref_class
            % Display some output
            [delprog, timings] = subtom_display_progress(delprog, timings, ...
                message, op_type, num_classes, class_idx);

            continue
        end

        % Initialize maximum CCC
        max_ccc = -100000;

        % Read in class to align
        class_avg_fn = sprintf('%s_class_%d_%d.em', ref_fn_prefix, class, ...
            iteration);

        if exist(class_avg_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'scan_angles_exact_refs:File %s does not exist.', ...
                    class_avg_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        class_avg = getfield(tom_emread(class_avg_fn), 'Value');

        if ~all(size(class_avg) == box_size)
            try
                error('subTOM:volDimError', ...
                    'scan_angles_exact_refs:%s and %s %s.', ...
                    class_avg_fn, check_fn, 'are not same size');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        if apply_mask
            % Mask class average
            class_avg = class_avg .* align_mask;

            % Subtract mean of the masked class average under the align mask
            class_avg = subtom_subtract_mean_under_mask(class_avg, align_mask);
        else
            % Mask class average
            class_avg = class_avg .* class_avg_spheremask;

            % Subtract mean of the masked class average under the align mask
            class_avg = subtom_subtract_mean_under_mask(class_avg, ...
                class_avg_spheremask);

        end

        % Fourier transform class average.
        class_avg_fft = fftshift(fftn(class_avg));

        % Apply band-pass filter and inverse FFT shift
        class_avg_fft = ifftshift(class_avg_fft .* band_pass_mask);

        % Normalise the Fourier transform of the class average
        class_avg_fft = subtom_normalise_fftn(class_avg_fft);

        % Loop over the inplane search angles
        for phi_idx = -phi_angle_shells:phi_angle_shells
            for theta_idx = 0:theta_angle_shells
                if sind(theta_idx * psi_angle_step) == 0
                    psi_delta = 360;
                    psi_range = 0;
                else
                    psi_delta = psi_angle_step / ...
                        sind(theta_idx * psi_angle_step);

                    psi_range = 0:(ceil(360 / psi_delta) - 1);

                    % Make psi_delta equidistant again (from PYTOM)
                    psi_delta = 360 / ceil(360 / psi_delta);
                end

                for psi_idx = psi_range
                    psi = psi_idx * psi_delta;
                    theta = theta_idx * psi_angle_step;

                    % This is to reset the inplane caused by rotation of psi,
                    % which is necessary so that the particles initial
                    % orientation is not disturbed by the scanned angles, and
                    % keeps the maximum angular distance searched within what
                    % the user has specified in terms of psi and phi angle step.
                    phi0 = atan2d(-sind(psi), cosd(psi) * cosd(theta));
                    phi = phi0 + (phi_idx * phi_angle_step);

                    % Convert the search angle to a rotation matrix
                    rot_mat = subtom_zxz_to_matrix([phi, psi, theta]);

                    % Determine the actual search Euler angles from the above
                    % calculated rotation matrix.
                    scan_euler = subtom_matrix_to_zxz(rot_mat);
                    phi = scan_euler(1);
                    psi = scan_euler(2);
                    theta = scan_euler(3);

                    % Prepare the reference for correlation
                    % Rotate reference
                    rot_ref = tom_rotate(masked_ref, [phi, psi, theta]);

                    % Fourier transform reference
                    ref_fft = fftshift(fftn(rot_ref));

                    % Apply band-pass filter and inverse FFT shift
                    ref_fft = ifftshift(ref_fft .* band_pass_mask);

                    % Normalise the Fourier transform of the reference
                    ref_fft = subtom_normalise_fftn(ref_fft);

                    % Calculate cross correlation and apply rotated ccmask
                    ccf = real(...
                        fftshift(ifftn(class_avg_fft .* conj(ref_fft))));

                    ccf = ccf / numel(ccf);

                    % Determine max CCC and its location
                    if ~strcmp(cc_mask_fn, 'noshift')

                        % Rotate CC mask and mask the CCF
                        rot_cc_mask = tom_rotate(cc_mask, ...
                            [phi, psi, theta]);

                        masked_ccf = ccf .* rot_cc_mask;

                        % Find the integral coordinates and value of the
                        % peak
                        [peak_value, peak_linear_idx] = max(masked_ccf(:));
                        [x, y, z] = ind2sub(box_size, peak_linear_idx);
                        peak_coord = [x, y, z];

                        % Find the subpixel location and value of the peak
                        [ccc, peak] = get_subpixel_peak(masked_ccf, ...
                            peak_value, peak_coord);

                    else
                        % Find peak at previous center for no shift
                        peak_coord = round(old_ref_shift' + box_center);
                        peak_value = ccf(peak_coord(1), peak_coord(2), ...
                            peak_coord(3));

                        [ccc, peak] = get_subpixel_peak(ccf, peak_value, ...
                            peak_coord);

                    end

                    % If current max ccc is greater than the overall
                    % maximum, update the maximum ccc, Euler angles, and
                    % shifts
                    if ccc > max_ccc
                        max_ccc = ccc;

                        % Normalise the angles so that phi and psi are in
                        % the range (-180, 180] and theta is in the range
                        % [0, 180]
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

                        new_class_rot = [phi, psi, theta];
                        new_class_shift = peak - box_center;
                    end
                end
            end
        end

        % Create an affine matrix for the transformation of reference to
        % class-average
        affine_ref = eye(4, 4);
        affine_ref(1:3, 1:3) = subtom_zxz_to_matrix(new_class_rot);
        affine_ref(1:3, 4) = new_class_shift;

        % Find particles that belong to the current class.
        ptcl_idxs = find(output_motl(20, :) == class);

        % Update motl with new values for shifts and rotations.
        for ptcl_idx = ptcl_idxs

            % Create an affine matrix for the transformation of class-average to
            % particle.
            affine_ptcl = eye(4, 4);
            affine_ptcl(1:3, 1:3) = subtom_zxz_to_matrix(...
                output_motl(17:19, ptcl_idx));

            affine_ptcl(1:3, 4) = output_motl(11:13, ptcl_idx);

            % Determine the affine matrix for the transformation of reference
            % to particle. 
            % NOTE: In my head this should be the other way around, but for some
            % reason this is the one that works???
            affine_both = affine_ptcl * affine_ref;

            % Update the particles rotations and shifts.
            output_motl(17:19, ptcl_idx) = subtom_matrix_to_zxz(...
                affine_both(1:3, 1:3));

            output_motl(11:13, ptcl_idx) = affine_both(1:3, 4);
        end

        % Display some output
        [delprog, timings] = subtom_display_progress(delprog, timings, ...
            message, op_type, num_classes, class_idx);

    end

    % Write out the motl with class information included.
    tom_emwrite(output_motl_fn, output_motl);
    subtom_check_em_file(output_motl_fn, output_motl);

    % Remove the class information so the motive list can be used single
    % reference alignment. Here we are just setting the class number to 1.
    % Perhaps 0 would be more appropriate, but I see that leading to user-error.
    output_motl(20, :) = 1;

    % Write out the motl with class information excluded.
    tom_emwrite(output_motl_fn_, output_motl);
    subtom_check_em_file(output_motl_fn_, output_motl);
end

%##############################################################################%
%                              GET_SUBPIXEL_PEAK                               %
%##############################################################################%
function [value, peak] = get_subpixel_peak(ccf, peak_value, peak_coord)
% GET_SUBPIXEL_PEAK find sub-pixel peak of cross correlation function
%     GET_SUBPIXEL_PEAK(
%         CCF,
%         PEAK_VALUE,
%         PEAK_COORD)
%
%     A function to take in a given volume, find the pixel with highest value,
%     and use interpolation to find the peak with subpixel precision. 
%
%     The math for this function was taken from Yuxiang Chen's
%     find_subpixel_peak_position function in the SH_align package. See
%     10.1016/j.jsb.2013.03.002 for more information. 
%
% Example:
%     get_subpixel_peak(masked_ccf, peak_value, peak_coord)

% WW 01-2016
    try
        dx = (  ccf(peak_coord(1) + 1, peak_coord(2), peak_coord(3)) ...
              - ccf(peak_coord(1) - 1, peak_coord(2), peak_coord(3))) / 2;

        dy = (  ccf(peak_coord(1), peak_coord(2) + 1, peak_coord(3)) ...
              - ccf(peak_coord(1), peak_coord(2) - 1, peak_coord(3))) / 2;

        dz = (  ccf(peak_coord(1), peak_coord(2), peak_coord(3) + 1) ...
              - ccf(peak_coord(1), peak_coord(2), peak_coord(3) - 1)) / 2;

        dxx =   ccf(peak_coord(1) + 1, peak_coord(2), peak_coord(3)) ...
              + ccf(peak_coord(1) - 1, peak_coord(2), peak_coord(3)) ...
              - (2 * peak_value);

        dyy =   ccf(peak_coord(1), peak_coord(2) + 1, peak_coord(3)) ...
              + ccf(peak_coord(1), peak_coord(2) - 1, peak_coord(3)) ...
              - (2 * peak_value);

        dzz =   ccf(peak_coord(1), peak_coord(2), peak_coord(3) + 1) ...
              + ccf(peak_coord(1), peak_coord(2), peak_coord(3) - 1) ...
              - (2 * peak_value);

        dxy = (  ccf(peak_coord(1) + 1, peak_coord(2) + 1, peak_coord(3)) ...
               + ccf(peak_coord(1) - 1, peak_coord(2) - 1, peak_coord(3)) ...
               - ccf(peak_coord(1) + 1, peak_coord(2) - 1, peak_coord(3)) ...
               - ccf(peak_coord(1) - 1, peak_coord(2) + 1, peak_coord(3))) / 4;

        dxz = (  ccf(peak_coord(1) + 1, peak_coord(2), peak_coord(3) + 1) ...
               + ccf(peak_coord(1) - 1, peak_coord(2), peak_coord(3) - 1) ...
               - ccf(peak_coord(1) + 1, peak_coord(2), peak_coord(3) - 1) ...
               - ccf(peak_coord(1) - 1, peak_coord(2), peak_coord(3) + 1)) / 4;

        dyz = (  ccf(peak_coord(1), peak_coord(2) + 1, peak_coord(3) + 1) ...
               + ccf(peak_coord(1), peak_coord(2) - 1, peak_coord(3) - 1) ...
               - ccf(peak_coord(1), peak_coord(2) - 1, peak_coord(3) + 1) ...
               - ccf(peak_coord(1), peak_coord(2) + 1, peak_coord(3) - 1)) / 4;

        aa = [dxx, dxy, dxz; ...
              dxy, dyy, dyz; ...
              dxz, dyz, dzz];

        bb = [-dx; -dy; -dz];

        det = linsolve(aa, bb);

        if abs(det(1)) > 1 || abs(det(2)) > 1 || abs(det(3)) > 1
            peak = peak_coord;
            value = peak_value;
        else
            peak = [peak_coord(1) + det(1), ...
                    peak_coord(2) + det(2), ...
                    peak_coord(3) + det(3)];

            value =   peak_value ...
                    + (dx * det(1)) + (dy * det(2)) + (dz * det(3)) ...
                    + (dxx * (det(1)^2) / 2) + (dyy * (det(2)^2) / 2) ...
                    + (dzz * (det(3)^2) / 2) + (det(1) * det(2) * dxy) ...
                    + (det(1) * det(3) * dxz)  + (det(2) * det(3) * dyz);
        end
    catch
        peak = peak_coord;
        value = peak_value;
    end
end
