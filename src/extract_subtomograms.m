function extract_subtomograms(tomogram_dir, scratch_dir, tomo_row, ...
    subtomo_fn_prefix, subtomo_digits, all_motl_fn, boxsize, ...
    stats_fn_prefix, process_idx, reextract)
% EXTRACT_SUBTOMOGRAMS extract subtomograms on the cluster.
%     EXTRACT_SUBTOMOGRAMS(
%         TOMOGRAM_DIR, 
%         SCRATCH_DIR, 
%         TOMO_ROW, 
%         SUBTOMO_FN_PREFIX, 
%         SUBTOMO_DIGITS, 
%         ALL_MOTL_FN, 
%         BOXSIZE, 
%         STATS_FN_PREFIX, 
%         PROCESS_IDX, 
%         REEXTRACT)
%
%     Takes the tomograms given in TOMOGRAM_DIR and extracts subtomograms
%     specified in ALL_MOTL_FN with size BOXSIZE into SCRATCH_DIR with the name
%     formats SUBTOMO_FN_PREFIX_#.em where # corresponds to the entry in field 4
%     in ALL_MOTL_FN zero-padded to have at least SUBTOMO_DIGITS digits.
%
%     Tomograms are specified by the field TOMO_ROW in motive list ALL_MOTL_FN,
%     and the tomogram that will be processed is selected by PROCESS_IDX. A
%     CSV-format file with the subtomogram ID-number, average, min, max,
%     standard deviation and variance for each subtomogram in the tomogram is
%     also written with the name format STATS_FN_PREFIX_#.em where # corresponds
%     to the tomogram from which subtomograms were extracted. 
%
%     If REEXTRACT evaluates to true as a boolean, than existing subtomograms
%     will be overwritten. Otherwise the program will do nothing and exit if
%     STATS_FN_PREFIX_#.em already exists, or will also skip any subtomogram it
%     is trying to extract that already exists. This is for in the case that the
%     processing crashed at some point in execution and then can just be re-run
%     without any alterations.
%
% Example:
%     EXTRACT_SUBTOMOGRAMS(...
%         '/net/bstore1/bstore1/user/dataset/date/data/tomos/bin1', ...
%         '/net/bstore1/bstore1/user/dataset/date/subtomo/bin1/even', ...
%         7, 'subtomograms/subtomo', 1, 'combinedmotl/allmotl_1.em', ...
%         192, 'subtomograms/stats/subtomo_stats', 1, 0)
%
% See also EXTRACT_NOISE

