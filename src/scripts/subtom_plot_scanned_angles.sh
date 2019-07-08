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
# - subtom_plot_scanned_angles

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
# Plot scanned angles executable.
plot_angles_exec="${exec_dir}/utils/subtom_plot_scanned_angles"

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name prefix of the output plot. If you want to skip this
# output file leave this set to "".
output_fn_prefix=""

################################################################################
#                         PLOT SCANNED ANGLES OPTIONS                          #
################################################################################
# Angular increment in degrees, applied during the cone-search, i.e. psi and
# theta (define as real e.g. psi_angle_step=3)
psi_angle_step="0"

# Number of angular iterations, applied to psi and theta  (define as integer
# e.g. psi_angle_shells=3)
psi_angle_shells="0"

# Angular increment for phi in degrees, (define as real e.g. phi_angle_step=3)
phi_angle_step="0"

# Number of angular iterations for phi, (define as integer e.g.
# phi_angle_shells=3)
phi_angle_shells="0"

# Initial first Euler angle rotation around the Z-axis about which the scanned
# angles are centered. (define as real e.g. initial_phi=45).
initial_phi="0"

# Initial third Euler angle rotation around the Z-axis about which the scanned
# angles are centered. (define as real e.g. initial_psi=30).
initial_psi="0"

# Initial second Euler angle rotation around the X-axis about which the scanned
# angles are centered. (define as real e.g. initial_theta=135).
initial_theta="0"

# If the above angles are specified as degress leave this set to 'degrees', but
# if the angles above are in radian format set this to 'radians'.
angle_fmt="degrees"

# Set the marker size of the arrows that are drawn for the rotations, reasonable
# values seem to be around the range of 0.01 to 0.1.
marker_size="0.1"

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    "${exec_dir}/scripts/subtom_plot_scanned_angles.sh" "$(realpath $0)"
else
    echo "Options sourced!"
fi
