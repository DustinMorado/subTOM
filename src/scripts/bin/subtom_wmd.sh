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
# This subtomogram averaging script uses nine MATLAB compiled scripts below:
# - subtom_cluster
# - subtom_eigenvolumes_wmd
# - subtom_join_coeffs
# - subtom_join_dmatrix
# - subtom_parallel_coeffs
# - subtom_parallel_prealign
# - subtom_parallel_sums_cls
# - subtom_parallel_dmatrix
# - subtom_weighted_average_cls
# DRM 05-2019
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
set +o noclobber # Turn off preventing BASH overwriting files
unset ml
unset module

source "${1}"

# Check number of CC-Matrix prealign jobs
if [[ "${num_dmatrix_prealign_batch}" -gt "${max_jobs}" ]]
then
    echo " TOO MANY CC-MATRIX PREALIGNMENT JOBS!!!!!  I QUIT!!!"
    exit 1
fi

# Check number of D-Matrix jobs
if [[ "${num_dmatrix_batch}" -gt "${max_jobs}" ]]
then
    echo " TOO MANY D-MATRIX JOBS!!!!!  I QUIT!!!"
    exit 1
fi

# Check number of Eigencoefficient prealign jobs
if [[ "${num_coeff_prealign_batch}" -gt "${max_jobs}" ]]
then
    echo " TOO MANY EIGENCOEFFICIENT PREALIGNMENT JOBS!!!!!  I QUIT!!!"
    exit 1
fi

# Check number of Eigencoefficient jobs
if [[ "${num_coeff_batch}" -gt "${max_jobs}" ]]
then
    echo " TOO MANY EIGENCOEFFICIENT JOBS!!!!!  I QUIT!!!"
    exit 1
fi

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

dmatrix_dir="${scratch_dir}/$(dirname "${dmatrix_fn_prefix}")"
dmatrix_base="$(basename "${dmatrix_fn_prefix}")"

if [[ ! -d "${dmatrix_dir}" ]]
then
    mkdir -p "${dmatrix_dir}"
fi

eig_val_dir="${scratch_dir}/$(dirname "${eig_val_fn_prefix}")"
eig_val_base="$(basename "${eig_val_fn_prefix}")"

if [[ ! -d "${eig_val_dir}" ]]
then
    mkdir -p "${eig_val_dir}"
fi

eig_vol_dir="${scratch_dir}/$(dirname "${eig_vol_fn_prefix}")"
eig_vol_base="$(basename "${eig_vol_fn_prefix}")"

if [[ ! -d "${eig_vol_dir}" ]]
then
    mkdir -p "${eig_vol_dir}"
fi

variance_dir="${scratch_dir}/$(dirname "${variance_fn_prefix}")"
variance_base="$(basename "${variance_fn_prefix}")"

if [[ ! -d "${variance_dir}" ]]
then
    mkdir -p "${variance_dir}"
fi

coeff_dir="${scratch_dir}/$(dirname "${coeff_fn_prefix}")"
coeff_base="$(basename "${coeff_fn_prefix}")"

if [[ ! -d "${coeff_dir}" ]]
then
    mkdir -p "${coeff_dir}"
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

if [[ "${mask_fn}" == "none" ]]
then
    mask_fn_="none"
else
    mask_fn_="${scratch_dir}/${mask_fn}"
fi

################################################################################
#                                                                              #
#                                   D-MATRIX                                   #
#                                                                              #
################################################################################
#                           PREALIGNMENT (OPTIONAL)                            #
################################################################################
if [[ "${dmatrix_prealign}" -eq "1" ]]
then

    # Calculate number of job scripts needed
    num_jobs=$(((num_dmatrix_prealign_batch + array_max - 1) / array_max))
    job_name_="${job_name}_dmatrix_parallel_prealign"

    for ((job_idx = 1, array_start = 1; \
          job_idx <= num_jobs; \
          job_idx++, array_start += array_max))
    do
        array_end=$((array_start + array_max - 1))

        if [[ ${array_end} -gt ${num_dmatrix_prealign_batch} ]]
        then
            array_end=${num_dmatrix_prealign_batch}
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

        cat>"${script_fn}"<<-PDPREALIJOB
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

    "${preali_exec}" \\
        all_motl_fn_prefix \\
        "${scratch_dir}/${dmatrix_all_motl_fn_prefix}" \\
        ptcl_fn_prefix \\
        "${scratch_dir}/${ptcl_fn_prefix}" \\
        prealign_fn_prefix \\
        "${scratch_dir}/${ptcl_fn_prefix}_ali" \\
        iteration \\
        "${iteration}" \\
        num_prealign_batch \\
        "${num_dmatrix_prealign_batch}" \\
        process_idx \\
        "\${SGE_TASK_ID}"

