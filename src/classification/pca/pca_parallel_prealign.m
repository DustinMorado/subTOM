function pca_parallel_prealign(all_motl_fn_prefix, ptcl_fn_prefix, ...
    prealign_fn_prefix, iteration, num_prealign_batch, process_idx)
% PCA_PARALLEL_PREALIGN prealigns particles to speed up ccmatrix calculation.
%     PCA_PARALLEL_PREALIGN(
%         ALL_MOTL_FN_PREFIX,
%         PTCL_FN_PREFIX,
%         PREALIGN_FN_PREFIX,
%         ITERATION,
%         NUM_PREALIGN_BATCH,
%         PROCESS_IDX)
%
%     Prerotates and translates particles into alignment as precalculation on
%     disk to speed up the calculation of the constrained cross-correlation
%     matrix. The alignments are given in the motive list,
%     ALL_MOTL_FN_PREFIX_ITERATION.em, and the particles are specified as
%     PTCL_FN_PREFIX_#.em where # is described in row 4 of the motive list.
%     Pre-aligned particles will be written as PREALIGN_FN_PREFIX_#.em. The
%     process is designed to be run in parallel on a cluster. The particles will
%     be processed in NUM_PREALIGN_BATCH chunks, with the specific chunk being
%     processed described by PROCESS_IDX.
%
% Example:
%     PCA_PARALLEL_PREALIGN('combinedmotl/allmotl', 'subtomograms/subtomo',
%         'subtomograms/subtomo_align', 1, 256, 1)
%
%     Would prealign the particles in the motive list combinedmotl/allmotl_1.em,
%     where the particles subtomograms/subtomo_*.em, and write out the
%     prealigned particles as subtomograms/subtomo_align_*.em. The motive list
%     would be split into 256 chunks and this call to the function would process
%     the first chunk.
%
% See Also: PCA_PREPARE_CCMATRIX, PCA_PARALLEL_CCMATRIX, PCA_PARALLEL_XMATRIX

% DRM 03-2019
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% all_motl_fn_prefix = 'combined/allmotl';
% ptcl_fn_prefix = 'subtomograms/subtomo';
% prealign_fn_prefix = 'subtomograms/subtomo_align';
% iteration = 1;
% num_prealign_batch = 256;
% process_idx = 1;
%##############################################################################%
    % Evaluate numeric inputs
    if ischar(iteration)
        iteration = str2double(iteration);
    end

    if isnan(iteration) || rem(iteration, 1) ~= 0
        try
            error('subTOM:argumentError', ...
                'pca_parallel_prealign:iteration: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(num_prealign_batch)
        num_prealign_batch = str2double(num_prealign_batch);
    end

    if isnan(num_prealign_batch) || num_prealign_batch < 1 || ...
        rem(num_prealign_batch, 1) ~= 0

        try
            error('subTOM:argumentError', ...
                'pca_parallel_prealign:num_prealign_batch: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(process_idx)
        process_idx = str2double(process_idx);
    end

    if isnan(process_idx) || process_idx < 1 || ...
        process_idx > num_prealign_batch || rem(process_idx, 1) ~= 0

        try
            error('subTOM:argumentError', ...
                'pca_parallel_prealign:process_idx: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Read in motive list
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(fullfile(pwd(), all_motl_fn), 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'pca_parallel_prealign:File %s does not exist.', all_motl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl = getfield(tom_emread(all_motl_fn), 'Value');

    if size(all_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'pca_parallel_prealign:%s is not proper MOTL.', all_motl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    num_ptcls = size(all_motl, 2);

    if num_prealign_batch > num_ptcls
        try
            error('subTOM:argumentError', ...
                'pca_parallel_prealign:%s', ...
                'num_prealign_batch is greater than num_ptcls.');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Calculate the number and indices of particles to process
    prealign_batch_size = floor(num_ptcls / num_prealign_batch);

    if process_idx > (num_ptcls - (prealign_batch_size * num_prealign_batch))
        ptcl_start_idx = (process_idx - 1) * prealign_batch_size + 1 + ...
            (num_ptcls - (prealign_batch_size * num_prealign_batch));

        ptcl_end_idx = ptcl_start_idx + prealign_batch_size - 1;
    else
        ptcl_start_idx = (process_idx - 1) * (prealign_batch_size + 1) + 1;
        ptcl_end_idx = ptcl_start_idx + prealign_batch_size;
    end
    
    batch_size = ptcl_end_idx - ptcl_start_idx + 1;

    % Some variables for showing progress
    delprog = '';
    delprog_batch = max(floor(batch_size / 200), 1);
    batch_idx = 1;
    timings = [];
    tic;

    for ptcl_idx = ptcl_start_idx:ptcl_end_idx
        % Make sure that the particle hasn't already been done
        ptcl_fn = sprintf('%s_%d_%d.em', prealign_fn_prefix, iteration, ...
            all_motl(4, ptcl_idx));

        if exist(fullfile(pwd(), ptcl_fn), 'file') == 2
            warning('subTOM:recoverOnFail', ...
                'pca_parallel_prealign:%s exists. SKIPPING!', ptcl_fn);

            % Display some output
            if mod(batch_idx, delprog_batch) == 0
                elapsed_time = toc;
                timings = [timings elapsed_time];
                delprog = disp_progbar(process_idx, batch_size, batch_idx, ...
                    timings, delprog);
                tic;
            end

            batch_idx = batch_idx + 1;
            continue;
        end

        % Read in the particle
        ptcl_fn = sprintf('%s_%d.em', ptcl_fn_prefix, all_motl(4, ptcl_idx));

        if exist(fullfile(pwd(), ptcl_fn), 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'pca_parallel_prealign:File %s does not exist.', ptcl_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        ptcl = getfield(tom_emread(ptcl_fn), 'Value');

        % Get the shifts and rotations to align the particle
        ptcl_shift = -all_motl(11:13, ptcl_idx);
        ptcl_rot = -all_motl([18, 17, 19], ptcl_idx);

        % Align the particle and its weight
        % I am applying the mask here in case someone gives a softmask, in
        % practice I should be able to skip that product since I only pass the
        % masked indices to the x-matrix, but I think that would confuse the
        % user if they saw that result after passing a soft mask.
        ptcl = tom_rotate(tom_shift(ptcl, ptcl_shift), ptcl_rot);

        % Write out the aligned particle
        ptcl_fn = sprintf('%s_%d_%d.em', prealign_fn_prefix, iteration, ...
            all_motl(4, ptcl_idx));
        tom_emwrite(ptcl_fn, ptcl);
        check_em_file(ptcl_fn, ptcl);

        % Display some output
        if mod(batch_idx, delprog_batch) == 0
            elapsed_time = toc;
            timings = [timings elapsed_time];
            delprog = disp_progbar(process_idx, batch_size, batch_idx, ...
                timings, delprog);

            tic;
        end

        batch_idx = batch_idx + 1;
    end
end
