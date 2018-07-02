#!/bin/bash
if [[ $# -ne 2 || $1 == '-h' || $1 == '--help' ]]
then
    echo 'USAGE: install.sh <INSTALL_DIR> <MCR_DIR>'
    echo     Example: ./install.sh ~/software/SubSECT ~/opt/MCR/2016b/v91
    exit 0
fi

for i in ${1}/src/scripts/*.sh
do
    sed -e "s:XXXINSTALLATION_DIRXXX:${1}:g" \
        -e "s:XXXMCR_DIRXXX:${2}:g" \
        ${i} > ${1}/scripts/$(basename ${i})
done
