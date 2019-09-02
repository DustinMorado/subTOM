#!/bin/bash
################################################################################
# This script takes an input number of cores, and each core extract one tomogram
# at a time as written in a specified row of the allmotl. Parallelization works
# by writing a start file upon openinig of a tomo, and a completion file. After
# tomogram extraction, it moves on to the next tomogram that hasn't been
# started.
#
# This script uses  MATLAB compiled script below:
# - subtom_extract_subtomograms
# DRM 05-2019
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
unset ml
unset module

source "${1}"

if [[ ! -d "${mcr_cache_dir}" ]]
then
    mkdir -p "${mcr_cache_dir}"
fi

subtomo_dir="${scratch_dir}/$(dirname "${subtomo_fn_prefix}")"

if [[ ! -d "${subtomo_dir}" ]]
then
    mkdir -p "${subtomo_dir}"
fi

stats_dir="${scratch_dir}/$(dirname "${stats_fn_prefix}")"
stats_base="$(basename "${stats_fn_prefix}")"

if [[ ! -d "${stats_dir}" ]]
then
    mkdir -p "${stats_dir}"
fi

num_tomos=$("${motl_dump_exec}" \
    --row ${tomo_row} \
    "${scratch_dir}/${all_motl_fn_prefix}_${iteration}.em" | \
    sort -n | uniq | wc -l)

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
#                            SUBTOMOGRAM EXTRACTION                            #
#                                                                              #
################################################################################
job_name_="${job_name}_extract_subtomograms"
script_fn="${job_name_}"

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

cat>"${script_fn}"<<-JOBDATA
#!/bin/bash
#$ -N "${script_fn}"
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${mem_free},h_vmem=${mem_max}${dedmem}
#$ -e "${error_fn}"
#$ -o "${log_fn}"
#$ -t 1-${num_tomos}
set +C # Turn off prevention of redirection file overwriting
set -e # Turn on exit on error
set -f # Turn off filename expansion (globbing)

echo \${HOSTNAME}

ldpath="XXXMCR_DIRXXX/sys/opengl/lib/glnxa64"
ldpath="XXXMCR_DIRXXX/sys/os/glnxa64:\${ldpath}"
ldpath="XXXMCR_DIRXXX/bin/glnxa64:\${ldpath}"
ldpath="XXXMCR_DIRXXX/runtime/glnxa64:\${ldpath}"
export LD_LIBRARY_PATH="\${ldpath}"

###for SGE_TASK_ID in {1..${num_tomos}}; do
    mcr_cache_dir="${mcr_cache_dir}/${job_name_}_\${SGE_TASK_ID}"

    if [[ -d "\${mcr_cache_dir}" ]]
    then
        rm -rf "\${mcr_cache_dir}"
    fi

    export MCR_CACHE_ROOT="\${mcr_cache_dir}"

    "${extract_exe}" \\
        tomogram_dir \\
        "${tomogram_dir}" \\
        tomo_row \\
        "${tomo_row}" \\
        subtomo_fn_prefix \\
        "${scratch_dir}/${subtomo_fn_prefix}" \\
        subtomo_digits \\
        "${subtomo_digits}" \\
        all_motl_fn_prefix \\
        "${scratch_dir}/${all_motl_fn_prefix}" \\
        stats_fn_prefix \\
        "${scratch_dir}/${stats_fn_prefix}" \\
        iteration \\
        "${iteration}" \\
        box_size \\
        "${box_size}" \\
        process_idx \\
        "\${SGE_TASK_ID}" \\
        reextract \\
        "${reextract}" \\
        preload_tomogram \\
        "${preload_tomogram}" \\
        use_tom_red \\
        "${use_tom_red}" \\
        use_memmap \\
        "${use_memmap}"

###done 2>"${error_fn}" >"${log_fn}"
JOBDATA

echo -e "\nSTARTING - Parallel Volume Extraction - Iteration: ${iteration}\n"
chmod u+x "${script_fn}"

