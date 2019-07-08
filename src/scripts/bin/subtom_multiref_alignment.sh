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
# If the number of alignment jobs is greater than 1000, this script
# automatically splits the job into multiple arrays and launches them. It will
# not run if you have more than 4000 alignment jobs, as this is the current
# maximum per user.
#
# This subtomogram averaging script uses five MATLAB compiled scripts below:
# - subtom_scan_angles_exact
# - subtom_cat_motls
# - subtom_parallel_sums
# - subtom_weighted_average
# - subtom_compare_motls
# DRM 05-2019
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
set +o noclobber # Turn off preventing BASH overwriting files
unset ml
unset module

source "${1}"

# Check number of jobs
if [[ ${num_ali_batch} -gt ${max_jobs} || ${num_avg_batch} -gt ${max_jobs} ]]
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

    local_ref_dir="$(dirname "${local_dir}/${ref_fn_prefix}")"

    if [[ ! -d "${local_ref_dir}" ]]
    then
        mkdir -p "${local_ref_dir}"
    fi

    local_all_motl_dir="$(dirname "${local_dir}/${all_motl_fn_prefix}")"

    if [[ ! -d "${local_all_motl_dir}" ]]
    then
        mkdir -p "${local_all_motl_dir}"
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

weight_sum_dir="$(dirname "${weight_sum_fn_prefix}")"

if [[ ! -d "${scratch_dir}/${weight_sum_dir}" ]]
then
    mkdir -p "${scratch_dir}/${weight_sum_dir}"
fi

if [[ ${mem_free_ali%G} -ge 48 ]]
then
    dedmem_ali=',dedicated=24'
elif [[ ${mem_free_ali%G} -ge 24 ]]
then
    dedmem_ali=',dedicated=12'
else
    dedmem_ali=''
fi

if [[ ${mem_free_avg%G} -ge 48 ]]
then
    dedmem_avg=',dedicated=24'
elif [[ ${mem_free_avg%G} -ge 24 ]]
then
    dedmem_avg=',dedicated=12'
else
    dedmem_avg=''
fi

# Calculate the number of array subset jobs we will submit
num_ali_jobs=$(((num_ali_batch + array_max - 1) / array_max))
num_avg_jobs=$(((num_avg_batch + array_max - 1) / array_max))

# Check that number of iterations is inline with the arrays of parameters
while [[ "${#align_mask_fn[@]}" -lt "${iterations}" ]]
do
    idx="${#align_mask_fn[@]}"
    val="${align_mask_fn[$((idx - 1))]}"
    align_mask_fn[${idx}]="${val}"
done

while [[ "${#cc_mask_fn[@]}" -lt "${iterations}" ]]
do
    idx="${#cc_mask_fn[@]}"
    val="${cc_mask_fn[$((idx - 1))]}"
    cc_mask_fn[${idx}]="${val}"
done

while [[ "${#psi_angle_step[@]}" -lt "${iterations}" ]]
do
    idx="${#psi_angle_step[@]}"
    val="${psi_angle_step[$((idx - 1))]}"
    psi_angle_step[${idx}]="${val}"
done

while [[ "${#psi_angle_shells[@]}" -lt "${iterations}" ]]
do
    idx="${#psi_angle_shells[@]}"
    val="${psi_angle_shells[$((idx - 1))]}"
    psi_angle_shells[${idx}]="${val}"
done

while [[ "${#phi_angle_step[@]}" -lt "${iterations}" ]]
do
    idx="${#phi_angle_step[@]}"
    val="${phi_angle_step[$((idx - 1))]}"
    phi_angle_step[${idx}]="${val}"
done

while [[ "${#phi_angle_shells[@]}" -lt "${iterations}" ]]
do
    idx="${#phi_angle_shells[@]}"
    val="${phi_angle_shells[$((idx - 1))]}"
    phi_angle_shells[${idx}]="${val}"
done

while [[ "${#high_pass_fp[@]}" -lt "${iterations}" ]]
do
    idx="${#high_pass_fp[@]}"
    val="${high_pass_fp[$((idx - 1))]}"
    high_pass_fp[${idx}]="${val}"
done

