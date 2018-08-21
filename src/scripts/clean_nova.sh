#!/bin/bash
################################################################################
# This is a script for cleaning up the huge amount of data that the CTF
# correction processing of electron cryo-tomograhpy data by means of the program
# novaCTF creates.
#
# This script is meant to run on a local workstation. It should run relatively
# quickly and there should be no real need to run it parallel on the cluster.
#
# The run script and all of the launch scripts are written in BASH. This is
# mainly because the behaviour of BASH is a bit more predictable. And it is not
# the 1970s any more.
#
# This processing script uses no MATLAB compiled functions
# DRM 08-2018
################################################################################
set -e
set -o nounset
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the folder with the input to be processed.
# Other paths are relative to this one.
scratch_dir=<SCRATCH_DIR>

################################################################################
#                                  VARIABLES                                   #
################################################################################
# The format string for the datasets to process. The string XXXIDXXXX will be
# replaced with the numbers specified between the range start_idx and end_idx
#tomo_fmt=TS_XXXIDXXXX_dose-filt
#tomo_fmt=TS_XXXIDXXXX
#tomo_fmt=ts_XXXIDXXXX
#tomo_fmt=ts_XXXIDXXXX_dose-filt
#tomo_fmt=XXXIDXXXX_dose-filt
tomo_fmt=<TOMO_FMT>

# The format string for the directory of datasets to process. The string
# XXXIDXXXX will be replaced with the numbers specified between the range
# start_idx and end_idx
#tomo_dir_fmt=TS_XXXIDXXXX
#tomo_dir_fmt=ts_XXXIDXXXX
#tomo_dir_fmt=XXXIDXXXX
tomo_dir_fmt=<TOMO_DIR_FMT>

# The first tomogram to operate on
start_idx=<START_IDX>

# The last tomogram to operate on.
end_idx=<END_IDX>

# The format string for the tomogram indexes. Likely two or three digit zero
# padding or maybe just flat integers.
idx_fmt="%02d" # two digit zero padding e.g. 01
#idx_fmt="%03d" # three digit zero padding e.g. 001
#idx_fmt="%d" # no padding flat integer e.g. 1

################################################################################
#                               NOVA CTF OPTIONS                               #
################################################################################
# Where the defocus list file is located. The string XXXIDXXXX will be replaced
# with the formatted tomogram index, i.e. XXXIDXXXX_output.txt will be turned
# into 01_output.txt.
#defocus_file=TS_XXXIDXXXX_output.txt
defocus_file=<DEFOCUS_FILE>

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
cd ${scratch_dir}

for idx in $(seq ${start_idx} ${end_idx})
do
    fmt_idx=$(printf ${idx_fmt} ${idx})
    tomo=${tomo_fmt/XXXIDXXXX/${fmt_idx}}
    tomo_dir=${tomo_dir_fmt/XXXIDXXXX/${fmt_idx}}
    tomo_defocus=${defocus_file/XXXIDXXXX/${fmt_idx}}

    if [[ -d ${tomo_dir} ]]
    then
        if [[ -f ${tomo_dir}/${tomo}_ctfcorr.st_0 ]]
        then
            rm ${tomo_dir}/${tomo}_ctfcorr.st_*
        fi

        if [[ -f ${tomo_dir}/${tomo}_ctfcorr.ali_0 ]]
        then
            rm ${tomo_dir}/${tomo}_ctfcorr.ali_*
        fi

        if [[ -f ${tomo_dir}/${tomo}_erased.ali_0 ]]
        then
            rm ${tomo_dir}/${tomo}_erased.ali_*
        fi

        if [[ -f ${tomo_dir}/${tomo}_filtered.ali_0 ]]
        then
            rm ${tomo_dir}/${tomo}_filtered.ali_*
        fi

        if [[ -f ${tomo_dir}/${tomo}_flipped.ali_0 ]]
        then
            rm ${tomo_dir}/${tomo}_flipped.ali_*
        fi

        if [[ -f ${tomo_dir}/${tomo_defocus}_0 ]]
        then
            rm ${tomo_dir}/${tomo_defocus}_*
        fi

        if [[ -f ${tomo_dir}/eraser.com_0 ]]
        then
            rm ${tomo_dir}/eraser.com_*
        fi

        if [[ -f ${tomo_dir}/eraser.log ]]
        then
            rm ${tomo_dir}/eraser.log
        fi

        if [[ -f ${tomo_dir}/eraser.log\~ ]]
        then
            rm ${tomo_dir}/eraser.log\~
        fi

        if [[ -f ${tomo_dir}/newst.com_0 ]]
        then
            rm ${tomo_dir}/newst.com_*
        fi

        if [[ -f ${tomo_dir}/newst.log ]]
        then
            rm ${tomo_dir}/newst.log
        fi

        if [[ -f ${tomo_dir}/newst.log\~ ]]
        then
            rm ${tomo_dir}/newst.log\~
        fi

        if [[ -f ${tomo_dir}/nova_ctfcorr.com_0 ]]
        then
            rm ${tomo_dir}/nova_ctfcorr.com_*
        fi

        if [[ -f ${tomo_dir}/nova_filter.com_0 ]]
        then
            rm ${tomo_dir}/nova_filter.com_*
        fi

        if [[ -f ${tomo_dir}/nova_defocus.com ]]
        then
            rm ${tomo_dir}/nova_defocus.com
        fi

        if [[ -f ${tomo_dir}/nova_reconstruct.com ]]
        then
            rm ${tomo_dir}/nova_reconstruct.com
        fi
    fi
done
