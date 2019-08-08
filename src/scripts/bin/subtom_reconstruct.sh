#!/bin/bash
################################################################################
# This is a run script for the CTF correction processing of electron
# cryo-tomograhpy data by means of the program novaCTF.
#
# This script is meant to run on a local workstation but can also submit some of
# the processing to the cluster so that data can be preprocessed in parallel.
# However, note that the read/write density of operations in novaCTF is
# extremely large and therefore care should be taken to not overload systems, or
# be prepared to have a very slow connection to your filesystem..
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

# We use many IMOD commands and get the path from newstack
imod_exe_dir=$(dirname ${newstack_exe})

################################################################################
#                                                                              #
#                                 PREPARATION                                  #
#                                                                              #
################################################################################

################################################################################
#                          WRITE TEMPLATE COM SCRIPTS                          #
################################################################################

if [[ ${do_ctf} -eq 1 ]]
then
    cat<<DEFOCUSCOM>nova_defocus.com
Algorithm defocus
InputProjections XXXTOMOGRAMXXX.st
FULLIMAGE XXXFULLIMAGEXXX
THICKNESS XXXTHICKNESSXXX
TILTFILE XXXTOMOGRAMXXX.tlt
SHIFT 0.0 0.0
CorrectionType ${correction_type}
DefocusFileFormat ${defocus_file_format}
DefocusFile ${defocus_file}
PixelSize ${pixel_size}
DefocusStep ${defocus_step}
CorrectAstigmatism ${correct_astigmatism}
DEFOCUSCOM

    if [[ ! -z ${defocus_shift_file} ]]
    then
        cat<<DEFOCUSCOM>>nova_defocus.com
DefocusShiftFile ${defocus_shift_file}
DEFOCUSCOM
    fi

    cat<<CTFCORRCOM>nova_ctfcorr.com
Algorithm ctfCorrection
InputProjections XXXTOMOGRAMXXX.st
DefocusFile ${defocus_file}_XXXNUMBERXXX
OutputFile XXXTOMOGRAMXXX_ctfcorr.st_XXXNUMBERXXX
TILTFILE XXXTOMOGRAMXXX.tlt
CorrectionType ${correction_type}
DefocusFileFormat ${defocus_file_format}
PixelSize ${pixel_size}
AmplitudeContrast ${amplitude_contrast}
Cs ${cs}
Volt ${voltage}
CorrectAstigmatism ${correct_astigmatism}
CTFCORRCOM

fi

if [[ ${do_radial} -eq 1 ]]
then
    if [[ ${do_ctf} -eq 1 ]]
    then
        cat<<FILTERCOM>nova_filter.com
Algorithm filterProjections
InputProjections XXXTOMOGRAMXXX_flipped.ali_XXXNUMBERXXX
OutputFile XXXTOMOGRAMXXX_filtered.ali_XXXNUMBERXXX
TILTFILE XXXTOMOGRAMXXX.tlt
StackOrientation xz
RADIAL ${radial_cutoff} ${radial_falloff}
FILTERCOM

    else
        cat<<FILTERCOM>nova_filter.com
Algorithm filterProjections
InputProjections XXXTOMOGRAMXXX_flipped.ali
OutputFile XXXTOMOGRAMXXX_filtered.ali
TILTFILE XXXTOMOGRAMXXX.tlt
StackOrientation xz
RADIAL ${radial_cutoff} ${radial_falloff}
FILTERCOM

    fi
fi

if [[ ${do_radial} -eq 1 && ${do_ctf} -eq 1 ]]
then
    cat<<RECCOM>nova_reconstruct.com
Algorithm 3dctf
InputProjections XXXTOMOGRAMXXX_filtered.ali
OutputFile XXXTOMOGRAMXXX.ctf.rec  
TILTFILE XXXTOMOGRAMXXX.tlt
THICKNESS XXXTHICKNESSXXX
FULLIMAGE XXXFULLIMAGEXXX
SHIFT XXXSHIFTXXX
PixelSize ${pixel_size}
DefocusStep ${defocus_step}
Use3DCTF ${do_ctf}
RECCOM

