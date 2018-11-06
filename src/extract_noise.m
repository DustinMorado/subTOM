function extract_noise(tomogram_dir, scratch_dir, tomo_row, ...
    ampspec_fn_prefix, binary_fn_prefix, all_motl_fn, noise_motl_fn_prefix, ...
    boxsize, just_extract, ptcl_overlap_factor, noise_overlap_factor, ...
    num_noise, process_idx, reextract)
% EXTRACT_NOISE extract noise amplitude spectra on the cluster.
%     EXTRACT_NOISE(
%         TOMOGRAM_DIR,
%         SCRATCH_DIR,
%         TOMO_ROW,
%         AMPSPEC_FN_PREFIX,
%         BINARY_FN_PREFIX,
%         ALL_MOTL_FN,
%         NOISE_MOTL_FN_PREFIX,
%         BOXSIZE,
%         JUST_EXTRACT,
%         PTCL_OVERLAP_FACTOR,
%         NOISE_OVERLAP_FACTOR,
%         NUM_NOISE,
%         PROCESS_IDX,
%         REEXTRACT)
%
%     Takes the tomograms given in TOMOGRAM_DIR and extracts average amplitude
%     spectra and binary wedges into SCRATCH_DIR with the name formats
%     AMPSPEC_FN_PREFIX_#.em and BINARY_FN_PREFIX_#.em, respectively where #
%     corresponds to the tomogram from which it was created.
%
%     Tomograms are specified by the field TOMO_ROW in motive list ALL_MOTL_FN,
%     and the tomogram that will be processed is selected by PROCESS_IDX. Motive
%     lists with the positions used to generate the amplitude spectrum are
%     written with the name format NOISE_MOTL_FN_PREFIX_#.em.
%
%     NUM_NOISE Noise volumes of size BOXSIZE are first identified that do not
%     clash with the subtomogram positions in ALL_MOTL_FN or other already
%     selected noise volumes. PTCL_OVERLAP_FACTOR and NOISE_OVERLAP_FACTOR
%     define how much overlap selected noise volumes can have with subtomograms
%     and other noise volumes respectively with 0 being complete overlap and 1
%     being complete separation.
%
%     If NOISE_MOTL_FN_PREFIX_#.em already exists then if JUST_EXTRACT evaluates
%     to true as a boolean, then noise volume selection is skipped and the
%     positions in the motive list are extracted and the amplitude spectrum is
%     generated, whether or not the length of the motive list is less than
%     NUM_NOISE. Otherwise positions will be added to the motive list up to
%     NUM_NOISE.
%
%     If REEXTRACT evaluates to true as a boolean, than existing amplitude
%     spectra will be overwritten. Otherwise the program will do nothing and
%     exit if the volume already exists. This is for in the case that the
%     processing crashed at some point in execution and then can just be re-run
%     without any alterations.
%
% Example:
%     EXTRACT_NOISE(...
%         '/net/bstore1/bstore1/user/dataset/date/data/tomos/bin1', ...
%         '/net/bstore1/bstore1/user/dataset/date/subtomo/bin1/even', ...
%         7, 'otherinputs/ampspec', 'otherinputs/binary', ...
%         'combinedmotl/allmotl_1.em', 'combinedmotl/noisemotl', 192, 0, 1, ...
%         1, 100, 1, 0)
%
% See also EXTRACT_SUBTOMOGRAMS

