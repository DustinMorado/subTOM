function subtom_rotx_motl(varargin)
% SUBTOM_ROTX_MOTL transforms a MOTL to (un)apply a tomogram rotx operation.
%
%     SUBTOM_ROTX_MOTL(
%         'tomogram_dir', TOMOGRAM_DIR,
%         'tomo_row', TOMO_ROW,
%         'input_motl_fn', INPUT_MOTL_FN,
%         'output_motl_fn', OUTPUT_MOTL_FN,
%         'do_rotx', DO_ROTX)
%
%     Takes the motive list given by INPUT_MOTL_FN, and if DO_ROTX evaluates to
%     true as a boolean applies the same transformation as applied by 'clip
%     rotx' in the IMOD package, and else applies the inverse transformation.
%     The resulting motive list is then written out as OUTPUT_MOTL_FN. The
%     location of the tomograms needs to be given in TOMOGRAM_DIR, as well as
%     the field that specifies which tomogram to use for each particle in
%     TOMO_ROW. The size of the tomogram needs to be known to correctly
%     transform the particle center coordinates in fields 8-10 in the motive
%     list.

% DRM 09-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'tomogram_dir', '');
    addParameter(fn_parser, 'tomo_row', 7);
    addParameter(fn_parser, 'input_motl_fn', '');
    addParameter(fn_parser, 'output_motl_fn', '');
    addParameter(fn_parser, 'do_rotx', '0');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    tomogram_dir = fn_parser.Results.tomogram_dir;

    if exist(tomogram_dir, 'dir') ~= 7
        try
            error('subTOM:missingDirectoryError', ...
                'rotx_motl:tomogram_dir: Directory %s does not exist.', ...
                tomogram_dir);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    tomo_row = fn_parser.Results.tomo_row;

    if ischar(tomo_row)
        tomo_row = str2double(tomo_row);
    end

    try
        validateattributes(tomo_row, {'numeric'}, ...
            {'scalar', 'nonnan', 'integer', '>', 0, '<', 21}, ...
            'subtom_rotx_motl', 'tomo_row');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    input_motl_fn = fn_parser.Results.input_motl_fn;

    if isempty(input_motl_fn)
        try
            error('subTOM:missingRequired', ...
                'rotx_motl:Parameter %s is required.', ...
                'input_motl_fn');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if exist(input_motl_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'rotx_motl:File %s does not exist.', input_motl_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    input_motl = getfield(tom_emread(input_motl_fn), 'Value');

    if size(input_motl, 1) ~= 20
        try
            error('subTOM:MOTLError', ...
                'rotx_motl:%s is not proper MOTL.', input_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    output_motl_fn = fn_parser.Results.output_motl_fn;

    if isempty(output_motl_fn)
        try
            error('subTOM:missingRequired', ...
                'rotx_motl:Parameter %s is required.', ...
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
                'rotx_motl:File %s cannot be opened for writing', ...
                output_motl_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    fclose(fid);

    do_rotx = fn_parser.Results.do_rotx;

    if ischar(do_rotx)
        do_rotx = str2double(do_rotx);
    end

    try
        validateattributes(do_rotx, {'numeric'}, ...
            {'scalar', 'nonnan', 'binary'}, ...
            'subtom_rotx_motl', 'do_rotx');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%
    % Initially copy the output motive list as the input motive list.
    output_motl = input_motl;

    % First we have the Affine transformation of the rotx operation.
    rotx = [1,  0, 0, 0; ...
            0,  0, 1, 0; ...
            0, -1, 0, 0; ...
            0,  0, 0, 1];

    % If we are undoing the rotx operation, our Affine matrix is the transpose.
    if ~do_rotx
        rotx = rotx';
    end

    % Next we have to find the thickness of each tomogram in the MOTL.
    tomograms = unique(input_motl(tomo_row, :));
    thickness = zeros(1, length(tomograms));
    thickness_idx = 1;

    for tomogram = tomograms
        % We just try to open the tomogram with one, two, three, or four digits.
        for tomogram_digits = 1:4
            tomogram_fn = sprintf(sprintf('%%0%dd.rec', tomogram_digits), ...
                tomogram);

            tomogram_fn = fullfile(tomogram_dir, tomogram_fn);

            if exist(tomogram_fn, 'file') == 2
                break;
            end
        end

        if exist(tomogram_fn, 'file') ~= 2
            try
                error('subTOM:missingFileError', ...
                    'rotx_motl:File %s does not exist.', tomogram_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        % We find the tomogram size from the MRC header.
        tomo_size = getfield(subtom_readmrcheader(tomogram_fn), ...
            'Header', 'Size');

        % If we are applying the rotx operation the thickness is in the
        % Y-dimension, otherwise it is the Z-dimension.
        if do_rotx
            thickness(thickness_idx) = tomo_size(2);
        else
            thickness(thickness_idx) = tomo_size(3);
        end

        thickness_idx = thickness_idx + 1;
    end

    % Loop over all the particles
    for ptcl_idx = 1:size(output_motl, 2)
        tomo_thickness = thickness(...
            tomograms == output_motl(tomo_row, ptcl_idx));

        % Handle the particle center coordinates in the tomogram.
        if do_rotx
            output_motl(9, ptcl_idx) = input_motl(10, ptcl_idx);
            output_motl(10, ptcl_idx) = tomo_thickness - ...
                input_motl(9, ptcl_idx) + 1;

        else
            output_motl(9, ptcl_idx) = tomo_thickness - ...
                input_motl(10, ptcl_idx) + 1;

            output_motl(10, ptcl_idx) = input_motl(9, ptcl_idx);
        end

        % Create Affine of the transform from reference to particle.
        ptcl_affine = eye(4);
        ptcl_affine(1:3, 1:3) = subtom_zxz_to_matrix(...
            input_motl(17:19, ptcl_idx));

        ptcl_affine(1:3, 4) = input_motl(11:13, ptcl_idx);

        % The new Affine matrix
        rotx_affine = rotx * ptcl_affine;

        % Apply new transformation to the MOTL.
        output_motl(17:19, ptcl_idx) = subtom_matrix_to_zxz(...
            rotx_affine(1:3, 1:3));

        output_motl(11:13, ptcl_idx) = rotx_affine(1:3, 4);

        % Since the rotx operation should mean we are cutting out new particles
        % from the now rotated or non-rotated tomogram we reset the shifts.
        output_motl(11:13, ptcl_idx) = output_motl(8:10, ptcl_idx) + ...
            output_motl(11:13, ptcl_idx);

        output_motl(8:10, ptcl_idx) = floor(output_motl(11:13, ptcl_idx));
        output_motl(11:13, ptcl_idx) = output_motl(11:13, ptcl_idx) - ...
            output_motl(8:10, ptcl_idx);

    end

    % Write out the transformed motive list.
    tom_emwrite(output_motl_fn, output_motl);
    subtom_check_em_file(output_motl_fn, output_motl);
end
