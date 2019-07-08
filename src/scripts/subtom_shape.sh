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
# This utility script uses one MATLAB compiled scripts below:
# - subtom_shape

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
# shape executable.
shape_exec="${exec_dir}/utils/subtom_shape"

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name of the output volume to write.
output_fn="otherinputs/mask.em"

# Relative path and name of a reference to apply the mask to, which can be
# useful for checking. If you want to skip this check just leave it set to ""
ref_fn=""

################################################################################
#                                 SHAPE OPTION                                 #
################################################################################
# The shape to place into the volume. The available options are: sphere,
# sphere_shell, ellipsoid, ellipsoid_shell, cylinder, tube, elliptic_cylinder,
# elliptic_tube and cuboid.
shape="sphere"

# Size of the volume in pixels. The volume will be a cube with this side length.
box_size="128"

# For the shapes: sphere, and cylinder. Defines the radius of the shape. If you
# are not creating one of the listed shapes leave this set to "".
radius="32"

# For the shapes: sphere_shell, and tube. Defines the inner radius of the shape.
# If you are not creating one of the listed shapes leave this set to "".
inner_radius=""

# For the shapes: sphere_shell, and tube. Defines the outer radius of the shape.
# If you are not creating one of the listed shapes leave this set to "".
outer_radius=""

# For the shapes: ellipsoid, and elliptic_cylinder. Defines the radius of the
# shape about the X-axis. If you are not creating one of the listed shapes leave
# this set to "".
radius_x=""

# For the shapes: ellipsoid, and elliptic_cylinder. Defines the radius of the
# shape about the Y-axis. If you are not creating one of the listed shapes leave
# this set to "".
radius_y=""

# For the shapes: ellipsoid, and elliptic_cylinder. Defines the radius of the
# shape about the Z-axis. If you are not creating one of the listed shapes leave
# this set to "".
radius_z=""

# For the shapes: ellipsoid_shell, and elliptic_tube. Defines the inner radius
# of the shape about the X-axis. If you are not creating one of the listed
# shapes leave this set to "".
inner_radius_x=""

# For the shapes: ellipsoid_shell, and elliptic_tube. Defines the inner radius
# of the shape about the Y-axis. If you are not creating one of the listed
# shapes leave this set to "".
inner_radius_y=""

# For the shapes: ellipsoid_shell, and elliptic_tube. Defines the inner radius
# of the shape about the Z-axis. If you are not creating one of the listed
# shapes leave this set to "".
inner_radius_z=""

# For the shapes: ellipsoid_shell, and elliptic_tube. Defines the outer radius
# of the shape about the X-axis. If you are not creating one of the listed
# shapes leave this set to "".
outer_radius_x=""

# For the shapes: ellipsoid_shell, and elliptic_tube. Defines the outer radius
# of the shape about the Y-axis. If you are not creating one of the listed
# shapes leave this set to "".
outer_radius_y=""

# For the shapes: ellipsoid_shell, and elliptic_tube. Defines the outer radius
# of the shape about the Z-axis. If you are not creating one of the listed
# shapes leave this set to "".
outer_radius_z=""

# For the shape: cuboid. Defines the side length of the cuboid about the X-axis.
# If you are not creating one of the listed shapes leave this set to "".
length_x=""

# For the shape: cuboid. Defines the side length of the cuboid about the Y-axis.
# If you are not creating one of the listed shapes leave this set to "".
length_y=""

# For the shape: cuboid. Defines the side length of the cuboid about the Z-axis.
# If you are not creating one of the listed shapes leave this set to "".
length_z=""

# For the shape: cylinder, tube, elliptic_cylinder, and elliptic_tube. Defines
# the height of the shape. If you are not creating one of the listed shapes
# leave this set to "".
height=""

# For all shapes. Defines the X-coordinate of the center of the shape. The
# default center is defined as floor(box_size / 2) + 1. If you do not want to
# modify the default value leave this set to "".
center_x=""

# For all shapes. Defines the Y-coordinate of the center of the shape. The
# default center is defined as floor(box_size / 2) + 1. If you do not want to
# modify the default value leave this set to "".
center_y=""

# For all shapes. Defines the Z-coordinate of the center of the shape. The
# default center is defined as floor(box_size / 2) + 1. If you do not want to
# modify the default value leave this set to "".
center_z=""

# For all shapes. Defines a shift along the X-axis after any given rotations.
# This shift is part of an affine transformation about the given center that is
# applied to the coordinates before the shape is determined. If you do not want
# to modify the default value leave this set to "".
shift_x=""

# For all shapes. Defines a shift along the Y-axis after any given rotations.
# This shift is part of an affine transformation about the given center that is
# applied to the coordinates before the shape is determined. If you do not want
# to modify the default value leave this set to "".
shift_y=""

# For all shapes. Defines a shift along the Z-axis after any given rotations.
# This shift is part of an affine transformation about the given center that is
# applied to the coordinates before the shape is determined. If you do not want
# to modify the default value leave this set to "".
shift_z=""

# For all shapes. Defines an inplane rotation about the Z-axis. This rotation is
# part of an affine transformation about the given center that is applied to the
# coordinates before the shape is determined. If you do not want to modify the
# default value leave this set to "".
rotate_phi=""

# For all shapes. Defines an azimuthal rotation about the Z-axis. This rotation
# is part of an affine transformation about the given center that is applied to
# the coordinates before the shape is determined. If you do not want to modify
# the default value leave this set to "".
rotate_psi=""

# For all shapes. Defines a zenithal rotation about the X-axis. This rotation is
# part of an affine transformation about the given center that is applied to the
# coordinates before the shape is determined. If you do not want to modify the
# default value leave this set to "".
rotate_theta=""

# For all shapes. Defines the sigma of a Gaussian falloff away from the hard
# edges of the shape. If you do not want to modify the default value leave this
# set to "".
sigma=""

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    "${exec_dir}/scripts/subtom_shape.sh" "$(realpath $0)"
else
    echo "Options sourced!"
fi
