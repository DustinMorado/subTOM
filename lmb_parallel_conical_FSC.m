function lmb_parallel_conical_FSC(reference_A_fn, reference_B_fn, ...
    FSC_mask_fn, output_fn_prefix, pixelsize, n_fold, B_factor, ...
    filter_threshold, n_points, point_batch_size, process_idx)
% LMB_PARALLEL_CONICAL_FSC calculates a batch of conical FSCs.
% LMB_PARALLEL_CONICAL_FSC(REFERENCE_A_FN, REFERENCE_B_FN, FSC_MASK_FN,
%   OUTPUT_FN_PREFIX, PIXELSIZE, N_FOLD, B_FACTOR, FILTER_THRESHOLD, N_POINTS, 
%   POINT_BATCH_SIZE, PROCESS_IDX)
%
% Example: LMB_PARALLEL_CONICAL_FSC('even/ref/ref_1.em', 'odd/ref/ref_1.em', ...
%       'fscmask.em', 'ref_1', 1.177, 2, -130, 0.143, 200, 10, 1)

% DRM 05-2018
%##############################################################################%
%% DEBUG / SCRIPT
% reference_A_fn = 'even/ref/ref_1.em';
% reference_B_fn = 'odd/ref/ref_1.em';
% FSC_mask_fn = 'fscmask.em';
% output_fn_prefix = 'ref_1';
% n_fold = 2;
% B_factor = -130;
% filter_threshold = 0.143;
% n_points = 200;
% point_batch_size = 20;
% process_idx = 1;
%##############################################################################%

    % Evaluate numeric inputs
    if ischar(pixelsize)
        pixelsize = str2double(pixelsize);
    end

    if ischar(n_fold)
        n_fold = str2double(n_fold);
    end

    if ischar(B_factor)
        B_factor = str2double(B_factor);
    end

    if B_factor > 0
        B_factor = -B_factor;
    end

    if ischar(n_points)
        n_points = str2double(n_points);
    end

    if ischar(filter_threshold)
        filter_threshold = str2double(filter_threshold);
    end

    if ischar(point_batch_size)
        point_batch_size = str2double(point_batch_size);
    end

    if ischar(process_idx)
        process_idx = str2double(process_idx);
    end

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
    if n_fold > 1
        reference_A = tom_symref(reference_A, n_fold);
        reference_B = tom_symref(reference_B, n_fold);
    end

    % Apply masks
    masked_reference_A = reference_A .* FSC_mask;
    masked_reference_B = reference_B .* FSC_mask;

    % Fourier transforms of structures
    reference_A_fft = fftshift(fftn(reference_A));
    reference_B_fft = fftshift(fftn(reference_B));
    masked_reference_A_fft = fftshift(fftn(masked_reference_A));
    masked_reference_B_fft = fftshift(fftn(masked_reference_B));

    % Initial calculations for FSC
    % Complex conjugate product - corresponding to the Cross-Correlation
    % Function
    CCF = reference_A_fft .* conj(reference_B_fft);

    % Intensity of A
    intensity_A = reference_A_fft .* conj(reference_A_fft);

    % Intensity of B
    intensity_B = reference_B_fft .* conj(reference_B_fft);

    % Complex conjugate product - corresponding to the Cross-Correlation
    % Function
    masked_CCF = masked_reference_A_fft .* conj(masked_reference_B_fft);

    % Intensity of A
    masked_intensity_A =  masked_reference_A_fft .* ...
        conj(masked_reference_A_fft);

    % Intensity of B
    masked_intensity_B =  masked_reference_B_fft .* ...
        conj(masked_reference_B_fft);

    % Calculate uniform points on a sphere and the conical Gaussian's sigma,
    % which is set to be the average angular distance between neighboring
    % uniform points
    [pt_azimuth, pt_zenith, pt_radius] = n_sphere_points(n_points);
    angle_sigma = great_circle_avg_central_angle(pt_azimuth, pt_zenith);
    pt_azimuth = pt_azimuth(find(pt_zenith > 0));
    pt_zenith = pt_zenith(find(pt_zenith > 0));
    pt_radius = pt_radius(find(pt_zenith > 0));
    n_points = length(pt_radius);

    % Create a mesh grid first in Cartesian coordinates and then spherical
    % coordinates for the shell Gaussian weighting. The sigma here is hard-coded
    % to be one fourier pixel, but this could be changed.
    boxsize = size(reference_A, 1);
    n_shells = boxsize / 2;
    [grid_x, grid_y, grid_z] = ndgrid(-n_shells:n_shells - 1);
    [grid_azimuth, grid_zenith, grid_radius] = cart2sph(grid_x, grid_y, grid_z);
    shell_sigma = 1;

    % Figure out how many and which cones we are going to calculate
    pt_start = ((process_idx - 1) * point_batch_size) + 1;
    pt_end = pt_start + point_batch_size - 1;
    if pt_end > n_points
        pt_end = n_points;
    end

    for pt_idx = [pt_start:pt_end]
        tic
        FSC = zeros(n_shells, 2);
        for shell_idx = 1:n_shells
            weight = exp(-(angle_sigma.^2 .* (grid_radius - shell_idx).^2 + ...
                shell_sigma.^2 .* min(great_circle_central_angle(...
                grid_azimuth, grid_zenith, pt_azimuth(pt_idx), ...
                pt_zenith(pt_idx)), great_circle_central_angle(grid_azimuth, ...
                grid_zenith, pt_azimuth(pt_idx) + pi, ...
                -pt_zenith(pt_idx))).^2 ./ (2 .* shell_sigma .^2 .* ...
                angle_sigma .^ 2)));
            weight_CCF = sum(sum(sum(CCF .* weight)));
            weight_intensity_A = sum(sum(sum(intensity_A .* weight)));
            weight_intensity_B = sum(sum(sum(intensity_B .* weight)));
            weight_masked_CCF = sum(sum(sum(masked_CCF .* weight)));
            weight_masked_intensity_A = sum(sum(sum(masked_intensity_A .* ...
                weight)));

            weight_masked_intensity_B = sum(sum(sum(masked_intensity_B .* ...
                weight)));

            FSC(shell_idx, 1) = real(weight_CCF ./ ...
                sqrt(weight_intensity_A .* weight_intensity_B));
            FSC(shell_idx, 2) = real(weight_masked_CCF ./ ...
                sqrt(weight_masked_intensity_A .* weight_masked_intensity_B));
        end
        csvwrite(sprintf('%s_%d.csv', output_fn_prefix, pt_idx), FSC);
        FSC = transpose(FSC(:, 2));
        lowpass = ones(size(FSC));
        cutoff = find(FSC < filter_threshold, 1, 'first');
        if isempty(cutoff)
            cutoff = length(FSC) - 4;
            lowpass(cutoff:(cutoff + 4)) = 0.5 - 0.5 .* ...
                cos(pi .* ((cutoff + 4) - (cutoff:(cutoff + 4))) ./ 4);
        elseif (cutoff + 4) >= length(FSC)
            cutoff = length(FSC) - 4;
            lowpass(cutoff:(cutoff + 4)) = 0.5 - 0.5 .* ...
                cos(pi .* ((cutoff + 4) - (cutoff:(cutoff + 4))) ./ 4);
        else
            lowpass(cutoff:(cutoff + 4)) = 0.5 - 0.5 .* ...
                cos(pi .* ((cutoff + 4) - (cutoff:(cutoff + 4))) ./ 4);
            lowpass((cutoff + 5):end) = 0;
        end
        FSC_lowpass = FSC .* lowpass;

        % Calculate frequency array
        R = 1:length(FSC);
        R = (boxsize * pixelsize) ./ R;

        % Calculate exponential filter
        exp_filt = exp(-(B_factor ./ (4 .* (R.^2))));

        % Calculate figure of merit
        Cref = sqrt((2 .* FSC_lowpass) ./ (1 + FSC_lowpass));
        SFSC = exp_filt .* Cref;

        FSC_vol = vector_to_image(FSC, 3);
        SFSC_vol = vector_to_image(SFSC, 3);
        FSC_weight = exp(-(min(...
            great_circle_central_angle(grid_azimuth, grid_zenith, ...
            pt_azimuth(pt_idx), pt_zenith(pt_idx)), ...
            great_circle_central_angle(grid_azimuth, grid_zenith, ...
            pt_azimuth(pt_idx) + pi, -pt_zenith(pt_idx))).^2 ./ ...
            (2 .* angle_sigma .^ 2)));
        FSC_weight = double(FSC_weight >= 0.6065);
        weight_FSC_vol = FSC_vol .* FSC_weight;
        weight_SFSC_vol = SFSC_vol .* FSC_weight;
        tom_emwrite(sprintf('%s_FSC_%d.em', output_fn_prefix, pt_idx), FSC_vol);
        check_em_file(sprintf('%s_FSC_%d.em', output_fn_prefix, pt_idx), ...
            FSC_vol);

        tom_emwrite(sprintf('%s_SFSC_%d.em', output_fn_prefix, pt_idx), ...
            SFSC_vol);
        check_em_file(sprintf('%s_SFSC_%d.em', output_fn_prefix, pt_idx), ...
            SFSC_vol);

        tom_emwrite(sprintf('%s_FSCw_%d.em', output_fn_prefix, pt_idx), ...
            FSC_weight);
        check_em_file(sprintf('%s_FSCw_%d.em', output_fn_prefix, pt_idx), ...
            FSC_weight);

        tom_emwrite(sprintf('%s_wFSC_%d.em', output_fn_prefix, pt_idx), ...
            weight_FSC_vol);
        check_em_file(sprintf('%s_wFSC_%d.em', output_fn_prefix, pt_idx), ...
            weight_FSC_vol);

        tom_emwrite(sprintf('%s_wSFSC_%d.em', output_fn_prefix, pt_idx), ...
            weight_SFSC_vol);
        check_em_file(sprintf('%s_wSFSC_%d.em', output_fn_prefix, pt_idx), ...
            weight_SFSC_vol);
        toc
    end
