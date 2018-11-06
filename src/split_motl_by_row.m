function split_motl_by_row(input_motl_fn, motl_row, output_motl_fn_prfx)
% SPLIT_MOTL_BY_ROW split a MOTL file by a given row.
%     SPLIT_MOTL_BY_ROW(
%         INPUT_MOTL_FN,
%         MOTL_ROW,
%         OUTPUT_MOTL_FN_PRFX)
%
%    Takes the MOTL file specified by INPUT_MOTL_FN and writes out a seperate
%    MOTL file with OUTPUT_MOTL_FN_PRFX as the prefix where each output file
%    corresponds to a unique value of the row MOTL_ROW in INPUT_MOTL_FN.
%
% Example:
%     SPLIT_MOTL_BY_ROW('combinedmotl/allmotl_1.em', 7, ...
%         'combinedmotl/allmotl_1_tomo')
%
% See also SCALE_MOTL

% DRM 05-2018
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% input_motl_fn = 'input_motl.em';
% motl_row = 7;
% output_motl_fn_prefix = 'output_motl_tomo'
%##############################################################################%
    % Evaluate numeric inputs
    if ischar(motl_row)
        motl_row = str2double(motl_row);
    end

    input_motl = getfield(tom_emread(input_motl_fn), 'Value');
    row_values = unique(input_motl(motl_row, :));
    num_outputs = size(row_values, 2);
    output_motl_fmt = sprintf('%s_%%0%dd.em', output_motl_fn_prfx, ...
        length(num2str(num_outputs)));

    for row_value = row_values
        split_motl = input_motl(:, input_motl(motl_row, :) == row_value);
        split_motl_fn = sprintf(output_motl_fmt, row_value);
        tom_emwrite(split_motl_fn, split_motl);
        check_em_file(split_motl_fn, split_motl);
    end
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
