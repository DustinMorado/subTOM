=================
subtom_preprocess
=================

Aligns dose-fractionated data, sorts and stacks aligned frames, determines the
defocus of the tilt-series using CTFFIND4, GCTF, or IMOD CTFPLOTTER and then
dose-filters the tilt-series in prepartion for alignment using IMOD/eTomo.

-------
Options
-------

Directories
-----------

scratch_dir
  Absolute path to the folder with the input to be processed.
  Other paths are relative to this one.

frame_dir
  Relative path to the folder where the dose-fractionated movie frames are
  located.

Executables
-----------

alignframes_exe
  Absolute path to the IMOD alignframes executable. The directory of this will
  be used for the other IMOD programs used in the processing. Need version at
  least above 4.10.29

ctffind_exe
  Absolute path to the CTFFIND4 executable. Needs version at least above 4.1.13.

gctf_exe
  Absolute path to the GCTF executable. I wouldn't use it because it rarely
  works but it seems a version of 1.06 sometimes doesn't crash.

exec_dir
  Directory for subTOM executables

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

Other Cluster Options
---------------------

job_name
  The job name prefix that will be used for the cluster submission scripts, log
  files, and error logs for the processing. Be careful that this name is unique
  because previous submission scripts, logs, and error logs with the same job
  name prefix will be overwritten in the case of a name collision.

run_local
  If the user wants to skip the cluster and run the job locally, this value
  should be set to 1.

File Options
------------

ts_fmt
  The format string for the datasets to process. The string XXXIDXXXX will be
  replaced with the numbers specified between the range start_idx and end_idx.
 
  The raw sum tilt-series will have the name format ts_fmt.st, or ts_fmt.mrc, an
  extended data file ts_fmt.{mrc,st}.mdoc and could possibly have an associated
  log ts_fmt.log.
 
  Dose-fractionated movies of tilt-images are assumed to have the name format:
  ts_fmt_###_*.{mrc,tif} where ### is a running three-digit ID number for the
  tilt-image and * is the tilt-angle.

start_idx
  The first tilt-series to operate on.

end_idx
  The last tilt-series to operate on.

idx_fmt
  The format string for the tomogram indexes. Likely two or three digit zero
  padding or maybe just flat integers.

Beam Induced Motion Correction Options
--------------------------------------

do_aligned
  If you want to run alignframes to generate the non-dose-weighted tiltseries
  set this option to 1 and if you want to skip this step set this option to 0.

do_doseweight
  If you want to run alignframes to generate the dose-weighted tiltseries set
  this option to 1 and if you want to skip this step set this option to 0.

do_gain_correction
  Determines whether or not gain-correction needs to be done on the frames. Set
  to 1 to apply gain-correction during motion-correction, and 0 to skip it.
  Normally TIFF format frames will be saved with compression and will be
  unnormalized, and should be gain-corrected. MRC format frames are generally
  already saved with gain-correction applied during collection, so it can be
  skipped here.
 
  A good rule of thumb, is if you have a dm4 file in your data you need to do
  gain-correction, and if you don't see a dm4 file you do not.

gainref_fn
  The path to the gain-reference file, this will only be used if gain_correction
  is going to be applied.

defects_fn
  The path to the defects file, this is saved along with the gain-reference for
  unnormalized saved frames by SerialEM, and will only be used if
  gain-correction is going to be applied.

align_bin
  Binning to apply to the frames when calculating the alignment, if you are
  using super-resolution you may want to change this to 2. The defaults from
  IMOD would be 3 for counted data and 6 for super-resolution data. Multiple
  binnings can be tested and the best one will be used to generate the final
  sum.

sum_bin
  Binning to apply to the final sum. This is done using Fourier cropping as in
  MotionCorr and other similar programs. If you are using super-resolution you
  probably want to change this to 2, otherwise it should be set to 1.

scale
  Amount of scaling to apply to summed values before output. The default is 30
  however serialEM applies one of 39.3?

filter_radius2
  Cutoff Frequency for the lowpass filter used in frame alignment. The unit is
  absolute spatial frequency which goes from 0 to 0.5 relative to the pixelsize
  of the input frames (not considering binning applied in alignment). The
  default from IMOD is 0.06. Multiple radii can be used and the best filter will
  be selected for the actually used alignment.

filter_sigma2
  Falloff for the lowpass filter used in frame alignment. Same units as above.
  The defaults from IMOD is 0.0086.

