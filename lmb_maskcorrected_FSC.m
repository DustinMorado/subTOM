%% will_maskcorrected_FSC
% A script to take in two references and an FSC mask, and calculate a
% "mask-corrected" FSC. This works by randomizing the structure factor
% phases beyond a particular resolution and calculating an additional FSC.
% This allows for the determination of the extra correlation caused by
% overfitting or effects of the mask, which is then subtracted by the
% normal FSC curves. The theoretical procedure is described it Chen et al,
% Ultramicroscpy, 2013; (doi:10.1016/j.ultramic.2013.06.004). 
%
% The script can also output B-factor sharpened maps. This setting has two
% threshold settings: FSC and pixel. FSC allows you to use a FSC value as a
% cutoff for the lowpass filter, while using pixels allows you to use an
% arbitrary resolution cutoff. 
%
% This script can also perform CTF-reweighting using pre-calculated
% weighting filters. CTF-reweighting filters can be calculated with
% will_generate_ctf_reweight_filter.m
%
% -WW 06-2015 
%
% Updated to make the phase randomization work? It's around 3x faster...
% 
% -WW 06-2016

%% Inputs
name = 'test_ref_3';
oname = 'labmeeting_mine_ref_3';
refA_name = ['even/normWeightedTests/ampspec/ref/', name, '.em']; % Reference A
refB_name = ['odd/normWeightedTests/ampspec/ref/', name, '.em']; % Reference B
mask_name = 'fscmask.em'; % FSC mask ('none' for no mask)
pixelsize = (1.177); % Pixelsize (Angstroms)
symmetry = 2; % Symmetry (1 is no symmetry)

% X-axis label resolutions (in Angstroms)
resolution_label = 0; % (1 = on, 0 = off/Fourier pixels)
res_label = [32,16,8,4];

% CTF Reweighting
ctf_reweight = 1;    % 0 = off, 1 = on
ctf_filter_A = 'ctffilter_even.em';  % Filter A
ctf_filter_B = 'ctffilter_odd.em';  % Filter B


% Sharpen map
sharpen = 1; % 0 = off, 1 = on
bfactor = -100; % B-factor (Should be negative)
sharp_name = [oname, '_finalsharpref_',...
              num2str(bfactor * -1), '.em']; % Ouput name
unsharp_name = [oname, '_unsharpref.em'];
ctf_sharp_name = [oname, '_finalsharpref_',...
                  num2str(bfactor * -1), '_rectf.em'];
plot_sharp = 0; % Plot sharpening curve (0 = off, 1 = on)
% Lowpass filter mode (Mode 1 = FSC threshold, Mode 2 = pixel threshold)
filtermode = 1;
filterthresh = 0.143; % Lowpass filter threshold
% Smooth box edge 
box_gauss = 5; % 0 = off, otherwise odd number must be given.


%% Initialize 
% Read references
refA = emread(refA_name);
refB = emread(refB_name);

% Size of edge of box
edge = size(refA,1);

% Read mask
if ~strcmp(mask_name ,'none')
    mask = emread(mask_name);
else
    mask = ones(size(refA));
end

% Apply symmetry
if symmetry > 1
    refA = tom_symref(refA,symmetry);
    refB = tom_symref(refB,symmetry);
end

% Apply masks
mrefA = refA.*mask;
mrefB = refB.*mask;

% Fourier transforms of masked structures
mftA = fftshift(fftn(mrefA));
mftB = fftshift(fftn(mrefB));

%% Calculate initial steps of Normal FSC calculation
disp('Polarizing!!!');

% Calculate pixel distance array
R = will_distancearray(refA,1);

% Initial calculations for FSC
AB_cc = mftA.*conj(mftB);     % Complex conjugate of A and B
intA =  mftA.*conj(mftA);     % Intensity of A
intB =  mftB.*conj(mftB);     % Intensity of B

