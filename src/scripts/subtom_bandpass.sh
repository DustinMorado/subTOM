#!/bin/bash
################################################################################
# This is a run script for the standard AV3 subtomogram averaging scripts. The
# MATLAB executables for this script were compiled in MATLAB-9.9. The other
# difference is that these scripts have been edited to make sure that the output
# files from each step is readable.
#
# This script is meant to run anywhere.
#
# Also, the run script and all the launch scripts are written in bash. This is
# mainly because the behaviour of bash is a bit more predictable.
#
# This utility script uses one MATLAB compiled scripts below:
# - subtom_bandpass

# DRM 02-2021
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the root folder for subtomogram extraction.
# Other paths are relative to this one.
scratch_dir="${PWD}"

# Absolute path to the MCR directory for each job
mcr_cache_dir="${scratch_dir}/mcr"

# Directory for executables
exec_dir="XXXINSTALLATION_DIRXXX/bin"

################################################################################
#                                  VARIABLES                                   #
################################################################################
# bandpass executable.
bandpass_exec="${exec_dir}/utils/subtom_bandpass"

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name of the input volume to build and filter the bandpass
# against. If you just want to visualize an arbitrary filter you can use
# subtom_shape to create a template of the correct size and not ask for the
# filtered output.
input_fn="ref/ref_1.em"

# Relative path and name of the Fourier bandpass filter to write. If you do not
# want to output the filter volume simply leave this option blank.
filter_fn=""

# Relative path and name of the filtered volume to write. If you do not want to
# output the filtered volume simply leave this option blank.
output_fn=""

################################################################################
#                                FILTER OPTIONS                                #
################################################################################
# High pass filter cutoff (in transform units (pixels): calculate as
# (box_size*pixelsize)/(resolution_real) (define as integer e.g. high_pass_fp=2)
high_pass_fp="0"

# High pass filter falloff sigma (in transform units (pixels): describes a
# Gaussian sigma for the falloff of the high-pass filter past the cutoff above.
high_pass_sigma="2"

# Low pass filter (in transform units (pixels): calculate as
# (box_size*pixelsize)/(resolution_real) (define as integer e.g. low_pass_fp=7).
low_pass_fp="0"

# Low pass filter falloff sigma (in transform units (pixels): describes a
# Gaussian sigma for the falloff of the low-pass filter past the cutoff above.
low_pass_sigma="3"

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    ${exec_dir}/scripts/subtom_bandpass.sh "$(realpath $0)"
else
    echo "Options sourced!"
fi
