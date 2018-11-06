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
# This processing script uses no MATLAB compiled functions
# DRM 08-2018
################################################################################
set -e
set -o nounset
unset ml
unset module
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the folder with the input to be processed.
# Other paths are relative to this one.
scratch_dir=<SCRATCH_DIR>

################################################################################
#                                 EXECUTABLES                                  #
################################################################################
# Absolute path to the novaCTF executable.
novactf_exe=<NOVACTF_EXE>
#novactf_exe=/net/bstore1/bstore1/briggsgrp/LMB/software/novaCTF/novaCTF
#novactf_exe=$(which novaCTF) # If you have novaCTF in your path.

# Absolute path to the IMOD newstack executable. The directory of this will be
# used for the other IMOD programs used in the processing.
newstack_exe=<NEWSTACK_EXE>
#newstack_exe=${bstore1}../LMB/software/imod_4.10.10_RHEL7-64_CUDA8.0/IMOD/bin/newstack
#newstack_exe=$(which newstack) # If you have newstack in your path.

################################################################################
#                                MEMORY OPTIONS                                #
################################################################################
# The amount of memory your job requires
# e.g. mem_free='2G'
mem_free=<MEM_FREE>

# The upper bound on the amount of memory your job is allowed to use
# e.g. mem_max_ali='3G'
mem_max=<MEM_MAX>

# Set this value to the number of jobs you want to run in the background before
# reconstruction. Should be the number of threads on the local system or cluster
# which for our system is 24 on the cluster and higher on the local systems, but
# there you should be polite !
num_threads=<NUM_THREADS>

################################################################################
#                              OTHER LSF OPTIONS                               #
################################################################################
# If you want to skip the cluster and run the job locally set this to 1.
run_local=0

################################################################################
#                                  VARIABLES                                   #
################################################################################
# The format string for the datasets to process. The string XXXIDXXXX will be
# replaced with the numbers specified between the range start_idx and end_idx
#tomo_fmt=TS_XXXIDXXXX_dose-filt
#tomo_fmt=TS_XXXIDXXXX
#tomo_fmt=ts_XXXIDXXXX
#tomo_fmt=ts_XXXIDXXXX_dose-filt
#tomo_fmt=XXXIDXXXX_dose-filt
tomo_fmt=<TOMO_FMT>

# The format string for the directory of datasets to process. The string
# XXXIDXXXX will be replaced with the numbers specified between the range
# start_idx and end_idx
#tomo_dir_fmt=TS_XXXIDXXXX
#tomo_dir_fmt=ts_XXXIDXXXX
#tomo_dir_fmt=XXXIDXXXX
tomo_dir_fmt=<TOMO_DIR_FMT>

# The first tomogram to operate on
start_idx=<START_IDX>

# The last tomogram to operate on.
end_idx=<END_IDX>

# The format string for the tomogram indexes. Likely two or three digit zero
# padding or maybe just flat integers.
idx_fmt="%02d" # two digit zero padding e.g. 01
#idx_fmt="%03d" # three digit zero padding e.g. 001
#idx_fmt="%d" # no padding flat integer e.g. 1

# Set this value to 1 if you only want to write scripts for the reconstruction.
# This can be useful when the cluster doesn't have enough memory to do the
# reconstruction and the reconstruction has to be done on local machines
do_reconstruct=0

# Set this value to 1 if you want to use "trimvol -rx" to flip the tomograms to
# the XY standard orientation from the XZ generated tomograms. Otherwise "clip
# rotx" will be used since it is much faster.
do_trimvol=0

################################################################################
#                               NOVA CTF OPTIONS                               #
################################################################################
# Type of CTF correction to perform
#correction_type=phaseflip
correction_type=multiplication

# File format for the defocus list. Use ctffind4 for CTFFIND4 and imod for
# CTFPLOTTER
defocus_file_format=ctffind4
#defocus_file_format=imod

# Where the defocus list file is located. The string XXXIDXXXX will be replaced
# with the formatted tomogram index, i.e. XXXIDXXXX_output.txt will be turned
# into 01_output.txt.
#defocus_file=TS_XXXIDXXXX_output.txt
defocus_file=<DEFOCUS_FILE>

# The pixel size of the tilt series in nanometers
pixel_size=<PIXEL_SIZE>

