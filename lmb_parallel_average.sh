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
# - lmb_parallel_sums
# - lmb_weighted_average
# DRM 09-2017
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Root folder on the scratch
scratch_dir="SCRATCH_DIR"

# Folder on group shares
local_dir="LOCAL_DIR"

# MCR directory for each job
mcr_cache_dir='mcr'

# Directory for executables
exec_dir=${bstore1}/software/lmbtomopipeline/compiled

################################################################################
#                                  VARIABLES                                   #
################################################################################
# Parallel Averaging executable
paral_avg_exec=${exec_dir}/lmb_parallel_sums

# Final Averaging executable
avg_exec=${exec_dir}/lmb_weighted_average

################################################################################
#                                MEMORY OPTIONS                                #
################################################################################
# The amount of memory your job requires
mem_free_avg='12G'

# The upper bound on the amount of memory your job is allowed to use
mem_max_avg='16G'

################################################################################
#                              OTHER LSF OPTIONS                               #
################################################################################
# BE CAREFUL THAT THE NAME DOESN'T CORRESPOND TO THE BEGINNING OF ANY OTHER FILE
job_name='JOB_NAME'

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
iteration=1

# Total number of particles
num_ptcls=1000000

# Number of particles in each parallel subtomogram averaging job
avg_batch_size=100

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
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

# Relative path and name of the weight file
weight_fn_prefix='otherinputs/ampspec'

# Relative path and name of the partial weight files
weight_sum_fn_prefix='otherinputs/wei'

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

if [[ ! -d ${mcr_cache_dir} ]]
then
    mkdir -p ${mcr_cache_dir}
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
ref_fn="${scratch_dir}/${ref_fn_prefix}_${iteration}.em"

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

    cat > ${job_name}_paral_avg_array_${iteration}_${job_idx}<<-PAVGJOB
#!/bin/bash
#$ -N ${job_name}_paral_avg_array_${iteration}_${job_idx}
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
###for SGE_TASK_ID in {${array_start}..${array_end}}; do
process_idx=\${SGE_TASK_ID}
check="${ref_fn_prefix}_${iteration}_\${process_idx}.em"
if [[ -f "\${check}" ]]
then
    echo "\${check} already complete. SKIPPING"
    exit 0
fi
MCRDIR=${scratch_dir}/${mcr_cache_dir}
rm -rf \${MCRDIR}/${job_name}_paral_avg_\${process_idx}
mkdir \${MCRDIR}/${job_name}_paral_avg_\${process_idx}
export MCR_CACHE_ROOT=\${MCRDIR}/${job_name}_paral_avg_\${process_idx}
ptcl_start_idx=\$(((${avg_batch_size} * (process_idx - 1)) + 1))
time ${paral_avg_exec} \\
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
rm -rf \${MCRDIR}/${job_name}_paral_avg_\${process_idx}
###done 2> error_${job_name}_paral_avg_array_${iteration}_${job_idx} >\\
###log_${job_name}_paral_avg_array_${iteration}_${job_idx}
PAVGJOB
    if [[ ! -e "${ref_fn}" ]]
    then
        if [[ ${run_local} -eq 1 ]]
        then
            mv ${job_name}_paral_avg_array_${iteration}_${job_idx} temp_array
            sed 's/\#\#\#//' temp_array > \
                ${job_name}_paral_avg_array_${iteration}_${job_idx}
            rm temp_array
            chmod u+x ${job_name}_paral_avg_array_${iteration}_${job_idx}
            ./${job_name}_paral_avg_array_${iteration}_${job_idx} &
        else
            qsub ${job_name}_paral_avg_array_${iteration}_${job_idx}
        fi
    fi
done

echo "STARTING Parallel Average in Iteration Number: ${iteration}"
################################################################################
#                         PARALLEL AVERAGING PROGRESS                          #
################################################################################
ref_dir=$(dirname ${scratch_dir}/${ref_fn_prefix})
ref_base=$(basename ${scratch_dir}/${ref_fn_prefix})_${iteration}
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
if [[ -f "${ref_fn}" ]]
then
    echo "${ref_fn} already complete. SKIPPING"
    exit 0
fi
MCRDIR=${scratch_dir}/${mcr_cache_dir}/${job_name}_avg_${iteration}
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
if [[ ! -e "${ref_fn}" ]]
then
    if [[ ${run_local} -eq 1 ]]
    then
        chmod u+x ${job_name}_avg_${iteration}
        ./${job_name}_avg_${iteration} &
    else
        qsub ${job_name}_avg_${iteration}
    fi
fi
echo "STARTING Final Average in Iteration Number: ${iteration}"
################################################################################
#                            FINAL AVERAGE PROGRESS                            #
################################################################################
echo "Waiting for the final average ..."
unchanged_count=0
while [[ ! -e "${ref_fn}" ]]
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
################################################################################
#                            FINAL AVERAGE CLEAN UP                            #
################################################################################
### Copy file to group share
if [[ ${skip_local_copy} -ne 1 ]]
then
    cp ${scratch_dir}/${ref_fn_prefix}_${iteration}.em \
        ${local_dir}/${ref_fn_prefix}_${iteration}.em
    cp ${scratch_dir}/${weight_sum_fn_prefix}_debug_${iteration}.em \
        ${local_dir}/${weight_sum_fn_prefix}_debug_${iteration}.em 
    cp ${scratch_dir}/${weight_sum_fn_prefix}_debug_inv_${iteration}.em \
        ${local_dir}/${weight_sum_fn_prefix}_debug_inv_${iteration}.em 
fi

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
ref_base=$(basename ${scratch_dir}/${ref_fn_prefix})_${iteration}
weight_sum_dir=$(dirname ${scratch_dir}/${weight_sum_fn_prefix})
weight_sum_base=$(basename ${scratch_dir}/${weight_sum_fn_prefix})_${iteration}
find ${ref_dir} -name "${ref_base}_[0-9]*.em" -delete
find ${weight_sum_dir} -name "${weight_sum_base}_[0-9]*.em" -delete

echo "FINISHED Final Average in Iteration Number: ${iteration}"
echo "AVERAGE DONE IN ITERATION NUMBER ${iteration}"
