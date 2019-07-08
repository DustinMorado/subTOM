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
# - subtom_scale_motl

# DRM 05-2019
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables

source "${1}"

mcr_cacher_dir="${mcr_cache_dir}/scale_motl"

if [[ ! -d "${mcr_cache_dir}" ]]
then
    mkdir -p "${mcr_cache_dir}"
else
    rm -rf "${mcr_cache_dir}"
    mkdir -p "${mcr_cache_dir}"
fi

output_motl_dir="${scratch_dir}/$(dirname "${output_motl_fn}")"

if [[ ! -d "${output_motl_dir}" ]]
then
    mkdir -p "${output_motl_dir}"
fi

ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
export LD_LIBRARY_PATH="${ldpath}"

export MCR_CACHE_ROOT="${mcr_cache_dir}"

"${scale_motl_exec}" \
    input_motl_fn \
    "${scratch_dir}/${input_motl_fn}" \
    output_motl_fn \
    "${scratch_dir}/${output_motl_fn}" \
    scale_factor \
    "${scale_factor}"

rm -rf ${mcr_cache_dir}

if [[ ! -f subTOM_protocol.md ]]
then
    touch subTOM_protocol.md
fi

printf "# Scale Motive List\n" >> subTOM_protocol.md
printf -- "-------------------\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "OPTION" "VALUE" >> subTOM_protocol.md
printf "|:--------------------------" >> subTOM_protocol.md
printf "|:--------------------------|\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "scratch_dir" "${scratch_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "mcr_cache_dir" "${mcr_cache_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "exec_dir" "${exec_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "scale_motl_exec" "${scale_motl_exec}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "input_motl_fn" "${input_motl_fn}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "output_motl_fn" "${output_motl_fn}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n\n" "scale_factor" "${scale_factor}" >>\
    subTOM_protocol.md