if [[ "${run_local}" -eq 1 ]]
then
    sed -i 's/\#\#\#//' "${script_fn}"
    "./${script_fn}" &
else
    qsub "${script_fn}"
fi

################################################################################
#                       SUBTOMOGRAM EXTRACTION PROGRESS                        #
################################################################################
if [[ "${reextract}" -eq 1 ]]
then
    touch "${stats_dir}/empty_file"
    check_count=$(find "${stats_dir}" \
        -newer "${stats_dir}/empty_file" \
        -and \
        -regex ".*/${stats_base}_[0-9]+.csv" | wc -l)
else
    check_count=$(find "${stats_dir}" -regex \
        ".*/${stats_base}_[0-9]+.csv" | wc -l)
fi

# Wait for jobs to finish
while [ "${check_count}" -lt "${num_tomos}" ]
do
    if [[ "${reextract}" -eq 1 ]]
    then
        check_count=$(find "${stats_dir}" \
            -newer "${stats_dir}/empty_file" \
            -and \
            -regex ".*/${stats_base}_[0-9]+.csv" | wc -l)
    else
        check_count=$(find "${stats_dir}" -regex \
            ".*/${stats_base}_[0-9]+.csv" | wc -l)
    fi

    if [[ -f "${error_fn}" ]]
    then
        echo -e "\nERROR Update: Volume Extraction - Iteration: ${iteration}\n"
        tail "${error_fn}"
    fi

    if [[ -f "${log_fn}" ]]
    then
        echo -e "\nLOG Update: Volume Extraction - Iteration: ${iteration}\n"
        tail "${log_fn}"
    fi

    echo -e "\nSTATUS Update: Volume Extraction - Iteration: ${iteration}\n"
    echo -e "\t${check_count} tomograms extracted out of ${num_tomos}\n"
    sleep 60s
done

################################################################################
#                       SUBTOMOGRAM EXTRACTION CLEAN UP                        #
################################################################################
if [[ ! -d extract_tomo ]]
then
    mkdir extract_tomo
fi

if [[ -f "${script_fn}" ]]
then
    mv "${script_fn}" extract_tomo/.
fi

if [[ -f "${log_fn}" ]]
then
    mv "${log_fn}" extract_tomo/.
fi

if [[ -f "${error_fn}" ]]
then
    mv "${error_fn}" extract_tomo/.
fi

find "${mcr_cache_dir}" -regex ".*/${job_name_}_[0-9]+" -print0 |\
    xargs -0 -I {} rm -rf -- {}

if [[ -f ${stats_dir}/empty_file ]]
then
    rm "${stats_dir}/empty_file"
fi

if [[ ! -f subTOM_protocol.md ]]
then
    touch subTOM_protocol.md
fi

printf "# Extract Subtomograms\n" >> subTOM_protocol.md
printf -- "----------------------\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "OPTION" "VALUE" >> subTOM_protocol.md
printf "|:--------------------------" >> subTOM_protocol.md
printf "|:--------------------------|\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "tomogram_dir" "${tomogram_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "scratch_dir" "${scratch_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "mcr_cache_dir" "${mcr_cache_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "exec_dir" "${exec_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "extract_exe" "${extract_exe}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "motl_dump_exec" "${motl_dump_exec}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "mem_free" "${mem_free}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "mem_max" "${mem_max}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "job_name" "${job_name}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "run_local" "${run_local}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "iteration" "${iteration}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "all_motl_fn_prefix" "${all_motl_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "subtomo_fn_prefix" "${subtomo_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "stats_fn_prefix" "${stats_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "tomo_row" "${tomo_row}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "box_size" "${box_size}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "subtomo_digits" "${subtomo_digits}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "reextract" "${reextract}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "preload_tomogram" "${preload_tomogram}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "use_tom_red" "${use_tom_red}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n\n" "use_memmap" "${use_memmap}" >> subTOM_protocol.md
