#!/bin/bash
################################################################################
# This is a run script for the standard AV3 subtomogram classification scripts.
# The MATLAB executables for this script were compiled in MATLAB-8.5. The other
# difference is that these scripts have been edited to make sure that the output
# files from each step is readable.
#
# This script is meant to run on the scratch it copies the reference and final
# allmotl file to a local folder after each iteration.
#
# Also, the run script and all the launch scripts are written in bash. This is
# mainly because the behaviour of bash is a bit more predictable.
#
# If the number of alignment jobs is greater than 1000, this script
# automatically splits the job into multiple arrays and launches them. It will
# not run if you have more than 4000 alignment jobs, as this is the current
# maximum per user.
#
# This subtomogram averaging script uses three MATLAB compiled scripts below:
# - subtom_cluster
# - subtom_parallel_sums_cls
# - subtom_weighted_average_cls
# DRM 05-2019
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
set +o noclobber # Turn off preventing BASH overwriting files
unset ml
unset module

source "${1}"

# Check number of Averaging jobs
if [[ "${num_avg_batch}" -gt "${max_jobs}" ]]
then
    echo " TOO MANY AVERAGING JOBS!!!!!  I QUIT!!!"
    exit 1
fi

# Check that the appropriate directories exist
if [[ "${skip_local_copy}" -ne 1 ]]
then
    if [[ ! -d "${local_dir}" ]]
    then
        mkdir -p "${local_dir}"
    fi
fi

if [[ ! -d "${mcr_cache_dir}" ]]
then
    mkdir -p "${mcr_cache_dir}"
fi

cluster_all_motl_dir="${scratch_dir}/$(dirname "${cluster_all_motl_fn_prefix}")"
cluster_all_motl_base="$(basename "${cluster_all_motl_fn_prefix}")"

if [[ ! -d "${cluster_all_motl_dir}" ]]
then
    mkdir -p "${cluster_all_motl_dir}"
fi

ref_dir="${scratch_dir}/$(dirname "${ref_fn_prefix}")"
ref_base="$(basename "${ref_fn_prefix}")"

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
#                               CLASS AVERAGING                                #
#                                                                              #
################################################################################
#                                  CLUSTERING                                  #
################################################################################
cluster_fn="${scratch_dir}/${cluster_all_motl_fn_prefix}_${iteration}.em"

if [[ ! -f "${cluster_fn}" ]]
then
    ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
    export LD_LIBRARY_PATH="${ldpath}"

    job_name_="${job_name}_cluster"
    mcr_cache_dir_="${mcr_cache_dir}/${job_name_}"

    if [[ -d "${mcr_cache_dir_}" ]]
    then
        rm -rf "${mcr_cache_dir_}"
    fi

    export MCR_CACHE_ROOT="${mcr_cache_dir_}"

    "${cluster_exec}" \
        all_motl_fn_prefix \
        "${scratch_dir}/${coeff_all_motl_fn_prefix}" \
        coeff_fn_prefix \
        "${scratch_dir}/${coeff_fn_prefix}" \
        output_motl_fn_prefix \
        "${scratch_dir}/${cluster_all_motl_fn_prefix}" \
        iteration \
        "${iteration}" \
        cluster_type \
        "${cluster_type}" \
        coeff_idxs \
        "${coeff_idxs}" \
        num_classes \
        "${num_classes}"

    rm -rf "${mcr_cache_dir_}"
fi

################################################################################
#                             CLUSTERING CLEAN UP                              #
################################################################################
if [[ ${skip_local_copy} -ne 1 ]]
then
    local_cluster_all_motl_dir="$(dirname \
        "${local_dir}/${cluster_all_motl_fn_prefix}")"

    if [[ ! -d "${local_cluster_all_motl_dir}" ]]
    then
        mkdir -p "${local_cluster_all_motl_dir}"
    fi

    find "${cluster_all_motl_dir}" -regex \
        ".*/${cluster_all_motl_base}_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_cluster_all_motl_dir}/."

fi

################################################################################
#                              PARALLEL AVERAGING                              #
################################################################################
# Calculate number of job scripts needed
num_jobs=$(((num_avg_batch + array_max - 1) / array_max))
job_name_="${job_name}_parallel_sums_cls"

# Loop to generate parallel alignment scripts
for ((job_idx = 1, array_start = 1; \
      job_idx <= num_jobs; \
      job_idx++, array_start += array_max))
