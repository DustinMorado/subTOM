#!/bin/bash
################################################################################
# This is a run script for preprocessing dose-fractionated electron
# cryo-tomograhpy data and setting up an organized directory system for then
# processing the data using eTomo/IMOD and novaCTF.
#
# This script is meant to run on a local workstation but can also submit some of
# the processing to the cluster so that data can be preprocessed in parallel.
#
# The run script and all of the launch scripts are written in BASH. This is
# mainly because the behaviour of BASH is a bit more predictable. And it is not
# the 1970s any more.
#
# DRM 05-2019
################################################################################
set -e
set -o nounset
unset ml
unset module

source "${1}"

# We use many IMOD commands and get the path from alignframes
imod_exe_dir="$(dirname "${alignframes_exe}")"

# IMOD uses the pixel size in nanometers, so convert Angstrom to nm.
apix_nm=$(awk -vapix="${apix}" 'BEGIN { print apix / 10 }')

# Handle the case when the aligned frames pixel size is different than the input
# frames pixel size.
apix2=$(awk -vapix="${apix}" -vbin="${sum_bin}" 'BEGIN { print apix * bin }')
apix2_nm=$(awk -vapix="${apix2}" 'BEGIN { print apix / 10 }')


# This is the main loop over the indices of tiltseries to process
for idx in $(seq "${start_idx}" "${end_idx}")
do

    # Convert the numeric index to the string formatted version used in names.
    fmt_idx=$(printf "${idx_fmt}" "${idx}")

    # The tiltseries basename is whatever the user has given with XXXIDXXXX
    # swapped out with the string formatted index.
    ts="${ts_fmt/XXXIDXXXX/${fmt_idx}}"

    # Check if the tiltseries base directory exists and if not create it.
    ts_dir="${scratch_dir}/${ts}"
    empty_ts_dir=0
    if [[ ! -d "${ts_dir}" ]]
    then
        mkdir "${ts_dir}"
        empty_ts_dir=1
    fi

    # Check for the raw-sum tiltseries either in .st or .mrc format.
    if [[ -f "${scratch_dir}/${ts}.st" ]]
    then
        ts_fn="${ts}.st"
        mv -n "${scratch_dir}/${ts}.st" "${ts_dir}/."
        empty_ts_dir=0
    elif [[ -f "${ts_dir}/${ts}.st" ]]
    then
        ts_fn="${ts}.st"
    elif [[ -f "${scratch_dir}/${ts}.mrc" ]]
    then
        ts_fn="${ts}.mrc"
        mv -n "${scratch_dir}/${ts}.mrc" "${ts_dir}/."
        empty_ts_dir=0
    elif [[ -f "${ts_dir}/${ts}.mrc" ]]
    then
        ts_fn="${ts}.mrc"
    else
        ts_fn=""
    fi

    # Check for the raw-sum tiltseries either in .st or .mrc format.
    if [[ -f "${scratch_dir}/${ts}.st.mdoc" ]]
    then
        mdoc_fn="${ts}.st.mdoc"
        mv -n "${scratch_dir}/${ts}.st.mdoc" "${ts_dir}/."
        empty_ts_dir=0
    elif [[ -f "${ts_dir}/${ts}.st.mdoc" ]]
    then
        mdoc_fn="${ts}.st.mdoc"
    elif [[ -f "${scratch_dir}/${ts}.mrc.mdoc" ]]
    then
        mdoc_fn="${ts}.mrc.mdoc"
        mv -n "${scratch_dir}/${ts}.mrc.mdoc" "${ts_dir}/."
        empty_ts_dir=0
    elif [[ -f "${ts_dir}/${ts}.mrc.mdoc" ]]
    then
        mdoc_fn="${ts}.mrc.mdoc"
    else
        mdoc_fn=""
    fi

    # Check for the tiltseries log and if it exists move it into the tiltseries
    # directory.
    if [[ -f "${scratch_dir}/${ts}.log" ]]
    then
        mv -n "${scratch_dir}/${ts}.log" "${ts_dir}/."
        empty_ts_dir=0
    fi

    # Check for the raw frames
    num_tif_frames=$(find "${scratch_dir}/${frame_dir}" -name "${ts}_*.tif" | \
        wc -l)

    num_mrc_frames=$(find "${scratch_dir}/${frame_dir}" -name "${ts}_*.mrc" | \
        wc -l)

    if [[ "${num_tif_frames}" -gt 0 ]]
    then
        frame_ext=tif
        num_frames="${num_tif_frames}"
        one_frame=$(find "${scratch_dir}/${frame_dir}" -name "${ts}_*.tif" | \
            head -n 1)

    elif [[ "${num_mrc_frames}" -gt 0 ]]
    then
        frame_ext=mrc
        num_frames="${num_mrc_frames}"
        one_frame=$(find "${scratch_dir}/${frame_dir}" -name "${ts}_*.mrc" | \
            head -n 1)

    else
        frame_ext=""
        num_frames=0
        one_frame=""
    fi

    if [[ "${do_aligned}" -eq 1 || "${do_doseweight}" -eq 1 ]]
    then
        if [[ -z "${mdoc_fn}" && "${num_frames}" -gt 0 ]]
        then
            mdoc_fn="${ts}.st.mdoc"
            touch "${ts_dir}/${mdoc_fn}"
            empty_ts_dir=0
            echo "PixelSpacing = ${apix}" >> "${ts_dir}/${mdoc_fn}"

            if [[ -n "${ts_fn}" ]]
            then
                echo "ImageFile = ${ts_fn}" >> "${ts_dir}/${mdoc_fn}"
                echo "ImageSize = $("${imod_exe_dir}/header" -size \
                    "${ts_dir}/${ts_fn}" | awk '{ print $1, $2 }')" >> \
                    "${ts_dir}/${mdoc_fn}"

            elif [[ -n "${one_frame}" ]]
            then
                echo "ImageFile = ${ts}.st" >> "${ts_dir}/${mdoc_fn}"
                echo "ImageSize = $("${imod_exe_dir}/header" -size \
                    "${one_frame}" | awk '{ print $1, $2 }')" >> \
                    "${ts_dir}/${mdoc_fn}"

            else
                echo "ERROR: No frames or mdoc to run alignframes"
                exit 1
            fi

            echo "DataMode = 1" >> "${ts_dir}/${mdoc_fn}"
            echo -e "\n[T = subTOM: MDOC generated from raw sum]\n" >> \
                "${ts_dir}/${mdoc_fn}"

            echo -e "\n[T =     Tilt axis angle = ${tilt_axis_angle}, \
                binning = 1  spot = -1  camera = -1]\n" >> \
                "${ts_dir}/${mdoc_fn}"

            idx_field=$(echo "${ts}" | awk -F_ '{ print NF }')
            idx_field=$((idx_field + 1))
            angle_field=$((idx_field + 1))
            z_value=0
            num_sub_frames=$("${imod_exe_dir}"/header -size "${one_frame}" |\
                awk '{ print $3 }')

            frame_fns=($(find "${scratch_dir}/${frame_dir}" \
                -name "${ts}_*.${frame_ext}" | xargs -n 1 -I {} \
                basename {} ".${frame_ext}" | sort -t_ -n \
                -k"${idx_field},${idx_field}"))

            for frame_fn in ${frame_fns[@]}
            do
                echo "[ZValue = ${z_value}]" >> "${ts_dir}/${mdoc_fn}"
                tilt_angle=$(echo "${frame_fn}" | awk -F_ \
                    -vangle="${angle_field}" '{ print $angle }')

                echo "TiltAngle = ${tilt_angle}" >> "${ts_dir}/${mdoc_fn}"
                echo "PixelSpacing = ${apix}" >> "${ts_dir}/${mdoc_fn}"
                echo "SubFramePath = ${frame_fn}.${frame_ext}" >>\
                    "${ts_dir}/${mdoc_fn}"

                echo "NumSubFrames = ${num_sub_frames}" >>\
                    "${ts_dir}/${mdoc_fn}"

                echo "FrameDosesAndNumber = 0 ${num_sub_frames}" >>\
                    "${ts_dir}/${mdoc_fn}"

                echo "" >> "${ts_dir}/${mdoc_fn}"
                z_value=$((z_value + 1))
            done
        fi
    fi

    if [[ "${empty_ts_dir}" -eq 1 ]]
    then
        echo "Seems like nothing to do for ${ts}. SKIPPING!"
        rmdir "${ts_dir}"
        continue
    fi

    if [[ "${do_aligned}" -eq 1 && ! -d "${ts_dir}/alignframes" ]]
    then
        mkdir "${ts_dir}/alignframes"
    fi

    if [[ "${do_doseweight}" -eq 1 && ! -d "${ts_dir}/alignframes" ]]
    then
        mkdir "${ts_dir}/alignframes"
    fi

    if [[ "${do_ctffind4}" -eq 1 && ! -d "${ts_dir}/ctffind4" ]]
    then
        mkdir "${ts_dir}/ctffind4"
    fi

    if [[ "${do_gctf}" -eq 1 && ! -d "${ts_dir}/gctf" ]]
    then
        mkdir "${ts_dir}/gctf"
    fi

    if [[ "${do_ctfplotter}" -eq 1 && ! -d "${ts_dir}/ctfplotter" ]]
    then
        mkdir "${ts_dir}/ctfplotter"
    fi

