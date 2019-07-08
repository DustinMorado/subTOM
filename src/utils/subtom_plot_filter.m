function subtom_plot_filter(varargin)
% SUBTOM_PLOT_FILTER creates a graphic of bandpass filters optionally with CTF.
%
%     SUBTOM_PLOT_FILTER(
%         'box_size', BOX_SIZE,
%         'pixelsize', PIXELSIZE,
%         'high_pass_fp', HIGH_PASS_FP,
%         'high_pass_sigma', HIGH_PASS_SIGMA,
%         'low_pass_fp', LOW_PASS_FP,
%         'low_pass_sigma', LOW_PASS_SIGMA,
%         'defocus', DEFOCUS,
%         'voltage', VOLTAGE,
%         'cs', CS,
%         'ac', AC,
%         'phase_shift', PHASE_SHIFT,
%         'b_factor', B_FACTOR,
%         'output_fn_prefix', OUTPUT_FN_PREFIX)
%
%     Takes in the local alignment filter parameters used in subTOM
%     HIGH_PASS_FP, HIGH_PASS_SIGMA, LOW_PASS_FP, and LOW_PASS_SIGMA; then
%     produces a figure showing the filter that will be applied to the Fourier
%     transform of the reference during alignment. The Fourier pixel frequencies
%     are converted into Angstroms using the given BOX_SIZE and PIXELSIZE. A
%     single CTF can also be specified with DEFOCUS, VOLTAGE, CS, AC,
%     PHASE_SHIFT, and the root square of this curve will be plotted in addition
%     to how the band-pass filter affects the amplitude effects of the CTF.
%     Finally a B-factor falloff can also be specified with B_FACTOR, and this
%     decay curve will also be plotted and also plotted with the CTF root
%     square, and also the CTF root square and band-pass filter all together, so
%     a cumulative effect of a specific choice of filter parameters at a given
%     defocus and falloff can be observed. If OUTPUT_FN_PREFIX is not empty it
%     is used to save the graphic in MATLAB figure, pdf, and png formatted
%     files.

