================
subtom_alignment
================

The main pipeline process script of subTOM. Iteratively aligns and averages a
collection of subvolumes.

This subtomogram alignment script uses five MATLAB compiled scripts below:

- :doc:`../functions/subtom_scan_angles_exact`
- :doc:`../functions/subtom_cat_motls`
- :doc:`../functions/subtom_parallel_sums`
- :doc:`../functions/subtom_weighted_average`
- :doc:`../functions/subtom_compare_motls`

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

cat_exec
  Concatenate MOTLs executable

sum_exec
  Parallel Summing executable

avg_exec
  Weighted Averaging executable

compare_exec
  Compare MOTLs executable

Memory Options
--------------

mem_free_ali
  The amount of memory the job requires for alignment. This variable determines
  whether a number of CPUs will be requested to be dedicated for each job. At
  24G, one half of the CPUs on a node will be dedicated for each of the
  processes (12 CPUs). At 48G, all of the CPUs on the node will be dedicated for
  each of the processes (24 CPUs).

mem_max_ali
  The upper bound on the amount of memory the alignment job is allowed to use.
  If any of the processes request or require more memory than this, the queue
  will kill the process. This is more of an option for safety of the cluster to
  prevent the user from crashing the cluster requesting too much memory.

mem_free_avg
  The amount of memory the job requires for averaging.

mem_max_avg
  The upper bound on the amount of memory the averaging job is allowed to use.

OTHER CLUSTER OPTIONS
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

Subtomogram Alignment Workflow Options
--------------------------------------

Parallelization Options
-----------------------

start_iteration
  The index of the reference to start from : input will be
  ref_fn_prefix_start_iteration.em and all_motl_fn_prefix_start_iteration.em
  (define as integer e.g.  start_iteration=3)
 
  More on iterations since they're confusing and it is slightly different here
  than from previous iterations.
 
  The start_iteration is the beginning for the iteration variable used
  throughout this script. Iteration refers to iteration that is used for
  subtomogram alignment. So if start_iteration is 1, then subtomogram alignment
  will work using allmotl_1.em and ref_1.em. The output from alignment will be
  particle motls for the next iteration. This in the script is avg_iteration
  variable. The particle motls will be joined to form allmotl_2.em and then the
  parallel averaging will form ref_2.em and then the loop is done and iteration
  will become 2 and avg_iteration will become 3.

iterations
  Number iterations (big loop) to run: final output will be
  ref_fn_prefix_start_iteration+iterations.em and
  all_motl_fn_prefix_start_iteration+iterations.em

num_ali_batch
  The number of batches to split the parallel subtomogram alignment job into.

num_avg_batch
  The number of batches to split the parallel subtomogram averaging job into.

File Options
------------

all_motl_fn_prefix
  Relative path and name of the concatenated motivelist of all particles (e.g.
  allmotl_iter.em , the variable will be written as a string e.g.
  all_motl_fn_prefix='sub-directory/allmotl')

ref_fn_prefix
  Relative path and name of the reference volumes (e.g. ref_iter.em , the
  variable will be written as a string e.g. ref_fn_prefix='sub-directory/ref')

ptcl_fn_prefix
  Relative path and name of the subtomograms (e.g. part_n.em , the variable will
  be written as a string e.g. ptcl_fn_prefix='sub-directory/part')

align_mask_fn
  Relative path and name of the alignment mask
  Leave the parentheses and if the number of values is less than the number of
  iterations the last value will be repeated to the correct length.

cc_mask_fn
  Relative path and name of the cross-correlation mask this defines the maximum
  shifts in each direction
  Leave the parentheses and if the number of values is less than the number of
  iterations the last value will be repeated to the correct length.

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

apply_weight
  Apply weight to subtomograms (1=yes, 0=no).

apply_mask
  Apply mask to subtomograms (1=yes, 0=no).

psi_angle_step
  Angular increment in degrees, applied during the cone-search, i.e. psi and
  theta (define as real e.g. psi_angle_step=3).
  Leave the parentheses and if the number of values is less than the number of
  iterations the last value will be repeated to the correct length.

