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
# - clean_motl

# DRM 12-2017
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the folder with the input to be processed.
# Other paths are relative to this one.
scratch_dir=<SCRATCH_DIR>

# Absolute path to MCR directory for the processing.
mcr_cache_dir=${scratch_dir}/mcr

# Directory for executables
exec_dir=XXXINSTALLATION_DIRXXX/bin

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative or absolute path and name of the input MOTL file to be cleaned.
input_motl_fn=<INPUT_MOTL_FN>

# Relative or absolute path and name of the output MOTL file.
output_motl_fn=<OUTPUT_MOTL_FN>

################################################################################
#                                  VARIABLES                                   #
################################################################################
# clean_motl executable
clean_motl_exec=${exec_dir}/clean_motl

################################################################################
#                                CLEAN OPTIONS                                 #
################################################################################
# Which row in the motl file contains the correct tomogram number.
# Usually row 5 and 7 both correspond to the correct value and can be used
# interchangeably, but there are instances when 5 contains a sequential ordered
# value starting from 1, while 7 contains the correct corresponding tomogram.
tomo_row=7

# If the following is set to 1 then the MOTL will be cleaned by CCC either by
# CCC value or a fraction of the highest CCC values to keep. If it is set to 0
# then CCC cleaning will be skipped.
do_cclean=0

# If cleaning by CC then after edge, cluster, and distance cleaning, if any are
# selected, is completed. The MOTL will be sorted by CCC and then the top
# fraction as specified here will be kept with the rest discarded. For example
# if cc_fraction=0.7 the top 70% of the clean data will be kept and the bottom
# 30% of the cleaned data will be discarded. A value of 1 here means that data
# is not cleaned by CCC fraction.
cc_fraction=1

# If cc_fraction is 1 and therefore not used then particles with a CCC below
# this cutoff will be removed from the output MOTL file. Values must be within
# -1 to 1, with -1 not removing any particles.
cc_cutoff=-1

# If the following is set to 1 then the MOTL will be cleaned by distance. If it
# is set to 0 distance cleaning will be skipped.
do_distance=0

# Particles that are less than this distance in pixels from another particle
# will be cleaned with the particle with the highest CCC kept while the others
# are removed from the output MOTL file.
distance_cutoff=0

# If the following is set to 1 then the MOTL will be cleaned by a clustering
# criteria that enforces kept particles to exist as clusters. This can be useful
# when there is no lattice and clusters of particles makes a good indication
# that a true copy of the reference exists there. If it is set to 0 cluster
# cleaning will be skipped.
do_cluster=0

# The following determines the radius that defines what is considered a cluster
# in cluster cleaning.
cluster_distance=0

# The cluster size specifies how many particles must be found within
# cluster_distance for the particle to be considered part of a cluster. The
# particle with the highest CCC in the cluster will be selected as the
# representative particle for the cluster and the remaining clustered points
# will be removed.
cluster_size=1

# If the following is set to 1 then the MOTL will be edge cleaned considering
# the dimensions of the tomogram in which the particles are contained. If any
# part of the particle exists outside of the tomogram it will be removed from
# the MOTL. If it is set to 0 edge cleaning will be skipped.
do_edge=0

# Absolute path to the folder where the tomograms are stored. If you are not
# edge cleaning set this to 'none'
tomogram_dir='none'

# What is the boxsize of the particle that will be extracted from the tomogram,
# which is necessary to specify to be able to edge clean.
boxsize=128
################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
cd ${scratch_dir}
mcr_cache_dir=${mcr_cache_dir}/clean_motl
if [[ ! -d ${mcr_cache_dir} ]]
then
    mkdir -p ${mcr_cache_dir}
else
    rm -rf ${mcr_cache_dir}
    mkdir -p ${mcr_cache_dir}
fi

if [[ ! -d $(dirname ${output_motl_fn}) ]]
then
    mkdir -p $(dirname ${output_motl_fn})
fi

ldpath=XXXMCR_DIRXXX/runtime/glnxa64
ldpath=${ldpath}:XXXMCR_DIRXXX/bin/glnxa64
ldpath=${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64
ldpath=${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=${ldpath}
export MCR_CACHE_ROOT=${mcr_cache_dir}
time ${clean_motl_exec} \
    ${input_motl_fn} \
    ${output_motl_fn} \
    ${tomo_row} \
    ${do_cclean} \
    ${cc_fraction} \
    ${cc_cutoff} \
    ${do_distance} \
    ${distance_cutoff} \
    ${do_cluster} \
    ${cluster_distance} \
    ${cluster_size} \
    ${do_edge} \
    ${tomogram_dir} \
    ${boxsize}
rm -rf ${mcr_cache_dir}
