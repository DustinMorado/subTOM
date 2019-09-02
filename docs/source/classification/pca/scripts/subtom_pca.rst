==========
subtom_pca
==========

The main PCA pipeline process script of subTOM.

This subtomogram classification script uses fourteen MATLAB compiled scripts
below:

- :doc:`../../general/functions/subtom_parallel_prealign`
- :doc:`../functions/subtom_prepare_ccmatrix`
- :doc:`../functions/subtom_parallel_ccmatrix`
- :doc:`../functions/subtom_join_ccmatrix`
- :doc:`../functions/subtom_eigs`
- :doc:`../functions/subtom_svds`
- :doc:`../functions/subtom_parallel_xmatrix_pca`
- :doc:`../functions/subtom_parallel_eigenvolumes`
- :doc:`../functions/subtom_join_eigenvolumes`
- :doc:`../functions/subtom_parallel_eigencoeffs_pca`
- :doc:`../functions/subtom_join_eigencoeffs_pca`
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

eig_exec
  Eigendecomposition executable.

pre_ccmatrix_exec
  Prepare CC-Matrix executable.

par_ccmatrix_exec
  Parallel CC-Matrix executable.

ccmatrix_exec
  Final CC-Matrix executable.

par_eigcoeff_exec
  Parallel Eigencoefficient executable.

eigcoeff_exec
  Final Eigencoefficient executable.

par_eigvol_exec
  Parallel Eigenvolume executable.

eigvol_exec
  Final Eigenvolume executable.

preali_exec
  Parallel Subtomogram prealign executable.

xmatrix_exec
  Parallel X-Matrix executable.

svds_exec
  Singular Value Decomposition executable.

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

num_ccmatrix_prealign_batch
  Number of batches to split the parallel particle prealignment for the
  CC-Matrix calculation into. If you are not doing prealignment you can ignore
  this option.

num_ccmatrix_batch
  Number of batches to split the parallel CC-Matrix calculation job into.

num_xmatrix_batch
  Number of batches to split the parallel X-Matrix calculation job into. This
  also determines the number of batches the Eigenvolumes calculation will be
  split into.

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

CC-Matrix Options
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
  Symmetry to apply to each pair of particle and reference in CC-Matrix
  calculation, if no symmetry ccmatrix_nfold=1 (define as integer e.g.
  ccmatrix_nfold=3)

tomo_row
  Which row in the motl file contains the correct tomogram number.
  Usually row 5 and 7 both correspond to the correct value and can be used
  interchangeably, but there are instances when 5 contains a sequential ordered
  value starting from 1, while 7 contains the correct corresponding tomogram.

ccmatrix_prealign
  If you want to pre-align all of the particles to speed up the CC-Matrix
  calculation, set the following to 1, otherwise the particles will be aligned
  during the computation.

CC-Matrix File Options
----------------------

ccmatrix_all_motl_fn_prefix
  Relative path and name of the concatenated motivelist of all particles (e.g.
  allmotl_iter.em , the variable will be written as a string e.g.
  ccmatrix_all_motl_fn_prefix='sub-directory/allmotl').

ptcl_fn_prefix
  Relative path and name of the subtomograms (e.g. part_n.em , the variable will
  be written as a string e.g. ptcl_fn_prefix='sub-directory/part').

mask_fn
  Relative path and name of the classification mask. This should be a binary
  mask as correlations are done in real-space, and calculations will only be
  done using voxels passed by the mask, so smaller masks will run faster. If you
  want to use the default spherical mask set mask_fn to 'none'.

weight_fn_prefix
  Relative path and name of the weight file.

ccmatrix_fn_prefix
  Relative path and name of the CC-Matrix.

Eigendecomposition Options
--------------------------

decomp_type
  The following determines which type of decomposition to perform. If the
  following is 'eigs', then traditional Eigenvalue decomposition will be
  calculated and either the largest magnitude or largest algebraic Eigenvalues
  will be returned, however in the CC-Matrix calculation the Eigenvalues can be
  negative which can be problematic in later stages of processing, and so 'svds'
  can also be given and Singular Value Decomposition will calculated instead.

num_eigs
  The number of Eigenvectors and Eigenvalues (or Left Singular Vectors and
  Singular Values) to calculate.

eigs_iterations
  If using 'eigs' the following allows you to adjust the number of iterations to
  use in the decomposition. If you want to use the default number of iterations
  leave this set to 'default'.

eigs_tolerance
  If using 'eigs' the following allows you to adjust the convergence tolerance
  of the decomposition calculation. If you want to use the default tolerance
  leave this set to 'default'.