psi_angle_shells
  Number of angular iterations, applied to psi and theta  (define as integer
  e.g. psi_angle_shells=4). Note that in terms of cones this is twice the number
  of cones sampled.
  Leave the parentheses and if the number of values is less than the number of
  iterations the last value will be repeated to the correct length.

phi_angle_step
  Angular increment for phi in degrees, (define as real e.g. phi_angle_step=3).
  Leave the parentheses and if the number of values is less than the number of
  iterations the last value will be repeated to the correct length.

phi_angle_shells
  Number of angular iterations for phi, (define as integer e.g.
  phi_angle_shells=6).
  Leave the parentheses and if the number of values is less than the number of
  iterations the last value will be repeated to the correct length.

high_pass_fp
  High pass filter cutoff (in transform units (pixels): calculate as (boxsize *
  pixelsize) / (resolution_real) (define as integer).
  Leave the parentheses and if the number of values is less than the number of
  iterations the last value will be repeated to the correct length.

high_pass_sigma
  High pass filter falloff sigma (in transform units (pixels): describes a
  Gaussian sigma for the falloff of the high-pass filter past the cutoff above.
  Leave the parentheses and if the number of values is less than the number of
  iterations the last value will be repeated to the correct length.

low_pass_fp
  Low pass filter (in transform units (pixels): calculate as (boxsize *
  pixelsize) / (resolution_real) (define as integer).
  Leave the parentheses and if the number of values is less than the number of
  iterations the last value will be repeated to the correct length.

low_pass_sigma
  Low pass filter falloff sigma (in transform units (pixels): describes a
  Gaussian sigma for the falloff of the low-pass filter past the cutoff above.
  Leave the parentheses and if the number of values is less than the number of
  iterations the last value will be repeated to the correct length.

nfold
  Symmetry, if no symmetry nfold=1 (define as integer e.g. nfold=3).
  Leave the parentheses and if the number of values is less than the number of
  iterations the last value will be repeated to the correct length.

threshold
  Threshold for cross correlation coefficient. Only particles with ccc_new >
  threshold will be added to new average (define as real e.g. threshold=0.5).
  These particles will still be aligned at each iteration.

iclass
  Particles with that number in position 20 of motivelist will be added to new
  average (define as integer e.g. iclass=1). NOTES: Class 1 is ALWAYS added.
  Negative classes and class 2 are never added.

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    local_dir=""

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    align_exec="${exec_dir}/alignment/subtom_scan_angles_exact"

    cat_exec="${exec_dir}/MOTL/subtom_cat_motls"

    sum_exec="${exec_dir}/alignment/subtom_parallel_sums"

    avg_exec="${exec_dir}/alignment/subtom_weighted_average"

    compare_exec="${exec_dir}/MOTL/subtom_compare_motls"

    mem_free_ali=1G

    mem_max_ali=64G

    mem_free_avg=1G

    mem_max_avg=64G

    job_name=subTOM

    array_max=1000

    max_jobs=4000

    run_local=0

    skip_local_copy=1

    start_iteration=1

    iterations=3

    num_ali_batch=1

    num_avg_batch=1

    all_motl_fn_prefix="combinedmotl/allmotl"

    ref_fn_prefix="ref/ref"

    ptcl_fn_prefix="subtomograms/subtomo"

    align_mask_fn=("otherinputs/align_mask_1.em" \
                   "otherinputs/align_mask_2.em" \
                   "otherinputs/align_mask_3.em")

    cc_mask_fn=("otherinputs/cc_mask_r10.em" \
                "otherinputs/cc_mask_r05.em")

    weight_fn_prefix="otherinputs/ampspec"

    weight_sum_fn_prefix="otherinputs/wei"

    tomo_row=7

    apply_weight=0

    apply_mask=1

    psi_angle_step=(10 5 2.5)

    psi_angle_shells=(4)

    phi_angle_step=(20 5)

    phi_angle_shells=(6)

    high_pass_fp=(1)

    high_pass_sigma=(2)

    low_pass_fp=(12 15 18)

    low_pass_sigma=(3)

    nfold=(1 6)

    threshold=-1

    iclass=0
