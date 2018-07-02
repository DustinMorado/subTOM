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
# This subtomogram parallel averaging script uses three MATLAB compiled scripts
# below:
# - subsets_parallel_sums
# - subsets_weighted_average
# - subsets_maskcorrected_FSC
# DRM 09-2017
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
mcr_cache_dir='mcr'

# Directory for executables
exec_dir=XXXINSTALLATION_DIRXXX/bin

################################################################################
#                                  VARIABLES                                   #
################################################################################
# Parallel Averaging executable
sum_exec=${exec_dir}/subsets_parallel_sums

# Final Averaging executable
avg_exec=${exec_dir}/subsets_weighted_average

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

################################################################################
#                                                                              #
#                    SUBTOMOGRAM AVERAGING WORKFLOW OPTIONS                    #
#                                                                              #
################################################################################
#                           PARALLELIZATION OPTIONS                            #
################################################################################
# The index of the reference to generate : input will be
# motilvelist_iteration.em (define as integer e.g. iteration=1)
iteration=<ITERATION>

# Total number of particles
num_ptcls=<NUM_PTCLS>

# Number of particles in each parallel subtomogram averaging job
avg_batch_size=<AVG_BATCH_SIZE>

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
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

# Relative path and name of the weight file
#weight_fn_prefix='../WNG_Wedge_Tests/ampspec_log.em'
weight_fn_prefix=<WEIGHT_FN_PREFIX>

# Relative path and name of the partial weight files
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
if [[ ! -d ${local_dir} ]]
then
    mkdir -p ${local_dir}
fi

if [[ ! -d $(dirname ${local_dir}/${ref_fn_prefix}) ]]
then
    mkdir -p $(dirname ${local_dir}/${ref_fn_prefix})
fi
################################################################################
#                                                                              #
#                        SUBTOMOGRAM AVERAGING WORKFLOW                        #
#                                                                              #
################################################################################
################################################################################
#                              PARALLEL AVERAGING                              #
################################################################################
# Generate and launch array files
# Calculate number of job scripts needed
num_avg_jobs=$(((num_avg_batch + array_max - 1) / array_max))
array_start=1

# Loop to generate parallel alignment scripts
for ((job_idx=1; job_idx <= num_avg_jobs; job_idx++))
do
    array_end=$((array_start + array_max - 1))
    if [[ ${array_end} -gt ${num_avg_batch} ]]
    then
        array_end=${num_avg_batch}
    fi

    cat > ${job_name}_paral_avg_subsets_array_${iteration}_${job_idx}<<-PAVGJOB
#!/bin/bash
#$ -N ${job_name}_paral_avg_subsets_array_${iteration}_${job_idx}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${mem_free_avg},h_vmem=${mem_max_avg}
#$ -o log_${job_name}_paral_avg_subsets_array_${iteration}_${job_idx}
#$ -e error_${job_name}_paral_avg_subsets_array_${iteration}_${job_idx}
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
process_idx=\${SGE_TASK_ID}
check="${all_motl_fn_prefix}_${iteration}_\${process_idx}.em"
if [[ -f "\${check}" ]]
then
    echo "\${check} already complete. SKIPPING"
    exit 0
fi
MCRDIR=${scratch_dir}/${mcr_cache_dir}
rm -rf \${MCRDIR}/${job_name}_paral_avg_subsets_\${process_idx}
mkdir \${MCRDIR}/${job_name}_paral_avg_subsets_\${process_idx}
export MCR_CACHE_ROOT=\${MCRDIR}/${job_name}_paral_avg_subsets_\${process_idx}
ptcl_start_idx=\$(((${avg_batch_size} * (process_idx - 1)) + 1))
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
\${process_idx}
rm -rf \${MCRDIR}/${job_name}_paral_avg_subsets_\${process_idx}
PAVGJOB

    qsub ${job_name}_paral_avg_subsets_array_${iteration}_${job_idx}
    array_start=$((array_start + array_max))
done

echo "STARTING Parallel Average in Iteration Number: ${iteration}"
################################################################################
#                         PARALLEL AVERAGING PROGRESS                          #
################################################################################
ref_dir=$(dirname ${scratch_dir}/${ref_fn_prefix})
ref_base=$(basename ${scratch_dir}/${ref_fn_prefix})_${iteration}
num_complete=$(find ${ref_dir} -name "${ref_base}_*_subset1.em" | wc -l)
num_complete_prev=0
unchanged_count=0
while [ ${num_complete} -lt ${num_avg_batch} ]
do
    num_complete=$(find ${ref_dir} -name "${ref_base}_*_subset1.em" | wc -l)
    echo "${num_complete} parallel average out of ${num_avg_batch}"
    if [[ ${num_complete} -eq ${num_complete_prev} ]]
    then
        unchanged_count=$((unchanged_count + 1))
    else
        unchanged_count=0
    fi
    num_complete_prev=${num_complete}
    
    if [[ ${unchanged_count} -gt 0 && ${unchanged_count} -gt 120 ]]
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
if [[ ! -d ${scratch_dir}/avg_subsets_${iteration} ]]
then
    mkdir ${scratch_dir}/avg_subsets_${iteration}