# The strip size in nanometers to perform CTF correction in novaCTF refer to the
# paper for more information on this value and sensible defaults.
defocus_step=15

# Do you want to correct astigmatism 1 for yes 0 for no, but you will need
# CTFFIND4 formated defocus list to be able to correct for astigmatism.
correct_astigmatism=1

# If you want to shift the defocus for some reason away from the center of the
# mass of the tomogram provide a defocus_shifts file with the shifts. See the
# paper for more information on this value.
defocus_shift_file=
#defocus_shift_file=TS_XXXIDXXXX_defocus_shift.txt

# The amplitude contrast for CTF correction
amplitude_contrast=0.07

# The spherical aberration of the microscope in mm for CTF correction
cs=2.7

# The voltage in KeV of the microscope for CTF correction
voltage=300

# The parameters of RADIAL from the tilt manpage in IMOD that describes the
# radial filter used to weight before back-projection.
radial_cutoff=0.5
radial_falloff=0.0

################################################################################
#                                 IMOD OPTIONS                                 #
################################################################################
# The radius in pixels to erase when removing the gold fiducials from the
# aligned tilt-series stacks.
erase_radius=<ERASE_RADIUS>

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
cd ${scratch_dir}

imod_exe_dir=$(dirname ${newstack_exe})

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
    echo DefocusShiftFile ${defocus_shift_file} >> nova_defocus.com
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

cat<<FILTERCOM>nova_filter.com
Algorithm filterProjections
InputProjections XXXTOMOGRAMXXX_flipped.ali_XXXNUMBERXXX
OutputFile XXXTOMOGRAMXXX_filtered.ali_XXXNUMBERXXX
TILTFILE XXXTOMOGRAMXXX.tlt
StackOrientation xz
RADIAL ${radial_cutoff} ${radial_falloff}
FILTERCOM

cat<<RECCOM>nova_reconstruct.com
Algorithm 3dctf
InputProjections XXXTOMOGRAMXXX_filtered.ali
OutputFile XXXTOMOGRAMXXX.rec  
TILTFILE XXXTOMOGRAMXXX.tlt
THICKNESS XXXTHICKNESSXXX
FULLIMAGE XXXFULLIMAGEXXX
SHIFT XXXSHIFTXXX
PixelSize ${pixel_size}
DefocusStep ${defocus_step}
Use3DCTF 1
RECCOM

cat <<NEWSTCOM>newst.com
\$${imod_exe_dir}/newstack -StandardInput
InputFile XXXTOMOGRAMXXX_ctfcorr.st_XXXNUMBERXXX
OutputFile XXXTOMOGRAMXXX_ctfcorr.ali_XXXNUMBERXXX
TransformFile XXXTOMOGRAMXXX.xf
SizeToOutputInXandY XXXFULLIMAGEXXX
BinByFactor 1
AdjustOrigin
NearestNeighbor
NEWSTCOM

cat <<GOLDERASECOM>eraser.com
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