%% Sum Fourier shells
tic
% Number of Fourier Shells
n_shells = edge/2;  % Hardcoded to half the box-size

% Normal shell arrays
AB_cc_array = zeros(1,n_shells); % Complex conjugate of A and B
intA_array = zeros(1,n_shells); % Intenisty of A
intB_array = zeros(1,n_shells); % Intenisty of B

% Precalculate shell masks
shell_mask = cell(n_shells,1);
for i = 1:n_shells
    % Shells are set to one pixel size
    shell_start = (i-1);
    shell_end = i;
    
    % Generate shell mask
    temp_mask = (R >= shell_start) & (R < shell_end);
    
    % Write out linearized shell mask
    shell_mask{i} = temp_mask(:);
end

% Sum numbers for each shell
for i = 1:n_shells
    % Write normal outputs
    AB_cc_array(i) = sum(AB_cc(shell_mask{i}));
    intA_array(i) = sum(intA(shell_mask{i}));
    intB_array(i) = sum(intB(shell_mask{i}));
end

%% Calculate Normal FSC
fsc = real(AB_cc_array) ./ sqrt(intA_array .* intB_array);

%% Calculate initial steps of Randomized FSC calculation
cutoff = find(fsc < 0.8, 1, 'first')

% Generate phase-randomized density maps
disp('Randomizing phases!');

% Determine for phase randomization
pr_sub = (R > cutoff);
pr_idx = find(pr_sub);
n_pr = size(pr_idx,1);

% Calculate Fourier transforms
ftA = fftshift(fftn(refA));
ftB = fftshift(fftn(refB));

% Split phases and amplitudes of high resolution data
phase_A = angle(ftA);
phase_B = angle(ftB);
amp_A = abs(ftA);
amp_B = abs(ftB);

% Randomize phases
rphase_A = phase_A;
rphase_B = phase_B;
rphase_A(pr_idx) = phase_A(pr_idx(randperm(n_pr)));
rphase_B(pr_idx) = phase_B(pr_idx(randperm(n_pr)));

% Apply randomized phases to reference FTs
rftA = amp_A.*exp(rphase_A*sqrt(-1));
rftB = amp_B.*exp(rphase_B*sqrt(-1));

% Generate phase-randomized real-space maps
rrefA = ifftn(ifftshift(rftA));
rrefB = ifftn(ifftshift(rftB));

% Apply masks
mrrefA = rrefA.*mask;
mrrefB = rrefB.*mask;

% Fourier transforms of masked structures
mrftA = fftshift(fftn(mrrefA));
mrftB = fftshift(fftn(mrrefB));

% Initial calculations for phase-randomized FSC
rAB_cc = mrftA.*conj(mrftB);     % Complex conjugate of A and B
rintA =  mrftA.*conj(mrftA);     % Intensity of A
rintB =  mrftB.*conj(mrftB);     % Intensity of B

% Phase-randomized shell arrays
rAB_cc_array = zeros(1,n_shells); % Complex conjugate of A and B
rintA_array = zeros(1,n_shells); % Intenisty of A
rintB_array = zeros(1,n_shells); % Intenisty of B

% Sum numbers for each shell
for i = 1:n_shells
    
    % Write phase randomized outputs
    rAB_cc_array(i) = sum(rAB_cc(shell_mask{i}));
    rintA_array(i) = sum(rintA(shell_mask{i}));
    rintB_array(i) = sum(rintB(shell_mask{i}));
end
toc

% Phase-randomized FSC
rfsc = real(rAB_cc_array) ./ sqrt(rintA_array .* rintB_array);

% Mask-corrected FSC
corr_fsc = fsc;
corr_fsc((cutoff + 2):end) =    (  fsc((cutoff + 2):end) ...
                                 - rfsc(cutoff + 2:end)) ...
                             ./ (1 - rfsc((cutoff + 2):end));

