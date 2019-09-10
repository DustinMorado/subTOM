#!/bin/bash
################################################################################
# This is a run script for the standard AV3 subtomogram averaging scripts. The
# MATLAB executables for this script were compiled in MATLAB-8.5. The other
# difference is that these scripts have been edited to make sure that the output
# files from each step is readable.
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

# Check that other directories exist and if not, make them
if [[ ${skip_local_copy} -ne 1 ]]
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

all_motl_a_dir="${scratch_dir}/$(dirname "${all_motl_a_fn_prefix}")"
all_motl_a_base="$(basename "${all_motl_a_fn_prefix}")"
all_motl_b_dir="${scratch_dir}/$(dirname "${all_motl_b_fn_prefix}")"
all_motl_b_base="$(basename "${all_motl_b_fn_prefix}")"

ref_a_dir="${scratch_dir}/$(dirname "${ref_a_fn_prefix}")"
ref_a_base="$(basename "${ref_a_fn_prefix}")"
ref_b_dir="${scratch_dir}/$(dirname "${ref_b_fn_prefix}")"
ref_b_base="$(basename "${ref_b_fn_prefix}")"

if [[ ! -d "${ref_a_dir}" ]]
then
    mkdir -p "${ref_a_dir}"
fi

if [[ ! -d "${ref_a_dir}" ]]
then
    mkdir -p "${ref_a_dir}"
fi

weight_sum_a_dir="${scratch_dir}/$(dirname "${weight_sum_a_fn_prefix}")"
weight_sum_a_base="$(basename "${weight_sum_a_fn_prefix}")"
weight_sum_b_dir="${scratch_dir}/$(dirname "${weight_sum_b_fn_prefix}")"
weight_sum_b_base="$(basename "${weight_sum_b_fn_prefix}")"

if [[ ! -d "${weight_sum_a_dir}" ]]
then
    mkdir -p "${weight_sum_a_dir}"
fi

if [[ ! -d "${weight_sum_b_dir}" ]]
then
    mkdir -p "${weight_sum_b_dir}"
fi

output_dir="${scratch_dir}/$(dirname "${output_fn_prefix}")"
output_base="$(basename "${output_fn_prefix}")"

if [[ ! -d "${output_dir}" ]]
then
    mkdir -p "${output_dir}"
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

if [[ "${fsc_mask_fn}" == "none" ]]
then
    fsc_mask_fn_="none"
else
    fsc_mask_fn_="${scratch_dir}/${fsc_mask_fn}"
fi

################################################################################
#                                                                              #
#                              PARALLEL AVERAGING                              #
#                                                                              #
################################################################################
# Calculate number of job scripts needed
num_jobs=$(((num_avg_batch + array_max - 1) / array_max))
job_name_="${job_name}_parallel_sums_bfactor"

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
        "${scratch_dir}/${all_motl_a_fn_prefix}" \\
        ref_fn_prefix \\
        "${scratch_dir}/${ref_a_fn_prefix}" \\
        ptcl_fn_prefix \\
        "${scratch_dir}/${ptcl_a_fn_prefix}" \\
        weight_fn_prefix \\
        "${scratch_dir}/${weight_a_fn_prefix}" \\
        weight_sum_fn_prefix \\
        "${scratch_dir}/${weight_sum_a_fn_prefix}" \\
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

    "${sum_exec}" \\
        all_motl_fn_prefix \\
        "${scratch_dir}/${all_motl_b_fn_prefix}" \\
        ref_fn_prefix \\
        "${scratch_dir}/${ref_b_fn_prefix}" \\
        ptcl_fn_prefix \\
        "${scratch_dir}/${ptcl_b_fn_prefix}" \\
        weight_fn_prefix \\
        "${scratch_dir}/${weight_b_fn_prefix}" \\
        weight_sum_fn_prefix \\
        "${scratch_dir}/${weight_sum_b_fn_prefix}" \\
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

###done 2>"${error_fn}" >"${log_fn}"
PSUMJOB

done

