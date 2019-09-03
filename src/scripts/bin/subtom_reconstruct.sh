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

# Default to 3D-CTF if both 2D and 3D are requested
if [[ ${do_3dctf} -eq 1 && ${do_2dctf} -eq 1 ]]
then
    do_2dctf=0
fi

################################################################################
#                                                                              #
#                                 PREPARATION                                  #
#                                                                              #
################################################################################

################################################################################
#                          WRITE TEMPLATE COM SCRIPTS                          #
################################################################################

if [[ ${do_3dctf} -eq 1 ]]
then
    cat<<DEFOCUSCOM>"${job_name}_nova_defocus.com"
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
        cat<<DEFOCUSCOM>>"${job_name}_nova_defocus.com"
DefocusShiftFile ${defocus_shift_file}
DEFOCUSCOM
    fi

    cat<<CTFCORRCOM>"${job_name}_nova_ctfcorr.com"
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
    if [[ ${do_3dctf} -eq 1 ]]
    then
        cat<<FILTERCOM>"${job_name}_nova_filter.com"
Algorithm filterProjections
InputProjections XXXTOMOGRAMXXX_flipped.ali_XXXNUMBERXXX
OutputFile XXXTOMOGRAMXXX_filtered.ali_XXXNUMBERXXX
TILTFILE XXXTOMOGRAMXXX.tlt
StackOrientation xz
RADIAL ${radial_cutoff} ${radial_falloff}
FILTERCOM

    else
        cat<<FILTERCOM>"${job_name}_nova_filter.com"
Algorithm filterProjections
InputProjections XXXTOMOGRAMXXX_flipped.ali
OutputFile XXXTOMOGRAMXXX_filtered.ali
TILTFILE XXXTOMOGRAMXXX.tlt
StackOrientation xz
RADIAL ${radial_cutoff} ${radial_falloff}
FILTERCOM

    fi
fi

if [[ ${do_radial} -eq 1 && ${do_3dctf} -eq 1 ]]
then
    cat<<RECCOM>"${job_name}_nova_reconstruct.com"
Algorithm 3dctf
InputProjections XXXTOMOGRAMXXX_filtered.ali
OutputFile XXXTOMOGRAMXXX.3dctf.rec  
TILTFILE XXXTOMOGRAMXXX.tlt
THICKNESS XXXTHICKNESSXXX
FULLIMAGE XXXFULLIMAGEXXX
SHIFT XXXSHIFTXXX
PixelSize ${pixel_size}
DefocusStep ${defocus_step}
Use3DCTF ${do_3dctf}
RECCOM

elif [[ ${do_radial} -eq 1 && ${do_2dctf} -eq 1 ]]
then
    cat<<RECCOM>"${job_name}_nova_reconstruct.com"
Algorithm 3dctf
InputProjections XXXTOMOGRAMXXX_filtered.ali
OutputFile XXXTOMOGRAMXXX.2dctf.rec  
TILTFILE XXXTOMOGRAMXXX.tlt
THICKNESS XXXTHICKNESSXXX
FULLIMAGE XXXFULLIMAGEXXX
SHIFT XXXSHIFTXXX
PixelSize ${pixel_size}
DefocusStep ${defocus_step}
Use3DCTF ${do_3dctf}
RECCOM

elif [[ ${do_radial} -eq 1 ]]
then
    cat<<RECCOM>"${job_name}_nova_reconstruct.com"
Algorithm 3dctf
InputProjections XXXTOMOGRAMXXX_filtered.ali
OutputFile XXXTOMOGRAMXXX.nonctf.rec  
TILTFILE XXXTOMOGRAMXXX.tlt
THICKNESS XXXTHICKNESSXXX
FULLIMAGE XXXFULLIMAGEXXX
SHIFT XXXSHIFTXXX
PixelSize ${pixel_size}
DefocusStep ${defocus_step}
Use3DCTF ${do_3dctf}
RECCOM

elif [[ ${do_3dctf} -eq 1 ]]
then
    cat<<RECCOM>"${job_name}_nova_reconstruct.com"
Algorithm 3dctf
InputProjections XXXTOMOGRAMXXX_flipped.ali
OutputFile XXXTOMOGRAMXXX.3dctf.rec  
TILTFILE XXXTOMOGRAMXXX.tlt
THICKNESS XXXTHICKNESSXXX
FULLIMAGE XXXFULLIMAGEXXX
SHIFT XXXSHIFTXXX
PixelSize ${pixel_size}
DefocusStep ${defocus_step}
Use3DCTF ${do_3dctf}
RECCOM

elif [[ ${do_2dctf} -eq 1 ]]
then
    cat<<RECCOM>"${job_name}_nova_reconstruct.com"
Algorithm 3dctf
InputProjections XXXTOMOGRAMXXX_flipped.ali
OutputFile XXXTOMOGRAMXXX.2dctf.rec  
TILTFILE XXXTOMOGRAMXXX.tlt
THICKNESS XXXTHICKNESSXXX
FULLIMAGE XXXFULLIMAGEXXX
SHIFT XXXSHIFTXXX
PixelSize ${pixel_size}
DefocusStep ${defocus_step}
Use3DCTF ${do_3dctf}
RECCOM

else
    cat<<RECCOM>"${job_name}_nova_reconstruct.com"
Algorithm 3dctf
InputProjections XXXTOMOGRAMXXX_flipped.ali
OutputFile XXXTOMOGRAMXXX.nonctf.rec  
TILTFILE XXXTOMOGRAMXXX.tlt
THICKNESS XXXTHICKNESSXXX
FULLIMAGE XXXFULLIMAGEXXX
SHIFT XXXSHIFTXXX
PixelSize ${pixel_size}
DefocusStep ${defocus_step}
Use3DCTF ${do_3dctf}
RECCOM

