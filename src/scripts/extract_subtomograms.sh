#!/bin/bash
################################################################################
# This script takes an input number of cores, and each core extract one tomogram
# at a time as written in a specified row of the allmotl. Parallelization works
# by writing a start file upon openinig of a tomo, and a completion file. After
# tomogram extraction, it moves on to the next tomogram that hasn't been
# started.
#
# This script uses  MATLAB compiled script below:
# - extract_subtomograms
# DRM 11-2017
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the folder where the tomograms are stored
tomogram_dir=<TOMOGRAM_DIR>

# Absolute path to the root folder for subtomogram extraction.
# Other paths are relative to this one.
scratch_dir=<SCRATCH_DIR>

# MCR directory for each job
mcr_cache_dir=${scratch_dir}/mcr

# Directory for executables
exec_dir=XXXINSTALLATION_DIRXXX/bin

################################################################################
#                                  VARIABLES                                   #
################################################################################
# subtomogram extraction executable
extract_exe=${exec_dir}/extract_subtomograms

################################################################################
#                                MEMORY OPTIONS                                #
################################################################################
# The amount of memory your job requires
# e.g. mem_free='10G'
mem_free=<MEM_FREE>

# The upper bound on the amount of memory your job is allowed to use
# e.g. mem_max='15G'
mem_max=<MEM_MAX>

################################################################################
#                              OTHER LSF OPTIONS                               #
################################################################################
# BE CAREFUL THAT THE NAME DOESN'T CORRESPOND TO THE BEGINNING OF ANY OTHER FILE
job_name=<JOB_NAME>

# If you want to skip the cluster and run the job locally set this to 1.
run_local=0

################################################################################
#                                                                              #
#                    SUBTOMOGRAM EXTRACTION WORKFLOW OPTIONS                   #
#                                                                              #
################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative or absolute path to allmotl file from root folder.
all_motl_fn=<ALL_MOTL_FN>

# Relative or absolute path and filename for output subtomograms
subtomo_fn_prefix=<SUBTOMO_FN_PREFIX>

# Relative or absoluted path and filename for stats .csv files.
stats_fn_prefix=<STATS_FN_PREFIX>

################################################################################
#                              TOMOGRAM OPTIONS                                #
################################################################################
# Row number of allmotl for tomogram numbers.
tomo_row=7

# Total number of tomograms in allmotl file
num_tomos=<NUM_TOMOS>

################################################################################
#                             EXTRACTION OPTIONS                               #
################################################################################
# Size of subtomogram in pixels
subtomogram_size=<SUBTOMOGRAM_SIZE>

# Leading zeros for subtomograms, for AV3, use 1. Other numbers are useful for
# DYNAMO.
subtomo_digits=1

# Set reextract to 1 if you want to force the program to re-extract subtomograms
# even if the stats file and the subtomograms already exist. If the stats file
# for the tomogram exists and is the correct size the whole tomogram will be
# skipped. If the subtomogram exists it will also be skipped, unless this option
# is true.
reextract=0

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
oldpwd=$(pwd)
cd ${scratch_dir}
if [[ ! -d ${mcr_cache_dir} ]]
then
    mkdir -p ${mcr_cache_dir}
fi

if [[ ! -d $(dirname ${subtomo_fn_prefix}) ]]
then
    mkdir -p $(dirname ${subtomo_fn_prefix})
fi

if [[ ! -d $(dirname ${stats_fn_prefix}) ]]
then
    mkdir -p $(dirname ${stats_fn_prefix})
fi

cd ${oldpwd}
job_name=${job_name}_extract_tomo_array
if [[ -f ${job_name} ]]
then
    rm -f ${job_name}
fi

if [[ -f error_${job_name} ]]
then
    rm -f error_${job_name}
fi

if [[ -f log_${job_name} ]]
then
    rm -f log_${job_name}
fi

if [[ ${mem_free%G} -ge 24 ]]; then
    dedmem=',dedicated=12'
else
    dedmem=''
fi