################################################################################
#                                                                              #
#                                PREPROCESSING                                 #
#                                                                              #
################################################################################

    script_fn="subtom_preprocess_${fmt_idx}.sh"
    cat<<PREPROC>"${script_fn}"
#!/bin/bash
#$ -N subtom_preprocess_${fmt_idx}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l dedicated=24,mem_free=${mem_free},h_vmem=${mem_max}
#$ -o log_preprocess_${fmt_idx}
#$ -e error_preprocess_${fmt_idx}
set +o noclobber
set -e
echo \${HOSTNAME}
PREPROC

################################################################################
#                        BEAM-INDUCED MOTION CORRECTION                        #
################################################################################

    aligned_fn="${ts_dir}/${ts}_aligned.st"

    if [[ "${do_aligned}" -eq 1 && ! -f "${aligned_fn}" ]]
    then
        cat<<PREPROC>>"${script_fn}"

"${alignframes_exe}" \\
    -MetadataFile "${ts_dir}/${mdoc_fn}" \\
    -AdjustAndWriteMdoc \\
    -PathToFramesInMdoc "${scratch_dir}/${frame_dir}" \\
    -PairwiseFrames -1 \\
    -AlignAndSumBinning 1,${sum_bin} \\
    -TotalScalingOfData ${scale} \\
    -TestBinnings ${align_bin} \\
    -VaryFilter ${filter_radius2} \\
    -FilterSigma2 ${filter_sigma2} \\
    -ShiftLimit ${shift_limit} \\
    -TransformExtension aligned.xf \\
    -FRCOutputFile "${ts_dir}/alignframes/${ts}_aligned_FRC.txt" \\
    -PlottableShiftFile "${ts_dir}/alignframes/${ts}_aligned_plot.txt" \\
    -DebugOutput 3 \\
    -TruncateAbove ${truncate_above} \\
