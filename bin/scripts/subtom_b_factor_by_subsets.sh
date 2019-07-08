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
unset ml
unset module

source "${1}"

# Check number of jobs
if [[ "${num_avg_batch}" -gt "${max_jobs}" ]]
then
    echo " TOO MANY JOBS!!!!!  I QUIT!!!"
    exit 1
fi

if [[ ! -d "${mcr_cache_dir}" ]]
then
    mkdir -p "${mcr_cache_dir}"
fi

ref_dir="${scratch_dir}/$(dirname "${ref_fn_prefix}")"

if [[ ! -d "${ref_dir}" ]]
then
    mkdir -p "${ref_dir}"
fi

weight_sum_dir="${scratch_dir}/$(dirname "${weight_sum_fn_prefix}")"

if [[ ! -d "${scratch_dir}/${weight_sum_dir}" ]]
then
    mkdir -p "${scratch_dir}/${weight_sum_dir}"
fi

job_name_sums="${job_name}_b_factor_sums_${iteration}"

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

# Since we are generating subset averages in two halfsets
ref_a_fn_prefix="${ref_fn_prefix}_a"
ref_b_fn_prefix="${ref_fn_prefix}_b"

ref_a_base="$(basename "${ref_a_fn_prefix}_${iteration}")"
ref_b_base="$(basename "${ref_b_fn_prefix}_${iteration}")"

weight_sum_a_fn_prefix="${weight_sum_fn_prefix}_a"
weight_sum_b_fn_prefix="${weight_sum_fn_prefix}_b"

weight_sum_a_base="$(basename "${weight_sum_a_fn_prefix}_${iteration}")"
weight_sum_b_base="$(basename "${weight_sum_b_fn_prefix}_${iteration}")"

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

    ${sum_exec} \\
        all_motl_fn_prefix \\
        "${scratch_dir}/${all_motl_a_fn_prefix}" \\
        ref_fn_prefix \\
        "${scratch_dir}/${ref_a_fn_prefix}" \\
        ptcl_fn_prefix \\
        "${scratch_dir}/${ptcl_fn_prefix}" \\
        weight_fn_prefix \\
        "${scratch_dir}/${weight_fn_prefix}" \\
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

    ${sum_exec} \\
        all_motl_fn_prefix \\
        "${scratch_dir}/${all_motl_b_fn_prefix}" \\
        ref_fn_prefix \\
        "${scratch_dir}/${ref_b_fn_prefix}" \\
        ptcl_fn_prefix \\
        "${scratch_dir}/${ptcl_fn_prefix}" \\
        weight_fn_prefix \\
        "${scratch_dir}/${weight_fn_prefix}" \\
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

    rm -rf "\${mcr_cache_dir}"
###done 2> "error_${job_name_sums}_${job_idx}" >\\
###"log_${job_name_sums}_${job_idx}"
PSUMJOB

    chmod u+x "${job_name_sums}_${job_idx}"

    if [[ "${run_local}" -eq 1 ]]
    then
        sed -i 's/\#\#\#//' "${job_name_sums}_${job_idx}"
        "./${job_name_sums}_${job_idx}" &
    else
        qsub "${job_name_sums}_${job_idx}"
    fi
done

echo "STARTING Parallel Average in Iteration Number: ${iteration}"
################################################################################
#                         PARALLEL AVERAGING PROGRESS                          #
################################################################################

num_complete_a=$(find "${ref_dir}" -name "${ref_a_base}_[0-9]*.em" |\
    wc -l)

num_complete_b=$(find "${ref_dir}" -name "${ref_b_base}_[0-9]*.em" |\
    wc -l)

num_complete_prev_a=0
num_complete_prev_b=0
unchanged_count_a=0
unchanged_count_b=0

while [[ ${num_complete_a} -lt ${num_avg_batch} && \
    ${num_complete_b} -lt ${num_avg_batch} ]]
