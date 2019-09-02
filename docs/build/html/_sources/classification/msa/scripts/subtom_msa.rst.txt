==========
subtom_msa
==========

The main MSA pipeline process script of subTOM.

This subtomogram classification script uses nine MATLAB compiled scripts
below:

- :doc:`../../general/functions/subtom_parallel_prealign`
- :doc:`../functions/subtom_parallel_xmatrix_msa`
- :doc:`../functions/subtom_join_xmatrix`
- :doc:`../functions/subtom_eigenvolumes_msa`
- :doc:`../functions/subtom_parallel_eigencoeffs_msa`
- :doc:`../functions/subtom_join_eigencoeffs_msa`
- :doc:`../../general/functions/subtom_cluster`
- :doc:`../../general/functions/subtom_parallel_sums_cls`
- :doc:`../../general/functions/subtom_weighted_average_cls`

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

par_eigcoeff_exec
  Parallel Eigencoefficient executable.

eigcoeff_exec
  Final Eigencoefficient executable.

eigvol_exec
  Eigenvolume Calculation executable.

preali_exec
  Parallel Subtomogram prealign executable.

par_xmatrix_exec
  Parallel X-Matrix executable.

xmatrix_exec
  Final X-Matrix executable.

sum_exec
  Parallel Summing executable

avg_exec
  Final Averaging executable

motl_dump_exec
  MOTL dump executable

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

num_xmatrix_prealign_batch
  Number of batches to split the parallel particle prealignment for the
  X-Matrix calculation into. If you are not doing prealignment you can ignore
  this option.

num_xmatrix_batch
  Number of batches to split the parallel X-Matrix calculation job into.

num_eig_coeff_prealign_batch
  Number of batches to split the parallel particle prealignment for the
  Eigencoefficients calculations into. If you are not doing prealignment you can
  ignore this option.

num_eig_coeff_batch
  Number of batches to split the parallel Eigencoefficient calculation into.

num_avg_batch
  The number of batches to split the parallel subtomogram averaging job into.

Subtomogram Classification Workflow Options
===========================================

X-Matrix Options
-----------------