PREPROC

        if [[ "${do_gain_correction}" -eq 1 ]]
        then
            cat<<PREPROC>>"${script_fn}"
    -GainReferenceFile "${scratch_dir}/${gainref_fn}" \\
    -CameraDefectFile "${scratch_dir}/${defects_fn}" \\
    -RotationAndFlip -1 \\
    -ImagesAreBinned 1.0 \\
PREPROC

        fi

        if [[ "${do_refinement}" -eq 1 ]]
        then
            cat<<PREPROC>>"${script_fn}"
    -RefineAlignment ${refine_iterations} \\
    -RefineRadius2 ${refine_radius2} \\
    -StopIterationsAtShift ${refine_shift_stop} \\
PREPROC

        fi

        if [[ -n "${extra_opts}" ]]
        then
            cat<<PREPROC>>"${script_fn}"
    ${extra_opts} \\
PREPROC

        fi

        cat<<PREPROC>>"${script_fn}"
    -OutputImageFile "${ts_dir}/${ts}_aligned.st" |  \\
tee "${ts_dir}/alignframes/${ts}_aligned.out"

"${imod_exe_dir}/newstack" \\
    -ReorderByTiltAngle 1 \\
    -UseMdocFiles \\
    "${ts_dir}/${ts}_aligned.st" \\
    "${ts_dir}/${ts}_aligned.st"

mv "${scratch_dir}/${frame_dir}/${ts}"*.aligned.xf \
    "${ts_dir}/alignframes/."

rm "${ts_dir}/${ts}_aligned.st~" "${ts_dir}/${ts}_aligned.st.mdoc~"
PREPROC

    fi

################################################################################
#                                DOSE-WEIGHTING                                #
################################################################################

    doseweight_fn="${ts_dir}/${ts}_dose-filt.st"

    if [[ "${do_doseweight}" -eq 1 && ! -f "${doseweight_fn}" ]]
    then
        cat<<PREPROC>>"${script_fn}"