% Plot corrected FSC
hold on
plot(1:size(fsc, 2), fsc);
plot(1:size(rfsc, 2), rfsc);
plot(1:size(corr_fsc,2),corr_fsc);

grid on
axis ([0 n_shells -0.1 1.05]);
set (gca, 'yTick', [0 0.143 0.5 1.0]);

% Label X-axis with resolution labels
if resolution_label == 1
    
    % Number of labels
    n_res = numel(res_label);

    % X-value for each label
    x_res = zeros(n_res,1);
    for i = 1:n_res
        x_res(i) = (edge*pixelsize)/res_label(i);
    end

    set (gca, 'XTickLabel', res_label)
    set (gca, 'XTick', x_res)
end

%% CTF-reweighting
if (ctf_reweight == 1) && (sharpen == 1)
    % Read in filter
    filter_A = emread(ctf_filter_A);
    % Find non_zero parts of tiler
    non_zero = filter_A~=0;
    % Reweight Fourier transform
    ftA_rectf = ftA;
    ftA_rectf(non_zero) = (ftA_rectf(non_zero)./filter_A(non_zero));
    % Zero outside frequencies
    ftA_rectf = ftA_rectf.*non_zero;
    % Inverse FFT
    refA_rectf = ifftn(ifftshift(ftA_rectf));
    
    % Read in filter
    filter_B = emread(ctf_filter_B);
    % Find non_zero parts of tiler
    non_zero = filter_B~=0;
    % Reweight Fourier transform
    ftB_rectf = ftB;
    ftB_rectf(non_zero) = (ftB_rectf(non_zero)./filter_B(non_zero));
    % Zero outside frequencies
    ftB_rectf = ftB_rectf.*non_zero;
    % Inverse FFT
    refB_rectf = ifftn(ifftshift(ftB_rectf));
end


%% Smooth box edges

if box_gauss ~= 0
    % Smooth box edges
    refA = will_smooth_box_edge(refA, box_gauss);
    refB = will_smooth_box_edge(refB, box_gauss);
    if (ctf_reweight == 1)
        refA_rectf = will_smooth_box_edge(refA_rectf, box_gauss);
        refB_rectf = will_smooth_box_edge(refB_rectf, box_gauss);
    end
end


%% Sharpening

if sharpen == 1
    % Average reference
    ref_avg = (refA + refB)./2;
    
    % Sharpen reference
    sharp_ref = will_sharpen_function(ref_avg,bfactor,corr_fsc,pixelsize,filtermode,filterthresh,plot_sharp);
    
    % Write out reference
    emwrite(-sharp_ref,sharp_name);
    emwrite(-ref_avg, unsharp_name);
    
    if (ctf_reweight == 1)
        ref_avg_rectf = (refA_rectf + refB_rectf)./2;
        sharp_ref_rectf = will_sharpen_function(ref_avg_rectf,bfactor,corr_fsc,pixelsize,filtermode,filterthresh,plot_sharp);
        emwrite(-sharp_ref_rectf, ctf_sharp_name);
    end
end


%% Calculate FSCs at points of interest
% Points of interest
fsc_points = [0.5, 0.143];
n_points = size(fsc_points,2);
% Array to hold FSC values
fsc_values = zeros(1,n_points);

for i = 1:n_points
    % Find point after value
    x2=find(corr_fsc<=fsc_points(i),1);
    y2=corr_fsc(x2);
    % Find point before value
    x1=find(corr_fsc(1:x2)>=fsc_points(i),1,'last');
    y1=fsc(x1);
    
    % Slope
    m = (y2-y1)/(x2-x1);

    % Find X-value
    x_val = ((fsc_points(i)-y1)/m)+x1;
    
    % Write out resolution
    fsc_values(i) = (size(refA,1)*pixelsize)/x_val;
    
    % Display output
    disp(['FSC at ',num2str(fsc_points(i)),' = ',num2str(fsc_values(i)),' Angstroms.']);    
end
