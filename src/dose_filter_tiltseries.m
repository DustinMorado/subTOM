function dose_filter_tiltseries(input_fn, output_fn, dose_fn)
% DOSE_FILTER_TILTSERIES generates a tiltseries filtered by applied dose.
%     DOSE_FILTER_TILTSERIES(
%         INPUT_FN
%         OUTPUT_FN
%         DOSE_FN)
%
%     A script to read in a tilt stack, and the order_tilt.csv file
%     used to generate the stack in order to dose filter each tilt.
%
% Example:
%     DOSE_FILTER_TILTSERIES('TS_01_aligned.st', 'TS_01_dose_filt.st', ...
%         'TS_01_dose-list.csv');

% DM 04-2017
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% input_fn = 'TS_01_aligned.st';
% output_fn = 'TS_01_dose_filt.st';
% dose_fn = 'TS_01_dose-list.csv';
%##############################################################################%
    % Read in tilt stack
    input_ts = read_serialEM_MRC(input_fn);

    % Calculate the number of tilt images in the series and the pixel size
    % based on the information in the header.
    num_tilts = input_ts.Header.MRC.nz;
    pixel_size =   double(input_ts.Header.MRC.xlen) ...
                 / double(input_ts.Header.MRC.mx);

    % Read in dose list
    dose_list = csvread(dose_fn);

    if (size(dose_list) ~= num_tilts)
        disp('ERROR: dose list file not the same size as input tilt series!');
        return;
    end

    % Determine cropped image indices
    image_size = double(min(input_ts.Header.MRC.nx,...
                            input_ts.Header.MRC.ny));

    start_x = ((double(input_ts.Header.MRC.nx) - image_size) / 2) + 1;
    end_x = double(input_ts.Header.MRC.nx) - (start_x - 1);
    start_y = ((double(input_ts.Header.MRC.ny) - image_size) / 2) + 1;
    end_y = double(input_ts.Header.MRC.ny) - (start_y - 1);

    % Precalculate frequency array
    freq_origin = floor(image_size / 2);
    fourier_pixel_size = 1 / (image_size * pixel_size);
    [freq_x, freq_y] = ndgrid(-freq_origin:image_size - (freq_origin + 1));
    freq_array = sqrt((freq_x.^2) + (freq_y.^2)) .* fourier_pixel_size;

    % Generate filtered stack
    filtered_tiltseries = zeros(image_size, image_size, num_tilts);
    for tilt_idx = 1:num_tilts
        filtered_tiltseries(:, :, tilt_idx) = dose_filter_tilt_image(...
            input_ts, tilt_idx,...
            start_x, end_x, start_y, end_y,...
            dose_list(tilt_idx), freq_array);
    end

    % We reuse the header from the input stack for labels etc. and write out
    input_ts.Value = filtered_tiltseries;
    write_serialEM_MRC(output_fn, input_ts);
end

