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
# - subtom_cat_motls

# DRM 05-2019
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables

source "${1}"

if [[ ! -d "${mcr_cache_dir}" ]]
then
    mkdir -p "${mcr_cache_dir}"
fi

if [[ "${write_motl}" -eq 1 ]]
then
    output_motl_dir="${scratch_dir}/$(dirname "${output_motl_fn}")"

    if [[ ! -d "${output_motl_dir}" ]]
    then
        mkdir -p "${output_motl_dir}" ]]
    fi
fi

if [[ "${write_star}" -eq 1 ]]
then
    output_star_dir="${scratch_dir}/$(dirname "${output_star_fn}")"

    if [[ ! -d "${output_star_dir}" ]]
    then
        mkdir -p "${output_star_dir}" ]]
    fi
fi

num_input_motl_fns=${#input_motl_fns[@]}

for (( idx = 0; idx < num_input_motl_fns; idx++ ))
do
    input_motl_fns_[${idx}]="${scratch_dir}/${input_motl_fns[${idx}]}"
done

ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
export LD_LIBRARY_PATH="${ldpath}"

mcr_cache_dir="${mcr_cache_dir}/cat_motls"

if [[ ! -d "${mcr_cache_dir}" ]]
then
    mkdir -p "${mcr_cache_dir}"
else
    rm -rf "${mcr_cache_dir}"
    mkdir -p "${mcr_cache_dir}"
fi

export MCR_CACHE_ROOT="${mcr_cache_dir}"

"${cat_motls_exec}" \
    write_motl \
    "${write_motl}" \
    output_motl_fn \
    "${scratch_dir}/${output_motl_fn}" \
    write_star \
    "${write_star}" \
    output_star_fn \
    "${output_star_fn}" \
    sort_row \
    "${sort_row}" \
    do_quiet \
    "${do_quiet}" \
    ${input_motl_fns_[*]}

rm -rf "${mcr_cache_dir}"

if [[ ! -f subTOM_protocol.md ]]
then
    touch subTOM_protocol.md
fi

printf "# Concatenate Motive Lists\n" >> subTOM_protocol.md
printf -- "--------------------------\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "OPTION" "VALUE" >> subTOM_protocol.md
printf "|:--------------------------" >> subTOM_protocol.md
printf "|--------------------------:|\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "scratch_dir" "${scratch_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "mcr_cache_dir" "${mcr_cache_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "exec_dir" "${exec_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "cat_motls_exec" "${cat_motls_exec}" >>\
    subTOM_protocol.md

for input_motl_fn in ${input_motl_fns[@]}
do
    printf "| %-25s | %25s |\n" "input_motl_fn" "${input_motl_fn}" >>\
        subTOM_protocol.md

done

printf "| %-25s | %25s |\n" "output_motl_fn" "${output_motl_fn}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "output_star_fn" "${output_star_fn}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "write_motl" "${write_motl}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "write_star" "${write_star}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "sort_row" "${sort_row}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n\n" "do_quiet" "${do_quiet}" >> subTOM_protocol.md
