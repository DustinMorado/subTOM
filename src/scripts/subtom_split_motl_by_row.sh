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
# - subtom_split_motl_by_row

# DRM 05-2019
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the folder with the input to be processed.
# Other paths are relative to this one.
scratch_dir="${PWD}"

# Absolute path to MCR directory for the processing.
mcr_cache_dir="${scratch_dir}/mcr"

# Directory for executables
exec_dir="XXXINSTALLATION_DIRXXX/bin"

################################################################################
#                                  VARIABLES                                   #
################################################################################
# Split MOTL by row executable.
split_motl_by_row_exec="${exec_dir}/MOTL/subtom_split_motl_by_row"

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name of the input MOTL file to be split.
input_motl_fn="combinedmotl/allmotl_1.em"

# Relative path and filename prefix of output MOTL files.
output_motl_fn_prefix="combinedmotl/allmotl_1_tomo"

################################################################################
#                              SPLIT MOTL OPTIONS                              #
################################################################################

# Which row to split the input MOTL file by.
split_row="7"

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    ${exec_dir}/scripts/subtom_split_motl_by_row.sh "$(realpath $0)"
else
    echo "Options sourced!"
fi