###done 2>"${error_fn}" >"${log_fn}"
PDPREALIJOB

    done

    all_motl_fn="${scratch_dir}/${dmatrix_all_motl_fn_prefix}_${iteration}.em"
    num_ptcls=$("${motl_dump_exec}" --size "${all_motl_fn}")
    ptcl_dir="${scratch_dir}/$(dirname "${ptcl_fn_prefix}")"
    ptcl_base="$(basename "${ptcl_fn_prefix}_ali")"
    num_complete=$(find "${ptcl_dir}" -regex \
        ".*/${ptcl_base}_${iteration}_[0-9]+.em" | wc -l)

    if [[ ${num_complete} -lt ${num_ptcls} ]]
    then
        echo -e "\nSTARTING D-Matrix Prealignment - Iteration: ${iteration}\n"

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
        echo -e "\nSKIPPING D-Matrix Prealignment - Iteration: ${iteration}\n"
    fi

################################################################################
#                       PREALIGNMENT (OPTIONAL) PROGRESS                       #
################################################################################
    num_complete_prev=0
    unchanged_count=0

    while [[ ${num_complete} -lt ${num_ptcls} ]]
    do
        num_complete=$(find "${ptcl_dir}" -regex \
            ".*/${ptcl_base}_${iteration}_[0-9]+.em" | wc -l)

        if [[ ${num_complete} -eq ${num_complete_prev} ]]
        then
            unchanged_count=$((unchanged_count + 1))
        else
            unchanged_count=0
        fi

        num_complete_prev=${num_complete}

        if [[ ${num_complete} -gt 0 && ${unchanged_count} -gt 120 ]]
        then
            echo "Parallel D-Matrix prealignment has seemed to stall"
            echo "Please check error logs and resubmit the job if neeeded."
            exit 1
        fi

        if [[ -f "error_${job_name_}_1" ]]
        then
            echo -e "\nERROR Update: Prealignment - Iteration: ${iteration}\n"
            tail "error_${job_name_}"_*
        fi

        if [[ -f "log_${job_name_}_1" ]]
        then
            echo -e "\nLOG Update: Prealignment - Iteration: ${iteration}\n"
            tail "log_${job_name_}"_*
        fi

        echo -e "\nSTATUS Update: Prealignment - Iteration: ${iteration}\n"
        echo -e "\t${num_complete} particles out of ${num_ptcls}\n"
        sleep 60s
    done

################################################################################
#                       PREALIGNMENT (OPTIONAL) CLEAN UP                       #
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

    echo -e "\nFINISHED D-Matrix Prealignment - Iteration: ${iteration}\n"
fi

################################################################################
#                        PARALLEL D-MATRIX CALCULATION                         #
################################################################################
if [[ ${dmatrix_prealign} -eq 1 ]]
then
    ptcl_fn_prefix_="${ptcl_fn_prefix}_ali"
else
    ptcl_fn_prefix_="${ptcl_fn_prefix}"
fi

# Calculate number of job scripts needed
num_jobs=$(((num_dmatrix_batch + array_max - 1) / array_max))
job_name_="${job_name}_parallel_dmatrix"

# Loop to generate parallel alignment scripts
for ((job_idx = 1, array_start = 1; \
      job_idx <= num_jobs; \
      job_idx++, array_start += array_max))
