function lmb_extract_noise(tomo_folder, tomo_digits, root_folder, tomo_row, ...
                           noisename, allmotlfilename, subtomosize, ...
                           num_noise, checkstartname, checkdonename)
% LMB_EXTRACT_NOISE 
% A script for extracting subtomograms on the cluster. This can be run in
% parallel with local scripts, as it writes out a check file when it starts
% extraction and a check file when it completes extraction.
%
% This script also writes out the statistics for each subtomogram from
% tom_dev. There are writen out as the subtomo_stats_tomonum.csv files in their
% respective subtomogram averaging folders.
% Columns of the statistics arrays are as follows:
% Subtomo Num, Mean, Max, Min, Standard Deviation, Variance
%
% v2: some edits to allow for assignment of subtomogram names and leading
% zeros in subtomogram number. This is primarily for extraction for DYNAMO.
% Also allows for naming the path of the stats file.
%
% Ww 09-2016

%% Evaluate numeric inputs
if ischar(tomo_digits)
    tomo_digits = str2num(tomo_digits);
end

if ischar(tomo_row)
    tomo_row = str2num(tomo_row);
end

if ischar(subtomosize)
    subtomosize = str2num(subtomosize);
end

if ischar(num_noise)
    num_noise = str2num(num_noise)
end

%% Initialize
% Read in allmotl
allmotl = tom_emread(allmotlfilename);
allmotl = allmotl.Value;

% Determine tomogram numbers
tomos = unique(allmotl(tomo_row, :));
n_tomos = size(tomos, 2);

% Go to root folder
cd(root_folder);

%% Write out subtomograms
% Loop through each tomo in the allmotl
for tomo_idx = 1:n_tomos
    % Tomogram string
    tomo_str = sprintf(['%0', num2str(tomo_digits), 'd'], tomos(tomo_idx));

    % Check if it's not already being processed
    if ~exist([checkstartname, '_', tomo_str], 'file')
        disp(['Starting on tomogram: ', tomo_str]);

        % Create start file
        system(['touch ', checkstartname, '_', tomo_str]);

        % Parse motls
        temp_motl = allmotl(:,  allmotl(tomo_row, :)==tomos(tomo_idx));
        num_tomo_ptcl = size(temp_motl, 2);

        % Read in the tomogram
        vol = tom_mrcread([tomo_folder, '/', tomo_str, '.rec']);
        vol_dim = [ vol.Header.MRC.nx, vol.Header.MRC.ny, vol.Header.MRC.nz ];

        % Noise motls
        noise_motl = zeros(20, num_noise);

        % Noise tomogram limits
        half_boxsize = subtomosize / 2;
        abs_min = [ subtomosize, subtomosize, subtomosize ];
        abs_max = vol_dim - abs_min;

        noise_count = 0;
        while noise_count < num_noise
            test = [randi([abs_min(1), abs_max(1)]),...
                    randi([abs_min(2), abs_max(2)]),...
                    randi([abs_min(3), abs_max(3)])];
            test_min = test - half_boxsize;
            test_max = test + half_boxsize - 1;

            do_collide = false;
            for ptcl_idx = 1:num_tomo_ptcl
                ptcl = temp_motl(8:10, ptcl_idx);
                ptcl_min = ptcl - half_boxsize;
                ptcl_max = ptcl + half_boxsize - 1;
                do_collide = all(  (test_min <= ptcl_max)...
                                 & (test_max >= ptcl_min));
                if do_collide
                    break;
                end
            end

            if (noise_count > 0) & ~do_collide
                for noise_idx = 1:noise_count
                    noise = noise_motl(8:10, noise_idx);
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
                noise_motl(8:10, noise_count + 1) = test;
                noise_count = noise_count + 1;
            end
        end

        % Extract the subtomograms for each tomogram
        disp('Generating average noise amplitude spectra');
        noise_ampspec_name = [noisename, '_', tomo_idx, '.em'];
        noise_ampspec = extract_noise_ampspec(subtomosize, vol.Value,...
                                              noise_motl);

        % Cleanup
        clear vol
        disp(['Tomogram: ', tomo_str, ' extracted!!']);
        system(['touch ', checkdonename, '_', tomo_str]);
    end
end

function noise_ampspec_avg = extract_noise_ampspec(...
    subtomosize,...
    vol,...
    motl_vec)
%% extract_noise_ampspec
% A modified version of flo_extract_subtomos_MPMV. This is written as a
% function for batch processing. This function takes in an already opened 
% motl rather than a filename. -WW 09/2014
%
% v2: 
%
% WW 09-2016
disp('Tomogram read; begin extraction!!!!');

%% Extract and writeout subtomos
% Initialize amplitude spectrum volume
noise_ampspec_sum = zeros(subtomosize, subtomosize, subtomosize);
num_noise = size(motl_vec, 2);

for indx = 1:num_noise
    noise_pos = transpose(motl_vec(8:10, indx));
    noise_start = round(noise_pos - (subtomosize / 2));
    noise_size = ones(1, 3) * subtomosize;

    % Input the bottom,left,rear corner of the box and the box edge
    % dimensions. The extact the volume and convert to double.
    noise_vol = tom_red(vol, noise_start, noise_size);
    noise_vol = double(noise_vol);
    noise_ampspec = fftshift(tom_fourier(noise_vol));
    noise_ampspec = sqrt(noise_ampspec .* conj(noise_ampspec));
    noise_ampspec_sum = noise_ampspec_sum + noise_ampspec;
end

noise_ampspec_avg = noise_ampspec_sum ./ num_noise;
noise_ampspec_avg = noies_ampspec_avg ./ max(noise_ampspec_avg(:));