elif [[ ${do_radial} -eq 1 ]]
then
    cat<<RECCOM>nova_reconstruct.com
Algorithm 3dctf
InputProjections XXXTOMOGRAMXXX_filtered.ali
OutputFile XXXTOMOGRAMXXX.nonctf.rec  
TILTFILE XXXTOMOGRAMXXX.tlt
THICKNESS XXXTHICKNESSXXX
FULLIMAGE XXXFULLIMAGEXXX
SHIFT XXXSHIFTXXX
PixelSize ${pixel_size}
DefocusStep ${defocus_step}
Use3DCTF ${do_ctf}
RECCOM

elif [[ ${do_ctf} -eq 1 ]]
then
    cat<<RECCOM>nova_reconstruct.com
Algorithm 3dctf
InputProjections XXXTOMOGRAMXXX_flipped.ali
OutputFile XXXTOMOGRAMXXX.ctf.rec  
TILTFILE XXXTOMOGRAMXXX.tlt
THICKNESS XXXTHICKNESSXXX
FULLIMAGE XXXFULLIMAGEXXX
SHIFT XXXSHIFTXXX
PixelSize ${pixel_size}
DefocusStep ${defocus_step}
Use3DCTF ${do_ctf}
RECCOM

else
    cat<<RECCOM>nova_reconstruct.com
Algorithm 3dctf
InputProjections XXXTOMOGRAMXXX_flipped.ali
OutputFile XXXTOMOGRAMXXX.nonctf.rec  
TILTFILE XXXTOMOGRAMXXX.tlt
THICKNESS XXXTHICKNESSXXX
FULLIMAGE XXXFULLIMAGEXXX
SHIFT XXXSHIFTXXX
PixelSize ${pixel_size}
DefocusStep ${defocus_step}
Use3DCTF ${do_ctf}
RECCOM

fi

if [[ ${do_ctf} -eq 1 ]]
then
    cat <<NEWSTCOM>subtom_newst.com
\$${imod_exe_dir}/newstack -StandardInput
InputFile XXXTOMOGRAMXXX_ctfcorr.st_XXXNUMBERXXX
OutputFile XXXTOMOGRAMXXX_ctfcorr.ali_XXXNUMBERXXX
TransformFile XXXTOMOGRAMXXX.xf
SizeToOutputInXandY XXXFULLIMAGEXXX
BinByFactor 1
AdjustOrigin
NearestNeighbor
NEWSTCOM

else
    cat <<NEWSTCOM>subtom_newst.com
\$${imod_exe_dir}/newstack -StandardInput
InputFile XXXTOMOGRAMXXX.st
OutputFile XXXTOMOGRAMXXX.ali
TransformFile XXXTOMOGRAMXXX.xf
SizeToOutputInXandY XXXFULLIMAGEXXX
BinByFactor 1
AdjustOrigin
NearestNeighbor
NEWSTCOM

fi

if [[ ${do_ctf} -eq 1 ]]
then
    cat <<GOLDERASECOM>subtom_eraser.com
\$${imod_exe_dir}/ccderaser -StandardInput
InputFile XXXTOMOGRAMXXX_ctfcorr.ali_XXXNUMBERXXX
OutputFile XXXTOMOGRAMXXX_erased.ali_XXXNUMBERXXX
ModelFile XXXTOMOGRAMXXX_erase.fid
BetterRadius ${erase_radius}
PolynomialOrder 0
MergePatches
ExcludeAdjacent
CircleObjects /
GOLDERASECOM

else
    cat <<GOLDERASECOM>subtom_eraser.com
\$${imod_exe_dir}/ccderaser -StandardInput
InputFile XXXTOMOGRAMXXX.ali
OutputFile XXXTOMOGRAMXXX_erased.ali
ModelFile XXXTOMOGRAMXXX_erase.fid
BetterRadius ${erase_radius}
PolynomialOrder 0
MergePatches
ExcludeAdjacent
CircleObjects /
GOLDERASECOM

