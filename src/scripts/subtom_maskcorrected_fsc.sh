#!/bin/bash
################################################################################
# This is a run script for calculating the mask-corrected FSC curves and joined
# maps outside of the Matlab environment.
#
# This script is meant to run on a local workstation with access to an X server
# in the case when the user wants to display figures. I am unsure if both
# plotting options are disabled if the graphics display is still required, but
# if not it could be run remotely on the cluster, but it shouldn't be necessary.
#
# This script uses just one MATLAB compiled scripts below:
# - subtom_maskcorrected_FSC
#
# DRM 05-2019
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the folder with the input to be processed.
# Other paths are relative to this one.
scratch_dir="${PWD}"

# Absolute path to MCR directory for the processing.
mcr_cache_dir="${scratch_dir}/mcr"

# Directory for executables
exec_dir="XXXINSTALLATION_DIRXXX/bin"

################################################################################
#                                  VARIABLES                                   #
################################################################################
# FSC executable
fsc_exec=${exec_dir}/analysis/subtom_maskcorrected_fsc

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and filename prefix of the first half-map.
ref_a_fn_prefix="even/ref/ref"

# Relative path and filename prefix of the second half-map.
ref_b_fn_prefix="odd/ref/ref"

# The index of the reference to generate : input will be
# ref_{a,b}_fn_prefix_iteration.em (define as integer e.g. iteration=1)
iteration=1

# Relative path and name of the FSC mask.
fsc_mask_fn="FSC/fsc_mask.em"

# Relative path and name of the Fourier filter volume for the first half-map. If
# not using the option do_reweight just leave this set to ""
filter_a_fn=""

# Relative path and name of the Fourier filter volume for the second half-map.
# If not using the option do_reweight just leave this set to ""
filter_b_fn=""

# Relative path and prefix for the name of the output maps and figures.
output_fn_prefix="FSC/ref"

################################################################################
#                                 FSC OPTIONS                                  #
################################################################################
# Pixelsize of the half-maps in Angstroms.
pixelsize=1

# Symmetry to applied the half-maps before calculating FSC (1 is no symmetry).
nfold=1

# The Fourier pixel at which phase-randomization begins is set automatically to
# the point where the unmasked FSC falls below this threshold.
rand_threshold=0.8

# Plot the FSC curves - 1 = yes, 0 = no.
plot_fsc=1

################################################################################
#                              SHARPENING OPTIONS                              #
################################################################################
# Set to 1 to sharpen map or 0 to skip and just calculate the FSC.
do_sharpen=1

# B-Factor to be applied; must be negative or zero.
b_factor=0

# To remove some of the edge-artifacts associated with map-sharpening the edges
# of the map can be smoothed with a gaussian. Set to 0 to not smooth the edges,
# otherwise it must be set to an odd number. If an even number is given one will
# be added to the value to make it odd.
box_gaussian=1

# There are two mode used for low pass filtering. The first uses an FSC
# based threshold (mode 1), i.e. after FSC < 0.143, or a pixel-based
# resolution threhsold (mode 2).
filter_mode=1

# Set the threshold for the low pass filtering described above. Should be less
# than 1 for FSC based threshold (mode 1), and an integer value for the Fourier
# pixel-based threshold (mode 2).
filter_threshold=0.143

# Plot the sharpening curve - 1 = yes, 0 = no.
plot_sharpen=1

################################################################################
#                             REWEIGHTING OPTIONS                              #
################################################################################
# Set to 1 to apply the externally calculated Fourier weights filter_A_fn and
# filter_B_fn to each half-map to reweight the final output map.
do_reweight=0

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    ${exec_dir}/scripts/subtom_maskcorrected_fsc.sh "$(realpath $0)"
else
    echo "Options sourced!"
fi
