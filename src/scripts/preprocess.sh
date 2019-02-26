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
# This preprocessing script uses just one MATLAB compiled function below:
# - dose_filter_tiltseries
# DRM 07-2018
################################################################################
set -e
set -o nounset   # Crash on unset variables
unset ml
unset module
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the folder with the input to be processed.
# Other paths are relative to this one.
scratch_dir=<SCRATCH_DIR>

# Absolute or relative path to the folder where the dose-fractionated movie
# frames are located.
frame_dir=<FRAME_DIR>

################################################################################
#                                 EXECUTABLES                                  #
################################################################################
# Absolute path to the IMOD alignframes executable. The directory of this will
# be used for the other IMOD programs used in the processing.
#alignframes_exe=$(which alignframes) # If you have alignframes in your path.
alignframes_exe=<ALIGNFRAMES_EXE>

# Absolute path to the CTFFIND4 executable.
#ctffind_exe=${bstore1}/../LMB/software/ctffind/ctffind.exe
#ctffind_exe=$(which ctffind.exe)
ctffind_exe=<CTFFIND_EXE>

# Absolute path to the GCTF executable.
gctf_exe=<GCTF_EXE>

################################################################################
#                                MEMORY OPTIONS                                #
################################################################################
# The amount of memory your job requires
# e.g. mem_free='2G'
mem_free=<MEM_FREE>

# The upper bound on the amount of memory your job is allowed to use
# e.g. mem_max_ali='3G'
mem_max=<MEM_MAX>

################################################################################
#                              OTHER LSF OPTIONS                               #
################################################################################
# If you want to skip the cluster and run the job locally set this to 1.
run_local=0

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# The format string for the datasets to process. The string XXXIDXXXX will be
# replaced with the numbers specified between the range start_idx and end_idx.
#
# The raw sum tilt-series will have the name format ts_fmt.st, or ts_fmt.mrc, an
# extended data file ts_fmt.{mrc,st}.mdoc and could possibly have an associated
# log ts_fmt.log 
#
# Dose-fractionated movies of tilt-images are assumed to have the name format:
# ${ts_fmt}_###_*.{mrc,tif} where ### is a running three-digit ID number for the
# tilt-image and * is the tilt-angle 
#ts_fmt=XXXIDXXXX
#ts_fmt=TS_XXXIDXXXX
#ts_fmt=ts_XXXIDXXXX
ts_fmt=<TS_FMT>

# The first tilt-series to operate on
start_idx=<START_IDX>

# The last tilt-series to operate on.
end_idx=<END_IDX>

# The format string for the tomogram indexes. Likely two or three digit zero
# padding or maybe just flat integers.
idx_fmt="%02d" # two digit zero padding e.g. 01
#idx_fmt="%03d" # three digit zero padding e.g. 001
#idx_fmt="%d" # no padding flat integer e.g. 1

################################################################################
#                                                                              #
#                    BEAM INDUCED MOTION CORRECTION OPTIONS                    #
#                                                                              #
################################################################################
# Determines whether or not gain-correction needs to be done on the frames. Set
# to 1 to apply gain-correction during motion-correction, and 0 to skip it.
# Normally TIFF format frames will be saved with compression and will be
# unnormalized, and should be gain-corrected. MRC format frames are generally
# already saved with gain-correction applied during collection, so it can be
# skipped here.
#
# A good rule of thumb, is if you have a *.dm4 file in your data you need to do
# gain-correction, and if you don't see a *.dm4 file you do not.
do_gain_correction=1

# The path to the gain-reference file, this will only be used if gain_correction
# is going to be applied.
gainref_fn=<GAINREF_FN>

# The path to the defects file, this is saved along with the gain-reference for
# unnormalized saved frames by SerialEM, and will only be used if
# gain-correction is going to be applied.
defects_fn=<DEFECTS_FN>

# Binning to apply to the frames when calculating the alignment, if you are
# using super-resolution you may want to change this to 2. The defaults from
# IMOD would be 3 for counted data and 6 for super-resolution data. Multiple
# binnings can be tested and the best one will be used to generate the final
# sum.
align_bin=1,2,3

