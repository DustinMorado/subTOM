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
# - subtom_parallel_sums
# - subtom_weighted_average
# DRM 05-2019
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
set +o noclobber # Turn off preventing BASH overwriting files
unset ml
unset module

source "${1}"

# Check number of jobs
if [[ "${num_avg_batch}" -gt "${max_jobs}" ]]
then
    echo " TOO MANY JOBS!!!!!  I QUIT!!!"
    exit 1
fi

# Check that the appropriate directories exist
if [[ "${skip_local_copy}" -ne 1 ]]
then

    if [[ ! -d "${local_dir}" ]]
    then
        mkdir -p "${local_dir}"
    fi

    local_all_motl_dir="$(dirname "${local_dir}/${all_motl_fn_prefix}")"

    if [[ ! -d "${local_all_motl_dir}" ]]
    then
        mkdir -p "${local_all_motl_dir}"
    fi

    local_ref_dir="$(dirname "${local_dir}/${ref_fn_prefix}")"

    if [[ ! -d "${local_ref_dir}" ]]
    then
        mkdir -p "${local_ref_dir}"
    fi

    local_weight_sum_dir="$(dirname "${local_dir}/${weight_sum_fn_prefix}")"

    if [[ ! -d "${local_weight_sum_dir}" ]]
    then
        mkdir -p "${local_weight_sum_dir}"
    fi
fi

if [[ ! -d "${mcr_cache_dir}" ]]
then
    mkdir -p "${mcr_cache_dir}"
fi

all_motl_dir="${scratch_dir}/$(dirname "${all_motl_fn_prefix}")"
all_motl_base="$(basename "${all_motl_fn_prefix}")"

ref_dir="${scratch_dir}/$(dirname "${ref_fn_prefix}")"
ref_base="$(basename "${ref_fn_prefix}")"

if [[ -f "${ref_dir}/${ref_base}_${iteration}.em" ]]
then
    echo "${ref_dir}/${ref_base}_${iteration}.em already complete. SKIPPING"
    exit 0
fi

if [[ ! -d "${ref_dir}" ]]
then
    mkdir -p "${ref_dir}"
fi

weight_sum_dir="${scratch_dir}/$(dirname "${weight_sum_fn_prefix}")"
weight_sum_base="$(basename "${weight_sum_fn_prefix}")"

if [[ ! -d "${weight_sum_dir}" ]]
then
    mkdir -p "${weight_sum_dir}"
fi

job_name_sums="${job_name}_parallel_sums_${iteration}"

if [[ -f "${job_name_sums}_1" ]]
then
    rm -f "${job_name_sums}"_*
fi

if [[ -f "error_${job_name_sums}_1" ]]
then
    rm -f "error_${job_name_sums}"_*
fi

if [[ -f "log_${job_name_sums}_1" ]]
then
    rm -f "log_${job_name_sums}"_*
fi

job_name_avg="${job_name}_weighted_average_${iteration}"

if [[ ${mem_free%G} -ge 48 ]]
then
    dedmem=',dedicated=24'
elif [[ ${mem_free%G} -ge 24 ]]
then
    dedmem=',dedicated=12'
else
    dedmem=''
fi

################################################################################
#                                                                              #
#                              PARALLEL AVERAGING                              #
#                                                                              #
################################################################################

# Calculate number of job scripts needed
num_avg_jobs=$(((num_avg_batch + array_max - 1) / array_max))

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

    cat > "${job_name_sums}_${job_idx}"<<-PSUMJOB
#!/bin/bash
#$ -N "${job_name_sums}_${job_idx}"
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${mem_free},h_vmem=${mem_max}${dedmem}
#$ -o "log_${job_name_sums}_${job_idx}"
#$ -e "error_${job_name_sums}_${job_idx}"
#$ -t ${array_start}-${array_end}
set +o noclobber
set -e

echo \${HOSTNAME}

