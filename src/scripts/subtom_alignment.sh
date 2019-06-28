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
# If the number of alignment jobs is greater than 1000, this script
# automatically splits the job into multiple arrays and launches them. It will
# not run if you have more than 4000 alignment jobs, as this is the current
# maximum per user.
#
# This subtomogram averaging script uses five MATLAB compiled scripts below:
# - subtom_scan_angles_exact
# - subtom_cat_motls
# - subtom_parallel_sums
# - subtom_weighted_average
# - subtom_compare_motls
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
align_exec=${exec_dir}/alignment/subtom_scan_angles_exact

# Concatenate MOTLs executable
cat_exec=${exec_dir}/MOTL/subtom_cat_motls

# Parallel Summing executable
sum_exec=${exec_dir}/alignment/subtom_parallel_sums

# Final Averaging executable
avg_exec=${exec_dir}/alignment/subtom_weighted_average

# Compare MOTLs executable
compare_exec=${exec_dir}/MOTL/subtom_compare_motls

################################################################################
#                                MEMORY OPTIONS                                #
################################################################################
# The amount of memory your job requires
# e.g. mem_free_ali='2G'
mem_free_ali="1G"

# The upper bound on the amount of memory your job is allowed to use
# e.g. mem_max_ali='3G'
mem_max_ali="64G"

# The amount of memory your job requires
# e.g. mem_free_avg='2G'
mem_free_avg="1G"

# The upper bound on the amount of memory your job is allowed to use
# e.g. mem_max_avg='3G'
mem_max_avg="64G"

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
#                                                                              #
#                    SUBTOMOGRAM AVERAGING WORKFLOW OPTIONS                    #
#                                                                              #
################################################################################
#                           PARALLELIZATION OPTIONS                            #
################################################################################
# The index of the reference to start from : input will be
# reference_startindx.em and motilvelist_startindx.em (define as integer e.g.
# start_iteration=3)
#
# More on iterations since they're confusing and it is slightly different here
# than from previous iterations.
#
# The start_iteration is the beginning for the iteration variable used
# throughout this script. Iteration refers to iteration that is used for
# subtomogram alignment. So if start_iteration is 1, then subtomogram alignment
# will work using allmotl_1.em and ref_1.em. The output from alignment will be
# particle motls for the next iteration. This in the script is avg_iteration
# variable. The particle motls will be joined to form allmotl_2.em and then the
# parallel averaging will form ref_2.em and then the loop is done and iteration
# will become 2 and avg_iteration will become 3.
start_iteration="1"

# Number iterations (big loop) to run: final output will be
# reference_startindx+iterations.em and motilvelist_startindx+iterations.em
iterations="1"

# Number of batches to split the parallel subtomogram alignment job into
num_ali_batch="1"

