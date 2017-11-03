function will_scan_angles_exact8(startnumber,ind,batchnumberofparticles,refilename,particleallmotlfilename,particlemotlfilename,particlefilename,wedgelist,tomorow,wedgemaskname,particlefiltername,mask,masksubtomo,ccmask,checkfilename,angincr,angiter,phi_angincr,phi_angiter,hipass,lowpass,nfold,threshold,iclass)

%% Some general notes on how this works -WW
% In general, normalization seems to occur by subtracting the mask-weighted
% mean value from the masked volumes in real space, then dividing by the
% mean amplitude in Fourier space.
%
% The subtomograms are never shifted, only the reference and the alignment
% mask applied to the subtomogram.
%
% v4 is updated with will_find_subpixel_peak for shift and CC determination. 
% WW 01-2016
%
% v5 is updated with code to check output motl files. 
%
% v6 allows for optional masking of the subtomogram.
%
% v7 these updates not used...
%
% v8 options added for applying a Fourier filter mask to subtomograms and
% using alternate wedge masks on the references. 
%
% WW 03-2016

% % Debug
% startnumber = 3;
% ind = 1;
% batchnumberofparticles = 720;
% refilename = './ref/ref';
% particleallmotlfilename = './combinedmotl/allmotl';
% particlemotlfilename = './motl/motl';
% particlefilename = './subtomograms/subtomo';
% checkfilename = './checkjobs/checkfileali';
% wedgelist = './otherinputs/wedgelist.em';
% angincr = 2;
% angiter = 5;
% phi_angincr = 2;
% phi_angiter = 5;
% mask = './otherinputs/mask.em';
% masksubtomo = 1;
% ccmask = './otherinputs/ccmask.em';
% hipass = 1;
% lowpass = 9;
% nfold = 1;
% threshold = 0;
% iclass = 1;

tic
%% Evaluate numeric inputs
if (ischar(masksubtomo)); masksubtomo=eval(masksubtomo); end
if (ischar(iclass)); iclass=eval(iclass); end
if (ischar(threshold)); threshold=eval(threshold); end
if (ischar(nfold)); nfold=eval(nfold); end
if (ischar(lowpass)); lowpass=eval(lowpass); end
if (ischar(hipass)); hipass=eval(hipass); end
if (ischar(angiter)); angiter=eval(angiter); end
if (ischar(angincr)); angincr=eval(angincr); end
if (ischar(phi_angiter)); phi_angiter=eval(phi_angiter); end
if (ischar(phi_angincr)); phi_angincr=eval(phi_angincr); end
if (ischar(tomorow)); tomorow=eval(tomorow); end
if (ischar(batchnumberofparticles)); batchnumberofparticles=eval(batchnumberofparticles); end
if (ischar(ind)); ind=eval(ind); end
if (ischar(startnumber)); startnumber=eval(startnumber); end

%% Prepare masks

% Read in alignment masks
mask = emread(mask);     % Alignment mask
boxsize = size(mask,1);

% Read in CC mask if shifts are being refined
if ~strcmp(ccmask,'noshift')
    mask_y = emread(ccmask); % CC mask
end

% Calculate bandpass mask
mask_lowpass_3 = vince_spheremask(mask,lowpass,3);
mask_hipass_2 = vince_spheremask(mask,hipass,2);
mask_x = mask_lowpass_3-mask_hipass_2; % Bandpass mask
clear mask_lowpass_3;
clear mask_hipass_2;

% Calculate total signal passthrough in alignment mask
npixels = sum(mask(:)); 
% Calcualte center of box
cent = [floor(boxsize/2)+1 floor(boxsize/2)+1 floor(boxsize/2)+1];

% Mask for box-edges for subtomogram if align mask is not applied
if masksubtomo == 0
    % Initialize some hardcoded parameters for particle sphere mask
    maskrad = floor((boxsize/2)*0.8); % Set hard-edge as 0.8 radius
    sigma = floor((boxsize/2)*0.15); % Set gaussian sigma to 0.15 radius

    % Initialize a sphere mask
    spheremask=tom_sphere([boxsize,boxsize,boxsize],maskrad,sigma);
end

%% Prepare reference

% Read references
refname = [refilename '_' num2str(ind) '.em'];
ref = emread(refname);
% Perform n-fold symmetrization of reference. If a volume VOL is assumed to have a n-fold symmtry axis along Z it can be rotationally symmetrized
if nfold ~= 1
    ref = tom_symref(ref,nfold); 
end

