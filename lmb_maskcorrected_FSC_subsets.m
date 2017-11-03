%% dustin_maskcorrected_FSC_subsets
% A script to take in two references and an FSC mask, and calculate a
% "mask-corrected" FSC. This works by randomizing the structure factor
% phases beyond a particular resolution and calculating an additional FSC.
% This allows for the determination of the extra correlation caused by
% overfitting or effects of the mask, which is then subtracted by the
% normal FSC curves. The theoretical procedure is described it Chen et al,
% Ultramicroscpy, 2013; (doi:10.1016/j.ultramic.2013.06.004). 
%
% The script can also output B-factor sharpened maps. This setting has two
% threshold settings: FSC and pixel. FSC allows you to use a FSC value as a
% cutoff for the lowpass filter, while using pixels allows you to use an
% arbitrary resolution cutoff. 
%
% This script can also perform CTF-reweighting using pre-calculated
% weighting filters. CTF-reweighting filters can be calculated with
% will_generate_ctf_reweight_filter.m
%
% -WW 06-2015 
%
% Updated to make the phase randomization work? It's around 3x faster...
% 
% -WW 06-2016

%% Inputs
%% Inputs
iter=5;
name = 'nocldcl10';
oname = 'nocldcl10_out_maskfsc10';
%refA_names = dir(['even/ref/', name, 'bottom_subset*.em']); % Reference A
%refB_names = dir(['odd/ref/', name, 'top_subset*.em']); % Reference B

refA_names = dir(['./ref/ref', name, 'bottom_', num2str(iter),'_subset*.em']); % Reference A
refB_names = dir(['./ref/ref', name, 'top_', num2str(iter),'_subset*.em']); % Reference B

% The following are needed to figure out how many particles are in each subset
refA_motl = ['./combinedmotl/allmotl',name,'bottom_',num2str(iter),'.em'];
refB_motl = ['./combinedmotl/allmotl',name,'top_',num2str(iter),'.em'];
iclass = 1;

mask_name = './otherinputs/mask_tube_cut_v10_fsc.em'; % FSC mask ('none' for no mask)
pixelsize = (1.78); % Pixelsize (Angstroms)
symmetry = 1; % Symmetry (1 is no symmetry)


% X-axis label resolutions (in Angstroms)
resolution_label = 0; % (1 = on, 0 = off/Fourier pixels)
res_label = [32,16,8,4];

% CTF Reweighting
ctf_reweight = 1;    % 0 = off, 1 = on
ctf_filter_A = 'ctffilter_even.em';  % Filter A
ctf_filter_B = 'ctffilter_odd.em';  % Filter B


% Sharpen map
sharpen = 1; % 0 = off, 1 = on
plot_sharp = 0; % Plot sharpening curve (0 = off, 1 = on)
% Lowpass filter mode (Mode 1 = FSC threshold, Mode 2 = pixel threshold)
filtermode = 1;
filterthresh = 0.143; % Lowpass filter threshold
% Smooth box edge 
box_gauss = 5; % 0 = off, otherwise odd number must be given.

%% Initialize 
plot_colors = colormap('lines');

% Read mask
if ~strcmp(mask_name ,'none')
    mask = tom_emread(mask_name);
    mask = mask.Value;
else
    mask = ones(size(refA));
end

num_subsets = size(refA_names, 1);
num_good_ptcls_A = zeros(1, num_subsets);
num_good_ptcls_B = zeros(1, num_subsets);
allmotl_A = tom_emread(refA_motl);
allmotl_A = allmotl_A.Value;
allmotl_B = tom_emread(refB_motl);
allmotl_B = allmotl_B.Value;

for motl_idx = 1:size(allmotl_A, 2)
    for subset_idx = 1:num_subsets
        if   mod(motl_idx, 2 ^ (subset_idx - 1)) == 0 ...
           & (allmotl_A(20, motl_idx) == 1 | allmotl_A(20, motl_idx) == iclass)
            num_good_ptcls_A(subset_idx) = num_good_ptcls_A(subset_idx) + 1;
        end
    end
