function lmb_join_motls(iteration, all_motl_fn_prefix, ptcl_motl_fn_prefix)
if (ischar(iteration))
    iteration = str2double(iteration);
end

num_ptcls = length(dir(sprintf('%s_*_%d.em', ptcl_motl_fn_prefix, ...
    iteration + 1)));

allmotl = getfield(tom_emread(sprintf('%s_1_%d.em', ptcl_motl_fn_prefix, ...
    iteration + 1)), 'Value');

for ptcl_idx = 2:num_ptcls
    allmotl(:, end + 1) = getfield(tom_emread(sprintf('%s_%d_%d.em', ...
        ptcl_motl_fn_prefix, ptcl_idx, iteration + 1)), 'Value');
end

allmotl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration + 1);
tom_emwrite(allmotl_fn, allmotl);
check_em_file(allmotl_fn, allmotl);

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