% % Determine mean and stand deviation of reference
% [mref, xx1, xx2, mstd] = tom_dev(ref,'noinfo'); 
% % Normalize reference
% ref = (ref - mref)./mstd; % ww: I don't think this is necessary, as the reference is scaled again after masking and FTs

% Mask reference
m_ref = ref.*mask;
% Subtract the mask-weighted mean value
m_ref = m_ref - mask.*(sum(m_ref(:))/npixels);

%% Generate missing wedges
% Read in wedgelist
wedgelist = emread(wedgelist);


%% Prepare remaining inputs

% Read in allmotl file
allmotlname = [particleallmotlfilename '_' num2str(ind) '.em'];
allmotl = emread(allmotlname);


% Calculate end of motl batch to align
totnumberofparticles = size(allmotl,2); % Total number of particles in entire 
% If the motl ends before size of batch
if startnumber+batchnumberofparticles-1 > totnumberofparticles
    endnumber = totnumberofparticles; % Set endnumber to end of allmotl
else
    endnumber = startnumber+batchnumberofparticles-1; % Send endnumber based on batch size
end

%% Perform angular search
% Initialize wedge arrays for on-the-fly generation of the wedge masks
curr_wedge = 0;
wedge_mask = zeros(size(ref));



% Loop over batch
for indpart = startnumber:endnumber

     % Subtomogram number from allmotl file
     subtnumber = allmotl(4,indpart);
     % Parse out a single motl
     motl = allmotl(:,indpart);


     % Check if motl should be procesed based on class
     if ((motl(20,1) == 1) || (motl(20,1) == 2) || (motl(20,1) == iclass))

         % Check wedge and generated mask if needed
         if curr_wedge ~= motl(5,1)
             
             % Set current wedge
             curr_wedge = motl(5,1);
             
             % Wedge mask to apply to reference
             if strcmp(wedgemaskname,'none')
                 % Generate wedge mask
                 minangle = wedgelist(2,(wedgelist(1,:)==curr_wedge));
                 maxangle = wedgelist(3,(wedgelist(1,:)==curr_wedge));
                 wedge_mask = av3_wedge(ref,minangle,maxangle);
             else
                 % Read in per-tomogram wedge mask  
                 wedge_mask = emread([wedgemaskname,'_',num2str(motl(tomorow,1)),'.em']); 
                 
             end  
             
             % Fourier mask to apply to subtomogram
             if ~strcmp(particlefiltername,'none')
                 particlefilter = emread([particlefiltername,'_',num2str(motl(tomorow,1)),'.em']);
             end
             
         end
         

         
         
         % Parse Euler angles from motl
         phi_old = motl(17,1);
         psi_old = motl(18,1);
         the_old = motl(19,1);
         % Parse shifts from motl file
         rshift(1) = motl(11,1);
         rshift(2) = motl(12,1);
         rshift(3) = motl(13,1);

         % Initialize CCC 
         ccc = -1;
         % Initialize shift vector
         tshift = 0;


         % Read in subtomogram
         name = [particlefilename '_' num2str(subtnumber) '.em'];
         particle = emread(name);     
         if masksubtomo == 1
             % Rotate alignment mask
             rmask = tom_rotate(mask,[phi_old,psi_old,the_old]);
             % Shift alignment mask
             shiftmask = tom_shift(rmask,rshift); % shifts an image by a vector. The shift is performed in Fourier space
             % Mask subtomogram
             particle = shiftmask.*particle;
             % Subtract the mask-weighted mean value
             particle = particle - shiftmask.*(sum(particle(:))/npixels);
         else
             % Sphere mask subtomogram
             particle = particle.*spheremask;
             % Normalize subtomogram             
             particle = particle - spheremask.*(sum(particle(:))/sum(spheremask(:)));
         end


         % Fourier transform particle
         fpart = fftshift(tom_fourier(particle)); % Shift zero-frequency component to center of spectrum.
         % Apply bandpass filter and inverse FFT shift
         if strcmp(particlefiltername,'none')
             fpart = ifftshift(fpart.*mask_x);
         else
             fpart = ifftshift(fpart.*mask_x.*particlefilter);
         end
         % Set 0-frequency peak to zero
         fpart(1,1,1) = 0;
         % Divide by mean amplitude
