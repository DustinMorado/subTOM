function maskcorrected_FSC(reference_A_fn, reference_B_fn, FSC_mask_fn, ...
    output_fn_prefix, pixelsize, nfold, rand_threshold, plot_fsc, ...
    do_sharpen, B_factor, box_gaussian, filter_mode, filter_threshold, ...
    plot_sharpen, do_reweight, filter_A_fn, filter_B_fn)
% MASKCORRECTED_FSC calculates "mask-corrected" FSC and sharpened volumes.
%     MASKCORRECTED_FSC(...
%         REFERENCE_A_FN, ...
%         REFERENCE_B_FN, ...
%         FSC_MASK_FN, ...
%         OUTPUT_FN_PREFIX, ...
%         PIXELSIZE, ...
%         NFOLD, ...
%         RAND_THRESHOLD, ...
%         PLOT_FSC, ...
%         DO_SHARPEN, ...
%         B_FACTOR, ...
%         BOX_GAUSSIAN, ...
%         FILTER_MODE, ...
%         FILTER_THRESHOLD, ...
%         PLOT_SHARPEN, ...
%         DO_REWEIGHT, ...
%         FILTER_A_FN, ...
%         FILTER_B_FN)
%
%     Takes in two references REFERENCE_A_FN and REFERENCE_B_FN and a FSC mask
%     FSC_MASK_FN and calculates a "mask-corrected" FSC. This works by
%     randomizing the structure factor phases beyond the point where the
%     unmasked FSC curve falls below a given threshold (by default 0.8) and
%     calculating an additional FSC between these phase randomized maps.  This
%     allows for the determination of the extra correlation caused by effects of
%     the mask, which is then subtracted from the normal masked FSC curves. The
%     curve will be saved as a Matlab figure and a PDF file, and if PLOT_FSC is
%     true it will also be displayed.
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
%
% Example:
%     MASKCORRECTED_FSC('even/ref/ref_1.em', 'odd/ref/ref_1.em', ...
%         'fscmask.em', 'ref_1', 1.177, 2, 0.8, 1, 1, -100, 1, 1, 0.143, 1, ...
%         'ctffilter_even.em', 'ctffilter_odd.em')
%
%     Would calculate the mask-corrected FSC between the two maps with two-fold
%     nfold and under the mask. The FSC curve and curve used in sharpening will
%     be displayed. The map will be filtered using the mask-corrected curve
%     where it falls below 0.143. The map will also be reweighted using the
%     given Fourier reweighting volumes. The function will write out the
%     following files:
%         * 'ref_1_unsharpref.em' - The joined map with no sharpening applied
%         * 'ref_1_finalsharpref_100.em' - The joined map sharpened with a
%             B-Factor of -100.
%         * 'ref_1_finalsharpref_100_reweight.em' - The joined map sharpened
%             with a B-Factor of -100 and reweighted.
%         * 'ref_1_FSC.fig' - The unmasked, masked, phase-randomized, and
%             mask-corrected FSC curves in Matlab figure format.
%         * 'ref_1_FSC.pdf' - The unmasked, masked, phase-randomized, and
%             mask-corrected FSC curves in PDF format.
%         * 'ref_1_sharp.fig' - The curve  used to FSC-filter and sharpen the
%             map in Matlab figure format.
%         * 'ref_1_sharp.pdf' - The curve  used to FSC-filter and sharpen the
%             map in PDF format.

