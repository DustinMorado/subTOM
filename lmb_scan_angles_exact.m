function lmb_scan_angles_exact(ptcl_start_idx, iteration, ali_batch_size, ...
    ref_fn_prefix, all_motl_fn_prefix, ptcl_motl_fn_prefix, ptcl_fn_prefix, ...
    tomo_row, weight_fn_prefix, apply_weight, align_mask_fn, apply_mask, ...
    cc_mask_fn, psi_angle_step, psi_angle_shells, phi_angle_step, ...
    phi_angle_shells, high_pass_fp, low_pass_fp, nfold, threshold, iclass)
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
%ptcl_start_idx = '1';
%iteration = '3';
%ali_batch_size = '100';
%ref_fn_prefix = './ref/ref';
%all_motl_fn_prefix = './combinedmotl/allmotl';
%ptcl_motl_fn_prefix = './motls/motl';
%ptcl_fn_prefix = './subtomograms/subtomo';
%tomo_row = '5';
%weight_fn_prefix = './otherinputs/ampspec';
%apply_weight = '0';
%align_mask_fn = './otherinputs/mask192_r85_h80_g3_pos9797108.em';
%apply_mask = '0';
%cc_mask_fn = './otherinputs/ccmask192_r5.em';
%psi_angle_step = '2';
%psi_angle_shells = '3';
%phi_angle_step = '2';
%phi_angle_shells = '4';
%high_pass_fp = '1';
%low_pass_fp = '10';
%nfold = '2';
%threshold = '0';
%iclass = '1';

%##############################################################################%
%                                 CHECK INPUTS                                 %
%##############################################################################%
if (ischar(ptcl_start_idx))
    ptcl_start_idx = str2double(ptcl_start_idx);
end

if (ischar(iteration))
    iteration = str2double(iteration);
end

if (ischar(ali_batch_size))
    ali_batch_size = str2double(ali_batch_size);
end

if (ischar(tomo_row))
    tomo_row = str2double(tomo_row);
end

if (ischar(apply_weight))
    apply_weight = str2double(apply_weight);
end

if (ischar(apply_mask))
    apply_mask = str2double(apply_mask);
end

if (ischar(iclass))
    iclass = str2double(iclass);
end

if (ischar(threshold))
    threshold = str2double(threshold);
end

if (ischar(nfold))
    nfold = str2double(nfold);
end

if (ischar(low_pass_fp))
    low_pass_fp = str2double(low_pass_fp);
end

if (ischar(high_pass_fp))
    high_pass_fp = str2double(high_pass_fp);
end

if (ischar(psi_angle_shells))
    psi_angle_shells = str2double(psi_angle_shells);
end

if (ischar(psi_angle_step))
    psi_angle_step = str2double(psi_angle_step);
end

if (ischar(phi_angle_shells))
    phi_angle_shells = str2double(phi_angle_shells);
end

if (ischar(phi_angle_step))
    phi_angle_step = str2double(phi_angle_step);
end

%##############################################################################%
%                                PREPARE MASKS                                 %
%##############################################################################%
% Read in alignment masks
align_mask = getfield(tom_emread(align_mask_fn), 'Value');

% Read in CC mask if shifts are being refined
if ~strcmp(cc_mask_fn, 'noshift')
    cc_mask = getfield(tom_emread(cc_mask_fn), 'Value');
end

% Calculate band-pass mask
box_size = size(align_mask);
low_pass_mask = tom_spheremask(ones(box_size), low_pass_fp, 3);
high_pass_mask = tom_spheremask(ones(box_size), high_pass_fp, 2);
band_pass_mask = low_pass_mask - high_pass_mask;
clear low_pass_mask high_pass_mask;

% Mask for box-edges for subtomogram if align mask is not applied
if ~ apply_mask
    radius = floor(max(box_size) / 2) * 0.8;
    sigma = floor(max(box_size) / 2) * 0.15;
    ptcl_spheremask = tom_spheremask(ones(box_size), radius, sigma);
    clear radius sigma;
