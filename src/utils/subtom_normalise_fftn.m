function output_vol = subtom_normalise_fftn(input_vol)
% SUBTOM_NORMALISE_FFTN normalise an unshifted Fourier volume.
%     SUBTOM_NORMALISE_FFTN(
%         INPUT_VOL)
%
%     Sets the DC component of the spectrum of INPUT_VOL to 0 and then divides
%     by the mean amplitude. Note that INPUT_VOL is expected to be unshifted,
%     that is to say that its origin is located at (1, 1, 1). This can be
%     accomplished with ifftshift.
%
% Example:
%     subtom_normalise_fftn(ifftshift(ptcl_fft));

    % Cope the original input volume's Fourier Transform
    output_vol = input_vol;

    % Set the DC-component which represent's the volumes average to 0.
    output_vol(1, 1, 1) = 0;

    % Calculate the magnitude of the volume's Fourier Transform which has to be
    % divided by the number of elements in the array because of the scaling done
    % by MATLAB's fftn function.
    magnitude = sqrt(sum(sum(sum(output_vol .* conj(output_vol))))) / ...
        numel(output_vol);

    % Rescale the output volume's Fourier Transform by the inverse of the
    % magnitude.
    output_vol = output_vol ./ magnitude;
end
