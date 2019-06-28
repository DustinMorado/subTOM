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

# DRM 05-2019
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the folder with the input to be processed.
# Other paths are relative to this one.
scratch_dir="${PWD}"

# Absolute path to MCR directory for the processing.
mcr_cache_dir="${scratch_dir}/mcr"

# Directory for executables
exec_dir="XXXINSTALLATION_DIRXXX/bin"

################################################################################
#                                  VARIABLES                                   #
################################################################################
# clean_motl executable
clean_motl_exec="${exec_dir}/MOTL/subtom_clean_motl"

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name of the input MOTL file to be cleaned.
input_motl_fn="combinedmotl/allmotl_1.em"

# Relative path and name of the output MOTL file.
output_motl_fn="combinedmotl/allmotl_1_clean.em"

# Relative path and name of the optional output cleaning stats CSV file. If you
# do not want to write out the differences just leave this as "".
output_stats_fn="combinedmotl/allmotl_1_clean_stats.csv"

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
do_ccclean=0

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
# edge cleaning leave this set to "".
tomogram_dir=""

# What is the boxsize of the particle that will be extracted from the tomogram,
# which is necessary to specify to be able to edge clean.
boxsize=128

# If the following is 1 then the details of how many particles were cleaned in
# each stage will be written out, if 0 then not.
write_stats="1"

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    "${exec_dir}/scripts/subtom_clean_motl.sh" "$(realpath $0)"
else
    echo "Options sourced!"
fi
