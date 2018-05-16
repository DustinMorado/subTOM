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

# If you want to skip the cluster and run the job locally set this to 1.
run_local=0
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

# Relative path and filename prefix for output binary wedges
binary_fn_prefix="otherinputs/ampspec"

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

# If you already have noise MOTL lists calculated which may contain less than the
# total number of requested noise, but just want the code to do the extraction
# then you can set just_extract to 1. Otherwise set it to 0.
just_extract=0

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

# Set reextract to 1 if you want to force the program to re-extract amplitude
# spectra even if the amplitude spectrum file already exists. 
reextract=1

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

################################################################################
#                                                                              #
#                          TOMOGRAM NOISE EXTRACTION                           #
#                                                                              #
################################################################################
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
###for SGE_TASK_ID in {1..${num_tomos}}; do
rm -rf ${mcr_cache_dir}/${job_name}_\${SGE_TASK_ID}
mkdir ${mcr_cache_dir}/${job_name}_\${SGE_TASK_ID}
export MCR_CACHE_ROOT="${mcr_cache_dir}/${job_name}_\${SGE_TASK_ID}"
time ${noise_extract_exe} \\
    ${tomogram_dir} \\
    ${scratch_dir} \\
    ${tomo_row} \\
    ${ampspec_fn_prefix} \\
    ${binary_fn_prefix} \\
    ${all_motl_fn} \\
    ${noise_motl_fn_prefix} \\
    ${subtomogram_size} \\
    ${just_extract} \\
    ${ptcl_overlap_factor} \\
    ${noise_overlap_factor} \\
    ${num_noise} \\
    \${SGE_TASK_ID} \\
    ${reextract}
rm -rf ${mcr_cache_dir}/${job_name}_\${SGE_TASK_ID}
###done 2> error_${job_name}_array > log_${job_name}_array
JOBDATA

if [[ ${run_local} -eq 1 ]]
then
    mv ${job_name}_array temp_array
    sed 's/\#\#\#//' temp_array > ${job_name}_array
    rm temp_array
    chmod u+x ${job_name}_array
    ./${job_name}_array &
else
    qsub ./${job_name}_array
fi

echo "Parallel noise extraction submitted"
################################################################################
#                          NOISE EXTRACTION PROGRESS                           #
################################################################################
check_dir=$(dirname ${scratch_dir}/${ampspec_fn_prefix})
check_base=$(basename ${scratch_dir}/${ampspec_fn_prefix})
if [[ ${reextract} -eq 1 ]]
then
    touch ${check_dir}/empty_file
    check_count=$(find ${check_dir} -newer ${check_dir}/empty_file \
        -and -name "${check_base}_*.em" | wc -l)
else
    check_count=$(find ${check_dir} -name "${check_base}_*.em" | wc -l)
fi
# Wait for jobs to finish
while [ ${check_count} -lt ${num_tomos} ]; do
    if [[ ${reextract} -eq 1 ]]
    then
        check_count=$(find ${check_dir} -newer ${check_dir}/empty_file \
            -and -name "${check_base}_*.em" | wc -l)
    else
        check_count=$(find ${check_dir} -name "${check_base}_*.em" | wc -l)
    fi
    echo "Number of amplitude spectra complete ${check_count} / ${num_tomos}"
    sleep 60s
done
if [[ -f ${check_dir}/empty_file ]]
then
    rm ${check_dir}/empty_file
fi
################################################################################
#                          NOISE EXTRACTION CLEAN UP                           #
################################################################################
if [[ ! -d extract_noise ]]
then
    mkdir extract_noise
fi

if [[ -f ${job_name}_array ]]
then
    mv ${job_name}_array extract_noise/.
fi

if [[ -f log_${job_name}_array ]]
then
    mv log_${job_name}_array extract_noise/.
fi

if [[ -f error_${job_name}_array ]]
then
    mv error_${job_name}_array extract_noise/.
fi