% DRM 11-2017
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% tomogram_dir = 'tomogram_dir';
% scratch_dir = 'scratch_dir';
% tomo_row = 7;
% subtomo_fn_prefix = 'subtomograms/subtomo';
% subtomo_digits = 1;
% all_motl_fn = 'combinedmotl/allmotl_1.em';
% boxsize = 128;
% stats_fn_prefix = 'subtomograms/stats/subtomo_stats';
% process_idx = 1;
% reextract = 0
%##############################################################################%
    % Evaluate numeric inputs
    if ischar(tomo_row)
        tomo_row = str2double(tomo_row);
    end

    if ischar(subtomo_digits)
        subtomo_digits = str2double(subtomo_digits);
    end

    if ischar(boxsize)
        boxsize = str2double(boxsize);
    end

    if ischar(process_idx)
        process_idx = str2double(process_idx);
    end

    if ischar(reextract)
        reextract = str2double(reextract);
    end

    reextract = logical(reextract);

    % Read in allmotl
    allmotl = getfield(tom_emread(all_motl_fn), 'Value');

    % Get a list of all tomograms in the allmotl
    tomograms = unique(allmotl(tomo_row, :));

    % Identify our tomogram number for processing
    tomogram_number = tomograms(process_idx);

    % We just try to open the tomogram with one, two, three, or four digits.
    for tomogram_digits = 1:4
        tomogram_fn = sprintf(sprintf('%%0%dd.rec', tomogram_digits), ...
            tomogram_number);
        tomogram_fn = fullfile(tomogram_dir, tomogram_fn);
        if isfile(tomogram_fn)
            break;
        end
    end

    % Get tomogram motl
    motl = allmotl(:, allmotl(tomo_row, :) == tomogram_number);

    % Go to root folder
    cd(scratch_dir);

    % Check if we have already finished the processing for this tomogram
    stats_fn = sprintf('%s_%d.csv', stats_fn_prefix, tomogram_number);
    if ~reextract && exist(fullfile(pwd(), stats_fn), 'file') == 2
        stats = csvread(stats_fn);
        if size(stats, 1) == size(motl, 2)
            fprintf('Found stats file with all %d subvolumes. SKIPPING.\n', ...
                size(motl, 2));

            fprintf('Turn on reextract if you want to re-extract particles.\n');
            return
        end
    end

    % Create the array to hold the subtomogram statistics
    stats = zeros(size(motl, 2), 6);

    % Read in the tomogram
    tomogram = getfield(tom_mrcread(tomogram_fn), 'Value');

    delprog = '';
    for subtomo_idx = 1:size(motl, 2)
        % First check if the subtomogram already exists
        subtomo_fn = sprintf(sprintf('%s_%%0%dd.em', subtomo_fn_prefix, ...
            subtomo_digits), motl(4, subtomo_idx));

        if ~reextract && exist(fullfile(pwd(), subtomo_fn), 'file') == 2
            fprintf('Found particle: %s. SKIPPING.\n', subtomo_fn);
            fprintf('Turn on reextract if you want to re-extract particles.\n');
            continue
        end

        subtomo_position = motl(8:10, subtomo_idx);
        subtomo_start = round(subtomo_position - (boxsize / 2));
        subtomo = double(tom_red(tomogram, subtomo_start, ...
            repmat(boxsize, 1, 3)));

        % Normalize the subtomogram by mean subtraction and division by SD
        subtomo_mean = mean(subtomo(:));
        subtomo_stddev = std(subtomo(:));
        subtomo = (subtomo - subtomo_mean) / subtomo_stddev;

        % Calculate subtomogram stats
        stats(subtomo_idx, 1) = motl(4, subtomo_idx);
        stats(subtomo_idx, 2) = sum(subtomo(:)) / numel(subtomo);
        stats(subtomo_idx, 3) = max(subtomo(:));
        stats(subtomo_idx, 4) = min(subtomo(:));
        stats(subtomo_idx, 5) = std(subtomo(:));
        stats(subtomo_idx, 6) = stats(subtomo_idx, 5)^2;

        % Write out subtomogram
        tom_emwrite(subtomo_fn, subtomo);
        check_em_file(subtomo_fn, subtomo);

        % Display some output
        delprog = disp_progbar(tomogram_number, subtomo_idx, size(motl, 2), ...
            delprog);
    end

    % Write out stats file
    csvwrite(stats_fn, stats);
end

%% check_em_file
% A function to check that an EM file was correctly written.
function check_em_file(em_fn, em_data)
    while true
        try
            % If this fails, catch command is run
            tom_emread(em_fn);
            break
        catch ME
            ME.message
            tom_emwrite(em_fn, em_data);
        end
    end
end

%% Display a progress bar
function new_delprog = disp_progbar(tomogram_number, subtomo_count, ...
        num_subtomo, delprog)
    fmtstr = 'Tomogram %d: [%s%s] - %d%% - %d subtomograms\n';
    count = round(subtomo_count / num_subtomo * 40);
    percent = round(subtomo_count / num_subtomo * 100);
    left = repmat('#', 1, count);
    right = repmat(' ', 1, 40 - count);
    fprintf(delprog);
    fprintf(fmtstr, tomogram_number, left, right, percent, subtomo_count);
    new_delprog = repmat('\b', 1, ...
        length(sprintf(fmtstr, tomogram_number, left, right, percent, ...
        subtomo_count)));
end

%% Test if file exists
function file_exists = isfile(filename)
    [status, attrib] = fileattrib(filename);
    file_exists = status;
end
