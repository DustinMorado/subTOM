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
# - compare_motls

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
mcr_cache_dir=${scratch_dir}/mcr

# Directory for executables
exec_dir=XXXINSTALLATION_DIRXXX/bin

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative or absolute path and name of the first MOTL file
motl_A_fn=<MOTL_A_FN>

# Relative or absolute path and name of the second MOTL file
motl_B_fn=<MOTL_B_FN>

# Relative or absolute path and name of the optional output difference CSV file.
diff_output_fn=<DIFF_OUTPUT_FN>

################################################################################
#                                  VARIABLES                                   #
################################################################################
# Comparison MOTL executable
compare_motls_exec=${exec_dir}/compare_motls

# If the following is 1 then the differences will be written out, if 0 then not.
write_diffs=1
################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
cd ${scratch_dir}
mcr_cache_dir=${mcr_cache_dir}/compare_motls
if [[ ! -d ${mcr_cache_dir} ]]
then
    mkdir -p ${mcr_cache_dir}
else
    rm -rf ${mcr_cache_dir}
    mkdir -p ${mcr_cache_dir}
fi

if [[ ! -d $(dirname ${diff_output_fn}) ]]
then
    mkdir -p $(dirname ${diff_output_fn})
fi

ldpath=XXXMCR_DIRXXX/runtime/glnxa64
ldpath=${ldpath}:XXXMCR_DIRXXX/bin/glnxa64
ldpath=${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64
ldpath=${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=${ldpath}
export MCR_CACHE_ROOT=${mcr_cache_dir}
time ${compare_motls_exec} \
    ${motl_A_fn} \
    ${motl_B_fn} \
    ${write_diffs} \
    ${diff_output_fn}
rm -rf ${mcr_cache_dir}