% DRM 11-2017
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% tomogram_dir = 'tomogram_dir';
% scratch_dir = 'scratch_dir';
% tomo_row = 7;
% ampspec_fn_prefix = 'otherinputs/ampspec';
% binary_fn_prefix = 'otherinputs/binary';
% all_motl_fn = 'combinedmotl/allmotl_1.em';
% noise_motl_fn_prefix = 'combinedmotl/noisemotl';
% boxsize = 128;
% just_extract = 0;
% ptcl_overlap_factor = 1;
% noise_overlap_factor = 1;
% num_noise = 100;
% process_idx = 1;
% reextract = 0
%##############################################################################%
    % Evaluate numeric inputs
    if ischar(tomo_row)
        tomo_row = str2double(tomo_row);
    end

    if ischar(boxsize)
        boxsize = str2double(boxsize);
    end

    if ischar(just_extract)
        just_extract = str2double(just_extract);
    end

    just_extract = logical(just_extract);

    if ischar(num_noise)
        num_noise = str2double(num_noise);
    end

    if ischar(ptcl_overlap_factor)
        ptcl_overlap_factor = str2double(ptcl_overlap_factor);
    end

    if ischar(noise_overlap_factor)
        noise_overlap_factor = str2double(noise_overlap_factor);
    end

    if ischar(process_idx)
        process_idx = str2double(process_idx);
    end

    if ischar(reextract)
        reextract = str2double(reextract);
    end

    reextract = logical(reextract);

    % Read in allmotl
    allmotl = getfield(tom_emread(all_motl_fn), 'Value');

    % Get a list of all tomograms in the allmotl
    tomograms = unique(allmotl(tomo_row, :));

    % Identify our tomogram number for processing
    tomogram_number = tomograms(process_idx);

    % We just try to open the tomogram with one, two, three, or four digits.
    for tomogram_digits = 1:4
        tomogram_fn = sprintf(sprintf('%%0%dd.rec', tomogram_digits), ...
            tomogram_number);
        tomogram_fn = fullfile(tomogram_dir, tomogram_fn);
        if isfile(tomogram_fn)
            break;
        end
    end

    % Get tomogram motl
    motl = allmotl(:, allmotl(tomo_row, :) == tomogram_number);

    % Go to root folder
    cd(scratch_dir);

    % Check if we have already finished the processing for this tomogram
    noise_ampspec_fn = sprintf('%s_%d.em', ampspec_fn_prefix, tomogram_number);
    binary_wedge_fn = sprintf('%s_%d.em', binary_fn_prefix, tomogram_number);
    ampspec_exist = exist(fullfile(pwd(), noise_ampspec_fn), 'file') == 2;
    if ampspec_exist && ~reextract
        fprintf('Found noise amplitude spectrum: %s. SKIPPING.\n', ...
            noise_ampspec_fn);

        fprintf('Turn on reextract if you want to re-extract noise.\n');
        return
    end

    % check if noisemotl has already been calculated and if so read it in or
    % otherwise initialize a new empty one
    noise_motl_fn = sprintf('%s_%d.em', noise_motl_fn_prefix, tomogram_number);
    if exist(fullfile(pwd(), noise_motl_fn), 'file') == 2
        noise_motl = getfield(tom_emread(noise_motl_fn), 'Value');
        noise_count = size(noise_motl, 2);
        if just_extract
            num_noise = noise_count;
        end
    else
        noise_motl = zeros(20, num_noise);
        noise_count = 0;
    end

    % If we already have enough noise positions or selected just extract
    if noise_count >= num_noise
        % Extract the subtomograms for each tomogram
        tomogram = getfield(tom_mrcread(tomogram_fn), 'Value');
        noise_ampspec = extract_noise_ampspec(boxsize, tomogram, noise_motl);
        tom_emwrite(noise_ampspec_fn, noise_ampspec);
        check_em_file(noise_ampspec_fn, noise_ampspec);
        binary_wedge = binary_from_ampspec(noise_ampspec);
        tom_emwrite(binary_wedge_fn, binary_wedge);
        check_em_file(binary_wedge_fn, binary_wedge);
        return
    end

    % Read in the tomogram to get its dimension
    tomogram_size = getfield(getfield(tom_readmrcheader(tomogram_fn), ...
        'Header'), 'Size');
    if max(tomogram_size) <= 500
        bin_factor = 1;
    elseif max(tomogram_size ./ 2) <= 500
        bin_factor = 2;
    elseif max(tomogram_size ./ 4) <= 500
        bin_factor = 4;
    else
        bin_factor = 8;
    end

    % Create a mask volume that will hold possible positions for noise
    noise_mask = ones(round(tomogram_size ./ bin_factor));

    % Noise absolute minimum tomogram limits
    extract_boxsize = boxsize;
    boxsize = max(round(boxsize / bin_factor), 1);
    noise_mask(1:boxsize, :, :) = 0;
    noise_mask(:, 1:boxsize, :) = 0;
    noise_mask(:, :, 1:boxsize) = 0;

    % Noise absolute maximum tomogram limits
    noise_mask(size(noise_mask, 1) - (boxsize - 1):end, :, :) = 0;
    noise_mask(:, size(noise_mask, 2) - (boxsize - 1):end, :) = 0;
    noise_mask(:, :, size(noise_mask, 3) - (boxsize - 1):end) = 0;

    % We define mask size as a factor of the boxsize which defines the amount of
    % overlap we allow between particles and noise particles. Values less than
    % zero will create extra padding between particles, while values greater
    % than zero will allow some overlap
    ptcl_masksize = max(round(boxsize * (1 - ptcl_overlap_factor)), 1);
    noise_masksize = max(round(boxsize * (1 - noise_overlap_factor)), 1);

    % For each particle we clear out the mask around the particle
    for ptcl_idx = 1:size(motl, 2)
        % Get the particles position in the tomogram
        ptcl_pos = round((motl(8:10, ptcl_idx) + motl(11:13, ptcl_idx)) ./ ...
            bin_factor);

        % Particles can exist at the boundaries of the tomogram so we need to
        % set their boundaries manually to avoid improper indexing
        ptcl_min = max(round(ptcl_pos - (ptcl_masksize / 2)), 1);
        ptcl_max = min(round(ptcl_pos + (ptcl_masksize / 2 - 1)), ...
            size(noise_mask));

        % Zero out the mask around the particle
        noise_mask(ptcl_min(1):ptcl_max(1), ptcl_min(2):ptcl_max(2), ...
            ptcl_min(3):ptcl_max(3)) = 0;
    end

    % For each existing noise position we clear out the mask around the particle
    if noise_count > 0
        for noise_idx = 1:noise_count
            % Get the noise position in the tomogram
            noise_pos = round(noise_motl(8:10, noise_idx) ./ bin_factor);
            % Noise shouldn't exist at the boundaries of the tomogram, but just
            % in case the user has given some very large overlap factor value.
            noise_min = max(round(noise_pos - (noise_masksize / 2)), 1);
            noise_max = min(round(noise_pos + (noise_masksize / 2 - 1)), ...
                size(noise_mask));

            % Zero out the mask around the particle
            noise_mask(noise_min(1):noise_max(1), noise_min(2):noise_max(2), ...
                noise_min(3):noise_max(3)) = 0;
        end
    end

    delprog = '';
    rng('shuffle');
    while noise_count < num_noise
        % First we find non-zero indices in our noise_mask volume
        noise_pos_array = find(noise_mask == 1);

        % If we cannot find any suitable noise positions we break
        if isempty(noise_pos_array)
            fprintf('ERROR: No more available positions for noise.\n');
            fprintf('    %d noise found\n', noise_count);
            fprintf('    Consider using smaller overlap factor or less ');
            fprintf(' number of noise particles wanted.\n');
            break
        end

        % Pick a random position from this list
        noise_pos_idx = noise_pos_array(randi(length(noise_pos_array)));

        [noise_pos_x, noise_pos_y, noise_pos_z] = ind2sub(size(noise_mask), ...
            noise_pos_idx);
        noise_pos = [noise_pos_x, noise_pos_y, noise_pos_z];

        % Add this position to the noise MOTL
        noise_count = noise_count + 1;
        noise_motl(tomo_row, noise_count) = tomogram_number;
        noise_motl(8:10, noise_count) = noise_pos .* bin_factor;
        noise_motl(20, noise_count) = 1;

        % Noise shouldn't exist at the boundaries of the tomogram, but just in
        % case the user has given some very large overlap factor value.
        noise_min = max(round(noise_pos - (noise_masksize / 2)), 1);
        noise_max = min(round(noise_pos + (noise_masksize / 2 - 1)), ...
            size(noise_mask));

        % Zero out the mask around the particle
        noise_mask(noise_min(1):noise_max(1), noise_min(2):noise_max(2), ...
            noise_min(3):noise_max(3)) = 0;

        % Display some output
        delprog = disp_progbar(tomogram_number, noise_count, num_noise, ...
            delprog);
    end

    % Extract the subtomograms for each tomogram
    fprintf('Starting Noise Extraction and Amp. Spec. Calculation\n');
    tomogram = getfield(tom_mrcread(tomogram_fn), 'Value');
    noise_motl = noise_motl(:, noise_motl(20, :) == 1);
    noise_ampspec = extract_noise_ampspec(extract_boxsize, tomogram, ...
        noise_motl);

    tom_emwrite(noise_ampspec_fn, noise_ampspec);
    check_em_file(noise_ampspec_fn, noise_ampspec);

    binary_wedge = binary_from_ampspec(noise_ampspec);
    tom_emwrite(binary_wedge_fn, binary_wedge);
    check_em_file(binary_wedge_fn, binary_wedge);

    tom_emwrite(noise_motl_fn, noise_motl);
    check_em_file(noise_motl_fn, noise_motl);
