function parallel_sums(ptcl_start_idx, avg_batch_size, iteration, ...
    allmotl_fn_prefix, ref_fn_prefix, ptcl_fn_prefix, tomo_row, ...
    weight_fn_prefix, weight_sum_fn_prefix, iclass, process_idx)
% PARALLEL_SUMS creates raw sums and sums of Fourier weights sum in a batch.
%     PARALLEL_SUMS(
%         PTCL_START_IDX,
%         AVG_BATCH_SIZE,
%         ITERATION,
%         ALLMOTL_FN_PREFIX,
%         REF_FN_PREFIX,
%         PTCL_FN_PREFIX,
%         TOMO_ROW,
%         WEIGHT_FN_PREFIX,
%         WEIGHT_SUM_FN_PREFIX,
%         ICLASS,
%         PROCESS_IDX)
%
%     Aligns a subset of particles using the rotations and shifts in
%     ALLMOTL_FN_PREFIX_ITERATION starting from PTCL_START_IDX and with a subset
%     size of AVG_BATCH_SIZE to make a raw particle sum
%     REF_FN_PREFIX_ITERATION_PROCESS_IDX. Fourier weight volumes with name
%     prefix WEIGHT_FN_PREFIX will also be aligned and summed to make a weight
%     sum WEIGHT_SUM_FN_PREFIX_ITERATION_PROCESS_IDX. TOMO_ROW describes which
%     row of the motl file is used to determine the correct tomogram fourier
%     weight file. ICLASS describes which class outside of one is included in
%     the averaging. 
%
% Example:
%     PARALLEL_SUMS(1, 100, 3, 'combinedmotl/allmotl', 'ref/ref', ...
%         'subtomograms/subtomo', 5, 'otherinputs/ampspec', ...
%         'otherinputs/wei', 1, 1)
%
%     Would sum the first hundred particles, using particles with class number
%     1, and the first hundred corresponding weight volumes using the tomogram
%     number stored in the fifth row of the allmotl file
%     'combinedmotl/allmotl_3.em'. The function will write out the follwing
%     files:
%         * 'ref/ref_3_1.em' - The first subset of sums generated in parallel
%         * 'otherinputs/wei_3_1.em' - The corresponding subset sum of weights
%
% See also WEIGHTED_AVERAGE

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
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% ptcl_start_idx = 1;
% avg_batch_size = 100;
% iteration = 1;
% allmotl_fn_prefix = 'combinedmotl/allmotl';
% ref_fn_prefix = 'ref/ref';
% ptcl_fn_prefix = 'subtomograms/subtomo';
% tomo_row = 7;
% weight_fn_prefix = 'otherinputs/ampspec';
% weight_sum_fn_prefix = 'otherinputs/wei';
% iclass = 1;
% process_idx = 1;
%##############################################################################%
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

    % Initialize particle average and weight sum.
    temp_vol = getfield(tom_emread(sprintf('%s_%d.em', ptcl_fn_prefix, ...
        allmotl(4, ptcl_start_idx))), 'Value');

    ptcl_average = zeros(size(temp_vol));
    current_weight = 0;
    weight_sum = zeros(size(temp_vol));
    clear temp_vol

    % Calculate the end number of batch
    ptcl_end_idx = ptcl_start_idx + avg_batch_size - 1;
    % Set the end number within bounds of total particles
    if ptcl_end_idx > num_ptcls
        ptcl_end_idx = num_ptcls;
        avg_batch_size = ptcl_end_idx - ptcl_start_idx + 1;
    end

    %% Rotate and sum particles
    % Loop through each subtomogram
    for ptcl_idx = ptcl_start_idx:ptcl_end_idx
        % Check class of current subtomogram
        if     allmotl(20, ptcl_idx) == 1 ...
            || allmotl(20, ptcl_idx) == iclass ...
            || iclass == 0

            % Read in subtomogram
            ptcl = getfield(tom_emread(sprintf('%s_%d.em', ptcl_fn_prefix, ...
                allmotl(4, ptcl_idx))), 'Value');

            % Parse translations from motl
            % These translations describe the translation of the reference to
            % the particle after rotation has been applied to the reference. In
            % the motl they are ordered: X-axis shift, Y-axis shift, and Z-axis
            % shift.  They have the inverse description here in terms of the
            % particle shifting to the reference register.
            ptcl_shift = -allmotl(11:13, ptcl_idx);

            % Parse rotations from motl
            % These rotations describe the rotations of the reference to the
            % particle determined in alignment. In the motl they are ordered;
            % azimuthal rotation, inplane rotation, and zenithal rotation. They
            % have the inverse description here in terms of the particle
            % rotating to the reference orientation.
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
    fprintf('WROTE REFERENCE: %s\n', ref_fn);
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
    while true
        try
            % If this fails, catch command is run
            tom_emread(em_fn);
            break;
        catch ME
            fprintf('******\nWARNING:\n\t%s\n******', ME.message);
            tom_emwrite(em_fn, em_data)
        end
    end
end