%##############################################################################%
%                              READ_SERIALEM_MRC                               %
%##############################################################################%
function [Data] = read_serialEM_MRC(input_fn)
% READ_SERIALEM_MRC Correctly read MRC-files and extended headers from SerialEM.
%     READ_SERIALEM_MRC(
%         INPUT_FN)
%
%     Reads MRC format file with the name INPUT_FN.
%
% Structure of MRC-data files:
% MRC Header has a length of 1024 bytes
%  SIZE  DATA    NAME        DESCRIPTION
%    4   int     NX          number of Columns    (fastest changing in map)
%    4   int     NY          number of Rows
%    4   int     NZ          number of Sections   (slowest changing in map)
%
%    4   int     MODE        Types of pixel in image
%                            0 = Image     signed bytes
%                            1 = Image     signed short integer (16 bits)
%                            2 = Image     float
%                            3 = Complex   short*2
%                            4 = Complex   float*2
%                            6 = Image     unsigned short integer (16 bits)
%
%    4   int     NXSTART     Number of first COLUMN  in map (Default = 0)
%    4   int     NYSTART     Number of first ROW     in map      "
%    4   int     NZSTART     Number of first SECTION in map      "
%
%    4   int     MX          Number of intervals along X
%    4   int     MY          Number of intervals along Y
%    4   int     MZ          Number of intervals along Z
%
%    4   float   Xlen        Cell Dimensions (Angstroms)
%    4   float   Ylen                     "
%    4   float   Zlen                     "
%
%    4   float   ALPHA       Cell Angles (Degrees)
%    4   float   BETA                     "
%    4   float   GAMMA                    "
%
%    4   int     MAPC        Which axis corresponds to Columns (1,2,3 for X,Y,Z)
%    4   int     MAPR        Which axis corresponds to Rows
%    4   int     MAPS        Which axis corresponds to Sections
%
%    4   float   AMIN        Minimum density value
%    4   float   AMAX        Maximum density value
%    4   float   AMEAN       Mean    density value    (Average)
%
%    4   int     ISPG        Space group number       (0 for images)
%    4   int     NEXT        Number of bytes in extended header
%    2   short   CREATID     Creator ID
%    6    -      EXTRA       Not used. First two bytes should be set to 0.
%    4   char    EXTTYPE     Type of extended header
%    4   int     NVERSION    MRC version that file conforms to, otherwise 0
%    16   -      EXTRA2      Not used.
%
%    2   short   NINT        Number of bytes per section
%    2   short   NREAL       Bit flags for which types of short data:
%                            1 = tilt angle * 100 (2 bytes)
%                            2 = piece coordinates for montage (6 bytes)
%                            4 = stage coordinates * 25 (4 bytes)
%                            8 = magnification / 100 (2 bytes)
%                            16 = Intensity * 25000 (2 bytes)
%                            32 = Exposure dose (e-/A^2) (a float in 4 bytes)
%                            64, 256, 1024: Reserved for 2-byte items
%                            128, 512: Reserved for 4-byte items
%
%    20   -      EXTRA3      Not used
%    4   int     IMODSTAMP   1146047817 indicates the file was created by IMOD
%    4   int     IMODFLAGS   Bit flags if IMODSTAMP is 1146047817:
%                            1 = bytes are stored as signed
%                            2 = pixel spacing was set from size in ext. header
%                            4 = origin is stored with sign inverted
%                            8 = RMS value is negative if it was not computed
%                            16 = Bytes have two 4-bit values, 1st lo 2nd hi
%
%    2   short   IDTYPE      0=mono, 1=tilt, 2=tilts, 3=lina, 4=lins
%    2   short   LENS
%    2   short   ND1         for IDTYPE = 1, ND1 = axis (1, 2, or 3)
%    2   short   ND2
%    2   short   VD1         100. * tilt increment
%    2   short   VD2         100. * starting angle
%
%    24  float   TILTANGLES  0,1,2 = Original: 3,4,5 = Current
%
%    4   float   XORIGIN     X origin
%    4   float   YORIGIN     Y origin
%    4   float   ZORIGIN     Z origin
%    4   char    CMAP        Contains "MAP "
%    4   char    STAMP       First two bytes have 17,17 for be 68,65 for le
%    4   float   RMS         RMS deviation of densities from mean, < 0 if NC
%
%    4   int     NLABL       Number of labels being used
%    800 char    LABL        10 labels of 80 character
%
% Example:
%     read_serialEM_MRC('TS_01_aligned.st');
%
% See also TOM_EMREAD, TOM_SPIDERREAD, TOM_ISMRCFILE, TOM_MRCWRITE, TOM_MRC2EM
%
% Copyright (c) 2005
% TOM toolbox for Electron Tomography
% Max-Planck-Institute for Biochemistry
% Dept. Molecular Structural Biology
% 82152 Martinsried, Germany
% http://www.biochem.mpg.de/tom
%
% Created: 09/25/02 SN
% Last change: 04/05/17 DRM

    [comp_typ, maxsize, endian] = computer;
    switch endian
        case 'L'
            system_format = 'ieee-le';
        case 'B'
            system_format = 'ieee-be';
    end

    fid = fopen(input_fn, 'r', system_format);
    if fid == -1
        error(['Cannot open: ' input_fn ' file']);
    end;

    % This block of code is added to make sure the file is SEM MRC type
    % We could also check MRC.exttype == 'SERI', but I think this is more
    % compatible. DRM 04/05/2017
    fseek(fid, 92, -1); % Move from beginning of file to MRC.next
    temp_next = fread(fid, 1, '*integer*4');
    if temp_next ~= 0
        fseek(fid, 128, -1); % Move from beginning of file to MRC.nint & nreal
        temp_nint = fread(fid, 1, '*integer*2');
        temp_nreal = fread(fid, 1, '*integer*2');
        if not(is_SEM(temp_nint, temp_nreal))
            error(['MRC file: ' input_fn ' is not a SerialEM MRC file']);
        end
    end
    fseek(fid, 0, -1); % Move back to the beginning of the file.

    MRC.nx = fread(fid, 1, '*integer*4');
    MRC.ny = fread(fid, 1, '*integer*4');
    MRC.nz = fread(fid, 1, '*integer*4');

    MRC.mode = fread(fid, 1, '*integer*4');

    MRC.nxstart = fread(fid, 1, '*integer*4');
    MRC.nystart = fread(fid, 1, '*integer*4');
    MRC.nzstart = fread(fid, 1, '*integer*4');

    MRC.mx = fread(fid, 1, '*integer*4');
    MRC.my = fread(fid, 1, '*integer*4');
    MRC.mz = fread(fid, 1, '*integer*4');

    MRC.xlen = fread(fid, 1, '*real*4');
    MRC.ylen = fread(fid, 1, '*real*4');
    MRC.zlen = fread(fid, 1, '*real*4');

    MRC.alpha = fread(fid, 1, '*real*4');
    MRC.beta = fread(fid, 1, '*real*4');
    MRC.gamma = fread(fid, 1, '*real*4');

    MRC.mapc = fread(fid, 1, '*integer*4');
    MRC.mapr = fread(fid, 1, '*integer*4');
    MRC.maps = fread(fid, 1, '*integer*4');

    MRC.amin = fread(fid, 1, '*real*4');
    MRC.amax = fread(fid, 1, '*real*4');
    MRC.amean = fread(fid, 1, '*real*4');

    MRC.ispg = fread(fid, 1, '*integer*4');

    MRC.next = fread(fid, 1, '*integer*4');

    MRC.creatid = fread(fid, 1, '*integer*2');

    MRC.extra_data1 = fread(fid, 6, '*integer*1');

    MRC.exttype = fread(fid, [1, 4], '*char');

    MRC.nversion = fread(fid, 1, '*integer*4');

    MRC.extra_data2 = fread(fid, 16, '*integer*1');

    MRC.nint = fread(fid, 1, '*integer*2');
    MRC.nreal = fread(fid, 1, '*integer*2');

    MRC.extra_data3 = fread(fid, 20, '*integer*1');

    MRC.imodstamp = fread(fid, 1, '*integer*4');
    MRC.imodflags = fread(fid, 1, '*integer*4');

    MRC.idtype= fread(fid, 1, '*integer*2');
    MRC.lens=fread(fid, 1, '*integer*2');
    MRC.nd1=fread(fid, 1, '*integer*2');
    MRC.nd2 = fread(fid, 1, '*integer*2');
    MRC.vd1 = fread(fid, 1, '*integer*2');
    MRC.vd2 = fread(fid, 1, '*integer*2');

    MRC.tiltangles = fread(fid, 6, '*real*4');

    MRC.xorg = fread(fid, 1, '*real*4');
    MRC.yorg = fread(fid, 1, '*real*4');
    MRC.zorg = fread(fid, 1, '*real*4');

    MRC.cmap = fread(fid, [1, 4], '*char');
    MRC.stamp = fread(fid, 4, '*char');

    MRC.rms=fread(fid, 1, '*real*4');

    MRC.nlabl = fread(fid, 1, '*integer*4');
    MRC.labels = fread(fid, [80, 10], '*char*1')'; % Note the transpose!
    % for some reason the above read of 800 bytes moves the fileID from 224 to 1031
    % and these extra 7 bytes of overread can cause quite some problems. So I just
    % reset the file to the end of the standard header at 1025.
    fseek(fid, 1024, -1);

    if MRC.next ~= 0
        number_of_sections = int32(MRC.next) / int32(MRC.nint);
        for ext_section=1:number_of_sections
            if bitand(MRC.nreal, 1)
                Extended.a_tilt(ext_section) = fread(fid, 1, '*integer*2');
            else
                Extended.a_tilt(ext_section) = NaN;
            end
            if bitand(MRC.nreal, 2)
                Extended.piece_coord_x(ext_section) = fread(fid, 1, ...
                    '*integer*2');

                Extended.piece_coord_y(ext_section) = fread(fid, 1, ...
                    '*integer*2');

                Extended.piece_coord_z(ext_section) = fread(fid, 1, ...
                    '*integer*2');
            else
                Extended.piece_coord_x(ext_section) = NaN;
                Extended.piece_coord_y(ext_section) = NaN;
                Extended.piece_coord_z(ext_section) = NaN;
            end
            if bitand(MRC.nreal, 4)
                Extended.stage_coord_x(ext_section) = fread(fid, 1, ...
                    '*integer*2');

                Extended.stage_coord_y(ext_section) = fread(fid, 1, ...
                    '*integer*2');
            else
                Extended.stage_coord_x(ext_section) = NaN;
                Extended.stage_coord_y(ext_section) = NaN;
            end
            if bitand(MRC.nreal, 8)
                Extended.magnification(ext_section) = fread(fid, 1, ...
                    '*integer*2');
            else
                Extended.magnification(ext_section) = NaN;
            end
            if bitand(MRC.nreal, 16)
                Extended.intensity(ext_section) = fread(fid, 1, '*integer*2');
            else
                Extended.intensity(ext_section) = NaN;
            end
            if bitand(MRC.nreal, 32)
                Extended.dose_short1(ext_section) = fread(fid, 1, '*integer*2');
                Extended.dose_short2(ext_section) = fread(fid, 1, '*integer*2');
            else
                Extended.dose_short1(ext_section) = NaN;
                Extended.dose_short2(ext_section) = NaN;
            end
        end
    else
        Extended.a_tilt(1) = NaN;
        Extended.piece_coord_x(1) = NaN;
        Extended.piece_coord_y(1) = NaN;
        Extended.piece_coord_z(1) = NaN;
        Extended.stage_coord_x(1) = NaN;
        Extended.stage_coord_y(1) = NaN;
        Extended.magnification(1) = NaN;
        Extended.intensity(1) = NaN;
        Extended.dose_short1(1) = NaN;
        Extended.dose_short2(1) = NaN;
    end

    for i = 1:MRC.nz
        % mode 0 is weird and should always be signed but IMOD thinks
        % otherwise...
        if MRC.mode == 0 && bitand(MRC.imodflags, 1)
            Data_read(:, :, i) = fread(fid, [MRC.nx, MRC.ny], '*int8');
        elseif MRC.mode == 0
            Data_read(:, :, i) = fread(fid, [MRC.nx, MRC.ny], '*uint8');
        elseif MRC.mode == 1
            Data_read(:, :, i) = fread(fid, [MRC.nx, MRC.ny], '*integer*2');
        elseif MRC.mode == 2
            Data_read(:, :, i) = fread(fid, [MRC.nx, MRC.ny], '*real*4');
        elseif MRC.mode == 6
            Data_read(:, :, i) = fread(fid, [MRC.nx, MRC.ny], '*uint16');
        else
            error(['Sorry, i cannot read this as an MRC-File !!!']);
            Data_read=[];
        end
    end

    fclose(fid);
    Header=struct(...
        'Extended', Extended, ...
        'Filename', input_fn, ...
        'MRC', MRC);

    Data=struct('Value',Data_read,'Header',Header);