while [[ "${#high_pass_sigma[@]}" -lt "${iterations}" ]]
do
    idx="${#high_pass_sigma[@]}"
    val="${high_pass_sigma[$((idx - 1))]}"
    high_pass_sigma[${idx}]="${val}"
done

while [[ "${#low_pass_fp[@]}" -lt "${iterations}" ]]
do
    idx="${#low_pass_fp[@]}"
    val="${low_pass_fp[$((idx - 1))]}"
    low_pass_fp[${idx}]="${val}"
done

while [[ "${#low_pass_sigma[@]}" -lt "${iterations}" ]]
do
    idx="${#low_pass_sigma[@]}"
    val="${low_pass_sigma[$((idx - 1))]}"
    low_pass_sigma[${idx}]="${val}"
done

while [[ "${#nfold[@]}" -lt "${iterations}" ]]
do
    idx="${#nfold[@]}"
    val="${nfold[$((idx - 1))]}"
    nfold[${idx}]="${val}"
done

# Calculate the final iteration
end_iteration="$((start_iteration + iterations - 1))"

# Calculate the number of classes in the motive list
num_classes=$(${motl_dump_exec} --row 20 \
    "${scratch_dir}/${all_motl_fn_prefix}_${start_iteration}.em" | sort -n |\
    uniq | awk 'BEGIN { num_classes = 0 } { if ($1 >= 0) { num_classes++ }
    if ($1 == 2) { num_classes-- } } END { print num_classes }')

# Calculate how many sum batches there will be.
num_to_complete=$((num_avg_batch * num_classes))

################################################################################
#                                                                              #
#                        SUBTOMOGRAM AVERAGING WORKFLOW                        #
#                                                                              #
################################################################################
for ((iteration = start_iteration, array_idx = 0; \
      iteration <= end_iteration; \
      iteration++, array_idx++))
do
    avg_iteration="$((iteration + 1))"

    all_motl_fn="${all_motl_fn_prefix}_${avg_iteration}.em"
    all_motl_dir="${scratch_dir}/$(dirname "${all_motl_fn_prefix}")"
    all_motl_base="$(basename "${all_motl_fn_prefix}")_${avg_iteration}"

    ref_dir="${scratch_dir}/$(dirname "${ref_fn_prefix}")"
    ref_base="$(basename "${ref_fn_prefix}")_class_[0-9]*_${avg_iteration}"
    ref_complete=$(find "${ref_dir}" -name "${ref_base}.em" | wc -l)

    if [[ ${ref_complete} -eq ${num_classes} ]]
    then
        ref_complete=1
    else
        ref_complete=0
    fi

    weight_sum_dir="${scratch_dir}/$(dirname "${weight_sum_fn_prefix}")"
    weight_sum_base="$(basename "${weight_sum_fn_prefix}")"
    weight_sum_base="${weight_sum_base}_class_[0-9]*_${avg_iteration}"

    output_diffs_fn="${all_motl_fn_prefix}_${iteration}_${avg_iteration}"
    output_diffs_fn="${output_diffs_fn}_diff.csv"

    job_name_ali="${job_name}_scan_angles_exact_${iteration}"

    if [[ -f "${job_name_ali}_1" ]]
    then
        rm -f "${job_name_ali}"_*
    fi

    if [[ -f "error_${job_name_ali}_1" ]]
    then
        rm -f "error_${job_name_ali}"_*
    fi

    if [[ -f "log_${job_name_ali}_1" ]]
    then
        rm -f "log_${job_name_ali}"_*
    fi

    job_name_cat="${job_name}_cat_motls_${iteration}"

    job_name_sums="${job_name}_parallel_sums_${avg_iteration}"

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

    job_name_avg="${job_name}_weighted_average_${avg_iteration}"

    job_name_compare="${job_name}_compare_motls_${iteration}"

    echo "            ITERATION number ${iteration}"

