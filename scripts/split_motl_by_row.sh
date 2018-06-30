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
# - split_motl_by_row

# DRM 05-2018
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# MCR directory for the processing
mcr_cache_dir="mcr"

# Directory for executables
exec_dir=XXXINSTALLATION_DIRXXX/bin

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative or absolute path and name of the input MOTL file to be split.
input_motl_fn=<INPUT_MOTL_FN>

# Relative or absolute path and filename prefix of output MOTL files
output_motl_fn_prfx=<OUTPUT_MOTL_FN_PRFX>

################################################################################
#                                  VARIABLES                                   #
################################################################################
# unbinmotl executable
split_motl_by_row_exec=${exec_dir}/split_motl_by_row

# Which row to split the input MOTL file by
motl_row=<MOTL_ROW>

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ ! -d ${mcr_cache_dir} ]]
then
    mkdir -p ${mcr_cache_dir}
fi

ldpath=XXXMCR_DIRXXX/runtime/glnxa64
ldpath=${ldpath}:XXXMCR_DIRXXX/bin/glnxa64
ldpath=${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64
ldpath=${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=${ldpath}
MCRDIR=${PWD}/${mcr_cache_dir}/split_motl_by_row
rm -rf ${MCRDIR}
mkdir ${MCRDIR}
export MCR_CACHE_ROOT=${MCRDIR}
time ${split_motl_by_row_exec} \
    ${input_motl_fn} \
    ${motl_row} \
    ${output_motl_fn_prfx}
rm -rf ${MCRDIR}