end

for motl_idx = 1:size(allmotl_B, 2)
    for subset_idx = 1:num_subsets
        if   mod(motl_idx, 2 ^ (subset_idx - 1)) == 0 ...
           & (allmotl_B(20, motl_idx) == 1 | allmotl_B(20, motl_idx) == iclass)
            num_good_ptcls_B(subset_idx) = num_good_ptcls_B(subset_idx) + 1;
        end
    end
end

num_good_ptcls = symmetry .* (num_good_ptcls_A + num_good_ptcls_B);
subset_fscs = zeros(1, num_subsets);
subset_fsc_curves = {};
for subset_idx = 1:num_subsets
    % Read references
    refA = tom_emread([refA_names(subset_idx).folder, '/',...
                       refA_names(subset_idx).name]);
    refA = refA.Value;
    refB = tom_emread([refB_names(subset_idx).folder, '/',...
                       refB_names(subset_idx).name]);
    refB = refB.Value;

    % Size of box
    boxsize = size(refA,1);

    % Apply symmetry
    if symmetry > 1
        refA = tom_symref(refA,symmetry);
        refB = tom_symref(refB,symmetry);
    end
    
    % Create "unmasked" references to determine FSC phase-randomization cutoffs
    % RELION uses the true unmasked FSC to determine this, but that's a bad idea
    % for continuous densities like could occur with any lattice structure.
    umrefA = refA;
    umrefB = refB;
    % umrefA = tom_spheremask(refA, (length(refA) / 2) - 2, 1);
    % umrefB = tom_spheremask(refB, (length(refB) / 2) - 2, 1);

    % Apply masks
    mrefA = refA.*mask;
    mrefB = refB.*mask;

    % Fourier transforms of unmasked and masked structures
    umftA = fftshift(fftn(umrefA));
    umftB = fftshift(fftn(umrefB));
    mftA = fftshift(fftn(mrefA));
    mftB = fftshift(fftn(mrefB));

    % Calculate pixel distance array
    cartesian_origin = floor(boxsize / 2);
    [cart_x, cart_y, cart_z] = ndgrid(...
        -cartesian_origin:boxsize - (cartesian_origin + 1));
    radii = sqrt(cart_x.^2 + cart_y.^2 + cart_z.^2);
    clear cartesian_origin cart_x cart_y cart_z

    % Initial calculations for FSC
    umAB_cc = umftA.*conj(umftB);     % Complex conjugate of A and B
    umintA =  umftA.*conj(umftA);     % Intensity of A
    umintB =  umftB.*conj(umftB);     % Intensity of B
    mAB_cc = mftA.*conj(mftB);     % Complex conjugate of A and B
    mintA =  mftA.*conj(mftA);     % Intensity of A
    mintB =  mftB.*conj(mftB);     % Intensity of B

    %% Sum Fourier shells
    tic
    % Number of Fourier Shells
    n_shells = boxsize / 2;  % Hardcoded to half the box-size

    % Normal shell arrays
    mAB_cc_array = zeros(1, n_shells); % Complex conjugate of A and B
    mintA_array = zeros(1, n_shells); % Intenisty of A
    mintB_array = zeros(1, n_shells); % Intenisty of B
    umAB_cc_array = zeros(1, n_shells); % Complex conjugate of A and B
    umintA_array = zeros(1, n_shells); % Intenisty of A
    umintB_array = zeros(1, n_shells); % Intenisty of B

    % Precalculate shell masks
    shell_mask = cell(n_shells,1);
    for i = 1:n_shells
        % Shells are set to one pixel size
        shell_start = (i-1);
        shell_end = i;
        
        % Generate shell mask
        temp_mask = (radii >= shell_start) & (radii < shell_end);
        
        % Write out linearized shell mask
        shell_mask{i} = temp_mask(:);
    end

    % Sum numbers for each shell
    for i = 1:n_shells
        % Write normal outputs
        mAB_cc_array(i) = sum(mAB_cc(shell_mask{i}));
        mintA_array(i) = sum(mintA(shell_mask{i}));
        mintB_array(i) = sum(mintB(shell_mask{i}));
        umAB_cc_array(i) = sum(umAB_cc(shell_mask{i}));
        umintA_array(i) = sum(umintA(shell_mask{i}));
        umintB_array(i) = sum(umintB(shell_mask{i}));
    end

    %% Calculate Normal FSC
    mfsc = real(mAB_cc_array) ./ sqrt(mintA_array .* mintB_array);
    umfsc = real(umAB_cc_array) ./ sqrt(umintA_array .* umintB_array);

    %% Calculate initial steps of Randomized FSC calculation
    cutoff = find(umfsc < 0.8, 1, 'first')

    % Generate phase-randomized density maps
    disp('Randomizing phases!');

    % Determine for phase randomization
    pr_sub = (radii > cutoff);
    pr_idx = find(pr_sub);
    n_pr = size(pr_idx,1);

    % Calculate Fourier transforms
    ftA = fftshift(fftn(refA));
    ftB = fftshift(fftn(refB));

    % Split phases and amplitudes of high resolution data
    phase_A = angle(ftA);
    phase_B = angle(ftB);
    amp_A = abs(ftA);
    amp_B = abs(ftB);

    % Randomize phases
    rphase_A = phase_A;
    rphase_B = phase_B;
    rand_num_gen = rng('shuffle');
    rphase_A(pr_idx) = rand(numel(pr_idx), 1) .* (2.0 * pi);
    rphase_B(pr_idx) = rand(numel(pr_idx), 1) .* (2.0 * pi);

    % Apply randomized phases to reference FTs
    rftA = amp_A.*exp(rphase_A*sqrt(-1));
    rftB = amp_B.*exp(rphase_B*sqrt(-1));

    % Generate phase-randomized real-space maps
    rrefA = ifftn(ifftshift(rftA));
    rrefB = ifftn(ifftshift(rftB));

    % Apply masks
    mrrefA = rrefA.*mask;
    mrrefB = rrefB.*mask;

    % Fourier transforms of masked structures
    mrftA = fftshift(fftn(mrrefA));
    mrftB = fftshift(fftn(mrrefB));

    % Initial calculations for phase-randomized FSC
    rAB_cc = mrftA.*conj(mrftB);     % Complex conjugate of A and B
    rintA =  mrftA.*conj(mrftA);     % Intensity of A
    rintB =  mrftB.*conj(mrftB);     % Intensity of B

    % Phase-randomized shell arrays
    rAB_cc_array = zeros(1,n_shells); % Complex conjugate of A and B
    rintA_array = zeros(1,n_shells); % Intenisty of A
    rintB_array = zeros(1,n_shells); % Intenisty of B

    % Sum numbers for each shell
    for i = 1:n_shells
        
        % Write phase randomized outputs
        rAB_cc_array(i) = sum(rAB_cc(shell_mask{i}));
        rintA_array(i) = sum(rintA(shell_mask{i}));
        rintB_array(i) = sum(rintB(shell_mask{i}));
    end
    toc

    % Phase-randomized FSC
    rfsc = real(rAB_cc_array) ./ sqrt(rintA_array .* rintB_array);

    % Mask-corrected FSC
    corr_fsc = mfsc;
    corr_fsc((cutoff + 2):end) =    (  mfsc((cutoff + 2):end) ...
                                     - rfsc(cutoff + 2:end)) ...
                                 ./ (1 - rfsc((cutoff + 2):end));
    subset_fsc_curves{subset_idx} = corr_fsc;

    % Plot corrected FSC
    hold on
    fsc_color = plot_colors(subset_idx, :);
    umfsc_label = sprintf('Unmasked FSC - %d', subset_idx);
    plot(1:size(umfsc, 2), umfsc, 'LineStyle', ':', 'Color', fsc_color, ...
         'DisplayName', umfsc_label);
    mfsc_label = sprintf('Masked FSC - %d', subset_idx);
    plot(1:size(mfsc, 2), mfsc, 'LineStyle', '--', 'Color', fsc_color, ...
         'DisplayName', mfsc_label);
    rfsc_label = sprintf('Phase Randomized FSC - %d', subset_idx);
    plot(1:size(rfsc, 2), rfsc, 'LineStyle', '-.', 'Color', fsc_color, ...
         'DisplayName', rfsc_label);
    corrfsc_label = sprintf('Corrected FSC - %d', subset_idx);
    plot(1:size(corr_fsc, 2),corr_fsc, 'LineStyle', '-', ...
         'Color', fsc_color, 'DisplayName', corrfsc_label);

    grid on
    axis ([0, n_shells, -0.1, 1.05]);
    set (gca, 'yTick', [0, 0.143, 0.5, 0.8, 1.0]);

    % Label X-axis with resolution labels
    if resolution_label == 1
        
        % Number of labels
        n_res = numel(res_label);

        % X-value for each label
        x_res = zeros(n_res, 1);
        for i = 1:n_res
            x_res(i) = (boxsize * pixelsize) / res_label(i);
        end

        set (gca, 'XTickLabel', res_label)
        set (gca, 'XTick', x_res)
    end

    %% Calculate FSCs at points of interest
    % Points of interest
    fsc_points = [0.5, 0.143];
    n_points = size(fsc_points, 2);
    % Array to hold FSC values
    fsc_values = zeros(1, n_points);

    for i = 1:n_points
        % Find point after value
        x2=find(corr_fsc <= fsc_points(i), 1);
        y2=corr_fsc(x2);
        % Find point before value
        x1=find(corr_fsc(1:x2) >= fsc_points(i), 1, 'last');
        y1=corr_fsc(x1);
        
        % Slope
        m = (y2 - y1) / (x2 - x1);

        % Find X-value
        x_val = ((fsc_points(i) - y1) / m) + x1;
        
        % Write out resolution
        fsc_values(i) = (size(refA, 1) * pixelsize) / x_val;
        
        % Display output
        disp(['FSC at ', num2str(fsc_points(i)), ' = ', ...
              num2str(fsc_values(i)), ' Angstroms.']);
        if fsc_points(i) == 0.143
            subset_fscs(subset_idx) = fsc_values(i);
        end
    end
