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
# - subtom_cat_motls

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
# cat_motls executable
cat_motls_exec=${exec_dir}/MOTL/subtom_cat_motls

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and filename(s) of the input MOTL files to be
# concatenated. You can use shell wildcard characters * and ? to specify a given
# number of files and they will be expanded or you can just list the files one
# by one.
input_motl_fns=("")

# Relative path and name of the output MOTL file. If you are not
# going to write an output file just set this variable to ''
output_motl_fn=""

# Relative path and name of the output STAR file. If you are not
# going to write an output file just set this variable to ''
output_star_fn=""

################################################################################
#                             CONCATENATE OPTIONS                              #
################################################################################
# If you want to write out the concatenated MOTL files set this to 1, however if
# you just want to print the MOTL contents to the screen, set this to 0.
write_motl="0"

# If you want to write out the concatenated STAR file set this to 1, however if
# you just want to print the MOTL contents to the screen, set this to 0.
write_star="0"

# If you want to have the output MOTL file sorted by a particular field then
# specify it here. If the given value is not a value between 1-20 then the
# output MOTL file will be sorted arbitrarily based on the dir command in
# Matlab.
sort_row="4"

# If you just want to write output to files and not print to the screen set this
# to 1, however if you want to see the output printed to the screen leave this
# set to 0.
do_quiet="0"

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    ${exec_dir}/scripts/subtom_cat_motls.sh "$(realpath $0)"
else
    echo "Options sourced!"
fi
