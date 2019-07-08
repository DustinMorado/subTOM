#!/bin/bash
################################################################################
# This is a run script for the standard AV3 subtomogram averaging scripts. The
# MATLAB executables for this script were compiled in MATLAB-8.5. The other
# difference is that these scripts have been edited to make sure that the output
# files from each step is readable.
#
# This script is meant to run anywhere.
#
# Also, the run script and all the launch scripts are written in bash. This is
# mainly because the behaviour of bash is a bit more predictable.
#
# This utility script uses one MATLAB compiled scripts below:
# - subtom_plot_filter

# DRM 05-2019
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the folder with the input to be processed.
# Other paths are relative to this one.
scratch_dir="${PWD}"

# Absolute path to MCR directory for the processing.
mcr_cache_dir="${scratch_dir}/mcr"

# Absolute path to directory for executables.
exec_dir="XXXINSTALLATION_DIRXXX/bin"

################################################################################
#                                  VARIABLES                                   #
################################################################################
# Plot filter executable.
plot_filter_exec="${exec_dir}/utils/subtom_plot_filter"

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name prefix of the output plot. If you want to skip this
# output file leave this set to "".
output_fn_prefix=""

################################################################################
#                             PLOT FILTER OPTIONS                              #
################################################################################
# Size of the volume in pixels. The volume will be a cube with this side length.
box_size="128"

# Pixelsize of the data in Angstroms.
pixelsize="1"

# High pass filter cutoff (in transform units (pixels): calculate as
# (box_size*pixelsize)/(resolution_real) (define as integer e.g. high_pass_fp=2)
high_pass_fp="0"

# High pass filter falloff sigma (in transform units (pixels): describes a
# Gaussian sigma for the falloff of the high-pass filter past the cutoff above.
high_pass_sigma="0"

# Low pass filter (in transform units (pixels): calculate as
# (box_size*pixelsize)/(resolution_real) (define as integer e.g.low_pass_fp=30).
low_pass_fp="0"

# Low pass filter falloff sigma (in transform units (pixels): describes a
# Gaussian sigma for the falloff of the low-pass filter past the cutoff above.
low_pass_sigma="0"

# Defocus to plot along with band-pass filter in Angstroms with underfocus being
# positive. The graphic will include a line for the CTF root square and how it
# is attenuated by the band-pass which can be useful for understanding how
# amplitudes are modified by the filter. If you do not want to use this option
# just leave it set to "0" or "".
defocus="0"

# Voltage in keV used for calculating the CTF. If you do not want to plot a CTF
# function leave this set to "" or "300".
voltage="300"

# Spherical aberration in mm used for calculating the CTF. If you do not want to
# plot a CTF function leave this set to "" or "0.0".
cs="0.0"

# Amplitude contrast as a fraction of contrast (i.e. between 0 and 1) used for
# calculating the CTF. If you do not want to plot a CTF function leave this set
# to "" or "1".
ac="1"

# Phase shift in degrees used for calculating the CTF. If you do not want to
# plot a CTF function leave this set to "" or "0".
phase_shift="0"

# B-Factor describing the falloff of signal in the data by a multitude of
# amplitude decay factors. The graphic will include a line for the falloff and
# how it interacts with both the CTF if one was given and the band-pass filter.
# If you do not want to use this option just leave it set to "" or "0"
b_factor="0"

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    "${exec_dir}/scripts/subtom_plot_filter.sh" "$(realpath $0)"
else
    echo "Options sourced!"
fi
