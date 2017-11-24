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
# - lmb_parallel_sums
# - lmb_weighted_average
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

# Directory for executables
exec_dir=${bstore1}/software/lmbtomopipeline/compiled

################################################################################
#                                  VARIABLES                                   #
################################################################################
# Alignment executable
align_exec=${exec_dir}/lmb_scan_angles_exact

# MOTL join executable
join_exec=${exec_dir}/lmb_joinmotl

# Parallel Averaging executable
paral_avg_exec=${exec_dir}/lmb_parallel_sums

# Final Averaging executable
avg_exec=${exec_dir}/lmb_weighted_average

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
job_name='VMV013'

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
process_idx=\${SGE_TASK_ID}
check="${all_motl_fn_prefix}_$((iteration + 1)).em"
if [[ -f "\${check}" ]]
then
    echo "\${check} already complete. SKIPPING"
    exit 0
fi
MCRDIR=${mcr_cache_dir}/${job_name}_ali_\${process_idx}
rm -rf \${MCRDIR}
mkdir \${MCRDIR}
export MCR_CACHE_ROOT=\${MCRDIR}
ptcl_start_idx=\$(((${ali_batch_size} * (process_idx - 1)) + 1))
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
rm -rf \${MCRDIR}
ALIJOB

        qsub ${job_name}_ali_array_${iteration}_${job_idx}
        array_start=$((array_start + array_max))
    done

    echo "STARTING Alignment in Iteration Number: ${iteration}"
################################################################################
#                              ALIGNMENT PROGRESS                              #
################################################################################
    motl_dir=$(dirname ${scratch_dir}/${ptcl_motl_fn_prefix})
    motl_base=$(basename ${scratch_dir}/${ptcl_motl_fn_prefix})
    motl_base=${motl_base}_$((iteration + 1))
    num_complete=$(find ${motl_dir} -name "${motl_base}_*.em" | wc -l)
    num_complete_prev=0
    unchanged_count=0
    while [[ ${num_complete} -lt ${num_ptcls} ]]
    do
        num_complete=$(find ${motl_dir} -name "${motl_base}_*.em" | wc -l)
        echo "${num_complete} aligned out of ${num_ptcls}"
        if [[ ${num_complete} -eq ${num_complete_prev} ]]
        then
            unchanged_count=$((unchanged_count + 1))
        else
            unchanged_count=0
        fi
        num_complete_prev=${num_complete}

        if [[ ${num_complete} -gt 0 && ${unchanged_count} -gt 120 ]]
        then
            echo "Alignment has seemed to stall"
            echo "Please check error logs and resubmit the job if neeeded."
            exit 1
        fi  
        sleep 60s
    done
################################################################################
#                              ALIGNMENT CLEAN UP                              #
################################################################################
    if [[ ! -d "${scratch_dir}/ali_${iteration}" ]]
    then
        mkdir "${scratch_dir}/ali_${iteration}"
    fi

    if [[ -e "${job_name}_ali_array_${iteration}_1" ]]
    then
        mv -f "${job_name}_ali_array_${iteration}"_* \
            "${scratch_dir}/ali_${iteration}/."
    fi

    if [[ -e "log_${job_name}_ali_array_${iteration}_1" ]]
    then
        mv -f "log_${job_name}_ali_array_${iteration}"_* \
            "${scratch_dir}/ali_${iteration}/."
    fi

    if [[ -e "error_${job_name}_ali_array_${iteration}_1" ]]
    then
        mv -f "log_${job_name}_ali_array_${iteration}"_* \
            "${scratch_dir}/ali_${iteration}/."
    fi

    echo "FINISHED Alignment in Iteration Number: ${iteration}"
################################################################################
#                           COLLECT & COMBINE MOTLS                            #
################################################################################
    cat > ${job_name}_joinmotl_${iteration} <<-JOINJOB
#!/bin/bash
#$ -N ${job_name}_joinmotl_${iteration}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${mem_free_ali},h_vmem=${mem_max_ali}
#$ -o log_${job_name}_joinmotl_${iteration}
#$ -e error_${job_name}_joinmotl_${iteration}
set +o noclobber
set -e
echo \${HOSTNAME}
ldpath=/lmb/home/public/matlab/jbriggs/runtime/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/bin/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=\${ldpath}
cd ${scratch_dir}
check="${all_motl_fn_prefix}_$((iteration + 1)).em"
if [[ -f "\${check}" ]]
then
    echo "\${check} already complete. SKIPPING"
    exit 0
fi
MCRDIR=${mcr_cache_dir}/${job_name}_joinmotl
rm -rf \${MCRDIR}
mkdir \${MCRDIR}
export MCR_CACHE_ROOT=\${MCRDIR}
time ${join_exec} \\
${iteration} \\
${all_motl_fn_prefix} \\
${ptcl_motl_fn_prefix} \\
rm -rf \${MCRDIR}
JOINJOB

    qsub ${job_name}_joinmotl_${iteration}
    echo "STARTING MOTL Join in Iteration Number: ${iteration}"
