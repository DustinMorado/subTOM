function subtom_renumber_motl(varargin)
% SUBTOM_RENUMBER_MOTL renumbers particle indices in a motive list.
%
%     SUBTOM_RENUMBER_MOTL(
%         'input_motl_fn', INPUT_MOTL_FN,
%         'output_motl_fn', OUTPUT_MOTL_FN,
%         'sort_row', SORT_ROW,
%         'do_sequential', DO_SEQUENTIAL)
%
%     Takes the motive list given by INPUT_MOTL_FN, and renumbers the particles
%     in field 4 of the MOTL and writes out the renumbered list to
%     OUTPUT_MOTL_FN. If DO_SEQUENTIAL evaluates to true as a boolean then the
%     motive list will just be renumbered from 1 to the number of particles in
%     the MOTL, and the initial particle indices will be lost. If DO_SEQUENTIAL
%     evaluates to false as a boolean, then particle indices will be kept with
%     any duplicates of the particle index incremented by the largest particle
%     index found in the motive list. 
%
%     For example if DO_SEQUENTIAL is 0, and we have 100 particles where the
%     first particle index is 4, and the largest particle index in the motive
%     list is 325. If there are 3 copies of particle index 16 in the motive
%     list, then it will be renumbered so that these 3 copies correspond to
%     particle indices 16, 341, and 666. In this way as long as we keep the
%     original motive list we can trace back the origin of each particle.

% DRM 09-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'input_motl_fn', '');
    addParameter(fn_parser, 'output_motl_fn', '');
    addParameter(fn_parser, 'sort_row', '0');
    addParameter(fn_parser, 'do_sequential', '0');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    input_motl_fn = fn_parser.Results.input_motl_fn;

    if isempty(input_motl_fn)
        try
            error('subTOM:missingRequired', ...
                'renumber_motl:Parameter %s is required.', ...
                'input_motl_fn');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if exist(input_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'renumber_motl:File %s does not exist.', input_motl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    input_motl = getfield(tom_emread(input_motl_fn), 'Value');

    if size(input_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'renumber_motl:%s is not proper MOTL.', input_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    output_motl_fn = fn_parser.Results.output_motl_fn;

    if isempty(output_motl_fn)
        try
            error('subTOM:missingRequired', ...
                'renumber_motl:Parameter %s is required.', ...
                'output_motl_fn');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    fid = fopen(output_motl_fn, 'w');

    if fid == -1
        try
            error('subTOM:writeFileError', ...
                'renumber_motl:File %s cannot be opened for writing', ...
                output_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    fclose(fid);

    sort_row = fn_parser.Results.sort_row;

    if ischar(sort_row)
        sort_row = str2double(sort_row);
    end

    try
        validateattributes(sort_row, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>=', 0, '<', 21}, ...
            'subtom_renumber_motl', 'sort_row');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    do_sequential = fn_parser.Results.do_sequential;

    if ischar(do_sequential)
        do_sequential = str2double(do_sequential);
    end

    try
        validateattributes(do_sequential, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_renumber_motl', 'do_sequential');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%
    % Sort the motive list if it was requested.
    if logical(sort_row)
        input_motl_sorted = transpose(sortrows(input_motl', sort_row));
        input_motl = input_motl_sorted;
    end

    % Initially copy the output motive list as the input motive list.
    output_motl = input_motl;

    % If we are just simply renumbering, it is easy, the other case is more
    % complex.
    if do_sequential
        output_motl(4, :) = 1:size(output_motl, 2);
    else
        % Get the highest particle index in the motive list which is used a bit.
        ptcl_idx_max = max(output_motl(4, :));

        % We loop over particles in the input motive list removing the ones we
        % have processed so that we don't process duplicates twice.
        while size(input_motl, 2) > 0
            % Get the particle number
            ptcl_idx = input_motl(4, 1);

            % Determine if the particle number is unique
            num_idxs = sum(input_motl(4, :) == ptcl_idx);

            % If there are no duplicates it is easy we remove the particle from
            % the input motive list and move on.
            if num_idxs == 1
                input_motl = input_motl(:, 2:end);
            else
                % Find the indices of the output motive list that have duplicate
                % particle indices.
                motl_idxs = find(output_motl(4, :) == ptcl_idx);

                % Loop over the duplicates and renumber them.
                for dup_idx = 1:num_idxs
                    output_motl(4, motl_idxs(dup_idx)) = ptcl_idx + ...
                        (ptcl_idx_max * (dup_idx - 1));

                end

                % Remove the particles from the input motive list.
                input_motl(:, input_motl(4, :) == ptcl_idx) = [];
        end
    end

    % Write out the renumbered motive list.
    tom_emwrite(output_motl_fn, output_motl);
    subtom_check_em_file(output_motl_fn, output_motl);
end
