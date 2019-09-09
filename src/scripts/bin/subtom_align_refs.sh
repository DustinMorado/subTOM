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
# This subtomogram multireference parallel averaging script uses five MATLAB
# compiled scripts below:
# - subtom_scan_angles_exact_refs
# - subtom_parallel_sums
# - subtom_parallel_sums_cls
# - subtom_weighted_average
# - subtom_weighted_average_cls
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
fi

if [[ ! -d "${mcr_cache_dir}" ]]
then
    mkdir -p "${mcr_cache_dir}"
fi

all_motl_dir="${scratch_dir}/$(dirname "${all_motl_fn_prefix}")"
all_motl_base="$(basename "${all_motl_fn_prefix}")"

output_motl_dir="${scratch_dir}/$(dirname "${output_motl_fn_prefix}")"
output_motl_base="$(basename "${output_motl_fn_prefix}")"

if [[ ! -d "${output_motl_dir}" ]]
then
    mkdir -p "${output_motl_dir}"
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

if [[ "${align_mask_fn}" == "none" ]]
then
    align_mask_fn_="none"
else
    align_mask_fn_="${scratch_dir}/${align_mask_fn}"
fi

if [[ "${cc_mask_fn}" == "noshift" ]]
then
    cc_mask_fn_="noshift"
else
    cc_mask_fn_="${scratch_dir}/${cc_mask_fn}"
fi

################################################################################
#                           CLASS AVERAGE ALIGNMENT                            #
################################################################################
output_motl_fn_="${scratch_dir}/${output_motl_fn_prefix}"
output_motl_fn="${output_motl_fn_}_classed_${iteration}.em"
output_motl_fn_="${output_motl_fn_}_unclassed_${iteration}.em"

if [[ ! -f "${output_motl_fn}" && ! -f "${output_motl_fn_}" ]]
then
    echo -e "\nSTARTING Class Average Alignment - Iteration: ${iteration}\n"

    ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
    export LD_LIBRARY_PATH="${ldpath}"

    job_name_="${job_name}_scan_angles_exact_refs"
    mcr_cache_dir_="${mcr_cache_dir}/${job_name_}"

    if [[ -d "${mcr_cache_dir_}" ]]
    then
        rm -rf "${mcr_cache_dir_}"
    fi

    export MCR_CACHE_ROOT="${mcr_cache_dir_}"

    "${align_exec}" \
        all_motl_fn_prefix \
        "${scratch_dir}/${all_motl_fn_prefix}" \
        ref_fn_prefix \
        "${scratch_dir}/${ref_fn_prefix}" \
        align_mask_fn \
        "${align_mask_fn_}" \
        cc_mask_fn \
        "${cc_mask_fn_}" \
        output_motl_fn_prefix \
        "${scratch_dir}/${output_motl_fn_prefix}" \
        apply_mask \
        "${apply_mask}" \
        ref_class \
        "${ref_class}" \
        psi_angle_step \
        "${psi_angle_step}" \
        psi_angle_shells \
        "${psi_angle_shells}" \
        phi_angle_step \
        "${phi_angle_step}" \
        phi_angle_shells \
        "${phi_angle_shells}" \
        high_pass_fp \
        "${high_pass_fp}" \
        high_pass_sigma \
        "${high_pass_sigma}" \
        low_pass_fp \
        "${low_pass_fp}" \
        low_pass_sigma \
        "${low_pass_sigma}" \
        nfold \
        "${nfold}" \
        iteration \
        "${iteration}"

    rm -rf "${mcr_cache_dir_}"
else
    echo "${output_motl_fn} and ${output_motl_fn_} already exist."
    echo -e "\nSKIPPING Class Average Alignment - Iteration: ${iteration}\n"
fi

################################################################################
#                       CLASS AVERAGE ALIGNMENT CLEAN UP                       #
################################################################################
if [[ ${skip_local_copy} -ne 1 ]]
then
    local_all_motl_dir="$(dirname "${local_dir}/${all_motl_fn_prefix}")"

    if [[ ! -d "${local_all_motl_dir}" ]]
    then
        mkdir -p "${local_all_motl_dir}"
    fi

    find "${all_motl_dir}" -regex \
        ".*/${all_motl_base}_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_all_motl_dir}/."

    local_output_motl_dir="$(dirname "${local_dir}/${output_motl_fn_prefix}")"

    if [[ ! -d "${local_output_motl_dir}" ]]
    then
        mkdir -p "${local_output_motl_dir}"
    fi

    find "${output_motl_dir}" -regex \
        ".*/${output_motl_base}_classed_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_output_motl_dir}/."

    find "${output_motl_dir}" -regex \
        ".*/${output_motl_base}_unclassed_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_output_motl_dir}/."