################################################################################
#                              MOTL JOIN PROGRESS                              #
################################################################################
    unchanged_count=0
    while [[ ! -e "${all_motl_fn_prefix}_$((iteration + 1)).em" ]]
    do
        unchanged_count=$((unchanged_count + 1))
        if [[ ${unchanged_count} -gt 60 ]]
        then
            echo "MOTL join has seemed to stall"
            echo "Please check error logs and resubmit the job if neeeded."
            exit 1
        fi  
        sleep 60s
    done
################################################################################
#                              MOTL JOIN CLEAN UP                              #
################################################################################
    if [[ ! -d "${scratch_dir}/ali_${iteration}" ]]
    then
        mkdir "${scratch_dir}/ali_${iteration}"
    fi

    if [[ -e "${job_name}_joinmotl_${iteration}" ]]
    then
        mv -f "${job_name}_joinmotl_${iteration}" \
            "${scratch_dir}/ali_${iteration}/."
    fi

    if [[ -e "log_${job_name}_joinmotl_${iteration}" ]]
    then
        mv -f "log_${job_name}_joinmotl_${iteration}" \
            "${scratch_dir}/ali_${iteration}/."
    fi

    if [[ -e "error_${job_name}_joinmotl_${iteration}" ]]
    then
        mv -f "log_${job_name}_joinmotl_${iteration}" \
            "${scratch_dir}/ali_${iteration}/."
    fi

    ptcl_motl_dir=$(dirname ${scratch_dir}/${ptcl_motl_fn_prefix})
    ptcl_motl_base=$(basename ${scratch_dir}/${ptcl_motl_fn_prefix})
    find ${ptcl_motl_dir} -name "${ptcl_motl_base}_[0-9]*_${iteration}.em" \
        -delete

    echo "FINISHED MOTL Join in Iteration Number: ${iteration}"
################################################################################
#                              PARALLEL AVERAGING                              #
################################################################################
    # Generate and launch array files
    # Calculate number of job scripts needed
    num_avg_jobs=$(((num_avg_batch + array_max - 1) / array_max))
    array_start=1

    # Averaging scripts generate the reference for a given iteration number
    # since the alignment has output the allmotl for the next iteration we use
    # the next iteration to pass to the averaging executables
    avg_iteration=$((iteration + 1))
    # Loop to generate parallel alignment scripts
    for ((job_idx=1; job_idx <= num_avg_jobs; job_idx++))
    do
        array_end=$((array_start + array_max - 1))
        if [[ ${array_end} -gt ${num_avg_batch} ]]
        then
            array_end=${num_avg_batch}
        fi

        cat > ${job_name}_paral_avg_array_${avg_iteration}_${job_idx}<<-PAVGJOB
#!/bin/bash
#$ -N ${job_name}_paral_avg_array_${avg_iteration}_${job_idx}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${mem_free_avg},h_vmem=${mem_max_avg}
#$ -o log_${job_name}_paral_avg_array_${avg_iteration}_${job_idx}
#$ -e error_${job_name}_paral_avg_array_${avg_iteration}_${job_idx}
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
process_idx=\${SGE_TASK_ID}
check="${ref_fn_prefix}_${avg_iteration}_\${process_idx}.em"
if [[ -f "\${check}" ]]
then
    echo "\${check} already complete. SKIPPING"
    exit 0
fi
MCRDIR=${mcr_cache_dir}/${job_name}_paral_avg_\${process_idx}
rm -rf \${MCRDIR}
mkdir \${MCRDIR}
export MCR_CACHE_ROOT=\${MCRDIR}
ptcl_start_idx=\$(((${avg_batch_size} * (process_idx - 1)) + 1))
time ${paral_avg_exec} \\
\${ptcl_start_idx} \\
${avg_batch_size} \\
${avg_iteration} \\
${all_motl_fn_prefix} \\
${ref_fn_prefix} \\
${ptcl_fn_prefix} \\
${tomo_row} \\
${weight_fn_prefix} \\
${weight_sum_fn_prefix} \\
${iclass} \\
\${process_idx} \\
rm -rf \${MCRDIR}
PAVGJOB
        qsub ${job_name}_paral_avg_array_${avg_iteration}_${job_idx}
        array_start=$((array_start + array_max))
    done

    echo "STARTING Parallel Average in Iteration Number: ${avg_iteration}"
################################################################################
#                         PARALLEL AVERAGING PROGRESS                          #
################################################################################
    ref_dir=$(dirname ${scratch_dir}/${ref_fn_prefix})
    ref_base=$(basename ${scratch_dir}/${ref_fn_prefix})_${iteration}
    num_complete=$(find ${ref_dir} -name "${ref_base}_*.em" | wc -l)
    num_complete_prev=0
    unchanged_count=0
    while [ ${num_complete} -lt ${num_avg_batch} ]
    do
        num_complete=$(find ${ref_dir} -name "${ref_base}_*.em" | wc -l)
        echo "${num_complete} parallel average out of ${num_avg_batch}"
        if [[ ${num_complete} -eq ${num_complete_prev} ]]
        then
            unchanged_count=$((unchanged_count + 1))
        else
            unchanged_count=0
        fi
        num_complete_prev=${num_complete}
        
        if [[ ${num_complete} -gt 0 && ${unchanged_count} -gt 120 ]]
        then
            echo "Parallel averaging has seemed to stall"
            echo "Please check error logs and resubmit the job if neeeded."
            exit 1
        fi
        sleep 60s
    done