% DRM 12-2017
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% reference_A_fn = 'even/ref/ref_1.em';
% reference_B_fn = 'odd/ref/ref_1.em';
% FSC_mask_fn = 'fscmask.em';
% output_fn_prefix = 'ref_1';
% pixelsize = 1.177;
% nfold = 1;
% rand_threshold = 0.8;
% plot_fsc = 1;
% do_sharpen = 1;
% B_factor = -100;
% box_gaussian = 3;
% filter_mode = 1;
% filter_threshold = 0.143;
% plot_sharpen = 0;
% do_reweight = 1;
% filter_A_fn = 'ctffilter_even.em';
% filter_B_fn = 'ctffilter_odd.em';
%##############################################################################%
    % Evaluate numeric inputs
    if ischar(pixelsize)
        pixelsize = str2double(pixelsize);
    end

    if ischar(nfold)
        nfold = str2double(nfold);
    end

    if ischar(rand_threshold)
        rand_threshold = str2double(rand_threshold);
    end

    if ischar(plot_fsc)
        plot_fsc = str2double(plot_fsc);
    end

    plot_fsc = logical(plot_fsc);

    if ischar(do_sharpen)
        do_sharpen = str2double(do_sharpen);
    end

    do_sharpen = logical(do_sharpen);

    if ischar(B_factor)
        B_factor = str2double(B_factor);
    end

    if B_factor > 0
        B_factor = B_factor * -1;
    end

    if ischar(box_gaussian)
        box_gaussian = str2double(box_gaussian);
    end

    if box_gaussian > 0 && mod(box_gaussian, 2) == 0
        box_gaussian = box_gaussian + 1;
    end

    if ischar(filter_mode)
        filter_mode = str2double(filter_mode);
    end

    if ischar(filter_threshold)
        filter_threshold = str2double(filter_threshold);
    end

    if ischar(plot_sharpen)
        plot_sharpen = str2double(plot_sharpen);
    end

    plot_sharpen = logical(plot_sharpen);

    if ischar(do_reweight)
        do_reweight = str2double(do_reweight);
    end

    do_reweight = logical(do_reweight);

    % Read the references
    reference_A = getfield(tom_emread(reference_A_fn), 'Value');
    reference_B = getfield(tom_emread(reference_B_fn), 'Value');

    % Read the FSC mask
    if strcmp(FSC_mask_fn, 'none')
        FSC_mask = ones(size(reference_A));
    else
        FSC_mask = getfield(tom_emread(FSC_mask_fn), 'Value');
    end

    % Apply symmetry
    if nfold > 1
        reference_A = tom_symref(reference_A, nfold);
        reference_B = tom_symref(reference_B, nfold);
    end

    % Create "unmasked" references to determine FSC phase-randomization cutoffs
    % RELION uses the true unmasked FSC to determine this, but maybe a bad idea
    % for continuous densities like could occur with any lattice structure.
    %unmasked_reference_A = tom_spheremask(reference_A, ...
    %    (length(reference_A) / 2) - 2, 1);

    %unmasked_reference_B = tom_spheremask(reference_B, ...
    %    (length(reference_B) / 2) - 2, 1);

    unmasked_reference_A = reference_A;
    unmasked_reference_B = reference_B;

    % Apply masks
    masked_reference_A = reference_A .* FSC_mask;
    masked_reference_B = reference_B .* FSC_mask;

    % Fourier transforms of unmasked and masked structures
    reference_A_fft = fftshift(fftn(reference_A));
    reference_B_fft = fftshift(fftn(reference_B));
    unmasked_reference_A_fft = fftshift(fftn(unmasked_reference_A));
    unmasked_reference_B_fft = fftshift(fftn(unmasked_reference_B));
    masked_reference_A_fft = fftshift(fftn(masked_reference_A));
    masked_reference_B_fft = fftshift(fftn(masked_reference_B));

    % Calculate pixel distance array
    boxsize = size(reference_A, 1);
    cartesian_origin = floor(boxsize / 2);
    [cart_x, cart_y, cart_z] = ndgrid(...
        -cartesian_origin:boxsize - (cartesian_origin + 1));
    radii = sqrt(cart_x.^2 + cart_y.^2 + cart_z.^2);
    clear cartesian_origin cart_x cart_y cart_z

    % Initial calculations for FSC
    % Complex conjugate product - corresponding to the Cross-Correlation
    % Function
    unmasked_CCF = unmasked_reference_A_fft .* conj(unmasked_reference_B_fft);

    % Intensity of A
    unmasked_intensity_A =    unmasked_reference_A_fft ...
                           .* conj(unmasked_reference_A_fft);

    % Intensity of B
    unmasked_intensity_B =    unmasked_reference_B_fft ...
                           .* conj(unmasked_reference_B_fft);

    % Complex conjugate product - corresponding to the Cross-Correlation
    % Function
    masked_CCF = masked_reference_A_fft .* conj(masked_reference_B_fft);

    % Intensity of A
    masked_intensity_A = masked_reference_A_fft .* conj(masked_reference_A_fft);

    % Intensity of B
    masked_intensity_B = masked_reference_B_fft .* conj(masked_reference_B_fft);

    %% Sum Fourier shells
    tic
    % Number of Fourier Shells, hardcoded to half the box-size
    n_shells = boxsize / 2;

    % Normal shell arrays
    % Complex conjugate product - corresponding to the Cross-Correlation
    % Function
    unmasked_CCF_array = zeros(1, n_shells);

    % Intensity of A
    unmasked_intensity_A_array = zeros(1, n_shells);

    % Intensity of B
    unmasked_intensity_B_array = zeros(1, n_shells);

    % Complex conjugate product - corresponding to the Cross-Correlation
    % Function
    masked_CCF_array = zeros(1, n_shells);

    % Intensity of A
    masked_intensity_A_array = zeros(1, n_shells);

    % Intensity of B
    masked_intensity_B_array = zeros(1, n_shells);

    % Precalculate shell masks
    shell_mask = cell(n_shells, 1);
    for shell_idx = 1:n_shells
        % Shells are set to one pixel size
        shell_start = (shell_idx - 1);
        shell_end = shell_idx;

        % Generate shell mask
        temp_mask = (radii >= shell_start) & (radii < shell_end);

        % Write out linearized shell mask
        shell_mask{shell_idx} = temp_mask(:);
    end

    % Sum numbers for each shell
    for shell_idx = 1:n_shells
        % Write normal outputs
        unmasked_CCF_array(shell_idx) = sum(...
            unmasked_CCF(shell_mask{shell_idx}));

        unmasked_intensity_A_array(shell_idx) = sum(...
            unmasked_intensity_A(shell_mask{shell_idx}));

        unmasked_intensity_B_array(shell_idx) = sum(...
            unmasked_intensity_B(shell_mask{shell_idx}));

        masked_CCF_array(shell_idx) = sum(masked_CCF(shell_mask{shell_idx}));
        masked_intensity_A_array(shell_idx) = sum(...
            masked_intensity_A(shell_mask{shell_idx}));

        masked_intensity_B_array(shell_idx) = sum(...
            masked_intensity_B(shell_mask{shell_idx}));
    end

    %% Calculate Normal FSC
    unmasked_FSC = real(unmasked_CCF_array) ./ ...
        sqrt(unmasked_intensity_A_array .* unmasked_intensity_B_array);

    masked_FSC = real(masked_CCF_array) ./ ...
        sqrt(masked_intensity_A_array .* masked_intensity_B_array);

    %% Calculate initial steps of Randomized FSC calculation
    randomization_cutoff = find(unmasked_FSC < rand_threshold, 1, 'first');

    % Handle the case when the curve never falls below the threshold
    if isempty(randomization_cutoff)
        randomization_cutoff = n_shells;
    end

    % Sometimes there is a one pixel shift of the unmasked reweighted
    % references that really throws off the calculations and so this is a small
    % work around to make sure we don't use this artifact as the cutoff.
    if randomization_cutoff <= 1
        randomization_cutoff = find(unmasked_FSC < rand_threshold, 2, 'first');
        randomization_cutoff = randomization_cutoff(end);
    end

    fprintf('Phase Randomization at Fourier Pixel: %d\n', randomization_cutoff);

    % Determine for phase randomization
    randomization_mask = (radii > randomization_cutoff);
    randomization_idxs = find(randomization_mask);

    % Split phases and amplitudes of high resolution data
    reference_A_phase = angle(reference_A_fft);
    reference_B_phase = angle(reference_B_fft);
    reference_A_amplitude = abs(reference_A_fft);
    reference_B_amplitude = abs(reference_B_fft);

    % Randomize phases
    rng('shuffle');
    randomized_A_phase = reference_A_phase;
    randomized_B_phase = reference_B_phase;
    randomized_A_phase(randomization_idxs) = rand(...
        numel(randomization_idxs), 1) .* (2.0 * pi);

    randomized_B_phase(randomization_idxs) = rand(...
        numel(randomization_idxs), 1) .* (2.0 * pi);

    % Apply randomized phases to reference FTs
    randomized_A_fft =    reference_A_amplitude ...
                       .* exp(randomized_A_phase * sqrt(-1));

    randomized_B_fft =    reference_B_amplitude ...
                       .* exp(randomized_B_phase * sqrt(-1));

    % Generate phase-randomized real-space maps
    randomized_A = ifftn(ifftshift(randomized_A_fft));
    randomized_B = ifftn(ifftshift(randomized_B_fft));

    % Apply masks
    masked_randomized_A = randomized_A .* FSC_mask;
    masked_randomized_B = randomized_B .* FSC_mask;

    % Fourier transforms of masked structures
    masked_randomized_A_fft = fftshift(fftn(masked_randomized_A));
    masked_randomized_B_fft = fftshift(fftn(masked_randomized_B));

    % Initial calculations for phase-randomized FSC
    % Complex conjugate product - corresponding to the Cross-Correlation
    % Function
    randomized_CCF = masked_randomized_A_fft .* conj(masked_randomized_B_fft);

    % Intensity of A
    randomized_intensity_A =    masked_randomized_A_fft ...
                             .* conj(masked_randomized_A_fft);

    % Intensity of B
    randomized_intensity_B =    masked_randomized_B_fft ...
                             .* conj(masked_randomized_B_fft);

    % Phase-randomized shell arrays
    % Complex conjugate product - corresponding to the Cross-Correlation
    % Function
    randomized_CCF_array = zeros(1, n_shells);

    % Intensity of A
    randomized_intensity_A_array = zeros(1, n_shells);

    % Intensity of B
    randomized_intensity_B_array = zeros(1, n_shells);

    % Sum numbers for each shell
    for shell_idx = 1:n_shells
        % Write phase randomized outputs
        randomized_CCF_array(shell_idx) = sum(...
            randomized_CCF(shell_mask{shell_idx}));

        randomized_intensity_A_array(shell_idx) = sum(...
            randomized_intensity_A(shell_mask{shell_idx}));

        randomized_intensity_B_array(shell_idx) = sum(...
            randomized_intensity_B(shell_mask{shell_idx}));
    end
    toc

    % Phase-randomized FSC
    randomized_FSC = real(randomized_CCF_array) ./ ...
        sqrt(randomized_intensity_A_array .* randomized_intensity_B_array);

    % Mask-corrected FSC
    corrected_FSC = masked_FSC;
    corrected_FSC((randomization_cutoff + 2):end) = (...
        masked_FSC((randomization_cutoff + 2):end) - ...
        randomized_FSC(randomization_cutoff + 2:end)) ./ ...
        (1 - randomized_FSC((randomization_cutoff + 2):end));

    % Calculate FSCs at points of interest
    for FSC_POI = [0.5, 0.143]
        % Find point after value
        x2 = find(corrected_FSC <= FSC_POI, 1);

        % Handle the case in low binnings when the FSC never falls below
        % threshold
        if isempty(x2)
            fprintf('FSC did not fall below %f!\n', FSC_POI);
            resolution_fp = find(corrected_FSC == min(corrected_FSC(:)));
            resolution_A = (boxsize * pixelsize) / resolution_fp;
            FSC_value = min(corrected_FSC(:));
            fprintf('Min. FSC at %f = %f Angstroms\n', FSC_value, resolution_A);
        else
            y2 = corrected_FSC(x2);

            % Find point before value
            x1 = find(corrected_FSC(1:x2) >= FSC_POI, 1, 'last');
            y1 = corrected_FSC(x1);

            % Slope
            m = (y2 - y1) / (x2 - x1);

            % Resolution in Fourier Pixels
            resolution_fp = ((FSC_POI - y1) / m) + x1;

            % Resolution in Angstroms
            resolution_A = (boxsize * pixelsize) / resolution_fp;

            % Write out resolution
            fprintf('FSC at %f = %f\n', FSC_POI, resolution_A);
        end
    end

    % Plot corrected FSC
    if plot_fsc
        figure();
    else
        figure('Visible', 'off');
    end

    hold(gca, 'on');
    grid on
    axis ([0 n_shells -0.1 1.05]);

    set (gca, 'yTick', [0 0.143 0.5 1.0]);
    plot(1:size(unmasked_FSC, 2), unmasked_FSC, 'LineStyle', ':', ...
        'Color', 'b', 'DisplayName', 'Unmasked FSC');

    plot(1:size(masked_FSC, 2), masked_FSC, 'LineStyle', '--', 'Color', 'b', ...
        'DisplayName', 'Masked FSC');

    plot(1:size(randomized_FSC, 2), randomized_FSC, 'LineStyle', '-.', ...
        'Color', 'b', 'DisplayName', 'Phase Randomized FSC');

    plot(1:size(corrected_FSC, 2),corrected_FSC, 'LineStyle', '-', ...
        'Color', 'b', 'DisplayName', 'Corrected FSC');
    saveas(gcf, sprintf('%s_FSC', output_fn_prefix), 'fig')
    saveas(gcf, sprintf('%s_FSC', output_fn_prefix), 'pdf')

    if ~plot_fsc
        close(gcf);
    end

    if do_sharpen == 1
        if box_gaussian ~= 0
            smoothed_reference_A = smooth_box_edge(reference_A, box_gaussian);
            smoothed_reference_B = smooth_box_edge(reference_B, box_gaussian);
            reference = (smoothed_reference_A + smoothed_reference_B) ./ 2;
        else
            reference = (reference_A + reference_B) ./ 2;
        end

        % Write out reference
        reference_fn = sprintf('%s_unsharpref.em', output_fn_prefix);
        tom_emwrite(reference_fn, -reference);
        check_em_file(reference_fn, -reference);

        % Sharpen reference
        sharpened_reference = sharpen_function(reference, B_factor, ...
            corrected_FSC, pixelsize, filter_mode, filter_threshold, ...
            plot_sharpen, output_fn_prefix);

        % Write out sharpened reference
        sharpened_reference_fn = sprintf('%s_finalsharpref_%d.em', ...
            output_fn_prefix, (B_factor * -1));

        tom_emwrite(sharpened_reference_fn, -sharpened_reference);
        check_em_file(sharpened_reference_fn, -sharpened_reference);

        if (do_reweight == 1)
            % Read in filter
            filter_A = getfield(tom_emread(filter_A_fn), 'Value');

            % Find non_zero parts of the filter
            non_zero = filter_A ~= 0;

            % Reweight Fourier transform
            reweighted_reference_A_fft = reference_A_fft;
            reweighted_reference_A_fft(non_zero) = (...
                reweighted_reference_A_fft(non_zero) ./ filter_A(non_zero));

            % Zero outside frequencies
            reweighted_reference_A_fft = reweighted_reference_A_fft .* non_zero;

            % Inverse FFT
            reweighted_reference_A = ifftn(ifftshift(...
                reweighted_reference_A_fft));

            % Read in filter
            filter_B = getfield(tom_emread(filter_B_fn), 'Value');

            % Find non_zero parts of the filter
            non_zero = filter_B ~= 0;

            % Reweight Fourier transform
            reweighted_reference_B_fft = reference_B_fft;
            reweighted_reference_B_fft(non_zero) = (...
                reweighted_reference_B_fft(non_zero) ./ filter_B(non_zero));

            % Zero outside frequencies
            reweighted_reference_B_fft = reweighted_reference_B_fft .* non_zero;

            % Inverse FFT
            reweighted_reference_B = ifftn(ifftshift(...
                reweighted_reference_B_fft));

            if box_gaussian ~= 0
                smoothed_reweighted_A = smooth_box_edge(...
                    reweighted_reference_A, box_gaussian);

                smoothed_reweighted_B = smooth_box_edge(...
                    reweighted_reference_B, box_gaussian);

                reweighted_reference = (smoothed_reweighted_A + ...
                    smoothed_reweighted_B) ./ 2;
            else
                reweighted_reference = (reweighted_reference_A + ...
                    reweighted_reference_B) ./ 2;
            end

            % Write out reference
            reweighted_reference_fn = sprintf('%s_unsharpref_reweight.em', ...
                output_fn_prefix);

            tom_emwrite(reweighted_reference_fn, -reweighted_reference);
            check_em_file(reweighted_reference_fn, -reweighted_reference);

            % Sharpen reference
            sharpened_reweighted = sharpen_function(reweighted_reference, ...
                B_factor, corrected_FSC, pixelsize, filter_mode, ...
                filter_threshold, plot_sharpen, output_fn_prefix);

            % Write out sharpened reference
            sharpened_reweighted_fn = sprintf(...
                '%s_finalsharpref_%d_reweight.em', output_fn_prefix, ...
                (B_factor * -1));

            tom_emwrite(sharpened_reweighted_fn, -sharpened_reweighted);
            check_em_file(sharpened_reweighted_fn, -sharpened_reweighted);
        end
    end
