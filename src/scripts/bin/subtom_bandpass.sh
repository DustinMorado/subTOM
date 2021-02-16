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
# - subtom_bandpass

# DRM 02-2021
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables

source "${1}"

if [[ ! -d "${mcr_cache_dir}" ]]
then
    mkdir -p "${mcr_cache_dir}"
fi

if [[ -n "${filter_fn}" ]]
then
    filter_dir="${scratch_dir}/$(dirname "${filter_fn}")"

    if [[ ! -d "${filter_dir}" ]]
    then
        mkdir -p "${filter_dir}"
    fi

    filter_fn="${scratch_dir}/${filter_fn}"
else
    filter_fn=""
fi

if [[ -n "${output_fn}" ]]
then
    output_dir="${scratch_dir}/$(dirname "${output_fn}")"

    if [[ ! -d "${output_dir}" ]]
    then
        mkdir -p "${output_dir}"
    fi

    output_fn="${scratch_dir}/${output_fn}"
else
    output_fn=""
fi

ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
export LD_LIBRARY_PATH="${ldpath}"

mcr_cache_dir_="${mcr_cache_dir}/bandpass"

if [[ -d "${mcr_cache_dir_}" ]]
then
    rm -rf "${mcr_cache_dir_}"
fi

export MCR_CACHE_ROOT="${mcr_cache_dir_}"

"${bandpass_exec}" \
    input_fn \
    "${scratch_dir}/${input_fn}" \
    high_pass_fp \
    "${high_pass_fp}" \
    high_pass_sigma \
    "${high_pass_sigma}" \
    low_pass_fp \
    "${low_pass_fp}" \
    low_pass_sigma \
    "${low_pass_sigma}" \
    filter_fn \
    "${filter_fn}" \
    output_fn \
    "${output_fn}"

rm -rf "${mcr_cache_dir_}"

if [[ ! -f subTOM_protocol.md ]]
then
    touch subTOM_protocol.md
fi

printf "# Create / Apply Bandpass Filter Volume\n" >> subTOM_protocol.md
printf -- "---------------------\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "OPTION" "VALUE" >> subTOM_protocol.md
printf "|:--------------------------" >> subTOM_protocol.md
printf "|:--------------------------|\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "scratch_dir" "${scratch_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "mcr_cache_dir" "${mcr_cache_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "exec_dir" "${exec_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "bandpass_exec" "${bandpass_exec}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "input_fn" "${input_fn}" >> subTOM_protocol.md

if [[ -n "${filter_fn}" ]]
then
    printf "| %-25s | %25s |\n" "filter_fn" "${filter_fn}" >> subTOM_protocol.md
fi

if [[ -n "${output_fn}" ]]
then
    printf "| %-25s | %25s |\n" "output_fn" "${output_fn}" >> subTOM_protocol.md
fi

printf "| %-25s | %25s |\n" "high_pass_fp" "${high_pass_fp}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "high_pass_sigma" "${high_pass_sigma}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "low_pass_fp" "${low_pass_fp}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "low_pass_sigma" "${low_pass_sigma}" >>\
    subTOM_protocol.md
printf "\n" >> subTOM_protocol.md
