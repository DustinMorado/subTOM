function clean_motl(input_motl_fn, output_motl_fn, tomo_row, ...
    do_ccclean, cc_fraction, cc_cutoff, do_distance, distance_cutoff, ...
    do_cluster, cluster_distance, cluster_size, do_edge, tomogram_dir, boxsize)
% CLEAN_MOTL cleans a given MOTL file based on distance and or CC scores.
%     CLEAN_MOTL(
%         INPUT_MOTL_FN,
%         OUTPUT_MOTL_FN,
%         TOMO_ROW,
%         DO_CCCLEAN,
%         CC_FRACTION,
%         CC_CUTOFF,
%         DO_DISTANCE,
%         DISTANCE_CUTOFF,
%         DO_CLUSTER,
%         CLUSTER_DISTANCE,
%         CLUSTER_SIZE,
%         DO_EDGE,
%         TOMOGRAM_DIR,
%         BOXSIZE)
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
%     boxsize BOXSIZE would extend outside of the tomogram it will be removed.
%
% Example:
%     CLEAN_MOTL('combinedmotl/allmotl_1.em', ...
%         'combinedmotl/allmotl_clean_1.em', 7, 6, 0);

% DRM 05-2018
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% input_motl_fn = 'input_motl.em';
% output_motl_fn = 'output_motl.em';
% tomo_row = 7;
% do_ccclean = 0;
% cc_fraction = 1;
% cc_cutoff = -1;
% do_distance = 0;
% distance_cutoff = 6;
% do_cluster = 0;
% cluster_distance = 2;
% cluster_size = 1;
% do_edge = 0;
% tomogram_dir = 'tomogram_dir';
% boxsize = 64;
%##############################################################################%
    % Evaluate numeric input
    if ischar(tomo_row)
        tomo_row = str2double(tomo_row);
    end

    if ischar(do_ccclean)
        do_ccclean = str2double(do_ccclean);
    end
    do_cclean = logical(do_ccclean);

    if ischar(cc_cutoff)
        cc_cutoff = str2double(cc_cutoff);
    end

    if ischar(cc_fraction)
        cc_fraction = str2double(cc_fraction);
    end

    if ischar(do_distance)
        do_distance = str2double(do_distance);
    end
    do_distance = logical(do_distance);

    if ischar(distance_cutoff)
        distance_cutoff = str2double(distance_cutoff);
    end
    distance_cutoff = distance_cutoff^2;

    if ischar(do_cluster)
        do_cluster = str2double(do_cluster);
    end
    do_cluster = logical(do_cluster);

    if ischar(cluster_distance)
        cluster_distance = str2double(cluster_distance);
    end
    cluster_distance = cluster_distance^2;

    if ischar(cluster_size)
        cluster_size = str2double(cluster_size);
    end

    if ischar(do_edge)
        do_edge = str2double(do_edge);
    end
    do_edge = logical(do_edge);

    if ischar(boxsize)
        boxsize = str2double(boxsize);
    end

    % Read the given input MOTL
    motl = getfield(tom_emread(input_motl_fn), 'Value');

    % Create our final output MOTL
    clean_motl = [];

    % Loop over distance cleaning for each tomogram in the MOTL
    for tomo_idx = unique(motl(tomo_row, :))
        % Create a temporary MOTL of particles just in the current tomogram
        motl_ = motl(:, motl(tomo_row, :) == tomo_idx);

        if do_edge
            % We just try to open the tomogram with one, two, three, or four
            % digits.
            for tomogram_digits = 1:4
                tomogram_fn = sprintf(sprintf('%%0%dd.rec', ...
                    tomogram_digits), tomo_idx);
                tomogram_fn = fullfile(tomogram_dir, tomogram_fn);
                if isfile(tomogram_fn)
                    break;
                end
            end

            header = getfield(getfield(...
                tom_readmrcheader(tomogram_fn), 'Header'), 'MRC');

            origin_offset = floor(boxsize / 2);
            start_x = motl_(8,  :) - origin_offset;
            end_x = start_x + (boxsize - 1);
            start_y = motl_(9,  :) - origin_offset;
            end_y = start_y + (boxsize - 1);
            start_z = motl_(10, :) - origin_offset;
            end_z = start_z + (boxsize - 1);

            n_ptcls = size(motl_, 2);
            motl_ = motl_(:, start_x > 1 & start_y > 1 & start_z > 1 & ...
                end_x < header.nx & end_y < header.ny & end_z < header.nz);
            fprintf('Finished edge cleaning');
            fprintf('\tRemoved: %d particles.\n', n_ptcls - size(motl_, 2));
        end

        if do_cluster
            n_clusters = 0;
            clean_motl_ = [];
            while size(motl_, 2)
                distances =   (   (motl_(8,  :) + motl_(11, :)) ...
                                - (motl_(8,  1) + motl_(11, 1))).^2 ...
                            + (   (motl_(9,  :) + motl_(12, :)) ...
                                - (motl_(9,  1) + motl_(12, 1))).^2 ...
                            + (   (motl_(10, :) + motl_(13, :)) ...
                                - (motl_(10, 1) + motl_(13, 1))).^2;

                if sum(distances <= cluster_distance)  >= cluster_size
                    maxCCC = max(motl_(1, distances <= cluster_distance));
                    if motl_(1, 1) == maxCCC
                        clean_motl_ = [clean_motl_ motl_(:, 1)];
                        motl_(:, distances <= cluster_distance) = [];
                    else
                        best_idx = find(distances <= cluster_distance ...
                            & motl_(1, :) == maxCCC);
                        motl_ = [motl_(:, best_idx), ...
                            motl_(:, 1:size(motl_, 2) ~= best_idx)];
                    end
                    n_clusters = n_clusters + 1;
                else
                    motl_ = motl_(:, 2:end);
                end

            end

            motl_ = clean_motl_;
            fprintf('Finished cluster cleaning for tomogram: %d\n', tomo_idx);
            fprintf('\tFound: %d clusters.\n', n_clusters);
        end

        if do_distance
            ptcls_cleaned = 0;
            clean_motl_ = [];
            while size(motl_, 2) > 1
                distances =   (   (motl_(8,  :) + motl_(11, :)) ...
                                - (motl_(8,  1) + motl_(11, 1))).^2 ...
                            + (   (motl_(9,  :) + motl_(12, :)) ...
                                - (motl_(9,  1) + motl_(12, 1))).^2 ...
                            + (   (motl_(10, :) + motl_(13, :)) ...
                                - (motl_(10, 1) + motl_(13, 1))).^2;

                if motl_(1, 1) == max(motl_(1, distances <= distance_cutoff))
                    clean_motl_ = [clean_motl_ motl_(:, 1)];
                    motl_(:, distances <= distance_cutoff) = [];
                    ptcls_cleaned = ptcls_cleaned + ...
                        sum(distances <= distance_cutoff) - 1;
                else
                    ptcls_cleaned = ptcls_cleaned + 1;
                    motl_ = motl_(:, 2:end);
                end

            end

            motl_ = clean_motl_;
            fprintf('Finished distance cleaning for tomogram: %d\n', tomo_idx);
            fprintf('\tRemoved: %d particles.\n', ptcls_cleaned);
        end

        clean_motl = [clean_motl motl_];
    end

    if do_ccclean
        n_ptcls = size(clean_motl, 2);
        if cc_fraction < 1
            n_keep = ceil(n_ptcls * cc_fraction);
            clean_motl = transpose(sortrows(clean_motl', 1));
            clean_motl = transpose(sortrows(...
                clean_motl(:, end - n_keep + 1:end)', 4));
        else
            clean_motl = clean_motl(:, clean_motl(1, :) >= cc_cutoff);
        end
        fprintf('Finished CC cleaning');
        fprintf('\tRemoved: %d particles.\n', n_ptcls - size(clean_motl, 2));
    end

    tom_emwrite(output_motl_fn, clean_motl);
    check_em_file(output_motl_fn, clean_motl);
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
    size_check = numel(em_data) * 4 + 512;
    while true
        listing = dir(em_fn);
        if isempty(listing)
            fprintf('******\nWARNING:\n\tFile %s does not exist!', em_fn);
            tom_emwrite(em_fn, em_data);
        else
            if listing.bytes ~= size_check
                fprintf('******\nWARNING:\n');
                fprintf('\tFile %s is not the correct size!', em_fn);
                tom_emwrite(em_fn, em_data);
            else
                break;
            end
        end
    end
end

%% Test if file exists
function file_exists = isfile(filename)
    [status, attrib] = fileattrib(filename);
    file_exists = status;
end