%          fpart = (size(fpart,1)*size(fpart,2)*size(fpart,3))*fpart/sqrt((sum(sum(sum(fpart.*conj(fpart))))));
         fpart = ((boxsize^3).*fpart)./sqrt((sum(sum(sum(fpart.*conj(fpart))))));


         % Loop over phi range
         phi_range = phi_old-phi_angiter*phi_angincr:phi_angincr:phi_old+phi_angiter*phi_angincr;
         if isempty(phi_range)
             phi_range = phi_old;
         end
         
         for phi = phi_range

             % Loop for increments in theta
            for ithe =  0:ceil(angiter/2)

                if ithe == 0    % For no theta increments
                    npsi = 1;   % Number of psi iterations
                    dpsi = 360; % Change in psi

                else %sampling for psi and the on unit sphere in rings
                    dpsi = angincr/sin(ithe*angincr/180*pi); % Change in psi
                    npsi = ceil(360/dpsi); % Number of psi iterations
                end

                % Loop through psi increments
                for ipsi = 0:(npsi-1)
                    % Set point on top of unit sphere
                    r = [ 0 0 1];
                    % Get position after search cone-rotation
                    r = tom_pointrotate(r,0,ipsi*dpsi,ithe*angincr);
                    % Get position after old cone-rotation
                    r = tom_pointrotate(r,0,psi_old,the_old);
                    % Generate psi and theta from rotation position
                    the = 180/pi*atan2(sqrt(r(1).^2+r(2).^2),r(3));
                    psi = 180/pi*atan2(r(2),r(1)) + 90;

                    % Rotate the masked reference
                    rpart = tom_rotate(m_ref,[phi,psi,the]);
                    % Calculate shifted fourier transform of
                    % rotated reference
                    fref = fftshift(tom_fourier(rpart));
                    % Apply bandpass filtered wedge and edge mask,
                    % then invert fftshift
                    fref = ifftshift(wedge_mask.*fref.*mask_x);
                    % Set 0-frequency to zero
                    fref(1,1,1) = 0;
                    % Divide by mean amplitude
%                     fref = (size(fref,1)*size(fref,2)*size(fref,3))*fref/sqrt((sum(sum(sum(fref.*conj(fref))))));   % to be changed?
                    fref = ((boxsize^3).*fref)./sqrt((sum(sum(sum(fref.*conj(fref))))));

                    
                    %calculate rms - IMPORTANT! - missing wedge!!! 
                    % Calculate cross correlation and apply rotated ccmask
                    ccf = real(fftshift(tom_ifourier(fpart.*conj(fref))));
                    ccf = real(ccf/(boxsize.^3)); % added for normalization - FF

                    % Determine CCC
                    if ~strcmp(ccmask,'noshift');
                        
                        % Rotate cc mask                    
                        rccmask = tom_rotate(mask_y,[phi,psi,the]);

                        % Find ccc peak
                        [pos, ccctmp] = will_find_subpixel_peak(ccf.*rccmask);

                    else
                        
                        % Find peak at previous center for no shift
                        pos = rshift;
                        ccctmp = ccf(round(rshift(1)),round(rshift(2)),round(rshift(3)));
                        
                    end
                                        
                    % If CCC is greater than current ccc, update
                    % ccc, Euler angles, and shifts
                    if ccctmp > ccc
                        ccc = ccctmp;
                        phi_opt = phi;
                        psi_opt = psi;
                        the_opt = the;
                        if pos<0 % If the position of the peak is less than zero
                            tshift = rshift; % Set shift to old shifts
                        else
                            tshift = pos-cent; % Else set shift to peak position minus center position
                        end
                    end
                end
            end
        end
        motl(17,1) = phi_opt;
        motl(18,1) = psi_opt;
        motl(19,1) = the_opt;
        motl(11,1) = tshift(1);
        motl(12,1) = tshift(2);
        motl(13,1) = tshift(3);
        rshift = tom_pointrotate(tshift,-psi_opt,-phi_opt,-the_opt);
        motl(1,1) = ccc;
        motl(2:10,1)=allmotl(2:10,indpart);
        %kick off bad particles
        if ccc > threshold  
            motl(20,1) = 1;   %good particles -> class one
        else
            motl(20,1) = 2;   %bad CCF: kick into class 2
        end
      end; %endif
      % Write out motl
      motlname = [particlemotlfilename '_' num2str(indpart) '_' num2str(ind+1) '.em'];
      tom_emwrite(motlname,motl);
      % Check that motl was properly written
      m=0;
      while m == 0
          try
              emread(motlname); % If this fails, catch command is run
              m = 1; % While-loop is exited if the emread works
          catch
              tom_emwrite(motlname,motl);
          end
      end
    
      % Write out checkjob
      checkname = [checkfilename '_' num2str(indpart) '.em'];
      tom_emwrite(checkname,0);

end % end indpart

toc