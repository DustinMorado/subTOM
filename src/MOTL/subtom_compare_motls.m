function subtom_compare_motls(varargin)
% SUBTOM_COMPARE_MOTLS compares orientations and shifts between two MOTLS.
%
%     SUBTOM_COMPARE_MOTLS(
%         'motl_1_fn', MOTL_1_FN,
%         'motl_2_fn', MOTL_2_FN,
%         'write_diffs', WRITE_DIFFS,
%         'output_diffs_fn', OUPUT_DIFFS_FN)
%
%    Takes the motls given by MOTL_1_FN and MOTL_2_FN and calculates the
%    differences for both the orientations and coordinates between corresponding
%    particles in each motive list. If WRITE_DIFFS evaluates to true as a
%    boolean, then also a CSV file with the differences in coordinates and
%    orientations to DIFFS_OUTPUT_FN.
%

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'motl_1_fn', '');
    addParameter(fn_parser, 'motl_2_fn', '');
    addParameter(fn_parser, 'write_diffs', '0');
    addParameter(fn_parser, 'output_diffs_fn', '');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    motl_1_fn = fn_parser.Results.motl_1_fn;

    if isempty(motl_1_fn)
        try
            error('subTOM:missingRequired', ...
                'compare_motls:Parameter %s is required.', ...
                'motl_1_fn');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if exist(motl_1_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'compare_motls:File %s does not exist.', motl_1_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    motl_1 = getfield(tom_emread(motl_1_fn), 'Value');

    if size(motl_1, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'compare_motls:%s is not proper MOTL.', motl_1_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    motl_2_fn = fn_parser.Results.motl_2_fn;

    if isempty(motl_2_fn)
        try
            error('subTOM:missingRequired', ...
                'compare_motls:Parameter %s is required.', ...
                'motl_2_fn');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if exist(motl_2_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'compare_motls:File %s does not exist.', motl_2_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    motl_2 = getfield(tom_emread(motl_2_fn), 'Value');

    if size(motl_2, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'compare_motls:%s is not proper MOTL.', motl_2_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % We need to make sure that the motivelists are together in terms of
    % particles, in some cases sometime the motivelists get out of order with
    % respect to each other (???), so we just sort them here.
    motl_1 = transpose(sortrows(motl_1', 4));
    motl_2 = transpose(sortrows(motl_2', 4));

    if ~all(motl_1(4, :) == motl_2(4, :))
        try
            error('subTOM:argumentError', ...
                'compare_motls:%s and %s are not same sized.', ...
                    motl_1_fn, motl_2_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    write_diffs = fn_parser.Results.write_diffs;

    if ischar(write_diffs)
        write_diffs = str2double(write_diffs);
    end

    try
        validateattributes(write_diffs, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_compare_motls', 'write_diffs');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    output_diffs_fn = fn_parser.Results.output_diffs_fn;

    if ~write_diffs && ~isempty(output_diffs_fn)
        try
            error('subTOM:argumentError', ...
                'compare_motls: %s specified, but not %s', ...
                'output_diffs_fn', 'write_diffs');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    elseif write_diffs && isempty(output_diffs_fn)
        try
            error('subTOM:argumentError', ...
                'compare_motls: %s specified, but not %s', 'write_diffs', ...
                'output_diffs_fn');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    elseif ~isempty(output_diffs_fn)
        fid = fopen(output_diffs_fn, 'w');

        if fid == -1
            try
                error('subTOM:writeFileError', ...
                    'compare_motls:File %s cannot be opened for writing', ...
                    output_diffs_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        fclose(fid);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    n_idxs = size(motl_1, 2);
    coord_diffs = zeros(1, n_idxs);
    angular_diffs = zeros(1, n_idxs);
    angular_diffs_no_inplane = zeros(1, n_idxs);

    for idx = 1:n_idxs
        coord_x_1 = motl_1(8, idx) + motl_1(11, idx);
        coord_y_1 = motl_1(9, idx) + motl_1(12, idx);
        coord_z_1 = motl_1(10, idx) + motl_1(13, idx);

        coord_x_2 = motl_2(8, idx) + motl_2(11, idx);
        coord_y_2 = motl_2(9, idx) + motl_2(12, idx);
        coord_z_2 = motl_2(10, idx) + motl_2(13, idx);

        coord_diffs(idx) = sqrt(...
            (coord_x_1 - coord_x_2)^2 + ...
            (coord_y_1 - coord_y_2)^2 + ...
            (coord_z_1 - coord_z_2)^2);

        euler_phi_1 = motl_1(17, idx);
        euler_psi_1 = motl_1(18, idx);
        euler_theta_1 = motl_1(19, idx);

        euler_phi_2 = motl_2(17, idx);
        euler_psi_2 = motl_2(18, idx);
        euler_theta_2 = motl_2(19, idx);

        angular_diffs(idx) = subtom_euler_diff(...
            [euler_phi_1, euler_psi_1, euler_theta_1], ...
            [euler_phi_2, euler_psi_2, euler_theta_2]);

        angular_diffs_no_inplane(idx) = subtom_euler_diff(...
            [euler_phi_1, euler_psi_1, euler_theta_1], ...
            [euler_phi_2, euler_psi_2, euler_theta_2], 'no_inplane', 1);

    end

    mean_coord_diff = mean(coord_diffs);
    median_coord_diff = median(coord_diffs);
    std_coord_diff = std(coord_diffs);
    max_coord_diff = max(coord_diffs);

    mean_angular_diff = mean(angular_diffs);
    median_angular_diff = median(angular_diffs);
    std_angular_diff = std(angular_diffs);
    max_angular_diff = max(angular_diffs);

    mean_angular_diff_no_inplane = mean(angular_diffs_no_inplane);
    median_angular_diff_no_inplane = median(angular_diffs_no_inplane);
    std_angular_diff_no_inplane = std(angular_diffs_no_inplane);
    max_angular_diff_no_inplane = max(angular_diffs_no_inplane);

    mean_CCC_1 = mean(motl_1(1, :));
    median_CCC_1 = median(motl_1(1, :));
    std_CCC_1 = std(motl_1(1, :));
    min_CCC_1 = min(motl_1(1, :));
    max_CCC_1 = max(motl_1(1, :));

    mean_CCC_2 = mean(motl_2(1, :));
    median_CCC_2 = median(motl_2(1, :));
    std_CCC_2 = std(motl_2(1, :));
    min_CCC_2 = min(motl_2(1, :));
    max_CCC_2 = max(motl_2(1, :));

    fprintf(1, '\n%-60s : %f\n', ...
        'Mean Coordinate Difference', mean_coord_diff);

    fprintf(1, '%-60s : %f\n', ...
        'Median Coordinate Difference', median_coord_diff);

    fprintf(1, '%-60s : %f\n', ...
        'Coordinate Difference Std. Dev.', std_coord_diff);

    fprintf(1, '%-60s : %f\n', ...
        'Max Coordinate Difference', max_coord_diff);

    fprintf(1, '\n%-60s : %f\n', ...
        'Mean Angular Difference', mean_angular_diff);

    fprintf(1, '%-60s : %f\n', ...
        'Median Angular Difference', median_angular_diff);

    fprintf(1, '%-60s : %f\n', ...
        'Angular Difference Std. Dev.', std_angular_diff);

    fprintf(1, '%-60s : %f\n', ...
        'Max Angular Difference', max_angular_diff);

    fprintf(1, '\n%-60s : %f\n', ...
        'Mean Angular Difference (no inplane)', ...
        mean_angular_diff_no_inplane);

    fprintf(1, '%-60s : %f\n', ...
        'Median Angular Difference (no inplane)', ...
        median_angular_diff_no_inplane);

    fprintf(1, '%-60s : %f\n', ...
        'Angular Difference Std. Dev. (no inplane)', ...
        std_angular_diff_no_inplane);

    fprintf(1, '%-60s : %f\n', ...
        'Max Angular Difference (no inplane)', ...
        max_angular_diff_no_inplane);

    [motl_1_dir, motl_1_name, motl_1_ext] = fileparts(motl_1_fn);
    [motl_2_dir, motl_2_name, motl_2_ext] = fileparts(motl_2_fn);

    fprintf(1, '\n%-60s : %f\n', ...
        sprintf('Mean CCC for      %s', motl_1_name), mean_CCC_1);

    fprintf(1, '%-60s : %f\n', ...
        sprintf('Median CCC for    %s', motl_1_name), median_CCC_1);

    fprintf(1, '%-60s : %f\n', ...
        sprintf('CCC Std. Dev. for %s', motl_1_name), std_CCC_1);

    fprintf(1, '%-60s : %f\n', ...
        sprintf('Min. CCC for      %s', motl_1_name), min_CCC_1);

    fprintf(1, '%-60s : %f\n', ...
        sprintf('Max. CCC for      %s', motl_1_name), max_CCC_1);

    fprintf(1, '\n%-60s : %f\n', ...
        sprintf('Mean CCC for      %s', motl_2_name), mean_CCC_2);

    fprintf(1, '%-60s : %f\n', ...
        sprintf('Median CCC for    %s', motl_2_name), median_CCC_2);

    fprintf(1, '%-60s : %f\n', ...
        sprintf('CCC Std. Dev. for %s', motl_2_name), std_CCC_2);

    fprintf(1, '%-60s : %f\n', ...
        sprintf('Min. CCC for      %s', motl_2_name), min_CCC_2);

    fprintf(1, '%-60s : %f\n', ...
        sprintf('Max. CCC for      %s', motl_2_name), max_CCC_2);

    if write_diffs
        diffs = zeros(5, n_idxs);
        diffs(1, :) = motl_1(4, :);
        diffs(2, :) = motl_1(1, :);
        diffs(3, :) = motl_2(1, :);
        diffs(4, :) = coord_diffs;
        diffs(5, :) = angular_diffs;
        diffs(6, :) = angular_diffs_no_inplane;
        dlmwrite(output_diffs_fn, diffs', 'delimiter', ',', 'precision', 6);

        output_diffs_fd = fopen(output_diffs_fn, 'a');
        fprintf(output_diffs_fd, '%f,%f,%f,%f,', mean_coord_diff, ...
            median_coord_diff, std_coord_diff, max_coord_diff);

        fprintf(output_diffs_fd, '%f,%f,%f,%f,', mean_angular_diff, ...
            median_angular_diff, std_angular_diff, max_angular_diff);

        fprintf(output_diffs_fd, '%f,%f,%f,%f,', ...
            mean_angular_diff_no_inplane, median_angular_diff_no_inplane, ...
            std_angular_diff_no_inplane, max_angular_diff_no_inplane);

        fprintf(output_diffs_fd, '%f,%f,%f,%f,%f,', mean_CCC_1, ...
            median_CCC_1, std_CCC_1, min_CCC_1, max_CCC_1);

        fprintf(output_diffs_fd, '%f,%f,%f,%f,%f\n', mean_CCC_2, ...
            median_CCC_2, std_CCC_2, min_CCC_2, max_CCC_2);

        fclose(output_diffs_fd);
    end
end
