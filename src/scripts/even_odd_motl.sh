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
# This MOTL manipulation script uses one MATLAB compiled scripts below:
# - even_odd_motl

# DRM 05-2018
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the folder with the input to be processed.
# Other paths are relative to this one.
scratch_dir=<SCRATCH_DIR>

# Absolute path to MCR directory for the processing.
mcr_cache_dir="${scratch_dir}/mcr"

# Directory for executables
exec_dir=XXXINSTALLATION_DIRXXX/bin

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative or absolute path and name of the input MOTL file to be split.
input_motl_fn=<INPUT_MOTL_FN>

# Relative or absolute path and name of the output even MOTL file
even_motl_fn=<EVEN_MOTL_FN>

# Relative or absolute path and name of the output odd MOTL file
odd_motl_fn=<ODD_MOTL_FN>

################################################################################
#                                  VARIABLES                                   #
################################################################################
# unbinmotl executable
even_odd_exec=${exec_dir}/even_odd_motl

################################################################################
#                              EVEN / ODD OPTIONS                              #
################################################################################
# The following specifies which row of the MOTL will be used to split the data.
# To simply split into even and odd halves use the particle running ID, which is
# row 4. To split the halves by tomogram use row 5 or 7, and to split the halves
# by tube or sphere use row 6.
split_row=4

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
cd ${scratch_dir}
mcr_cache_dir=${mcr_cache_dir}/even_odd_motl
if [[ ! -d ${mcr_cache_dir} ]]
then
    mkdir -p ${mcr_cache_dir}
else
    rm -rf ${mcr_cache_dir}
    mkdir -p ${mcr_cache_dir}
fi

if [[ ! -d $(dirname ${even_motl_fn}) ]]
then
    mkdir -p $(dirname ${even_motl_fn})
fi

if [[ ! -d $(dirname ${odd_motl_fn}) ]]
then
    mkdir -p $(dirname ${odd_motl_fn})
fi

ldpath=XXXMCR_DIRXXX/runtime/glnxa64
ldpath=${ldpath}:XXXMCR_DIRXXX/bin/glnxa64
ldpath=${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64
ldpath=${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=${ldpath}
export MCR_CACHE_ROOT=${mcr_cache_dir}
time ${even_odd_exec} \
    ${input_motl_fn} \
    ${split_row} \
    ${even_motl_fn} \
    ${odd_motl_fn}
rm -rf ${mcr_cache_dir}
