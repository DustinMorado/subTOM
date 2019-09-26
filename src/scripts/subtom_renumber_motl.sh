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
# - subtom_renumber_motl

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
# renumber_motl executable.
renumber_motl_exec="${exec_dir}/MOTL/subtom_renumber_motl"

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name of the input MOTL file to be renumbered.
input_motl_fn="combinedmotl/allmotl_1.em"

# Relative path and name of the output MOTL file.
output_motl_fn="combinedmotl/allmotl_renumber_1.em"

################################################################################
#                               RENUMBER OPTIONS                               #
################################################################################
# If you want to have the output MOTL file sorted by a particular field before
# renumbering then specify it here.
sort_row="4"

# If the following is 1, particles will be completely renumbered from 1 to the
# number of particles in the motive list. If it is 0, particles will be
# renumbered in a way that preserves the original index while still removing any
# duplicate indices. As a guide you probably want to renumber sequentially after
# cleaning from initial oversampled coordinates, but do not want to renumber
# sequentially in other cases.
do_sequential="0"

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    "${exec_dir}/scripts/subtom_renumber_motl.sh" "$(realpath $0)"
else
    echo "Options sourced!"
fi