end

%##############################################################################%
%                                    IS_SEM                                    %
%##############################################################################%
function is_SEM_ans = is_SEM(nint, nreal)
% IS_SEM checks whether file has SerialEM extended header.
%     IS_SEM(
%         NINT,
%         NREAL)
%
%     A small function to check whether the file has the SerialEM extended
%     Header, which is done by making sure that the binary flags in NREAL add up
%     appropriately to the value in NINT.
%
% Example:
%     IS_SEM(0, 0)

    checksum = 0;
    if bitand(nreal, 1)
        checksum = checksum + 2;
    end
    if bitand(nreal, 2)
        checksum = checksum + 6;
    end
    if bitand(nreal, 4)
        checksum = checksum + 4;
    end
    if bitand(nreal, 8)
        checksum = checksum + 2;
    end
    if bitand(nreal, 16)
        checksum = checksum + 2;
    end
    if bitand(nreal, 32)
        checksum = checksum + 4;
    end
    is_SEM_ans = checksum == nint;
end

%##############################################################################%
%                             WRITE_SERIALEM_MRC                               %
%##############################################################################%
function write_serialEM_MRC(output_fn, input_data)
% WRITE_SERIALEM_MRC Writes data to MRC file with correct extended header.
%     WRITE_SERIALEM_MRC(
%         OUTPUT_FN,
%         INPUT_DATA)
%
%     Writes INPUT_DATA in a MRC format with the name OUTPUT_FN.
%
% Example:
%     WRITE_SERIALEM_MRC('TS_01_dose_filt.st', input_ts);
%
% See also READ_SERIALEM_MRC TOM_EMWRITE
%
% Copyright (c) 2005
% TOM toolbox for Electron Tomography
% Max-Planck-Institute for Biochemistry
% Dept. Molecular Structural Biology
% 82152 Martinsried, Germany
% http://www.biochem.mpg.de/tom
%
% Created: 09/25/02 SN
% Last modified: 04/05/17 DRM

    [comp_typ, maxsize, endian] = computer;
    switch endian
        case 'L'
            system_format = 'ieee-le';
        case 'B'
            system_format = 'ieee-be';
    end

    fid = fopen(output_fn, 'wb', system_format);
    if fid == -1
        error(['Cannot open: ', output_fn, ' file']);
    end

    MRC.nx = int32(size(input_data.Value, 1));
    MRC.ny = int32(size(input_data.Value, 2));
    if size(input_data.Value) > 2
        MRC.nz = int32(size(input_data.Value, 3));
    else
        MRC.nz = 1;
    end
    fwrite(fid, MRC.nx, 'integer*4');
    fwrite(fid, MRC.ny, 'integer*4');
    fwrite(fid, MRC.nz, 'integer*4');

    if isa(input_data.Value, 'int8') | isa(input_data.Value, 'uint8')
        MRC.mode = 0;
    elseif isa(input_data.Value, 'int16')
        MRC.mode = 1;
    elseif isa(input_data.Value, 'double') | isa(input_data.Value, 'single')
        MRC.mode = 2;
    elseif isa(input_data.Value, 'uint16')
        MRC.mode = 6;
    end
    fwrite(fid, MRC.mode, 'integer*4');

    MRC.nxstart = int32(0);
    MRC.nystart = int32(0);
    MRC.nzstart = int32(0);
    fwrite(fid, MRC.nxstart, 'integer*4');
    fwrite(fid, MRC.nystart, 'integer*4');
    fwrite(fid, MRC.nzstart, 'integer*4');

    MRC.mx = MRC.nx;
    MRC.my = MRC.ny;
    MRC.mz = MRC.nz;
    fwrite(fid, MRC.mx, 'integer*4');
    fwrite(fid, MRC.my, 'integer*4');
    fwrite(fid, MRC.mz, 'integer*4');

    % pixel size is [xyz]len / m[xyz] so we get it from the old MRC
    original_xapix = input_data.Header.MRC.xlen / ...
        double(input_data.Header.MRC.mx);

    original_yapix = input_data.Header.MRC.ylen / ...
        double(input_data.Header.MRC.my);

    original_zapix = input_data.Header.MRC.zlen / ...
        double(input_data.Header.MRC.mz);

    % We can now set the [xyz]len correctly as [xyz]len = [xyz]apix * m[xyz]
    MRC.xlen = original_xapix * double(MRC.mx);
    MRC.ylen = original_yapix * double(MRC.my);
    MRC.zlen = original_zapix * double(MRC.mz);
    fwrite(fid, MRC.xlen, 'real*4');
    fwrite(fid, MRC.ylen, 'real*4');
    fwrite(fid, MRC.zlen, 'real*4');

    % Since cell angles aren't generally used we just fall back to what SEM set
    MRC.alpha = single(input_data.Header.MRC.alpha);
    MRC.beta = single(input_data.Header.MRC.beta);
    MRC.gamma = single(input_data.Header.MRC.gamma);
    fwrite(fid, MRC.alpha, 'real*4');
    fwrite(fid, MRC.beta, 'real*4');
    fwrite(fid, MRC.gamma, 'real*4');

    % In EM MRC data these are always 1, 2, 3 respectively, in CCPEM they can
    % differ
    MRC.mapc = int32(1);
    MRC.mapr = int32(2);
    MRC.maps = int32(3);
    fwrite(fid, MRC.mapc, 'integer*4');
    fwrite(fid, MRC.mapr, 'integer*4');
    fwrite(fid, MRC.maps, 'integer*4');

    % We should have a faster version that supports the 2014 standards while
    % skipping setting these values since it's a bit slow.
    MRC.amin = single(min(min(min(input_data.Value))));
    MRC.amax = single(max(max(max(input_data.Value))));
    MRC.amean = single(mean(mean(mean(input_data.Value))));
    fwrite(fid, MRC.amin, 'real*4');
    fwrite(fid, MRC.amax, 'real*4');
    fwrite(fid, MRC.amean, 'real*4');

    % This should be 0 for images and 1 for volume but we will just take from
    % SerialEM
    MRC.ispg = int32(input_data.Header.MRC.ispg);
    fwrite(fid, MRC.ispg, 'integer*4');

    % We are going to copy the entire extended header, this could be a bad idea
    % if someone does some funny things with reordering or removing stacks from
    % input_data.Value, but for now I want to transfer as much as possible.
    MRC.next = int32(input_data.Header.MRC.next);
    fwrite(fid, MRC.next, 'integer*4');

    % Should always be 0 now.
    MRC.creatid = int16(0);
    fwrite(fid, MRC.creatid, 'integer*2');

    % We can just zero out the first empty field just in case
    MRC.extra_data1 = int8(zeros([6, 1]));
    fwrite(fid, MRC.extra_data1, 'integer*1');

    % Make sure that this is a valid 2014MRC file with exttype SERI
    MRC.exttype = 'SERI';
    fwrite(fid, MRC.exttype, 'char');

    % We are writing a valid 2014 MRC format file so the nversion should be
    % 20140
    MRC.nversion = int32(20140);
    fwrite(fid, MRC.nversion, 'integer*4');

    % Again we just zero out the second empty field
    MRC.extra_data2 = int8(zeros([16, 1]));
    fwrite(fid, MRC.extra_data2, 'integer*1');

    % In copying the entire extended header, we also have to keep nint and nreal
    MRC.nint = int16(input_data.Header.MRC.nint);
    MRC.nreal = int16(input_data.Header.MRC.nreal);
    fwrite(fid, MRC.nint, 'integer*2');
    fwrite(fid, MRC.nreal, 'integer*2');

    % zeroed out
    MRC.extra_data3 = int8(zeros([20, 1]));
    fwrite(fid, MRC.extra_data3, 'integer*1');

    % We preserve the imodstamp and the imodflags since the data is generally
    % preserved in terms of what the flags describe.
    MRC.imodstamp = int32(1146047817);
    MRC.imodflags = int32(input_data.Header.MRC.imodflags);
    fwrite(fid, MRC.imodstamp, 'integer*4');
    fwrite(fid, MRC.imodflags, 'integer*4');

    % We just copy the next six shorts from the original header because I don't
    % think they are actively used fields in EM and most are just constant
    % across all produced MRC files from SEM and IMOD
    MRC.idtype = int16(input_data.Header.MRC.idtype);
    MRC.lens = int16(input_data.Header.MRC.lens);
    MRC.nd1 = int16(input_data.Header.MRC.nd1);
    MRC.nd2 = int16(input_data.Header.MRC.nd2);
    MRC.vd1 = int16(input_data.Header.MRC.vd1);
    MRC.vd2 = int16(input_data.Header.MRC.vd2);
    fwrite(fid, MRC.idtype, 'integer*2');
    fwrite(fid, MRC.lens, 'integer*2');
    fwrite(fid, MRC.nd1, 'integer*2');
    fwrite(fid, MRC.nd2, 'integer*2');
    fwrite(fid, MRC.vd1, 'integer*2');
    fwrite(fid, MRC.vd2, 'integer*2');

    % Copy tiltangles here from the orignal, these are not the tomography
    % tilt-angles and again don't seem to be used, often they are just zeroed
    % out, but for now we just copy over.
    MRC.tiltangles = single(input_data.Header.MRC.tiltangles);
    fwrite(fid, MRC.tiltangles, 'real*4');

    % Doing the same thing for origin as tiltangles above, but these may
    % actually be used in PEET and in that case we maybe should calculate them
    % out for cases when the data has been cropped etc.
    MRC.xorg = single(input_data.Header.MRC.xorg);
    MRC.yorg = single(input_data.Header.MRC.yorg);
    MRC.zorg = single(input_data.Header.MRC.zorg);
    fwrite(fid, MRC.xorg, 'real*4');
    fwrite(fid, MRC.yorg, 'real*4');
    fwrite(fid, MRC.zorg, 'real*4');

    % Holds the string 'MAP '
    MRC.cmap = 'MAP ';
    fwrite(fid, MRC.cmap, 'char');

    % Here since we allow different endian formats we need to handle the stamp
    % here which is 17 17 for the first two bytes in BE and 68 65 for LE
    switch(system_format)
        case 'ieee-le'
            MRC.stamp = char([68 65 0 0]);
        case 'ieee-be'
            MRC.stamp = char([17 17 0 0]);
    end
    fwrite(fid, MRC.stamp, 'char');

    % With the 2014MRC format we can set a negative number to show we did not
    % calculate the RMS, and this is also detailed in the imodflags as well.  We
    % can't even calculate the RMS in Matlab without the dsp package or writing
    % the function ourselves.
    MRC.rms = single(-1);
    fwrite(fid, MRC.rms, 'real*4');

    % Labels are kind of tricky: Firstly we should leave tracks of our
    % modification in case we are doing something bad or wrong.  Secondly, we
    % have to add this as the last label, but if there are already 10 labels
    % then we have to push off the 3rd label (because the 1st two hold important
    % SerialEM information) and slide the labels up from there.
    label_date = datestr(now, 'dd.mm.yy-HH:MM');
    new_label = pad(['TOM_MRCWRITESEM: ' label_date], 80);

    if input_data.Header.MRC.nlabl < 10
        MRC.nlabl = int32(input_data.Header.MRC.nlabl + 1);
        fwrite(fid, MRC.nlabl, 'integer*4');
        for labl_idx = 1:10
            if labl_idx <= input_data.Header.MRC.nlabl
                MRC.labels(labl_idx, :) = input_data.Header.MRC.labels(...
                    labl_idx, :);
            elseif labl_idx == input_data.Header.MRC.nlabl + 1
                MRC.labels(labl_idx, :) = new_label;
            else
                MRC.labels(labl_idx, :) = pad('', 80);
            end
            fwrite(fid, MRC.labels(labl_idx, :), 'char');
        end
    elseif input_data.Header.MRC.nlabl == 10
        MRC.nlabl = int32(10);
        fwrite(fid, MRC.nlabl, 'integer*4');
        for labl_idx = 1:10
            if labl_idx < 3
                % Preserve the first two header labels
                MRC.labels(labl_idx, :) = input_data.Header.MRC.labels(...
                    labl_idx, :);
            elseif labl_idx < 10
                % Slide up labels 4 - 10 and remove label 3
                MRC.labels(labl_idx, :) = input_data.Header.MRC.labels(...
                    labl_idx + 1, :);
            else
                MRC.labels(labl_idx, :) = new_label;
            end
            fwrite(fid, MRC.labels(labl_idx, :), 'char');
        end
    end

    % We aren't going to touch the extended header just write it out.
    if MRC.next ~= 0
        number_of_sections = int32(MRC.next) / int32(MRC.nint);
        for ext_section=1:number_of_sections
            if bitand(MRC.nreal, 1)
                fwrite(fid, ...
                    input_data.Header.Extended.a_tilt(ext_section), ...
                    '*integer*2');
            end
            if bitand(MRC.nreal, 2)
                fwrite(fid, ...
                    input_data.Header.Extended.coord_x(ext_section), ...
                    '*integer*2');

                fwrite(fid, ...
                    input_data.Header.Extended.coord_y(ext_section), ...
                    '*integer*2');

                fwrite(fid, ...
                    input_data.Header.Extended.coord_z(ext_section), ...
                    '*integer*2');
            end
            if bitand(MRC.nreal, 4)
                fwrite(fid, ...
                    input_data.Header.Extended.stage_coord_x(ext_section), ...
                    '*integer*2');

                fwrite(fid, ...
                    input_data.Header.Extended.stage_coord_y(ext_section), ...
                    '*integer*2');
            end
            if bitand(MRC.nreal, 8)
                fwrite(fid, ...
                    input_data.Header.Extended.magnification(ext_section), ...
                    '*integer*2');
            end
            if bitand(MRC.nreal, 16)
                fwrite(fid, ...
                    input_data.Header.Extended.intensity(ext_section), ...
                    '*integer*2');
            end
            if bitand(MRC.nreal, 32)
                fwrite(fid, ...
                    input_data.Header.Extended.dose_short1(ext_section), ...
                    '*integer*2');

                fwrite(fid, ...
                    input_data.Header.Extended.dose_short2(ext_section), ...
                    '*integer*2');
            end
        end
    end

    % Finally we write out the data
    for section_idx = 1:(MRC.nz)
        if MRC.mode == 0 && bitand(MRC.imodflags, 1)
            fwrite(fid, ...
                input_data.Value(1:(MRC.nx), 1:(MRC.ny), section_idx), ...
                'int8');
        elseif MRC.mode == 0
            fwrite(fid, ...
                input_data.Value(1:(MRC.nx), 1:(MRC.ny), section_idx), ...
                'uint8');
        elseif MRC.mode == 1
            fwrite(fid, ...
                input_data.Value(1:(MRC.nx), 1:(MRC.ny), section_idx), ...
                'int16');
        elseif MRC.mode == 2
            fwrite(fid, ...
                input_data.Value(1:(MRC.nx), 1:(MRC.ny), section_idx), ...
                'real*4');
        elseif MRC.mode == 6
            fwrite(fid, ...
                input_data.Value(1:(MRC.nx), 1:(MRC.ny), section_idx), ...
                'uint16');
        end
    end

    % Update the MRC structure to represent the new header.
    input_data.Header.MRC = MRC;
    fclose(fid);
