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

# Absolute path to MCR directory for the processing.
mcr_cache_dir=${scratch_dir}/mcr

# Directory for executables
exec_dir=XXXINSTALLATION_DIRXXX/bin

################################################################################
#                                 EXECUTABLES                                  #
################################################################################
# Absolute path to the IMOD alignframes executable. The directory of this will
# be used for the other IMOD programs used in the processing.
#alignframes_exe=${bstore1}../LMB/software/imod_4.10.10_RHEL7-64_CUDA8.0/IMOD/bin/alignframes
#alignframes_exe=$(which alignframes) # If you have alignframes in your path.
alignframes_exe=<ALIGNFRAMES_EXE>

# Absolute path to the CTFFIND4 executable.
#ctffind_exe=${bstore1}/../LMB/software/ctffind/ctffind.exe
#ctffind_exe=$(which ctffind.exe)
ctffind_exe=<CTFFIND_EXE>

# Absolute path to the dose-filtering executable
dose_filt_exec=${exec_dir}/dose_filter_tiltseries

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
# The raw sum tilt-series will have the name format ts_fmt.st, and could
# possibly have an associated log ts_fmt.log and an extended data file
# ts_fmt.st.mdoc
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
# Determines the type of file for the dose-fractionated movie tilt-images. Set
# to 1 to look for TIFF format frames, and 0 to default to MRC format frames.
tiff_frames=1

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
# IMOD would be 3 for counted data and 6 for super-resolution data.
align_bin=1

# Binning to apply to the final sum. This is done using Fourier cropping as in
# MotionCorr and other similar programs. If you are using super-resolution you
# probably want to change this to 2, otherwise it should be set to 1.
sum_bin=1

# Cutoff Frequency for the lowpass filter used in frame alignment. The unit is
# absolute spatial frequency which goes from 0 to 0.5 relative to the pixelsize
# of the input frames (not considering binning applied in alignment). The
# default from IMOD is 0.06.
filter_radius2=0.125

# Falloff for the lowpass filter used in frame alignment. Same units as above.
# The defaults from IMOD is 0.0086.
filter_sigma2=0.1429

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

################################################################################
#                                                                              #
#                            DOSE FILTERING OPTIONS                            #
#                                                                              #
################################################################################
# The dose per micrograph in Electrons per square Angstrom
dose_rate=<DOSE_RATE>

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
cd ${scratch_dir}

imod_exe_dir=$(dirname ${alignframes_exe})

if [[ ! -d ${mcr_cache_dir} ]]
then
    mkdir -p ${mcr_cache_dir}
fi

