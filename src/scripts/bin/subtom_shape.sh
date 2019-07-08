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

mcr_cacher_dir="${mcr_cache_dir}/shape"

if [[ ! -d "${mcr_cache_dir}" ]]
then
    mkdir -p "${mcr_cache_dir}"
else
    rm -rf "${mcr_cache_dir}"
    mkdir -p "${mcr_cache_dir}"
fi

output_dir="${scratch_dir}/$(dirname "${output_fn}")"

if [[ ! -d "${output_dir}" ]]
then
    mkdir -p "${output_dir}"
fi

if [[ -n "${ref_fn}" ]]
then
    ref_fn_="${scratch_dir}/${ref_fn}"
else
    ref_fn_=""
fi

ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
export LD_LIBRARY_PATH="${ldpath}"

export MCR_CACHE_ROOT="${mcr_cache_dir}"

"${shape_exec}" \
    shape \
    "${shape}" \
    box_size \
    "${box_size}" \
    radius \
    "${radius}" \
    inner_radius \
    "${inner_radius}" \
    outer_radius \
    "${outer_radius}" \
    radius_x \
    "${radius_x}" \
    radius_y \
    "${radius_y}" \
    radius_z \
    "${radius_z}" \
    inner_radius_x \
    "${inner_radius_x}" \
    inner_radius_y \
    "${inner_radius_y}" \
    inner_radius_z \
    "${inner_radius_z}" \
    outer_radius_x \
    "${outer_radius_x}" \
    outer_radius_y \
    "${outer_radius_y}" \
    outer_radius_z \
    "${outer_radius_z}" \
    length_x \
    "${length_x}" \
    length_y \
    "${length_y}" \
    length_z \
    "${length_z}" \
    height \
    "${height}" \
    center_x \
    "${center_x}" \
    center_y \
    "${center_y}" \
    center_z \
    "${center_z}" \
    shift_x \
    "${shift_x}" \
    shift_y \
    "${shift_y}" \
    shift_z \
    "${shift_z}" \
    rotate_phi \
    "${rotate_phi}" \
    rotate_psi \
    "${rotate_psi}" \
    rotate_theta \
    "${rotate_theta}" \
    sigma \
    "${sigma}" \
    ref_fn \
    "${ref_fn_}" \
    output_fn \
    "${scratch_dir}/${output_fn}"

rm -rf ${mcr_cache_dir}

if [[ ! -f subTOM_protocol.md ]]
then
    touch subTOM_protocol.md
fi