do
    num_complete_a=$(find "${ref_dir}" -name "${ref_a_base}_*.em" |\
        wc -l)

    num_complete_a=$(find "${ref_dir}" -name "${ref_a_base}_*.em" |\
        wc -l)

    if [[ ${num_complete_a} -eq ${num_complete_prev_a} ]]
    then
        unchanged_count_a=$((unchanged_count_a + 1))
    else
        unchanged_count_a=0
    fi

    num_complete_prev_a=${num_complete_a}

    if [[ ${num_complete_b} -eq ${num_complete_prev_b} ]]
    then
        unchanged_count_b=$((unchanged_count_b + 1))
    else
        unchanged_count_b=0
    fi

    num_complete_prev_b=${num_complete_b}

    if [[ ${num_complete_a} -gt 0 && ${unchanged_count_a} -gt 120 ]]
    then
        echo "Parallel averaging has seemed to stall"
        echo "Please check error logs and resubmit the job if neeeded."
        exit 1
    fi

    if [[ -f "error_${job_name_sums}_${iteration}_1" ]]
    then
        echo -e "\nERROR Update: Averaging iteration ${iteration}\n"
        tail "error_${job_name_sums}_${iteration}"_*
    fi

    if [[ -f "log_${job_name_sums}_${iteration}_1" ]]
    then
        echo -e "\nLOG Update: Averaging iteration ${iteration}\n"
        tail "log_${job_name_sums}_${iteration}"_*
    fi

    sleep 60s
done

################################################################################
#                         PARALLEL AVERAGING CLEAN UP                          #
################################################################################

if [[ ! -d b_factor_${iteration} ]]
then
    mkdir b_factor_${iteration}
fi

if [[ -e "${job_name_sums}_1" ]]
then
    mv -f "${job_name_sums}"_* b_factor_${iteration}/.
fi

if [[ -e "log_${job_name_sums}_1" ]]
then
    mv -f "log_${job_name_sums}"_* b_factor_${iteration}/.
fi

if [[ -e "error_${job_name_sums}_1" ]]
then
    mv -f "error_${job_name_sums}"_* b_factor_${iteration}/.
fi

echo "FINISHED Parallel Average in Iteration Number: ${iteration}"

################################################################################
#                                FINAL AVERAGE                                 #
################################################################################

job_name_avg="${job_name}_b_factor_avg_${iteration}"

cat > "${job_name_avg}" <<-AVGJOB
#!/bin/bash
set +o noclobber
set -e

ldpath="/public/matlab/jbriggs/runtime/glnxa64"
ldpath="\${ldpath}:/public/matlab/jbriggs/bin/glnxa64"
ldpath="\${ldpath}:/public/matlab/jbriggs/sys/os/glnxa64"
ldpath="\${ldpath}:/public/matlab/jbriggs/sys/opengl/lib/glnxa64"
export LD_LIBRARY_PATH="\${ldpath}"

mcr_cache_dir="${mcr_cache_dir}/${job_name_avg}"

if [[ ! -d "\${mcr_cache_dir}" ]]
then
    mkdir -p "\${mcr_cache_dir}"
else
    rm -rf "\${mcr_cache_dir}"
    mkdir -p "\${mcr_cache_dir}"
fi

export MCR_CACHE_ROOT="\${mcr_cache_dir}"

"${avg_exec}" \\
    all_motl_fn_prefix \\
    "${scratch_dir}/${all_motl_a_fn_prefix}" \\
    ref_fn_prefix \\
    "${scratch_dir}/${ref_a_fn_prefix}" \\
    weight_sum_fn_prefix \\
    "${scratch_dir}/${weight_sum_a_fn_prefix}" \\
    iteration \\
    "${iteration}" \\
    iclass \\
    "${iclass}" \\
    num_avg_batch \\
    "${num_avg_batch}"

"${avg_exec}" \\
    all_motl_fn_prefix \\
    "${scratch_dir}/${all_motl_b_fn_prefix}" \\
    ref_fn_prefix \\
    "${scratch_dir}/${ref_b_fn_prefix}" \\
    weight_sum_fn_prefix \\
    "${scratch_dir}/${weight_sum_b_fn_prefix}" \\
    iteration \\
    "${iteration}" \\
    iclass \\
    "${iclass}" \\
    num_avg_batch \\
    "${num_avg_batch}"

rm -rf "\${mcr_cache_dir}"
AVGJOB

chmod u+x "${job_name_avg}"

"./${job_name_avg}" 2> "error_${job_name_avg}" |\
    tee "log_${job_name_avg}"

################################################################################
#                            FINAL AVERAGE CLEAN UP                            #
################################################################################

if [[ -e "${job_name_avg}" ]]
then
    mv "${job_name_avg}" b_factor_${iteration}/.
