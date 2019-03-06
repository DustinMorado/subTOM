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
# - extract_noise
# DRM 11-2017
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
unset ml
unset module
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the folder where the tomograms are stored
tomogram_dir=<TOMOGRAM_DIR>

# Absolute path to the root folder for subtomogram extraction.
# Other paths are relative to this one.
scratch_dir=<SCRATCH_DIR>

# Absolute path to the MCR directory for each job
mcr_cache_dir=${scratch_dir}/mcr

# Absolute path to the directory for executables
exec_dir=XXXINSTALLATION_DIRXXX/bin

################################################################################
#                                  VARIABLES                                   #
################################################################################
# Noise extraction executable
noise_extract_exe=${exec_dir}/extract_noise

# MOTL dump executable
motl_dump_exe=${exec_dir}/motl_dump

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

# If you want to skip the cluster and run the job locally set this to 1.
run_local=0

################################################################################
#                                                                              #
#                      NOISE EXTRACTION WORKFLOW OPTIONS                       #
#                                                                              #
################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative or absolute path to allmotl file from root folder.
all_motl_fn=<ALL_MOTL_FN>

# Relative or absolute path to noisemotl filename. If the file doesn't exist a
# new one will be written with the determined noise positions. If a previously
# existing noise motl exists it will be used instead. If the number of noise
# particles requested has been increased new particles will be found and added
# and the file will be updated.
noise_motl_fn_prefix=<NOISE_MOTL_FN_PREFIX>

# Relative or absolute path and filename prefix for output amplitude spectrums
ampspec_fn_prefix=<AMPSPEC_FN_PREFIX>

# Relative or absolute path and filename prefix for output binary wedges
binary_fn_prefix=<BINARY_FN_PREFIX>

################################################################################
#                              TOMOGRAM OPTIONS                                #
################################################################################
# Row number of allmotl for tomogram numbers.
tomo_row=7

################################################################################
#                             EXTRACTION OPTIONS                               #
################################################################################
# Size of subtomogram in pixels
subtomogram_size=<SUBTOMOGRAM_SIZE>

# If you already have noise MOTL lists calculated which may contain less than the
# total number of requested noise, but just want the code to do the extraction
# then you can set just_extract to 1. Otherwise set it to 0.
just_extract=0

# The amount of overlap to allow between noise particles and subtomograms
# Numbers less than 0 will allow for larger than a box size spacing between
# noise and a particle. Numbers greater than 0 will allow for some overlap
# between noise and a particle. For example 0.5 will allow 50% overlap between
# the noise and the particle, which can be useful when the boxsize is much
# larger than the particle.
ptcl_overlap_factor=0;

# The amount of overlap to allow between noise particles Numbers less than 0
# will allow for larger than a box size spacing between noise. Numbers greater
# than 0 will allow for some overlap between noise. For example 0.75 will allow
# 75% overlap between the noise, which can be useful when there is not much
# space for enough noise.
noise_overlap_factor=0;

# Number of noise particles to extract
num_noise=<NUM_NOISE>

# Set reextract to 1 if you want to force the program to re-extract amplitude
# spectra even if the amplitude spectrum file already exists. 
reextract=0

# Set preload_tomogram to 1 if you want to read the whole tomogram into memory
# before extraction. This is the fastest way to extract particles however the
# system needs to be able to have the memory to fit the whole tomogram into
# memory or otherwise it will crash. If it is set to 0, then either the
# subtomograms can be extracted using a memory-map to the data, or read directly
# from the file.
preload_tomogram=1

# Set use_tom_red to 1 if you want to use the AV3/TOM function tom_red to
# extract particles. This requires that preload_tomogram above is set to 1. This
# is the original way to extract particles, but it seemed to sometimes produce
# subtomograms that were incorrectly sized. If it is set to 0 then an inlined
# window function is used instead.
use_tom_red=1

# Set use_memmap to 1 to memory-map the tomogram and read subtomograms from this
# map. This appears to be a little slower than having the tomogram fully in
# memory without the massive memory footprint. However, it also appears to be
# slightly unstable and may crash unexpectedly. If it is set to 0 and
# preload_tomogram is also 0, then subtomograms will be read directly from the
# tomogram on disk. This also requires much less memory, however it appears to
# be extremely slow, so this only makes sense for a large number of tomograms
# being extracted on the cluster.
use_memmap=0

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

if [[ ! -d $(dirname ${noise_motl_fn_prefix}) ]]
then
    mkdir -p $(dirname ${noise_motl_fn_prefix})
fi

if [[ ! -d $(dirname ${ampspec_fn_prefix}) ]]
then
    mkdir -p $(dirname ${ampspec_fn_prefix})
fi

if [[ ! -d $(dirname ${binary_fn_prefix}) ]]
then
    mkdir -p $(dirname ${binary_fn_prefix})
fi

num_tomos=$(${motl_dump_exe} --row ${tomo_row} ${all_motl_fn} | \
    sort -n | uniq | wc -l)

cd ${oldpwd}
job_name=${job_name}_extract_noise_array
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

if [[ ${mem_free%G} -ge 24 ]]
then
    dedmem=',dedicated=12'
else
    dedmem=''
fi

################################################################################
#                                                                              #
#                          TOMOGRAM NOISE EXTRACTION                           #
#                                                                              #
################################################################################
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
ldpath=XXXMCR_DIRXXX/sys/opengl/lib/glnxa64
ldpath=XXXMCR_DIRXXX/sys/os/glnxa64:\${ldpath}
ldpath=XXXMCR_DIRXXX/bin/glnxa64:\${ldpath}
ldpath=XXXMCR_DIRXXX/runtime/glnxa64:\${ldpath}
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
        ${reextract} \\
        ${preload_tomogram} \\
        ${use_tom_red} \\
        ${use_memmap}
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

echo "Parallel noise extraction submitted"
################################################################################
#                          NOISE EXTRACTION PROGRESS                           #
################################################################################
cd ${scratch_dir}
check_dir=$(dirname ${ampspec_fn_prefix})
check_base=$(basename ${ampspec_fn_prefix})
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

cd ${oldpwd}
################################################################################
#                          NOISE EXTRACTION CLEAN UP                           #
################################################################################
if [[ ! -d extract_noise ]]
then
    mkdir extract_noise
fi

if [[ -f ${job_name} ]]
then
    mv ${job_name} extract_noise/.
fi

if [[ -f log_${job_name} ]]
then
    mv log_${job_name} extract_noise/.
fi

if [[ -f error_${job_name} ]]
then
    mv error_${job_name} extract_noise/.
fi
