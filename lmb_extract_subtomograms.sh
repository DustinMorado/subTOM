#!/bin/bash
################################################################################
# This script takes an input number of cores, and each core extract one tomogram
# at a time as written in a specified row of the allmotl. Parallelization works
# by writing a start file upon openinig of a tomo, and a completion file. After
# tomogram extraction, it moves on to the next tomogram that hasn't been
# started.
#
# This script uses  MATLAB compiled script below:
# - 
# DRM 11-2017
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Folders where the tomograms are stored
tomogram_dir="${bstore1}/VMV013/20170404/data/tomos/bin2"

# Root folder for subtomogram extraction. Other paths are relative to this one.
scratch_dir="${nfs6}/VMV013/20170404/subtomo/bin2/even"

# MCR directory for each job
mcr_cache_dir="${scratch_dir}/mcr"

# Directory for executables
exec_dir=${bstore1}/software/lmbtomopipeline/compiled

################################################################################
#                                  VARIABLES                                   #
################################################################################
# subtomogram extraction executable
extract_exe=${exec_dir}/lmb_extract_subtomograms

################################################################################
#                                MEMORY OPTIONS                                #
################################################################################
# The amount of memory your job requires
memfree='10G'

# The upper bound on the amount of memory your job is allowed to use
memmax='15G'

################################################################################
#                              OTHER LSF OPTIONS                               #
################################################################################
# BE CAREFUL THAT THE NAME DOESN'T CORRESPOND TO THE BEGINNING OF ANY OTHER FILE
job_name='VMV013_tomo_extract'

################################################################################
#                                                                              #
#                    SUBTOMOGRAM EXTRACTION WORKFLOW OPTIONS                   #
#                                                                              #
################################################################################
#                           PARALLELIZATION OPTIONS                            #
################################################################################
## Number of cores to process on
num_cores=16

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path to allmotl file from root folder.
all_motl_fn='combinedmotl/allmotl_1.em'

# Relative path and filename for output subtomograms
subtomo_fn_prefix='subtomograms/subtomo'

# Relative path and filename for stats .csv files.
stats_fn_prefix='subtomo_stats'

# Path and root of starting check file name
check_start_fn_prefix='complete/checkstart'

# Path and root of completion check file name
check_done_fn_prefix='complete/checkdone'

################################################################################
#                              TOMOGRAM OPTIONS                                #
################################################################################
# Number of digits in the tomogram numbers
# (tomograms should be named tomonumber.rec)
tomo_digits=2

# Row number of allmotl for tomogram numbers.
tomo_row=7

# Total number of tomograms in allmotl file
num_tomos=16

################################################################################
#                             EXTRACTION OPTIONS                               #
################################################################################
# Size of subtomogram in pixels
subtomogram_size=36

# Leading zeros for subtomograms, for AV3, use 1. Other numbers are useful for
# DYNAMO.
subtomo_digits=1
################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ ! -d "$(dirname ${scratch_dir}/${check_start_fn_prefix})" ]]
then
    mkdir "$(dirname ${scratch_dir}/${check_start_fn_prefix})"
fi

if [[ ! -d "${mcr_cache_dir}" ]]
then
    mkdir "${mcr_cache_dir}"
fi

if [[ -f ${job_name}_array ]]
then
    rm -f ${job_name}_array
fi

if [[ -f error_${job_name}_array ]]
then
    rm -f error_${job_name}_array
fi

if [[ -f log_${job_name}_array ]]
then
    rm -f log_${job_name}_array
fi

if [[ ${memfree%G} -ge 24 ]]; then
    dedmem=',dedicated=12'
else
    dedmem=''
fi

### Initialize parallel job array
cat > ${job_name}_array <<-JOBDATA
#!/bin/bash
#$ -N ${job_name}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${memfree},h_vmem=${memmax}${dedmem}
#$ -e error_${job_name}_array
#$ -o log_${job_name}_array
#$ -t 1-${num_cores}
set +C # Turn off prevention of redirection file overwriting
set -e # Turn on exit on error
set -f # Turn off filename expansion (globbing)
echo \${HOSTNAME}
ldpath="/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"
ldpath="/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:\${ldpath}"
ldpath="/lmb/home/public/matlab/jbriggs/bin/glnxa64:\${ldpath}"
ldpath="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:\${ldpath}"
export LD_LIBRARY_PATH=\${ldpath}
cd ${scratch_dir}
rm -rf ${scratch_dir}/${mcrcachedir}/${job_name}_\${SGE_TASK_ID}
mkdir ${scratch_dir}/${mcrcachedir}/${job_name}_\${SGE_TASK_ID}
export MCR_CACHE_ROOT="${scratch_dir}/${mcrcachedir}/${job_name}_\${SGE_TASK_ID}"
time ${extract_exe} \\
    ${tomogram_dir} \\
    ${tomo_digits} \\
    ${scratch_dir} \\
    ${tomo_row} \\
    ${subtomo_fn_prefix} \\
    ${subtomo_digits} \\
    ${all_motl_fn} \\
    ${subtomosize} \\
    ${stats_fn_prefix} \\
    ${check_start_fn_prefix} \\
    ${check_done_fn_prefix}
rm -rf ${scratch_dir}/${mcrcachedir}/${job_name}_\${SGE_TASK_ID}
JOBDATA

##### SEND OUT JOB ##########################
qsub ./${job_name}_array

echo "Parallel tomogram extraction submitted"

# Reset counter
check_start=0
check_done=0
check_start_dir=$(dirname ${scratch_dir}/${check_start_fn_prefix})
check_start_base=$(basename ${scratch_dir}/${check_start_fn_prefix})
check_done_dir=$(dirname ${scratch_dir}/${check_done_fn_prefix})
check_done_base=$(basename ${scratch_dir}/${check_done_fn_prefix})
# Wait for jobs to finish
while [ ${check_done} -lt ${num_cores} ]; do
    sleep 60s
    check_start=$(find ${check_start_dir} -name "${check_start_base}_*" | wc -l)
    echo "Number of tomograms started ${check_start} out of ${num_tomos}"
    check_done=$(find ${check_done_dir} -name "${check_done_base}_*" | wc -l)
    echo "Number of tomograms extracted ${check_done} out of ${num_tomos}"
done
