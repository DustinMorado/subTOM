#!/bin/bash
set -e
set -o nounset
################################################################################
#                                  VARIABLES                                   #
################################################################################
# The format string for the datasets to process. The string XXXIDXXXX will be
# replaced with the numbers specified between the range start_idx and end_idx
tomo_fmt=XXXIDXXXX_dose-filt
#tomo_fmt=TS_XXXIDXXX
#tomo_fmt=TS_XXXIDXXX_dose-filt
#tomo_fmt=ts_XXXIDXXX
#tomo_fmt=ts_XXXIDXXX_dose-filt

# The format string for the directory of datasets to process. The string
# XXXIDXXXX will be replaced with the numbers specified between the range
# start_idx and end_idx
tomo_dir_fmt=XXXIDXXXX
#tomo_dir_fmt=TS_XXXIDXXX
#tomo_dir_fmt=ts_XXXIDXXX

# The first tomogram to operate on
start_idx=1

# The last tomogram to operate on.
end_idx=63

# The format string for the tomogram indexes. Likely two or three digit zero
# padding or maybe just flat integers.
idx_fmt="%02d" # two digit zero padding e.g. 01
#idx_fmt="%03d" # three digit zero padding e.g. 001
#idx_fmt="%d" # no padding flat integer e.g. 1

# Set this value to 1 if you want to have the jobs submitted to the cluster
# or set it 0 to have the jobs run locally.
do_qsub=0

# Set this value to the number of jobs you want to run in the background before
# reconstruction. Should be the number of threads on the local system or cluster
# which for our system is 24 on the cluster and higher on the local systems, but
# there you should be polite !
num_threads=36

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
correction_type=multiplication

# File format for the defocus list. Use ctffind4 for CTFFIND4 and imod for
# CTFPLOTTER
defocus_file_format=ctffind4
#defocus_file_format=imod

# Where the defocus list file is located. The string XXXTOMOGRAMXXX will be
# replaced with the tomogram name, i.e. XXXTOMOGRAMXXX_output.txt will be turned
# into TS_01_output.txt. The string XXXIDXXXX will be replaced with the
# formatted tomogram index, i.e. XXXIDXXXX_output.txt will be turned into
# 01_output.txt.
defocus_file=XXXIDXXXX_output.txt
#defocus_file=XXXTOMOGRAMXXX_output.txt

# The pixel size of the tilt series in nanometers
pixel_size=0.1041

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
#defocus_shift_file=XXXTOMOGRAMXXX_defocus_shift.txt

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
erase_radius=56

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################

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
\$newstack -StandardInput
InputFile XXXTOMOGRAMXXX_ctfcorr.st_XXXNUMBERXXX
OutputFile XXXTOMOGRAMXXX_ctfcorr.ali_XXXNUMBERXXX
TransformFile XXXTOMOGRAMXXX.xf
SizeToOutputInXandY XXXFULLIMAGEXXX
BinByFactor 1
AdjustOrigin
NearestNeighbor
NEWSTCOM

cat <<GOLDERASECOM>eraser.com
\$ccderaser -StandardInput
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
    tomo_defocus=${tomo_defocus/XXXTOMOGRAMXXXX/${fmt_idx}}
    if [[ ! -d ${tomo_dir} ]]
    then
        continue
    fi
    if [[ ! -f ${tomo_dir}/tilt.com ]]
    then
        continue
    fi
    if [[ ! -f ${tomo_dir}/${tomo_defocus} ]]
    then
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

    novaCTF -param nova_defocus.com

    defocus_base=${defocus_file/XXXTOMOGRAMXXX/${tomo}}
    defocus_base=${defocus_base/XXXIDXXXX/${fmt_idx}}
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
        continue
    fi
    if [[ ! -f ${tomo_dir}/tilt.com ]]
    then
        continue
    fi
    if [[ ! -f ${tomo_dir}/${tomo_defocus} ]]
    then
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
#$ -l dedicated=24
#$ -o log_NovaCTF_${fmt_idx}
#$ -e error_NovaCTF_${fmt_idx}
cd ${tomo_dir}
dstep=0
for x in eraser.com_*
do
    (
        novaCTF -param nova_ctfcorr.com_\${dstep}
        submfg newst.com_\${dstep}
        submfg eraser.com_\${dstep}
        mrctaper -t 100 ${tomo}_erased.ali_\${dstep}
        clip flipyz ${tomo}_erased.ali_\${dstep} ${tomo}_flipped.ali_\${dstep}
        novaCTF -param nova_filter.com_\${dstep}
    ) &

    if [[ \$(((dstep + 1) % ${num_threads})) -eq 0 ]]
    then
        wait
    fi
    dstep=\$((dstep + 1))
