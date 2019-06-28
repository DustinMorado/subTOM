==================
subtom_reconstruct
==================

This is a run script for the reconstruction and possibly also CTF correction
processing of electron cryo-tomograhpy data by means of the program novaCTF.

This script is meant to run on a local workstation but can also submit some of
the processing to the cluster so that data can be preprocessed in parallel.
However, note that the read/write density of operations in novaCTF is
extremely large and therefore care should be taken to not overload systems, or
be prepared to have a very slow connection to your filesystem.

-------
Options
-------

Directories
-----------

scratch_dir
  Absolute path to the folder with the input to be processed.
  Other paths are relative to this one.

Executables
-----------

novactf_exe
  Absolute path to the novaCTF executable.

newstack_exe
  Absolute path to the IMOD newstack executable. The directory of this will be
  used for the other IMOD programs used in the processing.

exec_dir
  Directory for subTOM executables.

Memory Options
--------------

mem_free
  The amount of memory the job requires for alignment. This variable determines
  whether a number of CPUs will be requested to be dedicated for each job. At
  24G, one half of the CPUs on a node will be dedicated for each of the
  processes (12 CPUs). At 48G, all of the CPUs on the node will be dedicated for
  each of the processes (24 CPUs).

mem_max
  The upper bound on the amount of memory the alignment job is allowed to use.
  If any of the processes request or require more memory than this, the queue
  will kill the process. This is more of an option for safety of the cluster to
  prevent the user from crashing the cluster requesting too much memory.

num_threads
  Set this value to the number of jobs you want to run in the background before
  reconstruction. Should be the number of threads on the local system or cluster
  which for our system is 24 on the cluster and higher on the local systems, but
  there you should be polite!

Other Cluster Options
---------------------

run_local
  If the user wants to skip the cluster and run the job locally, this value
  should be set to 1.

File Options
------------

tomo_fmt
  The format string for the datasets to process. The string XXXIDXXXX will be
  replaced with the numbers specified between the range start_idx and end_idx.

tomo_dir_fmt
  The format string for the directory of datasets to process. The string
  XXXIDXXXX will be replaced with the numbers specified between the range
  start_idx and end_idx.

start_idx
  The first tomogram to operate on.

end_idx
  The last tomogram to operate on.

idx_fmt
  The format string for the tomogram indexes. Likely two or three digit zero
  padding or maybe just flat integers.

do_rotate_tomo
  Set this value to 1 if you want to use trimvol or clip rotx to rotate the
  tomogram from the PERPENDICULAR XZ generated tomograms to the standard XY
  PARALLEL orientation. Set this value to 0 if you want to skip this step which
  greatly speeds up processing and reduces the memory footprint, but at the cost
  of easy visualization of the tomogram.

do_trimvol
  Set this value to 1 if you want to use "trimvol -rx" to flip the tomograms to
  the XY standard orientation from the XZ generated tomograms. Otherwise "clip
  rotx" will be used since it is much faster.

Nova CTF Options
----------------

do_ctf
  Set this value to 1 if you want to do 3D-CTF correction during the
  reconstruction of the tomograms. If this value is set to 0 NovaCTF will still
  be used but it will generate tomograms largely identical to IMOD's WBP.

correction_type
  Type of CTF correction to perform.

defocus_file_format
  File format for the defocus list. Use ctffind4 for CTFFIND4, imod for
  CTFPLOTTER and gctf for Gctf.

defocus_file
  Where the defocus list file is located. The string XXXIDXXXX will be replaced
  with the formatted tomogram index, i.e. XXXIDXXXX_output.txt will be turned
  into 01_output.txt.

pixel_size
  The pixel size of the tilt series in nanometers. *Note NANOMETERS!*

defocus_step
  The strip size in nanometers to perform CTF correction in novaCTF refer to the
  paper for more information on this value and sensible defaults.

correct_astigmatism
  Do you want to correct astigmatism 1 for yes 0 for no.

defocus_shift_file
  If you want to shift the defocus for some reason away from the center of the
  mass of the tomogram provide a defocus_shifts file with the shifts. See the
  paper for more information on this value. If you do not want to use this
  option leave the value "".

amplitude_contrast
  The amplitude contrast for CTF correction.

cs
  The spherical aberration of the microscope in mm for CTF correction.

voltage
  The voltage in KeV of the microscope for CTF correction.

do_radial
  Set this value to 1 if you want to radial filter the projections before
  reconstruction. This corresponds to the W (weighted) in WBP, which is commonly
  what you want to do, however if you want to only back-project without the
  weighting set this value to 0.

radial_cutoff
  The parameters of RADIAL from the tilt manpage in IMOD that describes the
  radial filter used to weight before back-projection.

radial_falloff
  The parameters of RADIAL from the tilt manpage in IMOD that describes the
  radial filter used to weight before back-projection.

IMOD Options
------------

erase_radius
  The radius in pixels to erase when removing the gold fiducials from the
  aligned tilt-series stacks. Be careful that the value you give is appropriate
  for the unbinned aligned stack, which may be different than the value used in
  eTomo on the binned version.

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    novactf_exe="$(which novaCTF)"

    newstack_exe="$(which newstack)"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    mem_free="1G"

    mem_max="64G"

    num_threads=1

    run_local=0

    tomo_fmt="TS_XXXIDXXXX_dose-filt"

    tomo_dir_fmt="TS_XXXIDXXXX"

    start_idx=1

    end_idx=1

    idx_fmt="%02d"

    do_rotate_vol=1

    do_trimvol=0

    do_ctf=1

    correction_type="multiplication"

    defocus_file_format="imod"

    defocus_file="ctfplotter/TS_XXXIDXXXX_output.txt"

    pixel_size=0.1

    defocus_step=15

    correct_astigmatism=1

    defocus_shift_file=""

    amplitude_contrast=0.07

    cs=2.7

    voltage=300

    do_radial=1

    radial_cutoff=0.35

    radial_falloff=0.035

    erase_radius=32