end

%% disp_progbar
% Display a progress bar
function new_delprog = disp_progbar(tomogram_number, noise_count, num_noise, ...
        delprog)

    fmtstr = 'Tomogram %d: [%s%s] - %d%% - %d noise\n';
    count = round(noise_count / num_noise * 40);
    percent = round(noise_count / num_noise * 100);
    left = repmat('#', 1, count);
    right = repmat(' ', 1, 40 - count);
    fprintf(delprog);
    fprintf(fmtstr, tomogram_number, left, right, percent, noise_count);
    new_delprog = repmat('\b', 1, ...
        length(sprintf(fmtstr, tomogram_number, left, right, percent, ...
        noise_count)));
end

%% extract_noise_ampspec
% Calculate average noise amplitude spectrum
function noise_ampspec_avg = extract_noise_ampspec(boxsize, vol, motl_vec)
    % Initialize amplitude spectrum volume
    noise_ampspec_sum = zeros(boxsize, boxsize, boxsize);
    num_noise = size(motl_vec, 2);
    tomogram_number = max(motl_vec(5, 1), motl_vec(7, 1));

    delprog = '';
    for idx = 1:num_noise
        noise_pos = transpose(motl_vec(8:10, idx));
        noise_start = round(noise_pos - (boxsize / 2));
        noise_size = repmat(boxsize, 1, 3);

        % Input the bottom,left,rear corner of the box and the box edge
        % dimensions. The extact the volume and convert to double.
        noise_vol = tom_red(vol, noise_start, noise_size);
        noise_vol = double(noise_vol);

        % Normalize the volume by mean subtraction and division by SD
        noise_mean = mean(noise_vol(:));
        noise_stddev = std(noise_vol(:));
        noise_vol = (noise_vol - noise_mean) / noise_stddev;

        noise_ampspec = fftn(noise_vol);
        noise_ampspec = sqrt(noise_ampspec .* conj(noise_ampspec));
        noise_ampspec_sum = noise_ampspec_sum + noise_ampspec;
        delprog = disp_progbar(tomogram_number, idx, num_noise, delprog);
    end

    noise_ampspec_avg = fftshift(noise_ampspec_sum ./ num_noise);
    noise_ampspec_avg = noise_ampspec_avg ./ max(noise_ampspec_avg(:));

    % Relion gets unhappy with the origin of the FFT having a zero value so we
    % apply a 3x3 median filter in the origin plane to the origin
    center = boxsize / 2 + 1;
    noise_ampspec_avg(center, center, center) = (...
          noise_ampspec_avg(center, center, center) ...
        + noise_ampspec_avg(center, center + 1, center) ...
        + noise_ampspec_avg(center + 1, center + 1, center) ...
        + noise_ampspec_avg(center + 1, center, center) ...
        + noise_ampspec_avg(center + 1, center - 1, center) ...
        + noise_ampspec_avg(center, center - 1, center) ...
        + noise_ampspec_avg(center - 1, center - 1, center) ...
        + noise_ampspec_avg(center - 1, center, center) ...
        + noise_ampspec_avg(center - 1, center + 1, center)) ./ 9;
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
    size_check = numel(em_data) * 4 + 512;
    while true
        listing = dir(em_fn);
        if isempty(listing)
            fprintf('******\nWARNING:\n\tFile %s does not exist!', em_fn);
            tom_emwrite(em_fn, em_data);
        else
            if listing.bytes ~= size_check
                fprintf('******\nWARNING:\n');
                fprintf('\tFile %s is not the correct size!', em_fn);
                tom_emwrite(em_fn, em_data);
            else
                break;
            end
        end
    end
