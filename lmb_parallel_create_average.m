function lmb_parallel_create_average(ptcl_start_idx, avg_batch_size, ...
    iteration, allmotl_fn_prefix, ref_fn_prefix, ptcl_fn_prefix, ...
    tomo_row, weight_fn_prefix, weight_sum_fn_prefix, iclass, process_idx)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Info
% Just starting from one, for averaging but closest to
% will_parallel_create_average4.
%
% As opposed to the av3_wedge object to handle the missing wedge an outside
% calculated fourier weight is used. Ideally as of now this is an approximate
% amplitude spectrum volume of the tomogram the particle was extracted from.
% There is a script to generate this volume from noise positions in the
% tomograms.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialize numeric inputs
if ischar(ptcl_start_idx)
    ptcl_start_idx = str2double(ptcl_start_idx);
end

if ischar(avg_batch_size)
    avg_batch_size = str2double(avg_batch_size);
end

if ischar(iteration)
    iteration = str2double(iteration);
end

if ischar(tomo_row)
    tomo_row = str2double(tomo_row);
end

if ischar(iclass)
    iclass = str2double(iclass);
end

if ischar(process_idx)
    process_idx = str2double(process_idx);
end

% Read in allmotl and first subtomo and weight to skip finding boxsize
allmotl = getfield(tom_emread(sprintf('%s_%d.em', allmotl_fn_prefix, ...
    iteration)), 'Value');

% Check that start is within bounds of dataset
% Previously this was a huge if conditional wrapping which seemed
% unneccessary so I just put it here and we exit right away if we
% are out of bounds.
num_ptcls = size(allmotl, 2);
if ptcl_start_idx > num_ptcls
    return
end

ptcl_average = getfield(tom_emread(sprintf('%s_%d.em', ptcl_fn_prefix, ...
    allmotl(4, ptcl_start_idx))), 'Value');

current_weight = allmotl(tomo_row, ptcl_start_idx);
weight_sum = getfield(tom_emread(sprintf('%s_%d.em', weight_fn_prefix, ...
    current_weight)), 'Value');

% Calculate the end number of batch
ptcl_end_idx = ptcl_start_idx + avg_batch_size - 1;
% Set the end number within bounds of total particles
if ptcl_end_idx > num_ptcls
    ptcl_end_idx = num_ptcls;
    avg_batch_size = ptcl_end_idx - ptcl_start_idx + 1;
end

%% Rotate and sum particles
% Loop through each subtomogram
for ptcl_idx = (ptcl_start_idx + 1):ptcl_end_idx
    % Check class of current subtomogram
    if     allmotl(20, ptcl_idx) == 1 ...
        || allmotl(20, ptcl_idx) == iclass ...
        || iclass == 0

        % Read in subtomogram
        ptcl = getfield(tom_emread(sprintf('%s_%d.em', ptcl_fn_prefix, ...
            allmotl(4, ptcl_idx))), 'Value');

        % Parse translations from motl
        % These translations describe the translation of the reference to the
        % particle after rotation has been applied to the reference. In the
        % motl they are ordered: X-axis shift, Y-axis shift, and Z-axis shift.
        % They have the inverse description here in terms of the particle
        % shifting to the reference register.
        ptcl_shift = -allmotl(11:13, ptcl_idx);

        % Parse rotations from motl
        % These rotations describe the rotations of the reference to the
        % particle determined in alignment. In the motl they are ordered;
        % azimuthal rotation, inplane rotation, and zenithal rotation. They
        % have the inverse description here in terms of the particle rotating
        % to the reference orientation.
        ptcl_rot = -allmotl([18, 17, 19], ptcl_idx);

        % Shift and rotate particle
        aligned_ptcl = tom_shift(ptcl, ptcl_shift);
        aligned_ptcl = tom_rotate(aligned_ptcl, ptcl_rot);

        % Read in weight
        if current_weight ~= allmotl(tomo_row, ptcl_idx)
            current_weight = allmotl(tomo_row, ptcl_idx);
            weight = getfield(tom_emread(sprintf('%s_%d.em', ...
                weight_fn_prefix, current_weight)), 'Value');
        end

        % Rotate weight (We don't shift because this is Fourier space)
        aligned_weight = tom_rotate(weight, ptcl_rot);

        % Add wedge and particle to sum arrays
        weight_sum = weight_sum + aligned_weight;
        ptcl_average = ptcl_average + aligned_ptcl;

    end
end

% Write out summed wedge-weighting array
weight_sum_fn = sprintf('%s_%d_%d.em', weight_sum_fn_prefix, iteration,...
                        process_idx);
tom_emwrite(weight_sum_fn, weight_sum);
check_em_file(weight_sum_fn, weight_sum);
disp(['WROTE WEIGHT: ' weight_sum_fn]);

% Write out summed reference
ref_fn = sprintf('%s_%d_%d.em', ref_fn_prefix, iteration, process_idx);
tom_emwrite(ref_fn, ptcl_average);
check_em_file(ref_fn, ptcl_average);
disp(['WROTE REFERENCE: ' ref_fn]);

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
