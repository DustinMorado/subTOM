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
# This subtomogram averaging script uses nine MATLAB compiled scripts below:
# - subtom_cluster
# - subtom_eigenvolumes_msa
# - subtom_join_eigencoeffs_msa
# - subtom_join_xmatrix_msa
# - subtom_parallel_eigencoeffs_msa
# - subtom_parallel_prealign
# - subtom_parallel_sums_cls
# - subtom_parallel_xmatrix_msa
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

# Parallel Eigencoefficient executable.
par_eigcoeff_exec="${exec_dir}/classification/msa/subtom_parallel_eigencoeffs_msa"

# Final Eigencoefficient executable.
eigcoeff_exec="${exec_dir}/classification/msa/subtom_join_eigencoeffs_msa"

# Eigenvolume Calculation executable.
eigvol_exec="${exec_dir}/classification/msa/subtom_eigenvolumes_msa"

# Parallel Subtomogram prealign executable.
preali_exec="${exec_dir}/classification/general/subtom_parallel_prealign"

# Parallel X-Matrix executable.
par_xmatrix_exec="${exec_dir}/classification/msa/subtom_parallel_xmatrix_msa"

# Final X-Matrix executable.
xmatrix_exec="${exec_dir}/classification/msa/subtom_join_xmatrix"

# Parallel Summing executable
sum_exec="${exec_dir}/classification/general/subtom_parallel_sums_cls"

# Final Averaging executable
avg_exec="${exec_dir}/classification/general/subtom_weighted_average_cls"

# MOTL dump executable
motl_dump_exec="${exec_dir}/MOTL/motl_dump"

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

# Number of batches to split the parallel particle prealignment for the
# X-Matrix calculation into. If you are not doing prealignment you can ignore
# this option.
num_xmatrix_prealign_batch="1"

# Number of batches to split the parallel X-Matrix calculation job into.
num_xmatrix_batch="1"

# Number of batches to split the parallel particle prealignment for the
# Eigencoefficients calculations into. If you are not doing prealignment you can
# ignore this option.
num_eig_coeff_prealign_batch="1"

# Number of batches to split the parallel Eigencoefficient calculation into.
num_eig_coeff_batch="1"

# Number of batches to split the parallel subtomogram averaging job into
num_avg_batch="1"

################################################################################
#                                                                              #
#                 SUBTOMOGRAM CLASSIFICATION WORKFLOW OPTIONS                  #
#                                                                              #
################################################################################
#                               X-MATRIX OPTIONS                               #
################################################################################
# High pass filter cutoff (in transform units (pixels): calculate as
# (box_size*pixelsize)/(resolution_real) (define as integer e.g. high_pass_fp=2)
high_pass_fp="0"

# High pass filter falloff sigma (in transform units (pixels): describes a
# Gaussian sigma for the falloff of the high-pass filter past the cutoff above.
high_pass_sigma="2"

# Low pass filter (in transform units (pixels): calculate as
# (box_size*pixelsize)/(resolution_real) (define as integer e.g.
# low_pass_fp=30).
low_pass_fp="0"

# Low pass filter falloff sigma (in transform units (pixels): describes a
# Gaussian sigma for the falloff of the low-pass filter past the cutoff above.
low_pass_sigma="3"

# Symmetry to apply to each pair of particle and reference in X-Matrix
# calculation, if no symmetry nfold=1 (define as integer e.g. nfold=3).
nfold="1"

# If you want to pre-align all of the particles to speed up the X-Matrix
# calculation, set the following to 1, otherwise the particles will be aligned
# during the computation.
xmatrix_prealign=0

################################################################################
#                            X-MATRIX FILE OPTIONS                             #
################################################################################
# Relative path and name of the concatenated motivelist of all particles (e.g.
# allmotl_iter.em , the variable will be written as a string e.g.
# xmatrix_all_motl_fn_prefix='sub-directory/allmotl').
xmatrix_all_motl_fn_prefix="combinedmotl/allmotl"

# Relative path and name of the X-Matrix.
xmatrix_fn_prefix="class/xmatrix_msa"

