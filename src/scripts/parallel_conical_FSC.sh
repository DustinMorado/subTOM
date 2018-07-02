#!/bin/bash
################################################################################
# This is a run script for calculating the mask-corrected FSC curves and joined
# maps outside of the Matlab environment.
#
# This script is meant to run on a local workstation with access to an X server
# in the case when the user wants to display figures. I am unsure if both
# plotting options are disabled if the graphics display is still required, but
# if not it could be run remotely on the cluster, but it shouldn't be necessary.
#
# This script uses just one MATLAB compiled scripts below:
# - parallel_conical_FSC
#
# DRM 12-2017
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Root folder on the scratch
scratch_dir=<SCRATCH_DIR>

# MCR directory for the processing
mcr_cache_dir="mcr"

# Directory for executables
exec_dir=XXXINSTALLATION_DIRXXX/bin

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name of the first half-map.
reference_A_fn=<REFERENCE_A_FN>

# Relative path and name of the second half-map.
reference_B_fn=<REFERENCE_B_FN>

# Relative path and name of the FSC mask.
FSC_mask_fn=<FSC_MASK_FN>

# Relative path and prefix for the name of the output maps and figures.
output_fn_prefix=<OUTPUT_FN_PREFIX>

################################################################################
#                                  VARIABLES                                   #
################################################################################
# FSC executable
cFSC_exec=${exec_dir}/parallel_conical_FSC

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
#                                 FSC OPTIONS                                  #
################################################################################
# Pixelsize of the half-maps in Angstroms
pixelsize=<PIXELSIZE>

# Symmetry to applied the half-maps before calculating FSC (1 is no symmetry)
nfold=<NFOLD>

# How many orientations to calculate the FSC at 200 is from Diebolder et al.
# 2015, and is about 14 degree spacing while 105 is from Lyumkis et al. 2017 and
# is about 20 degree spacing
n_points=<N_POINTS>

# How many orientation sot calculate in each parallel conical FSC job
point_batch_size=<POINT_BATCH_SIZE>
################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ ! -d ${mcr_cache_dir} ]]
then
    mkdir -p ${mcr_cache_dir}
fi

# Generate and launch array file
array_start=1
array_end=$(((n_points + point_batch_size - 1) / point_batch_size))
cat > ${job_name}_paral_cFSC_array<<-CFSCJOB
#!/bin/bash
#$ -N ${job_name}_paral_cFSC
#$ -S
#$ -V
#$ -cwd
#$ -l mem_free=${mem_free},h_vmem=${mem_max}
#$ -o log_${job_name}_paral_cFSC_array
#$ -e error_${job_name}_paral_cFSC_array
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
MCRDIR=${PWD}/${mcr_cache_dir}/conical_FSC
rm -rf \${MCRDIR}
mkdir \${MCRDIR}
export MCR_CACHE_ROOT=\${MCRDIR}
time ${cFSC_exec} \\
    ${reference_A_fn} \\
    ${reference_B_fn} \\
    ${FSC_mask_fn} \\
    ${output_fn_prefix} \\
    ${pixelsize} \\
    ${nfold} \\
    ${n_points} \\
    ${point_batch_size} \\
    \${SGE_TASK_ID}
rm -rf \${MCRDIR}
###done 2>error_${job_name}_paral_cFSC_array >log_${job_name}_paral_cFSC_array
CFSCJOB
if [[ ${run_local} -eq 1 ]]
then
    mv ${job_name}_paral_cFSC_array temp_array
    sed 's/\#\#\#//' temp_array > ${job_name}_paral_cFSC_array
    rm temp_array
    chmod u+x ${job_name}_paral_cFSC_array &
else
    qsub ${job_name}_paral_cFSC_array
fi

echo "STARTING Conical FSC calculation"
################################################################################
#                             CONICAL FSC PROGRESS                             #
################################################################################
FSC_dir=$(dirname ${scratch_dir}/${output_fn_prefix})
FSC_base=$(basename ${scratch_dir}/${output_fn_prefix})
num_complete=$(find ${FSC_dir} -name "${FSC_base}_*.em" | wc -l)
num_complete_prev=0
unchanged_count=0

while [[ ${num_complete} -lt ${n_points} ]]
do
    num_complete=$(find ${FSC_dir} -name "${FSC_base}_*.em" | wc -l)
    echo "${num_complete} conical FSCs out of ${n_points}"
    if [[ ${num_complete} -eq ${num_complete_prev} ]]
    then
        unchanged_count=$((unchanged_count + 1))
    else
        unchanged_count=0
    fi
    num_complete_prev=${num_complete}
    
    if [[ ${num_complete} -gt 0 && ${unchanged_count} -gt 120 ]]
    then
        echo "Parallel conical FSC calculation has seemed to stall"
        echo "Please check error logs and resubmit the job if neeeded."
        exit 1
    fi
    sleep 60s
done
