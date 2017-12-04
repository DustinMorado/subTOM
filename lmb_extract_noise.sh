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
# Absolute path to the folder where the tomograms are stored
tomogram_dir="${bstore1}/VMV013/20170528/data/tomos/bin8"

# Absolute path to the root folder for subtomogram extraction.
# Other paths are relative to this one.
scratch_dir="${nfs6}/VMV013/20170528/subtomo/bin8"

# Absolute path to the MCR directory for each job
mcr_cache_dir="${scratch_dir}/mcr"

# Absolute path to the directory for executables
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
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path to allmotl file from root folder.
all_motl_fn="combinedmotl/allmotl_1.em"

# Relative path to noisemotl filename. If the file doesn't exist a new one will
# be written with the determined noise positions. If a previously existing noise
# motl exists it will be used instead. If the number of noise particles
# requested has been increased new particles will be found and added and the
# file will be updated.
noise_motl_fn_prefix="combinedmotl/noisemotl"

# Relative path and filename prefix for output amplitude spectrums
ampspec_fn_prefix="otherinputs/ampspec"

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
subtomogram_size=36

# The amount of overlap to allow between noise particles and subtomograms
# Numbers greater than 1 will allow for larger than a box size spacing between
# noise and a particle. Numbers less than 1 will allow for some overlap between
# noise and a particle. For example 0.5 will allow 50% overlap between the noise
# and the particle, which can be useful when the boxsize is much larger than the
# particle.
ptcl_overlap_factor=1;

# The amount of overlap to allow between noise particles
# Numbers greater than 1 will allow for larger than a box size spacing between
# noise. Numbers less than 1 will allow for some overlap between noise. For
# example 0.25 will allow 75% overlap between the noise, which can be useful when
# there is not much space for enough noise.
noise_overlap_factor=1;

# Number of noise particles to extract
num_noise=100
################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
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
time ${noise_extract_exe} \\
    ${tomogram_dir} \\
    ${scratch_dir} \\
    ${tomo_row} \\
    ${ampspec_fn_prefix} \\
    ${all_motl_fn} \\
    ${noise_motl_fn_prefix} \\
    ${subtomogram_size} \\
    ${ptcl_overlap_factor} \\
    ${noise_overlap_factor} \\
    ${num_noise} \\
    \${SGE_TASK_ID}
rm -rf ${mcr_cache_dir}/${job_name}_\${SGE_TASK_ID}
JOBDATA

##### SEND OUT JOB ##########################
qsub ./${job_name}_array

echo "Parallel noise extraction submitted"

# Reset counter
check_dir=$(dirname ${scratch_dir}/${ampspec_fn_prefix})
check_base=$(basename ${scratch_dir}/${ampspec_fn_prefix})
check_count=$(find ${check_dir} -name "${check_base}_*.em" | wc -l)
# Wait for jobs to finish
while [ ${check_count} -lt ${num_tomos} ]; do
    check_count=$(find ${check_dir} -name "${check_base}_*.em" | wc -l)
    echo "Number of amplitude spectra complete ${check_count} / ${num_tomos}"
    sleep 60s
done

for pos_idx in "${scratch_dir}/${noise_motl_fn_prefix}"_*.pos
do
    point2model -ScatteredPoints -CircleSize 5 -LineWidthIn2D 2 \
        "${pos_idx}" "${pos_idx/%pos/mod}"
done