################################################################################
#                            SUBTOMOGRAM ALIGNMENT                             #
################################################################################

    if [[ ! -f "${scratch_dir}/${all_motl_fn}" ]]
    then
        echo "STARTING Alignment in Iteration Number: ${iteration}"

        # Generate and launch array files
        for ((job_idx = 1, array_start = 1; \
              job_idx <= num_ali_jobs; \
              job_idx++, array_start += array_max))
        do


            # Calculate end job
            array_end=$((array_start + array_max - 1))

            if [[ ${array_end} -gt ${num_ali_batch} ]]
            then
                array_end=${num_ali_batch}
            fi

            ### Write out script for each node
            cat > "${job_name_ali}_${job_idx}" <<-ALIJOB
#!/bin/bash
#$ -N "${job_name_ali}_${job_idx}"
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${mem_free_ali},h_vmem=${mem_max_ali}${dedmem_ali}
#$ -o "log_${job_name_ali}_${job_idx}"
#$ -e "error_${job_name_ali}_${job_idx}"
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
    mcr_cache_dir="${mcr_cache_dir}/${job_name_ali}_${job_idx}_\${SGE_TASK_ID}"

    if [[ ! -d "\${mcr_cache_dir}" ]]
    then
        mkdir -p "\${mcr_cache_dir}"
    else
        rm -rf "\${mcr_cache_dir}"
        mkdir -p "\${mcr_cache_dir}"
    fi

    export MCR_CACHE_ROOT="\${mcr_cache_dir}"

    "${align_exec}" \\
        all_motl_fn_prefix \\
        "${scratch_dir}/${all_motl_fn_prefix}" \\
        ref_fn_prefix \\
        "${scratch_dir}/${ref_fn_prefix}" \\
        ptcl_fn_prefix \\
        "${scratch_dir}/${ptcl_fn_prefix}" \\
        weight_fn_prefix \\
        "${scratch_dir}/${weight_fn_prefix}" \\
        align_mask_fn \\
        "${scratch_dir}/${align_mask_fn[${array_idx}]}" \\
        cc_mask_fn \\
        "${scratch_dir}/${cc_mask_fn[${array_idx}]}" \\
        apply_weight \\
        "${apply_weight}" \\
        apply_mask \\
        "${apply_mask}" \\
        psi_angle_step \\
        "${psi_angle_step[${array_idx}]}" \\
        psi_angle_shells \\
        "${psi_angle_shells[${array_idx}]}" \\
        phi_angle_step \\
        "${phi_angle_step[${array_idx}]}" \\
        phi_angle_shells \\
        "${phi_angle_shells[${array_idx}]}" \\
        high_pass_fp \\
        "${high_pass_fp[${array_idx}]}" \\
        high_pass_sigma \\
        "${high_pass_sigma[${array_idx}]}" \\
        low_pass_fp \\
        "${low_pass_fp[${array_idx}]}" \\
        low_pass_sigma \\
        "${low_pass_sigma[${array_idx}]}" \\
        nfold \\
        "${nfold[${array_idx}]}" \\
        threshold \\
        "${threshold}" \\
        iteration \\
        "${iteration}" \\
        tomo_row \\
        "${tomo_row}" \\
        num_ali_batch \\
        "${num_ali_batch}" \\
        process_idx \\
        "\${SGE_TASK_ID}"

    rm -rf "\${mcr_cache_dir}"
###done 2> "error_${job_name_ali}_${job_idx}" >\\
###"log_${job_name_ali}_${job_idx}"
ALIJOB

            num_complete=$(find "${all_motl_dir}" \
                -name "${all_motl_base}_[0-9]*.em" | wc -l)

            num_complete_prev=0
            unchanged_count=0

            chmod u+x "${job_name_ali}_${job_idx}"

            if [[ ${run_local} -eq 1 && ${num_complete} -lt ${num_ali_batch} ]]
            then
                sed -i 's/\#\#\#//' "${job_name_ali}_${job_idx}"
                "./${job_name_ali}_${job_idx}" &
            elif [[ ${num_complete} -lt ${num_avg_batch} ]]
            then
                qsub "${job_name_ali}_${job_idx}"
            fi
        done