"${alignframes_exe}" \\
    -MetadataFile "${ts_dir}/${mdoc_fn}" \\
    -AdjustAndWriteMdoc \\
    -PathToFramesInMdoc "${scratch_dir}/${frame_dir}" \\
    -PairwiseFrames -1 \\
    -AlignAndSumBinning 1,${sum_bin} \\
    -TotalScalingOfData ${scale} \\
    -TestBinnings ${align_bin} \\
    -VaryFilter ${filter_radius2} \\
    -FilterSigma2 ${filter_sigma2} \\
    -ShiftLimit ${shift_limit} \\
    -TransformExtension dose-filt.xf \\
    -FRCOutputFile "${ts_dir}/alignframes/${ts}_dose-filt_FRC.txt" \\
    -PlottableShiftFile "${ts_dir}/alignframes/${ts}_dose-filt_plot.txt" \\
    -DebugOutput 3 \\
    -TruncateAbove ${truncate_above} \\
    -PixelSize ${apix_nm} \\
    -FixedTotalDose ${dose_per_tilt} \\
PREPROC

        if [[ "${do_gain_correction}" -eq 1 ]]
        then
            cat<<PREPROC>>"${script_fn}"
    -GainReferenceFile "${scratch_dir}/${gainref_fn}" \\
    -CameraDefectFile "${scratch_dir}/${defects_fn}" \\
    -RotationAndFlip -1 \\
    -ImagesAreBinned 1.0 \\
PREPROC

        fi

        if [[ "${do_refinement}" -eq 1 ]]
        then
            cat<<PREPROC>>"${script_fn}"
    -RefineAlignment ${refine_iterations} \\
    -RefineRadius2 ${refine_radius2} \\
    -StopIterationsAtShift ${refine_shift_stop} \\
PREPROC

        fi

        if [[ -n "${extra_opts}" ]]
        then
            cat<<PREPROC>>"${script_fn}"
    ${extra_opts} \\
PREPROC

        fi

        cat<<PREPROC>>"${script_fn}"
    -OutputImageFile "${ts_dir}/${ts}_dose-filt.st" | \\
tee "${ts_dir}/alignframes/${ts}_dose-filt.out"

"${imod_exe_dir}/newstack" \\
    -ReorderByTiltAngle 1 \\
    -UseMdocFiles \\
    "${ts_dir}/${ts}_dose-filt.st" \\
    "${ts_dir}/${ts}_dose-filt.st"

mv "${scratch_dir}/${frame_dir}/${ts}"*.dose-filt.xf \
    "${ts_dir}/alignframes/."

rm "${ts_dir}/${ts}_dose-filt.st~" "${ts_dir}/${ts}_dose-filt.st.mdoc~"
PREPROC

    fi

################################################################################
#                          CTF ESTIMATION - CTFFIND4                           #
################################################################################

    if [[ "${do_ctffind4}" -eq 1 && \
        ! -f "${ts_dir}/ctffind4/${ts}_output.ctf" ]]
    then
        cat<<PREPROC>>"${script_fn}"

if [[ ! -f "${ts_dir}/${ts}_aligned.mrc" ]]
then
    ln -sv "${ts_dir}/${ts}_aligned.st" "${ts_dir}/${ts}_aligned.mrc"
fi

"${ctffind_exe}"<<CTFFINDCARD
${ts_dir}/${ts}_aligned.mrc
no
${ts_dir}/ctffind4/${ts}_output.ctf
${apix2}
${voltage_kev}
${cs}
${ac}
${tile_size}
${min_res}
${max_res}
${min_def}
${max_def}
${def_step}
no
no
yes
${astigmatism}
no
yes
no
no
1
CTFFINDCARD

nz="\$(${imod_exe_dir}/header \\
    -size "${ts_dir}/${ts}_aligned.mrc" | awk '{print \$3}')"

mz="\$((nz / 2 + 1))"
def_avg="\$(grep "^\${mz}" "${ts_dir}/ctffind4/${ts}_output.txt" | \\
   awk '{ printf("%d", (\$2 + \$3) / 2) }')"

def_lo="\$((def_avg - 5000))"
def_hi="\$((def_avg + 5000))"