% DRM 05-2019
%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'box_size', '');
    addParameter(fn_parser, 'pixelsize', 1);
    addParameter(fn_parser, 'high_pass_fp', 0);
    addParameter(fn_parser, 'high_pass_sigma', 0);
    addParameter(fn_parser, 'low_pass_fp', 0);
    addParameter(fn_parser, 'low_pass_sigma', 0);
    addParameter(fn_parser, 'defocus', 0);
    addParameter(fn_parser, 'voltage', 300);
    addParameter(fn_parser, 'cs', 0.0);
    addParameter(fn_parser, 'ac', 1.0);
    addParameter(fn_parser, 'phase_shift', 0.0);
    addParameter(fn_parser, 'b_factor', 0.0);
    addParameter(fn_parser, 'output_fn_prefix', '');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    box_size = fn_parser.Results.box_size;

    if isempty(box_size)
        try
            error('subTOM:missingRequired', ...
                'plot_filter:Parameter %s is required.', ...
                'box_size');
        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    if ischar(box_size)
        box_size = str2double(box_size);
    end

    try
        validateattributes(box_size, {'numeric'}, ...
            {'scalar', 'nonnan', 'positive', 'integer'}, ...
            'subtom_plot_filter', 'box_size');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    pixelsize = fn_parser.Results.pixelsize;

    if isempty(pixelsize)
        pixelsize = 1;
    end

    if ischar(pixelsize)
        pixelsize = str2double(pixelsize);
    end

    try
        validateattributes(pixelsize, {'numeric'}, ...
            {'scalar', 'nonnan', 'positive'}, ...
            'subtom_plot_filter', 'pixelsize');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    high_pass_fp = fn_parser.Results.high_pass_fp;

    if isempty(high_pass_fp)
        high_pass_fp = 0;
    end

    if ischar(high_pass_fp)
        high_pass_fp = str2double(high_pass_fp);
    end

    try
        validateattributes(high_pass_fp, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_plot_filter', 'high_pass_fp');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    high_pass_sigma = fn_parser.Results.high_pass_sigma;

    if isempty(high_pass_sigma)
        high_pass_sigma = 0;
    end

    if ischar(high_pass_sigma)
        high_pass_sigma = str2double(high_pass_sigma);
    end

    try
        validateattributes(high_pass_sigma, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_plot_filter', 'high_pass_sigma');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    low_pass_fp = fn_parser.Results.low_pass_fp;

    if isempty(low_pass_fp)
        low_pass_fp = 0;
    end

    if ischar(low_pass_fp)
        low_pass_fp = str2double(low_pass_fp);
    end

    try
        validateattributes(low_pass_fp, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_plot_filter', 'low_pass_fp');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    low_pass_sigma = fn_parser.Results.low_pass_sigma;

    if isempty(low_pass_sigma)
        low_pass_sigma = 0;
    end

    if ischar(low_pass_sigma)
        low_pass_sigma = str2double(low_pass_sigma);
    end

    try
        validateattributes(low_pass_sigma, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_plot_filter', 'low_pass_sigma');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    defocus = fn_parser.Results.defocus;

    if isempty(defocus)
        defocus = 0;
    end

    if ischar(defocus)
        defocus = str2double(defocus);
    end

    try
        validateattributes(defocus, {'numeric'}, ...
            {'scalar', 'nonnan'}, ...
            'subtom_plot_filter', 'defocus');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    voltage = fn_parser.Results.voltage;

    if isempty(voltage)
        voltage = 300;
    end

    if ischar(voltage)
        voltage = str2double(voltage);
    end

    try
        validateattributes(voltage, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_plot_filter', 'voltage');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    cs = fn_parser.Results.cs;

    if isempty(cs)
        cs = 0;
    end

    if ischar(cs)
        cs = str2double(cs);
    end

    try
        validateattributes(cs, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative'}, ...
            'subtom_plot_filter', 'cs');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    ac = fn_parser.Results.ac;

    if isempty(ac)
        ac = 1;
    end

    if ischar(ac)
        ac = str2double(ac);
    end

    try
        validateattributes(ac, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative', '<', 1.01}, ...
            'subtom_plot_filter', 'ac');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    phase_shift = fn_parser.Results.phase_shift;

    if isempty(phase_shift)
        phase_shift = 0;
    end

    if ischar(phase_shift)
        phase_shift = str2double(phase_shift);
    end

    try
        validateattributes(phase_shift, {'numeric'}, ...
            {'scalar', 'nonnan', 'nonnegative', '<', 360}, ...
            'subtom_plot_filter', 'phase_shift');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    b_factor = fn_parser.Results.b_factor;

    if isempty(b_factor)
        b_factor = 0;
    end

    if ischar(b_factor)
        b_factor = str2double(b_factor);
    end

    try
        validateattributes(b_factor, {'numeric'}, ...
            {'scalar', 'nonnan', '<=', 0}, ...
            'subtom_plot_filter', 'b_factor');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    output_fn_prefix = fn_parser.Results.output_fn_prefix;

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Create Frequency Array
    frequency_array = [0:floor(box_size / 2)] ./ (box_size * pixelsize);

    % Interpolate the frequency array to improve how the plot looks.
    frequency_array_ = linspace(0, ...
        floor(box_size / 2) / (box_size * pixelsize), 1000);

    % Calculate band-pass mask
    if low_pass_fp > 0
        low_pass_mask = tom_spheremask(ones(box_size, box_size, box_size), ...
            low_pass_fp, low_pass_sigma);

    else
        low_pass_mask = ones(box_size, box_size, box_size);
    end

    if high_pass_fp > 0
        high_pass_mask = tom_spheremask(ones(box_size, box_size, box_size), ...
            high_pass_fp, high_pass_sigma);

    else
        high_pass_mask = zeros(box_size, box_size, box_size);
    end

    band_pass_mask = low_pass_mask - high_pass_mask;

    % Define the center of the volume.
    center = floor(box_size / 2) + 1;

    % Get the 1D filter from the band-pass mask. The 2nd dimension holds
    % row-vectors and we need to flip it from left to right.
    filter_1D = fliplr(band_pass_mask(center, 1:center, center));

    % Interpolate the filter to improve how the plot looks.
    filter_1D_ = interp1(frequency_array, filter_1D, frequency_array_);

    % Calculate the CTF
    ctf = subtom_ctf_1D(box_size, -defocus, pixelsize, voltage, cs, ac, ...
        phase_shift);

    % We care about how the CTF is modulating the amplitude so we do the root
    % square of the CTF.
    ctf_root_square = sqrt(ctf.^2);

    % Calculate the B-Factor falloff
    falloff = exp(b_factor .* frequency_array_ ./ 4);
    
    % Do the plotting.
    filter_fig = figure();
    filter_axes = axes(filter_fig);
    filter_xticks = [0:3:floor(box_size / 2)] ./ (box_size * pixelsize);
    filter_resolutions = 1 ./ filter_xticks;
    filter_xlabels = arrayfun(@(x) sprintf('%6.2f', x), filter_resolutions, ...
        'UniformOutput', 0);

    line_1 = plot(filter_axes, frequency_array_, filter_1D_, ...
        'DisplayName', 'Bandpass Filter');

    hold(filter_axes, 'on');
    line_1.Visible = 'off';

    line_2 = plot(filter_axes, frequency_array_, ctf_root_square, ...
        'DisplayName', 'CTF Root Square');

    line_2.Visible = 'off';

    line_3 = plot(filter_axes, frequency_array_, falloff, ...
        'DisplayName', 'B-Factor Falloff');

    line_3.Visible = 'off';

    line_4 = plot(filter_axes, frequency_array_, ctf_root_square .* falloff, ...
        'DisplayName', 'CTF Root Square w/ Falloff');

    line_4.Visible = 'off';

    line_5 = plot(filter_axes, frequency_array_, ...
        filter_1D_ .* ctf_root_square .* falloff, ...
        'DisplayName', 'Cumulative Filter');

    if isempty(output_fn_prefix)
        title(filter_axes, sprintf('Filter Function'));
    else
        [~, output_fn_base, ~] = fileparts(output_fn_prefix);
        title(filter_axes, sprintf('Filter Function %s', output_fn_base));
    end

    ylabel(filter_axes, 'Fourier Amplitude [arb. unit]');
    xlabel(filter_axes, sprintf('Resolution [\x212B]'));
    xticks(filter_axes, filter_xticks);
    xticklabels(filter_axes, filter_xlabels);
    filter_axes.XTickLabelRotation = 45;
    grid(filter_axes, 'on');
    legend(filter_axes, 'Location', 'eastoutside', 'Orientation', 'vertical');
    legend('boxoff');

    if ~isempty(output_fn_prefix)
        set(filter_fig, 'PaperPositionMode', 'auto');
        set(filter_fig, 'Position', [0, 0, 800, 600]);
        saveas(filter_fig, sprintf('%s_filter', output_fn_prefix), 'fig');
        saveas(filter_fig, sprintf('%s_filter', output_fn_prefix), 'pdf');
        saveas(filter_fig, sprintf('%s_filter', output_fn_prefix), 'png');
    end
end

function ctf = subtom_ctf_1D(box_size, DF1, apix, voltage, cs, ac, phase_shift)

    % Create Frequency Array
    frequency_array = linspace(0, floor(box_size / 2) / (box_size * apix), ...
        1000);

    % The CTF largely needs the square of the Frequency Array
    freq2 = frequency_array.^2;

    cs_      = cs * 1e7;
    voltage_ = voltage * 1e3;
    phase_shift_ = deg2rad(phase_shift);
    % lambda =  h / sqrt(2 * m_0 * e * V)
    % relativistic effects = 1 / sqrt(1 + (e * V / (2 * m_0 * c^2)))
    % h - Planck's Constant - 6.626068E-34 m^2 * kg / s
    % m - Electron Mass     - 9.10938356E−31 kg
    % e - Electron Charge   - −1.6021766208E−19 A * s
    h        = 6.626068E-34;
    c        = 299792458;
    e_mass   = 9.10938356E-31;
    e_charge = 1.6021766208E-19;

    relativism = 1 / sqrt(1 + (e_charge * voltage_ / (2 * e_mass * c^2)));
    lambda = (h / sqrt(2 * e_charge * e_mass * voltage_)) * relativism * 1e10;
    ac_shift = atan2(ac, sqrt(1 - ac^2));
    ctf = -sin((lambda * pi .* freq2) ...
        .* (DF1 - (0.5 * lambda^2 * cs_ .* freq2)) ...
        + ac_shift + phase_shift_);

end
