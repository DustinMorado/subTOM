============================
subtom_parallel_eigenvolumes
============================

Computes projections of data onto Eigenvectors.

.. code-block:: Matlab

    subtom_parallel_eigenvolumes(
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'ptcl_fn_prefix', ptcl_fn_prefix ('subtomograms/subtomo'),
        'eig_vec_fn_prefix', eig_vec_fn_prefix ('class/eigvec_pca'),
        'eig_val_fn_prefix', eig_val_fn_prefix ('class/eigval_pca'),
        'xmatrix_fn_prefix', xmatrix_fn_prefix ('class/xmatrix_pca'),
        'eig_vol_fn_prefix', eig_vol_fn_prefix ('class/eigvol_pca'),
        'mask_fn', mask_fn ('none'),
        'iteration', iteration (1),
        'num_xmatrix_batch', num_xmatrix_batch (1),
        'process_idx', process_idx (1))

Calculates the summed projections of particles onto previously determined Eigen
(or left singular) vectors, by means of an also previously calculated X-matrix
to produce Eigenvolumes which can then be used to determine which vectors can
best influence classification. The Eigenvectors are named based on
``eig_vec_fn_prefix`` and ``iteration`` and the X-Matrix is named based on
``xmatrix_fn_prefix``, ``iteration``, and ``process_idx``. The Eigenvolumes are
also masked by the file specified by ``mask_fn``. The Eigenvolumes are split
into ``num_xmatrix_batch`` sums, which is the same number of batches that the
X-Matrix was broken into in its computation. ``process_idx`` is a counter that
designates the current batch being determined. The output sum Eigenvolume will
be written out as specified by ``eig_vol_fn_prefix``, ``iteration``,
``process_idx`` and # where the # is the particular Eigenvolume being written
out.

-------
Example
-------

.. code-block:: Matlab

    subtom_parallel_eigenvolumes(
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'ptcl_fn_prefix', 'subtomograms/subtomo', ...
        'eig_vec_fn_prefix', 'class/eigvec', ...
        'eig_val_fn_prefix', 'class/eigval', ...
        'xmatrix_fn_prefix', 'class/xmatrix', ...
        'eig_vol_fn_prefix', 'class/eigvol', ...
        'mask_fn', 'otherinputs/classification_mask.em', ...
        'iteration', 1, ...
        'num_xmatrix_batch', 100, ...
        'process_idx', 1)

--------
See Also
--------

* :doc:`subtom_eigs`
* :doc:`subtom_join_ccmatrix`
* :doc:`subtom_join_eigencoeffs_pca`
* :doc:`subtom_join_eigenvolumes`
* :doc:`subtom_parallel_ccmatrix`
* :doc:`subtom_parallel_eigencoeffs_pca`
* :doc:`subtom_parallel_xmatrix_pca`
* :doc:`subtom_prepare_ccmatrix`
* :doc:`subtom_svds`
