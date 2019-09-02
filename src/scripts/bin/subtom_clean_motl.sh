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
# - subtom_clean_motl

# DRM 05-2019
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables

source "${1}"

if [[ ! -d "${mcr_cache_dir}" ]]
then
    mkdir -p "${mcr_cache_dir}"
fi

output_motl_dir="${scratch_dir}/$(dirname "${output_motl_fn}")"

if [[ ! -d "${output_motl_dir}" ]]
then
    mkdir -p "${output_motl_dir}"
fi

if [[ "${write_stats}" -eq 1 ]]
then
    output_stats_dir="${scratch_dir}/$(dirname "${output_stats_fn}")"

    if [[ ! -d "${output_stats_dir}" ]]
    then
        mkdir -p "${output_stats_dir}"
    fi
fi

ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
export LD_LIBRARY_PATH="${ldpath}"

mcr_cache_dir_="${mcr_cache_dir}/clean_motl"

if [[ -d "${mcr_cache_dir_}" ]]
then
    rm -rf "${mcr_cache_dir_}"
fi

export MCR_CACHE_ROOT="${mcr_cache_dir_}"

"${clean_motl_exec}" \
    input_motl_fn \
    "${scratch_dir}/${input_motl_fn}" \
    output_motl_fn \
    "${scratch_dir}/${output_motl_fn}" \
    tomo_row \
    "${tomo_row}" \
    do_ccclean \
    ${do_ccclean} \
    cc_fraction \
    ${cc_fraction} \
    cc_cutoff \
    ${cc_cutoff} \
    do_distance \
    ${do_distance} \
    distance_cutoff \
    ${distance_cutoff} \
    do_cluster \
    ${do_cluster} \
    cluster_distance \
    ${cluster_distance} \
    cluster_size \
    ${cluster_size} \
    do_edge \
    ${do_edge} \
    tomogram_dir \
    "${tomogram_dir}" \
    box_size \
    ${box_size} \
    write_stats \
    ${write_stats} \
    output_stats_fn \
    "${scratch_dir}/${output_stats_fn}"

rm -rf "${mcr_cache_dir_}"

if [[ ! -f subTOM_protocol.md ]]
then
    touch subTOM_protocol.md
fi

printf "# Clean Motive List\n" >> subTOM_protocol.md
printf -- "-------------------\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "OPTION" "VALUE" >> subTOM_protocol.md
printf "|:--------------------------" >> subTOM_protocol.md
printf "|:--------------------------|\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "scratch_dir" "${scratch_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "mcr_cache_dir" "${mcr_cache_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "exec_dir" "${exec_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "clean_motl_exec" "${clean_motl_exec}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "input_motl_fn" "${input_motl_fn}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "output_motl_fn" "${output_motl_fn}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "output_stats_fn" "${output_stats_fn}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "tomo_row" "${tomo_row}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "do_ccclean" "${do_ccclean}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "cc_fraction" "${cc_fraction}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "cc_cutoff" "${cc_cutoff}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "do_distance" "${do_distance}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "distance_cutoff" "${distance_cutoff}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "do_cluster" "${do_cluster}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "cluster_distance" "${cluster_distance}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "cluster_size" "${cluster_size}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "do_edge" "${do_edge}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "tomogram_dir" "${tomogram_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "box_size" "${box_size}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n\n" "write_stats" "${write_stats}" >>\
    subTOM_protocol.md

if [[ "${write_stats}" -eq 1 ]]
then
    printf "## Cleaning Statistics\n" >> subTOM_protocol.md
    printf -- "----------------------\n" >> subTOM_protocol.md
    printf "| %-35s | %35s |\n" "MEASURE" "VALUE" >> subTOM_protocol.md
    printf "|:------------------------------------" >> subTOM_protocol.md
    printf "|------------------------------------:|\n" >> subTOM_protocol.md
    awk -F, '{
        printf("| %-35s | %35d |\n", "Initial number of particles", $1);
        printf("| %-35s | %35d |\n", "Particles removed edge-cleaning", $2);
        printf("| %-35s | %35d |\n", "Particles removed cluster-cleaning", $3);
        printf("| %-35s | %35d |\n", "Particles removed distance-cleaning", $4);
        printf("| %-35s | %35d |\n", "Particles removed CC-cleaning", $5);
        printf("| %-35s | %35d |\n\n", "Final number of particles", $6);
    }' "${scratch_dir}/${output_stats_fn}" >> subTOM_protocol.md

fi
