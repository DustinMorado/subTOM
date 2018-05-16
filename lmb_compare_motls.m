function lmb_compare_motls(motl_A_fn, motl_B_fn, write_diffs, diffs_output_fn)
% LMB_COMPARE_MOTLS compares orientations and shifts between two MOTLS.
% LMB_COMPARE_MOTLS(MOTL_A_FN, MOTL_B_FN, WRITE_DIFFS, DIFFS_OUPUT_FN) takes the
%    motls given by MOTL_A_FN and MOTL_B_FN and calculates the differences for
%    both the orientations and coordinates between corresponding particles in
%    each motive list. If WRITE_DIFFS evaluates to true as a boolean, then also
%    a CSV file with the differences in coordinates and orientations to
%    DIFFS_OUTPUT_FN.
%
% Example: LMB_COMPARE_MOTLS('combinedmotl/allmotl_1.em', ...
%       'combinedmotl/allmotl_2.em', true, 'combinedmotl/allmotl_1_2_diff.csv')

% DRM 05-2018
%##############################################################################%
%% DEBUG / SCRIPT
% motl_A_fn = 'combinedmotl/allmotl_1.em';
% motl_B_fn = 'combinedmotl/allmotl_2.em';
% write_diffs = true;
% diffs_output_fn = 'combinedmotl/allmotl_1_2_diff.csv';
%##############################################################################%

    % Evaluate boolean input
    if ischar(write_diffs)
        write_diffs = logical(write_diffs);
    end
    write_diffs = logical(write_diffs);

    motl_A = getfield(tom_emread(motl_A_fn), 'Value');
    motl_B = getfield(tom_emread(motl_B_fn), 'Value');
    coord_A = motl_A(8:10, :) + motl_A(11:13, :);
    coord_B = motl_B(8:10, :) + motl_B(11:13, :);
    eulers_A = motl_A(17:19, :);
    eulers_B = motl_B(17:19, :);

    n_idxs = size(motl_A, 2);
    coord_diffs = zeros(1, n_idxs);
    angular_diffs = zeros(1, n_idxs);

    for idx = 1:n_idxs
        coord_diffs(idx) = sqrt(...
            (coord_B(1, idx) - coord_A(1, idx))^2 + ...
            (coord_B(2, idx) - coord_A(2, idx))^2 + ...
            (coord_B(3, idx) - coord_A(3, idx))^2);
        angular_diffs(idx) = euler_diff(eulers_B(:, idx), eulers_A(:, idx));
    end

    mean_coord_diff = mean(coord_diffs);
    median_coord_diff = median(coord_diffs);
    std_coord_diff = std(coord_diffs);

    mean_angular_diff = mean(angular_diffs);
    median_angular_diff = median(angular_diffs);
    std_angular_diff = std(angular_diffs);

    disp(sprintf('\nMean Coordinate Difference\t:\t%f', mean_coord_diff));
    disp(sprintf('Median Coordinate Difference\t:\t%f', median_coord_diff));
    disp(sprintf('Coordinate Difference Std. Dev.\t:\t%f',std_coord_diff));
    disp(sprintf('\nMean Angular Difference\t\t:\t%f', mean_angular_diff));
    disp(sprintf('Median Angular Difference\t:\t%f', median_angular_diff));
    disp(sprintf('Angular Std. Dev.\t\t:\t%f',std_angular_diff));
    disp(sprintf('\nMean CCC for %s\t\t:\t%f', motl_A_fn, mean(motl_A(1, :))));
    disp(sprintf('Median CCC for %s\t:\t%f', motl_A_fn, median(motl_A(1, :))));
    disp(sprintf('Std. Dev. CCC for %s\t:\t%f', motl_A_fn, std(motl_A(1, :))));
    disp(sprintf('\nMean CCC for %s\t\t:\t%f', motl_B_fn, mean(motl_B(1, :))));
    disp(sprintf('Median CCC for %s\t:\t%f', motl_B_fn, median(motl_B(1, :))));
    disp(sprintf('Std. Dev. CCC for %s\t:\t%f\n', motl_B_fn, ...
        std(motl_B(1, :))));

    if write_diffs
        diffs = zeros(2, n_idxs);
        diffs(1, :) = coord_diffs;
        diffs(2, :) = angular_diffs;
        dlmwrite(diffs_output_fn, transpose(diffs), ...
            'delimiter', ',', 'precision', 6);
    end