# We run the defocus part of the procedure first since it is very fast and we
# need it to determine the number of tilt-series we will be generating later.
# Then we can write all of the comfiles to be run in the processing.
for idx in $(seq ${start_idx} ${end_idx})
do
    fmt_idx=$(printf ${idx_fmt} ${idx})
    tomo=${tomo_fmt/XXXIDXXXX/${fmt_idx}}
    tomo_dir=${tomo_dir_fmt/XXXIDXXXX/${fmt_idx}}
    tomo_defocus=${defocus_file/XXXIDXXXX/${fmt_idx}}
    if [[ ! -d ${tomo_dir} ]]
    then
        echo "Directory ${tomo_dir} does not exist SKIPPING!"
        continue
    fi
    if [[ ! -f ${tomo_dir}/tilt.com ]]
    then
        echo "TILT COM script ${tomo_dir}/tilt.com does not exist SKIPPING!"
        continue
    fi
    if [[ ! -f ${tomo_dir}/${tomo_defocus} ]]
    then
        echo "Defocus file ${tomo_dir}/${tomo_defocus} does not exist SKIPPING!"
        continue
    fi
    cd ${tomo_dir}
    thickness=$(grep THICKNESS tilt.com | awk '{ print $2 }')
    shifts=$(grep SHIFT tilt.com | awk '{ print $2, $3 }')
    fullimage=$(grep FULLIMAGE tilt.com | awk '{ print $2, $3 }')
    sed \
        -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
        -e "s/XXXTHICKNESSXXX/${thickness}/g" \
        -e "s/XXXFULLIMAGEXXX/${fullimage}/g" \
        -e "s/XXXIDXXXX/${fmt_idx}/g" \
        ../nova_defocus.com > nova_defocus.com
    sed \
        -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
        -e "s/XXXTHICKNESSXXX/${thickness}/g" \
        -e "s/XXXFULLIMAGEXXX/${fullimage}/g" \
        -e "s/XXXSHIFTXXX/${shifts}/g" \
        ../nova_reconstruct.com > nova_reconstruct.com

    ${novactf_exe} -param nova_defocus.com

    defocus_base=${defocus_file/XXXIDXXXX/${fmt_idx}}
    nsteps=$(ls ${defocus_base}_* | awk -F_ '{ print $NF }' | sort -n | \
             tail -n 1)

    for dstep in $(seq 0 ${nsteps})
    do
        sed \
            -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
            -e "s/XXXNUMBERXXX/${dstep}/g" \
            -e "s/XXXIDXXXX/${fmt_idx}/g" \
            ../nova_ctfcorr.com > nova_ctfcorr.com_${dstep}
        sed \
            -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
            -e "s/XXXNUMBERXXX/${dstep}/g" \
            ../nova_filter.com > nova_filter.com_${dstep}
        sed \
            -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
            -e "s/XXXNUMBERXXX/${dstep}/g" \
            -e "s/XXXFULLIMAGEXXX/${fullimage}/g" \
            ../newst.com > newst.com_${dstep}
        sed \
            -e "s/XXXTOMOGRAMXXX/${tomo}/g" \
            -e "s/XXXNUMBERXXX/${dstep}/g" \
            ../eraser.com > eraser.com_${dstep}
    done
    cd ..
done

# Clean up the initally written com scripts.
rm nova_defocus.com nova_reconstruct.com nova_ctfcorr.com nova_filter.com
rm newst.com eraser.com

# The rest we write into a script so that we can run it locally or submit it to
# the cluster
for idx in $(seq ${start_idx} ${end_idx})
do
    fmt_idx=$(printf ${idx_fmt} ${idx})
    tomo=${tomo_fmt/XXXIDXXXX/${fmt_idx}}
    tomo_dir=${tomo_dir_fmt/XXXIDXXXX/${fmt_idx}}
    tomo_defocus=${defocus_file/XXXIDXXXX/${fmt_idx}}
    if [[ ! -d ${tomo_dir} ]]
    then
        echo "Directory ${tomo_dir} does not exist SKIPPING!"
        continue
    fi
    if [[ ! -f ${tomo_dir}/tilt.com ]]
    then
        echo "TILT COM script ${tomo_dir}/tilt.com does not exist SKIPPING!"
        continue
    fi
    if [[ ! -f ${tomo_dir}/${tomo_defocus} ]]
    then
        echo "Defocus file ${tomo_dir}/${tomo_defocus} does not exist SKIPPING!"
        continue
    fi
    if [[ ${do_reconstruct} -ne 1 ]]
    then
        cat<<RUNNOVA>run_nova_${fmt_idx}.sh
#!/bin/bash
#$ -N NovaCTF_${fmt_idx}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l dedicated=24,mem_free=${mem_free},h_vmem=${mem_max}
#$ -o log_NovaCTF_${fmt_idx}
#$ -e error_NovaCTF_${fmt_idx}
cd ${tomo_dir}
dstep=0
for x in eraser.com_*
do
    (
        ${novactf_exe} -param nova_ctfcorr.com_\${dstep}
        ${imod_exe_dir}/submfg newst.com_\${dstep}
        ${imod_exe_dir}/submfg eraser.com_\${dstep}
        ${imod_exe_dir}/mrctaper -t 100 ${tomo}_erased.ali_\${dstep}
        ${imod_exe_dir}/clip flipyz ${tomo}_erased.ali_\${dstep} \\
            ${tomo}_flipped.ali_\${dstep}
        ${novactf_exe} -param nova_filter.com_\${dstep}
    ) &

    if [[ \$(((dstep + 1) % ${num_threads})) -eq 0 ]]
    then
        wait
    fi
    dstep=\$((dstep + 1))
