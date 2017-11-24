function lmb_parallel_sums_subsets(ptcl_start_idx, avg_batch_size, ...
    iteration, allmotl_fn_prefix, ref_fn_prefix, ptcl_fn_prefix, tomo_row, ...
    weight_fn_prefix, weight_sum_fn_prefix, iclass, process_idx)
% LMB_PARALLEL_SUMS_SUBSETS creates subsets of raw sums and weight sum subsets.
%   LMB_PARALLEL_SUMS_SUBSETS(PTCL_START_IDX, AVG_BATCH_SIZE, ITERATION,
%   ALLMOTL_FN_PREFIX, REF_FN_PREFIX, PTCL_FN_PREFIX, TOMO_ROW,
%   WEIGHT_FN_PREFIX, WEIGHT_SUM_FN_PREFIX, ICLASS, PROCESS_IDX) aligns a subset
%   of particles using the rotations and shifts in ALLMOTL_FN_PREFIX_ITERATION
%   starting from PTCL_START_IDX and with a subset size of AVG_BATCH_SIZE to
%   make a raw particle sum REF_FN_PREFIX_ITERATION_PROCESS_IDX. Fourier weight
%   volumes with name prefix WEIGHT_FN_PREFIX will also be aligned and summed to
%   make a weight sum WEIGHT_SUM_FN_PREFIX_ITERATION_PROCESS_IDX. TOMO_ROW
%   describes which row of the motl file is used to determine the correct
%   tomogram fourier weight file. ICLASS describes which class outside of one is
%   included in the averaging. 
%
% The difference between this function and LMB_PARALLEL_SUMS is that this
% function creates a number of subsets of the particle and weight sum subsets,
% so that smaller and smaller populations of data are summed, and these
% subsets can then be used to estimate the B Factor of the structure.
%
% Example: LMB_PARALLEL_SUMS_SUBSETS(1, 100, 3, 'combinedmotl/allmotl', ...
%       'ref/ref', 'subtomograms/subtomo', 5, 'otherinputs/ampspec', ...
%       'otherinputs/wei', 1, 1)
%   Would sum the first hundred particles, using particles with class number 1,
%   and the first hundred corresponding weight volumes using the tomogram number
%   stored in the fifth row of the allmotl file 'combinedmotl/allmotl_3.em'. The
%   function will write out the follwing files:
%       * 'ref/ref_3_1_subset*.em' - The subsets of the first subset of sums
%                                    generated in parallel
%       * 'otherinputs/wei_3_1_subset*.em' - The subsets of the corresponding
%                                            subset sum of weights
%
% See also LMB_PARALLEL_SUMS LMB_WEIGHTED_AVERAGE_SUBSETS

% Just starting from one, for averaging but closest to
% will_parallel_create_average4.
%
% As opposed to the av3_wedge object to handle the missing wedge an outside
% calculated fourier weight is used. Ideally as of now this is an approximate
% amplitude spectrum volume of the tomogram the particle was extracted from.
% There is a script to generate this volume from noise positions in the
% tomograms.
%
% DRM 11-2017
% ==============================================================================

% Evaluate numeric inputs
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

% Calculate the end number of batch
ptcl_end_idx = ptcl_start_idx + avg_batch_size - 1;
% Set the end number within bounds of total particles
if ( ptcl_end_idx > num_ptcls )
    ptcl_end_idx = num_ptcls;
    avg_batch_size = ptcl_end_idx - ptcl_start_idx + 1;
end

% We calculate subsets in powers of two of the data but limit the smallest
% subset that contains at least 128 particles.
if iclass == 0
    % When iclass is 0 we have used all particles regardless of class value
    num_good_ptcls = num_ptcls;
else
    % When iclass is not zero then all particles with class value of 1 are
    % included in the average as well as particles with class value iclass
    num_good_ptcls = sum(allmotl(20, :) == 1 | allmotl(20, :) == iclass);
end
num_subsets = floor(log2(num_good_ptcls / 128)) + 1;

% Initialize particle sum array
% Normally you can run one iteration out of the loop to get the box sizes, but
% it's too complicated with the subsets so we just read the first particle and
% that gives us the size to initialize the cell arrays.
temp_vol = getfield(tom_emread(sprintf('%s_%d.em', ptcl_fn_prefix, ...
    allmotl(4, 1))), 'Value');

ptcl_average_cell = {};
weight_sum_cell = {};
for subset_idx = 1:num_subsets
    ptcl_average_cell{subset_idx} = zeros(size(temp_vol));
    weight_sum_cell{subset_idx} = zeros(size(temp_vol));
end
current_weight = 0;
clear temp_vol

%% Rotate and sum particles
% Loop through each subtomogram
for ptcl_idx = ptcl_start_idx:ptcl_end_idx
    if allmotl(20, ptcl_idx) ~= 1 && allmotl(20, ptcl_idx) ~= iclass &&
            iclass ~= 0
        continue
    end

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
        weight = getfield(tom_emread(sprintf('%s_%d.em', weight_fn_prefix, ...
            current_weight)), 'Value');
    end

    % Rotate weight (We don't shift because this is Fourier space)
    aligned_weight = tom_rotate(weight, ptcl_rot);

    % Add wedge and particle to sum arrays
    for subset_idx = 1:num_subsets
        if mod(ptcl_idx, 2 ^ (subset_idx - 1)) == 0
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
