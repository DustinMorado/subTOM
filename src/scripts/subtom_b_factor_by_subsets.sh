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
# This subtomogram parallel averaging script uses two MATLAB compiled scripts
# below:
# - b_factor_from_subsets/subtom_parallel_sums
# - b_factor_from_subsets/subtom_weighted_average
# - b_factor_from_subsets/subtom_maskcorrected_fsc
# DRM 05-2019
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the root folder for subtomogram extraction.
# Other paths are relative to this one.
scratch_dir="${PWD}"

# Absolute path to the MCR directory for each job
mcr_cache_dir="${scratch_dir}/mcr"

# Directory for executables
exec_dir="XXXINSTALLATION_DIRXXX/bin"

################################################################################
#                                  VARIABLES                                   #
################################################################################
# Parallel Summing executable
sum_exec="${exec_dir}/analysis/b_factor_by_subsets/subtom_parallel_sums"

# Final Averaging executable
avg_exec="${exec_dir}/analysis/b_factor_by_subsets/subtom_weighted_average"

# FSC executable
fsc_exec="${exec_dir}/analysis/b_factor_by_subsets/subtom_maskcorrected_fsc"

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

# Maximum number of jobs per array
array_max="1000"

# Maximum number of jobs per user
max_jobs="4000"

# If you want to skip the cluster and run the job locally set this to 1.
run_local="0"

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
all_motl_a_fn_prefix="even/combinedmotl/allmotl"

# Relative path and name prefix of the concatenated motivelist of all particles
# (e.g.  allmotl_iter.em , the variable will be written as a string e.g.
# all_motl_fn_prefix='sub-directory/allmotl')
all_motl_b_fn_prefix="even/combinedmotl/allmotl"

# Relative path and name prefix of the reference volumes (e.g.  ref_iter.em, the
# variable will be written as a string e.g.  ref_fn_prefix='sub-directory/ref')
ref_fn_prefix="FSC/ref"

# Relative path and name prefix of the subtomograms (e.g. part_n.em, the
# variable will be written as a string e.g.
# ptcl_fn_prefix='sub-directory/part')
ptcl_fn_prefix="subtomograms/subtomo"

# Relative path and name prefix of the weight file.
weight_fn_prefix="otherinputs/ampspec"

# Relative path and name prefix of the partial weight files.
weight_sum_fn_prefix="FSC/wei"

################################################################################
#                              AVERAGING OPTIONS                               #
################################################################################
# Which row in the motl file contains the correct tomogram number.
# Usually row 5 and 7 both correspond to the correct value and can be used
# interchangeably, but there are instances when 5 contains a sequential ordered
# value starting from 1, while 7 contains the correct corresponding tomogram.
tomo_row="7"

# Particles with that number in position 20 of motivelist will be added to new
# average (define as integer e.g. iclass=1). NOTES: Class 1 is ALWAYS added.
# Negative classes and class 2 are never added.
iclass="0"

################################################################################
#                                                                              #
#                     MASK CORRECTED FSC WORKFLOW OPTIONS                      #
#                                                                              #
################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# The index of the reference to generate : input will be
# ref_{a,b}_fn_prefix_iteration.em (define as integer e.g. iteration=1)
iteration=1

# Relative or absolute path and name of the FSC mask.
fsc_mask_fn="FSC/fsc_mask.em"

# Relative or absolute path and name of the Fourier filter volume for the first
# half-map. If not using the option do_reweight just leave this set to ""
filter_a_fn=""

# Relative or absolute path and name of the Fourier filter volume for the second
# half-map. If not using the option do_reweight just leave this set to ""
filter_b_fn=""

################################################################################
#                                 FSC OPTIONS                                  #
################################################################################
# Pixelsize of the half-maps in Angstroms
pixelsize=1

# Symmetry to applied the half-maps before calculating FSC (1 is no symmetry)
nfold=1

# The Fourier pixel at which phase-randomization begins is set automatically to
# the point where the unmasked FSC falls below this threshold.
rand_threshold=0.8

# Plot the FSC curves - 1 = yes, 0 = no
plot_fsc=1

################################################################################
#                              SHARPENING OPTIONS                              #
################################################################################
# Set to 1 to sharpen map or 0 to skip and just calculate the FSC
do_sharpen=1

# To remove some of the edge-artifacts associated with map-sharpening the edges
# of the map can be smoothed with a gaussian. Set to 0 to not smooth the edges,
# otherwise it must be set to an odd number. If an even number is given one will
# be added to the value to make it odd.
box_gaussian=1

# There are two mode used for low pass filtering. The first uses an FSC
# based threshold (mode 1), i.e. after FSC < 0.143, or a pixel-based
# resolution threhsold (mode 2).
filter_mode=1

# Set the threshold for the low pass filtering described above. Should be less
# than 1 for FSC based threshold (mode 1), and an integer value for the Fourier
# pixel-based threshold (mode 2).
filter_threshold=0.143

# Plot the sharpening curve - 1 = yes, 0 = no
plot_sharpen=1

################################################################################
#                             REWEIGHTING OPTIONS                              #
################################################################################
# Set to 1 to apply the externally calculated Fourier weights filter_A_fn and
# filter_B_fn to each half-map to reweight the final output map.
do_reweight=0

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    ${exec_dir}/scripts/subtom_b_factor_by_subsets.sh "$(realpath $0)"
else
    echo "Options sourced!"
fi