fi

if [[ -e "${job_name}_paral_avg_subsets_array_${iteration}_1" ]]
then
    mv -f ${job_name}_paral_avg_subsets_array_${iteration}_* \
        ${scratch_dir}/avg_subsets_${iteration}/.
fi

if [[ -e "log_${job_name}_paral_avg_subsets_array_${iteration}_1" ]]
then
    mv -f log_${job_name}_paral_avg_subsets_array_${iteration}_* \
        ${scratch_dir}/avg_subsets_${iteration}/.
fi

if [[ -e "error_${job_name}_paral_avg_subsets_array_${iteration}_1" ]]
then
    mv -f error_${job_name}_paral_avg_subsets_array_${iteration}_* \
        ${scratch_dir}/avg_subsets_${iteration}/.
fi

echo "FINISHED Parallel Average in Iteration Number: ${iteration}"
################################################################################
#                                FINAL AVERAGE                                 #
################################################################################
cat > ${job_name}_avg_subsets_${iteration} <<-AVGJOB
#!/bin/bash
#$ -N ${job_name}_avg_subsets_${iteration}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${mem_free_avg},h_vmem=${mem_max_avg}
#$ -o log_${job_name}_avg_subsets_${iteration}
#$ -e error_${job_name}_avg_subsets_${iteration}
set +o noclobber
set -e

echo \${HOSTNAME}
ldpath=XXXMCR_DIRXXX/runtime/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/bin/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64
ldpath=\${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=\${ldpath}
cd ${scratch_dir}
check="${ref_fn_prefix}_${iteration}.em"
if [[ -f "\${check}" ]]
then
    echo "\${check} already complete. SKIPPING"
    exit 0
fi
MCRDIR=${scratch_dir}/${mcr_cache_dir}/${job_name}_avg_subsets_iteration
rm -rf \${MCRDIR}
mkdir \${MCRDIR}
export MCR_CACHE_ROOT=\${MCRDIR}
time ${avg_exec} \\
${ref_fn_prefix} \\
${all_motl_fn_prefix} \\
${weight_sum_fn_prefix} \\
${iteration} \\
${iclass}
rm -rf \${MCRDIR}
AVGJOB

qsub ${job_name}_avg_subsets_${iteration}
echo "STARTING Final Average in Iteration Number: ${iteration}"
################################################################################
#                            FINAL AVERAGE PROGRESS                            #
################################################################################
echo "Waiting for the final average ..."
unchanged_count=0
while [[ ! -e "${scratch_dir}/${ref_fn_prefix}_${iteration}_subset1.em" ]]
do
    unchanged_count=$((unchanged_count + 1))
    if [[ ${unchanged_count} -gt 120 ]]
    then
        echo "Final averaging has seemed to stall"
        echo "Please check error logs and resubmit the job if neeeded."
        exit 1
    fi
    sleep 60s
done
echo "Found the first subset average ..."
echo "Waiting a few minutes for the others to finish as well ..."
sleep 300s
################################################################################
#                            FINAL AVERAGE CLEAN UP                            #
################################################################################
### Copy file to group share
cp ${scratch_dir}/${ref_fn_prefix}_${iteration}_subset*.em \
    ${local_dir}/.

if [[ -e "${job_name}_avg_subsets_${iteration}" ]]
then
    mv ${job_name}_avg_subsets_${iteration} \
        ${scratch_dir}/avg_subsets_${iteration}/.
fi

if [[ -e "log_${job_name}_avg_subsets_${iteration}" ]]
then
    mv log_${job_name}_avg_subsets_${iteration} \
        ${scratch_dir}/avg_subsets_${iteration}/.
fi

if [[ -e "error_${job_name}_avg_subsets_${iteration}" ]]
then
    mv error_${job_name}_avg_subsets_${iteration} \
        ${scratch_dir}/avg_subsets_${iteration}/.
fi

ref_dir=$(dirname ${scratch_dir}/${ref_fn_prefix})
ref_base=$(basename ${scratch_dir}/${ref_fn_prefix})_${iteration}
weight_sum_dir=$(dirname ${scratch_dir}/${weight_sum_fn_prefix})
weight_sum_base=$(basename ${scratch_dir}/${weight_sum_fn_prefix})_${iteration}
find ${ref_dir} -name "${ref_base}_[0-9]*.em" -delete
find ${weight_sum_dir} -name "${weight_sum_base}_[0-9]*.em" -delete

echo "FINISHED Final Average in Iteration Number: ${iteration}"
echo "AVERAGE DONE IN ITERATION NUMBER ${iteration}"
