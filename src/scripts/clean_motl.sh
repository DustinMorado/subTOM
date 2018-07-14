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
# - clean_motl

# DRM 12-2017
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
# Relative or absolute path and name of the input MOTL file to be cleaned.
input_motl_fn=<INPUT_MOTL_FN>

# Relative or absolute path and name of the output MOTL file.
output_motl_fn=<OUTPUT_MOTL_FN>

################################################################################
#                                  VARIABLES                                   #
################################################################################
# clean_motl executable
clean_motl_exec=${exec_dir}/clean_motl

################################################################################
#                                CLEAN OPTIONS                                 #
################################################################################
# Which row in the motl file contains the correct tomogram number.
# Usually row 5 and 7 both correspond to the correct value and can be used
# interchangeably, but there are instances when 5 contains a sequential ordered
# value starting from 1, while 7 contains the correct corresponding tomogram.
tomo_row=7

# Particles that are less than this distance in pixels from another particle
# will be cleaned with the particle with the highest CCC kept while the others
# are removed from the output MOTL file.
distance_cutoff=100

# Particles with a CCC below this cutoff will be removed from the output MOTL
# file. Use a value of -1 to only clean by distance.
cc_cutoff=-1

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
cd ${scratch_dir}
mcr_cache_dir=${mcr_cache_dir}/clean_motl
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
time ${clean_motl_exec} \
    ${input_motl_fn} \
    ${output_motl_fn} \
    ${tomo_row} \
    ${distance_cutoff} \
    ${cc_cutoff}
rm -rf ${mcr_cache_dir}
