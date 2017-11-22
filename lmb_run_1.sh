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
# This subtomogram averaging script uses three MATLAB compiled scripts below:
# - lmb_scan_angles_exact
# - lmb_parallel_create_average
# - lmb_averageref_weighted
# DRM 11-2017
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Root folder on the scratch
scratch_dir="${nfs6}/VMV013/20170404/subtomo/bin2/even"

# Folder on group shares
local_dir="${bstore1}/VMV013/20170404/subtomo/bin2/even/local"

# MRC directory for each job
mcr_cache_dir="${scratch_dir}/mcr"

# A completion file will be written out after each step, so this script can be
# re-run after a crash and figure out where to start from.
completion_dir="${scratch_dir}/complete"

# Directory for executables
exec_dir=${bstore1}/software/lmbtomopipeline/compiled

################################################################################
#                                  VARIABLES                                   #
################################################################################
# Alignment executable
align_exec=${exec_dir}/lmb_scan_angles_exact

# Parallel Averaging executable
paral_avg_exec=${exec_dir}/lmb_parallel_create_average

# Final Averaging executable
avg_exec=${exec_dir}/lmb_averageref_weighted

################################################################################
#                                MEMORY OPTIONS                                #
################################################################################
# The amount of memory your job requires
mem_free_ali='2G'

# The upper bound on the amount of memory your job is allowed to use
mem_max_ali='3G'

# The amount of memory your job requires
mem_free_avg='2G'

# The upper bound on the amount of memory your job is allowed to use
mem_max_avg='3G'

################################################################################
#                              OTHER LSF OPTIONS                               #
################################################################################
# BE CAREFUL THAT THE NAME DOESN'T CORRESPOND TO THE BEGINNING OF ANY OTHER FILE
job_name='vmv013'

# Maximum number of jobs per array
array_max=1000

# Maximum number of jobs per user
max_jobs=4000

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
start_iteration=1

# Number iterations (big loop) to run: final output will be
# reference_startindx+iterations.em and motilvelist_startindx+iterations.em
iterations=1

# Total number of particles
num_ptcls=26870

# Number of particles in each parallel subtomogram alignment job (define as
# integer e.g. batchnumberofparticles=3)
ali_batch_size=100