end

function [azimuth, zenith, radius] = n_sphere_points(n)
    p = 0.5;
    a = 1 - 2 * p / (n - 3);
    b = p * (n + 1) / (n - 3);
    s = zeros(1, n);
    azimuth = zeros(1, n);
    zenith = zeros(1, n);
    radius = ones(1, n);

    azimuth(1) = 0;
    zenith(1) = pi / 2;
    s(1) = 0;
    azimuth(n) = 0;
    zenith(n) = -pi / 2;

    for k = 2:n-1
        k_ = a * k + b;
        h_k = -1 + 2 * (k_ - 1) / (n - 1);
        s(k) = sqrt(1 - h_k^2);
        zenith(k) = acos(h_k) - (pi / 2);
        azimuth(k) = azimuth(k - 1) + 3.6 / sqrt(n) * 2 / (s(k - 1) + s(k));
        azimuth(k) = mod(azimuth(k), 2 * pi);
        if azimuth(k) > pi
            azimuth(k) = azimuth(k) - (2 * pi);
        end
    end
end

function central_angle  = great_circle_central_angle(azimuth_1, zenith_1, ...
    azimuth_2, zenith_2)

    central_angle = atan2(sqrt((cos(zenith_2) .* sin(abs(azimuth_2 - ...
        azimuth_1))).^2 + (cos(zenith_1) .* sin(zenith_2) - sin(zenith_1) .* ...
        cos(zenith_2) .* cos(abs(azimuth_2 - azimuth_1))).^2), ...
        sin(zenith_1) .* sin(zenith_2) + cos(zenith_1) .* cos(zenith_2) .* ...
        cos(abs(azimuth_2 - azimuth_1)));