ldpath="/public/matlab/jbriggs/runtime/glnxa64"
ldpath="\${ldpath}:/public/matlab/jbriggs/bin/glnxa64"
ldpath="\${ldpath}:/public/matlab/jbriggs/sys/os/glnxa64"
ldpath="\${ldpath}:/public/matlab/jbriggs/sys/opengl/lib/glnxa64"
export LD_LIBRARY_PATH="\${ldpath}"

###for SGE_TASK_ID in {${array_start}..${array_end}}; do
    mcr_cache_dir="${mcr_cache_dir}/${job_name_sums}_${job_idx}_\${SGE_TASK_ID}"

    if [[ ! -d "\${mcr_cache_dir}" ]]
    then
        mkdir -p "\${mcr_cache_dir}"
    else
        rm -rf "\${mcr_cache_dir}"
        mkdir -p "\${mcr_cache_dir}"
    fi

    export MCR_CACHE_ROOT="\${mcr_cache_dir}"

    "${sum_exec}" \\
        all_motl_fn_prefix \\
        "${scratch_dir}/${all_motl_fn_prefix}" \\
        ref_fn_prefix \\
        "${scratch_dir}/${ref_fn_prefix}" \\
        ptcl_fn_prefix \\
        "${scratch_dir}/${ptcl_fn_prefix}" \\
        weight_fn_prefix \\
        "${scratch_dir}/${weight_fn_prefix}" \\
        weight_sum_fn_prefix \\
        "${scratch_dir}/${weight_sum_fn_prefix}" \\
        iteration \\
        "${iteration}" \\
        tomo_row \\
        ${tomo_row} \\
        iclass \\
        "${iclass}" \\
        num_avg_batch \\
        "${num_avg_batch}" \\
        process_idx \\
        "\${SGE_TASK_ID}"

    rm -rf "\${mcr_cache_dir}"
###done 2> "error_${job_name_sums}_${job_idx}" >\\
###    "log_${job_name_sums}_${job_idx}"
PSUMJOB

    num_complete=$(find "${ref_dir}" -regex \
        ".*/${ref_base}_${iteration}_[0-9]+.em" | wc -l)

    num_complete_prev=0
    unchanged_count=0

    chmod u+x "${job_name_sums}_${job_idx}"

    if [[ "${run_local}" -eq 1 && ${num_complete} -lt ${num_avg_batch} ]]
    then
        sed -i 's/\#\#\#//' "${job_name_sums}_${job_idx}"
        "./${job_name_sums}_${job_idx}" &
    elif [[ ${num_complete} -lt ${num_avg_batch} ]]
    then
        qsub "${job_name_sums}_${job_idx}"
    fi
done

echo "STARTING Parallel Average in Iteration Number: ${iteration}"
################################################################################
#                         PARALLEL AVERAGING PROGRESS                          #
################################################################################

while [[ ${num_complete} -lt ${num_avg_batch} ]]
do
    num_complete=$(find "${ref_dir}" -regex \
        ".*/${ref_base}_${iteration}_[0-9]+.em" | wc -l)

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

    if [[ -f "error_${job_name_sums}_1" ]]
    then
        echo -e "\nERROR Update: Averaging iteration ${iteration}\n"
        tail "error_${job_name_sums}"_*
    fi

    if [[ -f "log_${job_name_sums}_1" ]]
    then
        echo -e "\nLOG Update: Averaging iteration ${iteration}\n"
        tail "log_${job_name_sums}"_*
    fi

    echo -e "\nSTATUS Update: Averaging iteration ${iteration}\n"
    echo -e "\t${num_complete} parallel sums out of ${num_avg_batch}\n"
    sleep 60s
done

################################################################################
#                         PARALLEL AVERAGING CLEAN UP                          #
################################################################################

if [[ ! -d avg_${iteration} ]]
then
    mkdir avg_${iteration}
fi

if [[ -e "${job_name_sums}_1" ]]
then
    mv -f "${job_name_sums}"_* avg_${iteration}/.
fi

if [[ -e "log_${job_name_sums}_1" ]]
then
    mv -f "log_${job_name_sums}"_* avg_${iteration}/.
fi

if [[ -e "error_${job_name_sums}_1" ]]
then
    mv -f "error_${job_name_sums}"_* avg_${iteration}/.
