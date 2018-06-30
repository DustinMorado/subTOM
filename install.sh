#!/bin/bash
if [[ $# -ne 2 || $1 == '-h' || $1 == '--help' ]]
then
    echo USAGE: install.sh <INSTALL_DIR> <MCR_DIR>
    echo     Example: ./install.sh ~/software/bw3 ~/opt/MCR/2016b/v91
    exit 0
fi

for i in scripts/*.sh
do
    sed -i -e "s/XXXINSTALL_DIRXXX/${1}/g" \
           -e "s/XXXMCR_DIRXXX/${2}/g" \
           ${i}
done
