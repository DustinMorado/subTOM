function subtom_cluster(varargin)
% SUBTOM_CULSTER classifies particles based on given eigencoefficients
%
%     SUBTOM_CLUSTER(
%         'all_motl_fn_prefix', ALL_MOTL_FN_PREFIX,
%         'eig_coeff_fn_prefix', EIG_COEFF_FN_PREFIX,
%         'output_motl_fn_prefix', OUTPUT_MOTL_FN_PREFIX,
%         'iteration', ITERATION,
%         'cluster_type', CLUSTER_TYPE,
%         'eig_idxs', EIG_IDXS,
%         'num_classes', NUM_CLASSES)
%
%     TODO: Fill in info here

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'all_motl_fn_prefix', 'combinedmotl/allmotl');
    addParameter(fn_parser, 'eig_coeff_fn_prefix', 'pca/eigcoeff');
    addParameter(fn_parser, 'output_motl_fn_prefix', 'pca/allmotl');
    addParameter(fn_parser, 'iteration', 1);
    addParameter(fn_parser, 'cluster_type', 'kmeans');
    addParameter(fn_parser, 'eig_idxs', 'all');
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

    eig_coeff_fn_prefix = fn_parser.Results.eig_coeff_fn_prefix;
    [eig_coeff_dir, ~, ~] = fileparts(eig_coeff_fn_prefix);

    if ~isempty(eig_coeff_dir) && exist(eig_coeff_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'cluster:eig_coeff_dir: Directory %s %s.', ...
                eig_coeff_dir, 'does not exist');

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
    % style for ranges i.e. '1-3,5,7-10' and convert this into the numerical
    % array [1 2 3 5 7 8 9 10]. Any errors in this string ideally will lead to
    % the array having NaNs, which then triggers an error below.
    eig_idxs = fn_parser.Results.eig_idxs;
    
    if ischar(eig_idxs)
        if strcmpi(eig_idxs, 'all')
            eig_idxs = [0];
        elseif ~isnan(str2double(eig_idxs))
            eig_idxs = [str2double(eig_idxs)];
        else
            eig_idxs_strs = split(eig_idxs, ',', 2);
            eig_idxs = [];

            for eig_idxs_str = eig_idxs_strs
                eig_range_str = split(eig_idxs_str, '-', 2);

                if length(eig_range_str) == 1
                    eig_idxs = horzcat(eig_idxs, str2double(eig_range_str));
                else
                    eig_range_start = str2double(eig_range_str(1));
                    eig_range_end = str2double(eig_range_str(2));
                    eig_idxs = horzcat(eig_idxs, eig_range_start:eig_range_end);
                end
            end
        end
    end

    try
        validateattributes(eig_idxs, {'numeric'}, ...
            {'nonnan', 'integer', 'nonnegative', 'vector'}, ...
            'subtom_cluster', 'eig_idxs');

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
    output_motl_fn = sprintf('%s_pca_%d.em', output_motl_fn_prefix, iteration);

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
    eig_coeff_fn = sprintf('%s_%d.em', eig_coeff_fn_prefix, iteration);

    if exist(eig_coeff_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'cluster:File %s does not exist.', eig_coeff_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    eigen_coeffs = getfield(tom_emread(eig_coeff_fn), 'Value');

    if size(eigen_coeffs, 1) ~= num_ptcls
        try
            error('subTOM:volDimError', ...
                'cluster:%s and %s do not have same number of particles.', ...
                all_motl_fn, eig_coeff_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    num_eigs = size(eigen_coeffs, 2);
    
    if eig_idxs == 0
        eig_idxs = [1:num_eigs];
    end

    if max(eig_idxs) > num_eigs
        try
            error('subTOM:argumentError', ...
                'cluster:Invalid Eigencoefficients requested.')

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    cluster_coeffs = eigen_coeffs(:, eig_idxs);

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
