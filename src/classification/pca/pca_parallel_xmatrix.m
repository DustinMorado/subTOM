function pca_parallel_xmatrix(all_motl_fn_prefix, xmatrix_fn_prefix, ...
    weight_fn_prefix, xmatrix_weight_fn_prefix, ptcl_fn_prefix, mask_fn, ...
    iteration, tomo_row, prealigned, num_xmatrix_batch, process_idx)
% PCA_PARALLEL_XMATRIX calculates chunks of the X (data) matrix for processing
%     PCA_PARALLEL_XMATRIX(
%         ALL_MOTL_FN_PREFIX,
%         XMATRIX_FN_PREFIX,
%         WEIGHT_FN_PREFIX,
%         XMATRIX_WEIGHT_FN_PREFIX,
%         PTCL_FN_PREFIX,
%         MASK_FN,
%         ITERATION,
%         TOMO_ROW,
%         REALIGNED,
%         NUM_XMATRIX_BATCH,
%         PROCESS_IDX)
%
%     Aligns a subset of particles using the rotations and shifts in
%     ALL_MOTL_FN_PREFIX_ITERATION.em and then places these voxels as a 1-D row
%     vector in a data sub-matrix which is historically known as the X-matrix
%     (See Borland, Van Heel 1990 J. Opt. Soc. Am. A). This X-matrix can then be
%     used to speed up the calculation of Eigenvolumes and Eigencoefficients
%     used for classification. The subset of particles compared is specified by
%     the number of particles in the motive list and the number of requested
%     batches specified by NUM_XMATRIX_BATCH, with the specific subset
%     deteremined by PROCESS_IDX. The X-matrix chunk will be written out as
%     XMATRIX_FN_PREFIX_ITERATION_PROCESS_IDX.em. The amplitude weights, given
%     by WEIGHT_FN_PREFIX_#.em where # is the number corresponding to the
%     tomogram from which the particle belongs to, from the row TOMO_ROW in the
%     motive list, are also rotated and summed for all particles in the chunk so
%     that the later calculated Eigenvolumes and Eigencoefficients can be
%     reweighted. These weight sums will be written out as
%     XMATRIX_WEIGHT_FN_PREIFX_ITERATION_PROCESS_IDX.em. The location of the
%     particles is specified by PTCL_FN_PREFIX. If PREALIGNED evaluates to true
%     as a boolean then the particles are assumed to be prealigned, which should
%     increase speed of computation of CC-Matrix calculations. Particles in the
%     X-matrix will be masked by the file given by MASK_FN. If the string 'none'
%     is used in place of MASK_FN, a default spherical mask is applied. This
%     mask should be a binary mask and only voxels within the mask are placed
%     into the X-matrix which can greatly speed up computations.
%
% Example:
%     PCA_PARALLEL_XMATRIX('combinedmotl/allmotl', 'pca/xmatrix',
%         'otherinputs/ampspec', 'pca/xmatrix_wei','subtomograms/subtomo',
%         'otherinputs/pca_mask.em', 1, 7, 0, 256, 1)
%
%     Would build the X-matrix over 256 chunks with the particles
%     subtomograms/subtomo_*.em as specified with the motive list
%     combinedmotl/allmotl_1.em. The particles will be masked with
%     otherinputs/pca_mask.em and the amplitude weights otherinputs/ampspec_*.em
%     will be rotated and summed getting the proper weight file from row 7 of
%     the motive list. The files output will be pca/xmatrix_1_1.em which is
%     the first chunk of the X-matrix, and pca/xmatrix_wei_1_1.em which is the
%     summed amplitude weight of the first chunk.

