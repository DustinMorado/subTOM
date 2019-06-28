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
# - subtom_extract_noise
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

noise_motl_dir="${scratch_dir}/$(dirname "${noise_motl_fn_prefix}")"

if [[ ! -d "${noise_motl_dir}" ]]
then
    mkdir -p "${noise_motl_dir}"
fi

ampspec_dir="${scratch_dir}/$(dirname "${ampspec_fn_prefix}")"
ampspec_base="$(basename "${ampspec_fn_prefix}")"

if [[ ! -d "${ampspec_dir}" ]]
then
    mkdir -p "${ampspec_dir}"
fi

binary_dir="${scratch_dir}/$(dirname "${binary_fn_prefix}")"

if [[ ! -d "${binary_dir}" ]]
then
    mkdir -p "${binary_dir}"
fi

num_tomos=$(${motl_dump_exe} \
    --row ${tomo_row} \
    "${scratch_dir}/${all_motl_fn_prefix}_${iteration}.em" | \
    sort -n | uniq | wc -l)

job_name="${job_name}_extract_noise_array"

if [[ -f "${job_name}" ]]
then
    rm -f "${job_name}"
fi

if [[ -f "error_${job_name}" ]]
then
    rm -f "error_${job_name}"
fi

if [[ -f "log_${job_name}" ]]
then
    rm -f "log_${job_name}"
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
#                          TOMOGRAM NOISE EXTRACTION                           #
#                                                                              #
################################################################################

cat > "${job_name}" <<-JOBDATA
#!/bin/bash
#$ -N "${job_name}"
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${mem_free},h_vmem=${mem_max}${dedmem}
#$ -e "error_${job_name}"
#$ -o "log_${job_name}"
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
    mcr_cache_dir="${mcr_cache_dir}/${job_name}_\${SGE_TASK_ID}"

    if [[ ! -d "\${mcr_cache_dir}" ]]
    then
        mkdir -p "\${mcr_cache_dir}"
    else
        rm -rf "\${mcr_cache_dir}"
        mkdir -p "\${mcr_cache_dir}"
    fi

    export MCR_CACHE_ROOT="\${mcr_cache_dir}"

    "${noise_extract_exe}" \\
        tomogram_dir \\
        "${tomogram_dir}" \\
        scratch_dir \\
        "${scratch_dir}" \\
        tomo_row \\
        "${tomo_row}" \\
        ampspec_fn_prefix \\
        "${ampspec_fn_prefix}" \\
        binary_fn_prefix \\
        "${binary_fn_prefix}" \\
        all_motl_fn_prefix \\
        "${all_motl_fn_prefix}" \\
        noise_motl_fn_prefix \\
        "${noise_motl_fn_prefix}" \\
        iteration \\
        "${iteration}" \\
        boxsize \\
        "${boxsize}" \\
        just_extract \\
        "${just_extract}" \\
        ptcl_overlap_factor \\
        "${ptcl_overlap_factor}" \\
        noise_overlap_factor \\
        "${noise_overlap_factor}" \\
        num_noise \\
        "${num_noise}" \\
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

    rm -rf "\${mcr_cache_dir}"
###done 2> "error_${job_name}" > "log_${job_name}"
JOBDATA

chmod u+x "${job_name}"

if [[ "${run_local}" -eq 1 ]]
then
    sed -i 's/\#\#\#//' "${job_name}"
    "./${job_name}" &
else
    qsub "${job_name}"
fi

echo "Parallel noise extraction submitted"

################################################################################
#                          NOISE EXTRACTION PROGRESS                           #
################################################################################

if [[ "${reextract}" -eq 1 ]]
then
    touch "${ampspec_dir}/empty_file"
    check_count=$(find "${ampspec_dir}" \
        -newer "${ampspec_dir}/empty_file" \
        -and \
        -name "${ampspec_base}_[0-9]*.em" | wc -l)

else
    check_count=$(find "${ampspec_dir}" -name \
        "${ampspec_base}_[0-9]*.em" | wc -l)

fi

# Wait for jobs to finish
while [ "${check_count}" -lt "${num_tomos}" ]
do
    if [[ "${reextract}" -eq 1 ]]
    then
        check_count=$(find "${ampspec_dir}" \
            -newer "${ampspec_dir}/empty_file" \
            -and \
            -name "${ampspec_base}_[0-9]*.em" | wc -l)

    else
        check_count=$(find "${ampspec_dir}" -name \
            "${ampspec_base}_[0-9]*.em" | wc -l)

    fi

    if [[ -f "error_${job_name}" ]]
    then
        echo -e "\nERROR Update: Noise Extraction\n"
        tail "error_${job_name}"
    fi

    if [[ -f "log_${job_name}" ]]
    then
        echo -e "\nLOG Update: Noise Extraction\n"
        tail "log_${job_name}"
    fi

    sleep 60s
done

if [[ -f "${ampspec_dir}/empty_file" ]]
then
    rm "${ampspec_dir}/empty_file"
fi

################################################################################
#                          NOISE EXTRACTION CLEAN UP                           #
################################################################################
if [[ ! -d extract_noise ]]
then
    mkdir extract_noise
fi

if [[ -f "${job_name}" ]]
then
    mv "${job_name}" extract_noise/.
fi

if [[ -f "log_${job_name}" ]]
then
    mv "log_${job_name}" extract_noise/.
fi

if [[ -f "error_${job_name}" ]]
then
    mv "error_${job_name}" extract_noise/.
fi

if [[ ! -f subTOM_protocol.md ]]
then
    touch subTOM_protocol.md
fi

printf "# Extract Noise\n" >> subTOM_protocol.md
printf -- "---------------\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "OPTION" "VALUE" >> subTOM_protocol.md
printf "|:--------------------------" >> subTOM_protocol.md
printf "|--------------------------:|\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "tomogram_dir" "${tomogram_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "scratch_dir" "${scratch_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "mcr_cache_dir" "${mcr_cache_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "exec_dir" "${exec_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "noise_extract_exe" "${noise_extract_exe}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "motl_dump_exe" "${motl_dump_exe}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "mem_free" "${mem_free}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "mem_max" "${mem_max}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "job_name" "${job_name}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "run_local" "${run_local}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "iteration" "${iteration}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "all_motl_fn" \
    "${all_motl_fn_prefix}_${iteration}.em" >> subTOM_protocol.md

printf "| %-25s | %25s |\n" "noise_motl_fn_prefix" "${noise_motl_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "ampspec_fn_prefix" "${ampspec_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "binary_fn_prefix" "${binary_fn_prefix}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "tomo_row" "${tomo_row}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "boxsize" "${boxsize}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "just_extract" "${just_extract}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "ptcl_overlap_factor" "${ptcl_overlap_factor}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "noise_overlap_factor" "${noise_overlap_factor}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "num_noise" "${num_noise}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "reextract" "${reextract}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "preload_tomogram" "${preload_tomogram}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "use_tom_red" "${use_tom_red}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n\n" "use_memmap" "${use_memmap}" >> subTOM_protocol.md
