#!/bin/bash
################################################################################
# This is a run script for the standard AV3 subtomogram averaging scripts. The
# MATLAB executables for this script were compiled in MATLAB-8.5. The other
# difference is that these scripts have been edited to make sure that the output
# files from each step is readable.
#
# This script is meant to run on the scratch it copies the reference and final
# allmotl file to a local folder after each iteration.
#
# Also, the run script and all the launch scripts are written in bash. This is
# mainly because the behaviour of bash is a bit more predictable.
#
# This subtomogram parallel averaging script uses two MATLAB compiled scripts
# below:
# - subtom_rand_class_motl
# DRM 05-2019
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the root folder for subtomogram extraction.
# Other paths are relative to this one.
scratch_dir="${PWD}"

# Absolute path to the MCR directory for each job
mcr_cache_dir="${scratch_dir}/mcr"

# Directory for executables
exec_dir="XXXINSTALLATION_DIRXXX/bin"

################################################################################
#                                  VARIABLES                                   #
################################################################################
# Randomize Motive List executable.
rand_exec="${exec_dir}/classification/multiref/subtom_rand_class_motl"

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name of the input motivelist to be randomized in class.
input_motl_fn="combinedmotl/allmotl_1.em"

# Relative path and name of the output motivelist.
output_motl_fn="combinedmotl/allmotl_multiref_1.em"

################################################################################
#                            RANDOMIZE MOTL OPTIONS                            #
################################################################################
# The number of classes to split the initial motive list into. The classes will
# be assigned randomly evenly within the valid particles, (non-negative class
# values excluding class 2), with the class number starting at 3 to not
# interfere with the classes 1 and 2 which are reserved for AV3's thresholding
# process.
num_classes="2"

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    ${exec_dir}/scripts/subtom_multiref_rand_class_motl.sh "$(realpath $0)"
else
    echo "Options sourced!"
fi
