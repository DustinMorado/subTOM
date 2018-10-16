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
# - parallel_sums
# - weighted_average
# DRM 09-2017
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
unset ml
unset module
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the root folder for subtomogram extraction.
# Other paths are relative to this one.
scratch_dir=<SCRATCH_DIR>

# Absolute path to the folder on a group share, if your scratch directory is
# cleaned and deleted regularly you can set a local directory to which you can
# copy the important results. If you do not need to do this, you can skip this
# step with the option skip_local_copy below.
local_dir=<LOCAL_DIR>

# Absolute path to the MCR directory for each job
mcr_cache_dir=${scratch_dir}/mcr

# Directory for executables
exec_dir=XXXINSTALLATION_DIRXXX/bin

################################################################################
#                                  VARIABLES                                   #
################################################################################
# Parallel Summing executable
sum_exec=${exec_dir}/parallel_sums

# Final Averaging executable
avg_exec=${exec_dir}/weighted_average

################################################################################
#                                MEMORY OPTIONS                                #
################################################################################
# The amount of memory your job requires
# e.g. mem_free='10G'
mem_free=<MEM_FREE>

# The upper bound on the amount of memory your job is allowed to use
#mem_max='15G'
mem_max=<MEM_MAX>

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
# The index of the reference to generate : input will be
# all_motl_fn_prefix_iteration.em (define as integer e.g. iteration=1)
iteration=<ITERATION>

# Total number of particles
num_ptcls=<NUM_PTCLS>

# Number of particles in each parallel subtomogram averaging job
avg_batch_size=<AVG_BATCH_SIZE>

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name prefix of the concatenated motivelist of all particles
# (e.g.  allmotl_iter.em , the variable will be written as a string e.g.
# all_motl_fn_prefix='sub-directory/allmotl')
all_motl_fn_prefix=<ALL_MOTL_FN_PREFIX>

# Relative path and name prefix of the reference volumes (e.g.  ref_iter.em, the
# variable will be written as a string e.g.  ref_fn_prefix='sub-directory/ref')
ref_fn_prefix=<REF_FN_PREFIX>

# Relative path and name prefix of the subtomograms (e.g. part_n.em, the
# variable will be written as a string e.g.
# ptcl_fn_prefix='sub-directory/part')
ptcl_fn_prefix=<PTCL_FN_PREFIX>

# Relative path and name prefix of the weight file.
weight_fn_prefix=<WEIGHT_FN_PREFIX>

# Relative path and name prefix of the partial weight files.
weight_sum_fn_prefix=<WEIGHT_SUM_FN_PREFIX>

################################################################################
#                              AVERAGING OPTIONS                               #
################################################################################
# Which row in the motl file contains the correct tomogram number.
# Usually row 5 and 7 both correspond to the correct value and can be used
# interchangeably, but there are instances when 5 contains a sequential ordered
# value starting from 1, while 7 contains the correct corresponding tomogram.
tomo_row=7

# Particles with that number in position 20 of motivelist will be added to new
# average (define as integer e.g. iclass=1). NOTES: Class 1 is ALWAYS added.
# Negative classes and class 0 are never added.
iclass=1

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
# Check number of jobs
num_avg_batch=$(((num_ptcls + avg_batch_size - 1) / avg_batch_size))
if [[ ${num_avg_batch} -gt ${max_jobs} ]]
then
    echo " TOO MANY JOBS!!!!!  I QUIT!!!"
    exit 1
fi

# Check that the appropriate directories exist
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

    if [[ ! -d $(dirname ${local_dir}/${weight_sum_fn_prefix}) ]]
    then
        mkdir -p $(dirname ${local_dir}/${weight_sum_fn_prefix})
    fi
fi

oldpwd=$(pwd)
cd ${scratch_dir}
if [[ ! -d ${mcr_cache_dir} ]]
then
    mkdir -p ${mcr_cache_dir}
fi

if [[ ! -d $(dirname ${ref_fn_prefix}) ]]
then
    mkdir -p $(dirname ${ref_fn_prefix})
fi

