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
tomogram_dir="${bstore1}/VMV013/20170528/data/tomos/bin4"

# Root folder for subtomogram extraction. Other paths are relative to this one.
scratch_dir="${nfs6}/VMV013/20170528/subtomo/bin4"

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
################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path to allmotl file from root folder.
all_motl_fn='combinedmotl/allmotl_2_1.em'

# Relative path and filename for output subtomograms
subtomo_fn_prefix='subtomograms/subtomo'

# Relative path and filename for stats .csv files.
stats_fn_prefix='subtomograms/stats/subtomo_stats'

################################################################################
#                              TOMOGRAM OPTIONS                                #
################################################################################
# Row number of allmotl for tomogram numbers.
tomo_row=7

# Total number of tomograms in allmotl file
num_tomos=16

################################################################################
#                             EXTRACTION OPTIONS                               #
################################################################################
# Size of subtomogram in pixels
subtomogram_size=72

# Leading zeros for subtomograms, for AV3, use 1. Other numbers are useful for
# DYNAMO.
subtomo_digits=1
################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ ! -d "${mcr_cache_dir}" ]]
then
    mkdir "${mcr_cache_dir}"
fi

if [[ ! -d $(dirname ${scratch_dir}/${stats_fn_prefix}) ]]
then
    mkdir -p $(dirname ${scratch_dir}/${stats_fn_prefix})
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
#$ -t 1-${num_tomos}
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
rm -rf ${mcr_cache_dir}/${job_name}_\${SGE_TASK_ID}
mkdir ${mcr_cache_dir}/${job_name}_\${SGE_TASK_ID}
export MCR_CACHE_ROOT="${mcr_cache_dir}/${job_name}_\${SGE_TASK_ID}"
time ${extract_exe} \\
    ${tomogram_dir} \\
    ${scratch_dir} \\
    ${tomo_row} \\
    ${subtomo_fn_prefix} \\
    ${subtomo_digits} \\
    ${all_motl_fn} \\
    ${subtomogram_size} \\
    ${stats_fn_prefix} \\
    \${SGE_TASK_ID}
rm -rf ${mcr_cache_dir}/${job_name}_\${SGE_TASK_ID}
JOBDATA

##### SEND OUT JOB ##########################
qsub ./${job_name}_array

echo "Parallel tomogram extraction submitted"

# Reset counter
check_dir=$(dirname "${scratch_dir}/${stats_fn_prefix}")
check_base=$(basename "${scratch_dir}/${stats_fn_prefix}")
check_count=$(find "${check_dir}" -name "${check_base}_*.csv" | wc -l)
# Wait for jobs to finish
while [ ${check_count} -lt ${num_tomos} ]; do
    sleep 60s
    check_count=$(find "${check_dir}" -name "${check_base}_*.csv" | wc -l)
    echo "Number of tomograms extracted ${check_count} out of ${num_tomos}"
done
