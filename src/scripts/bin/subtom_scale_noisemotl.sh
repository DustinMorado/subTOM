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
# - subtom_scale_motl
# - subtom_split_motl_by_row

# DRM 09-2019
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables

source "${1}"

if [[ ! -d "${mcr_cache_dir}" ]]
then
    mkdir -p "${mcr_cache_dir}"
fi

output_noise_motl_dir="${scratch_dir}/$(dirname \
    "${output_noise_motl_fn_prefix}")"

if [[ ! -d "${output_noise_motl_dir}" ]]
then
    mkdir -p "${output_noise_motl_dir}"
fi

tomo_idxs=($("${motl_dump_exec}" --row ${tomo_row} \
    "${scratch_dir}/${all_motl_fn_prefix}_${iteration}.em" | sort -nr | uniq))

if [[ ${tomo_idxs[0]} -ge 1000 ]]
then
    fmt_idx="%04d"
elif [[ ${tomo_idxs[0]} -ge 100 ]]
then
    fmt_idx="%03d"
elif [[ ${tomo_idxs[0]} -ge 10 ]]
then
    fmt_idx="%02d"
else
    fmt_idx="%d"
fi

for (( idx = 0; idx < ${#tomo_idxs[@]}; idx++ ))
do
    input_fn="${scratch_dir}/${input_noise_motl_fn_prefix}"
    input_fn="${input_fn}_$(printf "%d" "${tomo_idxs[${idx}]}").em"
    input_noise_motl_fns[${idx}]="${input_fn}"
done

ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
export LD_LIBRARY_PATH="${ldpath}"

mcr_cache_dir_="${mcr_cache_dir}/cat_motls"

if [[ -d "${mcr_cache_dir_}" ]]
then
    rm -rf "${mcr_cache_dir_}"
fi

export MCR_CACHE_ROOT="${mcr_cache_dir_}"

"${cat_motls_exec}" \
    write_motl \
    1 \
    output_motl_fn \
    "${scratch_dir}/${output_noise_motl_fn_prefix}_all_unscaled.em" \
    write_star \
    0 \
    sort_row \
    4 \
    do_quiet \
    1 \
    ${input_noise_motl_fns[*]}

rm -rf "${mcr_cache_dir_}"

mcr_cache_dir_="${mcr_cache_dir}/scale_motl"

if [[ -d "${mcr_cache_dir_}" ]]
then
    rm -rf "${mcr_cache_dir_}"
fi

export MCR_CACHE_ROOT="${mcr_cache_dir_}"

"${scale_motl_exec}" \
    input_motl_fn \
    "${scratch_dir}/${output_noise_motl_fn_prefix}_all_unscaled.em" \
    output_motl_fn \
    "${scratch_dir}/${output_noise_motl_fn_prefix}_all_scaled.em" \
    scale_factor \
    "${scale_factor}"

rm -rf "${mcr_cache_dir_}"

mcr_cache_dir_="${mcr_cache_dir}/split_motl_by_row"

if [[ -d "${mcr_cache_dir_}" ]]
then
    rm -rf "${mcr_cache_dir_}"
fi

export MCR_CACHE_ROOT="${mcr_cache_dir_}"

"${split_motl_by_row_exec}" \
    input_motl_fn \
    "${scratch_dir}/${output_noise_motl_fn_prefix}_all_scaled.em" \
    output_motl_fn_prefix \
    "${scratch_dir}/${output_noise_motl_fn_prefix}" \
    split_row \
    "${tomo_row}"

rm -rf "${mcr_cache_dir_}"
rm -f "${scratch_dir}/${output_noise_motl_fn_prefix}_all_unscaled.em"
rm -f "${scratch_dir}/${output_noise_motl_fn_prefix}_all_scaled.em"

for (( idx = 0; idx < ${#tomo_idxs[@]}; idx++ ))
do
    split_fn="${scratch_dir}/${output_noise_motl_fn_prefix}"
    split_fn="${split_fn}_$(printf "${fmt_idx}" "${tomo_idxs[${idx}]}").em"
    output_fn="${scratch_dir}/${output_noise_motl_fn_prefix}"
    output_fn="${output_fn}_${tomo_idxs[${idx}]}.em"

    if [[ "${split_fn}" != "${output_fn}" ]]
    then
        mv "${split_fn}" "${output_fn}"
    fi
done

if [[ ! -f subTOM_protocol.md ]]
then
    touch subTOM_protocol.md
fi

printf "# Scale Noise Motive List\n" >> subTOM_protocol.md
printf -- "-------------------\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "OPTION" "VALUE" >> subTOM_protocol.md
printf "|:--------------------------" >> subTOM_protocol.md
printf "|:--------------------------|\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "scratch_dir" "${scratch_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "mcr_cache_dir" "${mcr_cache_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "exec_dir" "${exec_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "cat_motls_exec" "${cat_motls_exec}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "scale_motl_exec" "${scale_motl_exec}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "split_motl_by_row_exec" \
    "${split_motl_by_row_exec}" >> subTOM_protocol.md

printf "| %-25s | %25s |\n" "motl_dump_exec" "${motl_dump_exec}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "iteration" "${iteration}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "all_motl_fn_prefix" "${all_motl_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "input_noise_motl_fn_prefix" \
    "${input_noise_motl_fn_prefix}" >> subTOM_protocol.md

printf "| %-25s | %25s |\n" "output_noise_motl_fn_prefix" \
    "${output_noise_motl_fn_prefix}" >> subTOM_protocol.md

printf "| %-25s | %25s |\n" "tomo_row" "${tomo_row}" >> subTOM_protocol.md

printf "| %-25s | %25s |\n\n" "scale_factor" "${scale_factor}" >>\
    subTOM_protocol.md
