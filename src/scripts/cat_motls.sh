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
# - cat_motls

# DRM 07-2018
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the folder with the input to be processed.
# Other paths are relative to this one.
scratch_dir=<SCRATCH_DIR>

# Absolute path to MCR directory for the processing.
mcr_cache_dir=${scratch_dir}/mcr

# Directory for executables
exec_dir=XXXINSTALLATION_DIRXXX/bin

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative or absolute path and filename(s) of the input MOTL files to be
# concatenated. You can use shell wildcard characters * and ? to specify a given
# number of files and they will be expanded or you can just list the files one
# by one.
input_motl_fns=(<INPUT_MOTL_FNS>)

# Relative or absolute path and name of the output MOTL file.
output_motl_fn=<OUTPUT_MOTL_FN>

################################################################################
#                                  VARIABLES                                   #
################################################################################
# cat_motls executable
cat_motls_exec=${exec_dir}/cat_motls

################################################################################
#                             CONCATENATE OPTIONS                               #
################################################################################
# If you want to write out the concatenated MOTL files set this to 1, however if
# you just want to print the MOTL contents to the screen, set this to 0.
write_output=0

# If you want to have the output MOTL file sorted by a particular field then
# specify it here. If the given value is not a value between 1-20 then the
# output MOTL file will be sorted arbitrarily based on the dir command in
# Matlab.
sort_row=0

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
cd ${scratch_dir}
mcr_cache_dir=${mcr_cache_dir}/cat_motls
if [[ ! -d ${mcr_cache_dir} ]]
then
    mkdir -p ${mcr_cache_dir}
else
    rm -rf ${mcr_cache_dir}
    mkdir -p ${mcr_cache_dir}
fi

if [[ ! -d $(dirname ${output_motl_fn}) ]]
then
    mkdir -p $(dirname ${output_motl_fn})
fi

ldpath=XXXMCR_DIRXXX/runtime/glnxa64
ldpath=${ldpath}:XXXMCR_DIRXXX/bin/glnxa64
ldpath=${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64
ldpath=${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=${ldpath}
export MCR_CACHE_ROOT=${mcr_cache_dir}
${cat_motls_exec} \
    ${write_output} \
    ${output_motl_fn} \
    ${sort_row} \
    ${input_motl_fns[*]}
rm -rf ${mcr_cache_dir}
