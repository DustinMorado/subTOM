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
# - subtom_seed_positions

# DRM 05-2019
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the folder with the input to be processed.
# Other paths are relative to this one.
scratch_dir="${PWD}"

# Absolute path to MCR directory for the processing
mcr_cache_dir="${scratch_dir}/mcr"

# Directory for executables
exec_dir="XXXINSTALLATION_DIRXXX/bin"

################################################################################
#                                  VARIABLES                                   #
################################################################################
# seed_positions executable
seed_pos_exec="${exec_dir}/MOTL/subtom_seed_positions"

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and prefix of the input MOTL files to be seeded.
input_motl_fn_prefix="../startset/clicker"

# Relative path and name of the output MOTL file.
output_motl_fn="combinedmotl/allmotl_1.em"

################################################################################
#                                 SEED OPTIONS                                 #
################################################################################
# The spacing in pixels at which positions will be added to the surface. 
spacing="8"

# If this is set to 1 (i.e. evaluates to true in Matlab) then the clicker
# motive list is assumed to correspond to tubules and points will be added along
# the tubule-axis. Otherwise the clicker file is assumed to correspond to
# spheres.
do_tubule="0"

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    ${exec_dir}/scripts/subtom_seed_positions.sh "$(realpath $0)"
else
    echo "Options sourced!"
fi