end

function avg_angle = great_circle_avg_central_angle(azimuth, zenith)
    angle_count = 0;
    angle_sum = 0;

    for pt_idx = 1:length(azimuth)
        if pt_idx == 1
            angle_sum = angle_sum + ...
                great_circle_central_angle(azimuth(pt_idx), zenith(pt_idx), ...
                azimuth(pt_idx + 1), zenith(pt_idx + 1));

            angle_count = angle_count + 1;
        elseif pt_idx == length(azimuth)
            angle_sum = angle_sum + ...
                great_circle_central_angle(azimuth(pt_idx - 1), ...
                zenith(pt_idx - 1), azimuth(pt_idx), zenith(pt_idx));

            angle_count = angle_count + 1;
        else
            angle_sum = angle_sum + ...
                great_circle_central_angle(azimuth(pt_idx - 1), ...
                zenith(pt_idx - 1), azimuth(pt_idx), zenith(pt_idx));

            angle_sum = angle_sum + ...
                great_circle_central_angle(azimuth(pt_idx), zenith(pt_idx), ...
                azimuth(pt_idx + 1), zenith(pt_idx + 1));

            angle_count = angle_count + 2;
        end
    end

    avg_angle = angle_sum / angle_count;
end

%% Convert a vector to a 2D or 3D image
function polar_volume = vector_to_image(input_vector, dimension)
    input_vector = transpose(input_vector);
    [s1, s2, s3] = size(input_vector);
    if s2 > 1 || s3 > 1
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
       tmp = zeros(s1, s1 * 4);
       for kk = 1:(4 * s1)
           tmp(:, kk) = transpose(input_vector);
       end
       polar_volume = polar2cart(tmp);
    else
       error('insert Parameter to define 2D or 3D');
    end
end

%% check_em_file
% A function to check that an EM file was correctly written.
function check_em_file(em_fn, em_data)
    while true
        try
            % If this fails, catch command is run
            tom_emread(em_fn);
            break;
        catch
            tom_emwrite(em_fn, em_data)
        end
    end
end