# Number of particles in each parallel subtomogram averaging job
avg_batch_size=100

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name of the motivelist of the single particle (e.g.
# part_n.em will have a motl_n_iter.em , the variable will be written as a
# string e.g. ptcl_motl_fn_prefix='sub-directory/motl')
ptcl_motl_fn_prefix='motls/motl'

# Relative path and name of the concatenated motivelist of all particles (e.g.
# allmotl_iter.em , the variable will be written as a string e.g.
# all_motl_fn_prefix='sub-directory/allmotl')
all_motl_fn_prefix='combinedmotl/allmotl'

# Relative path and name of the reference volumes (e.g. ref_iter.em , the
# variable will be written as a string e.g. ref_fn_prefix='sub-directory/ref')
ref_fn_prefix='ref/ref'

# Relative path and name of the subtomograms (e.g. part_n.em , the variable will
# be written as a string e.g. ptcl_fn_prefix='sub-directory/part')
ptcl_fn_prefix='subtomograms/subtomo'

# Relative path and name of the alignment mask
align_mask_fn='otherinputs/mask128_r52_h52_g3_pos666670.em'

# Relative path and name of the cross-correlation mask this defines the maximum
# shifts in each direction
cc_mask_fn='otherinputs/ccmask128_r6.em'

# Relative path and name of the weight file
#weight_fn_prefix='../WNG_Wedge_Tests/ampspec_log.em'
weight_fn_prefix='otherinputs/ampspec'

# Relative path and name of the partial weight files
weight_sum_fn_prefix='otherinputs/new_test_wei'

################################################################################
#                       ALIGNMENT AND AVERAGING OPTIONS                        #
################################################################################
# Which row in the motl file contains the correct tomogram number.
# Usually row 5 and 7 both correspond to the correct value and can be used
# interchangeably, but there are instances when 5 contains a sequential ordered
# value starting from 1, while 7 contains the correct corresponding tomogram.
tomo_row=5

# Apply weight to subtomograms (1=yes, 0=no)
apply_weight=1

# Apply mask to subtomograms (1=yes, 0=no)
apply_mask=1

# Angular increment in degrees, applied during the cone-search, i.e. psi and
# theta (define as real e.g. psi_angle_step=3)
psi_angle_step=2

# Number of angular iterations, applied to psi and theta  (define as integer
# e.g. psi_angle_shells=3)
psi_angle_shells=3

# Angular increment for phi in degrees, (define as real e.g. phi_angle_step=3)
phi_angle_step=2

# Number of angular iterations for phi, (define as integer e.g.
# phi_angle_shells=3)
phi_angle_shells=3

# High pass filter (in transform units (pixels): calculate as
# (boxsize*pixelsize)/(resolution_real) (define as integer e.g. high_pass_fp=2)
high_pass_fp=1

# Low pass filter (in transform units (pixels): calculate as
# (boxsize*pixelsize)/(resolution_real) (define as integer e.g.
# low_pass_fp=30), has a Gaussian dropoff of ~2 pixels
low_pass_fp=17

# Symmetry, if no symmetry nfold=1 (define as integer e.g. nfold=3)
nfold=2

# Threshold for cross correlation coefficient. Only particles with ccc_new >
# threshold will be added to new average (define as real e.g. threshold=0.5).
# These particles will still be aligned at each iteration
threshold=0

# Particles with that number in position 20 of motivelist will be added to new
# average (define as integer e.g. iclass=1). NOTES: Class 1 is ALWAYS added.
# Negative classes and class 0 are never added.
iclass=1

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
# Check that other directories exist and if not, make them
if [[ ! -d ${local_dir} ]]
then
    mkdir -p ${local_dir}
fi

if [[ ! -d ${mcr_cache_dir} ]]
then
    mkdir -p ${mcr_cache_dir}
fi

if [[ ! -d ${completion_dir} ]]
then
    mkdir -p ${completion_dir}
fi

# Check number of jobs
num_ali_batch=$(((num_ptcls + ali_batch_size - 1) / ali_batch_size))
num_avg_batch=$(((num_ptcls + avg_batch_size - 1) / avg_batch_size))
if [[ ${num_ali_batch} -gt ${max_jobs} || ${num_avg_batch} -gt ${max_jobs} ]]
then
    echo " TOO MANY JOBS!!!!!  I QUIT!!!"
    exit 1
fi

################################################################################
#                                                                              #
#                        SUBTOMOGRAM AVERAGING WORKFLOW                        #
#                                                                              #
################################################################################
end_iteration=$((start_iteration + iterations - 1))
for ((iteration=start_iteration; iteration <= end_iteration; iteration++))
do
    echo "            ITERATION number ${iteration}"
################################################################################
#                            SUBTOMOGRAM ALIGNMENT                             #
################################################################################
    if [[ ! -f ${completion_dir}/subtomo_ali_${iteration} ]]
    then
        # Generate and launch array files
        # Calculate number of job scripts needed
        num_ali_jobs=$(((num_ali_batch + array_max - 1) / array_max))
        array_start=1

        # Generate array files
        for ((job_idx=1; job_idx <= num_ali_jobs; job_idx++))
        do
            # Calculate end job
            array_end=$((array_start + array_max - 1))
            if [[ ${array_end} -gt ${num_ali_batch} ]]
            then
                array_end=${num_ali_batch}
            fi

            ### Write out script for each node
            cat > ${job_name}_ali_array_${iteration}_${job_idx} <<-ALIJOB
#!/bin/bash
#$ -N ${job_name}_ali_array_${iteration}_${job_idx}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${mem_free_ali},h_vmem=${mem_max_ali}
#$ -o log_${job_name}_ali_array_${iteration}_${job_idx}
#$ -e error_${job_name}_ali_array_${iteration}_${job_idx}
#$ -t ${array_start}-${array_end}
set +o noclobber
set -e
echo \${HOSTNAME}
ldpath=/lmb/home/public/matlab/jbriggs/runtime/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/bin/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=\${ldpath}
cd ${scratch_dir}
batch_idx=\${SGE_TASK_ID}
MCRDIR=${mcr_cache_dir}
rm -rf \${MCRDIR}/${job_name}_ali_\${batch_idx}
mkdir \${MCRDIR}/${job_name}_ali_\${batch_idx}
export MCR_CACHE_ROOT=\${MCRDIR}/${job_name}_ali_\${batch_idx}
ptcl_start_idx=\$(((${ali_batch_size} * (batch_idx - 1)) + 1))
time ${align_exec} \\
\${ptcl_start_idx} \\
${iteration} \\
${ali_batch_size} \\
${ref_fn_prefix} \\
${all_motl_fn_prefix} \\
${ptcl_motl_fn_prefix} \\
${ptcl_fn_prefix} \\
${tomo_row} \\
${weight_fn_prefix} \\
${apply_weight} \\
${align_mask_fn} \\
${apply_mask} \\
${cc_mask_fn} \\
${psi_angle_step} \\
${psi_angle_shells} \\
${phi_angle_step} \\
${phi_angle_shells} \\
${high_pass_fp} \\
${low_pass_fp} \\
${nfold} \\
${threshold} \\
${iclass}
rm -rf \${MCRDIR}/${job_name}_ali_\${batch_idx}
ALIJOB

            qsub ${job_name}_ali_array_${iteration}_${job_idx}
            array_start=$((array_start + array_max))
        done

        echo "Aligning subtomograms in iteration number ${iteration}"
################################################################################
#                              ALIGNMENT PROGRESS                              #
################################################################################
        num_ali_ptcls=0
        while [[ ${num_ali_ptcls} -lt ${num_ptcls} ]]
        do
            sleep 10s
            num_ali_ptcls=$(($(${listdir} ./checkjobs/ | wc -l) - 2))
            echo "Number of subtomograms aligned:"
            echo "${num_ali_ptcls} out of ${num_ptcls}"
        done

        ### Write out completion file
        touch ${completion_dir}/subtomo_ali_${iteration}
    fi

    ### Remove align scripts
    #rm -f ${job_name}_ali_array_${iteration}_*

    ### Clear checkjobs folder
    mv ${scratch_dir}/checkjobs \
        ${scratch_dir}/checkjobs_subtomo_ali_${iteration}
    mkdir ${scratch_dir}/checkjobs
    echo "DONE ALIGNMENT in iteration number ${iteration}"
################################################################################
#                              PARALLEL AVERAGING                              #
################################################################################
    if [[ ! -f ${completion_dir}/paral_avg_${iteration} ]]
    then
        # Generate and launch array files
        # Calculate number of job scripts needed
        num_avg_jobs=$(((num_avg_batch + array_max - 1) / array_max))
        array_start=1

        ### Loop to generate parallel alignment scripts
        for ((job_idx=1; job_idx <= num_avg_jobs; job_idx++))
        do
            array_end=$((array_start + array_max - 1))
            if [[ ${array_end} -gt ${num_avg_batch} ]]
            then
                array_end=${num_avg_batch}
            fi

            cat > ${job_name}_paral_avg_array_${iteration}_${job_idx}<<-PAVGJOB
#!/bin/bash
#$ -N ${job_name}_paral_avg_${iteration}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${mem_free_avg},h_vmem=${mem_max_avg}
#$ -o log_${job_name}_paral_avg_array_${iteration}_${job_idx}
#$ -e error_${job_name}_paral_avg_array_${iteration}_${job_idx}
#$ -t ${array_start}-${array_end}
set +o noclobber
set -e

echo \${HOSTNAME}
ldpath=/lmb/home/public/matlab/jbriggs/runtime/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/bin/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=\${ldpath}
cd ${scratch_dir}
batch_idx=\${SGE_TASK_ID}
MCRDIR=${mcr_cache_dir}
rm -rf \${MCRDIR}/${job_name}_paral_avg_\${batch_idx}
mkdir \${MCRDIR}/${job_name}_paral_avg_\${batch_idx}
export MCR_CACHE_ROOT=\${MCRDIR}/${job_name}_paral_avg_\${batch_idx}
ptcl_start_idx=\$(((${avg_batch_size} * (batch_idx - 1)) + 1))
time ${paral_avg_exec} \\
    \${ptcl_start_idx} \\
    ${avg_batch_size} \\
    ${num_ptcls} \\
    ${iteration} \\
    ${ptcl_motl_fn_prefix} \\
    ${all_motl_fn_prefix} \\
    ${ref_fn_prefix} \\
    ${ptcl_fn_prefix} \\
    ${wedgelist} \\
    ${iclass} \\
    \${batch_idx} \\
    ${checkjobavg}
rm -rf \${MCRDIR}/${job_name}_paral_avg_\${batch_idx}
PAVGJOB
            qsub ${job_name}_paral_avg_array_${iteration}_${job_idx}
            array_start=$((array_start + array_max))
        done

        echo "Parallel average in iteration number ${iteration}"
################################################################################
#                         PARALLEL AVERAGING PROGRESS                          #
################################################################################
        num_ptcl_avgs=0
        while [[ ${num_ptcl_avgs} -lt ${num_avg_batch} ]]
        do
            sleep 10s
            num_ptcl_avgs=$(($(${listdir} ./checkjobs/ | wc -l) - 2))
            echo "Number of parallel averages generated:"
            echo "${num_ptcl_avgs} out of ${num_avg_batch}"
        done

        ### Write out completion file
        touch ${completion_dir}/paral_avg_${iteration}
    fi

    ### Remove scripts
    #rm -f ${job_name}_paral_avg_array_${iteration}_*

    ### Clear checkjobs folder
    mv ${scratch_dir}/checkjobs \
        ${scratch_dir}/checkjobs_paral_avg_${iteration}
    mkdir ${scratch_dir}/checkjobs
    echo "DONE PARALLEL AVERAGE in iteration number ${iteration}"
################################################################################
#                                FINAL AVERAGE                                 #
################################################################################
    if [[ ! -f ${completion_dir}/final_avg_${iteration} ]]
    then
        rm -f ${scratch_dir}/checkjob_aver.txt

        cat > ${job_name}_avg_${iteration} <<-AVGJOB
#!/bin/bash
#$ -N ${job_name}_avg_${iteration}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${mem_free_avg},h_vmem=${mem_max_avg}
#$ -o log_${job_name}_avg_${iteration}
#$ -e error_${job_name}_avg_${iteration}
set +o noclobber
set -e

echo \${HOSTNAME}
ldpath=/lmb/home/public/matlab/jbriggs/runtime/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/bin/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=\${ldpath}
cd ${scratch_dir}
MCRDIR=${mcr_cache_dir}/${job_name}_avg_iteration
rm -rf \${MCRDIR}
mkdir \${MCRDIR}
export MCR_CACHE_ROOT=\${MCRDIR}
time ${avg_exec} \\
    ${ref_fn_prefix} \\
    ${all_motl_fn_prefix} \\
    ${avg_batch_size} \\
    ${num_ptcls} \\
    ${iteration} \\
    ${iclass}
rm -rf \${MCRDIR}
AVGJOB

        qsub ${job_name}_avg_${iteration}
        echo "Final average in iteration number ${iteration}"
################################################################################
#                            FINAL AVERAGE PROGRESS                            #
################################################################################
        check_avg=0
        echo "Waiting for the final average ..."
        while [[ ${check_avg} -lt 1 ]]
        do
            sleep 10s
            check_avg=$(ls ${scratch_dir}/checkjob_aver.txt 2>/dev/null | wc -l)
        done

        ### Write out completion file
        touch ${completion_dir}/final_avg_${iteration}

        ### Copy file to group share
        next_iteration=$((iteration + 1))
        cp ${scratch_dir}/${all_motl_fn_prefix}_${next_iteration}.em \
            ${local_dir}/${all_motl_fn_prefix}_${next_iteration}.em
        cp ${scratch_dir}/${ref_fn_prefix}_${next_iteration}.em \
            ${local_dir}/${ref_fn_prefix}_${next_iteration}.em
    fi

    ### Clean up from the iteration
    rm -f ${job_name}_avg_${iteration}
    rm -f ${scratch_dir}/checkjob_aver.txt
    rm -f ${scratch_dir}/${ref_fn_prefix}_*_*.em
    rm -f ${scratch_dir}/otherinputs/wei_*_*.em
    rm -f ${all_motl_fn_prefix}_*_*.em

    echo "AVERAGE DONE IN ITERATION NUMBER ${iteration}"
done
exit
