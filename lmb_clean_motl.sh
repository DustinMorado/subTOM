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
# clean_motl executable
clean_motl_exec=${exec_dir}/lmb_clean_motl

################################################################################
#                                CLEAN OPTIONS                                 #
################################################################################
# Which row in the motl file contains the correct tomogram number.
# Usually row 5 and 7 both correspond to the correct value and can be used
# interchangeably, but there are instances when 5 contains a sequential ordered
# value starting from 1, while 7 contains the correct corresponding tomogram.
tomo_row=7

# Particles that are less than this distance in pixels from another particle
# will be cleaned with the particle with the highest CCC kept while the others
# are removed from the output MOTL file.
distance_cutoff=100

# Particles with a CCC below this cutoff will be removed from the output MOTL
# file. Use a value of -1 to only clean by distance.
cc_cutoff=-1

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
MCRDIR=${PWD}/${mcr_cache_dir}/clean_motl
rm -rf ${MCRDIR}
mkdir ${MCRDIR}
export MCR_CACHE_ROOT=${MCRDIR}
time ${clean_motl_exec} \
    ${input_motl_fn} \
    ${output_motl_fn} \
    ${tomo_row} \
    ${distance_cutoff} \
    ${cc_cutoff}
rm -rf ${MCRDIR}