fi

if [[ ${do_2dctf} -eq 1 ]]
then

    # CTFPHASEFLIP requires the voltage to be an integer.
    int_voltage="$(printf "%.0f" "${voltage}")"

    cat <<PHASEFLIPCOM>"${job_name}_ctfphaseflip.com"
\$${imod_exe_dir}/ctfphaseflip -StandardInput
InputStack XXXTOMOGRAMXXX.st
AngleFile XXXTOMOGRAMXXX.tlt
OutputFileName XXXTOMOGRAMXXX_ctfcorr.st
TransformFile XXXTOMOGRAMXXX.xf
AxisAngle ${tilt_axis_angle}
DefocusFile ${defocus_file}
OffsetInZ ${defocus_shift}
Voltage ${int_voltage}
SphericalAberration ${cs}
DefocusTol ${defocus_tolerance}
PixelSize ${pixel_size}
AmplitudeContrast ${amplitude_contrast}
InterpolationWidth ${interpolation_width}
PHASEFLIPCOM

    if [[ ${use_gpu} -eq 1 ]]
    then
        cat <<PHASEFLIPCOM>>"${job_name}_ctfphaseflip.com"
UseGPU 0
PHASEFLIPCOM

    fi

fi

if [[ ${do_3dctf} -eq 1 ]]
then
    cat <<NEWSTCOM>"${job_name}_newst.com"
\$${imod_exe_dir}/newstack -StandardInput
InputFile XXXTOMOGRAMXXX_ctfcorr.st_XXXNUMBERXXX
OutputFile XXXTOMOGRAMXXX_ctfcorr.ali_XXXNUMBERXXX
TransformFile XXXTOMOGRAMXXX.xf
SizeToOutputInXandY XXXFULLIMAGEXXX
BinByFactor 1
AdjustOrigin
NearestNeighbor
NEWSTCOM

elif [[ ${do_2dctf} -eq 1 ]]
then
    cat <<NEWSTCOM>"${job_name}_newst.com"
\$${imod_exe_dir}/newstack -StandardInput
InputFile XXXTOMOGRAMXXX_ctfcorr.st
OutputFile XXXTOMOGRAMXXX_aligned.ali
TransformFile XXXTOMOGRAMXXX.xf
SizeToOutputInXandY XXXFULLIMAGEXXX
BinByFactor 1
AdjustOrigin
NearestNeighbor
NEWSTCOM

else
    cat <<NEWSTCOM>"${job_name}_newst.com"
\$${imod_exe_dir}/newstack -StandardInput
InputFile XXXTOMOGRAMXXX.st
OutputFile XXXTOMOGRAMXXX_aligned.ali
TransformFile XXXTOMOGRAMXXX.xf
SizeToOutputInXandY XXXFULLIMAGEXXX
BinByFactor 1
AdjustOrigin
NearestNeighbor
NEWSTCOM

fi

if [[ ${do_3dctf} -eq 1 ]]
then
    cat <<GOLDERASECOM>"${job_name}_eraser.com"
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
    cat <<GOLDERASECOM>"${job_name}_eraser.com"
\$${imod_exe_dir}/ccderaser -StandardInput
InputFile XXXTOMOGRAMXXX_aligned.ali
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

# Create a list of indices that have data and are being processed to check
# progress later on.
good_idxs=()

# Create a list of the last files to be written to check progress later on.
check_fns=()

# If we are doing 3D-CTF correction create a list of the number of defocus steps
# that are done in processing
if [[ ${do_3dctf} -eq 1 ]]
then
    nsteps_array=()