fi

echo -e "\nFINISHED Class Average Alignment - Iteration: ${iteration}\n"

################################################################################
#                                                                              #
#                              PARALLEL AVERAGING                              #
#                                                                              #
################################################################################
#                           PARALLEL CLASS AVERAGING                           #
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

    error_fn="error_${script_fn}"

    if [[ -f "${error_fn}" ]]
    then
        rm -f "${error_fn}"
    fi

    log_fn="log_${script_fn}"

    if [[ -f "${log_fn}" ]]
    then
        rm -f "${log_fn}"
    fi

    cat > "${script_fn}"<<-PSUMCLSJOB
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

    "${sum_cls_exec}" \\
        all_motl_fn_prefix \\
        "${scratch_dir}/${output_motl_fn_prefix}_classed" \\
        ref_fn_prefix \\
        "${scratch_dir}/${ref_fn_prefix}_aligned" \\
        ptcl_fn_prefix \\
        "${scratch_dir}/${ptcl_fn_prefix}" \\
        weight_fn_prefix \\
        "${scratch_dir}/${weight_fn_prefix}" \\
        weight_sum_fn_prefix \\
        "${scratch_dir}/${weight_sum_fn_prefix}_aligned" \\
        iteration \\
        "${iteration}" \\
        tomo_row \\
        ${tomo_row} \\
        num_avg_batch \\
        "${num_avg_batch}" \\
        process_idx \\
        "\${SGE_TASK_ID}"

###done 2>"${error_fn}" >"${log_fn}"
PSUMCLSJOB

done

# Unfortunately because of the AV3 specification of iclass (20th row in the
# MOTL) we have to do this complicated way of calculating the number of classes
# that are actually used in the average.
num_classes=$("${motl_dump_exec}" --row 20 \
    "${scratch_dir}/${all_motl_fn_prefix}_${iteration}.em" | sort -n |\
    uniq | awk 'BEGIN { num_classes = 0 } { if ($1 >= 0) { num_classes++ }
    if ($1 == 2) { num_classes-- } } END { print num_classes }')

num_total=$((num_avg_batch * num_classes))
num_complete=$(find "${ref_dir}" -regex \
    ".*/${ref_base}_aligned_class_[0-9]+_${iteration}_[0-9]+.em" | wc -l)

all_done=$(find "${ref_dir}" -regex \
    ".*/${ref_base}_aligned_class_[0-9]+_${iteration}.em" | wc -l)

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
    echo -e "\nSTARTING Parallel Class Sums - Iteration: ${iteration}\n"

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
    echo -e "\nSKIPPING Parallel Class Sums - Iteration: ${iteration}\n"
fi

################################################################################
#                      PARALLEL CLASS AVERAGING PROGRESS                       #
################################################################################
num_complete_prev=0
unchanged_count=0

while [[ ${num_complete} -lt ${num_total} ]]
do
    num_complete=$(find "${ref_dir}" -regex \
        ".*/${ref_base}_aligned_class_[0-9]+_${iteration}_[0-9]+.em" | wc -l)

    if [[ ${num_complete} -eq ${num_complete_prev} ]]
    then
        unchanged_count=$((unchanged_count + 1))
    else
        unchanged_count=0
    fi

    num_complete_prev=${num_complete}

    if [[ ${num_complete} -gt 0 && ${unchanged_count} -gt 120 ]]
    then
        echo "Parallel class summing has seemed to stall"
        echo "Please check error logs and resubmit the job if neeeded."
        exit 1
    fi

    if [[ -f "error_${job_name_}_1" ]]
    then
        echo -e "\nERROR Update: Class Sums - Iteration: ${iteration}\n"
        tail "error_${job_name_}"_*
    fi

    if [[ -f "log_${job_name_}_1" ]]
    then
        echo -e "\nLOG Update: Class Sums - Iteration: ${iteration}\n"
        tail "log_${job_name_}"_*
    fi

    echo -e "\nSTATUS Update: Class Sums - Iteration: ${iteration}\n"
    echo -e "\t${num_complete} parallel class sums out of ${num_total}\n"
    sleep 60s
done

################################################################################
#                      PARALLEL CLASS AVERAGING PROGRESS                       #
################################################################################
if [[ ! -d ali_ref_${iteration} ]]
then
    mkdir ali_ref_${iteration}