# Relative path and name of the subtomograms (e.g. part_n.em , the variable will
# be written as a string e.g. ptcl_fn_prefix='sub-directory/part').
ptcl_fn_prefix="subtomograms/subtomo"

# Relative path and name of the classification mask. This should be a binary
# mask as correlations are done in real-space, and calculations will only be
# done using voxels passed by the mask, so smaller masks will run faster. If you
# want to use the default spherical mask set mask_fn to 'none'
mask_fn="none"

################################################################################
#                             EIGENVOLUME OPTIONS                              #
################################################################################
# The number of Eigenvectors and Eigenvalues to calculate.
num_eigs='40'

# The following allows you to adjust the number of iterations to use in the
# decomposition. If you want to use the default number of iterations leave this
# set to 'default'.
eigs_iterations='default'

# The following allows you to adjust the convergence tolerance of the
# decomposition calculation. If you want to use the default tolerance leave this
# set to 'default'.
eigs_tolerance='default'

################################################################################
#                           EIGENVOLUME FILE OPTIONS                           #
################################################################################
# Relative path and name of the Eigenvectors.
eig_vec_fn_prefix="class/eigvec_msa"

# Relative path and name of the Eigenvalues.
eig_val_fn_prefix="class/eigval_msa"

# Relative path and name of the Eigenvolumes.
eig_vol_fn_prefix="class/eigvol_msa"

################################################################################
#                           EIGENCOEFFICIENT OPTIONS                           #
################################################################################
# If the following is set to 1, the Eigenvolume will have the particles
# missing-wedge weight applied to it before the correlation is calculated.
apply_weight="0"

# Which row in the motl file contains the correct tomogram number.
# Usually row 5 and 7 both correspond to the correct value and can be used
# interchangeably, but there are instances when 5 contains a sequential ordered
# value starting from 1, while 7 contains the correct corresponding tomogram.
tomo_row="7"

# If you want to pre-align all of the particles to speed up the Eigencoefficient
# calculation, set the following to 1, otherwise the particles will be aligned
# during the computation.
eig_coeff_prealign="0"

################################################################################
#                        EIGENCOEFFICIENT FILE OPTIONS                         #
################################################################################
# Relative path and name of the concatenated motivelist to project onto the
# Eigenvolumes. This can be a larger motivelist than the one used to calculate
# the X-Matrix and Eigenvolumes.
eig_coeff_all_motl_fn_prefix="combinedmotl/allmotl"

# Relative path and name of the Eigencoefficients.
eig_coeff_fn_prefix="class/eigcoeff_msa"

# Relative path and name of the weight file, if you are not applying the weight
# to the Eigenvolumes this can be left alone.
weight_fn_prefix="otherinputs/ampspec"

################################################################################
#                              CLUSTERING OPTIONS                              #
################################################################################
# The following determines which algorithm will be used to cluster the
# determined Eigencoefficients. The valid options are K-means clustering,
# 'kmeans', Hierarchical Ascendent Clustering using a Ward Criterion, 'hac', and
# a Gaussian Mixture Model, 'gaussmix'.
cluster_type="kmeans"

# Determines which Eigencoefficients are used to cluster. The format should be a
# semicolon-separated list that also supports ranges with a dash (-), for
# example 1-5;7;15-19 would select the first five Eigencoefficients, the seventh
# and the fifteenth through the nineteenth for classification. If it is left as
# "all" all coefficients will be used.
eig_idxs="all"

# How many classes should the particles be clustered into.
num_classes=2

################################################################################
#                           CLUSTERING FILE OPTIONS                            #
################################################################################
# Relative path and name of the concatenated motivelist of the output classified
# particles.
cluster_all_motl_fn_prefix="class/allmotl_msa"

################################################################################
#                            AVERAGING FILE OPTIONS                            #
################################################################################
# Relative path and name prefix of the reference volumes (e.g.  ref_iter.em, the
# variable will be written as a string e.g.  ref_fn_prefix='sub-directory/ref')
ref_fn_prefix="class/ref_msa"

# Relative path and name prefix of the partial weight files.
weight_sum_fn_prefix="class/wei_msa"

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    ${exec_dir}/scripts/subtom_msa.sh "$(realpath $0)"
else
    echo "Options sourced!"
fi