if [[ ! -d $(dirname ${weight_sum_fn_prefix}) ]]
then
    mkdir -p $(dirname ${weight_sum_fn_prefix})
fi

cd ${oldpwd}
job_name=${job_name}_paral_avg

if [[ ${mem_free%G} -ge 24 ]]
then
    dedmem=',dedicated=12'
else
    dedmem=''
fi
################################################################################
#                                                                              #
#                        SUBTOMOGRAM AVERAGING WORKFLOW                        #
#                                                                              #
################################################################################
#                              PARALLEL AVERAGING                              #
################################################################################
# Generate and launch array files
# Calculate number of job scripts needed
num_avg_jobs=$(((num_avg_batch + array_max - 1) / array_max))
ref_fn=${ref_fn_prefix}_${iteration}.em

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

    cat > ${job_name}_${iteration}_${job_idx}<<-PAVGJOB
#!/bin/bash
#$ -N ${job_name}_${iteration}_${job_idx}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${mem_free},h_vmem=${mem_max}${dedmem}
#$ -o log_${job_name}_${iteration}_${job_idx}
#$ -e error_${job_name}_${iteration}_${job_idx}
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
    mcr_cache_dir=${mcr_cache_dir}/${job_name}_${job_idx}_\${SGE_TASK_ID}
    if [[ ! -d \${mcr_cache_dir} ]]
    then
        mkdir -p \${mcr_cache_dir}
    else
        rm -rf \${mcr_cache_dir}
        mkdir -p \${mcr_cache_dir}
    fi

    export MCR_CACHE_ROOT=\${mcr_cache_dir}
    check="${ref_fn_prefix}_${iteration}_\${SGE_TASK_ID}.em"
    if [[ -f "\${check}" ]]
    then
        echo "\${check} already complete. SKIPPING"
        continue
    fi

    ptcl_start_idx=\$(((${avg_batch_size} * (SGE_TASK_ID - 1)) + 1))
    time ${sum_exec} \\
        \${ptcl_start_idx} \\
        ${avg_batch_size} \\
        ${iteration} \\
        ${all_motl_fn_prefix} \\
        ${ref_fn_prefix} \\
        ${ptcl_fn_prefix} \\
        ${tomo_row} \\
        ${weight_fn_prefix} \\
        ${weight_sum_fn_prefix} \\
        ${iclass} \\
        \${SGE_TASK_ID}
    rm -rf \${mcr_cache_dir}
###done 2> error_${job_name}_${iteration}_${job_idx} >\\
###log_${job_name}_${iteration}_${job_idx}
PAVGJOB
    cd ${scratch_dir}
    if [[ ! -e "${ref_fn}" ]]
    then
        cd ${oldpwd}
        if [[ ${run_local} -eq 1 ]]
        then
            mv ${job_name}_${iteration}_${job_idx} temp_array
            sed 's/\#\#\#//' temp_array > ${job_name}_${iteration}_${job_idx}
            rm temp_array
            chmod u+x ${job_name}_${iteration}_${job_idx}
            ./${job_name}_${iteration}_${job_idx} &
        else
            qsub ${job_name}_${iteration}_${job_idx}
        fi
    fi
done

echo "STARTING Parallel Average in Iteration Number: ${iteration}"
################################################################################
#                         PARALLEL AVERAGING PROGRESS                          #
################################################################################
cd ${scratch_dir}
ref_dir=$(dirname ${ref_fn_prefix})
ref_base=$(basename ${ref_fn_prefix})_${iteration}
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
cd ${oldpwd}
if [[ ! -d avg_${iteration} ]]
then
    mkdir avg_${iteration}
fi

if [[ -e ${job_name}_${iteration}_1 ]]
then
    mv -f ${job_name}_${iteration}_* avg_${iteration}/.
fi

if [[ -e log_${job_name}_${iteration}_1 ]]
then
    mv -f log_${job_name}_${iteration}_* avg_${iteration}/.
fi

if [[ -e error_${job_name}_${iteration}_1 ]]
then
    mv -f error_${job_name}_${iteration}_* avg_${iteration}/.
fi