end

%% Create binary wedge from the amplitude spectrum
function binary_wedge = binary_from_ampspec(ampspec)
    if size(ampspec, 1) <= 32
        crop_size = size(ampspec, 1);
    elseif round(size(ampspec, 1) / 2) <= 32
        crop_size = round(size(ampspec, 1) / 2);
    elseif round(size(ampspec, 1) / 4) <= 32
        crop_size = round(size(ampspec, 1) / 4);
    else
        crop_size = round(size(ampspec, 1) / 8);
    end

    if mod(crop_size, 2) == 1
        crop_size = crop_size + 1;
    end

    crop_start = size(ampspec) / 2 + 1 - (crop_size / 2);
    norm_ampspec = tom_red(ampspec, crop_start, repmat(crop_size, 1, 3));
    norm_ampspec = (norm_ampspec - mean(norm_ampspec(:))) ./ ...
        std(norm_ampspec(:), 1);
    best_ccc = [-1, -60, 60];
    n_voxels = numel(norm_ampspec);
    for min_angle = -60:-1
        for max_angle = 1:60
            wedge = av3_wedge(norm_ampspec, min_angle, max_angle);
            wedge = min(wedge, norm_ampspec);
            norm_wedge = (wedge - mean(wedge(:))) ./ std(wedge(:), 1);
            ccc = norm_ampspec .* norm_wedge;
            ccc = sum(ccc(:)) ./ n_voxels;
            if ccc > best_ccc(1)
                best_ccc = [ccc, min_angle, max_angle];
            end
        end
    end
    binary_wedge = av3_wedge(ampspec, best_ccc(2), best_ccc(3));
end

%% Test if file exists
function file_exists = isfile(filename)
    [status, attrib] = fileattrib(filename);
    file_exists = status;
end
