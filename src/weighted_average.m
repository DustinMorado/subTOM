function weighted_average(ref_fn_prefix, allmotl_fn_prefix, ...
    weight_fn_prefix, iteration, iclass)
% WEIGHTED_AVERAGE joins and weights parallel average subsets.
%     WEIGHTED_AVERAGE(
%         REF_FN_PREFIX,
%         MOTL_FN_PREFIX,
%         WEGIHT_FN_PREFIX,
%         ITERATION,
%         ICLASS)
%
%     Takes the parallel average subsets with the name prefix REF_FN_PREFIX, the
%     allmotl file with name prefix MOTL_FN_PREFIX and weight volume subsets
%     with the name prefix WEIGHT_FN_PREFIX to generate the final average, which
%     should then be used as the reference for iteration number ITERATION.
%     ICLASS describes which class outside of one is included in the final
%     average and is used to correctly scale the average and weights.
%
% Example:
%     WEIGHTED_AVERAGE('./ref/ref', './combinedmotl/allmotl', ...
%         './otherinputs/wei', 3, 1)
%
%   Would average all average batches './ref/ref_3_*.em', average all weights
%   './otherinputs/wei_3_*.em', using the particles with class number 1, apply
%   the inverse averaged weight to the average and write out:
%       * './ref/ref_debug_raw_3.em' - The unweighted average
%       * './ref/ref_3.em' - The weighted average
%       * './otherinputs/wei_debug_3.em' - The average weight volume
%       * './otherinputs/wei_debug_inv_3.em' - The inverse weight applied
%
% See also PARALLEL_SUMS

% Starting from one, but this version is most closly related to
% will_averageref_weighted2.
%
% This version has been updated to write out the raw
% average, unscaled weight sum, and inverted scaled weight sum.
%
% This version used in conjunction with lmb_parallel_create_average uses a more
% complicated weight volume than the original binary av3_wedge mask.
%
% DRM 10-2017
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% ref_fn_prefix = 'ref/ref';
% allmotl_fn_prefix = 'combinedmotl/allmotl';
% weight_fn_prefix = 'otherinputs/wei';
% iteration = 1;
% iclass = 0;
%##############################################################################%
    % Evaluate numeric inputs
    if ischar(iteration)
        iteration = str2double(iteration);
    end

    if ischar(iclass)
        iclass = str2double(iclass);
    end

    % Calculate the number of batches and also use this opportunity to make sure
    % we have equal number of average and weight files
    num_avg_batches = length(dir(...
        sprintf('%s_%d_*.em', ref_fn_prefix, iteration)));

    num_weight_batches = length(dir(sprintf('%s_%d_*.em', ...
        weight_fn_prefix, iteration)));

    if num_avg_batches ~= num_weight_batches
        error('ERROR: unequal number of avg, or weight files!');
    end

    num_batches = num_avg_batches;

    % Run the first batch outside of a loop to initialize volumes without having
    % to know the box size of particles and weights
    avg_sum = getfield(tom_emread(sprintf('%s_%d_1.em', ref_fn_prefix, ...
        iteration)), 'Value');

    weight_sum = getfield(tom_emread(sprintf('%s_%d_1.em', weight_fn_prefix, ...
        iteration)), 'Value');

    % Sum the remaining batch files
    for batch_idx = 2:num_batches
        avg_sum = avg_sum + getfield(tom_emread(sprintf('%s_%d_%d.em', ...
            ref_fn_prefix, iteration, batch_idx)), 'Value');

        weight_sum = weight_sum + getfield(tom_emread(sprintf('%s_%d_%d.em', ...
            weight_fn_prefix, iteration, batch_idx)), 'Value');
    end

    % We need to read in the allmotl for the next part
    allmotl = getfield(tom_emread(sprintf('%s_%d.em', allmotl_fn_prefix, ...
        iteration)), 'Value');

    % Find motls with the good classes and number of motls used in sums
    if iclass == 0
        % When iclass is 0 we have used all particles regardless of class value
        num_good_ptcls = size(allmotl, 2);
    else
        % When iclass is not zero then all particles with class value of 1 are
        % included in the average as well as particles with class value iclass
        num_good_ptcls = sum(allmotl(20, :) == 1 | allmotl(20, :) == iclass);
    end

    % Calculate and write-out the raw average from batches
    average = avg_sum ./ num_good_ptcls;
    average_fn = sprintf('%s_debug_raw_%d.em', ref_fn_prefix, iteration);
    tom_emwrite(average_fn, average);
    check_em_file(average_fn, average);

    % Calculate and write-out the average weight from batches
    weight_average = weight_sum ./ num_good_ptcls;
    weight_average_fn = sprintf('%s_debug_%d.em', weight_fn_prefix, iteration);
    tom_emwrite(weight_average_fn, weight_average);
    check_em_file(weight_average_fn, weight_average);

    % Calculate and write-out the average weight inverse that will reweight the
    % average
    weight_average_inverse = 1 ./ weight_average;

    % Find any inf (Infinity) values in the inverse and set them to zero
    inf_idxs = find(weight_average_inverse > 100000);
    if ~isempty(inf_idxs)
        weight_average_inverse(inf_idxs) = 0;
    end

    weight_average_inverse_fn = sprintf('%s_debug_inv_%d.em', ...
        weight_fn_prefix, iteration);

    tom_emwrite(weight_average_inverse_fn, weight_average_inverse);
    check_em_file(weight_average_inverse_fn, weight_average_inverse);

    % Apply the weight to the average
    average = fftshift(fftn(average));
    average = average .* weight_average_inverse;

    % Determine low pass filter dimensions, this filter takes out the last few
    % high frequency pixels, which dampens interpolation artefacts from
    % rotations etc.
    spheremask_radius = floor(size(average, 1) / 2) - 3;
    average = tom_spheremask(average, spheremask_radius);
    average = real(ifftn(ifftshift(average)));

    % Write-out the weighted average
    average_fn = sprintf('%s_%d.em', ref_fn_prefix, iteration);
    tom_emwrite(average_fn, average);
    check_em_file(average_fn, average);
    fprintf('WROTE AVERAGE: %s\n', average_fn);
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
