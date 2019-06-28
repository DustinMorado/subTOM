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
# - subtom_compare_motls

# DRM 05-2019
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
# Comparison MOTL executable
compare_motls_exec="${exec_dir}/MOTL/subtom_compare_motls"

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name of the first MOTL file
motl_1_fn="combinedmotl/allmotl_1.em"

# Relative path and name of the second MOTL file
motl_2_fn="combinedmotl/allmotl_2.em"

# Relative path and name of the optional output difference CSV file. If you do
# not want to write out the differences just leave this as "".
output_diffs_fn=""

################################################################################
#                              COMPARISON OPTIONS                              #
################################################################################
# If the following is 1 then the differences will be written out, if 0 then not.
write_diffs="0"

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    ${exec_dir}/scripts/subtom_compare_motls.sh "$(realpath $0)"
else
    echo "Options sourced!"
fi
