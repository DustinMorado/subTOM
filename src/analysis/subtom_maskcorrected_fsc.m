function subtom_maskcorrected_fsc(varargin)
% SUBTOM_MASKCORRECTED_FSC calculates "mask-corrected" FSC and sharpened refs.
%
%     SUBTOM_MASKCORRECTED_FSC(
%         'ref_a_fn_prefix', REF_A_FN_PREFIX,
%         'ref_b_fn_prefix', REF_B_FN_PREFIX,
%         'fsc_mask_fn', FSC_MASK_FN,
%         'output_fn_prefix', OUTPUT_FN_PREFIX,
%         'filter_a_fn', FILTER_A_FN,
%         'filter_b_fn', FILTER_B_FN,
%         'do_reweight', DO_REWEIGHT,
%         'do_sharpen', DO_SHARPEN,
%         'plot_fsc', PLOT_FSC,
%         'plot_sharpen', PLOT_SHARPEN,
%         'filter_mode', FILTER_MODE,
%         'pixelsize', PIXELSIZE,
%         'nfold', NFOLD,
%         'filter_threshold', FILTER_THRESHOLD,
%         'rand_threshold', RAND_THRESHOLD,
%         'b_factor', B_FACTOR,
%         'box_gaussian', BOX_GAUSSIAN,
%         'iteration', ITERATION)
%
%     Takes in two references REF_A_FN_PREFIX_#.em and REF_B_FN_PREFIX_#.em
%     where # corresponds to ITERATION and a FSC mask FSC_MASK_FN and calculates
%     a "mask-corrected" FSC. This works by randomizing the structure factor
%     phases beyond the point where the unmasked FSC curve falls below a given
%     threshold (by default 0.8) and calculating an additional FSC between these
%     phase randomized maps.  This allows for the determination of the extra
%     correlation caused by effects of the mask, which is then subtracted from
%     the normal masked FSC curves. The curve will be saved as a Matlab figure
%     and a PDF file, and if PLOT_FSC is true it will also be displayed.
%
%     The script can also output maps with the prefix OUTPUT_FN_PREFIX that have
%     been sharpened with B_FACTOR if DO_SHARPEN is turned on. This setting has
%     two threshold settings selected using FILTER_MODE, FSC (1) and pixel (2).
%     FSC allows you to use a FSC-value FILTER_THRESHOLD as a cutoff for the
%     lowpass filter, while using pixels allows you to use an arbitrary
%     resolution cutoff in FILTER_THRESHOLD. The sharpening curve will be saved
%     as a Matlab figure and a pdf file, and if PLOT_SHARPEN is true it will
%     also be displayed.
%
%     Finally this script can also perform and output reweighted maps if
%     DO_REWEIGHT is true, and the pre-calculated Fourier weight volumes
%     FILTER_A_FN and FILTER_B_FN.

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'ref_a_fn_prefix', 'even/ref/ref');
    addParameter(fn_parser, 'ref_b_fn_prefix', 'odd/ref/ref');
    addParameter(fn_parser, 'fsc_mask_fn', 'FSC/fsc_mask.em');
    addParameter(fn_parser, 'output_fn_prefix', 'FSC/ref');
    addParameter(fn_parser, 'filter_a_fn', '');
    addParameter(fn_parser, 'filter_b_fn', '');
    addParameter(fn_parser, 'do_reweight', 0);
    addParameter(fn_parser, 'do_sharpen', 0);
    addParameter(fn_parser, 'plot_fsc', 0);
    addParameter(fn_parser, 'plot_sharpen', 0);
    addParameter(fn_parser, 'filter_mode', 1);
    addParameter(fn_parser, 'pixelsize', 1.0);
    addParameter(fn_parser, 'nfold', 1);
    addParameter(fn_parser, 'filter_threshold', 0.143);
    addParameter(fn_parser, 'rand_threshold', 0.8);
    addParameter(fn_parser, 'b_factor', 0);
    addParameter(fn_parser, 'box_gaussian', 1);
    addParameter(fn_parser, 'iteration', 1);
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    iteration = fn_parser.Results.iteration;

    if ischar(iteration)
        iteration = str2double(iteration);
    end

    try
        validateattributes(iteration, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer'}, ...
            'subtom_maskcorrected_FSC', 'iteration');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    ref_a_fn_prefix = fn_parser.Results.ref_a_fn_prefix;
    ref_a_fn = sprintf('%s_%d.em', ref_a_fn_prefix, iteration);
    
    if exist(ref_a_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'maskcorrected_FSC:File %s does not exist.', ref_a_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    ref_b_fn_prefix = fn_parser.Results.ref_b_fn_prefix;
    ref_b_fn = sprintf('%s_%d.em', ref_b_fn_prefix, iteration);
    
    if exist(ref_b_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'maskcorrected_FSC:File %s does not exist.', ref_b_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    fsc_mask_fn = fn_parser.Results.fsc_mask_fn;

    if ~strcmpi(fsc_mask_fn, 'none') && exist(fsc_mask_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'maskcorrected_FSC:File %s does not exist.', fsc_mask_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    output_fn_prefix = fn_parser.Results.output_fn_prefix;
    [output_dir, ~, ~] = fileparts(output_fn_prefix);

    if ~isempty(output_dir) && exist(output_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'maskcorrected_FSC:output_dir: Directory %s %s.', ...
                output_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    output_fn_prefix = sprintf('%s_%d', output_fn_prefix, iteration);

    do_reweight = fn_parser.Results.do_reweight;

    if ischar(do_reweight)
        do_reweight = str2double(do_reweight);
    end

    try
        validateattributes(do_reweight, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_maskcorrected_FSC', 'do_reweight');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    filter_a_fn = fn_parser.Results.filter_a_fn;

    if do_reweight && exist(filter_a_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'maskcorrected_FSC:File %s does not exist.', filter_a_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    filter_b_fn = fn_parser.Results.filter_b_fn;

    if do_reweight && exist(filter_b_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'maskcorrected_FSC:File %s does not exist.', filter_b_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    do_sharpen = fn_parser.Results.do_sharpen;

    if ischar(do_sharpen)
        do_sharpen = str2double(do_sharpen);
    end

    try
        validateattributes(do_sharpen, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_maskcorrected_FSC', 'do_sharpen');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    plot_fsc = fn_parser.Results.plot_fsc;

    if ischar(plot_fsc)
        plot_fsc = str2double(plot_fsc);
    end

    try
        validateattributes(plot_fsc, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_maskcorrected_FSC', 'plot_fsc');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    plot_sharpen = fn_parser.Results.plot_sharpen;

    if ischar(plot_sharpen)
        plot_sharpen = str2double(plot_sharpen);
    end

    try
        validateattributes(plot_sharpen, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_maskcorrected_FSC', 'plot_sharpen');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    filter_mode = fn_parser.Results.filter_mode;

    if ischar(filter_mode)
        filter_mode = str2double(filter_mode);
    end

    try
        validateattributes(filter_mode, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>=', 1, '<=', 2}, ...
            'subtom_maskcorrected_FSC', 'filter_mode');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    filter_threshold = fn_parser.Results.filter_threshold;

    if ischar(filter_threshold)
        filter_threshold = str2double(filter_threshold);
    end

    if filter_mode == 1
        try
            validateattributes(filter_threshold, {'numeric'}, ...
                {'scalar', 'nonnan', '>=', 0, '<=', 1}, ...
                'subtom_maskcorrected_FSC', 'filter_threshold');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    else
        try
            validateattributes(filter_threshold, {'numeric'}, ...
                {'scalar', 'nonnan', 'integer', 'positive'}, ...
                'subtom_maskcorrected_FSC', 'filter_threshold');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    pixelsize = fn_parser.Results.pixelsize;

    if ischar(pixelsize)
        pixelsize = str2double(pixelsize);
    end

    try
        validateattributes(pixelsize, {'numeric'}, ...
            {'scalar', 'nonnan', '>=', 0}, ...
            'subtom_maskcorrected_FSC', 'pixelsize');

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
            'subtom_maskcorrected_FSC', 'nfold');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    rand_threshold = fn_parser.Results.rand_threshold;

    if ischar(rand_threshold)
        rand_threshold = str2double(rand_threshold);
    end

    try
        validateattributes(rand_threshold, {'numeric'}, ...
            {'scalar', 'nonnan', '>=', 0, '<=', 1}, ...
            'subtom_maskcorrected_FSC', 'rand_threshold');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    b_factor = fn_parser.Results.b_factor;

    if ischar(b_factor)
        b_factor = str2double(b_factor);
    end

    try
        validateattributes(b_factor, {'numeric'}, ...
            {'scalar', 'nonnan', '<=', 0}, ...
            'subtom_maskcorrected_FSC', 'b_factor');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    box_gaussian = fn_parser.Results.box_gaussian;

    if ischar(box_gaussian)
        box_gaussian = str2double(box_gaussian);
    end

    try
        validateattributes(box_gaussian, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', 'odd'}, ...
            'subtom_maskcorrected_FSC', 'box_gaussian');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % This is the filename we use to check against all the box sizes for correct
    % sizing.
    check_fn = ref_a_fn;

    % Read in the references.
    ref_a = getfield(tom_emread(ref_a_fn), 'Value');
    ref_b = getfield(tom_emread(ref_b_fn), 'Value');

    % Get the box size from the first reference.
    box_size = size(ref_a);

    % Make sure the box sizes of both references are equal.
    if ~all(size(ref_b) == box_size)
        try
            error('subTOM:volDimError', ...
                'maskcorrected_FSC:%s and %s are not same size.', ...
                ref_b_fn, check_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Read the FSC mask
    if strcmpi(fsc_mask_fn, 'none')
        fsc_mask = ones(box_size);
    else
        fsc_mask = getfield(tom_emread(fsc_mask_fn), 'Value');
    end

    if ~all(size(fsc_mask) == box_size)
        try
            error('subTOM:volDimError', ...
                'maskcorrected_FSC:%s and %s are not same size.', ...
                fsc_mask_fn, check_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Apply symmetry
    if nfold > 1
        ref_a = tom_symref(ref_a, nfold);
        ref_b = tom_symref(ref_b, nfold);
    end

    % Create "unmasked" references to determine FSC phase-randomization cutoffs
    % RELION uses the true unmasked FSC to determine this, but maybe a bad idea
    % for continuous densities like could occur with any lattice structure.
    %unmasked_ref_a = tom_spheremask(ref_a, ...
    %    (length(ref_a) / 2) - 2, 1);

    %unmasked_ref_b = tom_spheremask(ref_b, ...
    %    (length(ref_b) / 2) - 2, 1);

    unmasked_ref_a = ref_a;
    unmasked_ref_b = ref_b;

    % Apply masks
    masked_ref_a = ref_a .* fsc_mask;
    masked_ref_b = ref_b .* fsc_mask;

    % Fourier transforms of unmasked and masked structures
    ref_a_fft = fftshift(fftn(ref_a));
    ref_b_fft = fftshift(fftn(ref_b));
    unmasked_ref_a_fft = fftshift(fftn(unmasked_ref_a));
    unmasked_ref_b_fft = fftshift(fftn(unmasked_ref_b));
    masked_ref_a_fft = fftshift(fftn(masked_ref_a));
    masked_ref_b_fft = fftshift(fftn(masked_ref_b));

    % Calculate pixel distance array
    cartesian_origin = floor(box_size(1) / 2);
    cart_start = -cartesian_origin;
    cart_end = cart_start + box_size(1) - 1;
    [cart_x, cart_y, cart_z] = ndgrid(cart_start:cart_end);
    radii = sqrt(cart_x.^2 + cart_y.^2 + cart_z.^2);

    % Initial calculations for FSC
    % Complex conjugate product - corresponds to the Cross-Correlation Function
    unmasked_ccf = unmasked_ref_a_fft .* conj(unmasked_ref_b_fft);

    % Intensity of A
    unmasked_intensity_a = unmasked_ref_a_fft .* ...
        conj(unmasked_ref_a_fft);

    % Intensity of B
    unmasked_intensity_b = unmasked_ref_b_fft .* ...
        conj(unmasked_ref_b_fft);

    masked_ccf = masked_ref_a_fft .* conj(masked_ref_b_fft);
    masked_intensity_a = masked_ref_a_fft .* conj(masked_ref_a_fft);
    masked_intensity_b = masked_ref_b_fft .* conj(masked_ref_b_fft);

    %% Sum Fourier shells
    % Number of Fourier Shells, hardcoded to half the box-size plus one for the
    % DC (average / infinite wavelength / zero-frequency) component.
    n_shells = cartesian_origin + 1;

    % Normal shell sums
    shell_idxs = arrayfun(@(x) find(round(radii) == (x - 1)), 1:n_shells, ...
        'UniformOutput', false);

    unmasked_ccf_1d = arrayfun(@(x) ...
        sum(real(unmasked_ccf(shell_idxs{x}))), 1:n_shells);

    unmasked_intensity_a_1d = arrayfun(@(x) ...
        sum(unmasked_intensity_a(shell_idxs{x})), 1:n_shells);

    unmasked_intensity_b_1d = arrayfun(@(x) ...
        sum(unmasked_intensity_b(shell_idxs{x})), 1:n_shells);

    masked_ccf_1d = arrayfun(@(x) ...
        sum(real(masked_ccf(shell_idxs{x}))), 1:n_shells);

    masked_intensity_a_1d = arrayfun(@(x) ...
        sum(masked_intensity_a(shell_idxs{x})), 1:n_shells);

    masked_intensity_b_1d = arrayfun(@(x) ...
        sum(masked_intensity_b(shell_idxs{x})), 1:n_shells);

    %% Calculate Normal FSC
    unmasked_fsc = unmasked_ccf_1d ./ ...
        sqrt(unmasked_intensity_a_1d .* unmasked_intensity_b_1d);

    masked_fsc = masked_ccf_1d ./ ...
        sqrt(masked_intensity_a_1d .* masked_intensity_b_1d);

    %% Calculate initial steps of Randomized FSC calculation.
    rand_cutoffs = find(unmasked_fsc < rand_threshold, 2, 'first');

    % Sometimes there is a one pixel shift of the unmasked reweighted
    % references that really throws off the calculations and so this is a small
    % work around to make sure we don't use this artifact as the cutoff.
    rand_cutoffs = rand_cutoffs(rand_cutoffs > 1);

    % Handle the case in which the FSC never falls below the threshold.
    if isempty(rand_cutoffs)
        fprintf(2, 'Unmasked FSC never fell below rand_threshold!');
        rand_cutoff = 0;
    else
        rand_cutoff = rand_cutoffs(1);
    end

    % If the FSC never fell below the threshold we skip the phase randomization
    % since it takes a bit of time to calculate.
    if rand_cutoff
        fprintf(1, 'Phase Randomization at Fourier Pixel: %d\n', rand_cutoff);

        % Because the map needs to stay centro-symmetric we have to do some ugly
        % code to randomize the phases and this depends on whether or not the
        % box size is odd or even since this affects the number of unique
        % frequencies in the Fourier transform.

        % This should be the indices in the Fourier Transform that belong to a
        % unique half, and special care needs to be taken for one-half of the
        % X-axis.
        rand_idxs = find(round(radii) > (rand_cutoff - 1) & ...
            (cart_x < 0 | cart_x == 0 & cart_y < 0))';

        % This should be the indices that belond to the centro-symmetric version
        % of the indices above.
        sym_rand_idxs = find(round(radii) > (rand_cutoff - 1) & ...
            (cart_x > 0 | cart_x == 0 & cart_y > 0))';

        % Split phases and amplitudes of high resolution data
        ref_a_phase = angle(ref_a_fft);
        ref_b_phase = angle(ref_b_fft);
        ref_a_amplitude = abs(ref_a_fft);
        ref_b_amplitude = abs(ref_b_fft);

        % Randomize phases
        rng('shuffle');
        rand_a_phase = ref_a_phase;
        rand_b_phase = ref_b_phase;

        % The phases from angle are in the range -pi to pi
        rand_a_phase(rand_idxs) = (rand(1, numel(rand_idxs)) ...
            .* (2.0 * pi)) - pi;

        rand_b_phase(rand_idxs) = (rand(1, numel(rand_idxs)) ...
            .* (2.0 * pi)) - pi;

        % This is the ugly code that places the randomized phases in their
        % centrosymmetric counterpart places. The negative is because of
        % Hermitian symmetry of the Fourier Transform.
        if mod(box_size(1), 2) == 0
            sym_rand_a_phase = circshift(flip(rand_a_phase, 1), 1, 1);
            sym_rand_a_phase = circshift(flip(sym_rand_a_phase, 2), 1, 2);
            sym_rand_a_phase = -circshift(flip(sym_rand_a_phase, 3), 1, 3);

            sym_rand_b_phase = circshift(flip(rand_b_phase, 1), 1, 1);
            sym_rand_b_phase = circshift(flip(sym_rand_b_phase, 2), 1, 2);
            sym_rand_b_phase = -circshift(flip(sym_rand_b_phase, 3), 1, 3);
        else
            sym_rand_a_phase = -flip(flip(flip(rand_a_phase, 1), 2), 3);
            sym_rand_b_phase = -flip(flip(flip(rand_b_phase, 1), 2), 3);
        end

        % Set the centrosymmetric phase values
        rand_a_phase(sym_rand_idxs) = sym_rand_a_phase(sym_rand_idxs);
        rand_b_phase(sym_rand_idxs) = sym_rand_b_phase(sym_rand_idxs);

        % Apply randomized phases to reference FTs
        rand_a_fft = ref_a_amplitude .* exp(rand_a_phase * i);
        rand_b_fft = ref_b_amplitude .* exp(rand_b_phase * i);

        % Generate phase-randomized real-space maps
        rand_a = ifftn(ifftshift(rand_a_fft), 'symmetric');
        rand_b = ifftn(ifftshift(rand_b_fft), 'symmetric');

        % Apply masks
        masked_rand_a = rand_a .* fsc_mask;
        masked_rand_b = rand_b .* fsc_mask;

        % Fourier transforms of masked structures
        masked_rand_a_fft = fftshift(fftn(masked_rand_a));
        masked_rand_b_fft = fftshift(fftn(masked_rand_b));

        % Initial calculations for phase-randomized FSC
        rand_masked_ccf = masked_rand_a_fft .* conj(masked_rand_b_fft);
        rand_masked_intensity_a = masked_rand_a_fft .* conj(masked_rand_a_fft);
        rand_masked_intensity_b = masked_rand_b_fft .* conj(masked_rand_b_fft);

        % Phase-randomized shell arrays
        rand_masked_ccf_1d = arrayfun(@(x) ...
            sum(real(rand_masked_ccf(shell_idxs{x}))), 1:n_shells);

        rand_masked_intensity_a_1d = arrayfun(@(x) ...
            sum(rand_masked_intensity_a(shell_idxs{x})), 1:n_shells);

        rand_masked_intensity_b_1d = arrayfun(@(x) ...
            sum(rand_masked_intensity_b(shell_idxs{x})), 1:n_shells);

        % Phase-randomized FSC
        rand_fsc = real(rand_masked_ccf_1d) ./ ...
            sqrt(rand_masked_intensity_a_1d .* rand_masked_intensity_b_1d);

        % Mask-corrected FSC
        corrected_fsc = masked_fsc;

        % We offset the joining of the curves by 2 pixels because otherwise
        % there is an edge artifact at the exact randomization cutoff.
        corrected_fsc((rand_cutoff + 2):end) = ...
            (masked_fsc((rand_cutoff + 2):end) - ...
            rand_fsc(rand_cutoff + 2:end)) ./ ...
            (1 - rand_fsc((rand_cutoff + 2):end));

    else

        % Handle the case when we have skipped the phase randomization.
        corrected_fsc = masked_fsc;
    end

    % Calculate FSCs at points of interest
    for fsc_poi = [0.5, 0.143]

        % Find point after value
        x2 = find(corrected_fsc <= fsc_poi, 1);

        % Handle the case in low binnings when the FSC never falls below
        % threshold
        if isempty(x2)
            fprintf(2, 'FSC did not fall below %f!\n', fsc_poi);
            resolution_fp = find(...
                corrected_fsc == min(corrected_fsc(:)), 1, 'first') - 1;

            resolution_a = (box_size(1) * pixelsize) / resolution_fp;
            fsc_value = min(corrected_fsc(:));
            fprintf(1, 'Min. FSC = %f at %f Angstroms\n', fsc_value, ...
                resolution_a);

        elseif x2 == 1
            fprintf(2, 'FSC immediately fell below %f!\n', fsc_poi);
            x3 = find(corrected_fsc > fsc_poi, 1);

            if isempty(x3)
                try
                    error('subTOM:FSCError', ...
                        'maskcorrected_FSC: FSC never above %f!\n', fsc_poi);

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            x4 = find(corrected_fsc(x3:end) <= fsc_poi, 1);

            if isempty(x4)
                fprintf(2, 'FSC then did not fall below %f!\n', fsc_poi);
                resolution_fp = find(corrected_fsc == ...
                    min(corrected_fsc(x3:end)), 1, 'first') - 1;

                resolution_a = (box_size(1) * pixelsize) / resolution_fp;
                fsc_value = min(corrected_fsc(x3:end));
                fprintf(1, 'Min. FSC = %f at %f Angstroms\n', fsc_value, ...
                    resolution_a);
            end
        else
            y2 = corrected_fsc(x2);

            % Find point before value.
            x1 = find(corrected_fsc(1:x2) > fsc_poi, 1, 'last');
            y1 = corrected_fsc(x1);

            % Calculate the slope.
            m = (y2 - y1) / (x2 - x1);

            % Resolution in Fourier Pixels.
            resolution_fp = ((fsc_poi - y1) / m) + x1 - 1;

            % Resolution in Angstroms
            resolution_a = (box_size(1) * pixelsize) / resolution_fp;

            % Write out resolution
            fprintf('FSC = %f at %f\n', fsc_poi, resolution_a);
        end
    end

    % Plot corrected FSC
    if plot_fsc
        fsc_fig = figure();
    else
        fsc_fig = figure('Visible', 'off');
    end

    fsc_axes = axes(fsc_fig);
    fsc_xrange = [0:cartesian_origin] ./ (box_size(1) * pixelsize);
    fsc_xticks = [0:3:cartesian_origin] ./ (box_size(1) * pixelsize);
    fsc_resolutions = 1 ./ fsc_xticks;
    fsc_xlabels = arrayfun(@(x) sprintf('%6.2f', x), fsc_resolutions, ...
        'UniformOutput', 0);

    fsc_yticks = [0, 0.143, 0.5, 1.0];
    fsc_ylabels = arrayfun(@(x) sprintf('%6.3f', x), fsc_yticks, ...
        'UniformOutput', 0);

    plot(fsc_axes, fsc_xrange, unmasked_fsc, 'LineStyle', ':', ...
        'Color', 'b', 'DisplayName', 'Unmasked FSC');

    hold(fsc_axes, 'on');

    plot(fsc_axes, fsc_xrange, masked_fsc, 'LineStyle', '--', ...
        'Color', 'b', 'DisplayName', 'Masked FSC');

    plot(fsc_axes, fsc_xrange, rand_fsc, 'LineStyle', '-.', ...
        'Color', 'b', 'DisplayName', 'Phase Randomized FSC');

    plot(fsc_axes, fsc_xrange, corrected_fsc, 'LineStyle', '-', ...
        'Color', 'b', 'DisplayName', 'Corrected FSC');

    title(fsc_axes, sprintf('Final Resolution = %6.2f \x212B', resolution_a));
    ylabel(fsc_axes, 'Fourier Shell Correlation [arb. unit]');
    xlabel(fsc_axes, sprintf('Resolution [\x212B]'));
    xticks(fsc_axes, fsc_xticks);
    xticklabels(fsc_axes, fsc_xlabels);
    fsc_axes.XTickLabelRotation = 45;
    yticks(fsc_axes, fsc_yticks);
    yticklabels(fsc_axes, fsc_ylabels);
    grid(fsc_axes, 'on');
    legend(fsc_axes, 'Location', 'southoutside', 'Orientation', 'horizontal');
    legend('boxoff');
    set(fsc_fig, 'PaperPositionMode', 'auto');
    set(fsc_fig, 'Position', [0, 0, 800, 600]);
    saveas(fsc_fig, sprintf('%s_FSC', output_fn_prefix), 'fig');
    saveas(fsc_fig, sprintf('%s_FSC', output_fn_prefix), 'pdf');
    saveas(fsc_fig, sprintf('%s_FSC', output_fn_prefix), 'png');

    if ~plot_fsc
        close(fsc_fig);
    end

    if do_sharpen == 1

        if box_gaussian ~= 0
            smooth_ref_a = subtom_smooth_box_edge(ref_a, ...
                box_gaussian);

            smooth_ref_b = subtom_smooth_box_edge(ref_b, ...
                box_gaussian);

            ref = (smooth_ref_a + smooth_ref_b) ./ 2;
        else
            ref = (ref_a + ref_b) ./ 2;
        end

        % Write out reference
        ref_fn = sprintf('%s_unsharpref.em', output_fn_prefix);
        tom_emwrite(ref_fn, -ref);
        subtom_check_em_file(ref_fn, -ref);

        % Sharpen reference
        sharp_ref = subtom_sharpen('reference', ref, 'b_factor', b_factor, ...
            'fsc', corrected_fsc, 'pixelsize', pixelsize, ...
            'filter_mode', filter_mode, ...
            'filter_threshold', filter_threshold, ...
            'plot_sharpen', plot_sharpen, 'output_fn_prefix', output_fn_prefix);

        % Write out sharpened reference
        sharp_ref_fn = sprintf('%s_finalsharpref_%d.em', ...
            output_fn_prefix, (b_factor * -1));

        tom_emwrite(sharp_ref_fn, -sharp_ref);
        subtom_check_em_file(sharp_ref_fn, -sharp_ref);

        if (do_reweight == 1)
            filter_a = getfield(tom_emread(filter_a_fn), 'Value');

            if ~all(size(filter_a) == box_size)
                try
                    error('subTOM:volDimError', ...
                        'maskcorrected_FSC:%s and %s are not same size.', ...
                        filter_a_fn, check_fn);

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            % Find non_zero parts of the filter
            non_zero = filter_a ~= 0;

            % Reweight Fourier transform
            reweigh_ref_a_fft = ref_a_fft;
            reweigh_ref_a_fft(non_zero) = (...
                reweigh_ref_a_fft(non_zero) ./ filter_a(non_zero));

            % Zero outside frequencies
            reweigh_ref_a_fft = reweigh_ref_a_fft .* non_zero;

            % Inverse FFT
            reweigh_ref_a = ifftn(ifftshift(reweigh_ref_a_fft), ...
                'symmetric');

            % Read in filter
            filter_b = getfield(tom_emread(filter_b_fn), 'Value');

            if ~all(size(filter_b) == box_size)
                try
                    error('subTOM:volDimError', ...
                        'maskcorrected_FSC:%s and %s are not same size.', ...
                        filter_b_fn, check_fn);

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            % Find non_zero parts of the filter
            non_zero = filter_b ~= 0;

            % Reweight Fourier transform
            reweigh_ref_b_fft = ref_b_fft;
            reweigh_ref_b_fft(non_zero) = (...
                reweigh_ref_b_fft(non_zero) ./ filter_b(non_zero));

            % Zero outside frequencies
            reweigh_ref_b_fft = reweigh_ref_b_fft .* non_zero;

            % Inverse FFT
            reweigh_ref_b = ifftn(ifftshift(reweigh_ref_b_fft), ...
                'symmetric');

            if box_gaussian ~= 0
                smooth_reweigh_a = subtom_smooth_box_edge(...
                    reweigh_ref_a, box_gaussian);

                smooth_reweigh_b = smooth_box_edge(...
                    reweigh_ref_b, box_gaussian);

                reweigh_ref = (smooth_reweigh_a + ...
                    smooth_reweigh_b) ./ 2;
            else
                reweigh_ref = (reweigh_ref_a + ...
                    reweigh_ref_b) ./ 2;
            end

            % Write out reference
            reweigh_ref_fn = sprintf('%s_unsharpref_reweight.em', ...
                output_fn_prefix);

            tom_emwrite(reweigh_ref_fn, -reweigh_ref);
            check_em_file(reweigh_ref_fn, -reweigh_ref);

            % Sharpen reference
            sharp_reweigh = subtom_sharpen('reference', reweigh_ref, ...
                'b_factor', b_factor, 'fsc', corrected_fsc, ...
                'pixelsize', pixelsize, 'filter_mode', filter_mode, ...
                'filter_threshold', filter_threshold, ...
                'plot_sharpen', plot_sharpen, ...
                'output_fn_prefix', output_fn_prefix);

            % Write out sharpened reference
            sharp_reweigh_fn = sprintf(...
                '%s_finalsharpref_%d_reweight.em', output_fn_prefix, ...
                (b_factor * -1));

            tom_emwrite(sharp_reweigh_fn, -sharp_reweigh);
            subtom_check_em_file(sharp_reweigh_fn, -sharp_reweigh);
        end
    end
end
