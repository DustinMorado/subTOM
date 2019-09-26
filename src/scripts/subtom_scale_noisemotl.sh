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
# This MOTL manipulation script uses three MATLAB compiled scripts below:
# - subtom_cat_motls
# - subtom_scale_motl
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

# Absolute path to directory for executables.
exec_dir="XXXINSTALLATION_DIRXXX/bin"

################################################################################
#                                  VARIABLES                                   #
################################################################################
# cat_motls executable
cat_motls_exec="${exec_dir}/MOTL/subtom_cat_motls"

# scale_motl executable.
scale_motl_exec="${exec_dir}/MOTL/subtom_scale_motl"

# Split MOTL by row executable.
split_motl_by_row_exec="${exec_dir}/MOTL/subtom_split_motl_by_row"

# MOTL dump executable
motl_dump_exec="${exec_dir}/MOTL/motl_dump"

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# The iteration of the all particle motive list to process from : input will be
# all_motl_fn_prefix_iteration.em (define as integer e.g. iteration=1)
iteration="1"

# Relative path and prefix to allmotl file from root folder.
all_motl_fn_prefix="combinedmotl/allmotl"

# Relative path and prefix to input noisemotl filename.
input_noise_motl_fn_prefix="../bin8/combinedmotl/noisemotl"

# Relative path and prefix to output noisemotl filename.
output_noise_motl_fn_prefix="combinedmotl/noisemotl"

################################################################################
#                              TOMOGRAM OPTIONS                                #
################################################################################
# Row number of allmotl for tomogram numbers.
tomo_row="7"

################################################################################
#                                SCALING OPTION                                #
################################################################################
# How much to scale up the tomogram coordinate extraction positions (rows 8
# through 10 in the MOTL), e.g. To scale from bin8 to bin4 the factor would be
# 2.
scale_factor="2"

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    "${exec_dir}/scripts/subtom_scale_noisemotl.sh" "$(realpath $0)"
else
    echo "Options sourced!"
fi
