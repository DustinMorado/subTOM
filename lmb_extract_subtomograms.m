function lmb_extract_subtomograms(tomogram_dir, tomo_digits, scratch_dir, ...
    tomo_row, subtomo_fn_prefix, subtomo_digits, all_motl_fn, subtomosize, ...
    stats_fn_prefix, check_start_fn_prefix, check_done_fn_prefix)
% LMB_EXTRACT_SUBTOMOGRAMS extract subtomograms on the cluster.
% LMB_EXTRACT_SUBTOMOGRAMS(TOMOGRAM_DIR, TOMO_DIGITS, SCRATCH_DIR, ...
%     TOMO_ROW, SUBTOMO_FN_PREFIX, SUBTOMO_DIGITS, ALL_MOTL_FN, SUBTOMOSIZE, ...
%     STATS_FN_PREFIX, CHECK_START_FN_PREFIX, CHECK_DONE_FN_PREFIX)
%
% See also LMB_EXTRACT_NOISE

% DRM 11-2017
% ==============================================================================

% Evaluate numeric inputs
if ischar(tomo_digits)
    tomo_digits = str2double(tomo_digits);
end

if ischar(tomo_row)
    tomo_row = str2double(tomo_row);
end

if ischar(subtomo_digits)
    subtomo_digits = str2double(subtomo_digits);
end

if ischar(subtomosize)
    subtomosize = str2double(subtomosize);
end

% Read in allmotl
allmotl = getfield(tom_emread(all_motl_fn), 'Value');

% Determine tomogram numbers
tomos = unique(allmotl(tomo_row, :));
n_tomos = size(tomos, 2);

% Go to root folder
cd(scratch_dir);

% Write out subtomograms
% Loop through each tomo in the allmotl
for tomo_idx = 1:n_tomos
    % Tomogram string
    tomo_num = tomos(tomo_idx);
    tomo_str = sprintf(sprintf('%%0%dd', tomo_digits), tomo_num);

    % Check if it's not already being processed
    if ~exist(fullfile(pwd(), sprintf('%s_%s', check_start_fn_prefix, ...
            tomo_str)), 'file')

        % Create start file
        fclose(fopen(sprintf('%s_%s', check_start_fn_prefix, tomo_str), 'w'));

        % Parse motls
        temp_motl = allmotl(:, allmotl(tomo_row, :) == tomos(tomo_idx));

        % Create the array to hold the subtomogram statistics
        stats = zeros(size(temp_motl, 2), 6);

        % Read in the tomogram
        vol = getfield(tom_mrcread(fullfile(tomogram_dir, sprintf('%s.rec', ...
            tomo_str))), 'Value');

        for subtomo_idx = 1:size(temp_motl, 2)
            subtomo_position = temp_motl(8:10, subtomo_idx);
            subtomo_start = round(subtomo_position - (subtomosize / 2));
            subtomo = double(tom_red(vol, subtomo_start, ...
                repmat(subtomosize, 1, 3)));

            % Normalize the subtomogram by mean subtraction and division by SD
            subtomo_mean = mean(subtomo(:));
            subtomo_stddev = std(subtomo(:));
            subtomo = (subtomo - subtomo_mean) / subtomo_stddev;

            % Calculate subtomogram stats
            stats(subtomo_idx, 1) = temp_motl(4, subtomo_idx);
            stats(subtomo_idx, 2) = sum(subtomo(:)) / numel(subtomo);
            stats(subtomo_idx, 3) = max(subtomo(:));
            stats(subtomo_idx, 4) = min(subtomo(:));
            stats(subtomo_idx, 5) = std(subtomo(:));
            stats(subtomo_idx, 6) = stats(subtomo_idx, 5)^2;

            % Write out subtomogram
            subtomo_fn = sprintf(sprintf('%s_%%0%dd', subtomo_fn_prefix, ...
                subtomo_digits), temp_motl(4, subtomo_idx));

            tom_emwrite(subtomo_fn, subtomo);
            check_em_file(subtomo_fn, subtomo);
        end

        % Write out stats file
        csvwrite(sprintf('%s_%s.csv', stats_fn_prefix, tomo_str));

        % Cleanup
        clear vol

        % Create done file
        fclose(fopen(sprintf('%s_%s', check_done_fn_prefix, tomo_str), 'w'));
    end
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