do_algebraic
  If using 'eigs' the following allows you to calculate the largest algebraic
  Eigenvalues, which are guaranteed to be positive but not guaranteed to be the
  largest in magnitude. This is in contrast to the default behavior of
  calculating the largest magnitude Eigenvalues that are not guaranteed to be
  non-negative.

svds_iterations
  If using 'svds' the following allows you to adjust the number of iterations to
  use in the decomposition. If you want to use the default number of iterations
  leave this set to 'default'.

svds_tolerance
  If using 'svds' the following allows you to adjust the convergence tolerance
  of the decomposition calculation. If you want to use the default tolerance
  leave this set to 'default'.

Eigendecomposition File Options
-------------------------------

eig_vec_fn_prefix
  Relative path and name of the Eigenvectors (or Left Singular Vectors).

eig_val_fn_prefix
  Relative path and name of the Eigenvalues (or Singular Values).

X-Matrix File Options
---------------------

xmatrix_fn_prefix
  Relative path and name of the X-Matrix.

Eigenvolumes File Options
-------------------------

eig_vol_fn_prefix
  Relative path and name of the Eigenvolumes.

Eigencoefficient Options
------------------------

apply_weight
  If the following is set to 1, the Eigenvolume (or conjugate-space Eigenvector)
  will have the particles missing-wedge weight applied to it before the
  Correlation is calculated.

eig_coeff_prealign
  If you want to pre-align all of the particles to speed up the Eigencoefficient
  calculation, set the following to 1, otherwise the particles will be aligned
  during the computation.

Eigencoefficient File Options
-----------------------------

eig_coeff_all_motl_fn_prefix
  Relative path and name of the concatenated motivelist to project onto the
  Eigenvolumes (conjugate-space Eigenvectors). This can be a larger motivelist
  than the one used to calculate the CC-Matrix and Eigenvolumes.

eig_coeff_fn_prefix
  Relative path and name of the Eigencoefficients.

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

    eigs_exec="${exec_dir}/classification/pca/subtom_eigs"

    pre_ccmatrix_exec="${exec_dir}/classification/pca/subtom_prepare_ccmatrix"

    par_ccmatrix_exec="${exec_dir}/classification/pca/subtom_parallel_ccmatrix"

    ccmatrix_exec="${exec_dir}/classification/pca/subtom_join_ccmatrix"

    par_eigcoeff_exec="${exec_dir}/classification/pca/subtom_parallel_eigencoeffs_pca"

    eigcoeff_exec="${exec_dir}/classification/pca/subtom_join_eigencoeffs_pca"

    par_eigvol_exec="${exec_dir}/classification/pca/subtom_parallel_eigenvolumes"

    eigvol_exec="${exec_dir}/classification/pca/subtom_join_eigenvolumes"

    preali_exec="${exec_dir}/classification/general/subtom_parallel_prealign"

    xmatrix_exec="${exec_dir}/classification/pca/subtom_parallel_xmatrix_pca"

    svds_exec="${exec_dir}/classification/pca/subtom_svds"

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

    num_ccmatrix_prealign_batch="1"

    num_ccmatrix_batch="1"

    num_xmatrix_batch="1"

    num_eig_coeff_prealign_batch="1"

    num_eig_coeff_batch="1"

    num_avg_batch="1"

    high_pass_fp="0"

    high_pass_sigma="2"

    low_pass_fp="0"

    low_pass_sigma="3"

    nfold="1"

    tomo_row="7"

    ccmatrix_prealign=0

    ccmatrix_all_motl_fn_prefix="combinedmotl/allmotl"

    ptcl_fn_prefix="subtomograms/subtomo"

    mask_fn="none"

    weight_fn_prefix="otherinputs/ampspec"

    ccmatrix_fn_prefix="class/ccmatrix_pca"

    decomp_type='svds'

    num_eigs='40'

    eigs_iterations='default'

    eigs_tolerance='default'

    do_algebraic=0

    svds_iterations='default'

    svds_tolerance='default'

    eig_vec_fn_prefix="class/eigvec_pca"

    eig_val_fn_prefix="class/eigval_pca"

    xmatrix_fn_prefix="class/xmatrix_pca"

    eig_vol_fn_prefix="class/eigvol_pca"

    apply_weight="0"

    eig_coeff_prealign="0"

    eig_coeff_all_motl_fn_prefix="combinedmotl/allmotl"

    eig_coeff_fn_prefix="class/eigcoeff_pca"

    cluster_type="kmeans"

    eig_idxs="all"

    num_classes=2

    cluster_all_motl_fn_prefix="class/allmotl_pca"

    ref_fn_prefix="class/ref_pca"

    weight_sum_fn_prefix="class/wei_pca"