printf "# Create Shape Volume\n" >> subTOM_protocol.md
printf -- "---------------------\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "OPTION" "VALUE" >> subTOM_protocol.md
printf "|:--------------------------" >> subTOM_protocol.md
printf "|:--------------------------|\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "scratch_dir" "${scratch_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "mcr_cache_dir" "${mcr_cache_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "exec_dir" "${exec_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "shape_exec" "${shape_exec}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "output_fn" "${output_fn}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "box_size" "${box_size}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "shape" "${shape}" >> subTOM_protocol.md

if [[ -n "${radius}" ]]
then
    printf "| %-25s | %25s |\n" "radius" "${radius}" >> subTOM_protocol.md
fi

if [[ -n "${height}" ]]
then
    printf "| %-25s | %25s |\n" "height" "${height}" >> subTOM_protocol.md
fi

if [[ -n "${inner_radius}" ]]
then
    printf "| %-25s | %25s |\n" "inner_radius" "${inner_radius}" >>\
        subTOM_protocol.md

fi

if [[ -n "${outer_radius}" ]]
then
    printf "| %-25s | %25s |\n" "outer_radius" "${outer_radius}" >>\
        subTOM_protocol.md

fi

if [[ -n "${radius_x}" ]]
then
    printf "| %-25s | %25s |\n" "radius_x" "${radius_x}" >> subTOM_protocol.md
fi

if [[ -n "${radius_y}" ]]
then
    printf "| %-25s | %25s |\n" "radius_y" "${radius_y}" >> subTOM_protocol.md
fi

if [[ -n "${radius_z}" ]]
then
    printf "| %-25s | %25s |\n" "radius_z" "${radius_z}" >> subTOM_protocol.md
fi

if [[ -n "${inner_radius_x}" ]]
then
    printf "| %-25s | %25s |\n" "inner_radius_x" "${inner_radius_x}" >>\
        subTOM_protocol.md

fi

if [[ -n "${inner_radius_y}" ]]
then
    printf "| %-25s | %25s |\n" "inner_radius_y" "${inner_radius_y}" >>\
        subTOM_protocol.md

fi

if [[ -n "${inner_radius_z}" ]]
then
    printf "| %-25s | %25s |\n" "inner_radius_z" "${inner_radius_z}" >>\
        subTOM_protocol.md

fi

if [[ -n "${outer_radius_x}" ]]
then
    printf "| %-25s | %25s |\n" "outer_radius_x" "${outer_radius_x}" >>\
        subTOM_protocol.md

fi

if [[ -n "${outer_radius_y}" ]]
then
    printf "| %-25s | %25s |\n" "outer_radius_y" "${outer_radius_y}" >>\
        subTOM_protocol.md

fi

if [[ -n "${outer_radius_z}" ]]
then
    printf "| %-25s | %25s |\n" "outer_radius_z" "${outer_radius_z}" >>\
        subTOM_protocol.md

fi

if [[ -n "${length_x}" ]]
then
    printf "| %-25s | %25s |\n" "length_x" "${length_x}" >> subTOM_protocol.md
fi

if [[ -n "${length_y}" ]]
then
    printf "| %-25s | %25s |\n" "length_y" "${length_y}" >> subTOM_protocol.md
fi

if [[ -n "${length_z}" ]]
then
    printf "| %-25s | %25s |\n" "length_z" "${length_z}" >> subTOM_protocol.md
fi

if [[ -n "${center_x}" ]]
then
    printf "| %-25s | %25s |\n" "center_x" "${center_x}" >> subTOM_protocol.md
fi

if [[ -n "${center_y}" ]]
then
    printf "| %-25s | %25s |\n" "center_y" "${center_y}" >> subTOM_protocol.md
fi

if [[ -n "${center_z}" ]]
then
    printf "| %-25s | %25s |\n" "center_z" "${center_z}" >> subTOM_protocol.md
fi

if [[ -n "${shift_x}" ]]
then
    printf "| %-25s | %25s |\n" "shift_x" "${shift_x}" >> subTOM_protocol.md
fi

if [[ -n "${shift_y}" ]]
then
    printf "| %-25s | %25s |\n" "shift_y" "${shift_y}" >> subTOM_protocol.md
fi

if [[ -n "${shift_z}" ]]
then
    printf "| %-25s | %25s |\n" "shift_z" "${shift_z}" >> subTOM_protocol.md
fi

if [[ -n "${rotate_phi}" ]]
then
    printf "| %-25s | %25s |\n" "rotate_phi" "${rotate_phi}" >>\
        subTOM_protocol.md

fi

if [[ -n "${rotate_psi}" ]]
then
    printf "| %-25s | %25s |\n" "rotate_psi" "${rotate_psi}" >>\
        subTOM_protocol.md

fi

if [[ -n "${rotate_theta}" ]]
then
    printf "| %-25s | %25s |\n" "rotate_theta" "${rotate_theta}" >>\
        subTOM_protocol.md

fi

if [[ -n "${sigma}" ]]
then
    printf "| %-25s | %25s |\n" "sigma" "${sigma}" >> subTOM_protocol.md
fi

if [[ -n "${ref_fn}" ]]
then
    printf "| %-25s | %25s |\n" "ref_fn" "${ref_fn}" >> subTOM_protocol.md
fi

printf "\n" >> subTOM_protocol.md
