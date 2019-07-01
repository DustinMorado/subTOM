#!/bin/bash
################################################################################
# This script finds and extracts noise particles from tomograms and generates
# amplitude spectrum volumes for used in Fourier reweighting of particles in the
# subtomogram alignment and averaging routines.
#
# It also generates a noise motl file so that the noise positions found in
# binned tomograms can then be used later on in less or unbinned tomograms and
# after some positions have been cleaned, which could make it more difficult to
# pick non-structural noise in the tomogram.
#
# This tomogram extraction script uses one MATLAB compiled script below:
# - subtom_extract_noise
# DRM 05-2019
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the folder where the tomograms are stored
tomogram_dir=""

# Absolute path to the root folder for subtomogram extraction.
# Other paths are relative to this one.
scratch_dir="${PWD}"

# Absolute path to the MCR directory for each job
mcr_cache_dir="${scratch_dir}/mcr"

# Absolute path to the directory for executables
exec_dir="XXXINSTALLATION_DIRXXX/bin"

################################################################################
#                                  VARIABLES                                   #
################################################################################
# Noise extraction executable
noise_extract_exe="${exec_dir}/alignment/subtom_extract_noise"

# MOTL dump executable
motl_dump_exec="${exec_dir}/MOTL/motl_dump"

################################################################################
#                                MEMORY OPTIONS                                #
################################################################################
# The amount of memory your job requires
# e.g. mem_free='10G'
mem_free="1G"

# The upper bound on the amount of memory your job is allowed to use
#mem_max='15G'
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
#                      NOISE EXTRACTION WORKFLOW OPTIONS                       #
#                                                                              #
################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# The iteration of the all particle motive list to extract from : input will be
# all_motl_fn_prefix_iteration.em (define as integer e.g. iteration=1)
iteration="1"

# Relative path to allmotl file from root folder.
all_motl_fn_prefix="combinedmotl/allmotl"

# Relative path to noisemotl filename. If the file doesn't exist a
# new one will be written with the determined noise positions. If a previously
# existing noise motl exists it will be used instead. If the number of noise
# particles requested has been increased new particles will be found and added
# and the file will be updated.
noise_motl_fn_prefix="combinedmotl/noisemotl"

# Relative path and filename prefix for output amplitude spectrums
ampspec_fn_prefix="otherinputs/ampspec"

# Relative path and filename prefix for output binary wedges
binary_fn_prefix="otherinputs/binary"

################################################################################
#                              TOMOGRAM OPTIONS                                #
################################################################################
# Row number of allmotl for tomogram numbers.
tomo_row="7"

################################################################################
#                             EXTRACTION OPTIONS                               #
################################################################################
# Size of subtomogram in pixels
boxsize="128"

# If you already have noise MOTL lists calculated which may contain less than
# the total number of requested noise, but just want the code to do the
# extraction then you can set just_extract to 1. Otherwise set it to 0.
just_extract="0"

# The amount of overlap to allow between noise particles and subtomograms
# Numbers less than 0 will allow for larger than a box size spacing between
# noise and a particle. Numbers greater than 0 will allow for some overlap
# between noise and a particle. For example 0.5 will allow 50% overlap between
# the noise and the particle, which can be useful when the boxsize is much
# larger than the particle.
ptcl_overlap_factor="0"

# The amount of overlap to allow between noise particles Numbers less than 0
# will allow for larger than a box size spacing between noise. Numbers greater
# than 0 will allow for some overlap between noise. For example 0.75 will allow
# 75% overlap between the noise, which can be useful when there is not much
# space for enough noise.
noise_overlap_factor="0"

# Number of noise particles to extract
num_noise="1000"

# Set reextract to 1 if you want to force the program to re-extract amplitude
# spectra even if the amplitude spectrum file already exists. 
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
    ${exec_dir}/scripts/subtom_extract_noise.sh "$(realpath $0)"
else
    echo "Options sourced!"
fi