fi

if [[ -e "${job_name_}_1" ]]
then
    mv -f "${job_name_}"_* ali_ref_${iteration}/.
fi

if [[ -e "log_${job_name_}_1" ]]
then
    mv -f "log_${job_name_}"_* ali_ref_${iteration}/.
fi

if [[ -e "error_${job_name_}_1" ]]
then
    mv -f "error_${job_name_}"_* ali_ref_${iteration}/.
fi

find "${mcr_cache_dir}" -regex ".*/${job_name_}_[0-9]+" -print0 |\
    xargs -0 -I {} rm -rf -- {}

echo -e "\nFINISHED Parallel Class Sums - Iteration: ${iteration}\n"

################################################################################
#                             FINAL CLASS AVERAGE                              #
################################################################################
if [[ "${all_done}" -ne "${num_classes}" ]]
then
    echo -e "\nSTARTING Class Averaging - Iteration: ${iteration}\n"

    ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
    export LD_LIBRARY_PATH="${ldpath}"

    job_name_="${job_name}_weighted_average_cls"
    mcr_cache_dir_="${mcr_cache_dir}/${job_name_}"

    if [[ -d "${mcr_cache_dir_}" ]]
    then
        rm -rf "${mcr_cache_dir_}"
    fi

    export MCR_CACHE_ROOT="${mcr_cache_dir_}"

    "${avg_cls_exec}" \
        all_motl_fn_prefix \
        "${scratch_dir}/${output_motl_fn_prefix}_classed" \
        ref_fn_prefix \
        "${scratch_dir}/${ref_fn_prefix}_aligned" \
        weight_sum_fn_prefix \
        "${scratch_dir}/${weight_sum_fn_prefix}_aligned" \
        iteration \
        "${iteration}" \
        num_avg_batch \
        "${num_avg_batch}"

    rm -rf "${mcr_cache_dir_}"
else
    echo -e "\nSKIPPING Class Averaging - Iteration: ${iteration}\n"
fi

################################################################################
#                         FINAL CLASS AVERAGE CLEAN UP                         #
################################################################################
if [[ ${skip_local_copy} -ne 1 ]]
then
    local_ref_dir="$(dirname "${local_dir}/${ref_fn_prefix}")"

    if [[ ! -d "${local_ref_dir}" ]]
    then
        mkdir -p "${local_ref_dir}"
    fi

    find "${ref_dir}" -regex \
        ".*/${ref_base}_aligned_class_[0-9]+_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_ref_dir}/."

    find "${ref_dir}" -regex \
        ".*/${ref_base}_aligned_[XYZ]_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_ref_dir}/."

    find "${ref_dir}" -regex \
        ".*/${ref_base}_aligned_class_[0-9]+_debug_raw_${iteration}.em" \
        -print0 | xargs -0 -I {} cp -- {} "${local_ref_dir}/."

    local_weight_sum_dir="$(dirname "${local_dir}/${weight_sum_fn_prefix}")"

    if [[ ! -d "${local_weight_sum_dir}" ]]
    then
        mkdir -p "${local_weight_sum_dir}"
    fi

    find "${weight_sum_dir}" -regex \
        ".*/${weight_sum_base}_aligned_class_[0-9]+_debug_${iteration}.em" \
        -print0 | xargs -0 -I {} cp -- {} "${local_weight_sum_dir}/."

    find "${weight_sum_dir}" -regex \
        ".*/${weight_sum_base}_aligned_class_[0-9]+_debug_inv_${iteration}.em" \
        -print0 | xargs -0 -I {} cp -- {} "${local_weight_sum_dir}/."

fi

find "${ref_dir}" -regex \
    ".*/${ref_base}_aligned_class_[0-9]+_${iteration}_[0-9]+.em" -delete

find "${weight_sum_dir}" -regex \
    ".*/${weight_sum_base}_aligned_class_[0-9]+_${iteration}_[0-9]+.em" -delete

echo -e "\nFINISHED Class Averaging - Iteration: ${iteration}\n"

