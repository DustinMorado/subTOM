function lmb_splitmotl_by_row(input_motl_fn, motl_row, output_motl_fn_prfx)
% LMB_SPLITMOTL_BY_ROW split a MOTL file by a given row.
% LMB_SPLITMOTL_BY_ROW(INPUT_MOTL_FN, MOTL_ROW, OUTPUT_MOTL_FN_PRFX) takes
%    the MOTL file specified by INPUT_MOTL_FN and writes out a seperate MOTL
%    file with OUTPUT_MOTL_FN_PRFX as the prefix where each output file
%    corresponds to a unique value of the row MOTL_ROW in INPUT_MOTL_FN.
% See also LMB_SPLITMOTL, LMB_UNBINMOTL

% DRM 05-2018
% ==============================================================================

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

%% check_em_file
% A function to check that an EM file was correctly written.
function check_em_file(em_fn, em_data)
while true
    try
        % If this fails, catch command is run
        tom_emread(em_fn);
        break;
    catch
        tom_emwrite(em_fn, em_data)
    end
end