fi

################################################################################
#                             COMPLETE COM SCRIPTS                             #
################################################################################

# We run the defocus part of the procedure first since it is very fast and we
# need it to determine the number of tilt-series we will be generating later.
# Then we can write all of the comfiles to be run in the processing.
for idx in $(seq ${start_idx} ${end_idx})
do
    fmt_idx=$(printf ${idx_fmt} ${idx})
    tomo="${tomo_fmt/XXXIDXXXX/${fmt_idx}}"
    tomo_dir="${scratch_dir}/${tomo_dir_fmt/XXXIDXXXX/${fmt_idx}}"
    tomo_defocus="${defocus_file/XXXIDXXXX/${fmt_idx}}"

    # Make sure the tomogram directory exists.
    if [[ ! -d "${tomo_dir}" ]]
    then
        echo "Directory ${tomo_dir} does not exist SKIPPING!"
        continue
    fi

    # Make sure the tilt.com from eTomo exists.
    if [[ ! -f "${tomo_dir}/tilt.com" ]]
    then
        echo "TILT COM script ${tomo_dir}/tilt.com does not exist SKIPPING!"
        continue
    fi

    # If we are doing CTF correction make sure the defocus file exists.
    if [[ ${do_ctf} -eq 1  && ! -f "${tomo_dir}/${tomo_defocus}" ]]
    then
        echo "Defocus file ${tomo_dir}/${tomo_defocus} does not exist SKIPPING!"
        continue
    fi

    # Get the thickness, shifts and image size from the tilt.com.
    thickness=$(grep THICKNESS "${tomo_dir}/tilt.com" | awk '{ print $2 }')
    shifts="$(grep SHIFT "${tomo_dir}/tilt.com" | awk '{ print $2, $3 }')"
    fullimage="$(grep FULLIMAGE "${tomo_dir}/tilt.com" |\
        awk '{ print $2, $3 }')"

    # If we are doing CTF correction then at this point all we can do is
    # nova_defocus.com script, but if we are just doing WBP then we can do the
    # subtom_newst.com, subtom_eraser.com, and if we are filtering then
    # nova_filter.com as well.
    if [[ ${do_ctf} -eq 1 ]]
    then
        sed \
            -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
            -e "s/XXXTHICKNESSXXX/${thickness}/g" \
            -e "s/XXXFULLIMAGEXXX/${fullimage}/g" \
            -e "s/XXXIDXXXX/${fmt_idx}/g" \
            nova_defocus.com > "${tomo_dir}/nova_defocus.com"
    else
        sed \
            -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
            -e "s/XXXFULLIMAGEXXX/${fullimage}/g" \
            subtom_newst.com > "${tomo_dir}/subtom_newst.com"

        sed \
            -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
            subtom_eraser.com > "${tomo_dir}/subtom_eraser.com"

        if [[ ${do_radial} -eq 1 ]]
        then
            sed \
                -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
                nova_filter.com > "${tomo_dir}/nova_filter.com"

        fi
    fi

    # We can also always do the nova_reconstruct.com, regardless of doing
    # CTF-correction or not.
    sed \
        -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
        -e "s/XXXTHICKNESSXXX/${thickness}/g" \
        -e "s/XXXFULLIMAGEXXX/${fullimage}/g" \
        -e "s/XXXSHIFTXXX/${shifts}/g" \
        nova_reconstruct.com > "${tomo_dir}/nova_reconstruct.com"

    # Run the nova_defocus.com script 
    if [[ ${do_ctf} -eq 1 ]]
    then

        # We have to actually change into the tomogram directory because novaCTF
        # cannot handle paths with spaces nor COM-scripts with quotation marks.
        oldpwd="${PWD}"
        cd "${tomo_dir}"
        ${novactf_exe} -param nova_defocus.com
        cd "${oldpwd}"

        # Find out the number of strips novaCTF will use.
        defocus_dir="$(dirname "${tomo_dir}/${defocus_file}")"
        defocus_base="$(basename "${defocus_file}")"
        defocus_base="${defocus_base/XXXIDXXXX/${fmt_idx}}"
        nsteps=$(find "${defocus_dir}" -name "${defocus_base}_*" | \
            awk -F_ '{ print $NF }' | sort -n | tail -n 1)

        # For each of the strips make a COM script for CTF-correction,
        # filtering, alignment stack generation, and gold-erasing.
        for dstep in $(seq 0 ${nsteps})
        do
            sed \
                -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
                -e "s/XXXNUMBERXXX/${dstep}/g" \
                -e "s/XXXIDXXXX/${fmt_idx}/g" \
                nova_ctfcorr.com > "${tomo_dir}/nova_ctfcorr.com_${dstep}"

            if [[ ${do_radial} -eq 1 ]]
            then
                sed \
                    -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
                    -e "s/XXXNUMBERXXX/${dstep}/g" \
                    nova_filter.com > "${tomo_dir}/nova_filter.com_${dstep}"

            fi

            sed \
                -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
                -e "s/XXXNUMBERXXX/${dstep}/g" \
                -e "s/XXXFULLIMAGEXXX/${fullimage}/g" \
                subtom_newst.com > "${tomo_dir}/subtom_newst.com_${dstep}"

            sed \
                -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
                -e "s/XXXNUMBERXXX/${dstep}/g" \
                subtom_eraser.com > "${tomo_dir}/subtom_eraser.com_${dstep}"

        done
    fi