################################################################################
#                              PARALLEL AVERAGING                              #
################################################################################
# Calculate number of job scripts needed
num_jobs=$(((num_avg_batch + array_max - 1) / array_max))
job_name_="${job_name}_parallel_sums"

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

    error_fn="error_${script_fn}"

    if [[ -f "${error_fn}" ]]
    then
        rm -f "${error_fn}"
    fi

    log_fn="log_${script_fn}"

    if [[ -f "${log_fn}" ]]
    then
        rm -f "${log_fn}"
    fi

    cat > "${script_fn}"<<-PSUMALLJOB
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
        "${scratch_dir}/${output_motl_fn_prefix}_unclassed" \\
        ref_fn_prefix \\
        "${scratch_dir}/${ref_fn_prefix}_aligned" \\
        ptcl_fn_prefix \\
        "${scratch_dir}/${ptcl_fn_prefix}" \\
        weight_fn_prefix \\
        "${scratch_dir}/${weight_fn_prefix}" \\
        weight_sum_fn_prefix \\
        "${scratch_dir}/${weight_sum_fn_prefix}_aligned" \\
        iteration \\
        "${iteration}" \\
        tomo_row \\
        ${tomo_row} \\
        iclass \\
        1 \\
        num_avg_batch \\
        "${num_avg_batch}" \\
        process_idx \\
        "\${SGE_TASK_ID}"

###done 2>"${error_fn}" >"${log_fn}"
PSUMALLJOB

done

num_complete=$(find "${ref_dir}" -regex \
    ".*/${ref_base}_aligned_${iteration}_[0-9]+.em" | wc -l)

ref_fn="${scratch_dir}/${ref_fn_prefix}_aligned_${iteration}.em"

if [[ -f "${ref_fn}" ]]
then
    do_run=0
    num_complete="${num_avg_batch}"
elif [[ "${num_complete}" -eq "${num_avg_batch}" ]]
then
    do_run=0
else
    do_run=1
fi

if [[ "${do_run}" -eq "1" ]]
then
    echo -e "\nSTARTING Parallel Sums - Iteration: ${iteration}\n"

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
    echo -e "\nSKIPPING Parallel Sums - Iteration: ${iteration}\n"
fi

################################################################################
#                         PARALLEL AVERAGING PROGRESS                          #
################################################################################
    num_complete_prev=0
    unchanged_count=0

while [[ ${num_complete} -lt ${num_avg_batch} ]]
do
    num_complete=$(find "${ref_dir}" -regex \
        ".*/${ref_base}_aligned_${iteration}_[0-9]+.em" | wc -l)

    if [[ ${num_complete} -eq ${num_complete_prev} ]]
    then
        unchanged_count=$((unchanged_count + 1))
    else
        unchanged_count=0
    fi

    num_complete_prev=${num_complete}

    if [[ ${num_complete} -gt 0 && ${unchanged_count} -gt 120 ]]
    then
        echo "Parallel summing has seemed to stall"
        echo "Please check error logs and resubmit the job if neeeded."
        exit 1
    fi

    if [[ -f "error_${job_name_}_1" ]]
    then
        echo -e "\nERROR Update: Parallel Sums - Iteration: ${iteration}\n"
        tail "error_${job_name_}"_*
    fi

    if [[ -f "log_${job_name_}_1" ]]
    then
        echo -e "\nLOG Update: Parallel Sums - Iteration: ${iteration}\n"
        tail "log_${job_name_}"_*
    fi

    echo -e "\nSTATUS Update: Parallel Sums - Iteration: ${iteration}\n"
    echo -e "\t${num_complete} parallel sums out of ${num_avg_batch}\n"
    sleep 60s
done

################################################################################
#                      PARALLEL CLASS AVERAGING PROGRESS                       #
################################################################################
if [[ ! -d ali_ref_${iteration} ]]
then
    mkdir ali_ref_${iteration}
fi

if [[ -e "${job_name_}_1" ]]
then
    mv -f "${job_name_}"_* ali_ref_${iteration}/.
fi

if [[ -e "log_${job_name_}_1" ]]
then
    mv -f "log_${job_name_}"_* ali_ref_${iteration}/.
fi

if [[ -e "error_${job_name_}_1" ]]
then
    mv -f "error_${job_name_}"_* ali_ref_${iteration}/.
fi

find "${mcr_cache_dir}" -regex ".*/${job_name_}_[0-9]+" -print0 |\
    xargs -0 -I {} rm -rf -- {}

echo -e "\nFINISHED Parallel Sums - Iteration: ${iteration}\n"

