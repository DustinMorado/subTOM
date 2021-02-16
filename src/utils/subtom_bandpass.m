function subtom_bandpass(varargin)
% SUBTOM_BANDPASS creates and/or applies a bandpass filter to a volume.
%
%     SUBTOM_BANDPASS(...
%         'input_fn', INPUT_FN,
%         'high_pass_fp', HIGH_PASS_FP,
%         'high_pass_sigma', HIGH_PASS_SIGMA,
%         'low_pass_fp', LOW_PASS_FP,
%         'low_pass_sigma', LOW_PASS_SIGMA,
%         'filter_fn', FILTER_FN,
%         'output_fn', OUTPUT_FN)
%
% Simply creates and/or applies a bandpass filter just as would be done during
% alignment, with the option to write out the Fourier Filter volume as well just
% for visualization purposes. INPUT_FN defines the volume to be filtered, or at
% minimum the box size used to create the filter volume. The Fourier domain
% filter created is dependent on the parameters HIGH_PASS_FP, HIGH_PASS_SIGMA,
% LOW_PASS_FP, LOW_PASS_SIGMA which are all in the units of Fourier pixels. If
% FILTER_FN is a non-empty string then the bandpass filter volume itself is
% written to the filename given. If OUTPUT_FN is a non-empty string then the
% bandpass filtered volume is written to the filename given. 

% DRM 02-2021

%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'input_fn', '');
    addParameter(fn_parser, 'high_pass_fp', 0);
    addParameter(fn_parser, 'high_pass_sigma', 0);
    addParameter(fn_parser, 'low_pass_fp', 0);
    addParameter(fn_parser, 'low_pass_sigma', 0);
    addParameter(fn_parser, 'filter_fn', '');
    addParameter(fn_parser, 'output_fn', '');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    input_fn = fn_parser.Results.input_fn;

    if exist(input_fn, 'file') ~= 2
        try
            error('subTOM:missingFileError', ...
                'bandpass:File %s does not exist.', input_fn);

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    high_pass_fp = fn_parser.Results.high_pass_fp;

    if ischar(high_pass_fp)
        high_pass_fp = str2double(high_pass_fp);
    end

    try
        validateattributes(high_pass_fp, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_bandpass', 'high_pass_fp');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    high_pass_sigma = fn_parser.Results.high_pass_sigma;

    if ischar(high_pass_sigma)
        high_pass_sigma = str2double(high_pass_sigma);
    end

    try
        validateattributes(high_pass_sigma, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_bandpass', 'high_pass_sigma');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    low_pass_fp = fn_parser.Results.low_pass_fp;

    if ischar(low_pass_fp)
        low_pass_fp = str2double(low_pass_fp);
    end

    try
        validateattributes(low_pass_fp, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_bandpass', 'low_pass_fp');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    low_pass_sigma = fn_parser.Results.low_pass_sigma;

    if ischar(low_pass_sigma)
        low_pass_sigma = str2double(low_pass_sigma);
    end

    try
        validateattributes(low_pass_sigma, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_bandpass', 'low_pass_sigma');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    filter_fn = fn_parser.Results.filter_fn;

    if ~isempty(filter_fn)
        fid = fopen(filter_fn, 'w');

        if fid == -1
            try
                error('subTOM:writeFileError', ...
                    'bandpass:File %s cannot be opened for writing', ...
                    filter_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        fclose(fid);
    end

    output_fn = fn_parser.Results.output_fn;

    if ~isempty(output_fn)
        fid = fopen(output_fn, 'w');

        if fid == -1
            try
                error('subTOM:writeFileError', ...
                    'bandpass:File %s cannot be opened for writing', ...
                    output_fn);

            catch ME
                fprintf(2, '%s - %s\n', ME.identifier, ME.message);
                rethrow(ME);
            end
        end

        fclose(fid);
    end

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%
    % Read input to get the initial box size
    input = getfield(tom_emread(input_fn), 'Value');
    box_size = size(input);

    % Calculate band-pass mask
    if low_pass_fp > 0
        low_pass_mask = tom_spheremask(ones(box_size), low_pass_fp, ...
            low_pass_sigma);

    else
        low_pass_mask = ones(box_size);
    end

    if high_pass_fp > 0
        high_pass_mask = tom_spheremask(ones(box_size), high_pass_fp, ...
            high_pass_sigma);

    else
        high_pass_mask = zeros(box_size);
    end

    band_pass_mask = low_pass_mask - high_pass_mask;

    % Write out the filter if requested
    if ~isempty(filter_fn)
        tom_emwrite(filter_fn, band_pass_mask);
        subtom_check_em_file(filter_fn, band_pass_mask);
    end

    % Apply and write out the filter if requested
    if ~isempty(output_fn)
        output = ifftn(subtom_normalise_fftn(ifftshift(...
            fftshift(fftn(input)) .* band_pass_mask)), 'symmetric');

        tom_emwrite(output_fn, output);
        subtom_check_em_file(output_fn, output);
    end
end
