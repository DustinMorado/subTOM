function sharpened_reference = subtom_sharpen(varargin)
% SUBTOM_SHARPEN sharpens a density map.
%
%     SUBTOM_SHARPEN(...
%         'reference', REFERENCE,
%         'b_factor', B_FACTOR,
%         'fsc', FSC,
%         'pixelsize', PIXELSIZE,
%         'filter_mode', FILTER_MODE,
%         'filter_threshold', FILTER_THRESHOLD,
%         'plot_sharpen', PLOT_SHARPEN,
%         'output_fn_prefix', OUTPUT_FN_PREFIX)
%
% See Rosenthal and Henderson, 2003, doi:10.1016/j.jmb.2003.07.013
%
% There are two mode used for low pass filtering. The first uses an FSC
% based threshold (mode 1), i.e. after FSC < 0.143, or a pixel-based
% resolution threhsold (mode 2).

% -WW 06-2015

%##############################################################################%
%                             CREATE INPUT PARSER                              %
%##############################################################################%

    % With the large number of options required and many having sensible
    % defaults we create an input parser to allow for the options to be put in
    % an arbitrary order if at all.
    fn_parser = inputParser;
    addParameter(fn_parser, 'reference', '');
    addParameter(fn_parser, 'b_factor', 0);
    addParameter(fn_parser, 'fsc', NaN);
    addParameter(fn_parser, 'pixelsize', 1.0);
    addParameter(fn_parser, 'filter_mode', 1);
    addParameter(fn_parser, 'filter_threshold', 0.143);
    addParameter(fn_parser, 'plot_sharpen', 0);
    addParameter(fn_parser, 'output_fn_prefix', '');
    parse(fn_parser, varargin{:});

%##############################################################################%
%                                VALIDATE INPUT                                %
%##############################################################################%
    reference = fn_parser.Results.reference;

    try
        validateattributes(reference, {'numeric'}, ...
            {'3d'}, 'subtom_sharpen', 'reference');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    % Get the box size of the reference.
    box_size = size(reference);

    % Number of unique frequencies in the Fourier transform
    n_shells = floor(box_size(1) / 2) + 1;

    b_factor = fn_parser.Results.b_factor;

    if ischar(b_factor)
        b_factor_ = str2double(b_factor);
    end

    try
        validateattributes(b_factor, {'numeric'}, {'nonnan'}, ...
            'subtom_sharpen', 'b_factor');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    if b_factor > 0
        b_factor = b_factor * -1;
    end

    fsc = fn_parser.Results.fsc;

    if isnan(fsc)
        fsc = ones(1, n_shells);
    end

    try
        validateattributes(fsc, {'numeric'}, ...
            {'vector', 'numel', n_shells}, ...
            'subtom_sharpen', 'fsc');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    pixelsize = fn_parser.Results.pixelsize;

    if ischar(pixelsize)
        pixelsize = str2double(pixelsize);
    end

    try
        validateattributes(pixelsize, {'numeric'}, ...
            {'nonnan', 'positive', 'scalar'}, ...
            'subtom_sharpen', 'pixelsize');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    filter_mode = fn_parser.Results.filter_mode;

    if ischar(filter_mode)
        filter_mode = str2double(filter_mode);
    end

    try
        validateattributes(filter_mode, {'numeric'}, ...
            {'scalar', 'nonnan', '>=', 1, '<=', 2}, ...
            'subtom_sharpen', 'filter_mode');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    filter_threshold = fn_parser.Results.filter_threshold;

    if ischar(filter_threshold)
        filter_threshold = str2double(filter_threshold);
    end

    if filter_mode == 1
        try
            validateattributes(filter_threshold, {'numeric'}, ...
                {'nonnan', '>=', 0, '<=', 1, 'scalar'}, ...
                'subtom_sharpen', 'filter_threshold');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    else
        try
            validateattributes(filter_threshold, {'numeric'}, ...
                {'nonnan', 'nonnegative', 'integer', 'scalar'}, ...
                'subtom_sharpen', 'filter_threshold');

        catch ME
            fprintf(2, '%s - %s\n', ME.identifier, ME.message);
            rethrow(ME);
        end
    end

    plot_sharpen = fn_parser.Results.plot_sharpen;

    if ischar(plot_sharpen)
        plot_sharpen = str2double(plot_sharpen);
    end

    try
        validateattributes(plot_sharpen, {'numeric'}, ...
            {'nonnan', 'binary', 'scalar'}, ...
            'subtom_sharpen', 'plot_sharpen');

    catch ME
        fprintf(2, '%s - %s\n', ME.identifier, ME.message);
        rethrow(ME);
    end

    output_fn_prefix = fn_parser.Results.output_fn_prefix;

