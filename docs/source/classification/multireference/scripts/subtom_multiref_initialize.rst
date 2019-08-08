==========================
subtom_multiref_initialize
==========================

A startup processing script for multireference classification in subTOM. Splits
a given motive list into random equal classes and then generates the average of
each class.

This subtomogram averaging script uses three MATLAB compiled scripts below:

- :doc:`../functions/subtom_rand_class_motl`
- :doc:`../functions/subtom_parallel_sums`
- :doc:`../functions/subtom_weighted_average`

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

sum_exec
  Parallel Summing executable

avg_exec
  Weighted Averaging executable

rand_exec
  Randomize Motive List executable

Memory Options
--------------

mem_free
  The amount of memory the job requires. This variable determines whether a
  number of CPUs will be requested to be dedicated for each job. At 24G, one
  half of the CPUs on a node will be dedicated for each of the processes (12
  CPUs). At 48G, all of the CPUs on the node will be dedicated for each of the
  processes (24 CPUs).

mem_max
  The upper bound on the amount of memory the job is allowed to use.  If any of
  the processes request or require more memory than this, the queue will kill
  the process. This is more of an option for safety of the cluster to prevent
  the user from crashing the cluster requesting too much memory.

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
  all_motl_fn_prefix_iteration.em (define as integer e.g. iteration=1)

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

weight_fn_prefix
  Relative path and name of the weight file.

weight_sum_fn_prefix
  Relative path and name of the partial weight files.

Averaging Options
-----------------

tomo_row
  Which row in the motl file contains the correct tomogram number.
  Usually row 5 and 7 both correspond to the correct value and can be used
  interchangeably, but there are instances when 5 contains a sequential ordered
  value starting from 1, while 7 contains the correct corresponding tomogram.

num_classes
  The number of classes to split the initial motive list into. The classes will
  be assigned randomly evenly within the valid particles, (non-negative class
  values excluding class 2), with the class number starting at 3 to not
  interfere with the classes 1 and 2 which are reserved for AV3's thresholding
  process.

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    local_dir=""

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    sum_exec="${exec_dir}/classification/multiref/subtom_parallel_sums"

    avg_exec="${exec_dir}/classification/multiref/subtom_weighted_average"

    rand_exec="${exec_dir}/classification/multiref/subtom_rand_class_motl"

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

    ref_fn_prefix="ref/ref"

    ptcl_fn_prefix="subtomograms/subtomo"

    weight_fn_prefix="otherinputs/ampspec"

    weight_sum_fn_prefix="otherinputs/wei"

    tomo_row=7

    num_classes=2