high_pass_fp
  High pass filter cutoff (in transform units (pixels): calculate as (box_size *
  pixelsize) / (resolution_real) (define as integer).

high_pass_sigma
  High pass filter falloff sigma (in transform units (pixels): describes a
  Gaussian sigma for the falloff of the high-pass filter past the cutoff above.

low_pass_fp
  Low pass filter (in transform units (pixels): calculate as (box_size *
  pixelsize) / (resolution_real) (define as integer).

low_pass_sigma
  Low pass filter falloff sigma (in transform units (pixels): describes a
  Gaussian sigma for the falloff of the low-pass filter past the cutoff above.

nfold
  Symmetry to apply to each pair of particle and reference in X-Matrix
  calculation, if no symmetry nfold=1 (define as integer e.g. nfold=3).

xmatrix_prealign
  If you want to pre-align all of the particles to speed up the X-Matrix
  calculation, set the following to 1, otherwise the particles will be aligned
  during the computation.

X-Matrix File Options
----------------------

xmatrix_all_motl_fn_prefix
  Relative path and name of the concatenated motivelist of all particles (e.g.
  allmotl_iter.em , the variable will be written as a string e.g.
  xmatrix_all_motl_fn_prefix='sub-directory/allmotl').

xmatrix_fn_prefix
  Relative path and name of the X-Matrix.

ptcl_fn_prefix
  Relative path and name of the subtomograms (e.g. part_n.em , the variable will
  be written as a string e.g. ptcl_fn_prefix='sub-directory/part').

mask_fn
  Relative path and name of the classification mask. This should be a binary
  mask as correlations are done in real-space, and calculations will only be
  done using voxels passed by the mask, so smaller masks will run faster. If you
  want to use the default spherical mask set mask_fn to 'none'.

Eigenvolumes Options
--------------------

num_eigs
  The number of Eigenvectors and Eigenvalues to calculate.

eigs_iterations
  The following allows you to adjust the number of iterations to use in the
  decomposition. If you want to use the default number of iterations leave this
  set to 'default'.

eigs_tolerance
  The following allows you to adjust the convergence tolerance of the
  decomposition calculation. If you want to use the default tolerance leave this
  set to 'default'.

Eigenvolumes File Options
-------------------------

eig_vec_fn_prefix
  Relative path and name of the Eigenvectors.

eig_val_fn_prefix
  Relative path and name of the Eigenvalues.

eig_vol_fn_prefix
  Relative path and name of the Eigenvolumes.

Eigencoefficient Options
------------------------

apply_weight
  If the following is set to 1, the Eigenvolume will have the particles
  missing-wedge weight applied to it before the correlation is calculated.

tomo_row
  Which row in the motl file contains the correct tomogram number.
  Usually row 5 and 7 both correspond to the correct value and can be used
  interchangeably, but there are instances when 5 contains a sequential ordered
  value starting from 1, while 7 contains the correct corresponding tomogram.

eig_coeff_prealign
  If you want to pre-align all of the particles to speed up the Eigencoefficient
  calculation, set the following to 1, otherwise the particles will be aligned
  during the computation.

Eigencoefficient File Options
-----------------------------

eig_coeff_all_motl_fn_prefix
  Relative path and name of the concatenated motivelist to project onto the
  Eigenvolumes. This can be a larger motivelist than the one used to calculate
  the X-Matrix and Eigenvolumes.

eig_coeff_fn_prefix
  Relative path and name of the Eigencoefficients.

weight_fn_prefix
  Relative path and name of the weight file, if you are not applying the weight
  to the Eigenvolumes this can be left alone.

Clustering Options
------------------

cluster_type
  The following determines which algorithm will be used to cluster the
  determined Eigencoefficients. The valid options are K-means clustering,
  'kmeans', Hierarchical Ascendent Clustering using a Ward Criterion, 'hac', and
  a Gaussian Mixture Model, 'gaussmix'.

eig_idxs
  Determines which Eigencoefficients are used to cluster. The format should be a
  semicolon-separated list that also supports ranges with a dash (-), for
  example 1-5;7;15-19 would select the first five Eigencoefficients, the seventh
  and the fifteenth through the nineteenth for classification. If it is left as
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

    cluster_exec="${exec_dir}/classification/general/subtom_cluster"

    par_eigcoeff_exec="${exec_dir}/classification/msa/subtom_parallel_eigencoeffs_msa"

    eigcoeff_exec="${exec_dir}/classification/msa/subtom_join_eigencoeffs_msa"

    eigvol_exec="${exec_dir}/classification/msa/subtom_eigenvolumes_msa"

    preali_exec="${exec_dir}/classification/general/subtom_parallel_prealign"

    par_xmatrix_exec="${exec_dir}/classification/msa/subtom_parallel_xmatrix_msa"

    xmatrix_exec="${exec_dir}/classification/msa/subtom_join_xmatrix"

    sum_exec="${exec_dir}/classification/general/subtom_parallel_sums_cls"

    avg_exec="${exec_dir}/classification/general/subtom_weighted_average_cls"

    motl_dump_exec="${exec_dir}/MOTL/motl_dump"

    mem_free="1G"

    mem_max="64G"

    job_name="subTOM"

    array_max="1000"

    max_jobs="4000"

    run_local="0"

    skip_local_copy="1"

    iteration="1"

    num_xmatrix_prealign_batch="1"

    num_xmatrix_batch="1"

    num_eig_coeff_prealign_batch="1"

    num_eig_coeff_batch="1"

    num_avg_batch="1"

    high_pass_fp="1"

    high_pass_sigma="2"

    low_pass_fp="12"

    low_pass_sigma="3"

    nfold="1"

    xmatrix_prealign=0

    xmatrix_all_motl_fn_prefix="combinedmotl/allmotl"

    xmatrix_fn_prefix="class/xmatrix_msa"

    ptcl_fn_prefix="subtomograms/subtomo"

    mask_fn="none"

    num_eigs='40'

    eigs_iterations='default'

    eigs_tolerance='default'

    eig_vec_fn_prefix="class/eigvec_msa"

    eig_val_fn_prefix="class/eigval_msa"

    eig_vol_fn_prefix="class/eigvol_msa"

    apply_weight="0"

    tomo_row="7"

    eig_coeff_prealign="0"

    eig_coeff_all_motl_fn_prefix="combinedmotl/allmotl"

    eig_coeff_fn_prefix="class/eigcoeff_msa"

    weight_fn_prefix="otherinputs/ampspec"

    cluster_type="kmeans"

    eig_idxs="all"

    num_classes=2

    cluster_all_motl_fn_prefix="class/allmotl_msa"

    ref_fn_prefix="class/ref_msa"

    weight_sum_fn_prefix="class/wei_msa"