% DRM 02-2019
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% all_motl_fn_prefix = 'combined/allmotl';
% xmatrix_fn_prefix = 'pca/xmatrix';
% weight_fn_prefix = 'otherinputs/ampspec';
% xmatrix_weight_fn_prefix = 'pca/xmatrix_wei';
% ptcl_fn_prefix = 'subtomograms/subtomo';
% mask_fn = 'otherinputs/pca_mask.em';
% iteration = 1;
% tomo_row = 7;
% prealigned = 0;
% num_xmatrix_batch = 256;
% process_idx = 1;
%##############################################################################%
    % Evaluate numeric inputs
    if ischar(iteration)
        iteration = str2double(iteration);
    end

    if isnan(iteration) || rem(iteration, 1) ~= 0
        try
            error('subTOM:argumentError', ...
                'pca_parallel_xmatrix:iteration: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(tomo_row)
        tomo_row = str2double(tomo_row);
    end

    if isnan(tomo_row) || tomo_row < 1 || tomo_row > 20 || rem(tomo_row, 1) ~= 0
        try
            error('subTOM:argumentError', ...
                'pca_parallel_xmatrix:tomo_row: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(prealigned)
        prealigned = str2double(prealigned);
    end

    if isnan(prealigned)
        try
            error('subTOM:argumentError', ...
                'pca_parallel_xmatrix:prealigned: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ~ (prealigned == 1 || prealigned == 0)
        warning('subTOM:argumentWarning', ...
            'pca_parallel_xmatrix:prealigned: argument unexpected');
        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
    end

    prealigned = logical(prealigned);

    if ischar(num_xmatrix_batch)
        num_xmatrix_batch = str2double(num_xmatrix_batch);
    end

    if isnan(num_xmatrix_batch) || num_xmatrix_batch < 1 || ...
        rem(num_xmatrix_batch, 1) ~= 0

        try
            error('subTOM:argumentError', ...
                'pca_parallel_xmatrix:num_xmatrix_batch: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(process_idx)
        process_idx = str2double(process_idx);
    end

    if isnan(process_idx) || process_idx < 1 || ...
        process_idx > num_xmatrix_batch || rem(process_idx, 1) ~= 0

        try
            error('subTOM:argumentError', ...
                'pca_parallel_xmatrix:process_idx: argument invalid');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    %##########################################################################%
    %                         CHECK IF ALREADY CALCULATED                      %
    %##########################################################################%
    xmatrix_fn = sprintf('%s_%d_%d.em', xmatrix_fn_prefix, iteration, ...
        process_idx);

    if exist(fullfile(pwd(), xmatrix_fn), 'file') == 2
        warning('subTOM:recoverOnFail', ...
            'pca_parallel_xmatrix:File %s already exists. SKIPPING!', ...
            xmatrix_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    %##########################################################################%
    %                              PREPARE ALL MOTL                            %
    %##########################################################################%
    % Read in all_motl file
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(fullfile(pwd(), all_motl_fn), 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'pca_parallel_xmatrix:File %s does not exist.', all_motl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl = getfield(tom_emread(all_motl_fn), 'Value');

    if size(all_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'pca_parallel_xmatrix:%s is not proper MOTL.', all_motl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Calculate the number and indices of particles to process
    num_ptcls = size(all_motl, 2);

    if num_xmatrix_batch > num_ptcls
        try
            error('subTOM:argumentError', ...
                'pca_parallel_xmatrix:num_xmatrix_batch is %s.', ...
                'greater than num_ptcls.');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    xmatrix_batch_size = floor(num_ptcls / num_xmatrix_batch);

    if process_idx > (num_ptcls - (xmatrix_batch_size * num_xmatrix_batch))
        ptcl_start_idx = (process_idx - 1) * xmatrix_batch_size + 1 + ...
            (num_ptcls - (xmatrix_batch_size * num_xmatrix_batch));

        ptcl_end_idx = ptcl_start_idx + xmatrix_batch_size - 1;
    else
        ptcl_start_idx = (process_idx - 1) * (xmatrix_batch_size + 1) + 1;
        ptcl_end_idx = ptcl_start_idx + xmatrix_batch_size;
    end
    
    batch_size = ptcl_end_idx - ptcl_start_idx + 1;

    % Get box size from first subtomogram
    if ~prealigned
        ptcl_fn = sprintf('%s_%d.em', ptcl_fn_prefix, ...
            all_motl(4, ptcl_start_idx));
    else
        ptcl_fn = sprintf('%s_%d_%d.em', ptcl_fn_prefix, iteration, ...
            all_motl(4, ptcl_start_idx));
    end

    if exist(fullfile(pwd(), ptcl_fn), 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'pca_parallel_xmatrix:File %s does not exist.', ptcl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    check_fn = ptcl_fn;

    % Note the transpose, tom_reademheader returns a column vector, but Matlab
    % size function returns a row vector, and ones and zeros need row vector
    box_size = getfield(tom_reademheader(ptcl_fn), 'Header', 'Size')';

    % Create a ones volume thats used a bit
    ones_vol = ones(box_size);

    % Read in classification mask
    if ~strcmpi(mask_fn, 'none')
        if exist(fullfile(pwd(), mask_fn), 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'pca_parallel_xmatrix:File %s does not exist.', mask_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        mask = getfield(tom_emread(mask_fn), 'Value');

        if ~all(size(mask) == box_size)
            try
                error('subTOM:volDimError', ...
                    'pca_parallel_xmatrix:%s and %s are not same size.', ...
                    mask_fn, check_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end
    else
        % If no mask specified use a hard-coded spherical mask
        mask = tom_spheremask(ones_vol, floor(box_size(1) * 0.4));
    end

    % Find the indices and  the number of voxels in the mask. The mask should be
    % all ones but in case it isn't we threshold it at 1e-6
    mask_idxs = mask > 1e-6;
    num_mask_vox = sum(mask_idxs(:));

    % Initialize the partial xmatrix and the partial xmatrix weight
    xmatrix = zeros(num_mask_vox, batch_size);
    xmatrix_weight = zeros(box_size);

    % Some variables for showing progress
    delprog = '';
    delprog_batch = max(floor(batch_size / 200), 1);
    timings = [];
    tic;

    % Loop over batch
    xmatrix_idx = 1;
    ptcl_weight_idx = 0;
    for ptcl_idx = ptcl_start_idx:ptcl_end_idx

        % Read in the particle
        if ~prealigned
            ptcl_fn = sprintf('%s_%d.em', ptcl_fn_prefix, ...
                all_motl(4, ptcl_idx));
        else
            ptcl_fn = sprintf('%s_%d_%d.em', ptcl_fn_prefix, iteration, ...
                all_motl(4, ptcl_idx));
        end

        if exist(fullfile(pwd(), ptcl_fn), 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'pca_parallel_xmatrix:File %s does not exist.', ptcl_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        ptcl = getfield(tom_emread(ptcl_fn), 'Value');

        if ~all(size(ptcl) == box_size)
            try
                error('subTOM:volDimError', ...
                    'pca_parallel_xmatrix:%s and %s are not same size.', ...
                    ptcl_fn, check_fn);
            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        % Read in particle weight
        if ptcl_weight_idx ~= all_motl(tomo_row, ptcl_idx)
            ptcl_weight_idx = all_motl(tomo_row, ptcl_idx);
            ptcl_weight_fn = sprintf('%s_%d.em', weight_fn_prefix, ...
                all_motl(tomo_row, ptcl_idx));

            if exist(fullfile(pwd(), ptcl_weight_fn), 'file') ~= 2
                try
                    error('subTOM:missingFileError', ...
                        'pca_parallel_xmatrix:File %s does not exist.', ...
                        ptcl_weight_fn);
                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            ptcl_weight = getfield(tom_emread(ptcl_weight_fn), 'Value');

            if ~all(size(ptcl_weight) == box_size)
                try
                    error('subTOM:volDimError', ...
                        'pca_parallel_xmatrix:%s and %s are not same size.', ...
                        ptcl_weight_fn, check_fn);
                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end
        end

        % Get the shifts and rotations to align the particle
        ptcl_shift = -all_motl(11:13, ptcl_idx);
        ptcl_rot = -all_motl([18, 17, 19], ptcl_idx);

        % Align the particle and its weight
        % I am applying the mask here in case someone gives a softmask, in
        % practice I should be able to skip that product since I only pass the
        % masked indices to the x-matrix, but I think that would confuse the
        % user if they saw that result after passing a soft mask.
        if ~prealigned
            ptcl = tom_rotate(tom_shift(ptcl, ptcl_shift), ptcl_rot) .* mask;
        else
            ptcl = ptcl .* mask;
        end

        % We need to normalize the particle under the mask to a mean of zero and
        % standard deviation of one.
        ptcl_mean = sum(ptcl(:)) / num_mask_vox;
        ptcl_stdv = sqrt((sum(sum(sum(ptcl .* ptcl))) / ...
            num_mask_vox) - (ptcl_mean ^ 2));

        ptcl = (ptcl - (mask .* ptcl_mean)) / ptcl_stdv;

        % Set values in xmatrix and xmatrix weight
        xmatrix(:, xmatrix_idx) = ptcl(mask_idxs);
        xmatrix_weight = xmatrix_weight + tom_rotate(ptcl_weight, ptcl_rot);

        % Display some output
        if mod(xmatrix_idx, delprog_batch) == 0
            elapsed_time = toc;
            timings = [timings elapsed_time];
            delprog = disp_progbar(process_idx, batch_size, xmatrix_idx, ...
                timings, delprog);
            tic;
        end

        % Increment the xmatrix index
        xmatrix_idx = xmatrix_idx + 1;
    end

    % Write out the partial xmatrix and the partial xmatrix weight
    tom_emwrite(xmatrix_fn, xmatrix);
    check_em_file(xmatrix_fn, xmatrix);

    xmatrix_weight_fn = sprintf('%s_%d_%d.em', xmatrix_weight_fn_prefix, ...
        iteration, process_idx);

    tom_emwrite(xmatrix_weight_fn, xmatrix_weight);
    check_em_file(xmatrix_weight_fn, xmatrix_weight);
end
