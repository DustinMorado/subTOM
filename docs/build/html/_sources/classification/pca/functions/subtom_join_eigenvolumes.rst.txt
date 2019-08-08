========================
subtom_join_eigenvolumes
========================

Computes the final sum of projections of the data onto Eigenvectors.

.. code-block:: Matlab

    subtom_join_eigenvolumes(
        'eig_vec_fn_prefix', eig_vec_fn_prefix ('pca/eigvec'),
        'eig_vol_fn_prefix', eig_vol_fn_prefix ('pca/eigvol'),
        'mask_fn', mask_fn ('none'),
        'iteration', iteration (1),
        'num_xmatrix_batch', num_xmatrix_batch (1))

Calculates the sum of previously calculated Eigenvolume partial sums,
(projections onto previously determined Eigen (or left singular) vectors), which
can then be used to determine which vectors can best influence classification.
The Eigenvectors are named ``eig_vec_fn_prefix`` _ ``iteration``.em and are used
just to determine the number of particles to reweight the average.  The
previously calculated X-matrix weights are specified by
``xmatrix_weight_fn_prefix`` are used to reweight the output Eigenvolumes for
the missing wedge and other effects. The Eigenvolumes are also masked by the
file given in ``mask_fn``. The Eigenvolumes are expected to have been split into
``num_xmatrix_batch`` sums.  The output averages will be written out as
``eig_vol_fn_prefix`` _ ``iteration`` _#.em. where the # is the particular
Eigenvolume being written out. For easier viewing a montage of the Eigenvolumes
is made along the X, Y, and Z axes, written out as
``eig_vol_fn_prefix`` _(X,Y,Z)_ ``iteration``.em

-------
Example
-------

.. code-block:: Matlab

    subtom_join_eigenvolumes(...
        'eig_vec_fn_prefix', 'pca/eigvec', ...
        'eig_vol_fn_prefix', 'pca/eigvol', ...
        'mask_fn', 'otherinputs/classification_mask.em', ...
        'iteration', 1, ...
        'num_xmatrix_batch', 100)

--------
See Also
--------

* :doc:`subtom_cluster`
* :doc:`subtom_eigs`
* :doc:`subtom_join_ccmatrix`
* :doc:`subtom_join_eigencoeffs`
* :doc:`subtom_parallel_ccmatrix`
* :doc:`subtom_parallel_eigencoeffs`
* :doc:`subtom_parallel_eigenvolumes`
* :doc:`subtom_parallel_prealign`
* :doc:`subtom_parallel_sums`
* :doc:`subtom_parallel_xmatrix`
* :doc:`subtom_prepare_ccmatrix`
* :doc:`subtom_svds`
* :doc:`subtom_weighted_average`