done

# Clean up the initally written com scripts.
if [[ "${do_ctf}" -eq 1 ]]
then
    rm nova_defocus.com nova_ctfcorr.com
fi

if [[ "${do_radial}" -eq 1 ]]
then
    rm nova_filter.com
fi

rm nova_reconstruct.com subtom_newst.com subtom_eraser.com

################################################################################
#                                                                              #
#                                RECONSTRUCTION                                #
#                                                                              #
################################################################################

# The rest we write into a script so that we can run it locally or submit it to
# the cluster
for idx in $(seq ${start_idx} ${end_idx})
do
    fmt_idx="$(printf ${idx_fmt} ${idx})"
    tomo="${tomo_fmt/XXXIDXXXX/${fmt_idx}}"
    tomo_dir="${scratch_dir}/${tomo_dir_fmt/XXXIDXXXX/${fmt_idx}}"
    tomo_defocus="${defocus_file/XXXIDXXXX/${fmt_idx}}"
    script_fn="subtom_reconstruct_${fmt_idx}.sh"

    # Make sure the tomogram directory exists.
    if [[ ! -d "${tomo_dir}" ]]
    then
        echo "Directory ${tomo_dir} does not exist SKIPPING!"
        continue
    fi

    # Make sure the tilt.com from eTomo exists.
    if [[ ! -f "${tomo_dir}/tilt.com" ]]
    then
        echo "TILT COM script ${tomo_dir}/tilt.com does not exist SKIPPING!"
        continue
    fi

    # If we are doing CTF correction make sure the defocus file exists.
    if [[ ${do_ctf} -eq 1  && ! -f "${tomo_dir}/${tomo_defocus}" ]]
    then
        echo "Defocus file ${tomo_dir}/${tomo_defocus} does not exist SKIPPING!"
        continue
    fi

    if [[ ${do_ctf} -eq 1 ]]
    then

        # Find out the number of strips novaCTF will use.
        defocus_dir="$(dirname "${tomo_dir}/${defocus_file}")"
        defocus_base="$(basename "${defocus_file}")"
        defocus_base="${defocus_base/XXXIDXXXX/${fmt_idx}}"
        nsteps=$(find "${defocus_dir}" -name "${defocus_base}_*" | \
            awk -F_ '{ print $NF }' | sort -n | tail -n 1)

        cat<<RECONSTRUCT>"${script_fn}"
