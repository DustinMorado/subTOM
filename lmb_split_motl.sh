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
# - lmb_splitmotl

# DRM 01-2018
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
# Relative or absolute path and name of the input MOTL file to be split.
input_motl_fn="<INPUT_MOTL_FN>"

# Relative or absolute path and name of the even output MOTL file.
even_motl_fn="<EVEN_MOTL_FN>"

# Relative or absolute path and name of the odd output MOTL file.
odd_motl_fn="<ODD_MOTL_FN>"

################################################################################
#                                  VARIABLES                                   #
################################################################################
# unbinmotl executable
splitmotl_exec=${exec_dir}/lmb_split_motl

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
MCRDIR=${PWD}/${mcr_cache_dir}/splitmotl
rm -rf ${MCRDIR}
mkdir ${MCRDIR}
export MCR_CACHE_ROOT=${MCRDIR}
time ${splitmotl_exec} \
    ${input_motl_fn} \
    ${even_motl_fn} \
    ${odd_motl_fn}
rm -rf ${MCRDIR}