do
    array_end=$((array_start + array_max - 1))

    if [[ ${array_end} -gt ${num_dmatrix_batch} ]]
    then
        array_end=${num_dmatrix_batch}
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

    cat>"${script_fn}"<<-PDJOB
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

    "${par_dmatrix_exec}" \\
        all_motl_fn_prefix \\
        "${scratch_dir}/${dmatrix_all_motl_fn_prefix}" \\
        dmatrix_fn_prefix \\
        "${scratch_dir}/${dmatrix_fn_prefix}" \\
        ptcl_fn_prefix \\
        "${scratch_dir}/${ptcl_fn_prefix_}" \\
        ref_fn_prefix \\
        "${scratch_dir}/${dmatrix_ref_fn_prefix}" \\
        weight_fn_prefix \\
        "${scratch_dir}/${weight_fn_prefix}" \\
        mask_fn \\
        "${mask_fn_}" \\
        high_pass_fp \\
        "${high_pass_fp}" \\
        high_pass_sigma \\
        "${high_pass_sigma}" \\
        low_pass_fp \\
        "${low_pass_fp}" \\
        low_pass_sigma \\
        "${low_pass_sigma}" \\
        nfold \\
        "${nfold}" \\
        iteration \\
        "${iteration}" \\
        tomo_row \\
        "${tomo_row}" \\
        prealigned \\
        "${dmatrix_prealign}" \\
        num_dmatrix_batch \\
        "${num_dmatrix_batch}" \\
        process_idx \\
        "\${SGE_TASK_ID}"

###done 2>"${error_fn}" >"${log_fn}"
PDJOB

done

num_complete=$(find "${dmatrix_dir}" -regex \
    ".*/${dmatrix_base}_${iteration}_[0-9]+.em" | wc -l)

dmatrix_fn="${scratch_dir}/${dmatrix_fn_prefix}_${iteration}.em"

if [[ -f "${dmatrix_fn}" ]]
then
    do_run=0
    num_complete=${num_dmatrix_batch}
elif [[ ${num_complete} -eq ${num_dmatrix_batch} ]]
then
    do_run=0
else
    do_run=1
fi

if [[ ${do_run} -eq 1 ]]
then
    echo -e "\nSTARTING D-Matrix Calculation - Iteration: ${iteration}\n"

    for job_idx in $(seq 1 ${num_jobs})
    do
        script_fn="${job_name_}_${job_idx}"
        chmod u+x "${script_fn}"

        if [[ "${run_local}" -eq "1" ]]
        then
            sed -i 's/\#\#\#//' "${script_fn}"
            "./${script_fn}" &
        else
            qsub "${script_fn}"
        fi
    done
else
    echo -e "\nSKIPPING D-Matrix Calculation - Iteration: ${iteration}\n"
fi

################################################################################
#                          PARALLEL D-MATRIX PROGRESS                          #
################################################################################
num_complete_prev=0
unchanged_count=0

while [[ ${num_complete} -lt ${num_dmatrix_batch} ]]
do
    num_complete=$(find "${dmatrix_dir}" -regex \
        ".*/${dmatrix_base}_${iteration}_[0-9]+.em" | wc -l)

    if [[ ${num_complete} -eq ${num_complete_prev} ]]
    then
        unchanged_count=$((unchanged_count + 1))
    else
        unchanged_count=0
    fi

    num_complete_prev=${num_complete}

    if [[ ${num_complete} -gt 0 && ${unchanged_count} -gt 120 ]]
    then
        echo "Parallel D-Matrix has seemed to stall"
        echo "Please check error logs and resubmit the job if neeeded."
        exit 1
    fi

    if [[ -f "error_${job_name_}_1" ]]
    then
        echo -e "\nERROR Update: D-Matrix - Iteration: ${iteration}\n"
        tail "error_${job_name_}"_*
    fi

    if [[ -f "log_${job_name_}_1" ]]
    then
        echo -e "\nLOG Update: D-Matrix - Iteration: ${iteration}\n"
        tail "log_${job_name_}"_*
    fi

    echo -e "\nSTATUS Update: D-Matrix - Iteration: ${iteration}\n"
    echo -e "\t${num_complete} batches out of ${num_dmatrix_batch}\n"
    sleep 60s