end

%##############################################################################%
%                              PREPARE REFERENCE                               %
%##############################################################################%
% Read reference
ref = getfield(tom_emread(sprintf('%s_%d.em', ref_fn_prefix, iteration)), ...
    'Value');

% Perform n-fold symmetrization of reference. If a volume VOL is assumed to have
% a n-fold symmtry axis along Z it can be rotationally symmetrized
if nfold ~= 1
    ref = tom_symref(ref, nfold);
end

% Mask reference
masked_ref = ref .* align_mask;

% Subtract mean of the masked reference under the align mask
masked_ref = subtract_mean_under_mask(masked_ref, align_mask);

%##############################################################################%
%                               PREPARE ALLMOTL                                %
%##############################################################################%
% Read in allmotl file
allmotl = getfield(tom_emread(sprintf('%s_%d.em', all_motl_fn_prefix, ...
    iteration)), 'Value');

% Calculate last particle index based on size of allmotl
ptcl_end_idx = ptcl_start_idx + ali_batch_size - 1;
if ptcl_end_idx > size(allmotl, 2)
    ptcl_end_idx = size(allmotl, 2);
end

%##############################################################################%
%                                MISCELLANEOUS                                 %
%##############################################################################%
% Initialize a variable to keep track of the weight volume to use
current_weight = 0;

% Since the azimuthal angle can range over the full 360 degrees while the
% zenithal angle can only range over 180 degrees, the number of cones to search
% is defined as the ceiling of half of the azimuthal segments
theta_angle_shells = ceil(psi_angle_shells / 2);

% Calculate the center coordinates of the box for interpreting the shifts
box_center = (floor(box_size / 2) + 1);