end

% Estimate the B-Factor using the plot of inverse resolutions squared (1 / d^2)
% against the log of the number of asymmetric particles used (log10(N))
b_factor_domains = (1 ./ subset_fscs) .^ 2;
b_factor_ranges = log(num_good_ptcls);
b_factor_slope =  dot(b_factor_domains, b_factor_ranges) ...
                / dot(b_factor_domains, b_factor_domains);
max_b_factor_domain = (1 / (floor(min(subset_fscs(:))) - 0.05)) ^ 2;
max_b_factor_range = exp(b_factor_slope * max_b_factor_domain);
figure();
hold on
plot(b_factor_domains, num_good_ptcls, 'o');
b_factor_label = sprintf('%d', round(b_factor_slope));
plot([0, max_b_factor_domain], [1, max_b_factor_range], ...
     'DisplayName', b_factor_label);
set(gca, 'yscale', 'log');
set(gca, 'YDir', 'reverse');

for subset_idx = 1:num_subsets
    bfactor = round(-0.5 * b_factor_slope);
    sharp_name = sprintf('%s_finalsharpref_%d_subset%d.em', oname,...
                         (bfactor * -1), subset_idx);
    unsharp_name = sprintf('%s_unsharpref_subset%d.em', oname, subset_idx);
    ctf_sharp_name = sprintf('%s_finalsharpref_%d_rectf_subset%d.em', oname,...
                             (bfactor * -1), subset_idx);

    refA = tom_emread([refA_names(subset_idx).folder, '/',...
                       refA_names(subset_idx).name]);
    refA = refA.Value;
    ftA = fftshift(fftn(refA));
    refB = tom_emread([refB_names(subset_idx).folder, '/',...
                       refB_names(subset_idx).name]);
    refB = refB.Value;
    ftB = fftshift(fftn(refB));

    %% CTF-reweighting
    if (ctf_reweight == 1) && (sharpen == 1)
        % Read in filter
        filter_A = tom_emread(ctf_filter_A);
        filter_A = filter_A.Value;
        % Find non_zero parts of tiler
        non_zero = filter_A ~= 0;
        % Reweight Fourier transform
        ftA_rectf = ftA;
        ftA_rectf(non_zero) = (ftA_rectf(non_zero) ./ filter_A(non_zero));
        % Zero outside frequencies
        ftA_rectf = ftA_rectf .* non_zero;
        % Inverse FFT
        refA_rectf = ifftn(ifftshift(ftA_rectf));
        
        % Read in filter
        filter_B = tom_emread(ctf_filter_B);
        filter_B = filter_B.Value;
        % Find non_zero parts of tiler
        non_zero = filter_B ~= 0;
        % Reweight Fourier transform
        ftB_rectf = ftB;
        ftB_rectf(non_zero) = (ftB_rectf(non_zero) ./ filter_B(non_zero));
        % Zero outside frequencies
        ftB_rectf = ftB_rectf .* non_zero;
        % Inverse FFT
        refB_rectf = ifftn(ifftshift(ftB_rectf));
    end

    %% Smooth box edges
    if box_gauss ~= 0
        % Smooth box edges
        refA = smooth_box_edge(refA, box_gauss);
        refB = smooth_box_edge(refB, box_gauss);
        if (ctf_reweight == 1)
            refA_rectf = smooth_box_edge(refA_rectf, box_gauss);
            refB_rectf = smooth_box_edge(refB_rectf, box_gauss);
        end
    end

    %% Sharpening
    if sharpen == 1
        corr_fsc = subset_fsc_curves{subset_idx};
        % Average reference
        ref_avg = (refA + refB)./2;
        
        % Sharpen reference
        sharp_ref = sharpen_function(ref_avg, bfactor, corr_fsc, pixelsize, ...
                                     filtermode, filterthresh, plot_sharp);
        
        % Write out reference
        tom_emwrite(sharp_name, -sharp_ref);
        tom_emwrite(unsharp_name, -ref_avg);
        
        if (ctf_reweight == 1)
            ref_avg_rectf = (refA_rectf + refB_rectf)./2;
            sharp_ref_rectf = sharpen_function(ref_avg_rectf, bfactor, ...
                                               corr_fsc, pixelsize, ...
                                               filtermode, filterthresh, ...
                                               plot_sharp);
            tom_emwrite(ctf_sharp_name, -sharp_ref_rectf);
        end
    end