done

################################################################################
#                          PARALLEL D-MATRIX CLEAN UP                          #
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
#                                FINAL D-MATRIX                                #
################################################################################
if [[ ! -f "${dmatrix_fn}" ]]
then
    ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
    export LD_LIBRARY_PATH="${ldpath}"

    job_name_="${job_name}_join_dmatrix"
    mcr_cache_dir_="${mcr_cache_dir}/${job_name_}"

    if [[ -d "${mcr_cache_dir_}" ]]
    then
        rm -rf "${mcr_cache_dir_}"
    fi

    export MCR_CACHE_ROOT="${mcr_cache_dir_}"

    "${dmatrix_exec}" \
        all_motl_fn_prefix \
        "${scratch_dir}/${dmatrix_all_motl_fn_prefix}" \
        dmatrix_fn_prefix \
        "${scratch_dir}/${dmatrix_fn_prefix}" \
        ptcl_fn_prefix \
        "${scratch_dir}/${ptcl_fn_prefix}" \
        mask_fn \
        "${mask_fn_}" \
        iteration \
        "${iteration}" \
        num_dmatrix_batch \
        "${num_dmatrix_batch}"

    rm -rf "${mcr_cache_dir_}"
fi

################################################################################
#                           FINAL D-MATRIX CLEAN UP                            #
################################################################################
if [[ ${skip_local_copy} -ne 1 ]]
then
    local_dmatrix_dir="$(dirname "${local_dir}/${dmatrix_fn_prefix}")"

    if [[ ! -d "${local_dmatrix_dir}" ]]
    then
        mkdir -p "${local_dmatrix_dir}"
    fi

    find "${dmatrix_dir}" -regex \
        ".*/${dmatrix_base}_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_dmatrix_dir}/."

    find "${dmatrix_dir}" -regex \
        ".*/${dmatrix_base}_mean_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_dmatrix_dir}/."

fi

find "${dmatrix_dir}" -regex \
    ".*/${dmatrix_base}_${iteration}_[0-9]+.em" -delete

echo -e "\nFINISHED D-Matrix Calculation - Iteration: ${iteration}\n"

################################################################################
#                                                                              #
#                                 EIGENVOLUMES                                 #
#                                                                              #
################################################################################
eig_val_fn="${scratch_dir}/${eig_val_fn_prefix}_${iteration}.em"
variance_fn="${scratch_dir}/${variance_fn_prefix}_${iteration}.em"
all_done=$(find "${eig_vol_dir}" -regex \
    ".*/${eig_vol_base}_${iteration}_[0-9]+.em" | wc -l)

if [[ ! -f "${eig_val_fn}" ]]
then
    do_run=1
elif [[ ! -f "${variance_fn}" ]]
then
    do_run=1
elif [[ "${all_done}" -ne "${num_svs}" ]]
then
    do_run=1
else
    do_run=0
fi

if [[ "${do_run}" -eq 1 ]]
then
    ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
    export LD_LIBRARY_PATH="${ldpath}"

    job_name_="${job_name}_eigenvolumes_wmd"
    mcr_cache_dir_="${mcr_cache_dir}/${job_name_}"

    if [[ -d "${mcr_cache_dir_}" ]]
    then
        rm -rf "${mcr_cache_dir_}"
    fi

    export MCR_CACHE_ROOT="${mcr_cache_dir_}"

    "${eigvol_exec}" \
        all_motl_fn_prefix \
        "${scratch_dir}/${dmatrix_all_motl_fn_prefix}" \
        ptcl_fn_prefix \
        "${scratch_dir}/${ptcl_fn_prefix}" \
        dmatrix_fn_prefix \
        "${scratch_dir}/${dmatrix_fn_prefix}" \
        eig_val_fn_prefix \
        "${scratch_dir}/${eig_val_fn_prefix}" \
        eig_vol_fn_prefix \
        "${scratch_dir}/${eig_vol_fn_prefix}" \
        variance_fn_prefix \
        "${scratch_dir}/${variance_fn_prefix}" \
        mask_fn \
        "${mask_fn_}" \
        iteration \
        "${iteration}" \
        num_svs \
        "${num_svs}" \
        svds_iterations \
        "${svds_iterations}" \
        svds_tolerance \
        "${svds_tolerance}"

    rm -rf "${mcr_cache_dir_}"