#!/bin/bash
#$ -N subtom_reconstruct_${fmt_idx}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l dedicated=24,mem_free=${mem_free},h_vmem=${mem_max}
#$ -o log_reconstruct_${fmt_idx}
#$ -e error_reconstruct_${fmt_idx}
set +o noclobber
set +o nounset
set -e

echo \${HOSTNAME}

cd ${tomo_dir}

for dstep in \$(seq 0 ${nsteps})
do
    (
        "${novactf_exe}" -param nova_ctfcorr.com_\${dstep}
        "${imod_exe_dir}/submfg" subtom_newst.com_\${dstep}
        "${imod_exe_dir}/submfg" subtom_eraser.com_\${dstep}
        "${imod_exe_dir}/mrctaper" -t 100 "${tomo}_erased.ali_\${dstep}"
        "${imod_exe_dir}/clip" flipyz "${tomo}_erased.ali_\${dstep}" \\
            "${tomo}_flipped.ali_\${dstep}"
RECONSTRUCT

        if [[ ${do_radial} -eq 1 ]]
        then
            cat<<RECONSTRUCT>>"${script_fn}"
        "${novactf_exe}" -param nova_filter.com_\${dstep}
RECONSTRUCT

        fi

        cat<<RECONSTRUCT>>"${script_fn}"
    ) &

    if [[ \$(((dstep + 1) % ${num_threads})) -eq 0 ]]
    then
        wait
    fi
done

wait
"${novactf_exe}" -param nova_reconstruct.com
RECONSTRUCT

        if [[ ${do_rotate_tomo} -eq 1 && ${do_trimvol} -eq 1 ]]
        then
            cat<<RECONSTRUCT>>"${script_fn}"

"${imod_exe_dir}/trimvol" -rx "${tomo}.ctf.rec" "${tomo}.ctf.bin1.rec"
rm "${tomo}.ctf.rec"
RECONSTRUCT

        elif [[ ${do_rotate_tomo} -eq 1 ]]
        then
            cat<<RECONSTRUCT>>"${script_fn}"

"${imod_exe_dir}/clip" rotx "${tomo}.ctf.rec" "${tomo}.ctf.bin1.rec"
rm ${tomo}.ctf.rec
RECONSTRUCT

        else
            cat<<RECONSTRUCT>>"${script_fn}"

mv "${tomo}.ctf.rec" "${tomo}.ctf.bin1.rec"
RECONSTRUCT

        fi

        cat<<RECONSTRUCT>>"${script_fn}"

"${imod_exe_dir}/binvol" -bin 2 -antialias 5 "${tomo}.ctf.bin1.rec" \\
    "${tomo}.ctf.bin2.rec"

"${imod_exe_dir}/binvol" -bin 2 -antialias 5 "${tomo}.ctf.bin2.rec" \\
    "${tomo}.ctf.bin4.rec"

"${imod_exe_dir}/binvol" -bin 2 -antialias 5 "${tomo}.ctf.bin4.rec" \\
    "${tomo}.ctf.bin8.rec"
RECONSTRUCT

    else
        cat<<RECONSTRUCT>"${script_fn}"
#!/bin/bash
#$ -N subtom_reconstruct_${fmt_idx}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l dedicated=24,mem_free=${mem_free},h_vmem=${mem_max}
#$ -o log_reconstruct_${fmt_idx}
#$ -e error_reconstruct_${fmt_idx}
set +o noclobber
set +o nounset
set -e

echo \${HOSTNAME}

cd ${tomo_dir}

"${imod_exe_dir}/submfg" subtom_newst.com
"${imod_exe_dir}/submfg" subtom_eraser.com
"${imod_exe_dir}/mrctaper" -t 100 "${tomo}_erased.ali"
"${imod_exe_dir}/clip" flipyz "${tomo}_erased.ali" "${tomo}_flipped.ali"
RECONSTRUCT

        if [[ ${do_radial} -eq 1 ]]
        then
            cat<<RECONSTRUCT>>"${script_fn}"
