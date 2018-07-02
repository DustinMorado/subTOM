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
# - seed_positions

# DRM 07-2018
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
# Relative or absolute path and prefix of the input MOTL files to be seeded.
input_motl_fn_prefix=<INPUT_MOTL_FN>

# Relative or absolute path and name of the output MOTL file.
output_motl_fn=<OUTPUT_MOTL_FN>

################################################################################
#                                  VARIABLES                                   #
################################################################################
# seed_positions executable
seed_pos_exec=${exec_dir}/seed_positions

################################################################################
#                                 SEED OPTIONS                                 #
################################################################################
# The spacing in pixels at which positions will be added to the surface. 
spacing=<SPACING>

# If this is set to 1 (i.e. evaluates to true in Matlab) then the clicker
# motive list is assumed to correspond to tubules and points will be added along
# the tubule-axis. Otherwise the clicker file is assumed to correspond to
# spheres.
do_tubule=0

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ ! -d ${mcr_cache_dir} ]]
then
    mkdir -p ${mcr_cache_dir}
fi

if [[ ! -d $(dirname output_motl_fn) ]]
then
    mkdir -p $(dirname output_motl_fn) ]]
fi

ldpath=/XXXMCR_DIRXXX/runtime/glnxa64
ldpath=${ldpath}:/XXXMCR_DIRXXX/bin/glnxa64
ldpath=${ldpath}:/XXXMCR_DIRXXX/sys/os/glnxa64
ldpath=${ldpath}:/XXXMCR_DIRXXX/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=${ldpath}
MCRDIR=${PWD}/${mcr_cache_dir}/seed_positions
rm -rf ${MCRDIR}
mkdir ${MCRDIR}
export MCR_CACHE_ROOT=${MCRDIR}
time ${seed_pos_exec} \
    ${input_motl_fn_prefix} \
    ${output_motl_fn} \
    ${spacing} \
    ${do_tubule}
rm -rf ${MCRDIR}