################################################################################
#                              ALIGNMENT PROGRESS                              #
################################################################################

        while [[ ${num_complete} -lt ${num_ali_batch} ]]
        do
            num_complete=$(find "${all_motl_dir}" \
                -name "${all_motl_base}_[0-9]*.em" | wc -l)

            if [[ ${num_complete} -eq ${num_complete_prev} ]]
            then
                unchanged_count=$((unchanged_count + 1))
            else
                unchanged_count=0
            fi

            num_complete_prev=${num_complete}

            if [[ ${num_complete} -gt 0 && ${unchanged_count} -gt 240 ]]
            then
                echo "Alignment has seemed to stall"
                echo "Please check error logs and resubmit the job if neeeded."
                exit 1
            fi  

            if [[ -f "error_${job_name_ali}_1" ]]
            then
                echo -e "\nERROR Update: Alignment iteration ${iteration}\n"
                tail "error_${job_name_ali}"_*
            fi

            if [[ -f "log_${job_name_ali}_1" ]]
            then
                echo -e "\nLOG Update: Alignment iteration ${iteration}\n"
                tail "log_${job_name_ali}"_*
            fi

            echo -e "\nSTATUS Update: Alignment iteration ${iteration}\n"
            echo -e "\t${num_complete} aligned MOTLs out of ${num_ali_batch}\n"
            sleep 60s
        done

################################################################################
#                              ALIGNMENT CLEAN UP                              #
################################################################################

        if [[ ! -d ali_${iteration} ]]
        then
            mkdir ali_${iteration}
        fi

        if [[ -e "${job_name_ali}_1" ]]
        then
            mv -f "${job_name_ali}"_* ali_${iteration}/.
        fi

        if [[ -e "log_${job_name_ali}_1" ]]
        then
            mv -f "log_${job_name_ali}"_* ali_${iteration}/.
        fi

        if [[ -e "error_${job_name_ali}_1" ]]
        then
            mv -f "error_${job_name_ali}"_* ali_${iteration}/.
        fi

################################################################################
#                           COLLECT & COMBINE MOTLS                            #
################################################################################

        ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
        ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
        ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
        ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
        export LD_LIBRARY_PATH="${ldpath}"

        mcr_cache_dir_cat="${mcr_cache_dir}/${job_name_cat}"

        if [[ ! -d "${mcr_cache_dir_cat}" ]]
        then
            mkdir -p "${mcr_cache_dir_cat}"
        else
            rm -rf "${mcr_cache_dir_cat}"
            mkdir -p "${mcr_cache_dir_cat}"
        fi

        export MCR_CACHE_ROOT="${mcr_cache_dir_cat}"

        batch_idx=0
        input_motl_fmt="${scratch_dir}/${all_motl_fn_prefix}_${avg_iteration}"
        for batch in $(seq 1 ${num_ali_batch})
        do
            input_motl_fns[${batch_idx}]="${input_motl_fmt}_${batch}.em"
            batch_idx=$((batch_idx + 1))
        done

        "${cat_exec}" \
            write_motl \
            "1" \
            output_motl_fn \
            "${scratch_dir}/${all_motl_fn}" \
            write_star \
            "0" \
            output_star_fn \
            "" \
            sort_row \
            "4" \
            do_quiet \
            "1" \
            "${input_motl_fns[@]}"

        rm -rf "${mcr_cache_dir_cat}"

################################################################################
#                              MOTL JOIN CLEAN UP                              #
################################################################################

        if [[ ${skip_local_copy} -ne 1 ]]
        then
            cp "${scratch_dir}/${all_motl_fn}" "${local_dir}/${all_motl_fn}"
        fi

        find "${all_motl_dir}" -name "${all_motl_base}_[0-9]*.em" -delete

        echo "FINISHED Alignment in Iteration Number: ${iteration}"
    else
        echo "SKIPPED Alignment in Iteration Number: ${iteration}"
        echo "${scratch_dir}/${all_motl_fn} already exists."
    fi

################################################################################
#                              PARALLEL AVERAGING                              #
################################################################################

    if [[ ! -f "${ref_complete}" ]]
    then
        echo "STARTING Averaging in Iteration Number: ${avg_iteration}"

        # Generate and launch array files
        for ((job_idx = 1, array_start = 1; \
              job_idx <= num_avg_jobs; \
              job_idx++, array_start += array_max))
        do

            # Calculate end job
            array_end=$((array_start + array_max - 1))

            if [[ ${array_end} -gt ${num_avg_batch} ]]
            then
                array_end=${num_avg_batch}
            fi

            ### Write out script for each node
            cat > "${job_name_sums}_${job_idx}" <<-PSUMJOB