done
wait
${novactf_exe} -param nova_reconstruct.com
if [[ ${do_trimvol} -ne 1 ]]
then
    ${imod_exe_dir}/clip rotx -m 1 ${tomo}.rec ${tomo}.bin1.rec
else
    ${imod_exe_dir}/trimvol -rx -mode 1 ${tomo}.rec ${tomo}.bin1.rec
fi
rm ${tomo}.rec
${imod_exe_dir}/binvol -bin 2 -antialias 5 ${tomo}.bin1.rec ${tomo}.bin2.rec
${imod_exe_dir}/binvol -bin 2 -antialias 5 ${tomo}.bin2.rec ${tomo}.bin4.rec
${imod_exe_dir}/binvol -bin 2 -antialias 5 ${tomo}.bin4.rec ${tomo}.bin8.rec
cd ..
RUNNOVA

        chmod u+x run_nova_${fmt_idx}.sh
        if [[ ${run_local} -eq 1 ]]
        then
            ./run_nova_${fmt_idx}.sh
        else
            qsub run_nova_${fmt_idx}.sh
        fi
    else
        cat<<PREPNOVA>prep_nova_${fmt_idx}.sh
#!/bin/bash
#$ -N NovaCTF_prep_${fmt_idx}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l dedicated=24,mem_free=${mem_free},h_vmem=${mem_max}
#$ -o log_NovaCTF_prep_${fmt_idx}
#$ -e error_NovaCTF_prep_${fmt_idx}
tomo=${tomo_fmt/XXXIDXXXX/${fmt_idx}}
tomo_dir=${tomo_dir_fmt/XXXIDXXXX/${fmt_idx}}
cd \${tomo_dir}
dstep=0
for x in eraser.com_*
do
    (
        ${novactf_exe} -param nova_ctfcorr.com_\${dstep}
        ${imod_exe_dir}/submfg newst.com_\${dstep}
        ${imod_exe_dir}/submfg eraser.com_\${dstep}
        ${imod_exe_dir}/mrctaper -t 100 \${tomo}_erased.ali_\${dstep}
        ${imod_exe_dir}/clip flipyz \${tomo}_erased.ali_\${dstep} \\
            \${tomo}_flipped.ali_\${dstep}
        ${novactf_exe} -param nova_filter.com_\${dstep}
    ) &

    if [[ \$(((dstep + 1) % ${num_threads})) -eq 0 ]]
    then
        wait
    fi
    dstep=\$((dstep + 1))
done
wait
PREPNOVA

        chmod u+x prep_nova_${fmt_idx}.sh
        if [[ ${run_local} -eq 1 ]]
        then
           ./prep_nova_${fmt_idx}.sh
        else
            qsub prep_nova_${fmt_idx}.sh
        fi
        cat<<RECNOVA>rec_nova_${fmt_idx}.sh
#!/bin/bash
#$ -N NovaCTFrec_${fmt_idx}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l dedicated=24,mem_free=${mem_free},h_vmem=${mem_max}
#$ -o log_NovaCTFrec_${fmt_idx}
#$ -e error_NovaCTFrec_${fmt_idx}
tomo=${tomo_fmt/XXXIDXXXX/${fmt_idx}}
tomo_dir=${tomo_dir_fmt/XXXIDXXXX/${fmt_idx}}
cd \${tomo_dir}
${novactf_exe} -param nova_reconstruct.com
if [[ ${do_trimvol} -ne 1 ]]
then
    ${imod_exe_dir}/clip rotx -m 1 ${tomo}.rec ${tomo}.bin1.rec
else
    ${imod_exe_dir}/trimvol -rx -mode 1 ${tomo}.rec ${tomo}.bin1.rec
fi
rm \${tomo}.rec
${imod_exe_dir}/binvol -bin 2 -antialias 5 \${tomo}.bin1.rec \${tomo}.bin2.rec
${imod_exe_dir}/binvol -bin 2 -antialias 5 \${tomo}.bin2.rec \${tomo}.bin4.rec
${imod_exe_dir}/binvol -bin 2 -antialias 5 \${tomo}.bin4.rec \${tomo}.bin8.rec
cd ..
RECNOVA

        chmod u+x rec_nova_${fmt_idx}.sh
       ./rec_nova_${fmt_idx}.sh
    fi
done