end

%##############################################################################%
%                            DOSE_FILTER_TILT_IMAGE                            %
%##############################################################################%
function [filtered_tilt_image] = dose_filter_tilt_image(input_ts, tilt_idx,...
    start_x, end_x, start_y, end_y, dose, freq_array)
% DOSE_FILTER_TILT_IMAGE applies dose-filter to a single tilt image.
%     DOSE_FILTER_TILT_IMAGE(
%         INPUT_TS,
%         TILT_IDX,
%         START_X,
%         END_X,
%         START_Y,
%         END_Y,
%         DOSE,
%         FREQ_ARRAY)
%
%     A function to filter the information of a frame stack in Fourier space.
%     This filter is simply the attenuation filter from the Grant and
%     Grigorieff 2.6A rotavirus paper. The re-weighting is not applied here,
%     with the assumption that the r-weighting in the tomographic back
%     projection will be sufficent.
%
%     Takes the data in a tilt-series and applies a hard-coded
%     resolution-dependent critical exposure lowpass filter, using the parameter
%     from the fitted numbers in the Grant and Grigorieff 2015 eLife pape.
%
% Example:
%     DOSE_FILTER_TILT_IMAGE(input_ts, 1, start_x, end_x, start_y, end_y, ...
%         2.4, freq_array);

    a = 0.245;
    b = -1.665;
    c = 2.81;

    % Calculate Fourier transform
    tilt_image = double(input_ts.Value(start_x:end_x,...
                                               start_y:end_y,...
                                               tilt_idx));
    tilt_image_fft = fftshift(fft2(tilt_image));

    % Calculate exposure-dependent amplitude attenuator
    dose_filter = exp((-dose) ./ (2 .* ((a .* (freq_array.^b)) + c)));

    % Attenuate and inverse transform
    filtered_tilt_image = ifft2(ifftshift(tilt_image_fft .* dose_filter));
end
