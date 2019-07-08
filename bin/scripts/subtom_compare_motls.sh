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
# - subtom_compare_motls

# DRM 05-2019
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables

source "${1}"

mcr_cache_dir="${mcr_cache_dir}/compare_motls"

if [[ ! -d "${mcr_cache_dir}" ]]
then
    mkdir -p "${mcr_cache_dir}"
else
    rm -rf "${mcr_cache_dir}"
    mkdir -p "${mcr_cache_dir}"
fi

if [[ "${write_diffs}" -eq "1" ]]
then
    output_diffs_dir="${scratch_dir}/$(dirname "${output_diffs_fn}")"

    if [[ ! -d "${output_diffs_dir}" ]]
    then
        mkdir -p "${output_diffs_dir}"
    fi
fi

ldpath="/public/matlab/jbriggs/runtime/glnxa64"
ldpath="${ldpath}:/public/matlab/jbriggs/bin/glnxa64"
ldpath="${ldpath}:/public/matlab/jbriggs/sys/os/glnxa64"
ldpath="${ldpath}:/public/matlab/jbriggs/sys/opengl/lib/glnxa64"
export LD_LIBRARY_PATH="${ldpath}"

export MCR_CACHE_ROOT="${mcr_cache_dir}"

"${compare_motls_exec}" \
    motl_1_fn \
    "${scratch_dir}/${motl_1_fn}" \
    motl_2_fn \
    "${scratch_dir}/${motl_2_fn}" \
    write_diffs \
    ${write_diffs} \
    output_diffs_fn \
    "${scratch_dir}/${output_diffs_fn}"

rm -rf "${mcr_cache_dir}"