# Binning to apply to the final sum. This is done using Fourier cropping as in
# MotionCorr and other similar programs. If you are using super-resolution you
# probably want to change this to 2, otherwise it should be set to 1.
sum_bin=1

# Amount of scaling to apply to summed values before output. The default is 30
# however serialEM applies one of 39.3?
scale=39.3

# Cutoff Frequency for the lowpass filter used in frame alignment. The unit is
# absolute spatial frequency which goes from 0 to 0.5 relative to the pixelsize
# of the input frames (not considering binning applied in alignment). The
# default from IMOD is 0.06. Multiple radii can be used and the best filter will
# be selected for the actually used alignment.
filter_radius2=0.167,0.125,0.10,0.06

# Falloff for the lowpass filter used in frame alignment. Same units as above.
# The defaults from IMOD is 0.0086.
filter_sigma2=0.0086

# Limit on distance to search for correlation peak in unbinned pixels. The
# default from IMOD is 20.
shift_limit=20

# If this is set to 1, alignframes will do an iterative refinement of the
# initially found frame alignment solution. The default in IMOD is to not do
# this refinement.
do_refinement=1

# The maximum number of refinement iterations to run.
refine_iterations=5

# Cutoff Frequency for the lowpass filter used in refinement. The default in
# IMOD would be to use the same value used in alignment.
refine_radius2=0.167

# The amount of shift at which refinement will stop in unbinned pixels.
refine_shift_stop=0.1

# If you want to use other options to alignframes specify them here
extra_opts=''

################################################################################
#                                                                              #
#                            CTF ESTIMATION OPTIONS                            #
#                                                                              #
################################################################################
# The pixel size of the motion-corrected tilt-series in Angstroms
apix=<APIX>

# If this is set to 1, the defocus will be estimated with CTFFIND4.
do_ctffind4=1

# If this is set to 1, the defocus will be estimated with GCTF.
do_gctf=1

# If this is set to 1, the defocus will be estimated with CTFPLOTTER.
do_ctfplotter=1

# The accelerating voltage of the microscope in KeV
voltage_kev=300.0

# The spherical aberration of the microscope in mm.
cs=2.7

# The amount of amplitude contrast in the imaging system.
ac=0.07

# The size of tile to operate on
tile_size=512

# The lowest wavelength in Angstroms to allow in fitting (minimum resolution)
min_res=30.0

# The highest wavelength in Angstroms to allow in fitting (maximum resolution)
max_res=5.0

# The lowest wavelength in Angstroms to allow in fitting in CTFPLOTTER
min_res_ctfplotter=30.0

# The highest wavelength in Angstroms to allow in fitting in CTFPLOTTER
max_res_ctfplotter=5.0

# The lowest defocus in Angstroms to scan.
min_def=10000.0

# The highest defocus in Angstroms to scan.
max_def=60000.0

# The step size in Angstroms to scan defocus.
def_step=100.0

# The amount of astigmatism to allow in angstroms
astigmatism=1000.0

# The tilt-axis angle of the tilt series. This is only needed if you are
# estimating the CTF with ctfplotter.
tilt_axis_angle=85.3

################################################################################
#                                                                              #
#                            DOSE FILTERING OPTIONS                            #
#                                                                              #
################################################################################
# The dose per micrograph in Electrons per square Angstrom
dose_per_tilt=<DOSE_PER_TILT>

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
cd ${scratch_dir}

imod_exe_dir=$(dirname ${alignframes_exe})
apix_nm=$(echo ${apix} | awk '{print $1 / 10}')