################################################################################
#                             FINAL CLASS AVERAGE                              #
################################################################################
if [[ ! -f "${ref_fn}" ]]
then
    echo -e "\nSTARTING Averaging - Iteration: ${iteration}\n"

    ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
    export LD_LIBRARY_PATH="${ldpath}"

    job_name_="${job_name}_weighted_average"
    mcr_cache_dir_="${mcr_cache_dir}/${job_name_}"

    if [[ -d "${mcr_cache_dir_}" ]]
    then
        rm -rf "${mcr_cache_dir_}"
    fi

    export MCR_CACHE_ROOT="${mcr_cache_dir_}"

    "${avg_exec}" \
        all_motl_fn_prefix \
        "${scratch_dir}/${output_motl_fn_prefix}_unclassed" \
        ref_fn_prefix \
        "${scratch_dir}/${ref_fn_prefix}_aligned" \
        weight_sum_fn_prefix \
        "${scratch_dir}/${weight_sum_fn_prefix}_aligned" \
        iteration \
        "${iteration}" \
        iclass \
        1 \
        num_avg_batch \
        "${num_avg_batch}"

    rm -rf "${mcr_cache_dir_}"
else
    echo -e "\nSKIPPING Averaging - Iteration: ${iteration}\n"
fi

################################################################################
#                         FINAL CLASS AVERAGE CLEAN UP                         #
################################################################################
if [[ ${skip_local_copy} -ne 1 ]]
then
    local_ref_dir="$(dirname "${local_dir}/${ref_fn_prefix}")"

    if [[ ! -d "${local_ref_dir}" ]]
    then
        mkdir -p "${local_ref_dir}"
    fi

    find "${ref_dir}" -regex \
        ".*/${ref_base}_aligned_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_ref_dir}/."

    find "${ref_dir}" -regex \
        ".*/${ref_base}_aligned_debug_raw_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_ref_dir}/."

    local_weight_sum_dir="$(dirname "${local_dir}/${weight_sum_fn_prefix}")"

    if [[ ! -d "${local_weight_sum_dir}" ]]
    then
        mkdir -p "${local_weight_sum_dir}"
    fi

    find "${weight_sum_dir}" -regex \
        ".*/${weight_sum_base}_aligned_debug_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_weight_sum_dir}/."

    find "${weight_sum_dir}" -regex \
        ".*/${weight_sum_base}_aligned_debug_inv_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_weight_sum_dir}/."

fi

find "${ref_dir}" -regex \
    ".*/${ref_base}_aligned_${iteration}_[0-9]+.em" -delete

find "${weight_sum_dir}" -regex \
    ".*/${weight_sum_base}_aligned_${iteration}_[0-9]+.em" -delete

echo -e "\nFINISHED Averaging - Iteration: ${iteration}\n"

if [[ ! -f subTOM_protocol.md ]]
then
    touch subTOM_protocol.md
fi

printf "# Reference Alignment Iteration %d\n" "${iteration}" >>\
    subTOM_protocol.md

printf -- "-------------------------------------\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "OPTION" "VALUE" >> subTOM_protocol.md
printf "|:--------------------------" >> subTOM_protocol.md
printf "|:--------------------------|\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "scratch_dir" "${scratch_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "local_dir" "${local_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "mcr_cache_dir" "${mcr_cache_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "exec_dir" "${exec_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "align_exec" "${align_exec}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "sum_exec" "${sum_exec}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "avg_exec" "${avg_exec}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "sum_cls_exec" "${sum_cls_exec}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "avg_cls_exec" "${avg_cls_exec}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "motl_dump_exec" "${motl_dump_exec}" >>\
    subTOM_protocol.md

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

printf "| %-25s | %25s |\n" "output_motl_fn_prefix" \
    "${output_motl_fn_prefix}" >> subTOM_protocol.md

printf "| %-25s | %25s |\n" "ref_fn_prefix" "${ref_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "ptcl_fn_prefix" "${ptcl_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "align_mask_fn" "${align_mask_fn}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "cc_mask_fn" "${cc_mask_fn}" >> subTOM_protocol.md

printf "| %-25s | %25s |\n" "weight_fn_prefix" "${weight_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "weight_sum_fn_prefix" "${weight_sum_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "tomo_row" "${tomo_row}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "ref_class" "${ref_class}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "apply_mask" "${apply_mask}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "psi_angle_step" "${psi_angle_step}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "psi_angle_shells" "${psi_angle_shells}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "phi_angle_step" "${phi_angle_step}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "phi_angle_shells" "${phi_angle_shells}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "high_pass_fp" "${high_pass_fp}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "high_pass_sigma" "${high_pass_sigma}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "low_pass_fp" "${low_pass_fp}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "low_pass_sigma" "${low_pass_sigma}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n\n" "nfold" "${nfold}" >> subTOM_protocol.md
