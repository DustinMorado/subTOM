function dustin_parallel_create_average_subsets(...
        ptcl_start_idx,...
        avg_batch_size,...
        num_ptcls,...
        iteration,...
        motl_fn_prefix,...
        allmotl_fn_prefix,...
        ref_fn_prefix,...
        ptcl_fn_prefix,...
        weight_fn_prefix,...
        weight_sum_fn_prefix,...
        iclass,...
        process_idx)
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

if ischar(num_ptcls)
    num_ptcls = str2double(num_ptcls);
end

% Check that start is within bounds of dataset
% Previously this was a huge if conditional wrapping which seemed
% unneccessary so I just put it here and we exit right away if we
% are out of bounds.
if ptcl_start_idx > num_ptcls
    return
end

if ischar(iteration)
    iteration = str2double(iteration);
end

if ischar(iclass)
    iclass = str2double(iclass);
end

if ischar(process_idx)
    process_idx = str2double(process_idx);
end

% Read in first motl and first subtomo to get size of box
motl_fn = sprintf('%s_%d_%d.em', motl_fn_prefix, ptcl_start_idx, iteration);
motl = getfield(tom_emread(motl_fn), 'Value');
ref_fn = sprintf('%s_%d.em', ptcl_fn_prefix, motl(4, 1));
ref = tom_emread(ref_fn);

%% Initialize motl and averaging arrays
% Calculate the end number of batch
ptcl_end_idx = ptcl_start_idx + avg_batch_size - 1;
% Set the end number within bounds of total particles
if ( ptcl_end_idx > num_ptcls )
    ptcl_end_idx = num_ptcls;
    avg_batch_size = ptcl_end_idx - ptcl_start_idx + 1;
end

% Initialize allmotl array
allmotl = motl;
for ptcl_idx = (ptcl_start_idx + 1):ptcl_end_idx
    allmotl(:, end + 1) = getfield(tom_emread(sprintf('%s_%d_%d.em', ...
                                   motl_fn_prefix, ptcl_idx, iteration)), ...
                                   'Value');
end

% If iclass is 0 we keep all the particles otherwise we keep particles with
% iclass 1 or the user-supplied iclass value
if iclass == 0
    good_allmotl = allmotl;
else
    good_allmotl = allmotl(:, allmotl(20, :) == 1 | allmotl(20, :) == iclass);
end

num_good_ptcls = size(good_allmotl, 2);

% We calculate subsets in powers of two of the data but limit the smallest
% subset that contains at least 128 particles.
num_subsets = floor(log2(num_good_ptcls / 128)) + 1;

% Initialize particle sum array
ptcl_average_cell = {};
weight_sum_cell = {};
for subset_idx = 1:num_subsets
    ptcl_average_cell{subset_idx} = zeros(size(ref));
    weight_sum_cell{subset_idx} = zeros(size(ref));
end
current_weight = 0;

%% Rotate and sum particles
% Loop through each subtomogram
for motl_idx = 1:num_good_ptcls
    % Read in subtomogram
    ptcl_fn = sprintf('%s_%d.em', ptcl_fn_prefix, good_allmotl(4, motl_idx));
    ptcl = tom_emread(ptcl_fn);

    % Parse translations from motl
    % These translations describe the translation of the reference to the
    % particle after rotation has been applied to the reference. In the
    % motl they are ordered: X-axis shift, Y-axis shift, and Z-axis shift.
    % They have the inverse description here in terms of the particle
    % shifting to the reference register.
    ptcl_shift = -good_allmotl(11:13, motl_idx);

    % Parse rotations from motl
    % These rotations describe the rotations of the reference to the
    % particle determined in alignment. In the motl they are ordered;
    % azimuthal rotation, inplane rotation, and zenithal rotation. They
    % have the inverse description here in terms of the particle rotating
    % to the reference orientation.
    ptcl_rot = -good_allmotl([18, 17, 19], motl_idx);

    % Shift and rotate particle
    aligned_ptcl = tom_shift(ptcl.Value, ptcl_shift);
    aligned_ptcl = tom_rotate(aligned_ptcl, ptcl_rot);

    % Read in weight
    if current_weight ~= good_allmotl(5, motl_idx)
        current_weight = good_allmotl(5, motl_idx);
        weight_fn = sprintf('%s_%d.em', weight_fn_prefix, current_weight);
        weight = tom_emread(weight_fn);
    end

    % Rotate weight (We don't shift because this is Fourier space)
    aligned_weight = tom_rotate(weight.Value, ptcl_rot);

    % Add wedge and particle to sum arrays
    for subset_idx = 1:num_subsets
        if mod(motl_idx, 2 ^ (subset_idx - 1)) == 0
           ptcl_average_cell{subset_idx} =  ptcl_average_cell{subset_idx}...
                                          + aligned_ptcl; 
           weight_sum_cell{subset_idx} =  weight_sum_cell{subset_idx}...
                                        + aligned_weight;
        end
    end
end

for subset_idx = 1:num_subsets
    % Write out summed wedge-weighting array
    weight_sum_fn = sprintf('%s_%d_%d_subset%d.em', weight_sum_fn_prefix,...
                            iteration, process_idx, subset_idx);
    tom_emwrite(weight_sum_fn, weight_sum_cell{subset_idx});
    check_em_file(weight_sum_fn, weight_sum_cell{subset_idx});
    disp(['WROTE WEIGHT: ' weight_sum_fn]);

    % Write out summed reference
    ref_fn = sprintf('%s_%d_%d_subset%d.em', ref_fn_prefix, iteration,...
                     process_idx, subset_idx);
    tom_emwrite(ref_fn, ptcl_average_cell{subset_idx});
    check_em_file(ref_fn, ptcl_average_cell{subset_idx});
    disp(['WROTE REFERENCE: ' ref_fn]);
end

% Write out partial allmotl file
allmotl_fn = sprintf('%s_%d_%d.em', allmotl_fn_prefix, iteration, process_idx);
tom_emwrite(allmotl_fn, allmotl);
check_em_file(allmotl_fn, allmotl);
disp(['WROTE MOTIVELIST: ' allmotl_fn]);

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