fi

echo "FINISHED Parallel Average in Iteration Number: ${iteration}"

################################################################################
#                                FINAL AVERAGE                                 #
################################################################################

ldpath="/public/matlab/jbriggs/runtime/glnxa64"
ldpath="${ldpath}:/public/matlab/jbriggs/bin/glnxa64"
ldpath="${ldpath}:/public/matlab/jbriggs/sys/os/glnxa64"
ldpath="${ldpath}:/public/matlab/jbriggs/sys/opengl/lib/glnxa64"
export LD_LIBRARY_PATH="${ldpath}"

mcr_cache_dir_avg="${mcr_cache_dir}/${job_name_avg}"

if [[ ! -d "${mcr_cache_dir_avg}" ]]
then
    mkdir -p "${mcr_cache_dir_avg}"
else
    rm -rf "${mcr_cache_dir_avg}"
    mkdir -p "${mcr_cache_dir_avg}"
fi

export MCR_CACHE_ROOT="${mcr_cache_dir_avg}"

"${avg_exec}" \
    all_motl_fn_prefix \
    "${scratch_dir}/${all_motl_fn_prefix}" \
    ref_fn_prefix \
    "${scratch_dir}/${ref_fn_prefix}" \
    weight_sum_fn_prefix \
    "${scratch_dir}/${weight_sum_fn_prefix}" \
    iteration \
    "${iteration}" \
    iclass \
    "${iclass}" \
    num_avg_batch \
    "${num_avg_batch}"

rm -rf "${mcr_cache_dir_avg}"

################################################################################
#                            FINAL AVERAGE CLEAN UP                            #
################################################################################

if [[ ${skip_local_copy} -ne 1 ]]
then
    find "${all_motl_dir}" -regex \
        ".*/${all_motl_base}_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_all_motl_dir}/."

    find "${ref_dir}" -regex \
        ".*/${ref_base}_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_ref_dir}/."

    find "${ref_dir}" -regex \
        ".*/${ref_base}_debug_raw_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_ref_dir}/."

    find "${weight_sum_dir}" -regex \
        ".*/${weight_sum_base}_debug_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_weight_sum_dir}/."

    find "${weight_sum_dir}" -regex \
        ".*/${weight_sum_base}_debug_inv_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_weight_sum_dir}/."

fi

find "${ref_dir}" -regex ".*/${ref_base}_${iteration}_[0-9]+.em" -delete
find "${weight_sum_dir}" -regex \
    ".*/${weight_sum_base}_${iteration}_[0-9]+.em" -delete

echo "FINISHED Final Average in Iteration Number: ${iteration}"
echo "AVERAGE DONE IN ITERATION NUMBER ${iteration}"

if [[ ! -f subTOM_protocol.md ]]
then
    touch subTOM_protocol.md
fi

printf "# Generate Average Iteration %d\n" "${iteration}" >> subTOM_protocol.md
printf -- "-------------------------------\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "OPTION" "VALUE" >> subTOM_protocol.md
printf "|:--------------------------" >> subTOM_protocol.md
printf "|:--------------------------|\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "scratch_dir" "${scratch_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "local_dir" "${local_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "mcr_cache_dir" "${mcr_cache_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "exec_dir" "${exec_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "sum_exec" "${sum_exec}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "avg_exec" "${avg_exec}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "mem_free" "${mem_free}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "mem_max" "${mem_max}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "job_name" "${job_name}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "array_max" "${array_max}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "max_jobs" "${max_jobs}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "run_local" "${run_local}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "skip_local_copy" "${skip_local_copy}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "iteration" "${iteration}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "num_avg_batch" "${num_avg_batch}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "all_motl_fn_prefix" "${all_motl_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "ref_fn_prefix" "${ref_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "ptcl_fn_prefix" "${ptcl_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "weight_fn_prefix" "${weight_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "weight_sum_fn_prefix" "${weight_sum_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "tomo_row" "${tomo_row}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n\n" "iclass" "${iclass}" >> subTOM_protocol.md