fi

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
    if [[ ${do_2dctf} -eq 1  && ! -f "${tomo_dir}/${tomo_defocus}" ]]
    then
        echo "Defocus file ${tomo_dir}/${tomo_defocus} does not exist SKIPPING!"
        continue
    fi

    if [[ ${do_3dctf} -eq 1  && ! -f "${tomo_dir}/${tomo_defocus}" ]]
    then
        echo "Defocus file ${tomo_dir}/${tomo_defocus} does not exist SKIPPING!"
        continue
    fi

    # Add index to list of good indices and find last filename to look for.
    good_idxs[${#good_idxs[*]}]=${idx}

    # Get the thickness, shifts and image size from the tilt.com.
    thickness=$(grep THICKNESS "${tomo_dir}/tilt.com" | awk '{ print $2 }')
    shifts="$(grep SHIFT "${tomo_dir}/tilt.com" | awk '{ print $2, $3 }')"
    fullimage="$(grep FULLIMAGE "${tomo_dir}/tilt.com" |\
        awk '{ print $2, $3 }')"

    # If we are doing 3D-CTF correction then at this point all we can do is
    # ${job_name}_nova_defocus.com script, but if we are just doing 2D-CTF
    # phase-flipping or just WBP then we can do the ${job_name}_newst.com,
    # ${job_name}_eraser.com, and if we are filtering then
    # ${job_name}_nova_filter.com as well.
    if [[ ${do_3dctf} -eq 1 ]]
    then
        sed \
            -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
            -e "s/XXXTHICKNESSXXX/${thickness}/g" \
            -e "s/XXXFULLIMAGEXXX/${fullimage}/g" \
            -e "s/XXXIDXXXX/${fmt_idx}/g" \
            "${job_name}_nova_defocus.com" >\
            "${tomo_dir}/${job_name}_nova_defocus_${fmt_idx}.com"

        check_fns[${#check_fns[*]}]="${tomo_dir}/${tomo}.3dctf.bin8.rec"
    else
        if [[ ${do_2dctf} -eq 1 ]]
        then
            sed \
                -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
                "${job_name}_ctfphaseflip.com" >\
                "${tomo_dir}/${job_name}_ctfphaseflip_${fmt_idx}.com"

            check_fns[${#check_fns[*]}]="${tomo_dir}/${tomo}.2dctf.bin8.rec"
        else
            check_fns[${#check_fns[*]}]="${tomo_dir}/${tomo}.nonctf.bin8.rec"
        fi

        sed \
            -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
            -e "s/XXXFULLIMAGEXXX/${fullimage}/g" \
            "${job_name}_newst.com" >\
            "${tomo_dir}/${job_name}_newst_${fmt_idx}.com"

        sed \
            -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
            "${job_name}_eraser.com" >\
            "${tomo_dir}/${job_name}_eraser_${fmt_idx}.com"

        if [[ ${do_radial} -eq 1 ]]
        then
            sed \
                -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
                "${job_name}_nova_filter.com" >\
                "${tomo_dir}/${job_name}_nova_filter_${fmt_idx}.com"

        fi
    fi

    # We can also always do the nova_reconstruct.com, regardless of doing
    # CTF-correction or not.
    sed \
        -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
        -e "s/XXXTHICKNESSXXX/${thickness}/g" \
        -e "s/XXXFULLIMAGEXXX/${fullimage}/g" \
        -e "s/XXXSHIFTXXX/${shifts}/g" \
        "${job_name}_nova_reconstruct.com" >\
        "${tomo_dir}/${job_name}_nova_reconstruct_${fmt_idx}.com"

    # Run the nova_defocus.com script 
    if [[ ${do_3dctf} -eq 1 ]]
    then

        # We have to actually change into the tomogram directory because novaCTF
        # cannot handle paths with spaces nor COM-scripts with quotation marks.
        oldpwd="${PWD}"
        cd "${tomo_dir}"
        ${novactf_exe} -param "${job_name}_nova_defocus_${fmt_idx}.com"
        cd "${oldpwd}"

        # Find out the number of strips novaCTF will use.
        defocus_dir="$(dirname "${tomo_dir}/${defocus_file}")"
        defocus_base="$(basename "${defocus_file}")"
        defocus_base="${defocus_base/XXXIDXXXX/${fmt_idx}}"
        nsteps=$(find "${defocus_dir}" -name "${defocus_base}_*" | \
            awk -F_ '{ print $NF }' | sort -n | tail -n 1)

        nsteps_array[${#nstep[*]}]=${nsteps}

        # For each of the strips make a COM script for CTF-correction,
        # filtering, alignment stack generation, and gold-erasing.
        for dstep in $(seq 0 ${nsteps})
        do
            sed \
                -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
                -e "s/XXXNUMBERXXX/${dstep}/g" \
                -e "s/XXXIDXXXX/${fmt_idx}/g" \
                "${job_name}_nova_ctfcorr.com" >\
                "${tomo_dir}/${job_name}_nova_ctfcorr_${fmt_idx}.com_${dstep}"

            if [[ ${do_radial} -eq 1 ]]
            then
                sed \
                    -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
                    -e "s/XXXNUMBERXXX/${dstep}/g" \
                    "${job_name}_nova_filter.com" >\
                "${tomo_dir}/${job_name}_nova_filter_${fmt_idx}.com_${dstep}"

            fi

            sed \
                -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
                -e "s/XXXNUMBERXXX/${dstep}/g" \
                -e "s/XXXFULLIMAGEXXX/${fullimage}/g" \
                "${job_name}_newst.com" >\
                "${tomo_dir}/${job_name}_newst_${fmt_idx}.com_${dstep}"

            sed \
                -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
                -e "s/XXXNUMBERXXX/${dstep}/g" \
                "${job_name}_eraser.com" >\
                "${tomo_dir}/${job_name}_eraser_${fmt_idx}.com_${dstep}"

        done
    fi
done

################################################################################
#                                                                              #
#                                RECONSTRUCTION                                #
#                                                                              #
################################################################################
# The rest we write into a script so that we can run it locally or submit it to
# the cluster.
for good_idx_idx in ${!good_idxs[*]}
do
    good_idx=${good_idxs[good_idx_idx]}
    fmt_idx="$(printf ${idx_fmt} ${good_idx})"
    tomo="${tomo_fmt/XXXIDXXXX/${fmt_idx}}"
    tomo_dir="${scratch_dir}/${tomo_dir_fmt/XXXIDXXXX/${fmt_idx}}"
    script_fn="${job_name}_reconstruct_${fmt_idx}.sh"
    error_fn="error_${job_name}_reconstruct_${fmt_idx}"
    log_fn="log_${job_name}_reconstruct_${fmt_idx}"

    if [[ ${do_3dctf} -eq 1 ]]
    then

        # Find out the number of strips novaCTF will use.
        nsteps=${nsteps_array[good_idx_idx]}

        cat<<RECONSTRUCT>"${script_fn}"
#!/bin/bash
#$ -N "${job_name}_reconstruct_${fmt_idx}"
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l dedicated=24,mem_free=${mem_free},h_vmem=${mem_max}
#$ -o "${log_fn}"
#$ -e "${error_fn}"
set +o noclobber
set +o nounset
set -e

echo \${HOSTNAME}

cd "${tomo_dir}"

if [[ -f "${tomo}.3dctf.bin8.rec" ]]
then
    echo "${tomo}.3dctf.bin8.rec already exists. SKIPPING!"
    exit 0
fi

for dstep in \$(seq 0 ${nsteps})
do
    (
        if [[ ! -f "${tomo}_ctfcorr.st_\${dstep}" ]]
        then
            "${novactf_exe}" -param \\
                "${job_name}_nova_ctfcorr_${fmt_idx}.com_\${dstep}"

        else
            echo "${tomo}_ctfcorr.st_\${dstep} already exists. SKIPPING!"
        fi

        if [[ ! -f "${tomo}_ctfcorr.ali_\${dstep}" ]]
        then
            "${imod_exe_dir}/submfg" \\
                "${job_name}_newst_${fmt_idx}.com_\${dstep}"

        else
            echo "${tomo}_ctfcorr.ali_\${dstep} already exists. SKIPPING!"
        fi

        if [[ ! -f "${tomo}_erased.ali_\${dstep}" ]]
        then
            "${imod_exe_dir}/submfg" \\
                "${job_name}_eraser_${fmt_idx}.com_\${dstep}"

            "${imod_exe_dir}/mrctaper" -t 100 "${tomo}_erased.ali_\${dstep}"
        else
            echo "${tomo}_erased.ali_\${dstep} already exists. SKIPPING!"
        fi

        if [[ ! -f "${tomo}_flipped.ali_\${dstep}" ]]
        then
            "${imod_exe_dir}/clip" flipyz "${tomo}_erased.ali_\${dstep}" \\
                "${tomo}_flipped.ali_\${dstep}"

        else
            echo "${tomo}_flipped.ali_\${dstep} already exists. SKIPPING!"
        fi

RECONSTRUCT

        if [[ ${do_radial} -eq 1 ]]
        then
            cat<<RECONSTRUCT>>"${script_fn}"
        if [[ ! -f "${tomo}_filtered.ali_\${dstep}" ]]
        then
            "${novactf_exe}" -param \\
                "${job_name}_nova_filter_${fmt_idx}.com_\${dstep}"

        else
            echo "${tomo}_filtered.ali_\${dstep} already exists. SKIPPING!"
        fi

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

if [[ ! -f "${tomo}.3dctf.rec" && ! -f "${tomo}.3dctf.bin1.rec" ]]
then
    "${novactf_exe}" -param "${job_name}_nova_reconstruct_${fmt_idx}.com"
elif [[ -f "${tomo}.3dctf.rec" ]]
then
    echo "${tomo}.3dctf.rec already exists. SKIPPING!"
else
    echo "${tomo}.3dctf.bin1.rec already exists. SKIPPING!"
fi

RECONSTRUCT

        if [[ ${do_rotate_tomo} -eq 1 && ${do_trimvol} -eq 1 ]]
        then
            cat<<RECONSTRUCT>>"${script_fn}"
if [[ ! -f "${tomo}.3dctf.bin1.rec" ]]
then
    "${imod_exe_dir}/trimvol" -rx "${tomo}.3dctf.rec" "${tomo}.3dctf.bin1.rec"
    rm "${tomo}.3dctf.rec"
else
    echo "${tomo}.3dctf.bin1.rec already exists. SKIPPING!"
fi

RECONSTRUCT

        elif [[ ${do_rotate_tomo} -eq 1 ]]
        then
            cat<<RECONSTRUCT>>"${script_fn}"
if [[ ! -f "${tomo}.3dctf.bin1.rec" ]]
then
    "${imod_exe_dir}/clip" rotx "${tomo}.3dctf.rec" "${tomo}.3dctf.bin1.rec"
    rm ${tomo}.3dctf.rec
else
    echo "${tomo}.3dctf.bin1.rec already exists. SKIPPING!"
fi

RECONSTRUCT

        else
            cat<<RECONSTRUCT>>"${script_fn}"
if [[ ! -f "${tomo}.3dctf.bin1.rec" ]]
then
    mv "${tomo}.3dctf.rec" "${tomo}.3dctf.bin1.rec"
else
    echo "${tomo}.3dctf.bin1.rec already exists. SKIPPING!"
fi

RECONSTRUCT

        fi

        cat<<RECONSTRUCT>>"${script_fn}"
if [[ ! -f "${tomo}.3dctf.bin2.rec" ]]
then
    "${imod_exe_dir}/binvol" -bin 2 -antialias 5 "${tomo}.3dctf.bin1.rec" \\
        "${tomo}.3dctf.bin2.rec"

else
    echo "${tomo}.3dctf.bin2.rec already exists. SKIPPING!"
fi

if [[ ! -f "${tomo}.3dctf.bin4.rec" ]]
then
    "${imod_exe_dir}/binvol" -bin 2 -antialias 5 "${tomo}.3dctf.bin2.rec" \\
        "${tomo}.3dctf.bin4.rec"

else
    echo "${tomo}.3dctf.bin4.rec already exists. SKIPPING!"
fi

if [[ ! -f "${tomo}.3dctf.bin8.rec" ]]
then
    "${imod_exe_dir}/binvol" -bin 2 -antialias 5 "${tomo}.3dctf.bin4.rec" \\
        "${tomo}.3dctf.bin8.rec"

else
    echo "${tomo}.3dctf.bin8.rec already exists. SKIPPING!"
fi

RECONSTRUCT

    else
        cat<<RECONSTRUCT>"${script_fn}"
#!/bin/bash
#$ -N "${job_name}_reconstruct_${fmt_idx}"
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l dedicated=24,mem_free=${mem_free},h_vmem=${mem_max}
#$ -o "${log_fn}"
#$ -e "${error_fn}"
set +o noclobber
set +o nounset
set -e

echo \${HOSTNAME}

cd "${tomo_dir}"

RECONSTRUCT

        if [[ ${do_2dctf} -eq 1 ]]
        then
            cat<<RECONSTRUCT>>"${script_fn}"
if [[ -f "${tomo}.2dctf.bin8.rec" ]]
then
    echo "${tomo}.2dctf.bin8.rec already exists. SKIPPING!"
    exit 0
fi

if [[ ! -f "${tomo}_ctfcorr.st" ]]
then
    "${imod_exe_dir}/submfg" "${job_name}_ctfphaseflip_${fmt_idx}.com"
else
    echo "${tomo}_ctfcorr.st already exists. SKIPPING!"
fi

RECONSTRUCT

        else
            cat<<RECONSTRUCT>>"${script_fn}"
if [[ -f "${tomo}.nonctf.bin8.rec" ]]
then
    echo "${tomo}.nonctf.bin8.rec already exists. SKIPPING!"
    exit 0
fi

RECONSTRUCT
        fi

        cat<<RECONSTRUCT>>"${script_fn}"
if [[ ! -f "${tomo}_aligned.ali" ]]
then
    "${imod_exe_dir}/submfg" "${job_name}_newst_${fmt_idx}.com"
else
    echo "${tomo}_aligned.ali already exists. SKIPPING!"
fi

if [[ ! -f "${tomo}_erased.ali" ]]
then
    "${imod_exe_dir}/submfg" "${job_name}_eraser_${fmt_idx}.com"
    "${imod_exe_dir}/mrctaper" -t 100 "${tomo}_erased.ali"
else
    echo "${tomo}_erased.ali already exists. SKIPPING!"
fi

if [[ ! -f "${tomo}_flipped.ali" ]]
then
    "${imod_exe_dir}/clip" flipyz "${tomo}_erased.ali" "${tomo}_flipped.ali"
else
    echo "${tomo}_flipped.ali already exists. SKIPPING!"
fi

RECONSTRUCT

        if [[ ${do_radial} -eq 1 ]]
        then
            cat<<RECONSTRUCT>>"${script_fn}"
if [[ ! -f "${tomo}_filtered.ali" ]]
then
    "${novactf_exe}" -param "${job_name}_nova_filter_${fmt_idx}.com"
else
    echo "${tomo}_filtered.ali already exists. SKIPPING!"
fi

RECONSTRUCT

        fi

        if [[ ${do_2dctf} -eq 1 ]]
        then
            cat<<RECONSTRUCT>>"${script_fn}"
if [[ ! -f "${tomo}.2dctf.rec" && ! -f "${tomo}.2dctf.bin1.rec ]]
then
    "${novactf_exe}" -param "${job_name}_nova_reconstruct_${fmt_idx}.com"
elif [[ -f "${tomo}.2dctf.rec" ]]
then
    echo "${tomo}.2dctf.rec already exists. SKIPPING!"
else
    echo "${tomo}.2dctf.bin1.rec already exists. SKIPPING!"
fi

RECONSTRUCT

        else
            cat<<RECONSTRUCT>>"${script_fn}"
if [[ ! -f "${tomo}.nonctf.rec" && ! -f "${tomo}.nonctf.bin1.rec" ]]
then
    "${novactf_exe}" -param "${job_name}_nova_reconstruct_${fmt_idx}.com"
elif [[ -f "${tomo}.nonctf.rec" ]]
then
    echo "${tomo}.nonctf.rec already exists. SKIPPING!"
else
    echo "${tomo}.nonctf.bin1.rec already exists. SKIPPING!"
fi

RECONSTRUCT

        fi

        if [[ ${do_rotate_tomo} -eq 1 && ${do_trimvol} -eq 1 ]]
        then
            if [[ ${do_2dctf} -eq 1 ]]
            then
                cat<<RECONSTRUCT>>"${script_fn}"
if [[ ! -f "${tomo}.2dctf.bin1.rec" ]]
then
    "${imod_exe_dir}/trimvol" -rx "${tomo}.2dctf.rec" "${tomo}.2dctf.bin1.rec"
    rm "${tomo}.2dctf.rec"
else
    echo "${tomo}.2dctf.bin1.rec already exists. SKIPPING!"
fi

RECONSTRUCT

            else
                cat<<RECONSTRUCT>>"${script_fn}"
if [[ ! -f "${tomo}.nonctf.bin1.rec" ]]
then
    "${imod_exe_dir}/trimvol" -rx "${tomo}.nonctf.rec" "${tomo}.nonctf.bin1.rec"
    rm "${tomo}.nonctf.rec"
else
    echo "${tomo}.nonctf.bin1.rec already exists. SKIPPING!"
fi

RECONSTRUCT

            fi

        elif [[ ${do_rotate_tomo} -eq 1 && ${do_2dctf} -eq 1 ]]
        then
            cat<<RECONSTRUCT>>"${script_fn}"
if [[ ! -f "${tomo}.2dctf.bin1.rec" ]]
then
    "${imod_exe_dir}/clip" rotx "${tomo}.2dctf.rec" "${tomo}.2dctf.bin1.rec"
    rm "${tomo}.2dctf.rec"
else
    echo "${tomo}.2dctf.bin1.rec already exists. SKIPPING!"
fi

RECONSTRUCT

        elif [[ ${do_rotate_tomo} -eq 1 ]]
        then
            cat<<RECONSTRUCT>>"${script_fn}"
if [[ ! -f "${tomo}.nonctf.bin1.rec" ]]
then
    "${imod_exe_dir}/clip" rotx "${tomo}.nonctf.rec" "${tomo}.nonctf.bin1.rec"
    rm "${tomo}.nonctf.rec"
else
    echo "${tomo}.nonctf.bin1.rec already exists. SKIPPING!"
fi

RECONSTRUCT

        elif [[ ${do_2dctf} -eq 1 ]]
        then
            cat<<RECONSTRUCT>>"${script_fn}"
if [[ ! -f "${tomo}.2dctf.bin1.rec" ]]
then
    mv "${tomo}.2dctf.rec" "${tomo}.2dctf.bin1.rec"
else
    echo "${tomo}.2dctf.bin1.rec already exists. SKIPPING!"
fi

RECONSTRUCT

        else
            cat<<RECONSTRUCT>>"${script_fn}"
if [[ ! -f "${tomo}.nonctf.bin1.rec" ]]
then
    mv "${tomo}.nonctf.rec" "${tomo}.nonctf.bin1.rec"
else
    echo "${tomo}.nonctf.bin1.rec already exists. SKIPPING!"
fi

RECONSTRUCT

        fi

        if [[ ${do_2dctf} -eq 1 ]]
        then
            cat<<RECONSTRUCT>>"${script_fn}"
if [[ ! -f "${tomo}.2dctf.bin2.rec" ]]
then
    "${imod_exe_dir}/binvol" -bin 2 -antialias 5 "${tomo}.2dctf.bin1.rec" \\
        "${tomo}.2dctf.bin2.rec"

else
    echo "${tomo}.2dctf.bin2.rec already exists. SKIPPING!"
fi

if [[ ! -f "${tomo}.2dctf.bin4.rec" ]]
then
    "${imod_exe_dir}/binvol" -bin 2 -antialias 5 "${tomo}.2dctf.bin2.rec" \\
        "${tomo}.2dctf.bin4.rec"

else
    echo "${tomo}.2dctf.bin4.rec already exists. SKIPPING!"
fi

if [[ ! -f "${tomo}.2dctf.bin8.rec" ]]
then
    "${imod_exe_dir}/binvol" -bin 2 -antialias 5 "${tomo}.2dctf.bin4.rec" \\
        "${tomo}.2dctf.bin8.rec"

else
    echo "${tomo}.2dctf.bin4.rec already exists. SKIPPING!"
fi

RECONSTRUCT

        else
            cat<<RECONSTRUCT>>"${script_fn}"
if [[ ! -f "${tomo}.nonctf.bin2.rec" ]]
then
    "${imod_exe_dir}/binvol" -bin 2 -antialias 5 "${tomo}.nonctf.bin1.rec" \\
        "${tomo}.nonctf.bin2.rec"

else
    echo "${tomo}.nonctf.bin2.rec already exists. SKIPPING!"
fi

if [[ ! -f "${tomo}.nonctf.bin4.rec" ]]
then
    "${imod_exe_dir}/binvol" -bin 2 -antialias 5 "${tomo}.nonctf.bin2.rec" \\
        "${tomo}.nonctf.bin4.rec"

else
    echo "${tomo}.nonctf.bin4.rec already exists. SKIPPING!"
fi

if [[ ! -f "${tomo}.nonctf.bin8.rec" ]]
then
    "${imod_exe_dir}/binvol" -bin 2 -antialias 5 "${tomo}.nonctf.bin4.rec" \\
        "${tomo}.nonctf.bin8.rec"

else
    echo "${tomo}.nonctf.bin8.rec already exists. SKIPPING!"
fi

RECONSTRUCT

        fi
    fi

    # Make the script executable.
    chmod u+x "${script_fn}"
done

################################################################################
#                           RECONSTRUCTION EXECUTION                           #
################################################################################
# We need to run the scripts but one at a time while still being able to
# monitor progress so we use a subshell here to do that
(
    for good_idx_idx in ${!good_idxs[*]}
    do
        good_idx=${good_idxs[good_idx_idx]}

        # Convert the numeric index to the string formatted version.
        fmt_idx="$(printf ${idx_fmt} ${good_idx})"

        script_fn="${job_name}_reconstruct_${fmt_idx}.sh"
        error_fn="error_${job_name}_reconstruct_${fmt_idx}"
        log_fn="log_${job_name}_reconstruct_${fmt_idx}"

        if [[ ${run_local} -eq 1 ]]
        then
            "./${script_fn}" 2>"${error_fn}" > "${log_fn}"
            wait
        else
            qsub "${script_fn}"
        fi
    done
)&

################################################################################
#                           RECONSTRUCTION PROGRESS                            #
################################################################################
num_scripts="${#good_idxs[*]}"
num_complete=0
num_complete_prev=0
unchanged_count=0

for check_fn in "${check_fns[@]}"
do
    if [[ -f "${check_fn}" ]]
    then
        num_complete=$((num_complete + 1))
    fi
done

while [[ ${num_complete} -lt ${num_scripts} ]]
do
    touch "check_${job_name}"
    sleep 60s

    num_complete=0

    for check_fn in "${check_fns[@]}"
    do
        check_dir="$(dirname "${check_fn}")"
        check_base="$(basename "${check_fn}")"

        # The following will be ${check_fn} if the file is still being modified
        # (i.e. more recently modified than check_${job_name}), and "" if the
        # file has not been modified in more than a minute.
        check_fn_="$(find ${check_dir} -regex ".*/${check_base}" -and \
            -newer "check_${job_name}")"

        if [[ -n "${check_fn_}" ]]
        then
            check_done=0
        else
            check_done=1
        fi

        if [[ -f "${check_fn}" && "${check_done}" -eq 1 ]]
        then
            num_complete=$((num_complete + 1))
        fi
    done

    if [[ ${num_complete} -eq ${num_complete_prev} ]]
    then
        unchanged_count=$((unchanged_count + 1))
    else
        unchanged_count=0
    fi

    num_complete_prev=${num_complete}

    if [[ ${num_complete} -gt 0 && ${unchanged_count} -gt 240 ]]
    then
        echo "Preprocessing has seemed to stall"
        echo "Please check error logs and resubmit the job if needed."
        exit 1
    fi

    # Create a general error and log file
    if [[ -f "error_${job_name}_reconstruct" ]]
    then
        rm "error_${job_name}_reconstruct"
        touch "error_${job_name}_reconstruct"
    else
        touch "error_${job_name}_reconstruct"
    fi

    if [[ -f "log_${job_name}_reconstruct" ]]
    then
        rm "log_${job_name}_reconstruct"
        touch "log_${job_name}_reconstruct"
    else
        touch "log_${job_name}_reconstruct"
    fi

    for log_idx in $(seq ${good_idxs[0]} ${good_idxs[-1]})
    do
        log_fmt_idx=$(printf "${idx_fmt}" ${log_idx})

        if [[ -f "error_${job_name}_reconstruct_${log_fmt_idx}" ]]
        then
            cat "error_${job_name}_reconstruct_${log_fmt_idx}" >>\
                "error_${job_name}_reconstruct"
        fi

        if [[ -f "log_${job_name}_reconstruct_${log_fmt_idx}" ]]
        then
            cat "log_${job_name}_reconstruct_${log_fmt_idx}" >>\
                "log_${job_name}_reconstruct"
        fi
    done

    echo -e "\nERROR Update: Reconstruction\n"
    tail "error_${job_name}_reconstruct"

    echo -e "\nLOG Update: Reconstruction\n"
    tail "log_${job_name}_reconstruct"

    echo -e "\nSTATUS Update: Reconstruction\n"
    echo -e "\t${num_complete} tomograms out of ${num_scripts}\n"
    rm "check_${job_name}"
    sleep 60s
done

################################################################################
#                           RECONSTRUCTION CLEAN UP                            #
################################################################################
if [[ ! -d reconstruct ]]
then
    mkdir reconstruct
fi

if [[ -e "log_${job_name}_reconstruct" ]]
then
    mv "log_${job_name}_reconstruct" reconstruct/.
fi

if [[ -e "error_${job_name}_reconstruct" ]]
then
    mv "error_${job_name}_reconstruct" reconstruct/.
fi

if [[ -f "${job_name}_nova_defocus.com" ]]
then
    rm -f "${job_name}_nova_defocus.com"
fi

if [[ -f "${job_name}_nova_ctfcorr.com" ]]
then
    rm -f "${job_name}_nova_ctfcorr.com"
fi

if [[ -f "${job_name}_nova_filter.com" ]]
then
    rm -f "${job_name}_nova_filter.com"
fi

if [[ -f "${job_name}_nova_reconstruct.com" ]]
then
    rm -f "${job_name}_nova_reconstruct.com"
fi

if [[ -f "${job_name}_ctfphaseflip.com" ]]
then
    rm -f "${job_name}_ctfphaseflip.com"
fi

if [[ -f "${job_name}_newst.com" ]]
then
    rm -f "${job_name}_newst.com"
fi

if [[ -f "${job_name}_eraser.com" ]]
then
    rm -f "${job_name}_eraser.com"
fi

if [[ -f "${job_name}_newst.com" ]]
then
    rm -f "${job_name}_newst.com"
fi

# Confusingly loop over the indices of good_idxs
# (0 to length of good_idxs)
for good_idx_idx in ${!good_idxs[*]}
do
    good_idx=${good_idxs[good_idx_idx]}

    # Convert the numeric index to the string formatted version.
    fmt_idx=$(printf "${idx_fmt}" "${good_idx}")

    tomo="${tomo_fmt/XXXIDXXXX/${fmt_idx}}"
    tomo_dir="${scratch_dir}/${tomo_dir_fmt/XXXIDXXXX/${fmt_idx}}"
    tomo_defocus="${defocus_file/XXXIDXXXX/${fmt_idx}}"

    script_fn="${job_name}_reconstruct_${fmt_idx}.sh"
    log_fn="log_${job_name}_reconstruct_${fmt_idx}"
    error_fn="error_${job_name}_reconstruct_${fmt_idx}"

    if [[ -e "${script_fn}" ]]
    then
        mv "${script_fn}" reconstruct/.
    fi

    if [[ -e "${log_fn}" ]]
    then
        mv "${log_fn}" reconstruct/.
    fi

    if [[ -e "${error_fn}" ]]
    then
        mv "${error_fn}" reconstruct/.
    fi

    if [[ -f "${tomo_dir}/${job_name}_nova_defocus_${fmt_idx}.com" ]]
    then
        rm -f "${tomo_dir}/${job_name}_nova_defocus_${fmt_idx}.com"
    fi

    if [[ -f "${tomo_dir}/${job_name}_ctfphaseflip_${fmt_idx}.com" ]]
    then
        rm -f "${tomo_dir}/${job_name}_ctfphaseflip_${fmt_idx}.com"
    fi

    if [[ -f "${tomo_dir}/${tomo}_ctfcorr.st" ]]
    then
        rm -f "${tomo_dir}/${tomo}_ctfcorr.st"
    fi

    if [[ -f "${tomo_dir}/${job_name}_newst_${fmt_idx}.com" ]]
    then
        rm -f "${tomo_dir}/${job_name}_newst_${fmt_idx}.com"
    fi

    if [[ -f "${tomo_dir}/${tomo}_aligned.ali" ]]
    then
        rm -f "${tomo_dir}/${tomo}_aligned.ali"
    fi

    if [[ -f "${tomo_dir}/${job_name}_newst_${fmt_idx}.log" ]]
    then
        rm -f "${tomo_dir}/${job_name}_newst_${fmt_idx}.log"
    fi

    if [[ -f "${tomo_dir}/${job_name}_newst_${fmt_idx}.log~" ]]
    then
        rm -f "${tomo_dir}/${job_name}_newst_${fmt_idx}.log~"
    fi

    if [[ -f "${tomo_dir}/${job_name}_eraser_${fmt_idx}.com" ]]
    then
        rm -f "${tomo_dir}/${job_name}_eraser_${fmt_idx}.com"
    fi

    if [[ -f "${tomo_dir}/${tomo}_erased.ali" ]]
    then
        rm -f "${tomo_dir}/${tomo}_erased.ali"
    fi

    if [[ -f "${tomo_dir}/${job_name}_eraser_${fmt_idx}.log" ]]
    then
        rm -f "${tomo_dir}/${job_name}_eraser_${fmt_idx}.log"
    fi

    if [[ -f "${tomo_dir}/${job_name}_eraser_${fmt_idx}.log~" ]]
    then
        rm -f "${tomo_dir}/${job_name}_eraser_${fmt_idx}.log~"
    fi

    if [[ -f "${tomo_dir}/${tomo}_flipped.ali" ]]
    then
        rm -f "${tomo_dir}/${tomo}_flipped.ali"
    fi

    if [[ -f "${tomo_dir}/${job_name}_nova_filter_${fmt_idx}.com" ]]
    then
        rm -f "${tomo_dir}/${job_name}_nova_filter_${fmt_idx}.com"
    fi

    if [[ -f "${tomo_dir}/${tomo}_filtered.ali" ]]
    then
        rm -f "${tomo_dir}/${tomo}_filtered.ali"
    fi

    if [[ -f "${tomo_dir}/${job_name}_nova_reconstruct_${fmt_idx}.com" ]]
    then
        rm -rf "${tomo_dir}/${job_name}_nova_reconstruct_${fmt_idx}.com"
    fi

    if [[ ${do_3dctf} -eq 1 ]]
    then
        nsteps=${nsteps_array[${good_idx_idx}]}

        for dstep in $(seq 0 ${nsteps})
        do
            clean_fn="${tomo_dir}/${tomo_defocus}_${dstep}"

            if [[ -f "${clean_fn}" ]]
            then
                rm -rf "${clean_fn}"
            fi

            clean_fn="${tomo_dir}/${job_name}_nova_ctfcorr_${fmt_idx}.com"
            clean_fn="${clean_fn}_${dstep}"

            if [[ -f "${clean_fn}" ]]
            then
                rm -rf "${clean_fn}"
            fi

            clean_fn="${tomo_dir}/${tomo}_ctfcorr.st_${dstep}"

            if [[ -f "${clean_fn}" ]]
            then
                rm -rf "${clean_fn}"
            fi

            clean_fn="${tomo_dir}/${job_name}_newst_${fmt_idx}.com_${dstep}"

            if [[ -f "${clean_fn}" ]]
            then
                rm -rf "${clean_fn}"
            fi

            clean_fn="${tomo_dir}/${tomo}_ctfcorr.ali_${dstep}"

            if [[ -f "${clean_fn}" ]]
            then
                rm -rf "${clean_fn}"
            fi

            clean_fn="${tomo_dir}/${job_name}_eraser_${fmt_idx}.com_${dstep}"

            if [[ -f "${clean_fn}" ]]
            then
                rm -rf "${clean_fn}"
            fi

            clean_fn="${tomo_dir}/${tomo}_erased.ali_${dstep}"

            if [[ -f "${clean_fn}" ]]
            then
                rm -rf "${clean_fn}"
            fi

            clean_fn="${tomo_dir}/${tomo}_flipped.ali_${dstep}"

            if [[ -f "${clean_fn}" ]]
            then
                rm -rf "${clean_fn}"
            fi

            clean_fn="${tomo_dir}/${job_name}_nova_filter_${fmt_idx}.com"
            clean_fn="${clean_fn}_${dstep}"

            if [[ -f "${clean_fn}" ]]
            then
                rm -rf "${clean_fn}"
            fi

            clean_fn="${tomo_dir}/${tomo}_filtered.ali_${dstep}"

            if [[ -f "${clean_fn}" ]]
            then
                rm -rf "${clean_fn}"
            fi
        done
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
printf "| %-25s | %25s |\n" "job_name" "${job_name}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "run_local" "${run_local}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "tomo_fmt" "${tomo_fmt}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "tomo_dir_fmt" "${tomo_dir_fmt}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "start_idx" "${start_idx}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "end_idx" "${end_idx}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "idx_fmt" "${idx_fmt}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "defocus_file" "${defocus_file}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "pixel_size" "${pixel_size}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "amplitude_contrast" "${amplitude_contrast}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "cs" "${cs}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "voltage" "${voltage}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "do_3dctf" "${do_3dctf}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "correction_type" "${correction_type}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "defocus_file_format" "${defocus_file_format}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "defocus_step" "${defocus_step}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "correct_astigmatism" "${correct_astigmatism}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "defocus_shift_file" "${defocus_shift_file}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "do_2dctf" "${do_2dctf}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "defocus_shift" "${defocus_shift}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "defocus_tolerance" "${defocus_tolerance}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "interpolation_width" "${interpolation_width}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "use_gpu" "${use_gpu}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "do_radial" "${do_radial}" >> subTOM_protocol.md
printf "| %-25s | %25s |\n" "radial_cutoff" "${radial_cutoff}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "radial_falloff" "${radial_falloff}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "erase_radius" "${erase_radius}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n" "do_rotate_tomo" "${do_rotate_tomo}" >>\
    subTOM_protocol.md

printf "| %-25s | %25s |\n\n" "do_trimvol" "${do_trimvol}" >> subTOM_protocol.md