end

function masked_vol = smooth_box_edge(volume, gaussian)
    %% smooth_box_edge
    % A function to take in a volume and smooth the box edges by masking with a
    % smaller box with a gaussian dropoff. The function returns a masked
    % volume. 
    %
    %
    % WW 04-2016

    %% Generate box mask

    % Get size of volume
    [x, y, z] = size(volume);

    % Initialize box mask
    box_mask = zeros(size(volume));

    % Get start and end indices
    xs = 1 + (2 * gaussian);
    xe = x - (2 * gaussian);
    ys = 1 + (2 * gaussian);
    ye = y - (2 * gaussian);
    zs = 1 + (2 * gaussian);
    ze = z - (2 * gaussian);

    % Generate binary mask
    box_mask(xs:xe, ys:ye, zs:ze) = 1;

    % Smooth binary mask
    smooth_mask = smooth3(box_mask, 'gaussian', gaussian, gaussian);

    % Return masked volume
    masked_vol = smooth_mask .* volume;
end

function sharp_ref = sharpen_function(reference, bfactor, fsc, pixelsize, ...
                                      filtermode,filterthresh,plot_mode)

    %% sharpen_function
    % A function for sharpening a density map using the Henderson b-factor
    % method. (See Rosenthal and Henderson, 2003,
    % doi:10.1016/j.jmb.2003.07.013) 
    %
    % There are two mode used for low pass filtering. The first uses an FSC
    % based threshold (mode 1), i.e. after FSC < 0.143, or a pixel-based 
    % resolution threhsold (mode 2). 
    %
    % -WW 06-2015

    %% Calculate lowpass FSC filter

    % Calculate FSC with low pass filter
    if filtermode == 1    % Filter by FSC threshold
        % Find FSC values below threshold
        lowpass = find(fsc < filterthresh, 1, 'first');
        % FSC filter
        fsc_lowpass = fsc;
        fsc_lowpass(lowpass:end) = 0;
    elseif filtermode == 2    % Filter by pixel threshold
        % Filter for threshold outside values
        lowpass = ones(size(fsc));
        lowpass(filterthresh + 1:end) = 0;
        % FSC filter
        fsc_lowpass = fsc .* lowpass;
    end


    %% Calculate sharpening filter

    % Calculate frequency array
    R = 1:size(fsc, 2);
    R = (size(reference, 3) * pixelsize) ./ R;

    % Calculate exponential filter
    exp_filt = exp(-(bfactor ./ (4 .* (R.^2))));

    % Calculate figure of merit
    Cref = sqrt((2 .* fsc_lowpass) ./ (1 + fsc_lowpass));

    % Calculate signal-weighted sharpening filter
    sharp_filt = vector_to_image((exp_filt .* Cref), 3);

    %% Apply sharpening
    % Fourier transform
    ft_ref = fftshift(fftn(reference));
    % Apply filter
    ft_filt_ref = ft_ref .* sharp_filt;
    % Inverse transform
    sharp_ref = real(ifftn(ifftshift(ft_filt_ref)));

    %% Plotting
    if plot_mode == 1
        figure()
        plot(1:size(fsc, 2), (exp_filt .* Cref));
    end
