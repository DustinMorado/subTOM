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
# - lmb_maskcorrected_FSC
#
# DRM 12-2017
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# MCR directory for the processing
mcr_cache_dir="mcr"

# Directory for executables
exec_dir=${bstore1}/software/lmbtomopipeline/compiled

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name of the first half-map.
reference_A_fn=even/ref/ref_1.em

# Relative path and name of the second half-map.
reference_B_fn=odd/ref/ref_1.em

# Relative path and name of the FSC mask.
FSC_mask_fn=fscmask.em

# Relative path and name of the Fourier filter volume for the first half-map.
filter_A_fn=ctffilter_even.em

# Relative path and name of the Fourier filter volume for the second half-map.
filter_B_fn=ctffilter_odd.em

# Relative path and prefix for the name of the output maps and figures.
output_fn_prefix=ref_1

################################################################################
#                                  VARIABLES                                   #
################################################################################
# FSC executable
FSC_exec=${exec_dir}/lmb_maskcorrected_FSC

################################################################################
#                                 FSC OPTIONS                                  #
################################################################################
# Pixelsize of the half-maps in Angstroms
pixelsize=1.177

# Symmetry to applied the half-maps before calculating FSC (1 is no symmetry)
nfold=1

# The Fourier pixel at which phase-randomization begins is set automatically to
# the point where the unmasked FSC falls below this threshold.
rand_threshold=0.8

# Plot the FSC curves - 1 = yes, 0 = no
plot_fsc=1

################################################################################
#                              SHARPENING OPTIONS                              #
################################################################################
# Set to 1 to sharpen map or 0 to skip and just calculate the FSC
do_sharpen=1

# B-Factor to be applied. Since the B-Factor should be negative if the value
# given here is positive it will be converted to negative.
B_factor=-100

# To remove some of the edge-artifacts associated with map-sharpening the edges
# of the map can be smoothed with a gaussian. Set to 0 to not smooth the edges,
# otherwise it must be set to an odd number. If an even number is given one will
# be added to the value to make it odd.
box_gaussian=3

# There are two mode used for low pass filtering. The first uses an FSC
# based threshold (mode 1), i.e. after FSC < 0.143, or a pixel-based
# resolution threhsold (mode 2).
filter_mode=1

# Set the threshold for the low pass filtering described above. Should be less
# than 1 for FSC based threshold (mode 1), and an integer value for the Fourier
# pixel-based threshold (mode 2).
filter_threshold=0.143

# Plot the sharpening curve - 1 = yes, 0 = no
plot_sharpen=1

################################################################################
#                             REWEIGHTING OPTIONS                              #
################################################################################
# Set to 1 to apply the externally calculated Fourier weights filter_A_fn and
# filter_B_fn to each half-map to reweight the final output map.
do_reweight=1

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ ! -d ${mcr_cache_dir} ]]
then
    mkdir -p ${mcr_cache_dir}
fi

ldpath=/lmb/home/public/matlab/jbriggs/runtime/glnxa64
ldpath=${ldpath}:/lmb/home/public/matlab/jbriggs/bin/glnxa64
ldpath=${ldpath}:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64
ldpath=${ldpath}:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=${ldpath}
MCRDIR=${PWD}/${mcr_cache_dir}/lmb_maskcorrected_FSC
rm -rf ${MCRDIR}
mkdir ${MCRDIR}
export MCR_CACHE_ROOT=${MCRDIR}
time ${FSC_exec} \
    ${reference_A_fn} \
    ${reference_B_fn} \
    ${FSC_mask_fn} \
    ${output_fn_prefix} \
    ${pixelsize} \
    ${nfold} \
    ${rand_threshold} \
    ${plot_fsc} \
    ${do_sharpen} \
    ${B_factor} \
    ${box_gaussian} \
    ${filter_mode} \
    ${filter_threshold} \
    ${plot_sharpen} \
    ${do_reweight} \
    ${filter_A_fn} \
    ${filter_B_fn}
rm -rf ${MCRDIR}