for idx in $(seq ${start_idx} ${end_idx})
do
    fmt_idx=$(printf ${idx_fmt} ${idx})
    ts=${ts_fmt/XXXIDXXXX/${fmt_idx}}
    if [[ -f ${ts}.st ]];
    then
        ts_fn=${ts}.st
        mdoc_fn=${ts}.st.mdoc
    elif [[ -f ${ts}.mrc ]];
    then
        ts_fn=${ts}.mrc
        mdoc_fn=${ts}.mrc.mdoc
    else
        echo "Did not find either ${ts}.st or ${ts}.mrc! SKIPPING!"
        continue
    fi

    if [[ ! -f ${mdoc_fn} ]];
    then
        echo "Did not find associated mdoc for ${ts_fn}! SKIPPING!"
        continue
    fi

    if [[ ! -d ${ts} ]]
    then
        mkdir ${ts}
    fi

    if [[ ! -d ${ts}/alignframes ]]
    then
        mkdir ${ts}/alignframes
    fi

    if [[ ${do_ctffind4} -eq 1 && ! -d ${ts}/ctffind4 ]]
    then
        mkdir ${ts}/ctffind4
    fi

    if [[ ${do_gctf} -eq 1 && ! -d ${ts}/gctf ]]
    then
        mkdir ${ts}/gctf
    fi

    if [[ ${do_ctfplotter} -eq 1 && ! -d ${ts}/ctfplotter ]]
    then
        mkdir ${ts}/ctfplotter
    fi

    mv -n ${ts_fn} ${ts}/.
    mv -n ${mdoc_fn} ${ts}/.

    if [[ -f ${ts}.log ]]
    then
        mv -n ${ts}.log ${ts}/.
    fi

    cat<<PREPROC>preprocess_${fmt_idx}.sh
#!/bin/bash
#$ -N preprocess_${fmt_idx}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l dedicated=24,mem_free=${mem_free},h_vmem=${mem_max}
#$ -o log_preprocess_${fmt_idx}
#$ -e error_preprocess_${fmt_idx}
set +o noclobber
set -e
echo \${HOSTNAME}
if [[ ! -f ${ts}/${ts}_aligned.st ]]
then
    ${alignframes_exe} \\
        -MetadataFile ${ts}/${mdoc_fn} \\
        -AdjustAndWriteMdoc \\
        -PathToFramesInMdoc ${frame_dir} \\
        -PairwiseFrames -1 \\
        -AlignAndSumBinning 1,${sum_bin} \\
        -TotalScalingOfData ${scale} \\
        -TestBinnings ${align_bin} \\
        -VaryFilter ${filter_radius2} \\
        -FilterSigma2 ${filter_sigma2} \\
        -ShiftLimit ${shift_limit} \\
        -TransformExtension aligned.xf \\
        -FRCOutputFile ${ts}/alignframes/${ts}_aligned_FRC.txt \\
        -PlottableShiftFile ${ts}/alignframes/${ts}_aligned_plot.txt \\
        -DebugOutput 3 \\
PREPROC

if [[ ${do_gain_correction} -eq 1 ]]
then
    cat<<PREPROC>>preprocess_${fmt_idx}.sh
        -GainReferenceFile ${gainref_fn} \\
        -CameraDefectFile ${defects_fn} \\
        -RotationAndFlip -1 \\
        -ImagesAreBinned 1.0 \\
PREPROC
fi

if [[ ${do_refinement} -eq 1 ]]
then
    cat<<PREPROC>>preprocess_${fmt_idx}.sh
        -RefineAlignment ${refine_iterations} \\
        -RefineRadius2 ${refine_radius2} \\
        -StopIterationsAtShift ${refine_shift_stop} \\
PREPROC
fi

if [[ -n ${extra_opts} ]]
then
    cat<<PREPROC>>preprocess_${fmt_idx}.sh
        ${extra_opts} \\
PREPROC
fi

    cat<<PREPROC>>preprocess_${fmt_idx}.sh
        -OutputImageFile ${ts}/${ts}_aligned.st | \\
    tee ${ts}/alignframes/${ts}_aligned.out
    newstack \\
        -ReorderByTiltAngle 1 \\
        -UseMdocFiles \\
        ${ts}/${ts}_aligned.st \\
        ${ts}/${ts}_aligned.st
    rm ${ts}/${ts}_aligned.st\~ ${ts}/${ts}_aligned.st.mdoc\~
fi

