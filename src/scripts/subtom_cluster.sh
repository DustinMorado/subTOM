#!/bin/bash
################################################################################
# This is a run script for the standard AV3 subtomogram classification scripts.
# The MATLAB executables for this script were compiled in MATLAB-8.5. The other
# difference is that these scripts have been edited to make sure that the output
# files from each step is readable.
#
# This script is meant to run on the scratch it copies the reference and final
# allmotl file to a local folder after each iteration.
#
# Also, the run script and all the launch scripts are written in bash. This is
# mainly because the behaviour of bash is a bit more predictable.
#
# If the number of alignment jobs is greater than 1000, this script
# automatically splits the job into multiple arrays and launches them. It will
# not run if you have more than 4000 alignment jobs, as this is the current
# maximum per user.
#
# This subtomogram averaging script uses three MATLAB compiled scripts below:
# - subtom_cluster
# - subtom_parallel_sums_cls
# - subtom_weighted_average_cls
# DRM 05-2019
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the root folder for subtomogram extraction.
# Other paths are relative to this one.
scratch_dir="${PWD}"

# Absolute path to the folder on a group share, if your scratch directory is
# cleaned and deleted regularly you can set a local directory to which you can
# copy the important results. If you do not need to do this, you can skip this
# step with the option skip_local_copy below.
local_dir=""

# Absolute path to the MCR directory for each job.
mcr_cache_dir="${scratch_dir}/mcr"

# Directory for executables.
exec_dir="XXXINSTALLATION_DIRXXX/bin"

################################################################################
#                                  VARIABLES                                   #
################################################################################
# Cluster executable.
cluster_exec="${exec_dir}/classification/general/subtom_cluster"

# Parallel Summing executable
sum_exec="${exec_dir}/classification/general/subtom_parallel_sums_cls"

# Final Averaging executable
avg_exec="${exec_dir}/classification/general/subtom_weighted_average_cls"

################################################################################
#                                MEMORY OPTIONS                                #
################################################################################
# The amount of memory your job requires
# e.g. mem_free_ali='2G'
mem_free="1G"

# The upper bound on the amount of memory your job is allowed to use
# e.g. mem_max_ali='3G'
mem_max="64G"

################################################################################
#                              OTHER LSF OPTIONS                               #
################################################################################
# BE CAREFUL THAT THE NAME DOESN'T CORRESPOND TO THE BEGINNING OF ANY OTHER FILE
job_name="subTOM"

# Maximum number of jobs per array
array_max="1000"

# Maximum number of jobs per user
max_jobs="4000"

# If you want to skip the cluster and run the job locally set this to 1.
run_local="0"

# If you want to skip the copying of data to local_dir set this to 1.
skip_local_copy="1"

################################################################################
#                           PARALLELIZATION OPTIONS                            #
################################################################################
# The index of the references to generate : input will be
# all_motl_fn_prefix_iteration.em (define as integer e.g. iteration=1)
iteration="1"

# Number of batches to split the parallel subtomogram averaging job into
num_avg_batch="1"

################################################################################
#                                                                              #
#                 SUBTOMOGRAM CLASSIFICATION WORKFLOW OPTIONS                  #
#                                                                              #
################################################################################
#                           COEFFICIENT FILE OPTIONS                           #
################################################################################
# Relative path and name of the concatenated motivelist to cluster and classify.
coeff_all_motl_fn_prefix="combinedmotl/allmotl"

# Relative path and name of the coefficients.
coeff_fn_prefix="class/coeffs"

################################################################################
#                              CLUSTERING OPTIONS                              #
################################################################################
# The following determines which algorithm will be used to cluster the
# determined coefficients. The valid options are K-means clustering, 'kmeans',
# Hierarchical Ascendent Clustering using a Ward Criterion, 'hac', and a
# Gaussian Mixture Model, 'gaussmix'.
cluster_type="kmeans"

# Determines which coefficients are used to cluster. The format should be a
# semicolon-separated list that also supports ranges with a dash (-), for
# example 1-5;7;15-19 would select the first five coefficients, the seventh and
# the fifteenth through the nineteenth for classification. If it is left as
# "all" all coefficients will be used.
coeff_idxs="all"

# How many classes should the particles be clustered into.
num_classes=2

################################################################################
#                           CLUSTERING FILE OPTIONS                            #
################################################################################
# Relative path and name of the concatenated motivelist of the output classified
# particles.
cluster_all_motl_fn_prefix="class/allmotl_class"

################################################################################
#                            AVERAGING FILE OPTIONS                            #
################################################################################
# Relative path and name of the subtomograms (e.g. part_n.em , the variable will
# be written as a string e.g. ptcl_fn_prefix='sub-directory/part').
ptcl_fn_prefix="subtomograms/subtomo"

# Relative path and name prefix of the reference volumes (e.g.  ref_iter.em, the
# variable will be written as a string e.g.  ref_fn_prefix='sub-directory/ref')
ref_fn_prefix="class/ref"

# Relative path and name prefix of the partial weight files.
weight_sum_fn_prefix="class/wei"

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    ${exec_dir}/scripts/subtom_cluster.sh "$(realpath $0)"
else
    echo "Options sourced!"
fi
