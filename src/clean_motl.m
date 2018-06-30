function clean_motl(input_motl_fn, output_motl_fn, tomo_row, ...
    distance_cutoff, cc_cutoff)
% CLEAN_MOTL cleans a given MOTL file based on distance and or CC scores.
%     CLEAN_MOTL(
%         INPUT_MOTL_FN,
%         OUTPUT_MOTL_FN,
%         TOMO_ROW,
%         DISTANCE_CUTOFF,
%         CC_CUTOFF)
%
%     Takes the motl given by INPUT_MOTL_FN, and splits it internally by
%     tomogram given by the row TOMO_ROW in the MOTL, and then removes particles
%     that are within DISTANCE_CUTOFF pixels of each other, keeping the particle
%     with the higher CCC, and then particles with a CCC lower than CC_CUTOFF
%     are also removed and the final cleaned MOTL file is written out to
%     OUTPUT_MOTL_FN.
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
% distance_cutoff = 6;
% cc_cutoff = 0;
%##############################################################################%
    % Evaluate numeric input
    if ischar(tomo_row)
        tomo_row = str2double(tomo_row);
    end

    if ischar(distance_cutoff)
        distance_cutoff = str2double(distance_cutoff);
    end

    if ischar(cc_cutoff)
        cc_cutoff = str2double(cc_cutoff);
    end

    % Read the given input MOTL
    motl = getfield(tom_emread(input_motl_fn), 'Value');

    % We can quickly up-front remove particles below the CC cutoff threshold.
    motl = motl(:, motl(1, :) >= cc_cutoff);

    % Loop over distance cleaning for each tomogram in the MOTL
    for tomo_idx = unique(motl(tomo_row, :))
        % Create a temporary MOTL of particles just in the current tomogram
        motl_ = motl(:, motl(tomo_row, :) == tomo_idx);

        % We will calculate the distance between the first particle and every
        % other particle in the MOTL (including the first particle itself), and
        % then delete the inspected particles from the temporary MOTL, so we
        % iterate a While-Loop until the temporary MOTL is down to 1 or no
        % particles left to inspect.
        while size(motl_, 2) > 1
            distances = sqrt(((motl_(8, :) + motl_(11, :)) - ...
                              (motl_(8, 1) + motl_(11, 1))).^2 + ...
                             ((motl_(9, :) + motl_(12, :)) - ...
                              (motl_(9, 1) + motl_(12, 1))).^2 + ...
                             ((motl_(10, :) + motl_(13, :)) - ...
                              (motl_(10, 1) + motl_(13, 1))).^2);

            % Find which indices in the temporary MOTL are within the distance
            % cutoff.
            clean_idxs = find(distances < distance_cutoff);

            % We will only keep the particle that has the highest CC-value,
            % and the remaining indices will be targeted for deletion.
            delete_idxs = clean_idxs(find(clean_idxs ~= ...
                find(motl_(1, :) == max(motl_(1, clean_idxs)), 1)));
            if ~isempty(delete_idxs)
                ptcl_idxs = motl_(4, delete_idxs);
                motl(1, ismember(motl(4, :), motl_(4, delete_idxs))) = -100;
                motl_(:, clean_idxs) = [];
            end
        end
    end

    motl = motl(:, motl(1, :) >= cc_cutoff);
    tom_emwrite(output_motl_fn, motl);
    check_em_file(output_motl_fn, motl);
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
    while true
        try
            % If this fails, catch command is run
            tom_emread(em_fn);
            break;
        catch ME
            fprintf('******\nWARNING:\n\t%s\n******', ME.message);
            tom_emwrite(em_fn, em_data)
        end
    end
end
