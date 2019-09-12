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
# - subtom_random_subset_motl

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
# Random subset motive list executable.
random_subset_motl_exec="${exec_dir}/MOTL/subtom_random_subset_motl"

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name of the input MOTL file to draw the subset from.
input_motl_fn="combinedmotl/allmotl_1.em"

# Relative path and name of the output MOTL file.
output_motl_fn="combinedmotl/allmotl_subset_1.em"

################################################################################
#                                SUBSET OPTIONS                                #
################################################################################
# How many particles to be included in the subset.
subset_size=1000

# The following describes a field in the MOTL to equally distribute particles of
# the subset amongst. Such that if subset_row was the tomogram row (7), and
# there were ten tomograms described in the motive list, then the subset of 1000
# particles would have 100 particles from each tomogram. If there are more
# unique values than the subset size then the field is not taken into account.
subset_row=7

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    "${exec_dir}/scripts/subtom_random_subset_motl.sh" "$(realpath $0)"
else
    echo "Options sourced!"
fi