fi

################################################################################
#                             EIGENVOLUME CLEAN UP                             #
################################################################################
if [[ ${skip_local_copy} -ne 1 ]]
then
    local_eig_val_dir="$(dirname "${local_dir}/${eig_val_fn_prefix}")"

    if [[ ! -d "${local_eig_val_dir}" ]]
    then
        mkdir -p "${local_eig_val_dir}"
    fi

    find "${eig_val_dir}" -regex \
        ".*/${eig_val_base}_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_eig_val_dir}/."

    local_eig_vol_dir="$(dirname "${local_dir}/${eig_vol_fn_prefix}")"

    if [[ ! -d "${local_eig_vol_dir}" ]]
    then
        mkdir -p "${local_eig_vol_dir}"
    fi

    find "${eig_vol_dir}" -regex \
        ".*/${eig_vol_base}_${iteration}_[0-9]+.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_eig_vol_dir}/."

    find "${eig_vol_dir}" -regex \
        ".*/${eig_vol_base}_[XYZ]_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_eig_vol_dir}/."


    local_variance_dir="$(dirname "${local_dir}/${variance_fn_prefix}")"

    if [[ ! -d "${local_variance_dir}" ]]
    then
        mkdir -p "${local_variance_dir}"
    fi

    find "${variance_dir}" -regex \
        ".*/${variance_base}_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_variance_dir}/."

fi

################################################################################
#                                                                              #
#                              EIGENCOEFFICIENTS                               #
#                                                                              #
################################################################################
#                           PREALIGNMENT (OPTIONAL)                            #
################################################################################
if [[ "${coeff_prealign}" -eq "1" ]]
then

    # Calculate number of job scripts needed
    num_jobs=$(((num_coeff_prealign_batch + array_max - 1) / array_max))
    job_name_="${job_name}_coeff_parallel_prealign"

    for ((job_idx = 1, array_start = 1; \
          job_idx <= num_jobs; \
          job_idx++, array_start += array_max))
    do
        array_end=$((array_start + array_max - 1))

        if [[ ${array_end} -gt ${num_coeff_prealign_batch} ]]
        then
            array_end=${num_coeff_prealign_batch}
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

        cat>"${script_fn}"<<-PECPREALIJOB
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

    "${preali_exec}" \\
        all_motl_fn_prefix \\
        "${scratch_dir}/${coeff_all_motl_fn_prefix}" \\
        ptcl_fn_prefix \\
        "${scratch_dir}/${ptcl_fn_prefix}" \\
        prealign_fn_prefix \\
        "${scratch_dir}/${ptcl_fn_prefix}_ali" \\
        iteration \\
        "${iteration}" \\
        num_prealign_batch \\
        "${num_coeff_prealign_batch}" \\
        process_idx \\
        "\${SGE_TASK_ID}"

###done 2>"${error_fn}" >"${log_fn}"
PECPREALIJOB

    done

    all_motl_fn="${scratch_dir}/${coeff_all_motl_fn_prefix}_${iteration}.em"
    num_ptcls=$("${motl_dump_exec}" --size "${all_motl_fn}")
    ptcl_dir="${scratch_dir}/$(dirname "${ptcl_fn_prefix}")"
    ptcl_base="$(basename "${ptcl_fn_prefix}_ali")"
    num_complete=$(find "${ptcl_dir}" -regex \
        ".*/${ptcl_base}_${iteration}_[0-9]+.em" | wc -l)

    if [[ "${num_complete}" -lt "${num_ptcls}" ]]
    then
        echo -e "STARTING Eig. Coeff. Prealignment - Iteration: ${iteration}\n"

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
        echo -e "SKIPPING Eig. Coeff. Prealignment - Iteration: ${iteration}\n"
    fi

