function [Data] = subtom_readmrcheader(input_fn)
% SUBTOM_READMRCHEADER tom_readmrcheader alternative to read MRC header
%     SUBTOM_READMRCHEADER(
%         input_fn)
%
%     An alternative to the tom_readmrcheader, where a strange change in
%     an undefined size for 'char' led to issues with R2020B. This
%     version fixes those issues, It also just reads the default 1024
%     byte header.
%
% Example:
%     SUBTOM_READMRCHEADER('input.mrc');
%
% See also SUBTOM_WINDOW

% DRM 2021.03.24 - Original docstring below
%
%TOM_READMRCHAEDER reads the header information of an MRC-file
%
%   [Data] = tom_readmrcheader(varargin)
%
%   out=tom_readmrcheader
%   out=tom_readmrcheader('source_file','le')
%
%PARAMETERS
%
%  INPUT
%   'source_file'       ...
%   le                  ...
%
%  OUTPUT
%   out                 ...
%
%EXAMPLE
%   i=tom_readmrcheader;
%   A fileselect-box appears and the MRC-file can be picked.
%   Open the file for little-endian only (PC format)
%
%   i=tom_readmrcheader('c:\test\mrs_001.mrc','le');
%   Open MRC file mrs_001.mrc in little-endian(PC) format
%
%REFERENCES
%
%SEE ALSO
%   TOM_MRCREAD, TOM_MRC2EM, TOM_ISMRCFILE, TOM_READEMHEADER
%
%   created by SN 09/25/02
%   updated by WDN 05/23/05
%
%   Nickell et al.,
%'TOM software toolbox: acquisition and analysis for electron tomography',
%   Journal of Structural Biology, 149 (2005), 227-234.
%
%   Copyright (c) 2004-2007
%   TOM toolbox for Electron Tomography
%   Max-Planck-Institute of Biochemistry
%   Dept. Molecular Structural Biology
%   82152 Martinsried, Germany
%   http://www.biochem.mpg.de/tom

    % Determine the system type.
    [str, maxsize, endian] = computer;

    switch endian
        case 'L'
            machinefmt = 'ieee-le';
        case 'B'
            machinefmt = 'ieee-be';
    end

    if exist(input_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'readmrcheader:File %s does not exist.', input_fn);
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    % MATLAB assumes UTF-8 for the encoding I think this is part
    % of the issue perhaps the files are ASCII encoded but IDK.
    fid = fopen(input_fn, 'r', machinefmt, 'UTF-8');

    MRC.nx = fread(fid, 1, 'int32=>double', 0, machinefmt);
    MRC.ny = fread(fid, 1, 'int32=>double', 0, machinefmt);
    MRC.nz = fread(fid, 1, 'int32=>double', 0, machinefmt);

    MRC.mode = fread(fid, 1, 'int32=>double', 0, machinefmt);

    MRC.nxstart = fread(fid, 1, 'int32=>double', 0, machinefmt);
    MRC.nystart = fread(fid, 1, 'int32=>double', 0, machinefmt);
    MRC.nzstart = fread(fid, 1, 'int32=>double', 0, machinefmt);

    MRC.mx = fread(fid, 1, 'int32=>double', 0, machinefmt);
    MRC.my = fread(fid, 1, 'int32=>double', 0, machinefmt);
    MRC.mz = fread(fid, 1, 'int32=>double', 0, machinefmt);
    MRC.xlen = fread(fid, 1, 'float32=>double', 0, machinefmt);
    MRC.ylen = fread(fid, 1, 'float32=>double', 0, machinefmt);
    MRC.zlen = fread(fid, 1, 'float32=>double', 0, machinefmt);

    MRC.alpha = fread(fid, 1, 'float32=>double', 0, machinefmt);
    MRC.beta = fread(fid, 1, 'float32=>double', 0, machinefmt);
    MRC.gamma = fread(fid, 1, 'float32=>double', 0, machinefmt);

    MRC.mapc = fread(fid, 1, 'int32=>double', 0, machinefmt);
    MRC.mapr = fread(fid, 1, 'int32=>double', 0, machinefmt);
    MRC.maps = fread(fid, 1, 'int32=>double', 0, machinefmt);

    MRC.amin = fread(fid, 1, 'float32=>double', 0, machinefmt);
    MRC.amax = fread(fid, 1, 'float32=>double', 0, machinefmt);
    MRC.amean = fread(fid, 1, 'float32=>double', 0, machinefmt);

    MRC.ispg = fread(fid, 1, 'int16=>double', 0, machinefmt);
    MRC.nsymbt = fread(fid, 1, 'int16=>double', 0, machinefmt);
    MRC.next = fread(fid, 1, 'int32=>double', 0, machinefmt);
    MRC.creatid = fread(fid, 1, 'int16=>double', 0, machinefmt);

    MRC.unused1 = fread(fid, [1, 30], 'int8=>double', 0, machinefmt);

    MRC.nint = fread(fid, 1, 'int16=>double', 0, machinefmt);
    MRC.nreal = fread(fid, 1, 'int16=>double', 0, machinefmt);

    MRC.unused2 = fread(fid, [1, 28], 'int8=>double', 0, machinefmt);

    MRC.idtype = fread(fid, 1, 'int16=>double', 0, machinefmt);
    MRC.lens = fread(fid, 1, 'int16=>double', 0, machinefmt);

    MRC.nd1 = fread(fid, 1, 'int16=>double', 0, machinefmt);
    MRC.nd2 = fread(fid, 1, 'int16=>double', 0, machinefmt);

    MRC.vd1 = fread(fid, 1, 'int16=>double', 0, machinefmt);
    MRC.vd2 = fread(fid, 1, 'int16=>double', 0, machinefmt);

    MRC.tiltangles = fread(fid, [1, 6], 'float32=>double', 0, machinefmt);

    MRC.xorg = fread(fid, 1, 'float32=>double', 0, machinefmt);
    MRC.yorg = fread(fid, 1, 'float32=>double', 0, machinefmt);
    MRC.zorg = fread(fid, 1, 'float32=>double', 0, machinefmt);

    % Here it is important the 'int8=>char*1' otherwise for some reason
    % MATLAB will buffer the entire file which totally defeats the
    % purpose of just reading the header!?!?.
    MRC.cmap = fread(fid, [1, 4], 'int8=>char*1', 0, machinefmt);
    MRC.stamp = fread(fid, [1, 4], 'int8=>char*1', 0, machinefmt);

    MRC.rms = fread(fid, 1, 'float32=>double', 0, machinefmt);

    MRC.nlabl = fread(fid, 1, 'int32=>double', 0, machinefmt);
    MRC.labl = fread(fid, [80, 10], 'int8=>char*1', 0, machinefmt)';

    fclose(fid);

    Header = struct(...
        'Voltage', 0,...
        'Cs', 0,...
        'Aperture', 0,...
        'Magnification', 0, ...
        'Postmagnification', 0,...
        'Exposuretime', 0, ...
        'Objectpixelsize', 0, ...
        'Microscope', 0,...
        'Pixelsize', 0,...
        'CCDArea', 0,...
        'Defocus', 0, ...
        'Astigmatism', 0,...
        'AstigmatismAngle', 0,...
        'FocusIncrement', 0,...
        'CountsPerElectron', 0,...
        'Intensity', 0,...
        'EnergySlitwidth', 0,...
        'EnergyOffset', 0,...
        'Tiltangle', 0, ...
        'Tiltaxis', 0, ...
        'Username', num2str(zeros(20, 1)),...
        'Date',num2str(zeros(8)),...
        'Size', [MRC.nx, MRC.ny, MRC.nz],...
        'Comment', num2str(zeros(80, 1)),...
        'Parameter', num2str(zeros(40, 1)),...
        'Fillup', num2str(zeros(256, 1)),...
        'Filename', input_fn,...
        'Marker_X', 0,...
        'Marker_Y', 0,...
        'MRC', MRC);

    Data = struct('Header', Header);
end
