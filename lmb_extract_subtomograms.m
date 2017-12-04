function lmb_extract_subtomograms(tomogram_dir, scratch_dir, tomo_row, ...
    subtomo_fn_prefix, subtomo_digits, all_motl_fn, subtomosize, ...
    stats_fn_prefix, process_idx) 
% LMB_EXTRACT_SUBTOMOGRAMS extract subtomograms on the cluster.
% LMB_EXTRACT_SUBTOMOGRAMS(TOMOGRAM_DIR, SCRATCH_DIR, TOMO_ROW,
%     SUBTOMO_FN_PREFIX, SUBTOMO_DIGITS, ALL_MOTL_FN, SUBTOMOSIZE,
%     STATS_FN_PREFIX, PROCESS_IDX)
%
% See also LMB_EXTRACT_NOISE

% DRM 11-2017
% ==============================================================================

% Evaluate numeric inputs
if ischar(tomo_row)
    tomo_row = str2double(tomo_row);
end

if ischar(subtomo_digits)
    subtomo_digits = str2double(subtomo_digits);
end

if ischar(subtomosize)
    subtomosize = str2double(subtomosize);
end

if ischar(process_idx)
    process_idx = str2double(process_idx);
end

% Figure out what tomogram we are processing
% Get a list of all tomograms in the tomogram directory
tomograms = dir(fullfile(tomogram_dir, '*.rec'));

% Get the tomogram name from the dir list and process index
tomogram_fn = tomograms(process_idx).name;
clear tomograms

% Tomograms have the form 'X-zero-padded-number.rec', i.e. '002.rec'
% The following gets us the '002' by stripping off the .rec suffix
tomogram_base = regexprep(tomogram_fn, '\.rec', '');

% Convert the above format string number back to a number for checking in the
% MOTL list
tomogram_number = str2double(tomogram_base);

% Finally we get the full path of the tomogram
tomogram_fn = fullfile(tomogram_dir, tomogram_fn);

% Read in allmotl
allmotl = getfield(tom_emread(all_motl_fn), 'Value');

% Get tomogram motl
motl = allmotl(:, allmotl(tomo_row, :) == tomogram_number);
clear allmotl

% Go to root folder
cd(scratch_dir);

% Create the array to hold the subtomogram statistics
stats = zeros(size(motl, 2), 6);

% Read in the tomogram
tomogram = getfield(tom_mrcread(tomogram_fn), 'Value');

delprog = '';
for subtomo_idx = 1:size(motl, 2)
    subtomo_position = motl(8:10, subtomo_idx);
    subtomo_start = round(subtomo_position - (subtomosize / 2));
    subtomo = double(tom_red(tomogram, subtomo_start, ...
        repmat(subtomosize, 1, 3)));

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
    subtomo_fn = sprintf(sprintf('%s_%%0%dd', subtomo_fn_prefix, ...
        subtomo_digits), motl(4, subtomo_idx));

    tom_emwrite(subtomo_fn, subtomo);
    check_em_file(subtomo_fn, subtomo);

    % Display some output
    delprog = disp_progbar(tomogram_number, subtomo_idx, size(motl, 2), ...
        delprog);
end

% Write out stats file
csvwrite(sprintf('%s_%d.csv', stats_fn_prefix, tomogram_number), stats);

% Cleanup
clear tomogram

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

