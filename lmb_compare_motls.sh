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
# - lmb_compare_motls

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
exec_dir=${bstore1}/software/lmbtomopipeline/compiled

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative or absolute path and name of the first MOTL file
motl_A_fn=combinedmotl/allmotl_1.em

# Relative or absolute path and name of the second MOTL file
motl_B_fn=combinedmotl/allmotl_2.em

# Relative or absolute path and name of the optional output difference CSV file.
diff_output_fn=combinedmotl/allmotl_1_2_diff.csv

################################################################################
#                                  VARIABLES                                   #
################################################################################
# Comparison MOTL executable
compare_motls_exec=${exec_dir}/lmb_compare_motls

# Set the following to true to write out the differences, or false to skip
write_diffs='true'
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
MCRDIR=${PWD}/${mcr_cache_dir}/compare_motls
rm -rf ${MCRDIR}
mkdir ${MCRDIR}
export MCR_CACHE_ROOT=${MCRDIR}
time ${compare_motls_exec} \
    ${motl_A_fn} \
    ${motl_B_fn} \
    ${write_diffs} \
    ${diff_output_fn}
rm -rf ${MCRDIR}
