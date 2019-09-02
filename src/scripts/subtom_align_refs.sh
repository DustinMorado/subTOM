#!/bin/bash
################################################################################
# This is a run script for the standard AV3 subtomogram averaging scripts. The
# MATLAB executables for this script were compiled in MATLAB-8.5. The other
# difference is that these scripts have been edited to make sure that the output
# files from each step is readable.
#
# This script is meant to run on the scratch it copies the reference and final
# allmotl file to a local folder after each iteration.
#
# Also, the run script and all the launch scripts are written in bash. This is
# mainly because the behaviour of bash is a bit more predictable.
#
# This subtomogram parallel averaging script uses five MATLAB compiled scripts
# below:
# - subtom_scan_angles_exact_refs
# - subtom_parallel_sums
# - subtom_parallel_sums_cls
# - subtom_weighted_average
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

# Absolute path to the MCR directory for each job
mcr_cache_dir="${scratch_dir}/mcr"

# Directory for executables
exec_dir="XXXINSTALLATION_DIRXXX/bin"

################################################################################
#                                  VARIABLES                                   #
################################################################################
# Alignment executable
align_exec="${exec_dir}/classification/general/subtom_scan_angles_exact_refs"

# Parallel Summing executable.
sum_exec="${exec_dir}/alignment/subtom_parallel_sums"

# Final Averaging executable.
avg_exec="${exec_dir}/alignment/subtom_weighted_average"

# Class Average Parallel Summing executable.
sum_cls_exec="${exec_dir}/classification/general/subtom_parallel_sums_cls"

# Class Average Final Averaging executable.
avg_cls_exec="${exec_dir}/classification/general/subtom_weighted_average_cls"

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
#                            OTHER CLUSTER OPTIONS                             #
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
#                                                                              #
#                    SUBTOMOGRAM AVERAGING WORKFLOW OPTIONS                    #
#                                                                              #
################################################################################
#                           PARALLELIZATION OPTIONS                            #
################################################################################
# The index of the reference to generate : input will be
# all_motl_fn_prefix_iteration.em (define as integer e.g. iteration=1)
iteration="1"

# Number of batches to split the parallel subtomogram averaging job into
num_avg_batch="1"

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name prefix of the concatenated motivelist of all particles
# (e.g.  allmotl_iter.em , the variable will be written as a string e.g.
# all_motl_fn_prefix='sub-directory/allmotl')
all_motl_fn_prefix="combinedmotl/allmotl"

# Relative path and name prefix of the output motivelist of all particles. There
# will be two versions written out. The first with "_classed_" will retain the
# iclass values to generate new aligned class averages. The second with
# "_unclassed_" will set all particles iclass to 1 to generate a cumulative
# class average.
output_motl_fn_prefix="combinedmotl/allmotl"

# Relative path and name prefix of the reference volumes (e.g.  ref_iter.em, the
# variable will be written as a string e.g.  ref_fn_prefix='sub-directory/ref')
ref_fn_prefix="ref/ref"

# Relative path and name prefix of the subtomograms (e.g. part_n.em, the
# variable will be written as a string e.g.
# ptcl_fn_prefix='sub-directory/part')
ptcl_fn_prefix="subtomograms/subtomo"

# Relative path and name of the alignment mask. If "none" is given a default
# spherical mask will be used. (e.g.  align_mask_fn='otherinputs/align_mask.em')
align_mask_fn="otherinputs/align_mask.em"

# Relative path and name of the cross-correlation mask this defines the maximum
# shifts in each direction. If "noshift" is given no shifts are allowed. (e.g.
# cc_mask_fn='otherinputs/cc_mask_1.em')
cc_mask_fn="otherinputs/cc_mask.em"

# Relative path and name prefix of the weight file.
weight_fn_prefix="otherinputs/ampspec"

# Relative path and name prefix of the partial weight files.
weight_sum_fn_prefix="otherinputs/wei"

################################################################################
#                       ALIGNMENT AND AVERAGING OPTIONS                        #
################################################################################
# Which row in the motl file contains the correct tomogram number.
# Usually row 5 and 7 both correspond to the correct value and can be used
# interchangeably, but there are instances when 5 contains a sequential ordered
# value starting from 1, while 7 contains the correct corresponding tomogram.
tomo_row="7"

# Which class average to align the other class averages against. Because of the
# AV3 specification for iclass this should be a number that is 3 or above. 
ref_class="3"

# Apply mask to class averages (1=yes, 0=no)
apply_mask="0"

# Angular increment in degrees, applied during the cone-search, i.e. psi and
# theta (define as real e.g. psi_angle_step=3)
psi_angle_step="0"

# Number of angular iterations, applied to psi and theta  (define as integer
# e.g. psi_angle_shells=3)
psi_angle_shells="0"

# Angular increment for phi in degrees, (define as real e.g. phi_angle_step=3)
phi_angle_step="0"

# Number of angular iterations for phi, (define as integer e.g.
# phi_angle_shells=3)
phi_angle_shells="0"

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

# Symmetry, if no symmetry nfold=1 (define as integer e.g. nfold=3)
nfold="1"

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    ${exec_dir}/scripts/subtom_align_refs.sh "$(realpath $0)"
else
    echo "Options sourced!"
fi