################################################################################
#                       PREALIGNMENT (OPTIONAL) PROGRESS                       #
################################################################################
    num_complete_prev=0
    unchanged_count=0

    while [[ ${num_complete} -lt ${num_ptcls} ]]
    do
        num_complete=$(find "${ptcl_dir}" -regex \
            ".*/${ptcl_base}_${iteration}_[0-9]+.em" | wc -l)

        if [[ ${num_complete} -eq ${num_complete_prev} ]]
        then
            unchanged_count=$((unchanged_count + 1))
        else
            unchanged_count=0
        fi

        num_complete_prev=${num_complete}

        if [[ ${num_complete} -gt 0 && ${unchanged_count} -gt 120 ]]
        then
            echo "Parallel prealignment has seemed to stall"
            echo "Please check error logs and resubmit the job if neeeded."
            exit 1
        fi

        if [[ -f "error_${job_name_}_1" ]]
        then
            echo -e "\nERROR Update: Prealignment - Iteration: ${iteration}\n"
            tail "error_${job_name_}"_*
        fi

        if [[ -f "log_${job_name_}_1" ]]
        then
            echo -e "\nLOG Update: Prealignment - Iteration: ${iteration}\n"
            tail "log_${job_name_}"_*
        fi

        echo -e "\nSTATUS Update: Prealignment - Iteration: ${iteration}\n"
        echo -e "\t${num_complete} particles out of ${num_ptcls}\n"
        sleep 60s
    done

################################################################################
#                       PREALIGNMENT (OPTIONAL) CLEAN UP                       #
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

    echo -e "FINISHED Eig. Coeff. Prealignment - Iteration: ${iteration}\n"
fi

################################################################################
#                    PARALLEL EIGENCOEFFICIENT CALCULATION                     #
################################################################################
if [[ ${coeff_prealign} -eq 1 ]]
then
    ptcl_fn_prefix_="${ptcl_fn_prefix}_ali"
else
    ptcl_fn_prefix_="${ptcl_fn_prefix}"
fi

# Calculate number of job scripts needed
num_jobs=$(((num_coeff_batch + array_max - 1) / array_max))
job_name_="${job_name}_parallel_coeffs"

# Loop to generate parallel alignment scripts
for ((job_idx = 1, array_start = 1; \
      job_idx <= num_jobs; \
      job_idx++, array_start += array_max))
do
    array_end=$((array_start + array_max - 1))

    if [[ ${array_end} -gt ${num_coeff_batch} ]]
    then
        array_end=${num_coeff_batch}
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

    cat>"${script_fn}"<<-PCJOB
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

    "${par_coeff_exec}" \\
        all_motl_fn_prefix \\
        "${scratch_dir}/${coeff_all_motl_fn_prefix}" \\
        dmatrix_fn_prefix \\
        "${scratch_dir}/${dmatrix_fn_prefix}" \\
        ptcl_fn_prefix \\
        "${scratch_dir}/${ptcl_fn_prefix_}" \\
        ref_fn_prefix \\
        "${scratch_dir}/${dmatrix_ref_fn_prefix}" \\
        coeff_fn_prefix \\
        "${scratch_dir}/${coeff_fn_prefix}" \\
        eig_val_fn_prefix \\
        "${scratch_dir}/${eig_val_fn_prefix}" \\
        eig_vol_fn_prefix \\
        "${scratch_dir}/${eig_vol_fn_prefix}" \\
        weight_fn_prefix \\
        "${scratch_dir}/${weight_fn_prefix}" \\
        mask_fn \\
        "${mask_fn_}" \\
        high_pass_fp \\
        "${high_pass_fp}" \\
        high_pass_sigma \\
        "${high_pass_sigma}" \\
        low_pass_fp \\
        "${low_pass_fp}" \\
        low_pass_sigma \\
        "${low_pass_sigma}" \\
        nfold \\
        "${nfold}" \\
        tomo_row \\
        "${tomo_row}" \\
        iteration \\
        "${iteration}" \\
        prealigned \\
        "${coeff_prealign}" \\
        num_coeff_batch \\
        "${num_coeff_batch}" \\
        process_idx \\
        "\${SGE_TASK_ID}"

