#!/bin/bash
################################################################################
# This is a run script for calculating the mask-corrected FSC curves and joined
# maps outside of the Matlab environment.
#
# This script is meant to run on a local workstation with access to an X server
# in the case when the user wants to display figures. I am unsure if both
# plotting options are disabled if the graphics display is still required, but
# if not it could be run remotely on the cluster, but it shouldn't be necessary.
#
# This script uses just one MATLAB compiled scripts below:
# - subtom_maskcorrected_FSC
#
# DRM 05-2019
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables

source "${1}"

mcr_cache_dir="${mcr_cache_dir}/maskcorrected_FSC"

if [[ ! -d "${mcr_cache_dir}" ]]
then
    mkdir -p "${mcr_cache_dir}"
else
    rm -rf "${mcr_cache_dir}"
    mkdir -p "${mcr_cache_dir}"
fi

output_dir="${scratch_dir}/$(dirname "${output_fn_prefix}")"

if [[ ! -d "${output_dir}" ]]
then
    mkdir -p "${output_dir}"
fi

ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
export LD_LIBRARY_PATH="${ldpath}"

export MCR_CACHE_ROOT="${mcr_cache_dir}"

"${fsc_exec}" \
    ref_a_fn_prefix \
    "${scratch_dir}/${ref_a_fn_prefix}" \
    ref_b_fn_prefix \
    "${scratch_dir}/${ref_b_fn_prefix}" \
    iteration \
    "${iteration}" \
    fsc_mask_fn \
    "${scratch_dir}/${fsc_mask_fn}" \
    output_fn_prefix \
    "${scratch_dir}/${output_fn_prefix}" \
    filter_a_fn \
    "${scratch_dir}/${filter_a_fn}" \
    filter_b_fn \
    "${scratch_dir}/${filter_b_fn}" \
    do_reweight \
    "${do_reweight}" \
    do_sharpen \
    "${do_sharpen}" \
    plot_fsc \
    "${plot_fsc}" \
    plot_sharpen \
    "${plot_sharpen}" \
    filter_mode \
    "${filter_mode}" \
    pixelsize \
    "${pixelsize}" \
    nfold \
    "${nfold}" \
    filter_threshold \
    "${filter_threshold}" \
    rand_threshold \
    "${rand_threshold}" \
    b_factor \
    "${b_factor}" \
    box_gaussian \
    "${box_gaussian}"

rm -rf "${mcr_cache_dir}"

if [[ ! -f subTOM_protocol.md ]]
then
    touch subTOM_protocol.md
fi

printf "# Mask Corrected FSC Iteration %d\n" "${iteration}" >>\
    subTOM_protocol.md

printf -- "---------------------------------\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "OPTION" "VALUE" >> subTOM_protocol.md
printf "|:--------------------------" >> subTOM_protocol.md
printf "|--------------------------:|\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "scratch_dir" "${scratch_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "mcr_cache_dir" "${mcr_cache_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "exec_dir" "${exec_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "fsc_exec" "${fsc_exec}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "ref_a_fn" "${ref_a_fn_prefix}_${iteration}.em" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "ref_b_fn" "${ref_b_fn_prefix}_${iteration}.em" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "fsc_mask_fn" "${fsc_mask_fn}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "filter_a_fn" "${filter_a_fn}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "filter_b_fn" "${filter_b_fn}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "output_fn_prefix" "${output_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "pixelsize" "${pixelsize}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "nfold" "${nfold}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "rand_threshold" "${rand_threshold}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "plot_fsc" "${plot_fsc}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "do_sharpen" "${do_sharpen}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "b_factor" "${b_factor}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "box_gaussian" "${box_gaussian}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "filter_mode" "${filter_mode}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "filter_threshold" "${filter_threshold}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "plot_sharpen" "${plot_sharpen}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n\n" "do_reweight" "${do_reweight}" >>\
    subTOM_protocol.md