end

function distance = euler_diff(e1, e2);
    size_e1 = size(e1, 2);
    distance = zeros(1, size_e1);
    for e_idx = 1:size_e1
        rot_mat_1 = euler_to_matrix(e1(:, e_idx));
        rot_mat_2 = euler_to_matrix(e2(:, e_idx));
        q1 = matrix_to_quaternion(rot_mat_1);
        q2 = matrix_to_quaternion(rot_mat_2);
        distance(e_idx) = rad2deg(real(acos(abs(dot(q1, q2)))) * 2);
    end
end

function rot_mat = euler_to_matrix(input_eulers)
    cos_phi = cosd(input_eulers(1));
    cos_theta = cosd(input_eulers(3));
    cos_psi = cosd(input_eulers(2));
    sin_phi = sind(input_eulers(1));
    sin_theta = sind(input_eulers(3));
    sin_psi = sind(input_eulers(2));

    rot_mat(1, 1) =  cos_phi * cos_psi - sin_phi * cos_theta * sin_psi;
    rot_mat(1, 2) = -sin_phi * cos_psi - cos_phi * cos_theta * sin_psi;
    rot_mat(1, 3) =  sin_theta * sin_psi;
    rot_mat(2, 1) =  cos_phi * sin_psi + sin_phi * cos_theta * cos_psi;
    rot_mat(2, 2) =  cos_phi * cos_theta * cos_psi - sin_phi * sin_psi;
    rot_mat(2, 3) = -sin_theta * cos_psi;
    rot_mat(3, 1) =  sin_phi * sin_theta;
    rot_mat(3, 2) =  cos_phi * sin_theta;
    rot_mat(3, 3) =  cos_theta;
end

function quat = matrix_to_quaternion(rot_mat)
    quat(1) = sqrt(trace(rot_mat) + 1) / 2;

    if imag(quat(1)) > 0
        quat(1) = 0;
    end

    quat(2) = sqrt(1 + rot_mat(1, 1) - rot_mat(2, 2) - rot_mat(3, 3)) / 2;
    quat(3) = sqrt(1 + rot_mat(2, 2) - rot_mat(1, 1) - rot_mat(3, 3)) / 2;
    quat(4) = sqrt(1 + rot_mat(3, 3) - rot_mat(1, 1) - rot_mat(2, 2)) / 2;

    [~, max_quat_idx] = max(quat);

    if max_quat_idx == 1
        quat(2) = (rot_mat(3, 2) - rot_mat(2, 3)) / (4 * quat(1));
        quat(3) = (rot_mat(1, 3) - rot_mat(3, 1)) / (4 * quat(1));
        quat(4) = (rot_mat(2, 1) - rot_mat(1, 2)) / (4 * quat(1));
    elseif max_quat_idx == 2
        quat(1) = (rot_mat(3, 2) - rot_mat(2, 3)) / (4 * quat(2));
        quat(3) = (rot_mat(1, 2) + rot_mat(2, 1)) / (4 * quat(2));
        quat(4) = (rot_mat(3, 1) + rot_mat(1, 3)) / (4 * quat(2));
    elseif max_quat_idx == 3
        quat(1) = (rot_mat(1, 3) - rot_mat(3, 1)) / (4 * quat(3));
        quat(2) = (rot_mat(1, 2) + rot_mat(2, 1)) / (4 * quat(3));
        quat(4) = (rot_mat(2, 3) + rot_mat(3, 2)) / (4 * quat(3));
    else
        quat(1) = (rot_mat(2, 1) - rot_mat(1, 2)) / (4 * quat(4));
        quat(2) = (rot_mat(3, 1) + rot_mat(1, 3)) / (4 * quat(4));
        quat(3) = (rot_mat(2, 3) + rot_mat(3, 2)) / (4 * quat(4));
    end
end
