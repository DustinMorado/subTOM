function subtom_cluster(varargin)
% SUBTOM_CULSTER classifies particles based on given coefficients
%
%     SUBTOM_CLUSTER(
%         'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX,
%         'coeff_fn_prefix', COEFF_FN_PREFIX,
%         'output_motl_fn_prefix', OUTPUT_MOTL_FN_PREFIX,
%         'iteration', ITERATION,
%         'cluster_type', CLUSTER_TYPE,
%         'coeff_idxs', COEFF_IDXS,
%         'num_classes', NUM_CLASSES)
%
%     Takes the motive list given by ALL_MOTL_FN_PREFIX and the coefficients
%     specified by COEFF_FN_PREFIX for the iteration ITERATION and clusters the
%     data based on the coefficients. Clustering can be done using one of three
%     methods, which are specfied by CLUSTER_TYPE. The options are K-Means
%     clustering with 'kmeans', Hierarchical Ascendant Clustering with 'hac' and
%     a Gaussian Mixture Model with 'gaussmix'. A subset of coefficients can be
%     selected and are given as a semicolon-separated string of indices as
%     COEFF_IDXS. The string can also contain ranges delimited by a dash, for
%     example '1;3;5-10'. The data will be clustered into NUM_CLASSES number of
%     clusters and the clustered motive list will be written out to a file given
%     by OUTPUT_MOTL_FN_PREFIX.

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'all_motl_fn_prefix', 'combinedmotl/allmotl');
    addParameter(fn_parser, 'coeff_fn_prefix', 'class/coeff');
    addParameter(fn_parser, 'output_motl_fn_prefix', 'class/allmotl');
    addParameter(fn_parser, 'iteration', 1);
    addParameter(fn_parser, 'cluster_type', 'kmeans');
    addParameter(fn_parser, 'coeff_idxs', 'all');
    addParameter(fn_parser, 'num_classes', '2');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    all_motl_fn_prefix = fn_parser.Results.all_motl_fn_prefix;
    [all_motl_dir, ~, ~] = fileparts(all_motl_fn_prefix);

    if ~isempty(all_motl_dir) && exist(all_motl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'cluster:all_motl_dir: Directory %s %s.', ...
                all_motl_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    coeff_fn_prefix = fn_parser.Results.coeff_fn_prefix;
    [coeff_dir, ~, ~] = fileparts(coeff_fn_prefix);

    if ~isempty(coeff_dir) && exist(coeff_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'cluster:coeff_dir: Directory %s %s.', ...
                coeff_dir, 'does not exist');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    output_motl_fn_prefix = fn_parser.Results.output_motl_fn_prefix;
    [output_motl_dir, ~, ~] = fileparts(output_motl_fn_prefix);

    if ~isempty(output_motl_dir) && exist(output_motl_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'cluster:output_motl_dir: Directory %s %s.', ...
                output_motl_dir, 'does not exist');

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
            'subtom_cluster', 'iteration');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    cluster_type = fn_parser.Results.cluster_type;

    try
        cluster_type = validatestring(cluster_type, ...
            {'kmeans', 'hac', 'gaussmix'}, ...
            'subtom_cluster', 'cluster_type');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    % This is a bit tricky to parse unfortunately. We take in a string in IMOD
    % style for ranges i.e. '1-3;5;7-10' and convert this into the numerical
    % array [1 2 3 5 7 8 9 10]. Any errors in this string ideally will lead to
    % the array having NaNs, which then triggers an error below.
    coeff_idxs = fn_parser.Results.coeff_idxs;
    
    if ischar(coeff_idxs)
        if strcmpi(coeff_idxs, 'all')
            coeff_idxs = [0];
        elseif ~isnan(str2double(coeff_idxs))
            coeff_idxs = [str2double(coeff_idxs)];
        else
            idxs_strs = split(coeff_idxs, ';', 2);
            coeff_idxs = [];

            for idxs_str = idxs_strs
                range_str = split(idxs_str, '-', 2);

                if length(range_str) == 1
                    coeff_idxs = horzcat(coeff_idxs, str2double(range_str));
                else
                    range_start = str2double(range_str(1));
                    range_end = str2double(range_str(2));
                    coeff_idxs = horzcat(coeff_idxs, range_start:range_end);
                end
            end
        end
    end

    try
        validateattributes(coeff_idxs, {'numeric'}, ...
            {'nonnan', 'integer', 'nonnegative', 'vector'}, ...
            'subtom_cluster', 'coeff_idxs');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    num_classes = fn_parser.Results.num_classes;

    if ischar(num_classes)
        num_classes = str2double(num_classes);
    end

    try
        validateattributes(num_classes, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', 'positive'}, ...
            'subtom_cluster', 'num_classes');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Check if the calculation has already been done and skip if so.
    output_motl_fn = sprintf('%s_%d.em', output_motl_fn_prefix, iteration);

    if exist(output_motl_fn, 'file') == 2
        warning('subTOM:recoverOnFail', ...
            'cluster:File %s already exists. SKIPPING!', output_motl_fn);

        [msg, msg_id] = lastwarn;
        fprintf(2, '%s - %s\n', msg_id, msg);
        return
    end

    % Read in all_motl file
    all_motl_fn = sprintf('%s_%d.em', all_motl_fn_prefix, iteration);

    if exist(all_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'cluster:File %s does not exist.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    all_motl = getfield(tom_emread(all_motl_fn), 'Value');

    if size(all_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'cluster:%s is not proper MOTL.', all_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    num_ptcls = size(all_motl, 2);
    output_motl = all_motl;

    % Read in the Eigencoefficients
    coeff_fn = sprintf('%s_%d.em', coeff_fn_prefix, iteration);

    if exist(coeff_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'cluster:File %s does not exist.', coeff_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    coeffs = getfield(tom_emread(coeff_fn), 'Value');

    if size(coeffs, 1) ~= num_ptcls
        try
            error('subTOM:volDimError', ...
                'cluster:%s and %s do not have same number of particles.', ...
                all_motl_fn, coeff_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    num_coeffs = size(coeffs, 2);
    
    if coeff_idxs == 0
        coeff_idxs = [1:num_coeffs];
    end

    if max(coeff_idxs) > num_coeffs
        try
            error('subTOM:argumentError', ...
                'cluster:Invalid Eigencoefficients requested.')

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    cluster_coeffs = coeffs(:, coeff_idxs);

    if strcmpi(cluster_type, 'kmeans')
        output_motl(20, :) = kmeans(cluster_coeffs, num_classes, ...
            'Replicates', 10) + 2;

    elseif strcmpi(cluster_type, 'hac')
        output_motl(20, :) = clusterdata(cluster_coeffs, 'linkage', 'ward', ...
            'maxclust', num_classes) + 2;

    else
        gmfit = fitgmdist(cluster_coeffs, num_classes, ...
            'CovarianceType', 'full', 'SharedCovariance', false, ...
            'Options', statset('MaxIter', 1000));

        output_motl(20, :) = cluster(gmfit, cluster_coeffs) + 2;
    end

    % Write out the classified motive list.
    tom_emwrite(output_motl_fn, output_motl);
    subtom_check_em_file(output_motl_fn, output_motl);
end