if [[ ! -f ${ts}/${ts}_dose-filt.st ]]
then
    ${alignframes_exe} \\
        -MetadataFile ${ts}/${mdoc_fn} \\
        -AdjustAndWriteMdoc \\
        -PathToFramesInMdoc ${frame_dir} \\
        -PairwiseFrames -1 \\
        -AlignAndSumBinning 1,${sum_bin} \\
        -TotalScalingOfData ${scale} \\
        -TestBinnings ${align_bin} \\
        -VaryFilter ${filter_radius2} \\
        -FilterSigma2 ${filter_sigma2} \\
        -ShiftLimit ${shift_limit} \\
        -TransformExtension dose-filt.xf \\
        -FRCOutputFile ${ts}/alignframes/${ts}_dose-filt_FRC.txt \\
        -PlottableShiftFile ${ts}/alignframes/${ts}_dose-filt_plot.txt \\
        -DebugOutput 3 \\
        -PixelSize ${apix_nm} \\
        -FixedTotalDose ${dose_per_tilt} \\
PREPROC

if [[ ${do_gain_correction} -eq 1 ]]
then
    cat<<PREPROC>>preprocess_${fmt_idx}.sh
        -GainReferenceFile ${gainref_fn} \\
        -CameraDefectFile ${defects_fn} \\
        -RotationAndFlip -1 \\
        -ImagesAreBinned 1.0 \\
PREPROC
fi

if [[ ${do_refinement} -eq 1 ]]
then
    cat<<PREPROC>>preprocess_${fmt_idx}.sh
        -RefineAlignment ${refine_iterations} \\
        -RefineRadius2 ${refine_radius2} \\
        -StopIterationsAtShift ${refine_shift_stop} \\
PREPROC
fi

if [[ -n ${extra_opts} ]]
then
    cat<<PREPROC>>preprocess_${fmt_idx}.sh
        ${extra_opts} \\
PREPROC
fi

    cat<<PREPROC>>preprocess_${fmt_idx}.sh
        -OutputImageFile ${ts}/${ts}_dose-filt.st | \\
    tee ${ts}/alignframes/${ts}_dose-filt.out

    newstack \\
        -ReorderByTiltAngle 1 \\
        -UseMdocFiles \\
        ${ts}/${ts}_dose-filt.st \\
        ${ts}/${ts}_dose-filt.st
    rm ${ts}/${ts}_dose-filt.st\~ ${ts}/${ts}_dose-filt.st.mdoc\~
fi

if [[ ${do_ctffind4} -eq 1 && ! -f ${ts}/ctffind4/${ts}_output.ctf ]]
then
    if [[ ! -f ${ts}/${ts}_aligned.mrc ]]
    then
        ln -sv ${ts}_aligned.st ${ts}/${ts}_aligned.mrc
    fi

    ${ctffind_exe}<<CTFFINDCARD
${ts}/${ts}_aligned.mrc
no
${ts}/ctffind4/${ts}_output.ctf
${apix}
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
CTFFINDCARD

    nz=\$(header -size ${ts}/${ts}_aligned.mrc | awk '{print \$3}')
    mz=\$((nz / 2 + 1))
    def_avg=\$(grep "^\${mz}" ${ts}/ctffind4/${ts}_output.txt | \\
       awk '{ printf("%d", (\$2 + \$3) / 2) }')
    def_lo=\$((def_avg - 5000))
    def_hi=\$((def_avg + 5000))

    ${ctffind_exe}<<CTFFINDCARD
${ts}/${ts}_aligned.mrc
no
${ts}/ctffind4/${ts}_output.ctf
${apix}
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
CTFFINDCARD

    rm ${ts}/${ts}_aligned.mrc
fi

