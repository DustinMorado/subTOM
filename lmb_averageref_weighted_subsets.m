function julia_multiref_lmb_averageref_weighted_subsets(avg_fn_prefix, allmotl_fn_prefix,...
                                         weight_fn_prefix, iteration, class)
% LMB_AVERAGEREF_WEIGHTED_SUBSETS joins and weights subsets of average subsets.
%   LMB_AVERAGEREF_WEIGHTED_SUBSETS(REF_FN_PREFIX, MOTL_FN_PREFIX,
%   WEGIHT_FN_PREFIX, ITERATION, ICLASS) takes the parallel average subsets with
%   the name prefix REF_FN_PREFIX, the motl files subsets with name prefix
%   MOTL_FN_PREFIX and weight volume subsets with the name prefix
%   WEIGHT_FN_PREFIX to generate the final average, which should then be used
%   as the reference for iteration number ITERATION. ICLASS describes which
%   class outside of one is included in the final average and is used to
%   correctly scale the average and weights.
%
% The difference between this function and LMB_AVERAGEREF_WEIGHTED is that this
% function expects there to be a number of subsets of the average subsets, so
% that smaller and smaller populations of data are averaged, and these subsets
% can then be used to estimate the B Factor of the structure.
%
% Example: LMB_AVERAGEREF_WEIGHTED_SUBSETS('./ref/ref', ...
%                                          './combinedmotl/allmotl', ...
%                                          './otherinputs/wei', 3, 1)
%   Would average all average batches './ref/ref_3_*_subset*.em', average all 
%   weights './otherinputs/wei_3_*_subset*.em', using the particles with class
%   number 1, apply the inverse averaged weight to the average and write out:
%       * './ref/ref_debug_raw_3_subset*.em' - The unweighted averages
%       * './ref/ref_3_subset_*.em' - The weighted averages
%       * './otherinputs/wei_debug_3_subset*.em' - The average weight volumes
%       * './otherinputs/wei_debug_inv_3_subset*.em' - The inverse weights
%       * './combinedmotl/allmotl_3.em' - The MOTL list for the next iteration
%
% See also LMB_AVERAGEREF_WEIGHTED LMB_PARALLEL_CREATE_AVERAGE_SUBSETS

% Starting from one, but this version is most closly related to
% will_averageref_weighted2.
%
% This version has been updated to write out the raw average, unscaled weight
% sum, and inverted scaled weight sum.
%
% This version used in conjunction with lmb_parallel_create_average_subsets uses
% a more complicated weight volume than the original binary av3_wedge mask, as
% well as working with halves and halves of particle subsets as a way to
% estimate the B Factor based on Figure 11 in Rosenthal and Henderson 2003.
%
% DRM 10-2017
% =============================================================================

% Evaluate numeric inputs
if ischar(iteration)
    iteration = str2double(iteration);
end

if ischar(class)
    iclass = str2double(class);
end

%read in allmotl and determine the class name
allmotl_fn = sprintf('%s%d.em', allmotl_fn_prefix, iteration);
allmotl=emread(allmotl_fn);

classes=unique(allmotl(20,:));
class_name=classes(class);
allmotl_class=allmotl(:,allmotl(20,:)==classes(class));
num_ptcls=size(allmotl_class,2);
% Calculate the number of batches and also use this opportunity to make sure we
% have an equal number of averages, weights and motl files
%num_motl_batches   = length(dir(sprintf('%s_%d_*.em', ...
%                                        motl_fn_prefix, iteration)));
num_avg_batches = length(dir(sprintf('%s_%d_%d_*_subset1.em', avg_fn_prefix, class_name,  ...
                                     iteration)));

num_weight_batches = length(dir(sprintf('%s_%d_%d_*_subset1.em', ...
                                        weight_fn_prefix, class_name, iteration)));

if ~ (num_weight_batches == num_avg_batches)
      error('ERROR: unequal number of motl, avg, or weight files!');
end

num_batches = num_motl_batches;
clear num_avg_batches num_weight_batches;

% We calculate subsets in powers of two of the data but limit the smallest
% subset that contains at least 128 particles.
num_subsets = floor(log2(num_ptcls / 128)) + 1;

% Run the first batch outside of a loop to initialize volumes without having to
% know the box size of particles and weights
%allmotl = getfield(tom_emread(sprintf('%s_%d_1.em', motl_fn_prefix, ...
                                      %iteration)), 'Value');
