#!/bin/bash
################################################################################
# This is a run script for the standard AV3 subtomogram averaging scripts. The
# MATLAB executables for this script were compiled in MATLAB-8.5. The other
# difference is that these scripts have been edited to make sure that the output
# files from each step is readable.
#
# This script is meant to run on the scratch it copies the reference and final
# allmotl file to a local folder after each iteration.
#
# Also, the run script and all the launch scripts are written in bash. This is
# mainly because the behaviour of bash is a bit more predictable.
#
# This subtomogram multireference parallel averaging script uses three MATLAB
# compiled scripts below:
# - subtom_rand_class_motl
# - subtom_parallel_sums
# - subtom_weighted_average
# DRM 05-2019
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
set +o noclobber # Turn off preventing BASH overwriting files
unset ml
unset module

source "${1}"

if [[ ! -d "${mcr_cache_dir}" ]]
then
    mkdir -p "${mcr_cache_dir}"
fi

################################################################################
#                            CREATE INITIAL CLASSES                            #
################################################################################
ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
export LD_LIBRARY_PATH="${ldpath}"

mcr_cache_dir_rand_class="${mcr_cache_dir}/rand_class_motl"

if [[ ! -d "${mcr_cache_dir_rand_class}" ]]
then
    mkdir -p "${mcr_cache_dir_rand_class}"
else
    rm -rf "${mcr_cache_dir_rand_class}"
    mkdir -p "${mcr_cache_dir_rand_class}"
fi

export MCR_CACHE_ROOT="${mcr_cache_dir_rand_class}"

"${rand_exec}" \
    input_motl_fn \
    "${scratch_dir}/${input_motl_fn}" \
    output_motl_fn \
    "${scratch_dir}/${output_motl_fn}" \
    num_classes \
    "${num_classes}"

rm -rf "${mcr_cache_dir_rand_class}"

if [[ ! -f subTOM_protocol.md ]]
then
    touch subTOM_protocol.md
fi

printf "# Multireference Randomize MOTL Class\n" >> subTOM_protocol.md
printf -- "-------------------------------------\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "OPTION" "VALUE" >> subTOM_protocol.md
printf "|:--------------------------" >> subTOM_protocol.md
printf "|:--------------------------|\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "scratch_dir" "${scratch_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "mcr_cache_dir" "${mcr_cache_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "exec_dir" "${exec_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "rand_exec" "${rand_exec}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "input_motl_fn" "${input_motl_fn}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "output_motl_fn" "${output_motl_fn}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n\n" "num_classes" "${num_classes}" >>\
    subTOM_protocol.md
