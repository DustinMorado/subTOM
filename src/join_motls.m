function join_motls(iteration, all_motl_fn_prefix, ptcl_motl_fn_prefix)
% JOIN_MOTLS combines individual subtomogram motive lists into a single allmotl.
%     JOIN_MOTLS(
%         ITERATION,
%         ALL_MOTL_FN_PREFIX,
%         PTCL_MOTL_FN_PREFIX)
%
%     Takes the individual subtomogram motive lists with the name format
%     PTCL_MOTL_FN_PREFIX_*_#.em where the * goes from 1 to the number of
%     subtomogram motive lists and where # is ITERATION + 1, and combines all of
%     them into a single motivelist that is written out as
%     ALL_MOTL_FN_PREFIX_#.em.
%
% Example:
%     JOIN_MOTLS(1, 'combinedmotl/allmotl', 'motls/motl')

% DRM 05-2018
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% iteration = 1;
% all_motl_fn_prefix = 'combinedmotl/allmotl';
% ptcl_motl_fn_prefix = ' motls/motl';
%##############################################################################%
    if ischar(iteration)
        iteration = str2double(iteration);
    end

    num_ptcls = length(dir(sprintf('%s_*_%d.em', ptcl_motl_fn_prefix, ...
        iteration + 1)));

    allmotl = zeros(20, num_ptcls);
    for ptcl_idx = 1:num_ptcls
        allmotl(:, ptcl_idx) = getfield(tom_emread(sprintf('%s_%d_%d.em', ...
            ptcl_motl_fn_prefix, ptcl_idx, iteration + 1)), 'Value');
    end

    allmotl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration + 1);
    tom_emwrite(allmotl_fn, allmotl);
    check_em_file(allmotl_fn, allmotl);
end

%% check_em_file
% A function to check that an EM file was correctly written.
function check_em_file(em_fn, em_data)
    while true
        try
            % If this fails, catch command is run
            tom_emread(em_fn);
            break;
        catch ME
            ME.message
            tom_emwrite(em_fn, em_data);
        end
    end
end