################################################################################
#                         PARALLEL AVERAGING CLEAN UP                          #
################################################################################
    if [[ ! -d "${scratch_dir}/avg_${iteration}" ]]
    then
        mkdir "${scratch_dir}/avg_${iteration}"
    fi

    if [[ -e "${job_name}_paral_avg_array_${iteration}_1" ]]
    then
        mv -f "${job_name}_paral_avg_array_${iteration}"_* \
            "${scratch_dir}/avg_${iteration}/."
    fi

    if [[ -e "log_${job_name}_paral_avg_array_${iteration}_1" ]]
    then
        mv -f "log_${job_name}_paral_avg_array_${iteration}"_* \
            "${scratch_dir}/avg_${iteration}/."
    fi

    if [[ -e "error_${job_name}_paral_avg_array_${iteration}_1" ]]
    then
        mv -f "error_${job_name}_paral_avg_array_${iteration}"_* \
            "${scratch_dir}/avg_${iteration}/."
    fi

    echo "FINISHED Parallel Average in Iteration Number: ${iteration}"
################################################################################
#                                FINAL AVERAGE                                 #
################################################################################
    cat > ${job_name}_avg_${avg_iteration} <<-AVGJOB
#!/bin/bash
#$ -N ${job_name}_avg_${avg_iteration}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${mem_free_avg},h_vmem=${mem_max_avg}
#$ -o log_${job_name}_avg_${avg_iteration}
#$ -e error_${job_name}_avg_${avg_iteration}
set +o noclobber
set -e

echo \${HOSTNAME}
ldpath=/lmb/home/public/matlab/jbriggs/runtime/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/bin/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=\${ldpath}
cd ${scratch_dir}
check="${ref_fn_prefix}_${avg_iteration}.em"
if [[ -f "\${check}" ]]
then
    echo "\${check} already complete. SKIPPING"
    exit 0
fi
MCRDIR=${mcr_cache_dir}/${job_name}_avg_${avg_iteration}
rm -rf \${MCRDIR}
mkdir \${MCRDIR}
export MCR_CACHE_ROOT=\${MCRDIR}
time ${avg_exec} \\
${ref_fn_prefix} \\
${all_motl_fn_prefix} \\
${weight_sum_fn_prefix} \\
${avg_iteration} \\
${iclass}
rm -rf \${MCRDIR}
AVGJOB

    qsub ${job_name}_avg_${avg_iteration}
    echo "STARTING Final Average in Iteration Number ${avg_iteration}"
################################################################################
#                            FINAL AVERAGE PROGRESS                            #
################################################################################
    unchanged_count=0
    while [[ ! -e "${scratch_dir}/${ref_fn_prefix}_${iteration}.em" ]]
    do
        unchanged_count=$((unchanged_count + 1))
        if [[ ${unchanged_count} -gt 60 ]]
        then
            echo "Final averaging has seemed to stall"
            echo "Please check error logs and resubmit the job if neeeded."
            exit 1
        fi
        sleep 60s
    done
################################################################################
#                            FINAL AVERAGE CLEAN UP                            #
################################################################################
    ### Copy file to group share
    cp ${scratch_dir}/${ref_fn_prefix}_${iteration}.em \
        ${local_dir}/${ref_fn_prefix}_${iteration}.em

    if [[ -e "${job_name}_avg_${iteration}" ]]
    then
        mv ${job_name}_avg_${iteration} \
            ${scratch_dir}/avg_${iteration}/.
    fi

    if [[ -e "log_${job_name}_avg_${iteration}" ]]
    then
        mv log_${job_name}_avg_${iteration} \
            ${scratch_dir}/avg_${iteration}/.
    fi

    if [[ -e "error_${job_name}_avg_${iteration}" ]]
    then
        mv error_${job_name}_avg_${iteration} \
            ${scratch_dir}/avg_${iteration}/.
    fi

    ref_dir=$(dirname ${scratch_dir}/${ref_fn_prefix})
    ref_base=$(basename ${scratch_dir}/${ref_fn_prefix})_${avg_iteration}
    weight_sum_dir=$(dirname ${scratch_dir}/${weight_sum_fn_prefix})
    weight_sum_base=$(basename ${scratch_dir}/${weight_sum_fn_prefix})
    weight_sum_base=${weight_sum_base}_${avg_iteration}
    find ${ref_dir} -name "${ref_base}_[0-9]*.em" -delete
    find ${weight_sum_dir} -name "${weight_sum_base}_[0-9]*.em" -delete

    echo "FINISHED Final Average in Iteration Number: ${avg_iteration}"
    echo "AVERAGE DONE IN ITERATION NUMBER ${avg_iteration}"
    next_iteration=$((iteration + 1))
done
