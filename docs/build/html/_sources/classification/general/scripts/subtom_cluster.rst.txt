==============
subtom_cluster
==============

Clusters a motive-list using pre-calculated and supplied coefficients and
outputs a classified motive-list and class averages.

This subtomogram classification script uses three MATLAB compiled scripts
below:

- :doc:`../functions/subtom_cluster`
- :doc:`../functions/subtom_parallel_sums_cls`
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

cluster_exec
  Cluster executable.

sum_exec
  Parallel Summing executable

avg_exec
  Final Averaging executable

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

Parallelization Options
-----------------------

iteration
  The index of the references to generate : input will be
  all_motl_fn_prefix_iteration.em (define as integer e.g. iteration=1)

num_avg_batch
  The number of batches to split the parallel subtomogram averaging job into.

Subtomogram Classification Workflow Options
===========================================

Coefficient File Options
-----------------------------

coeff_all_motl_fn_prefix
  Relative path and name of the concatenated motivelist to cluster and classify.

coeff_fn_prefix
  Relative path and name of the coefficients.

Clustering Options
------------------

cluster_type
  The following determines which algorithm will be used to cluster the
  determined Eigencoefficients. The valid options are K-means clustering,
  'kmeans', Hierarchical Ascendent Clustering using a Ward Criterion, 'hac', and
  a Gaussian Mixture Model, 'gaussmix'.

coeff_idxs
  Determines which coefficients are used to cluster. The format should be a
  semicolon-separated list that also supports ranges with a dash (-), for
  example 1-5;7;15-19 would select the first five coefficients, the seventh and
  the fifteenth through the nineteenth for classification. If it is left as
  "all" all coefficients will be used.

num_classes
  How many classes should the particles be clustered into.

Clustering File Options
-----------------------

cluster_all_motl_fn_prefix
  Relative path and name of the concatenated motivelist of the output classified
  particles.

Averaging File Options
----------------------

ref_fn_prefix
  Relative path and name prefix of the reference volumes (e.g.  ref_iter.em, the
  variable will be written as a string e.g.  ref_fn_prefix='sub-directory/ref')

weight_sum_fn_prefix
  Relative path and name prefix of the partial weight files.

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    local_dir=""

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="XXXINSTALLATION_DIRXXX/bin"

    cluster_exec="${exec_dir}/classification/pca/subtom_cluster"

    sum_exec="${exec_dir}/classification/pca/subtom_parallel_sums"

    avg_exec="${exec_dir}/classification/pca/subtom_weighted_average"

    mem_free="1G"

    mem_max="64G"

    job_name="subTOM"

    array_max="1000"

    max_jobs="4000"

    run_local="0"

    skip_local_copy="1"

    iteration="1"

    num_avg_batch="1"

    coeff_all_motl_fn_prefix="combinedmotl/allmotl"

    coeff_fn_prefix="class/coeffs"

    cluster_type="kmeans"

    eig_idxs="all"

    num_classes=2

    cluster_all_motl_fn_prefix="class/allmotl_class"

    ref_fn_prefix="class/ref"

    weight_sum_fn_prefix="class/wei"
