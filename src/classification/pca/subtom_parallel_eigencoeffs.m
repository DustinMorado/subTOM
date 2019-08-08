function subtom_parallel_eigencoeffs(varargin)
% SUBTOM_PARALLEL_EIGENCOEFFS computes particle Eigencoefficients.
%
%     SUBTOM_PARALLEL_EIGENCOEFFS(
%         'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX,
%         'xmatrix_fn_prefix', XMATRIX_FN_PREFIX,
%         'ptcl_fn_prefix', PTCL_FN_PREFIX,
%         'eig_coeff_fn_prefix', EIG_COEFF_FN_PREFIX,
%         'eig_vec_fn_prefix', EIG_VEC_FN_PREFIX,
%         'eig_val_fn_prefix', EIG_VAL_FN_PREFIX,
%         'eig_vol_fn_prefix', EIG_VOL_FN_PREFIX,
%         'weight_fn_prefix', WEIGHT_FN_PREFIX,
%         'mask_fn', MASK_FN,
%         'use_fast', USE_FAST,
%         'use_eig_vec', USE_EIG_VEC,
%         'apply_weight', APPLY_WEIGHT,
%         'prealigned', PREALIGNED,
%         'nfold', NFOLD,
%         'iteration', ITERATION,
%         'tomo_row', TOMO_ROW,
%         'num_xmatrix_batch', NUM_XMATRIX_BATCH,
%         'process_idx', PROCESS_IDX)
%
%     Takes a batch subset of particles described by ALL_MOTL_FN_PREFIX with
%     filenames given by PTCL_FN_PREFIX and projects them onto by default the
%     Eigenvolumes specified by EIG_VOL_FN_PREFIX. This determines a set of
%     coefficients describing a low-rank approximation of the data. A subset of
%     this coefficient matrix is written out based on EIG_COEFF_FN_PREFIX and
%     PROCESS_IDX, with there being NUM_XMATRIX_BATCH batches in total.
%
%     The calculation can be performed in a variety of ways with various speeds
%     of processing. If the subset of particles is the same size as the X-Matrix
%     batch used to determine the Eigenvolumes (or the conjugate space
%     Eigenvector volume as described below), then the user can set USE_FAST to
%     1 and a single-step calculation will be performed to determine an estimate
%     of the coefficients based on the transition formulas. Otherwise as long as
%     APPLY_WEIGHT is set to 0 and the particle amplitude spectrum weight (or
%     binary missing wedge) is not applied to the Eigenvolumes; the batch
%     coefficient matrix is just a simple matrix product of the X-Matrix chunk
%     with the matrix form of the Eigenvolumes.
%
%     If the number of particles in the motive list batch is bigger than the
%     size of the X-Matrix chunk or if APPLY_WEIGHT is set to 1 and the
%     Eigenvolumes will be reweighted using the correct weight of each particle
%     as described by WEIGHT_FN_PREFIX and TOMO_ROW, then each particle will be
%     read and projected in a loop. If PREALIGNED is set to 1, then it is
%     understood that the particles have been prealigned beforehand and the
%     alignment of the particles can be skipped to save time.  MASK_FN describes
%     the mask used throughout classification and 'NONE' describes a default
%     spherical mask. NFOLD describes a C-symmetry number to apply to the
%     Eigenvolume before projection
%
%     Also as a consequence of the transition formulas conjugate space
%     Eignvectors can be used in place of the Eigenvolumes if USE_EIG_VEC is set
%     to 1, as a means to calculate the Eigencoefficients, however this should
%     be identical in the final result and is just for clarity.

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'all_motl_fn_prefix', 'combinedmotl/allmotl');
    addParameter(fn_parser, 'xmatrix_fn_prefix', 'pca/xmatrix');
    addParameter(fn_parser, 'ptcl_fn_prefix', 'subtomograms/subtomo');
    addParameter(fn_parser, 'eig_coeff_fn_prefix', 'pca/eigcoeff');
    addParameter(fn_parser, 'eig_vec_fn_prefix', 'pca/eigvec');
    addParameter(fn_parser, 'eig_val_fn_prefix', 'pca/eigval');
    addParameter(fn_parser, 'eig_vol_fn_prefix', 'pca/eigvol');
    addParameter(fn_parser, 'weight_fn_prefix', 'otherinputs/ampspec');
    addParameter(fn_parser, 'mask_fn', 'none');
    addParameter(fn_parser, 'use_fast', 0);
    addParameter(fn_parser, 'use_eig_vec', 0);
    addParameter(fn_parser, 'apply_weight', 0);
    addParameter(fn_parser, 'prealigned', '0');
    addParameter(fn_parser, 'nfold', 1);
    addParameter(fn_parser, 'iteration', 1);
    addParameter(fn_parser, 'tomo_row', 7);
    addParameter(fn_parser, 'num_xmatrix_batch', 1);
    addParameter(fn_parser, 'process_idx', 1);
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    all_motl_fn_prefix = fn_parser.Results.all_motl_fn_prefix;
    [all_motl_dir, ~, ~] = fileparts(all_motl_fn_prefix);

    if ~isempty(all_motl_dir) && exist(all_motl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_eigencoeffs:all_motl_dir: Directory %s %s.', ...
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
                'parallel_eigencoeffs:xmatrix_dir: Directory %s %s.', ...
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
                'parallel_eigencoeffs:ptcl_dir: Directory %s %s.', ...
                ptcl_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    eig_coeff_fn_prefix = fn_parser.Results.eig_coeff_fn_prefix;
    [eig_coeff_dir, ~, ~] = fileparts(eig_coeff_fn_prefix);

    if ~isempty(eig_coeff_dir) && exist(eig_coeff_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_eigencoeffs:eig_coeff_dir: Directory %s %s.', ...
                eig_coeff_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    eig_vec_fn_prefix = fn_parser.Results.eig_vec_fn_prefix;
    [eig_vec_dir, ~, ~] = fileparts(eig_vec_fn_prefix);

    if ~isempty(eig_vec_dir) && exist(eig_vec_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_eigencoeffs:eig_vec_dir: Directory %s %s.', ...
                eig_vec_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    eig_val_fn_prefix = fn_parser.Results.eig_val_fn_prefix;
    [eig_val_dir, ~, ~] = fileparts(eig_val_fn_prefix);

    if ~isempty(eig_val_dir) && exist(eig_val_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_eigencoeffs:eig_val_dir: Directory %s %s.', ...
                eig_val_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    eig_vol_fn_prefix = fn_parser.Results.eig_vol_fn_prefix;
    [eig_vol_dir, ~, ~] = fileparts(eig_vol_fn_prefix);

    if ~isempty(eig_vol_dir) && exist(eig_vol_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_eigencoeffs:eig_vol_dir: Directory %s %s.', ...
                eig_vol_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    weight_fn_prefix = fn_parser.Results.weight_fn_prefix;
    [weight_dir, ~, ~] = fileparts(weight_fn_prefix);

    if ~isempty(weight_dir) && exist(weight_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'parallel_eigencoeffs:weight_dir: Directory %s %s.', ...
                weight_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    mask_fn = fn_parser.Results.mask_fn;

    if ~strcmp(mask_fn, 'none') && exist(mask_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_eigencoeffs:File %s does not exist.', mask_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    use_fast = fn_parser.Results.use_fast;

    if ischar(use_fast)
        use_fast = str2double(use_fast);
    end

    try
        validateattributes(use_fast, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_parallel_eigencoeffs', 'use_fast');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    use_eig_vec = fn_parser.Results.use_eig_vec;

    if ischar(use_eig_vec)
        use_eig_vec = str2double(use_eig_vec);
    end

    try
        validateattributes(use_eig_vec, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_parallel_eigencoeffs', 'use_eig_vec');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    if use_fast && use_eig_vec
        try
            error('subTOM:argumentError', ...
                'parallel_eigencoeffs: %s and %s specified', 'use_fast', ...
                'use_eig_vec');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    apply_weight = fn_parser.Results.apply_weight;

    if ischar(apply_weight)
        apply_weight = str2double(apply_weight);
    end

    try
        validateattributes(apply_weight, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_parallel_eigencoeffs', 'apply_weight');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    if use_fast && apply_weight
        try
            error('subTOM:argumentError', ...
                'parallel_eigencoeffs: %s and %s specified', 'use_fast', ...
                'apply_weight');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    prealigned = fn_parser.Results.prealigned;

    if ischar(prealigned)
        prealigned = str2double(prealigned);
    end

    try
        validateattributes(prealigned, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_parallel_eigencoeffs', 'prealigned');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    nfold = fn_parser.Results.nfold;

    if ischar(nfold)
        nfold = str2double(nfold);
    end

    try
        validateattributes(nfold, {'numeric'}, ...
            {'scalar', 'nonnan', 'positive', 'integer'}, ...
            'subtom_parallel_eigencoeffs', 'nfold');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    iteration = fn_parser.Results.iteration;

    if ischar(iteration)
        iteration = str2double(iteration);
    end

    try
        validateattributes(iteration, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer'}, ...
            'subtom_parallel_eigencoeffs', 'iteration');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    tomo_row = fn_parser.Results.tomo_row;

    if ischar(tomo_row)
        tomo_row = str2double(tomo_row);
    end

    try
        validateattributes(tomo_row, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0, '<', 21}, ...
            'subtom_parallel_eigencoeffs', 'tomo_row');

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
            'subtom_parallel_eigencoeffs', 'num_xmatrix_batch');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    process_idx = fn_parser.Results.process_idx;

    if ischar(process_idx)
        process_idx = str2double(process_idx);
    end

    try
        validateattributes(process_idx, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0, ...
            '<=', num_xmatrix_batch}, ...
            'subtom_parallel_eigencoeffs', 'process_idx');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Check if the calculation has already been done and skip if so.
    eig_coeff_fn = sprintf('%s_%d.em', eig_coeff_fn_prefix, iteration);

    if exist(eig_coeff_fn, 'file') == 2
        warning('subTOM:recoverOnFail', ...
            'subtom_parallel_eigencoeffs:File %s already exists. SKIPPING!', ...
            eig_coeff_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Check if the calculation has already been done and skip if so.
    eig_coeff_fn = sprintf('%s_%d_%d.em', eig_coeff_fn_prefix, iteration, ...
        process_idx);

    if exist(eig_coeff_fn, 'file') == 2
        warning('subTOM:recoverOnFail', ...
            'subtom_parallel_eigencoeffs:File %s already exists. SKIPPING!', ...
            eig_coeff_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Check if doing fast computation and if we actually need to do batches.
    if use_fast && process_idx > 1
        warning('subTOM:skipCalculationWarning', ...
            'parallel_eigencoeffs:%s %s. SKIPPING!', 'use_fast',  ...
            'only requires a single process');

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Read in all_motl file
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(all_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_eigencoeffs:File %s does not exist.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl = getfield(tom_emread(all_motl_fn), 'Value');

    if size(all_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'parallel_eigencoeffs:%s is not proper MOTL.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    num_ptcls = size(all_motl, 2);

    if use_fast
        eig_vec_fn = sprintf('%s_%d.em', eig_vec_fn_prefix, iteration);

        if exist(eig_vec_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'parallel_eigencoeffs:File %s does not exist.', eig_vec_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        eigen_vectors = getfield(tom_emread(eig_vec_fn), 'Value');
        num_ptcls_eig_vec = size(eigen_vectors, 1);

        if num_ptcls ~= num_ptcls_eig_vec
            try
                error('subTOM:argumentError', ...
                    'parallel_eigencoeffs:File %s %s %s.', all_motl_fn, ...
                    'has more particles than given Eigenvectors, ', ...
                    'cannot use_fast');

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        num_eigs = size(eigen_vectors, 2);
        eig_val_fn = sprintf('%s_%d.em', eig_val_fn_prefix, iteration);

        if exist(eig_val_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'parallel_eigencoeffs:File %s does not exist.', eig_val_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        eigen_values = getfield(tom_emread(eig_val_fn), 'Value');

        if min(eigen_values(:)) < 0
            warning('subTOM:EigenValueWarning', ...
                'parallel_eigencoeffs: %s %s.', ...
                'Negative Eigen values determined, ', ...
                'try do_algebraic or subtom_svds');

            [msg, msg_id] = lastwarn;
            fprintf(2, '%s - %s\n', msg_id, msg);
        end

        if length(eigen_values) ~= num_eigs
            try
                error('subTOM:volDimError', ...
                    'parallel_eigencoeffs:%s %s %s.', eig_val_fn, ...
                    'is not the correct size for ', eig_vec_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        eigen_coeffs = eigen_vectors * diag(sqrt(abs(eigen_values)));
        eig_coeff_fn = sprintf('%s_%d.em', eig_coeff_fn_prefix, iteration);
        tom_emwrite(eig_coeff_fn, eigen_coeffs);
        subtom_check_em_file(eig_coeff_fn, eigen_coeffs);
        return
    end

    num_ptcls_xmatrix = 0;

    for batch_idx = 1:num_xmatrix_batch
        xmatrix_fn = sprintf('%s_%d_%d.em', xmatrix_fn_prefix, ...
            iteration, batch_idx);

        if exist(xmatrix_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'parallel_eigencoeffs:File %s does not exist.', ...
                    xmatrix_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        xmatrix_size = getfield(tom_reademheader(xmatrix_fn), ...
            'Header', 'Size')';

        num_ptcls_xmatrix = num_ptcls_xmatrix + xmatrix_size(2);
    end

    if use_eig_vec && ~apply_weight && (num_ptcls_xmatrix == num_ptcls)
        xmatrix_fn = sprintf('%s_%d_%d.em', xmatrix_fn_prefix, ...
            iteration, process_idx);

        if exist(xmatrix_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'parallel_eigencoeffs:File %s does not exist.', ...
                    xmatrix_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        xmatrix = getfield(tom_emread(xmatrix_fn), 'Value');

        eig_vec_fn_ = sprintf('%s_conjugate_%d.em', eig_vec_fn_prefix, ...
            iteration);

        if exist(eig_vec_fn_, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'parallel_eigencoeffs:File %s does not exist.', ...
                    eig_vec_fn_);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        eigen_vectors_ = getfield(tom_emread(eig_vec_fn_), 'Value');
        eigen_coeffs = xmatrix' * eigen_vectors_;
        eig_coeff_fn = sprintf('%s_%d_%d.em', eig_coeff_fn_prefix, ...
            iteration, process_idx);

        tom_emwrite(eig_coeff_fn, eigen_coeffs);
        subtom_check_em_file(eig_coeff_fn, eigen_coeffs);
        return

    elseif ~apply_weight && (num_ptcls_xmatrix == num_ptcls)
        xmatrix_fn = sprintf('%s_%d_%d.em', xmatrix_fn_prefix, ...
            iteration, process_idx);

        if exist(xmatrix_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'parallel_eigencoeffs:File %s does not exist.', ...
                    xmatrix_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        xmatrix = getfield(tom_emread(xmatrix_fn), 'Value');

        eig_vol_fn = sprintf('%s_%d.em', eig_vol_fn_prefix, iteration);

        if exist(eig_vol_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'parallel_eigencoeffs:File %s does not exist.', ...
                    eig_vol_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        eigen_volumes = getfield(tom_emread(eig_vol_fn), 'Value');

        if size(eigen_volumes, 1) ~= size(xmatrix, 1)
            try
                error('subTOM:volDimError', ...
                    'parallel_eigencoeffs:%s %s %s.', eig_vol_fn, ...
                    'is not the correct size for ', xmatrix_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        eig_val_fn = sprintf('%s_%d.em', eig_val_fn_prefix, iteration);

        if exist(eig_val_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'parallel_eigencoeffs:File %s does not exist.', eig_val_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        eigen_values = getfield(tom_emread(eig_val_fn), 'Value');

        if min(eigen_values(:)) < 0
            warning('subTOM:EigenValueWarning', ...
                'parallel_eigencoeffs: %s %s.', ...
                'Negative Eigen values determined, ', ...
                'try do_algebraic or subtom_svds');

            [msg, msg_id] = lastwarn;
            fprintf(2, '%s - %s\n', msg_id, msg);
        end

        if length(eigen_values) ~= size(eigen_volumes, 2)
            try
                error('subTOM:volDimError', ...
                    'parallel_eigencoeffs:%s %s %s.', eig_val_fn, ...
                    'is not the correct size for ', eig_vol_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        eigen_coeffs = xmatrix' * eigen_volumes * ...
            diag(sqrt(1 ./ abs(eigen_values)));

        eig_coeff_fn = sprintf('%s_%d_%d.em', eig_coeff_fn_prefix, ...
            iteration, process_idx);

        tom_emwrite(eig_coeff_fn, eigen_coeffs);
        subtom_check_em_file(eig_coeff_fn, eigen_coeffs);
        return
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
        check_fn = sprintf('%s_%d.em', ptcl_fn_prefix, ...
            all_motl(4, ptcl_start_idx));
    else
        check_fn = sprintf('%s_%d_%d.em', ptcl_fn_prefix, iteration, ...
            all_motl(4, ptcl_start_idx));
    end

    if exist(check_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'parallel_eigencoeffs:File %s does not exist.', check_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % Note the transpose, tom_reademheader returns a column vector, but Matlab
    % size function returns a row vector, and ones and zeros need row vector
    box_size = getfield(tom_reademheader(check_fn), 'Header', 'Size')';

    % Read in classification mask
    if ~strcmpi(mask_fn, 'none')
        if exist(mask_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'parallel_eigencoeffs:File %s does not exist.', mask_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        mask = getfield(tom_emread(mask_fn), 'Value');

        if ~all(size(mask) == box_size)
            try
                error('subTOM:volDimError', ...
                    'parallel_eigencoeffs:%s and %s are not same size.', ...
                    mask_fn, check_fn);

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

    if use_eig_vec
        eig_vec_fn_ = sprintf('%s_conjugate_%d.em', eig_vec_fn_prefix, ...
            iteration);

        if exist(eig_vec_fn_, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'parallel_eigencoeffs:File %s does not exist.', ...
                    eig_vec_fn_);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        num_eigs = getfield(tom_reademheader(eig_vec_fn_), 'Header', 'Size', ...
            {2});

        proj_cell = cell(num_eigs, 1);
        proj_weights = ones(num_eigs, 1);

        for eig_idx = 1:num_eigs
            proj_vol_fn = sprintf('%s_conjugate_vol_%d_%d.em', ...
                eig_vec_fn_prefix, iteration, eig_idx);

            if exist(proj_vol_fn, 'file') ~= 2
                try
                    error('subTOM:missingFileError', ...
                        'parallel_eigencoeffs:File %s does not exist.', ...
                        proj_vol_fn);

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            proj_vol = getfield(tom_emread(proj_vol_fn), 'Value');

            if ~all(size(proj_vol) == box_size)
                try
                    error('subTOM:volDimError', ...
                        'parallel_eigencoeffs:%s and %s are not same size.', ...
                        proj_vol_fn, check_fn);

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            proj_cell{eig_idx} = proj_vol;
        end
    else
        eig_val_fn = sprintf('%s_%d.em', eig_val_fn_prefix, iteration);

        if exist(eig_val_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'parallel_eigencoeffs:File %s does not exist.', ...
                    eig_val_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        eigen_values = getfield(tom_emread(eig_val_fn), 'Value');

        if min(eigen_values(:)) < 0
            warning('subTOM:EigenValueWarning', ...
                'parallel_eigencoeffs: %s %s.', ...
                'Negative Eigen values determined, ', ...
                'try do_algebraic or subtom_svds');

            [msg, msg_id] = lastwarn;
            fprintf(2, '%s - %s\n', msg_id, msg);
        end

        num_eigs = length(eigen_values);
        proj_cell = cell(num_eigs, 1);
        proj_weights = sqrt(1 ./ abs(eigen_values));

        for eig_idx = 1:num_eigs
            proj_vol_fn = sprintf('%s_%d_%d.em', ...
                eig_vol_fn_prefix, iteration, eig_idx);

            if exist(proj_vol_fn, 'file') ~= 2
                try
                    error('subTOM:missingFileError', ...
                        'parallel_eigencoeffs:File %s does not exist.', ...
                        proj_vol_fn);

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            proj_vol = getfield(tom_emread(proj_vol_fn), 'Value');

            if ~all(size(proj_vol) == box_size)
                try
                    error('subTOM:volDimError', ...
                        'parallel_eigencoeffs:%s and %s are not same size.', ...
                        proj_vol_fn, check_fn);

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            proj_cell{eig_idx} = proj_vol;
        end
    end

    eigen_coeffs = zeros(batch_size, num_eigs);
    weight_idx = 0;
    batch_idx = 1;

    % Setup the progress bar
    delprog = '';
    timings = [];
    message = sprintf('Calculating Eigencoefficients %d', process_idx);
    op_type = 'particles';
    num_ops = batch_size * num_eigs;
    tic;

    for ptcl_idx = ptcl_start_idx:ptcl_end_idx

        % Read in the particle
        if ~prealigned
            ptcl_fn = sprintf('%s_%d.em', ptcl_fn_prefix, ...
                all_motl(4, ptcl_idx));
        else
            ptcl_fn = sprintf('%s_%d_%d.em', ptcl_fn_prefix, iteration, ...
                all_motl(4, ptcl_idx));
        end

        if exist(ptcl_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'parallel_eigencoeffs:File %s does not exist.', ptcl_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        ptcl = getfield(tom_emread(ptcl_fn), 'Value');

        if ~all(size(ptcl) == box_size)
            try
                error('subTOM:volDimError', ...
                    'parallel_eigencoeffs:%s and %s are not same size.', ...
                    ptcl_fn, check_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        % Get the shifts and rotations to align the particle
        ptcl_shift = -all_motl(11:13, ptcl_idx);
        ptcl_rot = -all_motl([18, 17, 19], ptcl_idx);

        % Align the particle
        if ~prealigned
            ptcl = tom_rotate(tom_shift(ptcl, ptcl_shift), ptcl_rot);
        end

        % Apply symmetry if specified.
        if nfold ~= 1
            ptcl = tom_symref(ptcl, nfold);
        end

        % I am applying the mask here in case someone gives a softmask, in
        % practice I should be able to skip that product since I only pass the
        % masked indices to the x-matrix, but I think that would confuse the
        % user if they saw that result after passing a soft mask.
        ptcl = ptcl .* mask;

        % We need to normalize the particle under the mask to a mean of zero and
        % standard deviation of one.
        ptcl_mean = sum(ptcl(:)) / num_mask_vox;
        ptcl_stdv = sqrt((sum(sum(sum(ptcl .* ptcl))) / ...
            num_mask_vox) - (ptcl_mean ^ 2));

        ptcl = (ptcl - (mask .* ptcl_mean)) / ptcl_stdv;

        % Read in weight if we need to
        if apply_weight && (weight_idx ~= all_motl(tomo_row, ptcl_idx))

            % Update weight index
            weight_idx = all_motl(tomo_row, ptcl_idx);

            % Read in the weight
            weight_fn = sprintf('%s_%d.em', weight_fn_prefix, ...
                all_motl(tomo_row, ptcl_idx));

            if exist(weight_fn, 'file') ~= 2
                try
                    error('subTOM:missingFileError', ...
                        'parallel_eigencoeffs:File %s does not exist.', ...
                        weight_fn);

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            weight = getfield(tom_emread(weight_fn), 'Value');

            if ~all(size(weight) == box_size)
                try
                    error('subTOM:volDimError', ...
                        'parallel_eigencoeffs:%s and %s %s.', ...
                        weight_fn, check_fn, 'are not same size');

                catch ME
                    fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                    rethrow(ME);
                end
            end

            % Perform n-fold symmetrization of reference weight.
            if nfold ~= 1
                weight = tom_symref(weight, nfold);
            end

            % Rotate weight for the particle
            rot_weight = tom_rotate(weight, ptcl_rot);
        elseif apply_weight

            % Rotate weight for the particle
            rot_weight = tom_rotate(weight, ptcl_rot);
        end

        for eigen_idx = 1:num_eigs
            if apply_weight
                proj_vol_fft = fftshift(fftn(proj_cell{eigen_idx}));
                proj_vol = ifftn(ifftshift(proj_vol_fft .* rot_weight), ...
                    'symmetric');

            else
                proj_vol = proj_cell{eigen_idx}
            end

            eigen_coeffs(batch_idx, eigen_idx) = sum(sum(sum(...
                proj_vol .* ptcl))) .* proj_weights(eigen_idx);

            % Display some output
            op_idx = (batch_idx - 1) * num_eigs + eigen_idx;
            [delprog, timings] = subtom_display_progress(delprog, timings, ...
                message, op_type, num_ops, op_idx);

        end

        batch_idx = batch_idx + 1;
    end

    eig_coeff_fn = sprintf('%s_%d_%d.em', eig_coeff_fn_prefix, iteration, ...
        process_idx);

    tom_emwrite(eig_coeff_fn, eigen_coeffs);
    subtom_check_em_file(eig_coeff_fn, eigen_coeffs);
end