"${ctffind_exe}"<<CTFFINDCARD
${ts_dir}/${ts}_aligned.mrc
no
${ts_dir}/ctffind4/${ts}_output.ctf
${apix2}
${voltage_kev}
${cs}
${ac}
${tile_size}
${min_res}
${max_res}
\${def_lo}
\${def_hi}
100.0
no
yes
yes
${astigmatism}
no
yes
no
no
1
CTFFINDCARD

rm "${ts}/${ts}_aligned.mrc"
PREPROC

    fi

################################################################################
#                            CTF ESTIMATION - GCTF                             #
################################################################################

    if [[ "${do_gctf}" -eq 1 && ! -f "${ts_dir}/gctf/${ts}_output.ctf" ]]
    then
        cat<<PREPROC>>"${script_fn}"

newstack \\
    -NumberedFromOne \\
    -SplitStartingNumber 1 \\
    "${ts_dir}/${ts}_aligned.st" \\
    "${ts_dir}/gctf/${ts}_aligned"

num_tilts="\$(ls "${ts_dir}/gctf/${ts}"_aligned.[0-9]* | wc -l)"
echo "\${num_tilts}" > "${ts_dir}/gctf/${ts}_output_filein.txt"

for tilt_idx in \$(seq 1 "\${num_tilts}")
do
    if [[ "\${num_tilts}" -le 10 ]]
    then
        fmt_tilt_idx="\${tilt_idx}"
    elif [[ "\${num_tilts}" -le 100 ]]
    then
        fmt_tilt_idx="\$(printf "%02d" "\${tilt_idx}")"
    else
        fmt_tilt_idx="\$(printf "%03d" "\${tilt_idx}")"
    fi

    mv "${ts_dir}/gctf/${ts}_aligned.\${fmt_tilt_idx}" \\
        "${ts_dir}/gctf/${ts}_aligned_\${fmt_tilt_idx}.mrc"

    echo "${ts_dir}/gctf/${ts}_aligned_\${fmt_tilt_idx}.ctf" >> \\
        "${ts_dir}/gctf/${ts}_output_filein.txt"

    echo 0 >> "${ts_dir}/gctf/${ts}_output_filein.txt"
done

"${gctf_exe}" \\
    --apix ${apix2} \\
    --ac ${ac} \\
    --kV ${voltage_kev} \\
    --defH ${max_def} \\
    --defS ${def_step} \\
    --astm ${astigmatism} \\
    --resL ${min_res} \\
    --resH ${max_res} \\
    --boxsize ${tile_size} \\
    --do_EPA \\
    ${ts_dir}/gctf/${ts}_aligned_*.mrc

newstack -filein "${ts_dir}/gctf/${ts}_output_filein.txt" \\
    "${ts_dir}/gctf/${ts}_output.ctf"

rm "${ts_dir}/gctf/${ts}_output_filein.txt"
cat "${ts_dir}/gctf/${ts}"_aligned_*_EPA.log > \\
    "${ts_dir}/gctf/${ts}_aligned_EPA.log"

rm "${ts_dir}/gctf/${ts}"_aligned_*_EPA.log
cat "${ts_dir}/gctf/${ts}"_aligned_*_gctf.log > \\
    "${ts_dir}/gctf/${ts}_aligned_gctf.log"

rm "${ts_dir}/gctf/${ts}"_aligned_*_gctf.log
rm "${ts_dir}/gctf/${ts}"_aligned_*.ctf
rm "${ts_dir}/gctf/${ts}"_aligned_*.mrc
mv micrographs_all_gctf.star "${ts_dir}/gctf/${ts}_output.star"
PREPROC

    fi

################################################################################
#                         CTF ESTIMATION - CTFPLOTTER                          #
################################################################################

    if [[ "${do_ctfplotter}" -eq 1 && \
        ! -f "${ts_dir}/ctfplotter/${ts}_output.txt" ]]
    then

        # Convert the low resolution cutoff into absolute spatial frequency.
        asf_res_lo="$(awk -vrl="${min_res_ctfplotter}" -vpx="${apix2}" \
            'BEGIN { printf("%f", px/rl) }')"

        # Convert the high resolution cutoff into absolute spatial frequency.
        asf_res_hi="$(awk -vrh="${max_res_ctfplotter}" -vpx="${apix2}" \
            'BEGIN { printf("%f", px/rh) }')"

        # Get the approximate defocus from the mdoc file.
        expected_defocus="$(grep TargetDefocus "${ts_dir}/${mdoc_fn}" | \
            head -n 1 | awk '{ printf("%f", $3 * -1000) }')"

        # Handle the case when we don't have the TargetDefocus in the mdoc, as
        # in the case when we make it from scratch.
        if [[ -z "${expected_defocus}" ]]
        then
            expected_defocus=3000
        fi

        # CTFPLOTTER requires the voltage to be an integer.
        int_volt="$(printf "%.0f" "${voltage_kev}")"

        cat<<PREPROC>>"${script_fn}"

