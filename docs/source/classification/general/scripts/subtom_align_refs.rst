=================
subtom_align_refs
=================

Aligns the class averages from a given MOTL file and then applies the found
rotations to class particles and re-averages the classes and all particle
average in parallel on the cluster or locally.

This subtomogram alignment and averaging script uses five MATLAB compiled
scripts below:

- :doc:`../functions/subtom_scan_angles_exact_refs`
- :doc:`../../../functions/subtom_parallel_sums`
- :doc:`../functions/subtom_parallel_sums_cls`
- :doc:`../../../functions/subtom_weighted_average`
- :doc:`../functions/subtom_weighted_average_cls`

-------
Options
-------

Directories
-----------

scratch_dir
  Absolute path to the folder with the input to be processed.
  Other paths are relative to this one.

local_dir
  Absolute path to the folder on a group share, if the scratch directory is
  cleaned and deleted regularly this can set a local directory to which the
  important results will be copied. If this is not needed it can be skipped with
  the option skip_local_copy below.

mcr_cache_dir
  Absolute path to MCR directory for the processing.

exec_dir
  Directory for executables

Variables
---------

align_exec
  Alignment executable

sum_exec
  Parallel Summing executable

avg_exec
  Weighted Averaging executable

sum_cls_exec
  Class Average Parallel Summing executable

avg_cls_exec
  Class Average Final Averaging executable

motl_dump_exec
  MOTL dump executable

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

array_max
  The maximum number of jobs per cluster submission script. Cluster submission
  scripts work using the array feature common to queuing systems, and this value
  is the maximum array size used in a script. If the user requests more batches
  of processing than this value, then the submission scripts will be split into
  files of up to array_max jobs.

max_jobs
  The maximum number of jobs for alignment. If the number of batches / exceeds
  this value the script will immediately quit.

run_local
  If the user wants to skip the cluster and run the job locally, this value
  should be set to 1.

skip_local_copy
  Set this option to 1 to skip the copying of data to local_dir.

Subtomogram Averaging Workflow Options
--------------------------------------

Parallelization Options
-----------------------

iteration
  The index of the reference to generate : input will be
  all_motl_fn_prefix_iteration.em (define as integer)

num_avg_batch
  The number of batches to split the parallel subtomogram averaging job into.

File Options
------------

all_motl_fn_prefix
  Relative path and name of the concatenated motivelist of all particles (e.g.
  allmotl_iter.em , the variable will be written as a string e.g.
  all_motl_fn_prefix='sub-directory/allmotl')

output_motl_fn_prefix
  Relative path and name prefix of the output motivelist of all particles. There
  will be two versions written out. The first with "_classed_" will retain the
  iclass values to generate new aligned class averages. The second with
  "_unclassed_" will set all particles iclass to 1 to generate a cumulative
  class average.

ref_fn_prefix
  Relative path and name of the reference volumes (e.g. ref_iter.em , the
  variable will be written as a string e.g. ref_fn_prefix='sub-directory/ref')

ptcl_fn_prefix
  Relative path and name of the subtomograms (e.g. part_n.em , the variable will
  be written as a string e.g. ptcl_fn_prefix='sub-directory/part')

align_mask_fn
  Relative path and name of the alignment mask. If "none" is given a default
  spherical mask will be used. (e.g.  align_mask_fn='otherinputs/align_mask.em')

cc_mask_fn
  Relative path and name of the cross-correlation mask this defines the maximum
  shifts in each direction. If "noshift" is given no shifts are allowed. (e.g.
  cc_mask_fn='otherinputs/cc_mask_1.em')

weight_fn_prefix
  Relative path and name of the weight file.

weight_sum_fn_prefix
  Relative path and name of the partial weight files.

Alignment and Averaging Options
-------------------------------

tomo_row
  Which row in the motl file contains the correct tomogram number.
  Usually row 5 and 7 both correspond to the correct value and can be used
  interchangeably, but there are instances when 5 contains a sequential ordered
  value starting from 1, while 7 contains the correct corresponding tomogram.

ref_class
  Which class average to align the other class averages against. Because of the
  AV3 specification for iclass this should be a number that is 3 or above. 

apply_mask
  Apply mask to class averages (1=yes, 0=no)

psi_angle_step
  Angular increment in degrees, applied during the cone-search, i.e. psi and
  theta (define as real e.g. psi_angle_step=3)

psi_angle_shells
  Number of angular iterations, applied to psi and theta  (define as integer
  e.g. psi_angle_shells=3)

phi_angle_step
  Angular increment for phi in degrees, (define as real e.g. phi_angle_step=3)

phi_angle_shells
  Number of angular iterations for phi, (define as integer e.g.
  phi_angle_shells=3)

high_pass_fp
  High pass filter cutoff (in transform units (pixels): calculate as
  (box_size*pixelsize)/(resolution_real) (define as integer e.g. high_pass_fp=2)

high_pass_sigma
  High pass filter falloff sigma (in transform units (pixels): describes a
  Gaussian sigma for the falloff of the high-pass filter past the cutoff above.

low_pass_fp
  Low pass filter (in transform units (pixels): calculate as
  (box_size*pixelsize)/(resolution_real) (define as integer e.g.
  low_pass_fp=30).

low_pass_sigma
  Low pass filter falloff sigma (in transform units (pixels): describes a
  Gaussian sigma for the falloff of the low-pass filter past the cutoff above.

nfold
  Symmetry, if no symmetry nfold=1 (define as integer e.g. nfold=3)

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    local_dir=""

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    sum_exec="${exec_dir}/alignment/subtom_parallel_sums"

    avg_exec="${exec_dir}/alignment/subtom_weighted_average"

    sum_exec="${exec_dir}/classification/general/subtom_parallel_sums_cls"

    avg_exec="${exec_dir}/classification/general/subtom_weighted_average_cls"

    mem_free=1G

    mem_max=64G

    job_name=subTOM

    array_max=1000

    max_jobs=4000

    run_local=0

    skip_local_copy=1

    iteration=1

    num_avg_batch=1

    all_motl_fn_prefix="combinedmotl/allmotl"

    output_motl_fn_prefix="combinedmotl/allmotl"

    ref_fn_prefix="ref/ref"

    ptcl_fn_prefix="subtomograms/subtomo"

    align_mask_fn="otherinputs/align_mask.em"

    cc_mask_fn="otherinputs/cc_mask.em"

    weight_fn_prefix="otherinputs/ampspec"

    weight_sum_fn_prefix="otherinputs/wei"

    tomo_row=7

    ref_class=3

    apply_mask=0

    psi_angle_step=1

    psi_angle_step=6

    phi_angle_step=1

    phi_angle_shells=10

    high_pass_fp=1

    high_pass_sigma=2

    low_pass_fp=10

    low_pass_sigma=3

    nfold=1