#!/bin/bash
#$ -N "${job_name_sums}_${job_idx}"
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${mem_free_avg},h_vmem=${mem_max_avg}${dedmem_avg}
#$ -o "log_${job_name_sums}_${job_idx}"
#$ -e "error_${job_name_sums}_${job_idx}"
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
        "${avg_iteration}" \\
        tomo_row \\
        ${tomo_row} \\
        num_avg_batch \\
        "${num_avg_batch}" \\
        process_idx \\
        "\${SGE_TASK_ID}"

    rm -rf "\${mcr_cache_dir}"
###done 2> "error_${job_name_sums}_${job_idx}" >\\
###"log_${job_name_sums}_${job_idx}"
PSUMJOB

            num_complete=$(find "${ref_dir}" \
                -name "${ref_base}_[0-9]*.em" | wc -l)

            num_complete_prev=0
            unchanged_count=0

            chmod u+x "${job_name_sums}_${job_idx}"

            if [[ ${run_local} -eq 1 && \
                ${num_complete} -lt ${num_to_complete} ]]
            then
                sed -i 's/\#\#\#//' "${job_name_sums}_${job_idx}"
                "./${job_name_sums}_${job_idx}" &
            elif [[ ${num_complete} -lt ${num_to_complete} ]]
            then
                qsub "${job_name_sums}_${job_idx}"
            fi
        done


################################################################################
#                         PARALLEL AVERAGING PROGRESS                          #
################################################################################

        while [[ ${num_complete} -lt ${num_to_complete} ]]
        do
            num_complete=$(find "${ref_dir}" \
                -name "${ref_base}_[0-9]*.em" | wc -l)

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
                echo -e "\nERROR Update: Averaging iteration ${avg_iteration}\n"
                tail "error_${job_name_sums}"_*
            fi

            if [[ -f "log_${job_name_sums}_1" ]]
            then
                echo -e "\nLOG Update: Averaging iteration ${avg_iteration}\n"
                tail "log_${job_name_sums}"_*
            fi

            echo -e "\nSTATUS Update: Averaging iteration ${avg_iteration}\n"
            echo -e -n "\t${num_complete} parallel sums out of "
            echo -e "${num_to_complete}\n"
            sleep 60s
        done

################################################################################
#                         PARALLEL AVERAGING CLEAN UP                          #
################################################################################

        if [[ ! -d avg_${avg_iteration} ]]
        then
            mkdir avg_${avg_iteration}
        fi

        if [[ -e "${job_name_sums}_1" ]]
        then
            mv -f "${job_name_sums}"_* avg_${avg_iteration}/.
        fi

        if [[ -e "log_${job_name_sums}_1" ]]
        then
            mv -f "log_${job_name_sums}"_* avg_${avg_iteration}/.
        fi

        if [[ -e "error_${job_name_sums}_1" ]]
        then
            mv -f "error_${job_name_sums}"_* avg_${avg_iteration}/.
        fi

################################################################################
#                                FINAL AVERAGE                                 #
################################################################################

        ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
        ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
        ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
        ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
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
            "${avg_iteration}" \
            num_avg_batch \
            "${num_avg_batch}"

        rm -rf "${mcr_cache_dir_avg}"

################################################################################
#                            FINAL AVERAGE CLEAN UP                            #
################################################################################

        if [[ ${skip_local_copy} -ne 1 ]]
        then
            cp "${scratch_dir}/${ref_fn_prefix}_class"_*_${avg_iteration}.em \
                "${local_ref_dir}/."

            temp_path="${scratch_dir}/${weight_sum_fn_prefix}_class"
            cp "${temp_path}"_*debug*_${avg_iteration}.em \
                "${local_weight_sum_dir}/."

        fi

        find "${ref_dir}" -name "${ref_base}_[0-9]*.em" -delete
        find "${weight_sum_dir}" -name "${weight_sum_base}_[0-9]*.em" -delete

        echo "FINISHED Averaging in Iteration Number: ${avg_iteration}"
    else
        echo "SKIPPED Averaging in Iteration Number: ${iteration}"
        echo "${scratch_dir}/${ref_fn} already exists."
    fi

