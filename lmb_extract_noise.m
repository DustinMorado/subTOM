function lmb_extract_noise(tomogram_dir, tomo_digits, scratch_dir, tomo_row, ...
    ampspec_fn_prefix, all_motl_fn, noise_motl_fn, subtomogram_size, ...
    num_noise, check_start_fn_prefix, check_done_fn_prefix)
% LMB_EXTRACT_NOISE extract noise amplitude spectra on the cluster.
% LMB_EXTRACT_NOISE(TOMOGRAM_DIR, TOMO_DIGITS, SCRATCH_DIR, TOMO_ROW,
%   AMPSPEC_FN_PREFIX, ALL_MOTL_FN, NOISE_MOTL_FN, SUBTOMOGRAM_SIZE, ...
%   NUM_NOISE, CHECK_START_FN_PREFIX, CHECK_DONE_FN_PREFIX)
%
% See also LMB_EXTRACT_SUBTOMOGRAMS

% DRM 11-2017
% ==============================================================================

% Evaluate numeric inputs
if ischar(tomo_digits)
    tomo_digits = str2double(tomo_digits);
end

if ischar(tomo_row)
    tomo_row = str2double(tomo_row);
end

if ischar(subtomogram_size)
    subtomogram_size = str2double(subtomogram_size);
end

if ischar(num_noise)
    num_noise = str2double(num_noise);
end

% Read in allmotl
allmotl = getfield(tom_emread(all_motl_fn), 'Value');

% Determine tomogram numbers
tomos = unique(allmotl(tomo_row, :));
n_tomos = size(tomos, 2);

% Go to root folder
cd(scratch_dir);

% check if noisemotl has already been calculated and if so read it in or
% otherwise initialize a new empty one
if exist(fullfile(pwd(), noise_motl_fn), 'file') == 2
    noise_motl = getfield(tom_emread(noise_motl_fn), 'Value');
    if size(noise_motl, 2) < (n_tomos * num_noise)
        write_noise_motl = 1;
    else
        write_noise_motl = 0;
    end
else
    noise_motl = [];
    write_noise_motl = 1;
end

% Loop through each tomo in the allmotl
for tomo_idx = 1:n_tomos
    % Tomogram string
    tomo_num = tomos(tomo_idx);
    tomo_str = sprintf(['%0', num2str(tomo_digits), 'd'], tomo_num);

    % Check if it's not already being processed
    if ~exist(fullfile(pwd(), sprintf('%s_%s', check_start_fn_prefix, tomo_str)), ...
              'file')
        % Create start file
        fclose(fopen(sprintf('%s_%s', check_start_fn_prefix, tomo_str), 'w'));

        % Parse particle motls
        tomo_motl = allmotl(:,  allmotl(tomo_row, :) == tomo_num);
        num_tomo_ptcl = size(tomo_motl, 2);

        % If it exists (non-empty) parse noise motls
        if size(noise_motl, 2) > 0
            tomo_noise_motl = noise_motl(:, ...
                                         noise_motl(tomo_row, :) == tomo_num);
            noise_count = size(tomo_noise_motl, 2);
        else
            tomo_noise_motl = [];
            noise_count = 0;
        end

        % Read in the tomogram
        vol = tom_mrcread(fullfile(tomogram_dir, sprintf('%s.rec', tomo_str)));
        vol_dim = [ vol.Header.MRC.nx, vol.Header.MRC.ny, vol.Header.MRC.nz ];

        % Noise tomogram limits
        half_boxsize = subtomogram_size / 2;
        abs_min = [ subtomogram_size, subtomogram_size, subtomogram_size ];
        abs_max = vol_dim - abs_min;

        while noise_count < num_noise
            test = [randi([abs_min(1), abs_max(1)]),...
                    randi([abs_min(2), abs_max(2)]),...
                    randi([abs_min(3), abs_max(3)])];
            test_min = test - half_boxsize;
            test_max = test + half_boxsize - 1;

            do_collide = false;
            for ptcl_idx = 1:num_tomo_ptcl
                ptcl = tomo_motl(8:10, ptcl_idx);
                ptcl_min = ptcl - half_boxsize;
                ptcl_max = ptcl + half_boxsize - 1;
                do_collide = all(  (test_min <= ptcl_max)...
                                 & (test_max >= ptcl_min));
                if do_collide
                    break;
                end
            end

            if (noise_count > 0) && ~do_collide
                for noise_idx = 1:noise_count
                    noise = tomo_noise_motl(8:10, noise_idx);
                    noise_min = noise - half_boxsize;
                    noise_max = noise + half_boxsize - 1;
                    do_collide = all(  (test_min <= noise_max)...
                                     & (test_max >= noise_min));
                    if do_collide
                        break;
                    end
                end
            end

            if ~do_collide
                temp_noise_motl = zeros(20, 1);
                temp_noise_motl(5:7) = ones(3, 1) * tomo_num;
                temp_noise_motl(8:10) =  test;
                if size(tomo_noise_motl, 2) > 0
                    tomo_noise_motl(:, end + 1) = temp_noise_motl;
                else
                    tomo_noise_motl = temp_noise_motl;
                end

                if size(noise_motl, 2) > 0
                    noise_motl(:, end + 1) = temp_noise_motl;
                else
                    noise_motl = temp_noise_motl;
                end
                noise_count = noise_count + 1;
            end
        end

        % Extract the subtomograms for each tomogram
        noise_ampspec_name = sprintf('%s_%d.em', ampspec_fn_prefix, tomo_num);
        noise_ampspec = extract_noise_ampspec(subtomogram_size, vol.Value,...
                                              tomo_noise_motl);
        tom_emwrite(noise_ampspec_name, noise_ampspec);
        check_em_file(noise_ampspec_name, noise_ampspec);
        % Cleanup
        clear vol
        fclose(fopen(sprintf('%s_%s', check_done_fn_prefix, tomo_str), 'w'));
    end
end

if write_noise_motl
    tom_emwrite(noise_motl_fn, noise_motl); 
    check_em_file(noise_motl_fn, noise_motl); 
end

function noise_ampspec_avg = extract_noise_ampspec(...
    subtomogram_size,...
    vol,...
    motl_vec)
% Initialize amplitude spectrum volume
noise_ampspec_sum = zeros(subtomogram_size, subtomogram_size, subtomogram_size);
num_noise = size(motl_vec, 2);

for indx = 1:num_noise
    noise_pos = transpose(motl_vec(8:10, indx));
    noise_start = round(noise_pos - (subtomogram_size / 2));
    noise_size = ones(1, 3) * subtomogram_size;

    % Input the bottom,left,rear corner of the box and the box edge
    % dimensions. The extact the volume and convert to double.
    noise_vol = tom_red(vol, noise_start, noise_size);
    noise_vol = double(noise_vol);
    noise_ampspec = fftshift(tom_fourier(noise_vol));
    noise_ampspec = sqrt(noise_ampspec .* conj(noise_ampspec));
    noise_ampspec_sum = noise_ampspec_sum + noise_ampspec;
end

noise_ampspec_avg = noise_ampspec_sum ./ num_noise;
noise_ampspec_avg = noise_ampspec_avg ./ max(noise_ampspec_avg(:));

%% check_em_file
% A function to check that an EM file was correctly written.
function check_em_file(em_fn, em_data)
    while true
        try
            % If this fails, catch command is run
            tom_emread(em_fn);
            break
        catch
            tom_emwrite(em_fn, em_data);
        end
    end