# Number of batches to split the parallel subtomogram averaging job into
num_avg_batch="1"

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name of the concatenated motivelist of all particles (e.g.
# allmotl_iter.em , the variable will be written as a string e.g.
# all_motl_fn_prefix='sub-directory/allmotl')
all_motl_fn_prefix="combinedmotl/allmotl"

# Relative path and name of the reference volumes (e.g. ref_iter.em , the
# variable will be written as a string e.g. ref_fn_prefix='sub-directory/ref')
ref_fn_prefix="ref/ref"

# Relative path and name of the subtomograms (e.g. part_n.em , the variable will
# be written as a string e.g. ptcl_fn_prefix='sub-directory/part')
ptcl_fn_prefix="subtomograms/subtomo"

# Relative path and name of the alignment mask
# Leave the parentheses and if the number of values is less than the number of
# iterations the last value will be repeated to the correct length
# e.g. align_mask_fn=('otherinputs/align_mask_1.em' \
#                     'otherinputs/align_mask_2.em' \
#                     'otherinputs/align_mask_3.em')
align_mask_fn=("otherinputs/align_mask.em")

# Relative path and name of the cross-correlation mask this defines the maximum
# shifts in each direction
# Leave the parentheses and if the number of values is less than the number of
# iterations the last value will be repeated to the correct length
# e.g. cc_mask_fn=('otherinputs/cc_mask_1.em' \
#                  'otherinputs/cc_mask_5.em')
cc_mask_fn=("otherinputs/cc_mask.em")

# Relative path and name of the weight file
weight_fn_prefix="otherinputs/ampspec"

# Relative path and name of the partial weight files
weight_sum_fn_prefix="otherinputs/wei"

################################################################################
#                       ALIGNMENT AND AVERAGING OPTIONS                        #
################################################################################
# Which row in the motl file contains the correct tomogram number.
# Usually row 5 and 7 both correspond to the correct value and can be used
# interchangeably, but there are instances when 5 contains a sequential ordered
# value starting from 1, while 7 contains the correct corresponding tomogram.
tomo_row="7"

# Apply weight to subtomograms (1=yes, 0=no)
apply_weight="0"

# Apply mask to subtomograms (1=yes, 0=no)
apply_mask="0"

# Angular increment in degrees, applied during the cone-search, i.e. psi and
# theta (define as real e.g. psi_angle_step=3)
# Leave the parentheses and if the number of values is less than the number of
# iterations the last value will be repeated to the correct length
# e.g. psi_angle_step=(10 5 2.5 1 1)
psi_angle_step=("0")

# Number of angular iterations, applied to psi and theta  (define as integer
# e.g. psi_angle_shells=3)
# Leave the parentheses and if the number of values is less than the number of
# iterations the last value will be repeated to the correct length
# e.g. psi_angle_shells=(6 4 2)
psi_angle_shells=("0")

# Angular increment for phi in degrees, (define as real e.g. phi_angle_step=3)
# Leave the parentheses and if the number of values is less than the number of
# iterations the last value will be repeated to the correct length
phi_angle_step=("0")

# Number of angular iterations for phi, (define as integer e.g.
# phi_angle_shells=3)
# Leave the parentheses and if the number of values is less than the number of
# iterations the last value will be repeated to the correct length
phi_angle_shells=("0")

# High pass filter cutoff (in transform units (pixels): calculate as
# (boxsize*pixelsize)/(resolution_real) (define as integer e.g. high_pass_fp=2)
# Leave the parentheses and if the number of values is less than the number of
# iterations the last value will be repeated to the correct length
# e.g. high_pass_fp=(1 1 2 3)
high_pass_fp=("0")

# High pass filter falloff sigma (in transform units (pixels): describes a
# Gaussian sigma for the falloff of the high-pass filter past the cutoff above.
# Leave the parentheses and if the number of values is less than the number of
# iterations the last value will be repeated to the correct length
# e.g. high_pass_sigma=(2)
high_pass_sigma=("2")

# Low pass filter (in transform units (pixels): calculate as
# (boxsize*pixelsize)/(resolution_real) (define as integer e.g.
# low_pass_fp=30), has a Gaussian dropoff of ~2 pixels
# Leave the parentheses and if the number of values is less than the number of
# iterations the last value will be repeated to the correct length
low_pass_fp=("0")

# Low pass filter falloff sigma (in transform units (pixels): describes a
# Gaussian sigma for the falloff of the low-pass filter past the cutoff above.
# Leave the parentheses and if the number of values is less than the number of
# iterations the last value will be repeated to the correct length
# e.g. low_pass_sigma=(3)
low_pass_sigma=("3")

# Symmetry, if no symmetry nfold=1 (define as integer e.g. nfold=3)
# Leave the parentheses and if the number of values is less than the number of
# iterations the last value will be repeated to the correct length
# e.g. nfold=(1)
nfold=("1")

# Threshold for cross correlation coefficient. Only particles with ccc_new >
# threshold will be added to new average (define as real e.g. threshold=0.5).
# These particles will still be aligned at each iteration
threshold="-1"

# Particles with that number in position 20 of motivelist will be added to new
# average (define as integer e.g. iclass=1). NOTES: Class 1 is ALWAYS added.
# Negative classes and class 2 are never added.
iclass="0"

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    ${exec_dir}/scripts/subtom_alignment.sh "$(realpath $0)"
else
    echo "Options sourced!"
fi