end % END MASK_CORRECTED_FSC

%##############################################################################%
%                               SMOOTH_BOX_EDGE                                %
%##############################################################################%
function masked_vol = smooth_box_edge(volume, box_gaussian)
% SMOOTH_BOX_EDGE Smooths the edges of a volume.
%     SMOOTH_BOX_EDGE(...
%         VOLUME, ...
%         BOX_GAUSSIAN)
%
% A function to take in a volume and smooth the box edges by masking with a
% smaller box with a gaussian dropoff. The function returns a masked
% volume.
%
% Example:
%     SMOOTH_BOX_EDGE(getfield(tom_emread('file.em'), 'Value'), 3);

% WW 04-2016
    % Get size of volume
    [x, y, z] = size(volume);

    % Initialize box mask
    box_mask = zeros(size(volume));

    % Get start and end indices
    xs = 1 + (2 * box_gaussian);
    xe = x - (2 * box_gaussian);
    ys = 1 + (2 * box_gaussian);
    ye = y - (2 * box_gaussian);
    zs = 1 + (2 * box_gaussian);
    ze = z - (2 * box_gaussian);

    % Generate binary mask
    box_mask(xs:xe, ys:ye, zs:ze) = 1;

    % Smooth binary mask
    smooth_mask = smooth3(box_mask, 'gaussian', box_gaussian, box_gaussian);

    % Return masked volume
    masked_vol = smooth_mask .* volume;