################################################################################
#                                                                              #
#                            SUBTOMOGRAM EXTRACTION                            #
#                                                                              #
################################################################################
### Initialize parallel job array
cat > ${job_name} <<-JOBDATA
#!/bin/bash
#$ -N ${job_name}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${mem_free},h_vmem=${mem_max}${dedmem}
#$ -e error_${job_name}
#$ -o log_${job_name}
#$ -t 1-${num_tomos}
set +C # Turn off prevention of redirection file overwriting
set -e # Turn on exit on error
set -f # Turn off filename expansion (globbing)
echo \${HOSTNAME}
ldpath="XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
ldpath="XXXMCR_DIRXXX/sys/os/glnxa64:\${ldpath}"
ldpath="XXXMCR_DIRXXX/bin/glnxa64:\${ldpath}"
ldpath="XXXMCR_DIRXXX/runtime/glnxa64:\${ldpath}"
export LD_LIBRARY_PATH=\${ldpath}
cd ${scratch_dir}
###for SGE_TASK_ID in {1..${num_tomos}}; do
    mcr_cache_dir=${mcr_cache_dir}/${job_name}_\${SGE_TASK_ID}
    if [[ ! -d \${mcr_cache_dir} ]]
    then
        mkdir -p \${mcr_cache_dir}
    else
        rm -rf \${mcr_cache_dir}
        mkdir -p \${mcr_cache_dir}
    fi

    export MCR_CACHE_ROOT=\${mcr_cache_dir}
    time ${extract_exe} \\
        ${tomogram_dir} \\
        ${scratch_dir} \\
        ${tomo_row} \\
        ${subtomo_fn_prefix} \\
        ${subtomo_digits} \\
        ${all_motl_fn} \\
        ${subtomogram_size} \\
        ${stats_fn_prefix} \\
        \${SGE_TASK_ID} \\
        ${reextract}
    rm -rf \${mcr_cache_dir}
###done 2> error_${job_name} > log_${job_name}
JOBDATA

if [[ ${run_local} -eq 1 ]]
then
    mv ${job_name} temp_array
    sed 's/\#\#\#//' temp_array > ${job_name}
    rm temp_array
    chmod u+x ${job_name}
    ./${job_name} &
else
    qsub ./${job_name}
fi

echo "Parallel tomogram extraction submitted"
################################################################################
#                       SUBTOMOGRAM EXTRACTION PROGRESS                        #
################################################################################
cd ${scratch_dir}
check_dir=$(dirname ${stats_fn_prefix})
check_base=$(basename ${stats_fn_prefix})
if [[ ${reextract} -eq 1 ]]
then
    touch ${check_dir}/empty_file
    check_count=$(find ${check_dir} -newer ${check_dir}/empty_file \
        -and -name "${check_base}_*.csv" | wc -l)
else
    check_count=$(find ${check_dir} -name "${check_base}_*.csv" | wc -l)
fi

# Wait for jobs to finish
while [ ${check_count} -lt ${num_tomos} ]; do
    if [[ ${reextract} -eq 1 ]]
    then
        check_count=$(find ${check_dir} -newer ${check_dir}/empty_file \
            -and -name "${check_base}_*.csv" | wc -l)
    else
        check_count=$(find ${check_dir} -name "${check_base}_*.csv" | wc -l)
    fi

    echo "Number of tomograms extracted ${check_count} out of ${num_tomos}"
    sleep 60s
done

if [[ -f ${check_dir}/empty_file ]]
then
    rm ${check_dir}/empty_file
fi

cd ${oldpwd}
################################################################################
#                       SUBTOMOGRAM EXTRACTION CLEAN UP                        #
################################################################################
if [[ ! -d extract_tomo ]]
then
    mkdir extract_tomo
fi

if [[ -f ${job_name} ]]
then
    mv ${job_name} extract_tomo/.
fi

if [[ -f log_${job_name} ]]
then
    mv log_${job_name} extract_tomo/.
fi

if [[ -f error_${job_name} ]]
then
    mv error_${job_name} extract_tomo/.
fi