################################################################################
#                        COMPARE CHANGES OVER ITERATION                        #
################################################################################

    if [[ ! -f "${scratch_dir}/${output_diffs_fn}" ]]
    then
        ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
        ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
        ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
        ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
        export LD_LIBRARY_PATH="${ldpath}"

        mcr_cache_dir_compare="${mcr_cache_dir}/${job_name_compare}"

        if [[ ! -d "${mcr_cache_dir_compare}" ]]
        then
            mkdir -p "${mcr_cache_dir_compare}"
        else
            rm -rf "${mcr_cache_dir_compare}"
            mkdir -p "${mcr_cache_dir_compare}"
        fi

        export MCR_CACHE_ROOT="${mcr_cache_dir_compare}"

        ${compare_exec} \
            motl_1_fn \
            "${scratch_dir}/${all_motl_fn_prefix}_${iteration}.em" \
            motl_2_fn \
            "${scratch_dir}/${all_motl_fn_prefix}_${avg_iteration}.em" \
            write_diffs \
            1 \
            output_diffs_fn \
            "${scratch_dir}/${output_diffs_fn}"

        rm -rf "\${mcr_cache_dir}"

################################################################################
#                             COMPARISON CLEAN UP                              #
################################################################################

        if [[ ${skip_local_copy} -ne 1 ]]
        then
            cp "${scratch_dir}/${output_diffs_fn}" \
                "${local_dir}/${output_diffs_fn}"

        fi
    fi

    if [[ ! -f subTOM_protocol.md ]]
    then
        touch subTOM_protocol.md
    fi

    printf "# Align and Average Iteration %d\n" "${iteration}" >>\
        subTOM_protocol.md

    printf -- "--------------------------------\n" >> subTOM_protocol.md
    printf "| %-25s | %25s |\n" "OPTION" "VALUE" >> subTOM_protocol.md
    printf "|:--------------------------" >> subTOM_protocol.md
    printf "|:--------------------------|\n" >> subTOM_protocol.md
    printf "| %-25s | %25s |\n" "scratch_dir" "${scratch_dir}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "local_dir" "${local_dir}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "mcr_cache_dir" "${mcr_cache_dir}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "exec_dir" "${exec_dir}" >> subTOM_protocol.md
    printf "| %-25s | %25s |\n" "align_exec" "${align_exec}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "cat_exec" "${cat_exec}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "sum_exec" "${sum_exec}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "avg_exec" "${avg_exec}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "compare_exec" "${compare_exec}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "motl_dump_exec" "${motl_dump_exec}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "mem_free_ali" "${mem_free_ali}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "mem_max_ali" "${mem_max_ali}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "mem_free_avg" "${mem_free_avg}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "mem_max_ali" "${mem_max_avg}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "job_name" "${job_name}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "array_max" "${array_max}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "max_jobs" "${max_jobs}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "run_local" "${run_local}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "skip_local_copy" "${skip_local_copy}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "num_ali_batch" "${num_ali_batch}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "num_avg_batch" "${num_avg_batch}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "all_motl_fn" \
        "${all_motl_fn_prefix}_${iteration}.em" >> subTOM_protocol.md

    printf "| %-25s | %25s |\n" "ref_fn" \
        "${ref_fn_prefix}_${iteration}.em" >> subTOM_protocol.md

    printf "| %-25s | %25s |\n" "ptcl_fn_prefix" "${ptcl_fn_prefix}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "align_mask_fn" \
        "${align_mask_fn[${array_idx}]}" >> subTOM_protocol.md

    printf "| %-25s | %25s |\n" "cc_mask_fn" \
        "${cc_mask_fn[${array_idx}]}" >> subTOM_protocol.md

    printf "| %-25s | %25s |\n" "weight_fn_prefix" "${weight_fn_prefix}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "weight_sum_fn_prefix" \
        "${weight_sum_fn_prefix}" >> subTOM_protocol.md

    printf "| %-25s | %25s |\n" "tomo_row" "${tomo_row}" >> subTOM_protocol.md
    printf "| %-25s | %25s |\n" "apply_weight" "${apply_weight}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "apply_mask" "${apply_mask}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n" "psi_angle_step" \
        "${psi_angle_step[${array_idx}]}" >> subTOM_protocol.md

    printf "| %-25s | %25s |\n" "psi_angle_shells" \
        "${psi_angle_shells[${array_idx}]}" >> subTOM_protocol.md

    printf "| %-25s | %25s |\n" "phi_angle_step" \
        "${phi_angle_step[${array_idx}]}" >> subTOM_protocol.md

    printf "| %-25s | %25s |\n" "phi_angle_shells" \
        "${phi_angle_shells[${array_idx}]}" >> subTOM_protocol.md

    printf "| %-25s | %25s |\n" "high_pass_fp" \
        "${high_pass_fp[${array_idx}]}" >> subTOM_protocol.md

    printf "| %-25s | %25s |\n" "high_pass_sigma" \
        "${high_pass_sigma[${array_idx}]}" >> subTOM_protocol.md

    printf "| %-25s | %25s |\n" "low_pass_fp" \
        "${low_pass_fp[${array_idx}]}" >> subTOM_protocol.md

    printf "| %-25s | %25s |\n" "low_pass_sigma" \
        "${low_pass_sigma[${array_idx}]}" >> subTOM_protocol.md

    printf "| %-25s | %25s |\n" "nfold" "${nfold[${array_idx}]}" >>\
        subTOM_protocol.md

    printf "| %-25s | %25s |\n\n" "threshold" "${threshold}" >>\
        subTOM_protocol.md

    printf "# Motive List Comparison Iteration %d\n" "${iteration}" >>\
        subTOM_protocol.md

    printf -- "-------------------------------------\n" >> subTOM_protocol.md
    printf "| %-50s | %25s |\n" "MEASUREMENT" "VALUE" >> subTOM_protocol.md
    printf "|:---------------------------------------------------" >>\
        subTOM_protocol.md

    printf "|--------------------------:|\n" >> subTOM_protocol.md
    awk -F, '{ if (NF == 23) {
        printf("| %-50s | %25f |\n", "Mean Coordinate Difference", $1);
        printf("| %-50s | %25f |\n", "Median Coordinate Difference", $2);
        printf("| %-50s | %25f |\n", "Coordinate Difference Std. Dev.", $3);
        printf("| %-50s | %25f |\n", "Max Coordinate Difference", $4);
        printf("| %-50s | %25f |\n", "Mean Angular Difference", $5);
        printf("| %-50s | %25f |\n", "Median Angular Difference", $6);
        printf("| %-50s | %25f |\n", "Angular Difference Std. Dev.", $7);
        printf("| %-50s | %25f |\n", "Max Angular Difference", $8);
        printf("| %-50s | %25f |\n",
            "Mean Angular Difference (no inplane)", $9);

        printf("| %-50s | %25f |\n",
            "Median Angular Difference (no inplane)", $10);

        printf("| %-50s | %25f |\n",
            "Angular Difference (no inplane) Std. Dev.", $11);

        printf("| %-50s | %25f |\n",
            "Max Angular Difference (no inplane)", $12);

        printf("| %-50s | %25f |\n", "Input Mean CCC", $13);
        printf("| %-50s | %25f |\n", "Input Median CCC", $14);
        printf("| %-50s | %25f |\n", "Input CCC Std. Dev.", $15);
        printf("| %-50s | %25f |\n", "Input Min. CCC", $16);
        printf("| %-50s | %25f |\n", "Input Max. CCC", $17);
        printf("| %-50s | %25f |\n", "Output Mean CCC", $18);
        printf("| %-50s | %25f |\n", "Output Median CCC", $19);
        printf("| %-50s | %25f |\n", "Output CCC Std. Dev.", $20);
        printf("| %-50s | %25f |\n", "Output Min. CCC", $21);
        printf("| %-50s | %25f |\n", "Output Max. CCC", $22);
        printf("| %-50s | %25f |\n\n", "Number of class changes", $23);
    }}' "${scratch_dir}/${output_diffs_fn}" >> subTOM_protocol.md

done