avg_sum_cell = {};
weight_sum_cell = {};
for subset_idx = 1:num_subsets
    avg_sum_cell{subset_idx} = getfield( ...
        tom_emread(sprintf('%s_%d_1_subset%d.em', avg_fn_prefix, iteration, ...
                           subset_idx)), 'Value');
    weight_sum_cell{subset_idx} = getfield( ...
        tom_emread(sprintf('%s_%d_1_subset%d.em', weight_fn_prefix, ...
                           iteration, subset_idx)), 'Value');
end

% Sum remaining reference files
for batch_idx = 2:num_batches
    motl = tom_emread(sprintf('%s_%d_%d.em', motl_fn_prefix, iteration, ...
                              batch_idx));
    allmotl = cat(2, allmotl, motl.Value);

    for subset_idx = 1:num_subsets
        avg = tom_emread(sprintf('%s_%d_%d_subset%d.em', avg_fn_prefix, ...
                                 iteration, batch_idx, subset_idx));
        avg_sum_cell{subset_idx} =  avg_sum_cell{subset_idx} + avg.Value;
        weight = tom_emread(sprintf('%s_%d_%d_subset%d.em', ...
                                    weight_fn_prefix, iteration, batch_idx, ...
                                    subset_idx));
        weight_sum_cell{subset_idx} =  weight_sum_cell{subset_idx} ...
                                     + weight.Value;
    end
end

% Write out allmotl file
allmotl_fn = sprintf('%s_%d.em', motl_fn_prefix, iteration);
tom_emwrite(allmotl_fn, allmotl);
check_em_file(allmotl_fn, allmotl);
disp(['WROTE MOTIVELIST: ', allmotl_fn]);

% motl_idx_array is just an array with allmotl indices for counting.
motl_idx_array = 1:length(allmotl);
for subset_idx = 1:num_subsets
    % Find motls with the good classes and belonging to the proper subset
    % When iclass is 0 we have used all particles regardless of class value
    if iclass == 0
        % When the ptcl_idx is divisible by the subset number (minus one) then
        % it belongs to the subset
        subset_ptcl_mask = mod(motl_idx_array, 2^(subset_idx - 1)) == 0;
        num_good_ptcls = sum(subset_ptcl_mask);
    else
        subset_ptcl_mask = mod(motl_idx_array, 2^(subset_idx - 1)) == 0;
        % When ptcl belongs to iclass 1 or the user-supplied iclass value it
        % belongs to the subset
        iclass_ptcl_mask = allmotl(20, :) == 1 | allmotl(20, :) == iclass;
        num_good_ptcls = sum(subset_ptcl_mask & iclass_ptcl_mask);
    end

    % Calculate and write-out the raw subset average from batches
    average = avg_sum_cell{subset_idx} ./ num_good_ptcls;
    average_fn = sprintf('%s_debug_raw_%d_subset%d.em', avg_fn_prefix,...
                         iteration, subset_idx);
    tom_emwrite(average_fn, average);
    check_em_file(average_fn, average);

    % Calculate and write-out the average weight subset from batches
    weight_average = weight_sum_cell{subset_idx} ./ num_good_ptcls;
    weight_average_fn = sprintf('%s_debug_%d_subset%d.em', ...
                            weight_fn_prefix, iteration, subset_idx);
    tom_emwrite(weight_average_fn, weight_average);
    check_em_file(weight_average_fn, weight_average);

    % Calculate and write-out the average weight inverse subset that will
    % reweight the average
    weight_average_inverse = 1 ./ weight_average;

    % Find any inf (Infinity) values in the inverse and set them to zero
    inf_idxs = find(weight_average_inverse > 100000);
    if ~isempty(inf_idxs)
        weight_average_inverse(inf_idxs) = 0;
    end

    weight_average_inverse_fn = sprintf('%s_debug_inv_%d_subset%d.em', ...
        weight_fn_prefix, iteration, subset_idx);
    tom_emwrite(weight_average_inverse_fn, weight_average_inverse);
    check_em_file(weight_average_inverse_fn, weight_average_inverse);

    % Apply the weight to the average
    average = fftshift(tom_fourier(average));
    average = average .* weight_average_inverse;

    % Determine low pass filter dimensions, this filter takes out the last few
    % high frequency pixels, which dampens interpolation artefacts from
    % rotations etc.
    spheremask_radius = floor(size(average, 1) / 2) - 3;
    average = tom_spheremask(average, spheremask_radius);
    average = real(tom_ifourier(ifftshift(average)));
    
    % Write-out the weighted average
    average_fn = sprintf('%s_%d_subset%d.em', avg_fn_prefix, iteration,...
                         subset_idx);
    tom_emwrite(average_fn, average);
    check_em_file(average_fn, average);
    disp(['WROTE AVERAGE: ', average_fn]);
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