do
    array_end=$((array_start + array_max - 1))

    if [[ ${array_end} -gt ${num_avg_batch} ]]
    then
        array_end=${num_avg_batch}
    fi

    script_fn="${job_name_}_${job_idx}"

    if [[ -f "${script_fn}" ]]
    then
        rm -f "${script_fn}"
    fi

    error_fn="error_${job_name_}_${job_idx}"

    if [[ -f "${error_fn}" ]]
    then
        rm -f "${error_fn}"
    fi

    log_fn="log_${job_name_}_${job_idx}"

    if [[ -f "${log_fn}" ]]
    then
        rm -f "${log_fn}"
    fi

    cat>"${script_fn}"<<-PSUMJOB
#!/bin/bash
#$ -N "${script_fn}"
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${mem_free},h_vmem=${mem_max}${dedmem}
#$ -o "${log_fn}"
#$ -e "${error_fn}"
#$ -t ${array_start}-${array_end}
set +o noclobber
set -e

echo \${HOSTNAME}

ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
ldpath="\${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
ldpath="\${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
ldpath="\${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
export LD_LIBRARY_PATH="\${ldpath}"

###for SGE_TASK_ID in {${array_start}..${array_end}}; do
    mcr_cache_dir="${mcr_cache_dir}/${job_name_}_\${SGE_TASK_ID}"

    if [[ -d "\${mcr_cache_dir}" ]]
    then
        rm -rf "\${mcr_cache_dir}"
    fi

    export MCR_CACHE_ROOT="\${mcr_cache_dir}"

    "${sum_exec}" \\
        all_motl_fn_prefix \\
        "${scratch_dir}/${cluster_all_motl_fn_prefix}" \\
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
        "${tomo_row}" \\
        num_avg_batch \\
        "${num_avg_batch}" \\
        process_idx \\
        "\${SGE_TASK_ID}"

###done 2>"${error_fn}" >"${log_fn}"
PSUMJOB

done

num_total=$((num_avg_batch * num_classes))
num_complete=$(find "${ref_dir}" -regex \
    ".*/${ref_base}_class_[0-9]+_${iteration}_[0-9]+.em" | wc -l)

all_done=$(find "${ref_dir}" -regex \
    ".*/${ref_base}_class_[0-9]+_${iteration}.em" | wc -l)

if [[ "${all_done}" -eq "${num_classes}" ]]
then
    do_run=0
    num_complete="${num_total}"
elif [[ "${num_complete}" -eq "${num_total}" ]]
then
    do_run=0
else
    do_run=1
fi

if [[ "${do_run}" -eq "1" ]]
then
    echo -e "\nSTARTING Parallel Average - Iteration: ${iteration}\n"

    for job_idx in $(seq 1 ${num_jobs})
    do
        script_fn="${job_name_}_${job_idx}"
        chmod u+x "${script_fn}"

        if [[ "${run_local}" -eq 1 ]]
        then
            sed -i 's/\#\#\#//' "${script_fn}"
            "./${script_fn}" &
        else
            qsub "${script_fn}"
        fi
    done
else
    echo -e "\nSKIPPING Parallel Average - Iteration: ${iteration}\n"
fi

################################################################################
#                         PARALLEL AVERAGING PROGRESS                          #
################################################################################
num_complete_prev=0
unchanged_count=0

while [[ ${num_complete} -lt ${num_total} ]]
do
    num_complete=$(find "${ref_dir}" -regex \
        ".*/${ref_base}_class_[0-9]+_${iteration}_[0-9]+.em" | wc -l)

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

    if [[ -f "error_${job_name_}_1" ]]
    then
        echo -e "\nERROR Update: Averaging iteration ${iteration}\n"
        tail "error_${job_name_}"_*
    fi

    if [[ -f "log_${job_name_}_1" ]]
    then
        echo -e "\nLOG Update: Averaging iteration ${iteration}\n"
        tail "log_${job_name_}"_*
    fi

    echo -e "\nSTATUS Update: Averaging iteration ${iteration}\n"
    echo -e "\t${num_complete} parallel sums out of ${num_total}\n"
    sleep 60s
done

################################################################################
#                         PARALLEL AVERAGING CLEAN UP                          #
################################################################################
if [[ ! -d wmd_${iteration} ]]
then
    mkdir wmd_${iteration}
fi

if [[ -e "${job_name_}_1" ]]
then
    mv -f "${job_name_}"_* wmd_${iteration}/.
fi

if [[ -e "log_${job_name_}_1" ]]
then
    mv -f "log_${job_name_}"_* wmd_${iteration}/.
fi

