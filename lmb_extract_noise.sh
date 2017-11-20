#!/bin/bash
################################################################################
# This script finds and extracts noise particles from tomograms and generates
# amplitude spectrum volumes for used in Fourier reweighting of particles in the
# subtomogram alignment and averaging routines.
#
# It also generates a noise motl file so that the noise positions found in
# binned tomograms can then be used later on in less or unbinned tomograms and
# after some positions have been cleaned, which could make it more difficult to
# pick non-structural noise in the tomogram.
#
# This script uses one MATLAB compiled script below:
# - lmb_extract_noise
# DRM 11-2017
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Folder where the tomograms are stored
tomogram_dir="${bstore1}/VMV013/20170528/data/tomos/bin8"

# Root folder for subtomogram extraction. Other paths are relative to this one.
scratch_dir="${nfs6}/VMV013/20170528/subtomo/bin8"

# MCR directory for each job
mcr_cache_dir="${scratch_dir}/mcr"

# Directory for executables
exec_dir=${bstore1}/software/lmbtomopipeline/compiled

################################################################################
#                                  VARIABLES                                   #
################################################################################
# Noise extraction executable
noise_extract_exe=${exec_dir}/lmb_extract_noise

################################################################################
#                                MEMORY OPTIONS                                #
################################################################################
# The amount of memory your job requires
mem_free='10G'

# The upper bound on the amount of memory your job is allowed to use
mem_max='15G'

################################################################################
#                              OTHER LSF OPTIONS                               #
################################################################################
# BE CAREFUL THAT THE NAME DOESN'T CORRESPOND TO THE BEGINNING OF ANY OTHER FILE
job_name='VMV013_noise_extract'

################################################################################
#                                                                              #
#                      NOISE EXTRACTION WORKFLOW OPTIONS                       #
#                                                                              #
################################################################################
#                           PARALLELIZATION OPTIONS                            #
################################################################################
# Number of cores to process on
num_cores=16

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path to allmotl file from root folder.
all_motl_fn="${scratch_dir}/combinedmotl/allmotl_1.em"

# Relative path to noisemotl filename. If the file doesn't exist a new one will
# be written with the determined noise positions. If a previously existing noise
# motl exists it will be used instead. If the number of noise particles
# requested has been increased new particles will be found and added and the
# file will be updated.
noise_motl_fn="${scratch_dir}/combinedmotl/noisemotl.em"

# Relative path and filename prefix for output amplitude spectrums
ampspec_fn_prefix="${scratch_dir}/otherinputs/ampspec"

# Path and root of starting check file name
check_start_fn_prefix="${scratch_dir}/complete/noise_checkstart"

# Path and root of completion check file name
check_done_fn_prefix="${scratch_dir}/complete/noise_checkdone"

################################################################################
#                              TOMOGRAM OPTIONS                                #
################################################################################
# Number of digits in the tomogram numbers
# (tomograms should be named tomonumber.rec)
tomo_digits=2

# Row number of allmotl for tomogram numbers.
tomo_row=7

# Total number of tomograms in allmotl file
n_tomos=16

################################################################################
#                             EXTRACTION OPTIONS                               #
################################################################################
# Size of subtomogram in pixels
subtomogram_size=36

# Number of noise particles to extract
num_noise=100
################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ ! -d "$(dirname ${check_start_fn_prefix})" ]]
then
    mkdir "$(dirname ${check_start_fn_prefix})"
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

if [[ ${mem_free%G} -ge 24 ]]; then
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
#$ -l mem_free=${mem_free},h_vmem=${mem_max}${dedmem}
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
rm -rf ${mcr_cache_dir}/${job_name}_\${SGE_TASK_ID}
mkdir ${mcr_cache_dir}/${job_name}_\${SGE_TASK_ID}
export MCR_CACHE_ROOT="${mcr_cache_dir}/${job_name}_\${SGE_TASK_ID}"
time ${noise_extract_exe} \\
    ${tomogram_dir} \\
    ${tomo_digits} \\
    ${scratch_dir} \\
    ${tomo_row} \\
    ${ampspec_fn_prefix} \\
    ${all_motl_fn} \\
    ${noise_motl_fn} \\
    ${subtomogram_size} \\
    ${num_noise} \\
    ${check_start_fn_prefix} \\
    ${check_done_fn_prefix}
rm -rf ${mcr_cache_dir}/${job_name}_\${SGE_TASK_ID}
JOBDATA

##### SEND OUT JOB ##########################
qsub ./${job_name}_array

echo "Parallel noise extraction submitted"

# Reset counter
check_start=0
check_done=0
# Wait for jobs to finish
while [ ${check_done} -lt ${num_cores} ]; do
    sleep 60s
    check_start=$(ls ${check_start_fn_prefix}_* 2>&1 |\
                  grep -v '^ls:' | wc -w)
    echo "Number of tomograms started ${check_start} out of ${n_tomos}"
    check_done=$(ls ${check_done_fn_prefix}_* 2>&1 |\
                 grep -v '^ls:' | wc -w)
    echo "Number of tomograms extracted ${check_done} out of ${n_tomos}"
done
