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
# - scan_angles_exact
# - join_motls
# - parallel_sums
# - weighted_average
# - compare_motls
# DRM 11-2017
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Root folder on the scratch
scratch_dir=<SCRATCH_DIR>

# Folder on group shares
local_dir=<LOCAL_DIR>

# MRC directory for each job
mcr_cache_dir="${scratch_dir}/mcr"

# Directory for executables
exec_dir=XXXINSTALLATION_DIRXXX/bin

################################################################################
#                                  VARIABLES                                   #
################################################################################
# Alignment executable
align_exec=${exec_dir}/scan_angles_exact

# MOTL join executable
join_exec=${exec_dir}/join_motls

# Parallel Averaging executable
paral_avg_exec=${exec_dir}/parallel_sums

# Final Averaging executable
avg_exec=${exec_dir}/weighted_average

# Compare MOTLs executable
compare_exec=${exec_dir}/compare_motls

################################################################################
#                                MEMORY OPTIONS                                #
################################################################################
# The amount of memory your job requires
# e.g. mem_free_ali='2G'
mem_free_ali=<MEM_FREE_ALI>

# The upper bound on the amount of memory your job is allowed to use
# e.g. mem_max_ali='3G'
mem_max_ali=<MEM_MAX_ALI>

# The amount of memory your job requires
# e.g. mem_free_avg='2G'
mem_free_avg=<MEM_FREE_AVG>

# The upper bound on the amount of memory your job is allowed to use
# e.g. mem_max_avg='3G'
mem_max_avg=<MEM_MAX_AVG>

################################################################################
#                              OTHER LSF OPTIONS                               #
################################################################################
# BE CAREFUL THAT THE NAME DOESN'T CORRESPOND TO THE BEGINNING OF ANY OTHER FILE
job_name=<JOB_NAME>

# Maximum number of jobs per array
array_max=1000

# Maximum number of jobs per user
max_jobs=4000

# If you want to skip the cluster and run the job locally set this to 1.
run_local=0

# If you want to skip the copying of data to local_dir set this to 1.
skip_local_copy=1
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
start_iteration=<START_ITERATION>

# Number iterations (big loop) to run: final output will be
# reference_startindx+iterations.em and motilvelist_startindx+iterations.em
iterations=<ITERATIONS>

# Total number of particles
num_ptcls=<NUM_PTCLS>

# Number of particles in each parallel subtomogram alignment job (define as
# integer e.g. batchnumberofparticles=3)
ali_batch_size=<ALI_BATCH_SIZE>