fi

if [[ -e "log_${job_name_avg}" ]]
then
    mv "log_${job_name_avg}" b_factor_${iteration}/.
fi

if [[ -e "error_${job_name_avg}" ]]
then
    mv "error_${job_name_avg}" b_factor_${iteration}/.
fi

find "${ref_dir}" -name "${ref_a_base}_[0-9]*.em" -delete
find "${ref_dir}" -name "${ref_b_base}_[0-9]*.em" -delete
find "${weight_sum_dir}" -name "${weight_sum_a_base}_[0-9]*.em" -delete
find "${weight_sum_dir}" -name "${weight_sum_b_base}_[0-9]*.em" -delete

echo "FINISHED Final Average in Iteration Number: ${iteration}"
echo "AVERAGE DONE IN ITERATION NUMBER ${iteration}"

################################################################################
#                              MASK CORRECTED FSC                              #
################################################################################

mcr_cache_dir="${mcr_cache_dir}/maskcorrected_FSC"

if [[ ! -d "${mcr_cache_dir}" ]]
then
    mkdir -p "${mcr_cache_dir}"
else
    rm -rf "${mcr_cache_dir}"
    mkdir -p "${mcr_cache_dir}"
fi

ldpath="/public/matlab/jbriggs/runtime/glnxa64"
ldpath="${ldpath}:/public/matlab/jbriggs/bin/glnxa64"
ldpath="${ldpath}:/public/matlab/jbriggs/sys/os/glnxa64"
ldpath="${ldpath}:/public/matlab/jbriggs/sys/opengl/lib/glnxa64"
export LD_LIBRARY_PATH="${ldpath}"

export MCR_CACHE_ROOT="${mcr_cache_dir}"

"${fsc_exec}" \
    ref_a_fn_prefix \
    "${scratch_dir}/${ref_a_fn_prefix}" \
    ref_b_fn_prefix \
    "${scratch_dir}/${ref_b_fn_prefix}" \
    motl_a_fn_prefix \
    "${scratch_dir}/${motl_a_fn_prefix}" \
    motl_b_fn_prefix \
    "${scratch_dir}/${motl_b_fn_prefix}" \
    iteration \
    "${iteration}" \
    fsc_mask_fn \
    "${scratch_dir}/${fsc_mask_fn}" \
    output_fn_prefix \
    "${scratch_dir}/${ref_fn_prefix}" \
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

rm -rf "${mcr_cache_dir}"

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
printf "| %-25s | %25s |\n" "mcr_cache_dir" "${mcr_cache_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "exec_dir" "${exec_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "sum_exec" "${sum_exec}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "fsc_exec" "${fsc_exec}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "avg_exec" "${avg_exec}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "mem_free" "${mem_free}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "mem_max" "${mem_max}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "job_name" "${job_name}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "array_max" "${array_max}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "max_jobs" "${max_jobs}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "run_local" "${run_local}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "iteration" "${iteration}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "num_avg_batch" "${num_avg_batch}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "num_avg_batch" "${num_avg_batch}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "all_motl_fn" \
    "${all_motl_fn_prefix}_${iteration}.em" >> subTOM_protocol.md

printf "| %-25s | %25s |\n" "ref_fn" "${ref_fn_prefix}_${iteration}.em" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "ptcl_fn_prefix" "${ptcl_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "weight_fn_prefix" "${weight_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "weight_sum_fn_prefix" "${weight_sum_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "tomo_row" "${tomo_row}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "iclass" "${iclass}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "ref_a_fn" "${ref_a_fn_prefix}_${iteration}.em" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "ref_b_fn" "${ref_b_fn_prefix}_${iteration}.em" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "fsc_mask_fn" "${fsc_mask_fn}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "filter_a_fn" "${filter_a_fn}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "filter_b_fn" "${filter_b_fn}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "pixelsize" "${pixelsize}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "nfold" "${nfold}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "rand_threshold" "${rand_threshold}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "plot_fsc" "${plot_fsc}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "do_sharpen" "${do_sharpen}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "b_factor" "${b_factor}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "box_gaussian" "${box_gaussian}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "filter_mode" "${filter_mode}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "filter_threshold" "${filter_threshold}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "plot_sharpen" "${plot_sharpen}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n\n" "do_reweight" "${do_reweight}" >>\
    subTOM_protocol.md