%##############################################################################%
%                                  ALIGNMENT                                   %
%##############################################################################%
for ptcl_idx = ptcl_start_idx:ptcl_end_idx
    % Check if particle motl already exists and if so skip it
    ptcl_motl_fn = sprintf('%s_%d_%d.em', ptcl_motl_fn_prefix, ptcl_idx, ...
        iteration + 1);
    if exist(fullfile(pwd(), ptcl_motl_fn), 'file') == 2
        disp(sprintf('%s already exists. SKIPPING.', ptcl_motl_fn));
        continue
    end

    % Check if motl should be procesed based on class
    if allmotl(20, ptcl_idx) ~= 1 && ...
            allmotl(20, ptcl_idx) ~= iclass && iclass ~= 0
        % Write out motl
        tom_emwrite(ptcl_motl_fn, allmotl(:, ptcl_idx));
        check_em_file(ptcl_motl_fn, allmotl(:, ptcl_idx));
        continue
    end

    % Check wedge and generated mask if needed
    if current_weight ~= allmotl(5, ptcl_idx)
        % Set current weight and read in weight volume
        current_weight = allmotl(5, ptcl_idx);
        weight = getfield(tom_emread(sprintf('%s_%d.em', weight_fn_prefix, ...
            current_weight)), 'Value');
    end

    % Parse translations from motl
    % These translations describe the translation of the reference to the
    % particle after rotation has been applied to the reference. In the
    % motl they are ordered: X-axis shift, Y-axis shift, and Z-axis shift.
    old_ref_shift = allmotl(11:13, ptcl_idx);

    % Parse rotations from motl
    % These rotations describe the rotations of the reference to the
    % particle determined in alignment. In the motl they are ordered;
    % azimuthal rotation, inplane rotation, and zenithal rotation.
    old_ref_rot = allmotl(17:19, ptcl_idx);

    % Initialize maximum CCC and shift vector
    max_ccc = -100000;
    new_ref_shift = old_ref_shift;

    % Read in subtomogram
    ptcl = getfield(tom_emread(sprintf('%s_%d.em', ptcl_fn_prefix, ...
        allmotl(4, ptcl_idx))), 'Value');

    if apply_mask
        % Rotate and shift alignment mask
        ptcl_align_mask = tom_rotate(align_mask, old_ref_rot);
        ptcl_align_mask = tom_shift(ptcl_align_mask, old_ref_shift);

        % Mask subtomogram
        ptcl = ptcl .* ptcl_align_mask;

        % Subtract mean of the masked particle under the align mask
        ptcl = subtract_mean_under_mask(ptcl, ptcl_align_mask);
    else
        % Mask subtomogram
        ptcl = ptcl .* ptcl_spheremask;

        % Subtract mean of the masked particle under the align mask
        ptcl = subtract_mean_under_mask(ptcl, ptcl_spheremask);
    end

    % Fourier transform particle
    ptcl_fft = fftshift(tom_fourier(ptcl));

    % Apply band-pass filter and inverse FFT shift
    if apply_weight
        ptcl_fft = ifftshift(ptcl_fft .* band_pass_mask .* weight);
    else
        ptcl_fft = ifftshift(ptcl_fft .* band_pass_mask);
    end

    % Normalise the Fourier transform of the particle
    ptcl_fft = normalise_fftn(ptcl_fft);

    % Calculate the inplane search range
    min_phi = old_ref_rot(1) - (phi_angle_shells * phi_angle_step);
    max_phi = old_ref_rot(1) + (phi_angle_shells * phi_angle_step);
    phi_range = min_phi:phi_angle_step:max_phi;
    if isempty(phi_range)
        phi_range = old_ref_rot(1);
    end
    clear min_phi max_phi;

    % Loop over the inplane search angles
    for phi = phi_range
        for theta_idx = 0:theta_angle_shells
            if theta_idx == 0
                psi_delta = 360;
                psi_range = 0;
            else
                psi_delta = psi_angle_step / ...
                    sin(deg2rad(theta_idx * psi_angle_step));

                psi_range = 0:(ceil(360 / psi_delta) - 1);
                % Make psi_delta equidistant again (from PYTOM)
                psi_delta = 360 / ceil(360 / psi_delta);
            end

            for psi_idx = psi_range
                % We start with the reference z-axis unit vector and then rotate
                % the point along the unit sphere to a point on the rotational
                % cone search, and then apply the existing previously found
                % rotations from which we can recalculate the determined
                % zenithal and azimuthal angles for rotating the reference.
                psi = psi_idx * psi_delta;
                old_psi = old_ref_rot(2);
                theta = theta_idx * psi_angle_step;
                old_theta = old_ref_rot(3);
                z_hat = [0 0 1];
                z_hat = tom_pointrotate(z_hat, 0, psi, theta);
                z_hat = tom_pointrotate(z_hat, 0, old_psi, old_theta);

                % Determine the spherical coordinates of the reference's new
                % z-axis
                theta = atan2d(sqrt(z_hat(1).^2 + z_hat(2).^2), z_hat(3));
                psi = atan2(z_hat(2), z_hat(1)) + 90;
                clear z_hat;

                % Prepare the reference for correlation
                % Rotate reference
                rot_ref = tom_rotate(masked_ref, [phi, psi, theta]);

                % Fourier transform reference
                ref_fft = fftshift(tom_fourier(rot_ref));
                clear rot_ref;

                % Apply band-pass filter and inverse FFT shift
                ref_fft = ifftshift(ref_fft .* weight .* band_pass_mask);

                % Normalise the Fourier transform of the reference
                ref_fft = normalise_fftn(ref_fft);

                % Calculate cross correlation and apply rotated ccmask
                ccf = real(fftshift(tom_ifourier(ptcl_fft .* conj(ref_fft))));
                ccf = ccf / numel(ccf);

                % Determine max CCC and its location
                if ~strcmp(cc_mask_fn, 'noshift')
                    % Rotate CC mask and mask the CCF
                    rot_cc_mask = tom_rotate(cc_mask, [phi, psi, theta]);
                    masked_ccf = ccf .* rot_cc_mask;
                    clear rot_cc_mask;

                    % Find the integral coordinates and value of the peak
                    [peak_value, peak_linear_idx] = max(masked_ccf(:));
                    [x, y, z] = ind2sub(size(masked_ccf), peak_linear_idx);
                    peak_coord = [x, y, z];
                    clear peak_linear_idx x y z;

                    % Find the subpixel location and value of the peak
                    [ccc, peak] = get_subpixel_peak(masked_ccf, peak_value, ...
                        peak_coord);

                    clear peak_value peak_coord;
                else
                    % Find peak at previous center for no shift
                    peak_value = ccf(round(old_ref_shift + box_center))
                    peak_coord = round(old_ref_shift + box_center)
                    [ccc, peak] = get_subpixel_peak(ccf, peak_value, ...
                        peak_coord);

                    clear peak_value peak_coord;
                end

                % If current max ccc is greater than the overall maximum, update
                % the maximum ccc, Euler angles, and shifts
                if ccc > max_ccc
                    max_ccc = ccc;
                    new_ref_rot = [phi, psi, theta];
                    new_ref_shift = peak - box_center;
                end
            end
        end
    end

    % Update motl with new values for max CCC, shifts, rotations and class
    allmotl(1, ptcl_idx) = max_ccc;
    allmotl(11:13, ptcl_idx) = new_ref_shift;
    allmotl(17:19, ptcl_idx) = new_ref_rot;
    if max_ccc > threshold
        allmotl(20, ptcl_idx) = iclass;
    else
        allmotl(20, ptcl_idx) = 2;
    end

    % Write out motl
    tom_emwrite(ptcl_motl_fn, allmotl(:, ptcl_idx));
    check_em_file(ptcl_motl_fn, allmotl(:, ptcl_idx));
