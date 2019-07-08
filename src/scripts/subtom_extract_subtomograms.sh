#!/bin/bash
################################################################################
# This script takes an input number of cores, and each core extract one tomogram
# at a time as written in a specified row of the allmotl. Parallelization works
# by writing a start file upon openinig of a tomo, and a completion file. After
# tomogram extraction, it moves on to the next tomogram that hasn't been
# started.
#
# This script uses  MATLAB compiled script below:
# - subtom_extract_subtomograms
# DRM 05-2019
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the folder where the tomograms are stored
tomogram_dir=""

# Absolute path to the root folder for subtomogram extraction.
# Other paths are relative to this one.
scratch_dir="${PWD}"

# MCR directory for each job
mcr_cache_dir="${scratch_dir}/mcr"

# Directory for executables
exec_dir="XXXINSTALLATION_DIRXXX/bin"

################################################################################
#                                  VARIABLES                                   #
################################################################################
# subtomogram extraction executable
extract_exe="${exec_dir}/alignment/subtom_extract_subtomograms"

# MOTL dump executable
motl_dump_exec="${exec_dir}/MOTL/motl_dump"

################################################################################
#                                MEMORY OPTIONS                                #
################################################################################
# The amount of memory your job requires
# e.g. mem_free='10G'
mem_free="1G"

# The upper bound on the amount of memory your job is allowed to use
# e.g. mem_max='15G'
mem_max="64G"

################################################################################
#                              OTHER LSF OPTIONS                               #
################################################################################
# BE CAREFUL THAT THE NAME DOESN'T CORRESPOND TO THE BEGINNING OF ANY OTHER FILE
job_name="subTOM"

# If you want to skip the cluster and run the job locally set this to 1.
run_local="0"

################################################################################
#                                                                              #
#                    SUBTOMOGRAM EXTRACTION WORKFLOW OPTIONS                   #
#                                                                              #
################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# The iteration of the all particle motive list to extract from : input will be
# all_motl_fn_prefix_iteration.em (define as integer e.g. iteration=1)
iteration="1"

# Relative path to allmotl file from root folder.
all_motl_fn_prefix="combinedmotl/allmotl"

# Relative path and filename for output subtomograms.
subtomo_fn_prefix="subtomograms/subtomo"

# Relative path and filename for stats .csv files.
stats_fn_prefix="subtomograms/stats/tomo"

################################################################################
#                              TOMOGRAM OPTIONS                                #
################################################################################
# Row number of allmotl for tomogram numbers.
tomo_row="7"

################################################################################
#                             EXTRACTION OPTIONS                               #
################################################################################
# Size of subtomogram in pixels
box_size="128"

# Leading zeros for subtomograms, for AV3, use 1. Other numbers are useful for
# DYNAMO.
subtomo_digits="1"

# Set reextract to 1 if you want to force the program to re-extract subtomograms
# even if the stats file and the subtomograms already exist. If the stats file
# for the tomogram exists and is the correct size the whole tomogram will be
# skipped. If the subtomogram exists it will also be skipped, unless this option
# is true.
reextract="0"

# Set preload_tomogram to 1 if you want to read the whole tomogram into memory
# before extraction. This is the fastest way to extract particles however the
# system needs to be able to have the memory to fit the whole tomogram into
# memory or otherwise it will crash. If it is set to 0, then either the
# subtomograms can be extracted using a memory-map to the data, or read directly
# from the file.
preload_tomogram="1"

# Set use_tom_red to 1 if you want to use the AV3/TOM function tom_red to
# extract particles. This requires that preload_tomogram above is set to 1. This
# is the original way to extract particles, but it seemed to sometimes produce
# subtomograms that were incorrectly sized. If it is set to 0 then an inlined
# window function is used instead.
use_tom_red="0"

# Set use_memmap to 1 to memory-map the tomogram and read subtomograms from this
# map. This appears to be a little slower than having the tomogram fully in
# memory without the massive memory footprint. However, it also appears to be
# slightly unstable and may crash unexpectedly. If it is set to 0 and
# preload_tomogram is also 0, then subtomograms will be read directly from the
# tomogram on disk. This also requires much less memory, however it appears to
# be extremely slow, so this only makes sense for a large number of tomograms
# being extracted on the cluster.
use_memmap="0"

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    "${exec_dir}/scripts/subtom_extract_subtomograms.sh" "$(realpath $0)"
else
    echo "Options sourced!"
fi