# Number of particles in each parallel subtomogram averaging job
avg_batch_size=<AVG_BATCH_SIZE>

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name of the motivelist of the single particle (e.g.
# part_n.em will have a motl_n_iter.em , the variable will be written as a
# string e.g. ptcl_motl_fn_prefix='sub-directory/motl')
ptcl_motl_fn_prefix=<PTCL_MOTL_FN_PREFIX>

# Relative path and name of the concatenated motivelist of all particles (e.g.
# allmotl_iter.em , the variable will be written as a string e.g.
# all_motl_fn_prefix='sub-directory/allmotl')
all_motl_fn_prefix=<ALL_MOTL_FN_PREFIX>

# Relative path and name of the reference volumes (e.g. ref_iter.em , the
# variable will be written as a string e.g. ref_fn_prefix='sub-directory/ref')
ref_fn_prefix=<REF_FN_PREFIX>

# Relative path and name of the subtomograms (e.g. part_n.em , the variable will
# be written as a string e.g. ptcl_fn_prefix='sub-directory/part')
ptcl_fn_prefix=<PTCL_FN_PREFIX>

# Relative path and name of the alignment mask
# Leave the parentheses and if the number of values is less than the number of
# iterations the last value will be repeated to the correct length
# e.g. align_mask_fn=('otherinputs/align_mask_1.em' \
#                     'otherinputs/align_mask_2.em' \
#                     'otherinputs/align_mask_3.em')
align_mask_fn=(<ALIGN_MASK_FN>)

# Relative path and name of the cross-correlation mask this defines the maximum
# shifts in each direction
# Leave the parentheses and if the number of values is less than the number of
# iterations the last value will be repeated to the correct length
# e.g. cc_mask_fn=('otherinputs/cc_mask_1.em' \
#                  'otherinputs/cc_mask_5.em')
cc_mask_fn=(<CC_MASK_FN>)

# Relative path and name of the weight file
weight_fn_prefix=<WEIGHT_FN_PREFIX>

# Relative path and name of the partial weight files
weight_sum_fn_prefix=<WEIGHT_SUM_FN_PREFIX>

################################################################################
#                       ALIGNMENT AND AVERAGING OPTIONS                        #
################################################################################
# Which row in the motl file contains the correct tomogram number.
# Usually row 5 and 7 both correspond to the correct value and can be used
# interchangeably, but there are instances when 5 contains a sequential ordered
# value starting from 1, while 7 contains the correct corresponding tomogram.
tomo_row=7

# Apply weight to subtomograms (1=yes, 0=no)
apply_weight=0

# Apply mask to subtomograms (1=yes, 0=no)
apply_mask=1

# Angular increment in degrees, applied during the cone-search, i.e. psi and
# theta (define as real e.g. psi_angle_step=3)
# Leave the parentheses and if the number of values is less than the number of
# iterations the last value will be repeated to the correct length
# e.g. psi_angle_step=(10 5 2.5 1 1)
psi_angle_step=(<PSI_ANGLE_STEP>)

# Number of angular iterations, applied to psi and theta  (define as integer
# e.g. psi_angle_shells=3)
# Leave the parentheses and if the number of values is less than the number of
# iterations the last value will be repeated to the correct length
# e.g. psi_angle_shells=(3)
psi_angle_shells=(<PSI_ANGLE_SHELLS>)

# Angular increment for phi in degrees, (define as real e.g. phi_angle_step=3)
# Leave the parentheses and if the number of values is less than the number of
# iterations the last value will be repeated to the correct length
phi_angle_step=(<PHI_ANGLE_STEP>)

# Number of angular iterations for phi, (define as integer e.g.
# phi_angle_shells=3)
# Leave the parentheses and if the number of values is less than the number of
# iterations the last value will be repeated to the correct length
phi_angle_shells=(<PHI_ANGLE_SHELLS>)

# High pass filter (in transform units (pixels): calculate as
# (boxsize*pixelsize)/(resolution_real) (define as integer e.g. high_pass_fp=2)
# Leave the parentheses and if the number of values is less than the number of
# iterations the last value will be repeated to the correct length
# e.g. high_pass_fp=(1 1 2 3)
high_pass_fp=(<HIGH_PASS_FP>)

# Low pass filter (in transform units (pixels): calculate as
# (boxsize*pixelsize)/(resolution_real) (define as integer e.g.
# low_pass_fp=30), has a Gaussian dropoff of ~2 pixels
# Leave the parentheses and if the number of values is less than the number of
# iterations the last value will be repeated to the correct length
low_pass_fp=(<LOW_PASS_FP>)

# Symmetry, if no symmetry nfold=1 (define as integer e.g. nfold=3)
nfold=<NFOLD>

# Threshold for cross correlation coefficient. Only particles with ccc_new >
# threshold will be added to new average (define as real e.g. threshold=0.5).
# These particles will still be aligned at each iteration
threshold=-1

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
if [[ ${skip_local_copy} -ne 1 ]]
then
    if [[ ! -d ${local_dir} ]]
    then
        mkdir -p ${local_dir}
    fi

    if [[ ! -d $(dirname ${local_dir}/${ref_fn_prefix}) ]]
    then
        mkdir -p $(dirname ${local_dir}/${ref_fn_prefix})
    fi

    if [[ ! -d $(dirname ${local_dir}/${all_motl_fn_prefix}) ]]
    then
        mkdir -p $(dirname ${local_dir}/${all_motl_fn_prefix})
    fi

    if [[ ! -d $(dirname ${local_dir}/${weight_sum_fn_prefix}) ]]
    then
        mkdir -p $(dirname ${local_dir}/${weight_sum_fn_prefix})
    fi
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

# Calculate the number of array subset jobs we will submit
num_ali_jobs=$(((num_ali_batch + array_max - 1) / array_max))
num_avg_jobs=$(((num_avg_batch + array_max - 1) / array_max))

# Check that number of iterations is inline with the arrays of parameters
while [[ ${#align_mask_fn[@]} -lt ${iterations} ]]
do
    idx=${#align_mask_fn[@]}
    val=${align_mask_fn[$((idx - 1))]}
    align_mask_fn[${idx}]=${val}
done

while [[ ${#cc_mask_fn[@]} -lt ${iterations} ]]
do
    idx=${#cc_mask_fn[@]}
    val=${cc_mask_fn[$((idx - 1))]}
    cc_mask_fn[${idx}]=${val}
done

while [[ ${#psi_angle_step[@]} -lt ${iterations} ]]
do
    idx=${#psi_angle_step[@]}
    val=${psi_angle_step[$((idx - 1))]}
    psi_angle_step[${idx}]=${val}
done

while [[ ${#psi_angle_shells[@]} -lt ${iterations} ]]
do
    idx=${#psi_angle_shells[@]}
    val=${psi_angle_shells[$((idx - 1))]}
    psi_angle_shells[${idx}]=${val}
done

while [[ ${#phi_angle_step[@]} -lt ${iterations} ]]
do
    idx=${#phi_angle_step[@]}
    val=${phi_angle_step[$((idx - 1))]}
    phi_angle_step[${idx}]=${val}
done

while [[ ${#phi_angle_shells[@]} -lt ${iterations} ]]
do
    idx=${#phi_angle_shells[@]}
    val=${phi_angle_shells[$((idx - 1))]}
    phi_angle_shells[${idx}]=${val}
done

while [[ ${#high_pass_fp[@]} -lt ${iterations} ]]
do
    idx=${#high_pass_fp[@]}
    val=${high_pass_fp[$((idx - 1))]}
    high_pass_fp[${idx}]=${val}
done

while [[ ${#low_pass_fp[@]} -lt ${iterations} ]]
do
    idx=${#low_pass_fp[@]}
    val=${low_pass_fp[$((idx - 1))]}
    low_pass_fp[${idx}]=${val}
done

# Calculate the final iteration
end_iteration=$((start_iteration + iterations - 1))
################################################################################
#                                                                              #
#                        SUBTOMOGRAM AVERAGING WORKFLOW                        #
#                                                                              #
################################################################################
for ((iteration = start_iteration, array_idx = 0; \
      iteration <= end_iteration; \
      iteration++, array_idx++))
do
    avg_iteration=$((iteration + 1))
    all_motl_fn="${scratch_dir}/${all_motl_fn_prefix}_${avg_iteration}.em"
    motl_dir=$(dirname ${scratch_dir}/${ptcl_motl_fn_prefix})
    motl_base=$(basename ${scratch_dir}/${ptcl_motl_fn_prefix})
    ptcl_motl_dir=$(dirname ${scratch_dir}/${ptcl_motl_fn_prefix})
    ptcl_motl_base=$(basename ${scratch_dir}/${ptcl_motl_fn_prefix})
    ref_fn="${scratch_dir}/${ref_fn_prefix}_${avg_iteration}.em"
    ref_dir=$(dirname ${scratch_dir}/${ref_fn_prefix})
    ref_base=$(basename ${scratch_dir}/${ref_fn_prefix})_${avg_iteration}
    weight_sum_dir=$(dirname ${scratch_dir}/${weight_sum_fn_prefix})
    weight_sum_base=$(basename ${scratch_dir}/${weight_sum_fn_prefix})
    weight_sum_base=${weight_sum_base}_${avg_iteration}
    comparison_fn="${scratch_dir}/${all_motl_fn_prefix}_${iteration}"
    comparison_fn="${comparison_fn}_${avg_iteration}_diff.csv"
    echo "            ITERATION number ${iteration}"
################################################################################
#                            SUBTOMOGRAM ALIGNMENT                             #
################################################################################
    # Generate and launch array files
    for ((job_idx = 1, array_start = 1; \
          job_idx <= num_ali_jobs; \
          job_idx++, array_start += array_max))
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
ldpath=XXXMCR_DIRXXX/runtime/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/bin/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=\${ldpath}
cd ${scratch_dir}
###for SGE_TASK_ID in {${array_start}..${array_end}}; do
process_idx=\${SGE_TASK_ID}
if [[ -f "${all_motl_fn}" ]]
then
    echo "${all_motl_fn} already complete. SKIPPING"
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
${align_mask_fn[${array_idx}]} \\
${apply_mask} \\
${cc_mask_fn[${array_idx}]} \\
${psi_angle_step[${array_idx}]} \\
${psi_angle_shells[${array_idx}]} \\
${phi_angle_step[${array_idx}]} \\
${phi_angle_shells[${array_idx}]} \\
${high_pass_fp[${array_idx}]} \\
${low_pass_fp[${array_idx}]} \\
${nfold} \\
${threshold} \\
${iclass}
rm -rf \${MCRDIR}
###done 2> error_${job_name}_ali_array_${iteration}_${job_idx} >\\
###log_${job_name}_ali_array_${iteration}_${job_idx}
ALIJOB
        if [[ ! -e "${all_motl_fn}" ]]
        then
            if [[ ${run_local} -eq 1 ]]
            then
                mv ${job_name}_ali_array_${iteration}_${job_idx} temp_array
                sed 's/\#\#\#//' temp_array > \
                    ${job_name}_ali_array_${iteration}_${job_idx}
                rm temp_array
                chmod u+x ${job_name}_ali_array_${iteration}_${job_idx}
                ./${job_name}_ali_array_${iteration}_${job_idx} &
            else
                qsub ${job_name}_ali_array_${iteration}_${job_idx}
            fi
        fi
    done

    echo "STARTING Alignment in Iteration Number: ${iteration}"
################################################################################
#                              ALIGNMENT PROGRESS                              #
################################################################################
    num_complete=$(find ${motl_dir} -name \
        "${motl_base}_*_${avg_iteration}.em" | wc -l)
    num_complete_prev=0
    unchanged_count=0
    while [[ ${num_complete} -lt ${num_ptcls} && ! -e "${all_motl_fn}" ]]
    do
        num_complete=$(find ${motl_dir} -name \
            "${motl_base}_*_${avg_iteration}.em" | wc -l)
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
        mv -f "error_${job_name}_ali_array_${iteration}"_* \
            "${scratch_dir}/ali_${iteration}/."
    fi

    echo "FINISHED Alignment in Iteration Number: ${iteration}"
################################################################################
#                           COLLECT & COMBINE MOTLS                            #
################################################################################
    cat > ${job_name}_join_motl_${iteration} <<-JOINJOB
#!/bin/bash
#$ -N ${job_name}_join_motl_${iteration}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${mem_free_ali},h_vmem=${mem_max_ali}
#$ -o log_${job_name}_join_motl_${iteration}
#$ -e error_${job_name}_join_motl_${iteration}
set +o noclobber
set -e
echo \${HOSTNAME}
ldpath=XXXMCR_DIRXXX/runtime/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/bin/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=\${ldpath}
cd ${scratch_dir}
if [[ -f "${all_motl_fn}" ]]
then
    echo "${all_motl_fn} already complete. SKIPPING"
    exit 0
fi
MCRDIR=${mcr_cache_dir}/${job_name}_join_motl
rm -rf \${MCRDIR}
mkdir \${MCRDIR}
export MCR_CACHE_ROOT=\${MCRDIR}
time ${join_exec} \\
${iteration} \\
${all_motl_fn_prefix} \\
${ptcl_motl_fn_prefix}
rm -rf \${MCRDIR}
JOINJOB

    if [[ ! -e "${all_motl_fn}" ]]
    then
        if [[ ${run_local} -eq 1 ]]
        then
            chmod u+x ./${job_name}_join_motl_${iteration}
            ./${job_name}_join_motl_${iteration} &
        else
            qsub ${job_name}_join_motl_${iteration}
        fi
    fi
    echo "STARTING MOTL Join in Iteration Number: ${iteration}"
################################################################################
#                              MOTL JOIN PROGRESS                              #
################################################################################
    unchanged_count=0
    while [[ ! -e "${all_motl_fn}" ]]
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

    if [[ -e "${job_name}_join_motl_${iteration}" ]]
    then
        mv -f "${job_name}_join_motl_${iteration}" \
            "${scratch_dir}/ali_${iteration}/."
    fi

    if [[ -e "log_${job_name}_join_motl_${iteration}" ]]
    then
        mv -f "log_${job_name}_join_motl_${iteration}" \
            "${scratch_dir}/ali_${iteration}/."
    fi

    if [[ -e "error_${job_name}_join_motl_${iteration}" ]]
    then
        mv -f "error_${job_name}_join_motl_${iteration}" \
            "${scratch_dir}/ali_${iteration}/."
    fi

    find ${ptcl_motl_dir} -name \
        "${ptcl_motl_base}_[0-9]*_${avg_iteration}.em" -delete

    echo "FINISHED MOTL Join in Iteration Number: ${iteration}"
################################################################################
#                              PARALLEL AVERAGING                              #
################################################################################
    # Averaging scripts generate the reference for a given iteration number
    # since the alignment has output the allmotl for the next iteration we use
    # the next iteration to pass to the averaging executables
    # Loop to generate parallel alignment scripts
    for ((job_idx = 1, array_start = 1; \
          job_idx <= num_avg_jobs; \
          job_idx++, array_start += array_max))
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
ldpath=XXXMCR_DIRXXX/runtime/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/bin/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=\${ldpath}
cd ${scratch_dir}
###for SGE_TASK_ID in {${array_start}..${array_end}}; do
process_idx=\${SGE_TASK_ID}
if [[ -f "${ref_fn}" ]]
then
    echo "${ref_fn} already complete. SKIPPING"
    exit 0
fi
check_process="${ref_fn_prefix}_${avg_iteration}_\${process_idx}.em"
if [[ -f "\${check_process}" ]]
then
    echo "\${check_process} already complete. SKIPPING"
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
\${process_idx}
rm -rf \${MCRDIR}
###done 2> error_${job_name}_paral_avg_array_${avg_iteration}_${job_idx} >\\
###log_${job_name}_paral_avg_array_${avg_iteration}_${job_idx}
PAVGJOB
        if [[ ! -e "${ref_fn}" ]]
        then
            if [[ ${run_local} -eq 1 ]]
            then
                mv ${job_name}_paral_avg_array_${avg_iteration}_${job_idx} \
                    temp_array
                sed 's/\#\#\#//' temp_array > \
                    ${job_name}_paral_avg_array_${avg_iteration}_${job_idx}
                rm temp_array
                chmod u+x \
                    ${job_name}_paral_avg_array_${avg_iteration}_${job_idx}
                ./${job_name}_paral_avg_array_${avg_iteration}_${job_idx} &
            else
                qsub ${job_name}_paral_avg_array_${avg_iteration}_${job_idx}
            fi
        fi
    done

    echo "STARTING Parallel Average in Iteration Number: ${avg_iteration}"
################################################################################
#                         PARALLEL AVERAGING PROGRESS                          #
################################################################################
    num_complete=$(find ${ref_dir} -name "${ref_base}_*.em" | wc -l)
    num_complete_prev=0
    unchanged_count=0
    while [[ ${num_complete} -lt ${num_avg_batch} && ! -e "${ref_fn}" ]]
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
    if [[ ! -d "${scratch_dir}/avg_${avg_iteration}" ]]
    then
        mkdir "${scratch_dir}/avg_${avg_iteration}"
    fi

    if [[ -e "${job_name}_paral_avg_array_${avg_iteration}_1" ]]
    then
        mv -f "${job_name}_paral_avg_array_${avg_iteration}"_* \
            "${scratch_dir}/avg_${avg_iteration}/."
    fi

    if [[ -e "log_${job_name}_paral_avg_array_${avg_iteration}_1" ]]
    then
        mv -f "log_${job_name}_paral_avg_array_${avg_iteration}"_* \
            "${scratch_dir}/avg_${avg_iteration}/."
    fi

    if [[ -e "error_${job_name}_paral_avg_array_${avg_iteration}_1" ]]
    then
        mv -f "error_${job_name}_paral_avg_array_${avg_iteration}"_* \
            "${scratch_dir}/avg_${avg_iteration}/."
    fi

    echo "FINISHED Parallel Average in Iteration Number: ${avg_iteration}"
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
ldpath=XXXMCR_DIRXXX/runtime/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/bin/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64
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

    if [[ ! -e "${ref_fn}" ]]
    then
        if [[ ${run_local} -eq 1 ]]
        then
            chmod u+x ${job_name}_avg_${avg_iteration}
            ./${job_name}_avg_${avg_iteration} &
        else
            qsub ${job_name}_avg_${avg_iteration}
        fi
    fi

    echo "STARTING Final Average in Iteration Number ${avg_iteration}"
################################################################################
#                            FINAL AVERAGE PROGRESS                            #
################################################################################
    unchanged_count=0
    while [[ ! -e "${ref_fn}" ]]
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
    if [[ ${skip_local_copy} -ne 1 ]]
    then
        cp ${scratch_dir}/${ref_fn_prefix}_${avg_iteration}.em \
            ${local_dir}/${ref_fn_prefix}_${avg_iteration}.em

        cp ${scratch_dir}/${all_motl_fn_prefix}_${avg_iteration}.em \
            ${local_dir}/${all_motl_fn_prefix}_${avg_iteration}.em

        cp ${scratch_dir}/${weight_sum_fn_prefix}_debug_${avg_iteration}.em \
            ${local_dir}/${weight_sum_fn_prefix}_debug_${avg_iteration}.em

        cp \
          ${scratch_dir}/${weight_sum_fn_prefix}_debug_inv_${avg_iteration}.em \
            ${local_dir}/${weight_sum_fn_prefix}_debug_${avg_iteration}.em
    fi

    if [[ -e "${job_name}_avg_${avg_iteration}" ]]
    then
        mv ${job_name}_avg_${avg_iteration} \
            ${scratch_dir}/avg_${avg_iteration}/.
    fi

    if [[ -e "log_${job_name}_avg_${avg_iteration}" ]]
    then
        mv log_${job_name}_avg_${avg_iteration} \
            ${scratch_dir}/avg_${avg_iteration}/.
    fi

    if [[ -e "error_${job_name}_avg_${avg_iteration}" ]]
    then
        mv error_${job_name}_avg_${avg_iteration} \
            ${scratch_dir}/avg_${avg_iteration}/.
    fi

    find ${ref_dir} -name "${ref_base}_[0-9]*.em" -delete
    find ${weight_sum_dir} -name "${weight_sum_base}_[0-9]*.em" -delete

    echo "FINISHED Final Average in Iteration Number: ${avg_iteration}"
    echo "AVERAGE DONE IN ITERATION NUMBER ${avg_iteration}"
################################################################################
#                        COMPARE CHANGES OVER ITERATION                        #
################################################################################
    cat > ${job_name}_compare_motl_${iteration} <<-COMPAREJOB
#!/bin/bash
set +o noclobber
set -e
echo \${HOSTNAME}
ldpath=XXXMCR_DIRXXX/runtime/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/bin/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=\${ldpath}
cd ${scratch_dir}
MCRDIR=${mcr_cache_dir}/${job_name}_compare_motl
rm -rf \${MCRDIR}
mkdir \${MCRDIR}
export MCR_CACHE_ROOT=\${MCRDIR}
${compare_exec} \\
${all_motl_fn_prefix}_${iteration}.em \\
${all_motl_fn_prefix}_${avg_iteration}.em \\
1 \\
${comparison_fn}
rm -rf \${MCRDIR}
COMPAREJOB
    chmod u+x ./${job_name}_compare_motl_${iteration}
    ./${job_name}_compare_motl_${iteration}
    rm ./${job_name}_compare_motl_${iteration}
done
