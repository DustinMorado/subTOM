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
# - transform_motl

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
# Relative or absolute path and name of the input MOTL file to be transformed.
input_motl_fn=<INPUT_MOTL_FN>

# Relative or absolute path and name of the output MOTL file.
output_motl_fn=<OUTPUT_MOTL_FN>

################################################################################
#                                  VARIABLES                                   #
################################################################################
# transform_motl executable
transform_motl_exec=${exec_dir}/transform_motl

################################################################################
#                              TRANSFORM OPTIONS                               #
################################################################################
# How much to shift the reference along the X-Axis, applied after the rotations
# described below.
shift_x=0.0

# How much to shift the reference along the Y-Axis, applied after the rotations
# described below.
shift_y=0.0

# How much to shift the reference along the Z-Axis, applied after the rotations
# described below.
shift_z=0.0

# Hom much to finally rotate the reference in-plane about it's final Z-Axis.
# (i.e. Spin rotation corresponding to phi).
rotate_phi=0.0

# How much to first rotate the reference about it's initial Z-Axis.
# (i.e. Azimuthal rotation corresponding to psi).
rotate_psi=0.0

# How much to second rotate the reference about it's intermediate X-Axis.
# (i.e. Zenithal rotation corresponding to theta).
rotate_theta=0.0

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
cd ${scratch_dir}
mcr_cacher_dir=${mcr_cache_dir}/scale_motl
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
time ${transform_motl_exec} \
    ${input_motl_fn} \
    ${output_motl_fn} \
    ${shift_x} \
    ${shift_y} \
    ${shift_z} \
    ${rotate_phi} \
    ${rotate_psi} \
    ${rotate_theta}
rm -rf ${mcr_cache_dir}
