========================
subtom_join_eigenvolumes
========================

Computes the final sum of projections of the data onto Eigenvectors.

.. code-block:: Matlab

    subtom_join_eigenvolumes(
        'eig_vol_fn_prefix', eig_vol_fn_prefix ('class/eigvol_pca'),
        'iteration', iteration (1),
        'num_eigs', num_eigs (40),
        'num_xmatrix_batch', num_xmatrix_batch (1))

Calculates the sum of previously calculated Eigenvolume partial sums,
(projections onto previously determined Eigen (or left singular) vectors),
which can then be used to determine which vectors can best influence
classification. The Eigenvolumes are expected to have been split into
NUM_XMATRIX_BATCH sums.  The output averages will be written out as given by
EIG_VOL_FN_PREFIX, ITERATION and #, where the # is the particular
Eigenvolume being written out from 1 to NUM_EIGS. For easier viewing a
montage of the Eigenvolumes is made along the X, Y, and Z axes, written
out as specified by EIG_VOL_FN_PREFIX, (X,Y,Z) and ITERATION.

-------
Example
-------

.. code-block:: Matlab

    subtom_join_eigenvolumes(...
        'eig_vol_fn_prefix', 'class/eigvol', ...
        'iteration', 1, ...
        'num_eigs', 40, ...
        'num_xmatrix_batch', 100)

--------
See Also
--------

* :doc:`subtom_eigs`
* :doc:`subtom_join_ccmatrix`
* :doc:`subtom_join_eigencoeffs_pca`
* :doc:`subtom_parallel_ccmatrix`
* :doc:`subtom_parallel_eigencoeffs_pca`
* :doc:`subtom_parallel_eigenvolumes`
* :doc:`subtom_parallel_xmatrix_pca`
* :doc:`subtom_prepare_ccmatrix`
* :doc:`subtom_svds`
