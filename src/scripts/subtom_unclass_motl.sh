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
# - subtom_unclass_motl

# DRM 09-2019
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
# unclass motive list executable.
unclass_motl_exec="${exec_dir}/MOTL/subtom_unclass_motl"

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name of the input MOTL file to be unclassed.
input_motl_fn="combinedmotl/allmotl_wmd_1.em"

# Relative path and name of the output MOTL file.
output_motl_fn="combinedmotl/allmotl_wmd_unclassed_1.em"

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    "${exec_dir}/scripts/subtom_unclass_motl.sh" "$(realpath $0)"
else
    echo "Options sourced!"
fi