# Unfortunately because of the AV3 specification of iclass (20th row in the
# MOTL) we have to do this complicated way of calculating the number of
# particles that are actually used in the subsets average.
num_subsets_a=$("${motl_dump_exec}" --row 20 \
    "${scratch_dir}/${all_motl_a_fn_prefix}_${iteration}.em" |\
    awk -viclass=${iclass} 'BEGIN { num_ptcls = 0 } \
    { if ($1 == 1 || $1 == iclass) { num_ptcls++ } } \
    END { printf("%d", (int(log(num_ptcls / 128) / log(2)) + 1)) }')

num_total_a=$((num_avg_batch * num_subsets_a))
num_complete_a=$(find "${ref_a_dir}" -regex \
    ".*/${ref_a_base}_subset_[0-9]+_${iteration}_[0-9]+.em" | wc -l)

all_done_a=$(find "${ref_a_dir}" -regex \
    ".*/${ref_a_base}_subset_[0-9]+_${iteration}.em" | wc -l)

num_subsets_b=$("${motl_dump_exec}" --row 20 \
    "${scratch_dir}/${all_motl_b_fn_prefix}_${iteration}.em" |\
    awk -viclass=${iclass} 'BEGIN { num_ptcls = 0 }
    { if ($1 == 1 || $1 == iclass) { num_ptcls++ } }
    END { printf("%d", (int(log(num_ptcls / 128) / log(2)) + 1)) }')

num_total_b=$((num_avg_batch * num_subsets_b))
num_complete_b=$(find "${ref_b_dir}" -regex \
    ".*/${ref_b_base}_subset_[0-9]+_${iteration}_[0-9]+.em" | wc -l)

all_done_b=$(find "${ref_b_dir}" -regex \
    ".*/${ref_b_base}_subset_[0-9]+_${iteration}.em" | wc -l)

if [[ "${all_done_a}" -eq "${num_subsets_a}" && \
    "${all_done_b}" -eq "${num_subsets_b}" ]]
then
    do_run=0
    num_complete_a="${num_total_a}"
    num_complete_b="${num_total_b}"
elif [[ "${num_complete_a}" -eq "${num_total_a}" && \
    "${num_complete_b}" -eq "${num_total_b}" ]]
then
    do_run=0
else
    do_run=1
fi

if [[ "${do_run}" -eq "1" ]]
then
    echo -e "\nSTARTING Parallel Subset Sums - Iteration: ${iteration}\n"

    for job_idx in $(seq 1 "${num_jobs}")
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
    echo -e "\nSKIPPING Parallel Subset Sums - Iteration: ${iteration}\n"
fi

################################################################################
#                         PARALLEL AVERAGING PROGRESS                          #
################################################################################
num_complete_a_prev=0
unchanged_count_a=0

num_complete_b_prev=0
unchanged_count_b=0

while [[ "${num_complete_a}" -lt "${num_total_a}" || \
    "${num_complete_b}" -lt "${num_total_b}" ]]
do
    num_complete_a=$(find "${ref_a_dir}" -regex \
        ".*/${ref_a_base}_subset_[0-9]+_${iteration}_[0-9]+.em" | wc -l)

    num_complete_b=$(find "${ref_b_dir}" -regex \
        ".*/${ref_b_base}_subset_[0-9]+_${iteration}_[0-9]+.em" | wc -l)

    if [[ ${num_complete_a} -eq ${num_complete_a_prev} ]]
    then
        unchanged_count_a=$((unchanged_count_a + 1))
    else
        unchanged_count_a=0
    fi

    num_complete_prev_a=${num_complete_a}

    if [[ ${num_complete_b} -eq ${num_complete_b_prev} ]]
    then
        unchanged_count_b=$((unchanged_count_b + 1))
    else
        unchanged_count_b=0
    fi

    num_complete_prev_b=${num_complete_b}

    if [[ (${num_complete_a} -gt 0 && ${unchanged_count_a} -gt 120) || \
        (${num_complete_b} -gt 0 && ${unchanged_count_b} -gt 120) ]]
    then
        echo "Parallel Subset summing has seemed to stall"
        echo "Please check error logs and resubmit the job if neeeded."
        exit 1
    fi

    if [[ -f "error_${job_name_}_1" ]]
    then
        echo -e "\nERROR Update: B-factor Sums - Iteration: ${iteration}\n"
        tail "error_${job_name_}"_*
    fi

    if [[ -f "log_${job_name_}_1" ]]
    then
        echo -e "\nLOG Update: B-factor Sums - Iteration: ${iteration}\n"
        tail "log_${job_name_}"_*
    fi

    echo -e "\nSTATUS Update: B-factor Sums iteration ${iteration}\n"
    echo -e "\t${num_complete_a} parallel sums A out of ${num_total_a}\n"
    echo -e "\t${num_complete_b} parallel sums B out of ${num_total_b}\n"
    sleep 60s
done

################################################################################
#                         PARALLEL AVERAGING CLEAN UP                          #
################################################################################
if [[ ! -d b_factor_${iteration} ]]
then
    mkdir b_factor_${iteration}
fi

if [[ -e "${job_name_}_1" ]]
then
    mv -f "${job_name_}"_* b_factor_${iteration}/.
fi

if [[ -e "log_${job_name_}_1" ]]
then
    mv -f "log_${job_name_}"_* b_factor_${iteration}/.
fi

if [[ -e "error_${job_name_}_1" ]]
then
    mv -f "error_${job_name_}"_* b_factor_${iteration}/.
fi

find "${mcr_cache_dir}" -regex ".*/${job_name_}_[0-9]+" -print0 |\
    xargs -0 -I {} rm -rf -- {}

echo -e "\nFINISHED Parallel Subset Sums - Iteration: ${iteration}\n"

################################################################################
#                                FINAL AVERAGE                                 #
################################################################################
if [[ "${all_done_a}" -ne "${num_subsets_a}" || \
    "${all_done_b}" -ne "${num_subsets_b}" ]]
then
    ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
    export LD_LIBRARY_PATH="${ldpath}"

    job_name_="${job_name}_weighted_average_bfactor"
    mcr_cache_dir_="${mcr_cache_dir}/${job_name_}"

    if [[ -d "${mcr_cache_dir_}" ]]
    then
        rm -rf "${mcr_cache_dir_}"
    fi

    export MCR_CACHE_ROOT="${mcr_cache_dir_}"

    "${avg_exec}" \
        all_motl_fn_prefix \
        "${scratch_dir}/${all_motl_a_fn_prefix}" \
        ref_fn_prefix \
        "${scratch_dir}/${ref_a_fn_prefix}" \
        weight_sum_fn_prefix \
        "${scratch_dir}/${weight_sum_a_fn_prefix}" \
        iteration \
        "${iteration}" \
        iclass \
        "${iclass}" \
        num_avg_batch \
        "${num_avg_batch}"

    "${avg_exec}" \
        all_motl_fn_prefix \
        "${scratch_dir}/${all_motl_b_fn_prefix}" \
        ref_fn_prefix \
        "${scratch_dir}/${ref_b_fn_prefix}" \
        weight_sum_fn_prefix \
        "${scratch_dir}/${weight_sum_b_fn_prefix}" \
        iteration \
        "${iteration}" \
        iclass \
        "${iclass}" \
        num_avg_batch \
        "${num_avg_batch}"

    rm -rf "${mcr_cache_dir_}"
fi

################################################################################
#                            FINAL AVERAGE CLEAN UP                            #
################################################################################
if [[ ${skip_local_copy} -ne 1 ]]
then
    local_ref_a_dir="$(dirname "${local_dir}/${ref_a_fn_prefix}")"

    if [[ ! -d "${local_ref_a_dir}" ]]
    then
        mkdir -p "${local_ref_a_dir}"
    fi

    find "${ref_a_dir}" -regex \
        ".*/${ref_a_base}_subset_[0-9]+_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_ref_a_dir}/."

    find "${ref_a_dir}" -regex \
        ".*/${ref_a_base}_subset_[0-9]+_debug_raw_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_ref_a_dir}/."

    local_weight_sum_a_dir="$(dirname "${local_dir}/${weight_sum_a_fn_prefix}")"

    if [[ ! -d "${local_weight_sum_a_dir}" ]]
    then
        mkdir -p "${local_weight_sum_a_dir}"
    fi

    find "${weight_sum_a_dir}" -regex \
        ".*/${weight_sum_a_base}_subset_[0-9]+_debug_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_weight_sum_a_dir}/."

    find "${weight_sum_a_dir}" -regex \
        ".*/${weight_sum_a_base}_subset_[0-9]+_debug_inv_${iteration}.em" \
        -print0 | xargs -0 -I {} cp -- {} "${local_weight_sum_a_dir}/."

    local_ref_b_dir="$(dirname "${local_dir}/${ref_b_fn_prefix}")"

    if [[ ! -d "${local_ref_b_dir}" ]]
    then
        mkdir -p "${local_ref_b_dir}"
    fi

    find "${ref_b_dir}" -regex \
        ".*/${ref_b_base}_subset_[0-9]+_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_ref_b_dir}/."

    find "${ref_b_dir}" -regex \
        ".*/${ref_b_base}_subset_[0-9]+_debug_raw_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_ref_b_dir}/."

    local_weight_sum_b_dir="$(dirname "${local_dir}/${weight_sum_b_fn_prefix}")"

    if [[ ! -d "${local_weight_sum_b_dir}" ]]
    then
        mkdir -p "${local_weight_sum_b_dir}"
    fi

    find "${weight_sum_b_dir}" -regex \
        ".*/${weight_sum_b_base}_subset_[0-9]+_debug_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_weight_sum_b_dir}/."

    find "${weight_sum_b_dir}" -regex \
        ".*/${weight_sum_b_base}_subset_[0-9]+_debug_inv_${iteration}.em" \
        -print0 | xargs -0 -I {} cp -- {} "${local_weight_sum_b_dir}/."

fi

find "${ref_a_dir}" -regex \
    ".*/${ref_a_base}_subset_[0-9]+_${iteration}_[0-9]+.em" -delete

find "${ref_b_dir}" -regex \
    ".*/${ref_b_base}_subset_[0-9]+_${iteration}_[0-9]+.em" -delete

find "${weight_sum_a_dir}" -regex \
    ".*/${weight_sum_a_base}_subset_[0-9]+_${iteration}_[0-9]+.em" -delete

find "${weight_sum_b_dir}" -regex \
    ".*/${weight_sum_b_base}_subset_[0-9]+_${iteration}_[0-9]+.em" -delete

echo -e "\nFINISHED B-factor Subsets Average - Iteration: ${iteration}\n"

################################################################################
#                              MASK CORRECTED FSC                              #
################################################################################
ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
export LD_LIBRARY_PATH="${ldpath}"

job_name_="${job_name}_maskcorrected_fsc_bfactor"
mcr_cache_dir_="${mcr_cache_dir}/${job_name_}"

if [[ -d "${mcr_cache_dir_}" ]]
then
    rm -rf "${mcr_cache_dir_}"
fi

export MCR_CACHE_ROOT="${mcr_cache_dir_}"

"${fsc_exec}" \
    ref_a_fn_prefix \
    "${scratch_dir}/${ref_a_fn_prefix}" \
    ref_b_fn_prefix \
    "${scratch_dir}/${ref_b_fn_prefix}" \
    motl_a_fn_prefix \
    "${scratch_dir}/${all_motl_a_fn_prefix}" \
    motl_b_fn_prefix \
    "${scratch_dir}/${all_motl_b_fn_prefix}" \
    iteration \
    "${iteration}" \
    fsc_mask_fn \
    "${fsc_mask_fn_}" \
    output_fn_prefix \
    "${scratch_dir}/${output_fn_prefix}" \
    filter_a_fn \
    "${scratch_dir}/${filter_a_fn}" \
    filter_b_fn \
    "${scratch_dir}/${filter_b_fn}" \
    do_reweight \
    "${do_reweight}" \
    do_sharpen \
    "${do_sharpen}" \
    plot_fsc \
    "${plot_fsc}" \
    plot_sharpen \
    "${plot_sharpen}" \
    filter_mode \
    "${filter_mode}" \
    pixelsize \
    "${pixelsize}" \
    nfold \
    "${nfold}" \
    filter_threshold \
    "${filter_threshold}" \
    rand_threshold \
    "${rand_threshold}" \
    box_gaussian \
    "${box_gaussian}" \
    iclass \
    "${iclass}"

rm -rf "${mcr_cache_dir_}"

################################################################################
#                         MASK CORRECTED FSC CLEAN UP                          #
################################################################################
if [[ ${skip_local_copy} -ne 1 ]]
then
    local_output_dir="$(dirname "${local_dir}/${output_fn_prefix}")"

    if [[ ! -d "${local_output_dir}" ]]
    then
        mkdir -p "${local_output_dir}"
    fi

    find "${output_dir}" -regex \
        ".*/${output_base}_subset_FSC.[fp][dni][gf]" -print0 |\
        xargs -0 -I {} cp -- {} "${local_output_dir}/."

    find "${output_dir}" -regex \
        ".*/${output_base}_subset_b_factor.[fp][dni][gf]" -print0 |\
        xargs -0 -I {} cp -- {} "${local_output_dir}/."

    find "${output_dir}" -regex \
        ".*/${output_base}_sharp_-+[0-9]+.[fp][dni][gf]" -print0 |\
        xargs -0 -I {} cp -- {} "${local_output_dir}/."

    find "${output_dir}" -regex \
        ".*/${output_base}_unsharpref.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_output_dir}/."

    find "${output_dir}" -regex \
        ".*/${output_base}_finalsharpref_-?[0-9]+.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_output_dir}/."

    find "${output_dir}" -regex \
        ".*/${output_base}_unsharpref_reweight.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_output_dir}/."

    find "${output_dir}" -regex \
        ".*/${output_base}_finalsharpref_-?[0-9]+_reweight.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_output_dir}/."

fi

if [[ ! -f subTOM_protocol.md ]]
then
    touch subTOM_protocol.md
fi

printf "# B-Factor by Subsets Iteration %d\n" "${iteration}" >>\
    subTOM_protocol.md

printf -- "----------------------------------\n" >> subTOM_protocol.md
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
printf "| %-25s | %25s |\n" "fsc_exec" "${fsc_exec}" >> subTOM_protocol.md
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

printf "| %-25s | %25s |\n" "all_motl_a_fn_prefix" "${all_motl_a_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "all_motl_b_fn_prefix" "${all_motl_b_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "ref_a_fn_prefix" "${ref_a_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "ref_b_fn_prefix" "${ref_b_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "ptcl_a_fn_prefix" "${ptcl_a_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "ptcl_b_fn_prefix" "${ptcl_b_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "weight_a_fn_prefix" "${weight_a_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "weight_b_fn_prefix" "${weight_b_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "weight_sum_a_fn_prefix" \
    "${weight_sum_a_fn_prefix}" >> subTOM_protocol.md

printf "| %-25s | %25s |\n" "weight_sum_b_fn_prefix" \
    "${weight_sum_b_fn_prefix}" >> subTOM_protocol.md

printf "| %-25s | %25s |\n" "output_fn_prefix" "${output_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "tomo_row" "${tomo_row}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "iclass" "${iclass}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "fsc_mask_fn" "${fsc_mask_fn}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "filter_a_fn" "${filter_a_fn}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "filter_b_fn" "${filter_b_fn}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "pixelsize" "${pixelsize}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "nfold" "${nfold}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "rand_threshold" "${rand_threshold}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "plot_fsc" "${plot_fsc}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "do_sharpen" "${do_sharpen}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "box_gaussian" "${box_gaussian}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "filter_mode" "${filter_mode}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "filter_threshold" "${filter_threshold}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "plot_sharpen" "${plot_sharpen}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n\n" "do_reweight" "${do_reweight}" >>\
    subTOM_protocol.md