###done 2>"${error_fn}" >"${log_fn}"
PCJOB

done

num_complete=$(find "${coeff_dir}" -regex \
    ".*/${coeff_base}_${iteration}_[0-9]+.em" | wc -l)

coeff_fn="${scratch_dir}/${coeff_fn_prefix}_${iteration}.em"

if [[ -f "${coeff_fn}" ]]
then
    do_run=0
    num_complete=${num_coeff_batch}
elif [[ ${num_complete} -eq ${num_coeff_batch} ]]
then
    do_run=0
else
    do_run=1
fi

if [[ "${do_run}" -eq "1" ]]
then
    echo -e "\nSTARTING Coefficient Calculation - Iteration: ${iteration}\n"

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
    echo -e "\nSKIPPING Coefficient Calculation - Iteration: ${iteration}\n"
fi

################################################################################
#                      PARALLEL EIGENCOEFFICIENT PROGRESS                      #
################################################################################
num_complete_prev=0
unchanged_count=0

while [[ ${num_complete} -lt ${num_coeff_batch} ]]
do
    num_complete=$(find "${coeff_dir}" -regex \
        ".*/${coeff_base}_${iteration}_[0-9]+.em" | wc -l)

    if [[ ${num_complete} -eq ${num_complete_prev} ]]
    then
        unchanged_count=$((unchanged_count + 1))
    else
        unchanged_count=0
    fi

    num_complete_prev=${num_complete}

    if [[ ${num_complete} -gt 0 && ${unchanged_count} -gt 120 ]]
    then
        echo "Parallel coefficients has seemed to stall"
        echo "Please check error logs and resubmit the job if neeeded."
        exit 1
    fi

    if [[ -f "error_${job_name_}_1" ]]
    then
        echo -e "\nERROR Update: Coefficients - Iteration: ${iteration}\n"
        tail "error_${job_name_}"_*
    fi

    if [[ -f "log_${job_name_}_1" ]]
    then
        echo -e "\nLOG Update: Coefficients - Iteration: ${iteration}\n"
        tail "log_${job_name_}"_*
    fi

    echo -e "\nSTATUS Update: Coefficients - Iteration: ${iteration}\n"
    echo -e "\t${num_complete} batches out of ${num_coeff_batch}\n"
    sleep 60s
done

################################################################################
#                      PARALLEL EIGENCOEFFICIENT CLEAN UP                      #
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
#                           FINAL EIGENCOEFFICIENT                             #
################################################################################
if [[ ! -f "${coeff_fn}" ]]
then
    ldpath="XXXMCR_DIRXXX/runtime/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/bin/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64"
    ldpath="${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
    export LD_LIBRARY_PATH="${ldpath}"

    job_name_="${job_name}_join_coeffs"
    mcr_cache_dir_="${mcr_cache_dir}/${job_name_}"

    if [[ -d "${mcr_cache_dir_}" ]]
    then
        rm -rf "${mcr_cache_dir_}"
    fi

    export MCR_CACHE_ROOT="${mcr_cache_dir_}"

    "${coeff_exec}" \
        coeff_fn_prefix \
        "${scratch_dir}/${coeff_fn_prefix}" \
        iteration \
        "${iteration}" \
        num_coeff_batch \
        "${num_coeff_batch}"

    rm -rf "${mcr_cache_dir_}"
fi