end

%% Subtract mean of volume under a mask
function output_vol = subtract_mean_under_mask(input_vol, mask)
    masked_mean = sum(input_vol(:)) / sum(mask(:));
    masked_mean_vol = masked_mean * mask;
    output_vol = input_vol - masked_mean_vol;
    clear masked_mean masked_mean_vol;

%% Normalise an unshifted Fourier volume
% Sets the DC component of the spectrum to 0 and then divides by the mean
% amplitude.
function output_vol = normalise_fftn(input_vol)
    output_vol = input_vol;
    output_vol(1, 1, 1) = 0;

    magnitude = output_vol .* conj(output_vol);
    magnitude = sqrt(sum(magnitude(:)));
    output_vol = (numel(output_vol) * output_vol) / magnitude;
    clear magnitude;

%% Find sub-pixel peak
% A function to take in a given volume, find the pixel with highest value,
% and use interpolation to find the peak with subpixel precision. 
%
% The math for this function was taken from Yuxiang Chen's
% find_subpixel_peak_position function in the SH_align package. See 
% 10.1016/j.jsb.2013.03.002 for more information. 
%
% WW 01-2016
function [value, peak] = get_subpixel_peak(ccf, peak_value, peak_coord)
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

        value =   peak_value + (dx * det(1)) + (dy * det(2)) + (dz * det(3)) ...
                + (dxx * (det(1)^2) / 2) + (dyy * (det(2)^2) / 2) ...
                + (dzz * (det(3)^2) / 2) + (det(1) * det(2) * dxy) ...
                + (det(1) * det(3) * dxz)  + (det(2) * det(3) * dyz);
    end
catch
    peak = peak_coord;
    value = peak_value;
end

%% check_em_file
% A function to check that an EM file was correctly written.
function check_em_file(em_fn, em_data)
    while true
        try
            % If this fails, catch command is run
            tom_emread(em_fn);
            break
        catch
            tom_emwrite(em_fn, em_data);
        end
    end