if [[ -e "error_${job_name_}_1" ]]
then
    mv -f "error_${job_name_}"_* wmd_${iteration}/.
fi

find "${mcr_cache_dir}" -regex ".*/${job_name_}_[0-9]+" -print0 |\
    xargs -0 -I {} rm -rf -- {}

################################################################################
#                                FINAL AVERAGE                                 #
################################################################################
if [[ "${all_done}" -ne "${num_classes}" ]]
then
    ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
    export LD_LIBRARY_PATH="${ldpath}"

    job_name_="${job_name}_weighted_average_cls"
    mcr_cache_dir_="${mcr_cache_dir}/${job_name}_weighted_average"

    if [[ ! -d "${mcr_cache_dir_}" ]]
    then
        mkdir -p "${mcr_cache_dir_}"
    else
        rm -rf "${mcr_cache_dir_}"
        mkdir -p "${mcr_cache_dir_}"
    fi

    export MCR_CACHE_ROOT="${mcr_cache_dir_}"

    "${avg_exec}" \
        all_motl_fn_prefix \
        "${scratch_dir}/${cluster_all_motl_fn_prefix}" \
        ref_fn_prefix \
        "${scratch_dir}/${ref_fn_prefix}" \
        weight_sum_fn_prefix \
        "${scratch_dir}/${weight_sum_fn_prefix}" \
        iteration \
        "${iteration}" \
        num_avg_batch \
        "${num_avg_batch}"

    rm -rf "${mcr_cache_dir_}"
fi

################################################################################
#                            FINAL AVERAGE CLEAN UP                            #
################################################################################
if [[ ${skip_local_copy} -ne 1 ]]
then
    local_ref_dir="$(dirname "${local_dir}/${ref_fn_prefix}")"

    if [[ ! -d "${local_ref_dir}" ]]
    then
        mkdir -p "${local_ref_dir}"
    fi

    find "${ref_dir}" -regex \
        ".*/${ref_base}_class_[0-9]+_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_ref_dir}/."

    find "${ref_dir}" -regex \
        ".*/${ref_base}_class_[0-9]+_debug_raw_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_ref_dir}/."

    local_weight_sum_dir="$(dirname "${local_dir}/${weight_sum_fn_prefix}")"

    if [[ ! -d "${local_weight_sum_dir}" ]]
    then
        mkdir -p "${local_weight_sum_dir}"
    fi

    find "${weight_sum_dir}" -regex \
        ".*/${weight_sum_base}_class_[0-9]+_debug_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_weight_sum_dir}/."

    find "${weight_sum_dir}" -regex \
        ".*/${weight_sum_base}_class_[0-9]+_debug_inv_${iteration}.em" \
        -print0 | xargs -0 -I {} cp -- {} "${local_weight_sum_dir}/."

fi

find "${ref_dir}" -regex \
    ".*/${ref_base}_class_[0-9]+_${iteration}_[0-9]+.em" -delete

find "${weight_sum_dir}" -regex \
    ".*/${weight_sum_base}_class_[0-9]+_${iteration}_[0-9]+.em" -delete

echo -e "\nFINISHED Parallel Average - Iteration: ${iteration}\n"

if [[ ! -f subTOM_protocol.md ]]
then
    touch subTOM_protocol.md
fi

printf "# subTOM Cluster Iteration %d\n" "${iteration}" >>\
    subTOM_protocol.md

printf -- "---------------------------------\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "OPTION" "VALUE" >> subTOM_protocol.md
printf "|:--------------------------" >> subTOM_protocol.md
printf "|:--------------------------|\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "scratch_dir" "${scratch_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "local_dir" "${local_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "mcr_cache_dir" "${mcr_cache_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "exec_dir" "${exec_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "cluster_exec" "${cluster_exec}" >>\
    subTOM_protocol.md

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

printf "| %-25s | %25s |\n" "coeff_all_motl_fn_prefix" \
    "${coeff_all_motl_fn_prefix}" >> subTOM_protocol.md

printf "| %-25s | %25s |\n" "coeff_fn_prefix" "${coeff_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "cluster_type" "${cluster_type}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "coeff_idxs" "${coeff_idxs}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "num_classes" "${num_classes}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "cluster_all_motl_fn_prefix" \
    "${cluster_all_motl_fn_prefix}" >> subTOM_protocol.md

printf "| %-25s | %25s |\n" "ref_fn_prefix" "${ref_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n\n" "weight_sum_fn_prefix" \
    "${weight_sum_fn_prefix}" >> subTOM_protocol.md