################################################################################
#                       FINAL EIGENCOEFFICIENT CLEAN UP                        #
################################################################################
if [[ ${skip_local_copy} -ne 1 ]]
then
    local_coeff_all_motl_dir="$(dirname \
        "${local_dir}/${coeff_all_motl_fn_prefix}")"

    if [[ ! -d "${local_coeff_all_motl_dir}" ]]
    then
        mkdir -p "${local_coeff_all_motl_dir}"
    fi

    coeff_all_motl_dir="${scratch_dir}/$(dirname \
        "${coeff_all_motl_fn_prefix}")"

    coeff_all_motl_base="$(basename "${coeff_all_motl_fn_prefix}")"
    find "${coeff_all_motl_dir}" -regex \
        ".*/${coeff_all_motl_base}_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_coeff_all_motl_dir}/."

    local_coeff_dir="$(dirname "${local_dir}/${coeff_fn_prefix}")"

    if [[ ! -d "${local_coeff_dir}" ]]
    then
        mkdir -p "${local_coeff_dir}"
    fi

    find "${coeff_dir}" -regex \
        ".*/${coeff_base}_${iteration}.em" -print0 |\
        xargs -0 -I {} cp -- {} "${local_coeff_dir}/."

fi

find "${coeff_dir}" -regex \
    ".*/${coeff_base}_${iteration}_[0-9]+.em" -delete

echo -e "\nFINISHED Coefficient Calculation - Iteration: ${iteration}\n"

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
        echo -e "\nERROR Update: Averaging - Iteration: ${iteration}\n"
        tail "error_${job_name_}"_*
    fi

    if [[ -f "log_${job_name_}_1" ]]
    then
        echo -e "\nLOG Update: Averaging - Iteration: ${iteration}\n"
        tail "log_${job_name_}"_*
    fi

    echo -e "\nSTATUS Update: Averaging - Iteration: ${iteration}\n"
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
    mcr_cache_dir_="${mcr_cache_dir}/${job_name_}"

    if [[ -d "${mcr_cache_dir_}" ]]
    then
        rm -rf "${mcr_cache_dir_}"
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
        ".*/${ref_base}_[XYZ]_${iteration}.em" -print0 |\
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

printf "# WMD Classification Iteration %d\n" "${iteration}" >>\
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

printf "| %-25s | %25s |\n" "par_coeff_exec" "${par_coeff_exec}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "coeff_exec" "${coeff_exec}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "eigvol_exec" "${eigvol_exec}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "preali_exec" "${preali_exec}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "par_dmatrix_exec" "${par_dmatrix_exec}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "dmatrix_exec" "${dmatrix_exec}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "sum_exec" "${sum_exec}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "avg_exec" "${avg_exec}" >> subTOM_protocol.md
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
printf "| %-25s | %25s |\n" "num_dmatrix_prealign_batch" \
    "${num_dmatrix_prealign_batch}" >> subTOM_protocol.md

printf "| %-25s | %25s |\n" "num_dmatrix_batch" "${num_dmatrix_batch}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "num_coeff_prealign_batch" \
    "${num_coeff_prealign_batch}" >> subTOM_protocol.md

printf "| %-25s | %25s |\n" "num_coeff_batch" "${num_coeff_batch}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "num_avg_batch" "${num_avg_batch}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "high_pass_fp" "${high_pass_fp}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "high_pass_sigma" "${high_pass_sigma}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "low_pass_fp" "${low_pass_fp}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "low_pass_sigma" "${low_pass_sigma}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "nfold" "${nfold}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "tomo_row" "${tomo_row}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "dmatrix_prealign" "${dmatrix_prealign}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "dmatrix_all_motl_fn_prefix" \
    "${dmatrix_all_motl_fn_prefix}" >> subTOM_protocol.md

printf "| %-25s | %25s |\n" "dmatrix_fn_prefix" "${dmatrix_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "ptcl_fn_prefix" "${ptcl_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "dmatrix_ref_fn_prefix" \
    "${dmatrix_ref_fn_prefix}" >> subTOM_protocol.md

printf "| %-25s | %25s |\n" "weight_fn_prefix" "${weight_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "mask_fn" "${mask_fn}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "num_svs" "${num_svs}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "svds_iterations" "${svds_iterations}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "svds_tolerance" "${svds_tolerance}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "eig_val_fn_prefix" "${eig_val_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "eig_vol_fn_prefix" "${eig_vol_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "variance_fn_prefix" "${variance_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "coeff_prealign" "${coeff_prealign}" >>\
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
