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
# - lmb_unbinmotl

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
# Relative or absolute path and name of the input MOTL file to be unbinned.
input_motl_fn=bin8/even/combinedmotl/allmotl_1.em

# Relative or absolute path and name of the output MOTL file.
output_motl_fn=bin4/even/combinedmotl/allmotl_1.em

################################################################################
#                                  VARIABLES                                   #
################################################################################
# unbinmotl executable
unbinmotl_exec=${exec_dir}/lmb_unbinmotl

################################################################################
#                               UNBINNING OPTION                               #
################################################################################
# How much to scale up the tomogram coordinate extraction positions (rows 8
# through 10 in the MOTL) and the particle shifts (rows 11 through 13).
# e.g. To scale from bin8 to bin4 the factor would be 2.
unbin_factor=2

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
time ${unbinmotl_exec} \
    ${input_motl_fn} \
    ${output_motl_fn} \
    ${unbin_factor} \
rm -rf ${MCRDIR}
