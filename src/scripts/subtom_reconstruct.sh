#!/bin/bash
################################################################################
# This is a run script for the reconstruction and possibly also CTF correction
# processing of electron cryo-tomograhpy data by means of the program novaCTF.
#
# This script is meant to run on a local workstation but can also submit some of
# the processing to the cluster so that data can be preprocessed in parallel.
# However, note that the read/write density of operations in novaCTF is
# extremely large and therefore care should be taken to not overload systems, or
# be prepared to have a very slow connection to your filesystem.
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

################################################################################
#                                 EXECUTABLES                                  #
################################################################################
# Absolute path to the novaCTF executable.
#novactf_exe="$(which novaCTF)"
novactf_exe=""

# Absolute path to the IMOD newstack executable. The directory of this will be
# used for the other IMOD programs used in the processing.
#newstack_exe="$(which newstack)"
newstack_exe=""

# Directory for subTOM executables.
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

# Set this value to the number of jobs you want to run in the background before
# reconstruction. Should be the number of threads on the local system or cluster
# which for our system is 24 on the cluster and higher on the local systems, but
# there you should be polite!
num_threads=1

################################################################################
#                              OTHER LSF OPTIONS                               #
################################################################################
# BE CAREFUL THAT THE NAME DOESN'T CORRESPOND TO THE BEGINNING OF ANY OTHER FILE
job_name="subTOM"

# If you want to skip the cluster and run the job locally set this to 1.
run_local=0

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# The format string for the datasets to process. The string XXXIDXXXX will be
# replaced with the numbers specified between the range start_idx and end_idx.
#tomo_fmt="TS_XXXIDXXXX"
#tomo_fmt="ts_XXXIDXXXX"
#tomo_fmt="ts_XXXIDXXXX_dose-filt"
#tomo_fmt="XXXIDXXXX_dose-filt"
tomo_fmt="TS_XXXIDXXXX_dose-filt"

# The format string for the directory of datasets to process. The string
# XXXIDXXXX will be replaced with the numbers specified between the range
# start_idx and end_idx.
#tomo_dir_fmt="ts_XXXIDXXXX"
#tomo_dir_fmt="XXXIDXXXX"
tomo_dir_fmt="TS_XXXIDXXXX"

# The first tomogram to operate on.
start_idx=1

# The last tomogram to operate on.
end_idx=1

# The format string for the tomogram indexes. Likely two or three digit zero
# padding or maybe just flat integers.
# two digit zero padding e.g. 01
# no padding flat integer e.g. 1
#idx_fmt="%d"
idx_fmt="%02d"
# three digit zero padding e.g. 001
#idx_fmt="%03d"

################################################################################
#                             GENERAL CTF OPTIONS                              #
################################################################################
# Where the defocus list file is located. The string XXXIDXXXX will be replaced
# with the formatted tomogram index, i.e. XXXIDXXXX_output.txt will be turned
# into 01_output.txt.
defocus_file="ctfplotter/TS_XXXIDXXXX_output.txt"

# The pixel size of the tilt series in nanometers. Note NANOMETERS!
pixel_size=0.1

# The amplitude contrast for CTF correction.
amplitude_contrast=0.07

# The spherical aberration of the microscope in mm for CTF correction.
cs=2.7

# The voltage in KeV of the microscope for CTF correction.
voltage=300

################################################################################
#                             NOVA 3D-CTF OPTIONS                              #
################################################################################
# Set this value to 1 if you want to do 3D-CTF correction during the
# reconstruction of the tomograms. If this value is set to 0 NovaCTF will still
# be used but it will generate tomograms largely identical to IMOD's WBP.
do_3dctf=1

# Type of 3D-CTF correction to perform.
#correction_type="phaseflip"
correction_type="multiplication"

# File format for the defocus list. Use ctffind4 for CTFFIND4, imod for
# CTFPLOTTER and gctf for Gctf.
#defocus_file_format="gctf"
#defocus_file_format="ctffind4"
defocus_file_format="imod"

# The strip size in nanometers to perform CTF correction in novaCTF refer to the
# paper for more information on this value and sensible defaults.
defocus_step=15

# Do you want to correct astigmatism 1 for yes 0 for no.
correct_astigmatism=1

# If you want to shift the defocus for some reason away from the center of the
# mass of the tomogram provide a defocus_shifts file with the shifts. See the
# paper for more information on this value. If you do not want to use this
# option leave the value "".
#defocus_shift_file="TS_XXXIDXXXX_defocus_shift.txt"
defocus_shift_file=""

################################################################################
#                             IMOD 2D-CTF OPTIONS                              #
################################################################################
# Set this value to 1 if you want to do 2D-CTF correction during the
# reconstruction of the tomograms. As of now if you are doing 2D-CTF correction
# only "imod" is valid as a value for "defocus_file_format".
do_2dctf=1

# If you want to shift the defocus for some reason away from the center of the
# mass of the tomogram provide the number of pixels to shift here. The sign of
# the the shift is the same as for SHIFT in IMOD's tilt.com, but depends on the
# binning of the data, whereas in tilt it is for unbinned data. Refer to the man
# page for ctfphaseflip for a more detailed description.
defocus_shift=0

# Defocus tolerance in nanometers, which is one factor that governs the width of
# the strips. The actual strip width is based on the width of this region and
# several other factors. Refer to the man page for ctfphaseflip for a more
# detailed description.
defocus_tolerance=200

# The distance in pixels between the center lines of two consecutive strips.
# Refer to the man page for ctfphaseflip for a more detailed description.
interpolation_width=20

# If you want to use a GPU set this to 1, but be careful to not use both the
# cluster and the GPU as this is not supported.
use_gpu=0

################################################################################
#                            RADIAL FILTER OPTIONS                             #
################################################################################
# Set this value to 1 if you want to radial filter the projections before
# reconstruction. This corresponds to the W (weighted) in WBP, which is commonly
# what you want to do, however if you want to only back-project without the
# weighting set this value to 0.
do_radial=1

# The parameters of RADIAL from the tilt manpage in IMOD that describes the
# radial filter used to weight before back-projection.
radial_cutoff=0.5
radial_falloff=0.0

################################################################################
#                                 IMOD OPTIONS                                 #
################################################################################
# The radius in pixels to erase when removing the gold fiducials from the
# aligned tilt-series stacks. Be careful that the value you give is appropriate
# for the unbinned aligned stack, which may be different than the value used in
# eTomo on the binned version.
erase_radius="1"

# Set this value to 1 if you want to use trimvol or clip rotx to rotate the
# tomogram from the PERPENDICULAR XZ generated tomograms to the standard XY
# PARALLEL orientation. Set this value to 0 if you want to skip this step which
# greatly speeds up processing and reduces the memory footprint, but at the cost
# of easy visualization of the tomogram.
do_rotate_tomo=1

# Set this value to 1 if you want to use "trimvol -rx" to flip the tomograms to
# the XY standard orientation from the XZ generated tomograms. Otherwise "clip
# rotx" will be used since it is much faster.
do_trimvol=0

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    ${exec_dir}/scripts/subtom_reconstruct.sh "$(realpath $0)"
else
    echo "Options sourced!"
fi