shift_limit
  Limit on distance to search for correlation peak in unbinned pixels. The
  default from IMOD is 20.

do_refinement
  If this is set to 1, alignframes will do an iterative refinement of the
  initially found frame alignment solution. The default in IMOD is to not do
  this refinement.

refine_iterations
  The maximum number of refinement iterations to run.

refine_radius2
  Cutoff Frequency for the lowpass filter used in refinement. The default in
  IMOD would be to use the same value used in alignment.

refine_shift_stop
  The amount of shift at which refinement will stop in unbinned pixels.

truncate_above
  Movies often contain hot pixels not removed from the pixel-defect mask either
  from x-rays or other factors and these throw off the later scaling of sums.
  Traditionally they would be removed in eTomo using the ccderaser command /
  step, but it has been found to go better to truncate them at the
  frame-alignment and summing step. To find a reasonable value to truncate above
  use the command 'clip stats' on several movies to find out where the values
  start to become outliers, it should be around 5-7 for 10 frame movies of about
  3e/A^2 on the K2.

use_gpu
  If you want to use a GPU set this to 1, but be careful to not use both the
  cluster and the GPU as this is not supported.

extra_opts
  If you want to use other options to alignframes specify them here.

CTF Estimation Options
----------------------

apix
  The pixel size of the raw movie frames if they exist, or the pixelsize of the
  "_aligned.st" stack if alignframes and dose-weighting is not being done. The
  actual pixelsize used in CTF estimation is apix * sum_bin.

do_ctffind4
  If this is set to 1, the defocus will be estimated with CTFFIND4.

do_gctf
  If this is set to 1, the defocus will be estimated with GCTF.

do_ctfplotter
  If this is set to 1, the defocus will be estimated with CTFPLOTTER.

voltage_kev
  The accelerating voltage of the microscope in KeV.

cs
  The spherical aberration of the microscope in mm.

ac
  The amount of amplitude contrast in the imaging system.

tile_size
  The size of tile to operate on.

min_res
  The lowest wavelength in Angstroms to allow in fitting (minimum resolution).

max_res
  The highest wavelength in Angstroms to allow in fitting (maximum resolution).

min_res_ctfplotter
  The lowest wavelength in Angstroms to allow in fitting in CTFPLOTTER.

max_res_ctfplotter
  The highest wavelength in Angstroms to allow in fitting in CTFPLOTTER.

min_def
  The lowest defocus in Angstroms to scan.

max_def
  The highest defocus in Angstroms to scan.

def_step
  The step size in Angstroms to scan defocus.

astigmatism
  The amount of astigmatism to allow in Angstroms.

tilt_axis_angle
  The tilt-axis angle of the tilt series. This is only needed if you are
  estimating the CTF with ctfplotter. You can find this value running the
  command 'header' on the raw sum tiltseries and looking at the first label
  (Titles) in the header.

Dose Filtering Options
----------------------

dose_per_tilt
  The dose per micrograph in Electrons per square Angstrom.

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    frame_dir="Frames"

    alignframes_exe="$(which alignframes)"

    ctffind_exe="$(which ctffind)"

    gctf_exe="$(which Gctf)"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    mem_free="1G"

    mem_max="64G"

    job_name="subTOM"

    run_local=1

    ts_fmt="TS_XXXIDXXXX"

    start_idx=1

    end_idx=1

    idx_fmt="%02d"

    do_aligned=1

    do_doseweight=1

    do_gain_correction=1

    gainref_fn="Frames/gainref.dm4"

    defects_fn="Frames/defects.txt"

    align_bin=1,2,3

    sum_bin=1

    scale=39.3

    filter_radius2=0.167,0.125,0.10,0.06

    filter_sigma2=0.0086

    shift_limit=20

    do_refinement=1

    refine_iterations=5

    refine_radius2=0.167

    refine_shift_stop=0.1

    truncate_above=7

    use_gpu=0

    extra_opts=''

    apix=1

    do_ctffind4=1

    do_gctf=0

    do_ctfplotter=1

    voltage_kev=300.0

    cs=2.7

    ac=0.07

    tile_size=512

    min_res=30.0

    max_res=5.0

    min_res_ctfplotter=50.0

    max_res_ctfplotter=10.0

    min_def=10000.0

    max_def=60000.0

    def_step=100.0

    astigmatism=1000.0

    tilt_axis_angle=85.3

    dose_per_tilt=3.5