if [[ ${do_gctf} -eq 1 && ! -f ${ts}/gctf/${ts}_output.ctf ]]
then
    newstack \\
        -NumberedFromOne \\
        -SplitStartingNumber 1 \\
        ${ts}/${ts}_aligned.st \\
        ${ts}/gctf/${ts}_aligned
    num_tilts=\$(ls ${ts}/gctf/${ts}_aligned.[0-9]* | wc -l)
    for tilt_idx in \$(seq 1 \${num_tilts})
    do
        if [[ \${num_tilts} -le 10 ]]
        then
            fmt_tilt_idx=\${tilt_idx}
        elif [[ \${num_tilts} -le 100 ]]
        then
            fmt_tilt_idx=\$(printf "%02d" \${tilt_idx})
        else
            fmt_tilt_idx=\$(printf "%02d" \${tilt_idx})
        fi
        mv ${ts}/gctf/${ts}_aligned.\${fmt_tilt_idx} \\
            ${ts}/gctf/${ts}_aligned_\${fmt_tilt_idx}.mrc
    done
    ${gctf_exe} \\
        --apix ${apix} \\
        --ac ${ac} \\
        --kV ${voltage_kev} \\
        --defH ${max_def} \\
        --defS ${def_step} \\
        --astm ${astigmatism} \\
        --resL ${min_res} \\
        --resH ${max_res} \\
        --boxsize ${tile_size} \\
        --do_EPA \\
        ${ts}/gctf/${ts}_aligned_*.mrc
    echo \${num_tilts} > ${ts}/gctf/${ts}_output_filein.txt
    for tilt_idx in \$(seq 1 \${num_tilts})
    do
        if [[ \${num_tilts} -le 10 ]]
        then
            fmt_tilt_idx=\${tilt_idx}
        elif [[ \${num_tilts} -le 100 ]]
        then
            fmt_tilt_idx=\$(printf "%02d" \${tilt_idx})
        else
            fmt_tilt_idx=\$(printf "%02d" \${tilt_idx})
        fi
        echo ${ts}/gctf/${ts}_aligned_\${fmt_tilt_idx}.ctf >> \\
            ${ts}/gctf/${ts}_output_filein.txt
        echo 0 >> ${ts}/gctf/${ts}_output_filein.txt
    done
    newstack -filein ${ts}/gctf/${ts}_output_filein.txt \\
        ${ts}/gctf/${ts}_output.ctf
    rm ${ts}/gctf/${ts}_output_filein.txt
    cat ${ts}/gctf/${ts}_aligned_*_EPA.log > ${ts}/gctf/${ts}_aligned_EPA.log
    rm ${ts}/gctf/${ts}_aligned_*_EPA.log
    cat ${ts}/gctf/${ts}_aligned_*_gctf.log > ${ts}/gctf/${ts}_aligned_gctf.log
    rm ${ts}/gctf/${ts}_aligned_*_gctf.log
    rm ${ts}/gctf/${ts}_aligned_*.ctf
    rm ${ts}/gctf/${ts}_aligned_*.mrc
    mv micrographs_all_gctf.star ${ts}/gctf/${ts}_output.star
fi

if [[ ${do_ctfplotter} -eq 1 && ! -f ${ts}/ctfplotter/${ts}_output.txt ]]
then
    extracttilts ${ts}/${ts}_aligned.st ${ts}/ctfplotter/${ts}_aligned.rawtlt
    asf_def_lo=$(echo '' | awk -vrl=${min_res_ctfplotter} -vpx=${apix} '{
        printf("%f", px/rl)}')

    asf_def_hi=$(echo '' | awk -vrh=${max_res_ctfplotter} -vpx=${apix} '{
        printf("%f", px/rh)}')

    expected_defocus=\$(grep Target Defocus ${ts}/${ts}_aligned.st.mdoc | \\
        head -n 1 | awk '{ printf("%f", \$3 * -1000) }')

    int_volt=$(printf "%.0f" ${voltage_kev})
    ctfplotter \\
        -InputStack ${ts}/${ts}_aligned.st \\
        -AngleFile ${ts}/ctfplotter/${ts}_aligned.rawtlt \\
        -AxisAngle ${tilt_axis_angle} \\
        -DefocusFile ${ts}/ctfplotter/${ts}_output.txt \\
        -PixelSize ${apix_nm} \\
        -Voltage \${int_volt} \\
        -SphericalAberration ${cs} \\
        -AmplitudeContrast ${ac} \\
        -ExpectedDefocus \${expected_defocus} \\
        -AutoFitRangeAndStep 0,0 \\
        -FrequencyRangeToFit \${asf_def_lo},\${asf_def_hi} \\
        -VaryExponentInFit \\
        -BaselineFittingOrder 4 \\
        -TileSize ${tile_size} \\
        -FindAstigPhaseCuton 1,0,0 \\
        -SaveAndExit
fi
PREPROC

    if [[ ${run_local} -eq 1 ]]
    then
        chmod u+x preprocess_${fmt_idx}.sh
        #./preprocess_${fmt_idx}.sh
    else
        :
        #qsub preprocess_${fmt_idx}.sh
    fi
done
