function subtom_join_xmatrix(varargin)
% SUBTOM_JOIN_XMATRIX combines chunks of X-matrix into the final matrix.
%
%     SUBTOM_JOIN_XMATRIX(
%         'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX,
%         'xmatrix_fn_prefix', XMATRIX_FN_PREFIX,
%         'ptcl_fn_prefix', PTCL_FN_PREFIX,
%         'mask_fn', MASK_FN,
%         'iteration', ITERATION,
%         'num_xmatrix_batch', NUM_XMATRIX_BATCH)
%
%     Looks for partial chunks of the X-matrix the file name
%     XMATRIX_FN_PREFIX_ITERATION_#.em where # is from 1 to NUM_XMATRIX_BATCH,
%     and combines them into a final matrix of coefficients written out as
%     XMATRIX_FN_PREFIX_ITERATION.em.

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'all_motl_fn_prefix', 'combinedmotl/allmotl');
    addParameter(fn_parser, 'xmatrix_fn_prefix', 'class/xmatrix_msa');
    addParameter(fn_parser, 'ptcl_fn_prefix', 'subtomograms/subtomo');
    addParameter(fn_parser, 'mask_fn', 'none');
    addParameter(fn_parser, 'iteration', 1);
    addParameter(fn_parser, 'num_xmatrix_batch', 1);
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    all_motl_fn_prefix = fn_parser.Results.all_motl_fn_prefix;
    [all_motl_dir, ~, ~] = fileparts(all_motl_fn_prefix);

    if ~isempty(all_motl_dir) && exist(all_motl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'join_xmatrix:all_motl_dir: Directory %s %s.', ...
                all_motl_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    xmatrix_fn_prefix = fn_parser.Results.xmatrix_fn_prefix;
    [xmatrix_dir, ~, ~] = fileparts(xmatrix_fn_prefix);

    if ~isempty(xmatrix_dir) && exist(xmatrix_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'join_xmatrix:xmatrix_dir: Directory %s %s.', ...
                xmatrix_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    ptcl_fn_prefix = fn_parser.Results.ptcl_fn_prefix;
    [ptcl_dir, ~, ~] = fileparts(ptcl_fn_prefix);

    if ~isempty(ptcl_dir) && exist(ptcl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'join_xmatrix:ptcl_dir: Directory %s %s.', ...
                ptcl_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    mask_fn = fn_parser.Results.mask_fn;

    if ~strcmp(mask_fn, 'none') && exist(mask_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_xmatrix:File %s does not exist.', mask_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    iteration = fn_parser.Results.iteration;

    if ischar(iteration)
        iteration = str2double(iteration);
    end

    try
        validateattributes(iteration, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer'}, ...
            'subtom_join_xmatrix', 'iteration');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    num_xmatrix_batch = fn_parser.Results.num_xmatrix_batch;

    if ischar(num_xmatrix_batch)
        num_xmatrix_batch = str2double(num_xmatrix_batch);
    end

    try
        validateattributes(num_xmatrix_batch, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0}, ...
            'subtom_join_xmatrix', 'num_xmatrix_batch');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Check if the calculation has already been done and skip if so.
    xmatrix_fn = sprintf('%s_%d.em', xmatrix_fn_prefix, iteration);

    if exist(xmatrix_fn, 'file') == 2
        warning('subTOM:recoverOnFail', ...
            'join_xmatrix:File %s already exists. SKIPPING!', xmatrix_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    check_fn = sprintf('%s_%d_1.em', xmatrix_fn_prefix, iteration);

    if exist(check_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'join_xmatrix:File %s does not exist.', check_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    batch_size = getfield(tom_reademheader(check_fn), 'Header', 'Size');
    num_voxels = batch_size(1);
    xmatrix_size = batch_size(2);

    for batch_idx = 2:num_xmatrix_batch
        xmatrix_batch_fn = sprintf('%s_%d_%d.em', xmatrix_fn_prefix, ...
            iteration, batch_idx);

        if exist(xmatrix_batch_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'join_xmatrix:File %s does not exist.', ...
                    xmatrix_batch_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        batch_size = getfield(tom_reademheader(xmatrix_batch_fn), ...
            'Header', 'Size');

        if batch_size(1) ~= num_voxels
            try
                error('subTOM:volDimError', ...
                    'join_xmatrix:%s and %s are not same size.', ...
                    xmatrix_batch_fn, check_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME)
            end
        end

        xmatrix_size = xmatrix_size + batch_size(2);
    end

    xmatrix = zeros(num_voxels, xmatrix_size);
    start_idx = 1;

    % Setup the progress bar
    delprog = '';
    timings = [];
    message = sprintf('Joining X-Matrix');
    op_type = 'batches';
    tic;

    for batch_idx = 1:num_xmatrix_batch
        xmatrix_batch_fn = sprintf('%s_%d_%d.em', xmatrix_fn_prefix, ...
            iteration, batch_idx);

        xmatrix_batch = getfield(tom_emread(xmatrix_batch_fn), 'Value');
        num_ptcls = size(xmatrix_batch, 2);
        end_idx = start_idx + num_ptcls - 1;
        xmatrix(:, start_idx:end_idx) = xmatrix_batch;
        start_idx = start_idx + num_ptcls;

        % Display some output
        [delprog, timings] = subtom_display_progress(delprog, timings, ...
            message, op_type, num_xmatrix_batch, batch_idx);

    end

    % Center the columns of the X-Matrix
    xmatrix_mean = mean(xmatrix, 2);
    xmatrix = xmatrix - xmatrix_mean;

    % Write out the X-Matrix
    tom_emwrite(xmatrix_fn, xmatrix);
    subtom_check_em_file(xmatrix_fn, xmatrix);

    % We need to write out the X-Matrix mean for when we are calculating the
    % Eigencoefficients. To write it out we need to find out the box size.

    % Read in all_motl file
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(all_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'join_xmatrix:File %s does not exist.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl = getfield(tom_emread(all_motl_fn), 'Value');

    if size(all_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'join_xmatrix:%s is not proper MOTL.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    ptcl_fn = sprintf('%s_%d.em', ptcl_fn_prefix, all_motl(4, 1));

    % Note the transpose, tom_reademheader returns a column vector, but Matlab
    % size function returns a row vector, and ones and zeros need row vector
    box_size = getfield(tom_reademheader(ptcl_fn), 'Header', 'Size')';

    % Read in classification mask
    if ~strcmpi(mask_fn, 'none')
        if exist(mask_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'join_xmatrix:File %s does not exist.', mask_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        mask = getfield(tom_emread(mask_fn), 'Value');

        if ~all(size(mask) == box_size)
            try
                error('subTOM:volDimError', ...
                    'join_xmatrix:%s and %s are not same size.', ...
                    mask_fn, ptcl_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end
    else

        % If no mask specified use a hard-coded spherical mask
        mask = tom_spheremask(ones(box_size), floor(box_size(1) * 0.4));
    end

    % Find the indices and  the number of voxels in the mask. The mask should be
    % all ones but in case it isn't we threshold it at 1e-6
    mask_idxs = mask > 1e-6;
    num_mask_vox = sum(mask_idxs(:));

    if num_mask_vox ~= length(xmatrix_mean)
        try
            error('subTOM:volDimError', ...
                'join_xmatrix: X-Matrix is not the correct size for mask.');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    xmatrix_mean_vol = zeros(box_size);
    xmatrix_mean_vol(mask_idxs) = xmatrix_mean;
    xmatrix_mean_vol_fn = sprintf('%s_mean_%d.em', xmatrix_fn_prefix, ...
        iteration);

    tom_emwrite(xmatrix_mean_vol_fn, xmatrix_mean_vol);
    subtom_check_em_file(xmatrix_mean_vol_fn, xmatrix_mean_vol);
end