done
wait
novaCTF -param nova_reconstruct.com
if [[ ${do_trimvol} -ne 1 ]]
then
    clip rotx ${tomo}.rec ${tomo}.bin1.rec
else
    trimvol -rx ${tomo}.rec ${tomo}.bin1.rec
fi
rm ${tomo}.rec
binvol -bin 2 -antialias 5 ${tomo}.bin1.rec ${tomo}.bin2.rec
binvol -bin 2 -antialias 5 ${tomo}.bin2.rec ${tomo}.bin4.rec
binvol -bin 2 -antialias 5 ${tomo}.bin4.rec ${tomo}.bin8.rec
cd ..
RUNNOVA

        if [[ ${do_qsub} -eq 1 ]]
        then
#           qsub run_nova_${fmt_idx}.sh
        else
            chmod u+x run_nova_${fmt_idx}.sh
#           ./run_nova_${fmt_idx}.sh
        fi
    else
        cat<<PREPNOVA>prep_nova_${fmt_idx}.sh
#!/bin/bash
#$ -N NovaCTF_prep_${fmt_idx}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l dedicated=24
#$ -o log_NovaCTF_prep_${fmt_idx}
#$ -e error_NovaCTF_prep_${fmt_idx}
tomo=${tomo_fmt/XXXIDXXXX/${fmt_idx}}
tomo_dir=${tomo_dir_fmt/XXXIDXXXX/${fmt_idx}}
cd \${tomo_dir}
dstep=0
for x in eraser.com_*
do
    (
        novaCTF -param nova_ctfcorr.com_\${dstep}
        submfg newst.com_\${dstep}
        submfg eraser.com_\${dstep}
        mrctaper -t 100 \${tomo}_erased.ali_\${dstep}
        clip flipyz \${tomo}_erased.ali_\${dstep} \${tomo}_flipped.ali_\${dstep}
        novaCTF -param nova_filter.com_\${dstep}
    ) &

    if [[ \$(((dstep + 1) % ${num_threads})) -eq 0 ]]
    then
        wait
    fi
    dstep=\$((dstep + 1))
done
wait
PREPNOVA

        if [[ ${do_qsub} -eq 1 ]]
        then
#           qsub prep_nova_${fmt_idx}.sh
        else
            chmod u+x prep_nova_${fmt_idx}.sh
#           ./prep_nova_${fmt_idx}.sh
        fi
        cat<<RECNOVA>rec_nova_${fmt_idx}.sh
#!/bin/bash
#$ -N NovaCTFrec_${fmt_idx}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l dedicated=24
#$ -o log_NovaCTFrec_${fmt_idx}
#$ -e error_NovaCTFrec_${fmt_idx}
tomo=${tomo_fmt/XXXIDXXXX/${fmt_idx}}
tomo_dir=${tomo_dir_fmt/XXXIDXXXX/${fmt_idx}}
cd \${tomo_dir}
novaCTF -param nova_reconstruct.com
if [[ ${do_trimvol} -ne 1 ]]
then
    clip rotx ${tomo}.rec ${tomo}.bin1.rec
else
    trimvol -rx ${tomo}.rec ${tomo}.bin1.rec
fi
rm \${tomo}.rec
binvol -bin 2 -antialias 5 \${tomo}.bin1.rec \${tomo}.bin2.rec
binvol -bin 2 -antialias 5 \${tomo}.bin2.rec \${tomo}.bin4.rec
binvol -bin 2 -antialias 5 \${tomo}.bin4.rec \${tomo}.bin8.rec
cd ..
RECNOVA

        chmod u+x rec_nova_${fmt_idx}.sh
#       ./rec_nova_${fmt_idx}.sh
    fi
done
