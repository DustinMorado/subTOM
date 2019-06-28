function output_vol = subtom_subtract_mean_under_mask(input_vol, mask)
% SUBTOM_SUBTRACT_MEAN_UNDER_MASK subtract mean of volume under a mask.
%     SUBTOM_SUBTRACT_MEAN_UNDER_MASK(
%         INPUT_VOL,
%         MASK)
%
%     Calculates the average of INPUT_VOL only considering non-zero voxels in
%     MASK and then subtracts that mean value from all voxels in INPUT_VOL and
%     returns the adjusted volume.
%
% Example:
%     subtom_subtract_mean_under_mask(ptcl, rot_shift_align_mask);

    % Find the number of voxels in the mask.
    num_mask_vox = sum(sum(sum(mask > 1e-6)));

    % Mean under the mask
    masked_mean = sum(sum(sum(input_vol .* mask))) / num_mask_vox;
    output_vol = input_vol - (mask .* masked_mean);
end