for idx in $(seq ${start_idx} ${end_idx})
do
    fmt_idx=$(printf ${idx_fmt} ${idx})
    ts=${ts_fmt/XXXIDXXXX/${fmt_idx}}

    # Skip series that do not exist
    set +e
    ls ${frame_dir} | grep -q "${ts}"
    has_frames=$?
    if [[ ${has_frames} -ne 0 ]]
    then
        echo "Did not find frames for ${ts}! SKIPPING!"
        continue
    fi
    set -e 

    if [[ ${tiff_frames} -eq 1 ]]
    then
        frame_suffix=tif
        frame_fmt=${ts}_???_*.tif
        test_frame=$(ls ${frame_dir}/${ts}_001_*.tif)
    else
        frame_suffix=mrc
        frame_fmt=${ts}_???_*0.mrc
        test_frame=$(ls ${frame_dir}/${ts}_001_*0.mrc)
    fi

    nimg=$(ls ${frame_dir}/${frame_fmt} | wc -l)
    dose_field=$(echo ${test_frame} | grep -o '_' | wc -l)
    angle_field=$((dose_field + 1))

    if [[ ! -d ${ts} ]]
    then
        mkdir ${ts}
    fi

    if [[ -f ${ts}.st ]]
    then
        mv -n ${ts}.st ${ts}/.
    fi

    if [[ -f ${ts}.st.mdoc ]]
    then
        mv -n ${ts}.st.mdoc ${ts}/.
    fi

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
for frame in ${frame_dir}/${frame_fmt}
do
    output_frame=\${frame/%\\.${frame_suffix}/_aligned.mrc}
    if [[ -f \${output_frame} || -f ${ts}/${ts}_aligned.st ]]
    then
        continue
    fi
    
    ${alignframes_exe} \\
        -InputFile \${frame} \\
        -PairwiseFrames -1 \\
        -AlignAndSumBinning ${align_bin},${sum_bin} \\
        -FilterRadius2 ${filter_radius2} \\
        -FilterSigma2 ${filter_sigma2} \\
        -ShiftLimit ${shift_limit} \\
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

    if [[ -z ${extra_opts//} ]]
    then
        cat<<PREPROC>>preprocess_${fmt_idx}.sh
        ${extra_opts} \\
PREPROC
    fi

    cat<<PREPROC>>preprocess_${fmt_idx}.sh
        -OutputImageFile \${output_frame}
done

if [[ ! -f ${ts}/${ts}_aligned.st ]]
then
    find ${frame_dir} -name "${ts}_???_*_aligned.mrc" | \\
    sort -t_ -n -k ${angle_field},${angle_field} | \\
    awk -v nimg=${nimg} '
        BEGIN {
            print nimg;
        }
        {
            printf("%s\\n0\\n", \$0);
        }
    ' > ${ts}_filelistin.txt
    ${imod_exe_dir}/newstack -q -filein ${ts}_filelistin.txt \\
        -output ${ts}/${ts}_aligned.st
    rm ${ts}_filelistin.txt
fi

if [[ ! -f ${ts}/${ts}_dose-filt.rawtlt ]]
then
    find ${frame_dir} -name "${frame_fmt}" | \\
    xargs -n 1 -I {} basename {} .${frame_suffix} | \\
    sort -t_ -n -k ${angle_field},${angle_field} | \\
    awk -F_ -v field=${angle_field} '
        {
            tilt_angle = \$field + 0.0;
            printf("%f\n", tilt_angle);
        }
    ' > ${ts}/${ts}_dose-filt.rawtlt
fi

if [[ ! -f ${ts}/${ts}_dose_list.csv ]]
then
    find ${frame_dir} -name "${frame_fmt}" | \\
    sort -t_ -n -k ${dose_field},${dose_field} | \\
    awk -F_ -v dose_rate=${dose_rate} -v field=${angle_field} '
        BEGIN {
            dose = 0.0;
        }
        {
            printf("%d\t%f\n", \$field + 0, dose);
            dose += dose_rate;
        }
    ' |\\
    sort -n -k1,1 |\\
    cut -f 2 > ${ts}/${ts}_dose_list.csv
fi

if [[ -f \$(ls ${frame_dir}/${ts}_001_*_aligned.mrc) ]]
then
    rm ${frame_dir}/${ts}_???_*_aligned.mrc
fi

if [[ ! -f ${ts}/${ts}_output.ctf ]]
then
    ln -sv ${ts}_aligned.st ${ts}/${ts}_aligned.mrc
    ${ctffind_exe}<<CTFFINDCARD
${ts}/${ts}_aligned.mrc
no
${ts}/${ts}_output.ctf
${apix}
300.0
2.70
0.07
512
50.0
4.0
10000.0
80000.0
500.0
no
yes
yes
1000.0
no
no
CTFFINDCARD
    rm ${ts}/${ts}_aligned.mrc
fi

if [[ ! -f ${ts}/${ts}_dose-filt.st ]]
then
    ldpath=XXXMCR_DIRXXX/runtime/glnxa64
    ldpath=\${ldpath}:XXXMCR_DIRXXX/bin/glnxa64
    ldpath=\${ldpath}:XXXMCR_DIRXXX/sys/os/glnxa64
    ldpath=\${ldpath}:XXXMCR_DIRXXX/sys/opengl/lib/glnxa64
    export LD_LIBRARY_PATH=\${ldpath}
    mcr_cache_dir=${mcr_cache_dir}/dose_filter_${fmt_idx}
    if [[ ! -d \${mcr_cache_dir} ]]
    then
        mkdir -p \${mcr_cache_dir}
    else
        rm -rf \${mcr_cache_dir}
        mkdir -p \${mcr_cache_dir}
    fi
    export MCR_CACHE_ROOT=\${mcr_cache_dir}
    time ${dose_filt_exec} \\
        ${ts}/${ts}_aligned.st \\
        ${ts}/${ts}_dose-filt.st \\
        ${ts}/${ts}_dose_list.csv
    rm -rf \${mcr_cache_dir}
fi
PREPROC

    if [[ ${run_local} -eq 1 ]]
    then
        chmod u+x preprocess_${fmt_idx}.sh
        ./preprocess_${fmt_idx}.sh
    else
        qsub preprocess_${fmt_idx}.sh
    fi
done