echo "FINISHED Parallel Average in Iteration Number: ${iteration}"
################################################################################
#                                FINAL AVERAGE                                 #
################################################################################
job_name=${job_name/%_paral_avg/_avg}
cat > ${job_name}_${iteration} <<-AVGJOB
#!/bin/bash
#$ -N ${job_name}_${iteration}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${mem_free},h_vmem=${mem_max}${dedmem}
#$ -o log_${job_name}_${iteration}
#$ -e error_${job_name}_${iteration}
set +o noclobber
set -e

echo \${HOSTNAME}
ldpath=XXXMCR_DIRXXX/runtime/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/bin/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=\${ldpath}
cd ${scratch_dir}

if [[ -f ${ref_fn} ]]
then
    echo "${ref_fn} already complete. SKIPPING"
    exit 0
fi

mcr_cache_dir=${mcr_cache_dir}/${job_name}_${iteration}
if [[ ! -d \${mcr_cache_dir} ]]
then
    mkdir -p \${mcr_cache_dir}
else
    rm -rf \${mcr_cache_dir}
    mkdir -p \${mcr_cache_dir}
fi

export MCR_CACHE_ROOT=\${mcr_cache_dir}
time ${avg_exec} \\
    ${ref_fn_prefix} \\
    ${all_motl_fn_prefix} \\
    ${weight_sum_fn_prefix} \\
    ${iteration} \\
    ${iclass}
rm -rf \${mcr_cache_dir}
AVGJOB

cd ${scratch_dir}
if [[ ! -e ${ref_fn} ]]
then
    cd ${oldpwd}
    if [[ ${run_local} -eq 1 ]]
    then
        chmod u+x ${job_name}_${iteration}
        ./${job_name}_${iteration} &
    else
        qsub ${job_name}_${iteration}
    fi
fi

echo "STARTING Final Average in Iteration Number: ${iteration}"
################################################################################
#                            FINAL AVERAGE PROGRESS                            #
################################################################################
cd ${scratch_dir}
echo "Waiting for the final average ..."
unchanged_count=0
while [[ ! -e ${ref_fn} ]]
do
    if [[ -d ${mcr_cache_dir}/${job_name}_${iteration} ]]
    then
        unchanged_count=$((unchanged_count + 1))
    fi

    if [[ ${unchanged_count} -gt 120 ]]
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
cd ${oldpwd}
if [[ ${skip_local_copy} -ne 1 ]]
then
    cp ${scratch_dir}/${ref_fn_prefix}_${iteration}.em \
        ${local_dir}/${ref_fn_prefix}_${iteration}.em

    cp ${scratch_dir}/${weight_sum_fn_prefix}_debug_${iteration}.em \
        ${local_dir}/${weight_sum_fn_prefix}_debug_${iteration}.em 

    cp ${scratch_dir}/${weight_sum_fn_prefix}_debug_inv_${iteration}.em \
        ${local_dir}/${weight_sum_fn_prefix}_debug_inv_${iteration}.em 
fi

if [[ -e ${job_name}_${iteration} ]]
then
    mv ${job_name}_${iteration} avg_${iteration}/.
fi

if [[ -e log_${job_name}_${iteration} ]]
then
    mv log_${job_name}_${iteration} avg_${iteration}/.
fi

if [[ -e error_${job_name}_${iteration} ]]
then
    mv error_${job_name}_${iteration} avg_${iteration}/.
fi

ref_dir=$(dirname ${scratch_dir}/${ref_fn_prefix})
ref_base=$(basename ${scratch_dir}/${ref_fn_prefix})_${iteration}
weight_sum_dir=$(dirname ${scratch_dir}/${weight_sum_fn_prefix})
weight_sum_base=$(basename ${scratch_dir}/${weight_sum_fn_prefix})_${iteration}
find ${ref_dir} -name "${ref_base}_[0-9]*.em" -delete
find ${weight_sum_dir} -name "${weight_sum_base}_[0-9]*.em" -delete

echo "FINISHED Final Average in Iteration Number: ${iteration}"
echo "AVERAGE DONE IN ITERATION NUMBER ${iteration}"