"${novactf_exe}" -param nova_filter.com
RECONSTRUCT

        fi

        cat<<RECONSTRUCT>>"${script_fn}"
"${novactf_exe}" -param nova_reconstruct.com
RECONSTRUCT

        if [[ ${do_rotate_tomo} -eq 1 && ${do_trimvol} -eq 1 ]]
        then
            cat<<RECONSTRUCT>>"${script_fn}"
"${imod_exe_dir}/trimvol" -rx "${tomo}.nonctf.rec" "${tomo}.nonctf.bin1.rec"
rm "${tomo}.nonctf.rec"
RECONSTRUCT

        elif [[ ${do_rotate_tomo} -eq 1 ]]
        then
            cat<<RECONSTRUCT>>"${script_fn}"
"${imod_exe_dir}/clip" rotx "${tomo}.nonctf.rec" "${tomo}.nonctf.bin1.rec"
rm "${tomo}.nonctf.rec"
RECONSTRUCT

        else
            cat<<RECONSTRUCT>>"${script_fn}"
mv "${tomo}.nonctf.rec" "${tomo}.nonctf.bin1.rec"
RECONSTRUCT

        fi

        cat<<RECONSTRUCT>>"${script_fn}"
"${imod_exe_dir}/binvol" -bin 2 -antialias 5 "${tomo}.nonctf.bin1.rec" \\
    "${tomo}.nonctf.bin2.rec"

"${imod_exe_dir}/binvol" -bin 2 -antialias 5 "${tomo}.nonctf.bin2.rec" \\
    "${tomo}.nonctf.bin4.rec"

"${imod_exe_dir}/binvol" -bin 2 -antialias 5 "${tomo}.nonctf.bin4.rec" \\
    "${tomo}.nonctf.bin8.rec"
RECONSTRUCT

    fi

################################################################################
#                           RECONSTRUCTION EXECUTION                           #
################################################################################

    chmod u+x "${script_fn}"

    if [[ ${run_local} -eq 1 ]]
    then
        "./${script_fn}" 2> "error_reconstruct_${fmt_idx}" >\
            "log_reconstruct_${fmt_idx}"

        wait
    else
        qsub "${script_fn}"
    fi
done

if [[ ! -f subTOM_protocol.md ]]
then
    touch subTOM_protocol.md
fi

printf "# Reconstruction\n" >> subTOM_protocol.md
printf -- "----------------\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "OPTION" "VALUE" >> subTOM_protocol.md
printf "|:--------------------------" >> subTOM_protocol.md
printf "|:--------------------------|\n" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "scratch_dir" "${scratch_dir}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "novactf_exe" "${novactf_exe}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "newstack_exe" "${newstack_exe}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "exec_dir" "${exec_dir}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "mem_free" "${mem_free}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "mem_max" "${mem_max}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "num_threads" "${num_threads}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "run_local" "${run_local}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "tomo_fmt" "${tomo_fmt}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "tomo_dir_fmt" "${tomo_dir_fmt}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "start_idx" "${start_idx}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "end_idx" "${end_idx}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "idx_fmt" "${idx_fmt}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "do_rotate_tomo" "${do_rotate_tomo}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "do_trimvol" "${do_trimvol}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "do_ctf" "${do_ctf}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "correction_type" "${correction_type}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "defocus_file_format" "${defocus_file_format}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "defocus_file" "${defocus_file}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "pixel_size" "${pixel_size}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "defocus_step" "${defocus_step}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "correct_astigmatism" "${correct_astigmatism}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "defocus_shift_file" "${defocus_shift_file}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "amplitude_contrast" "${amplitude_contrast}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "cs" "${cs}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "voltage" "${voltage}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "do_radial" "${do_radial}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "radial_cutoff" "${radial_cutoff}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "radial_falloff" "${radial_falloff}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n\n" "erase_radius" "${erase_radius}" >>\
    subTOM_protocol.md
