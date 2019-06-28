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
# - subtom_transform_motl

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
# Absolute path to transform_motl executable.
transform_motl_exec="${exec_dir}/MOTL/subtom_transform_motl"

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name of the input MOTL file to be transformed.
input_motl_fn="combinedmotl/allmotl_1.em"

# Relative path and name of the output MOTL file.
output_motl_fn="combinedmotl/allmotl_transformed_1.em"

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
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    "${exec_dir}/scripts/subtom_transform_motl.sh" "$(realpath $0)"
else
    echo "Options sourced!"
fi
