function subtom_clean_motl(varargin)
% SUBTOM_CLEAN_MOTL cleans a given MOTL file based on distance and or CC scores.
%
%     SUBTOM_CLEAN_MOTL(
%         'input_motl_fn', INPUT_MOTL_FN,
%         'output_motl_fn', OUTPUT_MOTL_FN,
%         'tomo_row', TOMO_ROW,
%         'do_ccclean', DO_CCCLEAN,
%         'cc_fraction', CC_FRACTION,
%         'cc_cutoff', CC_CUTOFF,
%         'do_distance', DO_DISTANCE,
%         'distance_cutoff', DISTANCE_CUTOFF,
%         'do_cluster', DO_CLUSTER,
%         'cluster_distance', CLUSTER_DISTANCE,
%         'cluster_size', CLUSTER_SIZE,
%         'do_edge', DO_EDGE,
%         'tomogram_dir', TOMOGRAM_DIR,
%         'box_size', BOX_SIZE,
%         'write_stats', WRITE_STATS,
%         'output_stats_fn', OUTPUT_STATS_FN)
%
%     Takes the motl given by INPUT_MOTL_FN, and splits it internally by
%     tomogram given by the row TOMO_ROW in the MOTL, and then removes particles
%     by one or multiple methods, if DO_CCCLEAN evaluates to true as a boolean
%     then one of two methods can be applied. Either CC_CUTOFF is specified and
%     particles that have a CCC less than CC_CUTOFF will be discarded.
%     Alternatively CC_FRACTION can be specified as a number between 0 and 1 and
%     that fraction of the data with the highest CCCs will be kept and the rest
%     discarded. If DO_DISTANCE evaluates to true as a boolean then particles
%     that are within DISTANCE_CUTOFF pixels of each other will be determined
%     and only the particle with the highest CCC, will be kept. If
%     DO_CLUSTER evaluates to true as a boolean,then particles must have at
%     least CLUSTER_SIZE neighbor particles within CLUSTER_DISTANCE to be kept
%     after cleaning. Finally if DO_EDGE evaluates to true as a boolean then the
%     program will look for a tomogram in TOMOGRAM_DIR, and if a particle of
%     box_size BOX_SIZE would extend outside of the tomogram it will be removed.
%

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'input_motl_fn', '');
    addParameter(fn_parser, 'output_motl_fn', '');
    addParameter(fn_parser, 'tomo_row', '7');
    addParameter(fn_parser, 'do_ccclean', '0');
    addParameter(fn_parser, 'cc_fraction', '1');
    addParameter(fn_parser, 'cc_cutoff', '-1');
    addParameter(fn_parser, 'do_distance', '0');
    addParameter(fn_parser, 'distance_cutoff', 'Inf');
    addParameter(fn_parser, 'do_cluster', '0');
    addParameter(fn_parser, 'cluster_distance', '0');
    addParameter(fn_parser, 'cluster_size', '1');
    addParameter(fn_parser, 'do_edge', '0');
    addParameter(fn_parser, 'tomogram_dir', '');
    addParameter(fn_parser, 'box_size', '0');
    addParameter(fn_parser, 'write_stats', '0');
    addParameter(fn_parser, 'output_stats_fn', '');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    input_motl_fn = fn_parser.Results.input_motl_fn;

    if isempty(input_motl_fn)
        try
            error('subTOM:missingRequired', ...
                'clean_motl:Parameter %s is required.', ...
                'input_motl_fn');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if exist(input_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'clean_motl:File %s does not exist.', input_motl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    input_motl = getfield(tom_emread(input_motl_fn), 'Value');

    if size(input_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'clean_motl:%s is not proper MOTL.', input_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    output_motl_fn = fn_parser.Results.output_motl_fn;

    if isempty(output_motl_fn)
        try
            error('subTOM:missingRequired', ...
                'clean_motl:Parameter %s is required.', ...
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
                'clean_motl:File %s cannot be opened for writing', ...
                output_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    fclose(fid);
    
    tomo_row = fn_parser.Results.tomo_row;

    if ischar(tomo_row)
        tomo_row = str2double(tomo_row);
    end

    try
        validateattributes(tomo_row, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0, '<', 21}, ...
            'subtom_clean_motl', 'tomo_row');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    do_ccclean = fn_parser.Results.do_ccclean;

    if ischar(do_ccclean)
        do_ccclean = str2double(do_ccclean);
    end

    try
        validateattributes(do_ccclean, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_clean_motl', 'do_ccclean');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    cc_fraction = fn_parser.Results.cc_fraction;

    if ischar(cc_fraction)
        cc_fraction = str2double(cc_fraction);
    end

    try
        validateattributes(cc_fraction, {'numeric'}, ...
            {'scalar', 'nonnan', '>', 0, '<=', 1}, ...
            'subtom_clean_motl', 'cc_fraction');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    cc_cutoff = fn_parser.Results.cc_cutoff;

    if ischar(cc_cutoff)
        cc_cutoff = str2double(cc_cutoff);
    end

    try
        validateattributes(cc_cutoff, {'numeric'}, ...
            {'scalar', 'nonnan', '>=', -1, '<=', 1}, ...
            'subtom_clean_motl', 'cc_cutoff');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    if (cc_fraction < 1) && (cc_cutoff > -1)
        try
            error('subTOM:argumentError', ...
                'clean_motl: %s and %s specified', 'cc_fraction', ...
                'cc_cutoff');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    do_distance = fn_parser.Results.do_distance;

    if ischar(do_distance)
        do_distance = str2double(do_distance);
    end

    try
        validateattributes(do_distance, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_clean_motl', 'do_distance');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    distance_cutoff = fn_parser.Results.distance_cutoff;

    if ischar(distance_cutoff)
        distance_cutoff = str2double(distance_cutoff);
    end

    try
        validateattributes(distance_cutoff, {'numeric'}, ...
            {'scalar', 'nonnan', 'positive'}, ...
            'subtom_clean_motl', 'distance_cutoff');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    % To remove an unnecessary calculation of a square root in calculating
    % distances we square the distance cutoff.
    distance_cutoff = distance_cutoff^2;

    do_cluster = fn_parser.Results.do_cluster;

    if ischar(do_cluster)
        do_cluster = str2double(do_cluster);
    end

    try
        validateattributes(do_cluster, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_clean_motl', 'do_cluster');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    cluster_distance = fn_parser.Results.cluster_distance;

    if ischar(cluster_distance)
        cluster_distance = str2double(cluster_distance);
    end

    try
        validateattributes(cluster_distance, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_clean_motl', 'cluster_distance');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    % To remove an unnecessary calculation of a square root in calculating
    % distances we square the cluster distance.
    cluster_distance = cluster_distance^2;

    cluster_size = fn_parser.Results.cluster_size;

    if ischar(cluster_size)
        cluster_size = str2double(cluster_size);
    end

    try
        validateattributes(cluster_size, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_clean_motl', 'cluster_size');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    do_edge = fn_parser.Results.do_edge;

    if ischar(do_edge)
        do_edge = str2double(do_edge);
    end

    try
        validateattributes(do_edge, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_clean_motl', 'do_edge');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    tomogram_dir = fn_parser.Results.tomogram_dir;

    if do_edge
        if exist(tomogram_dir, 'dir') ~= 7
            try
                error('subTOM:missingDirectoryError', ...
                    'clean_motl:tomogram_dir: Directory %s %s.', ...
                    tomogram_dir, 'does not exist');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end
    end

    box_size = fn_parser.Results.box_size;

    if ischar(box_size)
        box_size = str2double(box_size);
    end

    try
        validateattributes(box_size, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_clean_motl', 'box_size');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    write_stats = fn_parser.Results.write_stats;

    if ischar(write_stats)
        write_stats = str2double(write_stats);
    end

    try
        validateattributes(write_stats, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_clean_motl', 'write_stats');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    output_stats_fn = fn_parser.Results.output_stats_fn;

    if write_stats && isempty(output_stats_fn)
        try
            error('subTOM:missingRequired', ...
                'clean_motl:Parameter %s is required.', ...
                'output_stats_fn');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    fid = fopen(output_stats_fn, 'w');

    if fid == -1
        try
            error('subTOM:writeFileError', ...
                'clean_motl:File %s cannot be opened for writing', ...
                output_stats_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    fclose(fid);

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Create our final output MOTL
    clean_motl = [];

    % Calculate the total number of particles
    total_num_ptcls = size(input_motl, 2);

    % Initialize variables to keep track of total number of particles cleaned.
    total_num_edge_cleaned = 0;
    total_num_cluster_cleaned = 0;
    total_num_distance_cleaned = 0;
    total_num_cc_cleaned = 0;

    % Loop over distance cleaning for each tomogram in the MOTL
    for tomo_idx = unique(input_motl(tomo_row, :))

        % Create a temporary MOTL of particles just in the current tomogram
        motl_ = input_motl(:, input_motl(tomo_row, :) == tomo_idx);

        if do_edge

            % We just try to open the tomogram with one, two, three, or four
            % digits.
            for tomogram_digits = 1:4
                tomogram_fn = sprintf(sprintf('%%0%dd.rec', ...
                    tomogram_digits), tomo_idx);

                tomogram_fn = fullfile(tomogram_dir, tomogram_fn);

                if exist(tomogram_fn, 'file') == 2
                    break;
                end
            end

            if exist(tomogram_fn, 'file') ~= 2
                try
                    error('subTOM:missingFileError', ...
                        'clean_motl:File %s does not exist.', tomogram_fn);

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            % Get just the header of the tomogram to find its dimensions while
            % also avoiding reading the whole thing into memory.
            header = getfield(getfield(...
                tom_readmrcheader(tomogram_fn), 'Header'), 'MRC');

            % Define the center of the box
            origin_offset = floor(box_size / 2);

            % Calculate all of the region starts and ends for every particle
            % within the tomogram.
            start_x = motl_(8,  :) - origin_offset;
            end_x = start_x + (box_size - 1);

            start_y = motl_(9,  :) - origin_offset;
            end_y = start_y + (box_size - 1);

            start_z = motl_(10, :) - origin_offset;
            end_z = start_z + (box_size - 1);

            % Find the current number of particles in the motive list
            num_ptcls = size(motl_, 2);

            % remove any particles where the region start is not within the
            % bounds of the tomogram and any particles where the region end is
            % not within the bounds of the tomogram.
            motl_ = motl_(:, start_x > 1 & start_y > 1 & start_z > 1 & ...
                end_x < header.nx & end_y < header.ny & end_z < header.nz);

            num_edge_cleaned = num_ptcls - size(motl_, 2);
            total_num_edge_cleaned = total_num_edge_cleaned + num_edge_cleaned;

            % Display some output
            fprintf(1, '\nFinished edge cleaning for tomogram: %d\n', ...
                tomo_idx);

            fprintf(1, '\tRemoved: %d particles.\n\n', num_edge_cleaned);
        end

        if do_cluster

            % Initialize the number of clusters that we find
            num_clusters = 0;

            % Find the current number of particles in the motive list
            num_ptcls = size(motl_, 2);

            % Create an empty motive list to store particles that pass the
            % cluster test.
            clean_motl_ = [];

            % We do cluster cleaning by measuring all the distances between
            % the first particle and every other particle. Then if a cluster is
            % found in that case we add the particle with the highest CCC into
            % the clean motive list and remove the other particles in the
            % cluster. If there is not a cluster we only remove the first
            % particle. Then this is iterated until the current motive list is
            % empty.
            while size(motl_, 2)

                % The actual calculation of squared distance between all
                % particles and the first particle.
                distances =   (   (motl_(8,  :) + motl_(11, :)) ...
                                - (motl_(8,  1) + motl_(11, 1))).^2 ...
                            + (   (motl_(9,  :) + motl_(12, :)) ...
                                - (motl_(9,  1) + motl_(12, 1))).^2 ...
                            + (   (motl_(10, :) + motl_(13, :)) ...
                                - (motl_(10, 1) + motl_(13, 1))).^2;

                % The sum here finds the number of particles that have distances
                % less than or equale to the cluster_distance. If that value is
                % greater than or equal to cluster_size than particle 1 in the
                % current motive list qualifies as being part of a cluster.
                if sum(distances <= cluster_distance)  >= cluster_size

                    % Determine the highest CCC within the cluster, which we use
                    % to decide what particle to keep in the motive list.
                    maxCCC = max(motl_(1, distances <= cluster_distance));

                    % If the first particle was the one with the highest CCC
                    % score value then we are done for now and simply add this
                    % particle to the clean motive list and remove it from the
                    % current motive list so that the while-loop will proceed.
                    if motl_(1, 1) == maxCCC

                        % Add the first particle to the clean motl.
                        clean_motl_ = [clean_motl_ motl_(:, 1)];

                        % Remove all of the particles, including the first, that
                        % are in the cluster from the current motive list.
                        motl_(:, distances <= cluster_distance) = [];

                        % We have found a cluster and removed all particles
                        % besides the best, and therefore increment the count of
                        % clusters found.
                        num_clusters = num_clusters + 1;

                    % If the first particle is not the one with the highest CCC
                    % then perhaps there is a neighbor close to the particle
                    % with the highest CCC that is out of the cluster_distance
                    % range of the first particle. In that case we would remove
                    % the best particle of the cluster. To avoid this we simply
                    % place the current best particle first and allow the
                    % while-loop to run again and verify this particle is truly
                    % the best of the cluster.
                    else

                        % Find the index of the highest scoring particle in the
                        % cluster.
                        best_idx = find(distances <= cluster_distance ...
                            & motl_(1, :) == maxCCC);

                        % Move that particle to the front of the current motive
                        % list.
                        motl_ = [motl_(:, best_idx), ...
                            motl_(:, 1:size(motl_, 2) ~= best_idx)];

                    end

                % In this case the first particle of the current motive list is
                % not part of a cluster and so we just remove it and move on
                % with the while loop.
                else
                    motl_ = motl_(:, 2:end);
                end
            end

            % Update the current motive list as the found clustered particles.
            motl_ = clean_motl_;

            num_cluster_cleaned = num_ptcls - size(motl_, 2);
            total_num_cluster_cleaned = total_num_cluster_cleaned + ...
                num_cluster_cleaned;

            % Display some output.
            fprintf(1, 'Finished cluster cleaning for tomogram: %d\n', ...
                tomo_idx);

            fprintf(1, '\tRemoved: %d particles.\n', num_cluster_cleaned);
            fprintf(1, '\tFound: %d clusters.\n\n', num_clusters);
        end

        if do_distance

            % Find the current number of particles in the motive list
            num_ptcls = size(motl_, 2);

            % Create an empty motive list to store particles that pass the
            % cluster test.
            clean_motl_ = [];

            % We do distance cleaning by measuring all the distances between the
            % first particle and every other particle. Then we check if the
            % first particle has the highest CCC of all particles within
            % distance_cutoff (which always includes itself with a distance of
            % 0). If it is the highest then we add the first particle in the
            % clean motive list, and then regardless we remove it from the
            % current motive list. Then this is iterated until the current
            % motive list is empty.
            while size(motl_, 2) > 1

                % The actual calculation of squared distance between all
                % particles and the first particle.
                distances =   (   (motl_(8,  :) + motl_(11, :)) ...
                                - (motl_(8,  1) + motl_(11, 1))).^2 ...
                            + (   (motl_(9,  :) + motl_(12, :)) ...
                                - (motl_(9,  1) + motl_(12, 1))).^2 ...
                            + (   (motl_(10, :) + motl_(13, :)) ...
                                - (motl_(10, 1) + motl_(13, 1))).^2;

                % Check if the first particle has the highest CCC amongst all of
                % those within the distance_cutoff.
                if motl_(1, 1) == max(motl_(1, distances <= distance_cutoff))

                    % If the first particle is the highest (including the case
                    % when it is the only particle within the cutoff) add it to
                    % the clean motive list.
                    clean_motl_ = [clean_motl_ motl_(:, 1)];

                    % Remove all particles that were within the distance cutoff.
                    motl_(:, distances <= distance_cutoff) = [];

                % If the first particle does not have the highest CCC amongst
                % all of those within the distance_cutoff then we just remove
                % the first particle. If we just added the highest particle to
                % the clean list here, there could be the case when there a
                % particle with a higher CCC than the one selected that is
                % within the distance_cutoff to that particle but not the first,
                % in which case we have added the wrong particle and removed the
                % right one later on perhaps.
                else
                    motl_ = motl_(:, 2:end);
                end
            end

            % Update the current motive list as the found clustered particles.
            motl_ = clean_motl_;

            num_distance_cleaned = num_ptcls - size(motl_, 2);
            total_num_distance_cleaned = total_num_distance_cleaned + ...
                num_distance_cleaned;

            % Display some output.
            fprintf(1, 'Finished distance cleaning for tomogram: %d\n', ...
                tomo_idx);

            fprintf(1, '\tRemoved: %d particles.\n\n', num_distance_cleaned);
        end

        % Add the cleaned particles from the current tomogram to the collective
        % cleaned motive list.
        clean_motl = [clean_motl motl_];
    end

    % CC-cleaning can be done on the cleaned all motive list and doesn't need to
    % be done per tomogram.
    if do_ccclean

        % Find the current number of particles in the motive list
        num_ptcls = size(clean_motl, 2);

        % If we are cleaning by a fraction of CCCs we sort the motive list first
        % by CCC and then only take the requested fraction, which is then sorted
        % by the particle index so that the output motive list is in a sensible
        % order.
        if cc_fraction < 1

            % This is the number of particles to keep.
            num_to_keep = ceil(num_ptcls * cc_fraction);

            % First sort the motive list by increasing CCC (row 1).
            clean_motl = transpose(sortrows(clean_motl', 1));

            % Then sort the motive list by particle index (row 4), only keep the
            % num_to_keep last particles.
            clean_motl = transpose(sortrows(...
                clean_motl(:, end - num_to_keep + 1:end)', 4));

        % If we are not cleaning by fraction then we are cleaning by a hard CCC
        % cutoff threshold, this is probably not the best idea since the CCC
        % value depends on the orientation of the particle with respect to the
        % missing wedge.
        else
            clean_motl = clean_motl(:, clean_motl(1, :) >= cc_cutoff);
        end

        total_num_cc_cleaned = num_ptcls - size(clean_motl, 2);

        % Display some output.
        fprintf(1, 'Finished CC cleaning for the complete motive list.');
        fprintf(1, '\tRemoved: %d particles.\n\n', total_num_cc_cleaned);
    end

    tom_emwrite(output_motl_fn, clean_motl);
    subtom_check_em_file(output_motl_fn, clean_motl);

    % Display some output.
    final_num_ptcls = size(clean_motl, 2);
    fprintf(1, '\n| %-35s | %35s |\n', 'Operation', 'Value');
    fprintf(1, '| :%-34s | %34s: |\n', repmat('-', 1, 34), ...
        repmat('-', 1, 34));

    fprintf(1, '| %-35s | %35d |\n', 'Initial number of particles', ...
        total_num_ptcls);

    fprintf(1, '| %-35s | %35d |\n', 'Particles removed edge-cleaning', ...
        total_num_edge_cleaned);

    fprintf(1, '| %-35s | %35d |\n', 'Particles removed cluster-cleaning', ...
        total_num_cluster_cleaned);

    fprintf(1, '| %-35s | %35d |\n', 'Particles removed distance-cleaning', ...
        total_num_distance_cleaned);

    fprintf(1, '| %-35s | %35d |\n', 'Particles removed CC-cleaning', ...
        total_num_cc_cleaned);

    fprintf(1, '| %-35s | %35d |\n\n', 'Final number of particles', ...
        final_num_ptcls);

    if write_stats
        output_stats_fd = fopen(output_stats_fn, 'w');
        fprintf(output_stats_fd, '%d,%d,%d,%d,%d,%d\n', total_num_ptcls, ...
            total_num_edge_cleaned, total_num_cluster_cleaned, ...
            total_num_distance_cleaned, total_num_cc_cleaned, final_num_ptcls);

        fclose(output_stats_fd);
    end

end
