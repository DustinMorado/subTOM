function subtom_scan_angles_exact_multiref(varargin)
% SUBTOM_SCAN_ANGLES_EXACT_MULTIREF align a particle batch over local angles.
%
%     SUBTOM_SCAN_ANGLES_EXACT_MULTIREF(
%         'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX,
%         'ref_fn_prefix', REF_FN_PREFIX,
%         'ptcl_fn_prefix', PTCL_FN_PREFIX,
%         'weight_fn_prefix', WEIGHT_FN_PREFIX,
%         'align_mask_fn', ALIGN_MASK_FN,
%         'cc_mask_fn', CC_MASK_FN,
%         'apply_weight', APPLY_WEIGHT,
%         'apply_mask', APPLY_MASK,
%         'keep_class', KEEP_CLASS,
%         'psi_angle_step', PSI_ANGLE_STEP,
%         'psi_angle_shells', PSI_ANGLE_SHELLS,
%         'phi_angle_step', PHI_ANGLE_STEP,
%         'phi_angle_shells', PHI_ANGLE_SHELLS,
%         'high_pass_fp', HIGH_PASS_FP,
%         'high_pass_sigma', HIGH_PASS_SIGMA,
%         'low_pass_fp', LOW_PASS_FP,
%         'low_pass_sigma', LOW_PASS_SIGMA,
%         'nfold', NFOLD,
%         'threshold', THRESHOLD,
%         'iteration', ITERATION,
%         'tomo_row', TOMO_ROW,
%         'num_ali_batch', NUM_ALI_BATCH,
%         'process_idx', PROCESS_IDX)
%
%     Aligns a batch of particles from the collective motive list with the name
%     format ALL_MOTL_FN_PREFIX_#.em where # is the number ITERATION. The motive
%     list is split into NUM_ALI_BATCH chunks and the specific chunk to process
%     is specified by PROCESS_IDX. A motive list for the best determined
%     alignment parameters is written out for each batch with the name format
%     ALL_MOTL_FN_PREFIX_#_#.em where the first # is ITERATION + 1 and the
%     second # is the number PROCESS_IDX.
%
%     Particles, with the name format PTCL_FN_PREFX_#.em where # is the
%     subtomogram ID, are aligned against the reference with the name format
%     REF_FN_PREFIX_#.em where # is ITERATION. Before the comparison is made a
%     number of alterations are made to both the particle and reference:
%
%         - If NFOLD is greater than 1 then C#-symmetry is applied along the
%           Z-axis to the reference where # is NFOLD.
%
%         - The reference is masked in real space with the mask ALIGN_MASK_FN,
%           and if APPLY_MASK evaluates to true as a boolean, then this mask is
%           also applied to the particle. A sphere mask is applied to the
%           particle to reduces the artifacts caused by the box-edges on the
%           comparison. This sphere has a diameter that is 80% the box size and
%           falls of with a sigma that is 15% half the box size.
%
%             - The mask is rotated and shifted with the currently existing
%               alignment parameters for the particle as to best center the mask
%               on the particle density.
%
%             - APPLY_MASK can help alignment and suppress alignment to other
%               features when the particle is well-centered or already
%               reasonably well aligned, but if this is not the case there is
%               the risk that a tight alignment will cutoff parts of the
%               particle.
%
%         - Both the particle and the reference are bandpass filtered in the
%           Fourier domain defined by HIGH_PASS_FP, HIGH_PASS_SIGMA,
%           LOW_PASS_FP, and LOW_PASS_SIGMA which are all in the units of
%           Fourier pixels.
%
%         - A Fourier weight volume with the name format WEIGHT_FN_PREFIX_#.em
%           where # corresponds to the tomogram from which the particle came
%           from, which is found from the field TOMO_ROW in the motive list, is
%           applied to the reference in the Fourier domain, after the reference
%           has been rotated with the currently existing alignment parameters.
%           If APPLY_WEIGHT evaluates to true as a boolean, then this weight is
%           also applied to the particle with no rotation. This Fourier weight
%           is designed to compensate for the missing wedge.
%
%             - If a binary wedge is used, then it is reasonable to apply the
%               weight to the particle, however, for more complicated weights,
%               like the average amplitude spectrum, it should not be done.
%
%     The local rotations searched during alignment are deteremined by the four
%     parameters PSI_ANGLE_STEP, PSI_ANGLE_SHELLS, PHI_ANGLE_STEP, and
%     PHI_ANGLE_SHELLS. They describe a search where the currently existing
%     alignment parameters for azimuth and zenith are used to define a "pole" to
%     search about in PSI_ANGLE_SHELLS cones. The change in zenith between each
%     cone is PSI_ANGLE_STEP and the azimuth around the cone is close to the
%     same angle but is adjusted slightly to account for bias near the pole. The
%     final spin angle of the search is done with a change in spin of
%     PHI_ANGLE_STEP in PHI_ANGLE_SHELLS steps. The spin is applied in both
%     clockwise and counter-clockwise fashion.
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
%     parameters. Particles with a coefficient lower than THRESHOLD are placed
%     into class 2 and ignored in later processing, and particles with class
%     ICLASS are the only particles processed.
%
%         - If ICLASS is 0 all particles will be considered, and particles above
%         THRESHOLD will be assigned to iclass of 1 and particles below
%         THRESHOLD will be assigned to iclass of 2. If ICLASS is 1 or 2 then
%         particles with iclass 0 will be skipped, particles of iclass 1 and 2
%         will be aligned and particles with scores above THRESHOLD will be
%         assigned to iclass 1 and particles with scores below THRESHOLD will be
%         assigned to iclass 2. ICLASS of 2 does not make much sense but is set
%         this way in case of user mistakes or misunderstandings. If ICLASS is
%         greater than 2 then particles with iclass of 1, 2, and ICLASS will be
%         aligned, and particles with a score above THRESHOLD will maintain
%         their iclass if it is 1 or ICLASS, and particles with a previous
%         iclass of 2 will be upgraded to an iclass of 1. Particles with a score
%         below THRESHOLD will be assigned to iclass 2. 
%
%         - The class number is stored in the 20th field of the motive list.

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
    addParameter(fn_parser, 'ptcl_fn_prefix', 'subtomograms/subtomo');
    addParameter(fn_parser, 'weight_fn_prefix', 'otherinputs/ampspec');
    addParameter(fn_parser, 'align_mask_fn', 'none');
    addParameter(fn_parser, 'cc_mask_fn', 'noshift');
    addParameter(fn_parser, 'apply_weight', 0);
    addParameter(fn_parser, 'apply_mask', 0);
    addParameter(fn_parser, 'keep_class', 0);
    addParameter(fn_parser, 'psi_angle_step', 0);
    addParameter(fn_parser, 'psi_angle_shells', 0);
    addParameter(fn_parser, 'phi_angle_step', 0);
    addParameter(fn_parser, 'phi_angle_shells', 0);
    addParameter(fn_parser, 'high_pass_fp', 0);
    addParameter(fn_parser, 'high_pass_sigma', 0);
    addParameter(fn_parser, 'low_pass_fp', 0);
    addParameter(fn_parser, 'low_pass_sigma', 0);
    addParameter(fn_parser, 'nfold', 1);
    addParameter(fn_parser, 'threshold', -1);
    addParameter(fn_parser, 'iteration', 1);
    addParameter(fn_parser, 'tomo_row', 7);
    addParameter(fn_parser, 'num_ali_batch', 1);
    addParameter(fn_parser, 'process_idx', 1);
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    all_motl_fn_prefix = fn_parser.Results.all_motl_fn_prefix;
    [all_motl_dir, ~, ~] = fileparts(all_motl_fn_prefix);

    if ~isempty(all_motl_dir) && exist(all_motl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'scan_angles_exact_multiref:all_motl_dir: Directory %s %s.', ...
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
                'scan_angles_exact_multiref:ref_dir: Directory %s %s.', ...
                ref_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    ptcl_fn_prefix = fn_parser.Results.ptcl_fn_prefix;
    [ptcl_dir, ~, ~] = fileparts(ptcl_fn_prefix);

    if ~isempty(ptcl_dir) && exist(ptcl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'scan_angles_exact_multiref:ptcl_dir: Directory %s %s.', ...
                ptcl_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    weight_fn_prefix = fn_parser.Results.weight_fn_prefix;
    [weight_dir, ~, ~] = fileparts(weight_fn_prefix);

    if exist(weight_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'scan_angles_exact_multiref:weight_dir: Directory %s %s.', ...
                weight_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    align_mask_fn = fn_parser.Results.align_mask_fn;

    if ~strcmp(align_mask_fn, 'none') && exist(align_mask_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'scan_angles_exact_multiref:File %s does not exist.', ...
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
                'scan_angles_exact_multiref:File %s does not exist.', ...
                cc_mask_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    apply_weight = fn_parser.Results.apply_weight;

    if ischar(apply_weight)
        apply_weight = str2double(apply_weight);
    end

    try
        validateattributes(apply_weight, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_scan_angles_exact_multiref', 'apply_weight');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    apply_mask = fn_parser.Results.apply_mask;

    if ischar(apply_mask)
        apply_mask = str2double(apply_mask);
    end

    try
        validateattributes(apply_mask, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_scan_angles_exact_multiref', 'apply_mask');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    keep_class = fn_parser.Results.keep_class;

    if ischar(keep_class)
        keep_class = str2double(keep_class);
    end

    try
        validateattributes(keep_class, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_scan_angles_exact_multiref', 'keep_class');

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
            'subtom_scan_angles_exact_multiref', 'psi_angle_step');

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
            'subtom_scan_angles_exact_multiref', 'psi_angle_shells');

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
            'subtom_scan_angles_exact_multiref', 'phi_angle_step');

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
            'subtom_scan_angles_exact_multiref', 'phi_angle_shells');

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
            'subtom_scan_angles_exact_multiref', 'high_pass_fp');

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
            'subtom_scan_angles_exact_multiref', 'high_pass_sigma');

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
            'subtom_scan_angles_exact_multiref', 'low_pass_fp');

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
            'subtom_scan_angles_exact_multiref', 'low_pass_sigma');

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
            'subtom_scan_angles_exact_multiref', 'nfold');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    threshold = fn_parser.Results.threshold;

    if ischar(threshold)
        threshold = str2double(threshold);
    end

    try
        validateattributes(threshold, {'numeric'}, ...
            {'scalar', 'nonnan', '>=', -1, '<=', 1}, ...
            'subtom_scan_angles_exact_multiref', 'threshold');

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
            'subtom_scan_angles_exact_multiref', 'iteration');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    tomo_row = fn_parser.Results.tomo_row;

    if ischar(tomo_row)
        tomo_row = str2double(tomo_row);
    end

    try
        validateattributes(tomo_row, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0, '<', 21}, ...
            'subtom_scan_angles_exact_multiref', 'tomo_row');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    num_ali_batch = fn_parser.Results.num_ali_batch;

    if ischar(num_ali_batch)
        num_ali_batch = str2double(num_ali_batch);
    end

    try
        validateattributes(num_ali_batch, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0}, ...
            'subtom_scan_angles_exact_multiref', 'num_ali_batch');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    process_idx = fn_parser.Results.process_idx;

    if ischar(process_idx)
        process_idx = str2double(process_idx);
    end

    try
        validateattributes(process_idx, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0, '<=', num_ali_batch}, ...
            'subtom_scan_angles_exact_multiref', 'process_idx');

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
                'scan_angles_exact_multiref:File %s does not exist.', ...
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
                'scan_angles_exact_multiref:%s is not proper MOTL.', ...
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
    motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration + 1);

    if exist(motl_fn, 'file') == 2
        warning('subTOM:recoverOnFail', ...
            'scan_angles_exact_multiref:MOTL %s already exists. SKIPPING!', ...
            motl_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Check if the calculation has already been done and skip if so.
    motl_fn = sprintf('%s_%d_%d.em', all_motl_fn_prefix, iteration + 1, ...
        process_idx);

    if exist(motl_fn, 'file') == 2
        warning('subTOM:recoverOnFail', ...
            'scan_angles_exact_multiref:MOTL %s already exists. SKIPPING!', ...
            motl_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Read in the first reference to get the initial box size
    check_fn = sprintf('%s_class_%d_%d.em', ref_fn_prefix, classes(1), ...
        iteration);

    if exist(check_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'scan_angles_exact_multiref:File %s does not exist.', check_fn);

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
                    'scan_angles_exact_multiref:%s and %s %s.', ...
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
                    'scan_angles_exact_multiref:%s and %s %s.', ...
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

    % Mask for box-edges for subtomogram if align mask is not applied
    if ~apply_mask
        radius = floor(max(box_size) / 2) * 0.8;
        sigma = floor(max(box_size) / 2) * 0.15;
        ptcl_spheremask = tom_spheremask(ones(box_size), radius, sigma);
    end

    % Prepare the references.
    refs = arrayfun(@(x) zeros(box_size), 1:num_classes, 'UniformOutput', 0);

    for class_idx = 1:num_classes
        ref_fn = sprintf('%s_class_%d_%d.em', ref_fn_prefix, ...
            classes(class_idx), iteration);

        if exist(ref_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'scan_angles_exact_multiref:File %s does not exist.', ...
                    ref_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        ref = getfield(tom_emread(ref_fn), 'Value');

        if ~all(size(ref) == box_size)
            try
                error('subTOM:volDimError', ...
                    'scan_angles_exact_multiref:%s and %s %s.', ...
                    ref_fn, check_fn, 'are not same size');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

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

        refs{class_idx} = masked_ref;
    end

    % Calculate the particle indices that we will align
    num_ptcls = size(all_motl, 2);

    if num_ali_batch > num_ptcls
        try
            error('subTOM:argumentError', ...
                'scan_angles_exact_multiref:%s is greater than %s.', ...
                'num_ali_batch', 'num_ptcls');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    ali_batch_size = floor(num_ptcls / num_ali_batch);

    if process_idx > num_ptcls - num_ali_batch * ali_batch_size
        ptcl_start_idx = (process_idx - 1) * ali_batch_size + 1 + ...
            (num_ptcls - num_ali_batch * ali_batch_size);

        ptcl_end_idx = ptcl_start_idx + ali_batch_size - 1;
    else
        ptcl_start_idx = (process_idx - 1) * (ali_batch_size + 1) + 1;
        ptcl_end_idx = ptcl_start_idx + ali_batch_size;
    end

    batch_size = ptcl_end_idx - ptcl_start_idx + 1;

    motl = zeros(20, batch_size);
    motl_idx = 1;

    % Initialize a variable to keep track of the weight volume to use
    current_weight = 0;

    % Since the azimuthal angle can range over the full 360 degrees while the
    % zenithal angle can only range over 180 degrees, the number of cones to
    % search is defined as the ceiling of half of the azimuthal segments
    theta_angle_shells = ceil(psi_angle_shells / 2);

    % Calculate the center coordinates of the box for interpreting the shifts
    box_center = floor(box_size / 2) + 1;

    % Setup the progress bar
    delprog = '';
    timings = [];
    message = sprintf('Alignment Batch %d', process_idx);
    op_type = 'particles';
    tic;

    for ptcl_idx = ptcl_start_idx:ptcl_end_idx

        % Check if motl should be procesed based on class
        if ~ismember(all_motl(20, ptcl_idx), classes)

            % Skip alignment and add particle as is to batch motl
            motl(:, motl_idx) = all_motl(:, ptcl_idx);

            % Display some output
            [delprog, timings] = subtom_display_progress(delprog, timings, ...
                message, op_type, batch_size, motl_idx);

            motl_idx = motl_idx + 1;
            continue
        end

        % Check wedge and generated mask if needed
        if current_weight ~= all_motl(tomo_row, ptcl_idx)

            % Set current weight and read in weight volume
            current_weight = all_motl(tomo_row, ptcl_idx);
            weight_fn = sprintf('%s_%d.em', weight_fn_prefix, current_weight);

            if exist(weight_fn, 'file') ~= 2
                try
                    error('subTOM:missingFileError', ...
                        'scan_angles_exact_multiref:File %s %s.', ...
                        weight_fn, 'does not exist');

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            weight = getfield(tom_emread(weight_fn), 'Value');

            if ~all(size(weight) == box_size)
                try
                    error('subTOM:volDimError', ...
                        'scan_angles_exact_multiref:%s and %s %s.', ...
                        weight_fn, check_fn, 'are not same size');

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end
        end

        % Parse translations from motl
        % These translations describe the translation of the reference to the
        % particle after rotation has been applied to the reference. In the
        % motl they are ordered: X-axis shift, Y-axis shift, and Z-axis shift.
        old_ref_shift = all_motl(11:13, ptcl_idx);

        % Parse rotations from motl
        % These rotations describe the rotations of the reference to the
        % particle determined in alignment. In the motl they are ordered;
        % azimuthal rotation, inplane rotation, and zenithal rotation.
        old_ref_rot = all_motl(17:19, ptcl_idx);

        % Calculate the rotation matrix form of the rotations in the motive list
        % which is necessary to determine the correct scan angles centered on
        % this initial orientation.
        old_ref_rot_mat = subtom_zxz_to_matrix(old_ref_rot);

        % Initialize maximum CCC, shift vector, and current class
        max_ccc = -100000;
        new_ref_shift = old_ref_shift;
        new_class = all_motl(20, ptcl_idx);

        % Read in subtomogram
        ptcl_fn = sprintf('%s_%d.em', ptcl_fn_prefix, all_motl(4, ptcl_idx));

        if exist(ptcl_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'scan_angles_exact_multiref:File %s does not exist.', ...
                    ptcl_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        ptcl = getfield(tom_emread(ptcl_fn), 'Value');

        if ~all(size(ptcl) == box_size)
            try
                error('subTOM:volDimError', ...
                    'scan_angles_exact_multiref:%s and %s %s.', ...
                    ptcl_fn, check_fn, 'are not same size');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        if apply_mask
            % Rotate and shift alignment mask
            ptcl_align_mask = tom_rotate(align_mask, old_ref_rot);
            ptcl_align_mask = tom_shift(ptcl_align_mask, old_ref_shift);

            % Mask subtomogram
            ptcl = ptcl .* ptcl_align_mask;

            % Subtract mean of the masked particle under the align mask
            ptcl = subtom_subtract_mean_under_mask(ptcl, ptcl_align_mask);
        else
            % Mask subtomogram
            ptcl = ptcl .* ptcl_spheremask;

            % Subtract mean of the masked particle under the align mask
            ptcl = subtom_subtract_mean_under_mask(ptcl, ptcl_spheremask);
        end

        % Fourier transform particle
        ptcl_fft = fftshift(fftn(ptcl));

        % Apply band-pass filter and inverse FFT shift
        if apply_weight
            ptcl_fft = ifftshift(ptcl_fft .* band_pass_mask .* weight);
        else
            ptcl_fft = ifftshift(ptcl_fft .* band_pass_mask);
        end

        % Normalise the Fourier transform of the particle
        ptcl_fft = subtom_normalise_fftn(ptcl_fft);

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
                    initial_rot_mat = subtom_zxz_to_matrix([phi, psi, theta]);

                    % Compose the actual search angle which is the product of
                    % the rotation matrix describing the particles initial
                    % orientation and the rotation matrix describing the
                    % orientation we want to search.
                    rot_mat = old_ref_rot_mat * initial_rot_mat;

                    % Determine the actual search Euler angles from the above
                    % calculated rotation matrix.
                    scan_euler = subtom_matrix_to_zxz(rot_mat);
                    phi = scan_euler(1);
                    psi = scan_euler(2);
                    theta = scan_euler(3);

                    if ~keep_class
                        class_idxs = 1:num_classes;
                    else
                        class_idxs = find(classes == all_motl(20, ptcl_idx));
                    end

                    % Loop over the references.
                    for class_idx = class_idxs
                        masked_ref = refs{class_idx};

                        % Prepare the reference for correlation
                        % Rotate reference
                        rot_ref = tom_rotate(masked_ref, [phi, psi, theta]);

                        % Fourier transform reference
                        ref_fft = fftshift(fftn(rot_ref));

                        % Apply band-pass filter and inverse FFT shift
                        ref_fft = ifftshift(ref_fft .* weight .* ...
                            band_pass_mask);

                        % Normalise the Fourier transform of the reference
                        ref_fft = subtom_normalise_fftn(ref_fft);

                        % Calculate cross correlation and apply rotated ccmask
                        ccf = real(...
                            fftshift(ifftn(ptcl_fft .* conj(ref_fft))));

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

                            new_ref_rot = [phi, psi, theta];
                            new_ref_shift = peak - box_center;
                            new_class = classes(class_idx);
                        end
                    end
                end
            end
        end

        % Update motl with new values for max CCC, shifts, rotations and class
        motl(:, motl_idx) = all_motl(:, ptcl_idx);
        motl(1, motl_idx) = max_ccc;
        motl(11:13, motl_idx) = new_ref_shift;
        motl(17:19, motl_idx) = new_ref_rot;
        if max_ccc >= threshold
            motl(20, motl_idx) = new_class;
        else
            motl(20, motl_idx) = 2;
        end

        % Display some output
        [delprog, timings] = subtom_display_progress(delprog, timings, ...
            message, op_type, batch_size, motl_idx);

        motl_idx = motl_idx + 1;
    end

    % Write out motl
    tom_emwrite(motl_fn, motl);
    subtom_check_em_file(motl_fn, motl);
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