extracttilts "${ts_dir}/${ts}_aligned.st" \\
    "${ts_dir}/ctfplotter/${ts}_aligned.rawtlt"

ctfplotter \\
    -InputStack "${ts_dir}/${ts}_aligned.st" \\
    -AngleFile "${ts_dir}/ctfplotter/${ts}_aligned.rawtlt" \\
    -AxisAngle ${tilt_axis_angle} \\
    -DefocusFile "${ts_dir}/ctfplotter/${ts}_output.txt" \\
    -PixelSize ${apix2_nm} \\
    -Voltage ${int_volt} \\
    -SphericalAberration ${cs} \\
    -AmplitudeContrast ${ac} \\
    -ExpectedDefocus ${expected_defocus} \\
    -AutoFitRangeAndStep 0,0 \\
    -FrequencyRangeToFit ${asf_res_lo},${asf_res_hi} \\
    -VaryExponentInFit \\
    -BaselineFittingOrder 4 \\
    -TileSize ${tile_size} \\
    -FindAstigPhaseCuton 1,0,0 \\
    -SaveAndExit
PREPROC

    fi

################################################################################
#                             PREPROCESS EXECUTION                             #
################################################################################

    chmod u+x "${script_fn}"

    if [[ "${run_local}" -eq 1 ]]
    then
        "./${script_fn}" 2> "error_preprocess_${fmt_idx}" >\
            "log_preprocess_${fmt_idx}"
    else
        qsub "${script_fn}"
    fi
done

if [[ ! -f subTOM_protocol.md ]]
then
    touch subTOM_protocol.md
fi

printf "# Preprocessing\n" >> subTOM_protocol.md
printf -- "---------------\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "OPTION" "VALUE" >> subTOM_protocol.md
printf "|:--------------------------" >> subTOM_protocol.md
printf "|:--------------------------|\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "scratch_dir" "${scratch_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "frame_dir" "${frame_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "alignframes_exe" "${alignframes_exe}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "ctffind_exe" "${ctffind_exe}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "gctf_exe" "${gctf_exe}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "exec_dir" "${exec_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "mem_free" "${mem_free}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "mem_max" "${mem_max}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "run_local" "${run_local}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "ts_fmt" "${ts_fmt}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "start_idx" "${start_idx}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "end_idx" "${end_idx}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "idx_fmt" "${idx_fmt}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "do_aligned" "${do_aligned}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "do_doseweight" "${do_doseweight}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "do_gain_correction" "${do_gain_correction}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "gainref_fn" "${gainref_fn}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "defects_fn" "${defects_fn}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "align_bin" "${align_bin}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "sum_bin" "${sum_bin}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "scale" "${scale}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "filter_radius2" "${filter_radius2}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "filter_sigma2" "${filter_sigma2}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "shift_limit" "${shift_limit}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "do_refinement" "${do_refinement}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "refine_iterations" "${refine_iterations}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "refine_radius2" "${refine_radius2}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "refine_shift_stop" "${refine_shift_stop}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "truncate_above" "${truncate_above}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "extra_opts" "${extra_opts}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "apix" "${apix}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "do_ctffind4" "${do_ctffind4}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "do_gctf" "${do_gctf}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "do_ctfplotter" "${do_ctfplotter}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "voltage_kev" "${voltage_kev}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "cs" "${cs}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "ac" "${ac}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "tile_size" "${tile_size}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "min_res" "${min_res}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "max_res" "${max_res}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "min_res_ctfplotter" "${min_res_ctfplotter}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "max_res_ctfplotter" "${max_res_ctfplotter}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "min_def" "${min_def}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "max_def" "${max_def}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "def_step" "${def_step}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "astigmatism" "${astigmatism}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "tilt_axis_angle" "${tilt_axis_angle}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n\n" "dose_per_tilt" "${dose_per_tilt}" >>\
    subTOM_protocol.md