%##############################################################################%
%                               START PROCESSING                               %
%##############################################################################%

    % Create a raised-cosine low-pass filter to stop the signal beyond the given
    % filter threshold for the given filter mode.
    lowpass = ones(1, n_shells);

    % With filter mode 1 we put the low-pass cutoff centered at where the
    % FSC-curve falls below the value given in filter threshold.
    if filter_mode == 1

        % Find the first two values that fall below the threshold
        cutoff = find(fsc < filter_threshold, 2, 'first');

        % Handle the case when the FSC never falls below the threshold.
        if isempty(cutoff)
            cutoff = n_shells - 4;

        % Handle the weird case when sometimes the very first FSC value is
        % abnormally low and then jumps right back up.
        elseif cutoff(1) <= 1
            cutoff = cutoff(end);

        % Handle the normal case when the FSC behaves normally.
        else
            cutoff = cutoff(1);
        end
    end

    % Determine the values of the raised-cosine low-pass filter, making sure
    % that the cutoff is far enough back to fit and remove a small amount of
    % signal near Nyquist which helps with artifacts from interpolation.
    if (cutoff + 4) >= n_shells
        cutoff_start = n_shells - 4;
        cutoff_end = cutoff_start + 4;
        lowpass(cutoff_start:cutoff_end) = 0.5 - 0.5 .* ...
            cos(pi .* (cutoff_end - (cutoff_start:cutoff_end)) ./ 4);

    else
        cutoff_start = cutoff;
        cutoff_end = cutoff_start + 4;
        lowpass(cutoff_start:cutoff_end) = 0.5 - 0.5 .* ...
            cos(pi .* (cutoff_end - (cutoff_start:cutoff_end)) ./ 4);

        lowpass(cutoff_end + 1:end) = 0;
    end

    % Apply the raised-cosine low-pass filter to the FSC curve.
    fsc_lowpass = fsc .* lowpass;

    % Calculate figure of merit FSC taking into account the improvement in
    % resolution by joining the gold-standard independent halves.
    c_ref = sqrt((2 .* fsc_lowpass) ./ (1 + fsc_lowpass));

    % Convert the 1-D filter to a spherical volume.
    c_ref_vol = subtom_vector_to_volume('input_vector', c_ref);

    % Previously the 1-D filter was determined by linear interpolation, but
    % RELION does it using nearest neighbor which is now what is done above if
    % someone wants the old filter it is here.
    % c_ref_vol = subtom_vector_to_volume('input_vector', c_ref, ...
    %     'method', 'linear');

    % Calculate array of resolutions in the FSC.

    % First determine the cartesian coordinate bounds of the reference
    grid_start = -floor(box_size(1) / 2);
    grid_end = grid_start + box_size(1) - 1;

    % Create a cartesian grid of the X, Y, and Z coordinates of the reference
    [grid_x, grid_y, grid_z] = ndgrid(grid_start:grid_end);

    % Use the above created grid to create an array of the resolutions in the
    % Fourier Transform of the reference.
    resolutions = (box_size(1) * pixelsize) ./ ...
        sqrt(grid_x.^2 + grid_y.^2 + grid_z.^2);

    % Calculate exponential B-Factor filter.
    exp_filter = exp(-(b_factor ./ (4 .* (resolutions.^2))));

    % Get the 1-D version of the exponential filter
    box_center = floor(box_size(1) / 2) + 1;
    exp_curve = fliplr(exp_filter(box_center, 1:n_shells, box_center));

    % Calculate the 1-D signal-weighted sharpening filter.
    sharpen_curve = exp_curve .* c_ref;

    % Calculate the 3-D signal-weighted sharpening filter.
    sharpen_volume = c_ref_vol .* exp_filter;

    % Apply sharpening to the reference.
    sharpened_reference = ifftn(ifftshift(...
        fftshift(fftn(reference)) .* sharpen_volume), 'symmetric');

    % Handle plotting the sharpening function if requested.
    % We can either show the plot and not save it, save the plot but not show it
    % or both show and save the plot.
    if plot_sharpen || ~isempty(output_fn_prefix)

        % Handle the case when we are going to show the plot.
        if plot_sharpen
            sharpen_fig = figure();

        % Handle the case when are going to hide the plot, but save it.
        else
            sharpen_fig = figure('Visible', 'off');
        end

        sharpen_axes = axes(sharpen_fig);
        sharpen_xrange = [0:(n_shells - 1)] ./ (box_size(1) * pixelsize);
        sharpen_xticks = [0:3:(n_shells - 1)] ./ (box_size(1) * pixelsize);
        sharpen_resolutions = 1 ./ sharpen_xticks;
        sharpen_xlabels = arrayfun(@(x) sprintf('%6.2f', x), ...
            sharpen_resolutions, 'UniformOutput', 0);

        plot(sharpen_axes, sharpen_xrange, sharpen_curve, ...
            'DisplayName', 'sharpen');

        hold(sharpen_axes, 'on');
        % plot(sharpen_axes, 1:n_shells, exp_curve, 'DisplayName', 'exp\_filter');
        % plot(sharpen_axes, 1:n_shells, fsc, 'DisplayName', 'FSC');
        % plot(sharpen_axes, 1:n_shells, c_ref, 'DisplayName', 'C\_ref');
        title(sharpen_axes, sprintf('Sharpen Curve - B-Factor : %d', ...
            b_factor));

        ylabel(sharpen_axes, 'Amplitude [arb. unit]');
        xlabel(sharpen_axes, sprintf('Resolution [\x212B]'));
        xticks(sharpen_axes, sharpen_xticks);
        xticklabels(sharpen_axes, sharpen_xlabels);
        sharpen_axes.XTickLabelRotation = 45;
        xlim(sharpen_axes, [sharpen_xrange(1), sharpen_xrange(end)]);
        grid(sharpen_axes, 'on');
        legend(sharpen_axes, 'Location', 'southoutside', ...
            'Orientation', 'horizontal');

        legend('boxoff');
        set(sharpen_fig, 'PaperPositionMode', 'auto');
        set(sharpen_fig, 'Position', [0, 0, 800, 600]);

        if ~isempty(output_fn_prefix)
            output_fn = sprintf('%s_sharp_%d', output_fn_prefix, -b_factor);
            saveas(sharpen_fig, output_fn, 'fig');
            saveas(sharpen_fig, output_fn, 'pdf');
            saveas(sharpen_fig, output_fn, 'png');
        end

        if ~plot_sharpen
            pause(10);
            close(sharpen_fig);
        else
            waitfor(sharpen_fig);
        end
    end
end
