#!/bin/bash
if [[ $# -ne 2 || $1 == '-h' || $1 == '--help' ]]
then
    echo 'USAGE: install.sh <INSTALL_DIR> <MCR_DIR>'
    echo     Example: ./install.sh ~/software/subTOM ~/opt/MCR/2016b/v91
    exit 0
fi

# Strip off trailing slashes if they exist
install_dir="${1%/}"
mcr_dir="${2%/}"

if [[ ! -d "${install_dir}/scripts" ]]
then
    mkdir "${install_dir}/scripts"
fi

if [[ ! -d "${install_dir}/bin/scripts" ]]
then
    mkdir "${install_dir}/bin/scripts"
fi

for script_fn in "${install_dir}/src/scripts/"*.sh
do
    sed -e "s:XXXINSTALLATION_DIRXXX:${install_dir}:g" "${script_fn}" >\
        "${install_dir}/scripts/$(basename "${script_fn}")"

done

for script_fn in "${install_dir}/src/scripts/bin/"*.sh
do
    sed -e "s:XXXMCR_DIRXXX:${mcr_dir}:g" "${script_fn}" >\
        "${install_dir}/bin/scripts/$(basename "${script_fn}")"

    chmod u+x "${install_dir}/bin/scripts/$(basename "${script_fn}")"
done