end

function polar_volume = vector_to_image(input_vector, dimension);
    %polar_volume=convertVectorToImage(input_vector, dimension);
    %This function converts a vector to a 2D
    %or a 3D image and can be used for filtering
    %
    %dimension Do this in 2D or 3D
    %
    %
    % See also: CART2POLAR POLAR2CART SPH2CART

    input_vector = transpose(input_vector);
    [s1, s2, s3] = size(input_vector);
    if s2 > 1 | s3 > 1
       error('Please use a vector of dimension 1xNx1');
    end
    if mod(s1, 2) ~= 0
       error('vector should have even dimensions');
    end;

    if dimension == 3
       polar_volume = zeros(s1, s1 * 4, s1 * 2);
       tmp = zeros(s1, s1 * 4);
       for kk = 1:(4 * s1)
           tmp(:, kk) = transpose(input_vector);
       end

       for ll = 1:(s1 * 2)
           polar_volume(:, :, ll) = tmp;
       end
       polar_volume = tom_sph2cart(polar_volume);
    elseif dimension == 2
       polar_volume = zeros(s1, s1 * 4);
       tmp = zeros(s1, s1 * 4);
       for kk = 1:(4 * s1)
           tmp(:, kk) = transpose(input_vector);
       end
       polar_volume = polar2cart(tmp);
    else
       error('insert Parameter to define 2D or 3D');
    end 
end
