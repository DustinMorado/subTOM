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
# - subtom_even_odd_motl

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
# Even Odd Split Motive List executable
even_odd_exec="${exec_dir}/MOTL/subtom_even_odd_motl"

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name of the input MOTL file to be split.
input_motl_fn="combinedmotl/allmotl_1.em"

# Relative path and name of the output MOTL file where the even and odd halves
# are specified by the class number in the 20th row of the motive list. The even
# half inherits the current class number plus 200 and the odd half inherits the
# current class numbers plus 100.
output_motl_fn="combinedmotl/allmotl_eo_1.em"

# Relative path and name of the output even MOTL file.
even_motl_fn="even/combinedmotl/allmotl_1.em"

# Relative path and name of the output odd MOTL file.
odd_motl_fn="odd/combinedmotl/allmotl_1.em"

################################################################################
#                              EVEN / ODD OPTIONS                              #
################################################################################
# The following specifies which row of the MOTL will be used to split the data.
# To simply split into even and odd halves use the particle running ID, which is
# row 4. To split the halves by tomogram use row 5 or 7, and to split the halves
# by tube or sphere use row 6.
split_row=4

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    ${exec_dir}/scripts/subtom_even_odd_motl.sh "$(realpath $0)"
else
    echo "Options sourced!"
fi