end

%##############################################################################%
%                               SHARPEN_FUNCTION                               %
%##############################################################################%
function sharpened_reference = sharpen_function(reference, B_factor, fsc, ...
    pixelsize, filter_mode, filter_threshold, plot_sharpen, output_fn_prefix)
% SHARPEN_FUNCTION sharpens a density map.
%     SHARPEN_FUNCTION(...
%         REFERENCE, ...
%         B_FACTOR, ...
%         FSC, ...
%         PIXELSIZE, ...
%         FILTER_MODE, ...
%         FILTER_THRESHOLD, ...
%         PLOT_SHARPEN, ...
%         OUTPUT_FN_PREFIX)
%
% See Rosenthal and Henderson, 2003, doi:10.1016/j.jmb.2003.07.013
%
% There are two mode used for low pass filtering. The first uses an FSC
% based threshold (mode 1), i.e. after FSC < 0.143, or a pixel-based
% resolution threhsold (mode 2).

% -WW 06-2015
    if filter_mode == 1
        lowpass = ones(size(fsc));
        cutoff = find(fsc < filter_threshold, 1, 'first');
        if isempty(cutoff)
            cutoff = length(fsc) - 4;
            lowpass(cutoff:(cutoff + 4)) = 0.5 - 0.5 .* ...
                cos(pi .* ((cutoff + 4) - (cutoff:(cutoff + 4))) ./ 4);
        elseif (cutoff + 4) >= length(fsc)
            cutoff = length(fsc) - 4;
            lowpass(cutoff:(cutoff + 4)) = 0.5 - 0.5 .* ...
                cos(pi .* ((cutoff + 4) - (cutoff:(cutoff + 4))) ./ 4);
        else
            lowpass(cutoff:(cutoff + 4)) = 0.5 - 0.5 .* ...
                cos(pi .* ((cutoff + 4) - (cutoff:(cutoff + 4))) ./ 4);
            lowpass((cutoff + 5):end) = 0;
        end

        fsc_lowpass = fsc .* lowpass;
    elseif filter_mode == 2
        lowpass = ones(size(fsc));
        cutoff = filter_threshold;
        if isempty(cutoff)
            cutoff = length(fsc) - 4;
            lowpass(cutoff:(cutoff + 4)) = 0.5 - 0.5 .* ...
                cos(pi .* ((cutoff + 4) - (cutoff:(cutoff + 4))) ./ 4);
        elseif (cutoff + 4) >= length(fsc)
            cutoff = length(fsc) - 4;
            lowpass(cutoff:(cutoff + 4)) = 0.5 - 0.5 .* ...
                cos(pi .* ((cutoff + 4) - (cutoff:(cutoff + 4))) ./ 4);
        else
            lowpass(cutoff:(cutoff + 4)) = 0.5 - 0.5 .* ...
                cos(pi .* ((cutoff + 4) - (cutoff:(cutoff + 4))) ./ 4);
            lowpass((cutoff + 5):end) = 0;
        end

        fsc_lowpass = fsc .* lowpass;
    end

    % Calculate frequency array
    R = 1:size(fsc, 2);
    R = (size(reference, 3) * pixelsize) ./ R;

    % Calculate exponential filter
    exp_filt = exp(-(B_factor ./ (4 .* (R.^2))));

    % Calculate figure of merit
    Cref = sqrt((2 .* fsc_lowpass) ./ (1 + fsc_lowpass));

    % Calculate signal-weighted sharpening filter
    sharp_filt = vector_to_volume(exp_filt .* Cref);

    % Apply sharpening
    ft_ref = fftshift(fftn(reference));
    ft_filt_ref = ft_ref .* sharp_filt;
    sharpened_reference = real(ifftn(ifftshift(ft_filt_ref)));

    if plot_sharpen
        figure();
    else
        figure('Visible', 'off');
    end

    plot(1:size(fsc, 2), (exp_filt .* Cref));
    saveas(gcf, sprintf('%s_sharp_%d', output_fn_prefix, ...
        (B_factor * -1)), 'fig');

    saveas(gcf, sprintf('%s_sharp_%d', output_fn_prefix, ...
        (B_factor * -1)), 'pdf');

    if ~plot_sharpen
        close(gcf);
    end
end

%##############################################################################%
%                               VECTOR_TO_VOLUME                               %
%##############################################################################%
function polar_volume = vector_to_volume(input_vector)
% VECTOR_TO_VOLUME convert a vector to a 3D volume.
%     VECTOR_TO_VOLUME(...
%         INPUT_VECTOR)
%
% TODO: Add more information here
%
% Example:
%     vector_to_volume(FSC_curve)

% -AF 03-2008
    dim = numel(input_vector);
    [s1, s2, s3] = size(input_vector);
    if mod(dim, 2) ~= 0
        error('Array should have even dimensions');
    elseif (s1 == 1 && s2 == 1) || (s1 == 1 && s3 == 1) || (s2 == 1 && s3 == 1)
        input_vector = reshape(input_vector, dim, 1);
    else
        error('Input array was not a vector');
    end

    polar_volume = tom_sph2cart(...
        repmat(repmat(input_vector, 1, dim * 4), 1, 1, dim * 2));
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
