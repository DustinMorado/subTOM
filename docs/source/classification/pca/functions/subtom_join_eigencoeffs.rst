=======================
subtom_join_eigencoeffs
=======================

Randomizes a given number of classes in a motive list.

.. code-block:: Matlab

    subtom_join_eigencoeffs(
        'eig_coeff_fn_prefix', eig_coeff_fn_prefix ('pca/eigcoeff'),
        'iteration', iteration (1),
        'num_xmatrix_batch', num_xmatrix_batch (1))

Looks for partial chunks of the low-rank approximation coefficients of projected
particles with the file name ``eig_coeff_fn_prefix`` _ ``iteration`` _#.em where
# is from 1 to ``num_xmatrix_batch``, and combines them into a final matrix of
coefficients written out as ``eig_coeff_fn_prefix`` _ ``iteration``.em.

-------
Example
-------

.. code-block:: Matlab

    subtom_join_eigencoeffs(...
        'eig_coeff_fn_prefix', 'pca/eigcoeff', ...
        'iteration', 1, ...
        'num_xmatrix_batch', 100)

--------
See Also
--------

* :doc:`subtom_cluster`
* :doc:`subtom_eigs`
* :doc:`subtom_join_ccmatrix`
* :doc:`subtom_join_eigenvolumes`
* :doc:`subtom_parallel_ccmatrix`
* :doc:`subtom_parallel_eigencoeffs`
* :doc:`subtom_parallel_eigenvolumes`
* :doc:`subtom_parallel_prealign`
* :doc:`subtom_parallel_sums`
* :doc:`subtom_parallel_xmatrix`
* :doc:`subtom_prepare_ccmatrix`
* :doc:`subtom_svds`
* :doc:`subtom_weighted_average`
