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
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the folder with the input to be processed.
# Other paths are relative to this one.
scratch_dir="${PWD}"

# Relative path to the folder where the dose-fractionated movie frames are
# located.
frame_dir="Frames"

################################################################################
#                                 EXECUTABLES                                  #
################################################################################
# Absolute path to the IMOD alignframes executable. The directory of this will
# be used for the other IMOD programs used in the processing. Need version at
# least above 4.10.29
#alignframes_exe=$(which alignframes) # If you have alignframes in your path.
alignframes_exe="$(which alignframes)"

# Absolute path to the CTFFIND4 executable. Needs version at least above 4.1.13.
#ctffind_exe=${bstore1}/../LMB/software/ctffind/ctffind.exe
#ctffind_exe=$(which ctffind.exe)
ctffind_exe="$(which ctffind)"

# Absolute path to the GCTF executable. I wouldn't use it because it rarely
# works but it seems a version of 1.06 sometimes doesn't crash.
gctf_exe="$(which Gctf)"

# Directory for subTOM executables
exec_dir="XXXINSTALLATION_DIRXXX/bin"

################################################################################
#                                MEMORY OPTIONS                                #
################################################################################
# The amount of memory your job requires
# e.g. mem_free='2G'
mem_free="1G"

# The upper bound on the amount of memory your job is allowed to use
# e.g. mem_max_ali='3G'
mem_max="64G"

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
# tilt-image and * is the tilt-angle.
#ts_fmt=XXXIDXXXX
#ts_fmt=ts_XXXIDXXXX
ts_fmt="TS_XXXIDXXXX"

# The first tilt-series to operate on.
start_idx=1

# The last tilt-series to operate on.
end_idx=1

# The format string for the tomogram indexes. Likely two or three digit zero
# padding or maybe just flat integers.
# no padding flat integer e.g. 1
#idx_fmt="%d"
# two digit zero padding e.g. 01
idx_fmt="%02d"
# three digit zero padding e.g. 001
#idx_fmt="%03d"

################################################################################
#                                                                              #
#                    BEAM INDUCED MOTION CORRECTION OPTIONS                    #
#                                                                              #
################################################################################
# If you want to run alignframes to generate the non-dose-weighted tiltseries
# set this option to 1 and if you want to skip this step set this option to 0.
do_aligned=1

# If you want to run alignframes to generate the dose-weighted tiltseries set
# this option to 1 and if you want to skip this step set this option to 0.
do_doseweight=1

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
gainref_fn="Frames/gainref.dm4"

# The path to the defects file, this is saved along with the gain-reference for
# unnormalized saved frames by SerialEM, and will only be used if
# gain-correction is going to be applied.
defects_fn="Frames/defects.txt"

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

# Movies often contain hot pixels not removed from the pixel-defect mask either
# from x-rays or other factors and these throw off the later scaling of sums.
# Traditionally they would be removed in eTomo using the ccderaser command /
# step, but it has been found to go better to truncate them at the
# frame-alignment and summing step. To find a reasonable value to truncate above
# use the command 'clip stats' on several movies to find out where the values
# start to become outliers, it should be around 5-7 for 10 frame movies of about
# 3e/A^2 on the K2.
truncate_above=7

# If you want to use other options to alignframes specify them here.
extra_opts=''

################################################################################
#                                                                              #
#                            CTF ESTIMATION OPTIONS                            #
#                                                                              #
################################################################################
# The pixel size of the motion-corrected tilt-series in Angstroms.
apix=1

# If this is set to 1, the defocus will be estimated with CTFFIND4.
do_ctffind4=1

# If this is set to 1, the defocus will be estimated with GCTF.
do_gctf=0

# If this is set to 1, the defocus will be estimated with CTFPLOTTER.
do_ctfplotter=1

# The accelerating voltage of the microscope in KeV.
voltage_kev=300.0

# The spherical aberration of the microscope in mm.
cs=2.7

# The amount of amplitude contrast in the imaging system.
ac=0.07

# The size of tile to operate on.
tile_size=512

# The lowest wavelength in Angstroms to allow in fitting (minimum resolution).
min_res=30.0

# The highest wavelength in Angstroms to allow in fitting (maximum resolution).
max_res=5.0

# The lowest wavelength in Angstroms to allow in fitting in CTFPLOTTER.
min_res_ctfplotter=30.0

# The highest wavelength in Angstroms to allow in fitting in CTFPLOTTER.
max_res_ctfplotter=5.0

# The lowest defocus in Angstroms to scan.
min_def=10000.0

# The highest defocus in Angstroms to scan.
max_def=60000.0

# The step size in Angstroms to scan defocus.
def_step=100.0

# The amount of astigmatism to allow in Angstroms.
astigmatism=1000.0

# The tilt-axis angle of the tilt series. This is only needed if you are
# estimating the CTF with ctfplotter. You can find this value running the
# command 'header' on the raw sum tiltseries and looking at the first label
# (Titles) in the header.
tilt_axis_angle=85.3

################################################################################
#                                                                              #
#                            DOSE FILTERING OPTIONS                            #
#                                                                              #
################################################################################
# The dose per micrograph in Electrons per square Angstrom.
dose_per_tilt=3.5

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    ${exec_dir}/scripts/subtom_preprocess.sh "$(realpath $0)"
else
    echo "Options sourced!"
fi
