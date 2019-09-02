function subtom_join_coeffs(varargin)
% SUBTOM_JOIN_COEFFS combines chunks of coefficients into the final matrix.
%
%     SUBTOM_JOIN_COEFFS(
%         'coeff_fn_prefix', COEFF_FN_PREFIX,
%         'iteration', ITERATION,
%         'num_coeff_batch', NUM_COEFF_BATCH)
%
%     Looks for partial chunks of the low-rank approximation coefficients of
%     projected wedge-masked differences with the file name
%     COEFF_FN_PREFIX_ITERATION_#.em where # is from 1 to NUM_XMATRIX_BATCH, and
%     combines them into a final matrix of coefficients written out as
%     COEFF_FN_PREFIX_ITERATION.em.

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'coeff_fn_prefix', 'class/coeff_wmd');
    addParameter(fn_parser, 'iteration', 1);
    addParameter(fn_parser, 'num_coeff_batch', 1);
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    coeff_fn_prefix = fn_parser.Results.coeff_fn_prefix;
    [coeff_dir, ~, ~] = fileparts(coeff_fn_prefix);

    if ~isempty(coeff_dir) && exist(coeff_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'join_coeffs:coeff_dir: Directory %s %s.', ...
                coeff_dir, 'does not exist');

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
            'subtom_join_coeffs', 'iteration');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    num_coeff_batch = fn_parser.Results.num_coeff_batch;

    if ischar(num_coeff_batch)
        num_coeff_batch = str2double(num_coeff_batch);
    end

    try
        validateattributes(num_coeff_batch, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0}, ...
            'subtom_join_coeffs', 'num_coeff_batch');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Check if the calculation has already been done and skip if so.
    coeff_fn = sprintf('%s_%d.em', coeff_fn_prefix, iteration);

    if exist(coeff_fn, 'file') == 2
        warning('subTOM:recoverOnFail', ...
            'join_coeffs:File %s already exists. SKIPPING!', ...
            coeff_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    check_fn = sprintf('%s_%d_1.em', coeff_fn_prefix, iteration);

    if exist(check_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'join_coeffs:File %s does not exist.', check_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    batch_size = getfield(tom_reademheader(check_fn), 'Header', 'Size');
    full_coeffs_size = batch_size(1);
    num_eigs = batch_size(2);

    for batch_idx = 2:num_coeff_batch
        coeff_fn = sprintf('%s_%d_%d.em', coeff_fn_prefix, ...
            iteration, batch_idx);

        if exist(coeff_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'join_coeffs:File %s does not exist.', ...
                    coeff_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        batch_size = getfield(tom_reademheader(coeff_fn), 'Header', 'Size');

        if batch_size(2) ~= num_eigs
            try
                error('subTOM:volDimError', ...
                    'join_coeffs:%s and %s are not same size.', ...
                    coeff_fn, check_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME)
            end
        end

        full_coeffs_size = full_coeffs_size + batch_size(1);
    end

    full_coeffs = zeros(full_coeffs_size, num_eigs);
    start_idx = 1;

    % Setup the progress bar
    delprog = '';
    timings = [];
    message = sprintf('Joining Coefficients');
    op_type = 'batches';
    tic;

    for batch_idx = 1:num_coeff_batch
        coeff_fn = sprintf('%s_%d_%d.em', coeff_fn_prefix, ...
            iteration, batch_idx);

        if exist(coeff_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'join_coeffs:File %s does not exist.', ...
                    coeff_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        coeffs = getfield(tom_emread(coeff_fn), 'Value');
        batch_size = size(coeffs, 1);
        end_idx = start_idx + batch_size - 1;
        full_coeffs(start_idx:end_idx, :) = coeffs;
        start_idx = start_idx + batch_size;

        % Display some output
        [delprog, timings] = subtom_display_progress(delprog, timings, ...
            message, op_type, num_coeff_batch, batch_idx);

    end

    coeff_fn = sprintf('%s_%d.em', coeff_fn_prefix, iteration);
    tom_emwrite(coeff_fn, full_coeffs);
    subtom_check_em_file(coeff_fn, full_coeffs);
end
