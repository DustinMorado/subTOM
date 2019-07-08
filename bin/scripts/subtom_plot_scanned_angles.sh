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
set -e           # Crash on error
set -o nounset   # Crash on unset variables

source "${1}"

mcr_cacher_dir="${mcr_cache_dir}/plot_scanned_angles"

if [[ ! -d "${mcr_cache_dir}" ]]
then
    mkdir -p "${mcr_cache_dir}"
else
    rm -rf "${mcr_cache_dir}"
    mkdir -p "${mcr_cache_dir}"
fi

if [[ -n "${output_fn_prefix}" ]]
then
    output_dir="${scratch_dir}/$(dirname "${output_fn_prefix}")"

    if [[ ! -d "${output_dir}" ]]
    then
        mkdir -p "${output_dir}"
    fi

    output_fn_prefix_="${scratch_dir}/${output_fn_prefix}"
else
    output_fn_prefix_=""
fi

ldpath="/public/matlab/jbriggs/runtime/glnxa64"
ldpath="${ldpath}:/public/matlab/jbriggs/bin/glnxa64"
ldpath="${ldpath}:/public/matlab/jbriggs/sys/os/glnxa64"
ldpath="${ldpath}:/public/matlab/jbriggs/sys/opengl/lib/glnxa64"
export LD_LIBRARY_PATH="${ldpath}"

export MCR_CACHE_ROOT="${mcr_cache_dir}"

"${plot_angles_exec}" \
    psi_angle_step \
    "${psi_angle_step}" \
    psi_angle_shells \
    "${psi_angle_shells}" \
    phi_angle_step \
    "${phi_angle_step}" \
    phi_angle_shells \
    "${phi_angle_shells}" \
    initial_phi \
    "${initial_phi}" \
    initial_psi \
    "${initial_psi}" \
    initial_theta \
    "${initial_theta}" \
    angle_fmt \
    "${angle_fmt}" \
    marker_size \
    "${marker_size}" \
    output_fn_prefix \
    "${output_fn_prefix_}"

rm -rf ${mcr_cache_dir}
