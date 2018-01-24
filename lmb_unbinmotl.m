function lmb_unbinmotl(input_motl_fn, output_motl_fn, unbin_factor)
if ischar(unbin_factor)
    unbin_factor = str2double(unbin_factor);
end

input_motl = getfield(tom_emread(input_motl_fn), 'Value');
output_motl = input_motl;
output_motl(11:13, :) = (input_motl(8:10, :) + input_motl(11:13, :)) ...
    .* unbin_factor;

output_motl(8:10, :) = floor(output_motl(11:13, :));
output_motl(11:13, :) = output_motl(11:13, :) - output_motl(8:10, :);

tom_emwrite(output_motl_fn, output_motl);
check_em_file(output_motl_fn, output_motl);

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
