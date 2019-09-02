===========================
subtom_join_eigencoeffs_pca
===========================

Randomizes a given number of classes in a motive list.

.. code-block:: Matlab

    subtom_join_eigencoeffs_pca(
        'eig_coeff_fn_prefix', eig_coeff_fn_prefix ('class/eigcoeff_pca'),
        'iteration', iteration (1),
        'num_coeff_batch', num_coeff_batch (1))

Looks for partial chunks of the low-rank approximation coefficients of projected
particles with the file name given by ``eig_coeff_fn_prefix``, ``iteration`` and
# where # is from 1 to ``num_coeff_batch``, and combines them into a final
matrix of coefficients written out as specified by ``eig_coeff_fn_prefix`` and
``iteration``.

-------
Example
-------

.. code-block:: Matlab

    subtom_join_eigencoeffs_pca(...
        'eig_coeff_fn_prefix', 'class/eigcoeff', ...
        'iteration', 1, ...
        'num_coeff_batch', 100)

--------
See Also
--------

* :doc:`subtom_eigs`
* :doc:`subtom_join_ccmatrix`
* :doc:`subtom_join_eigenvolumes`
* :doc:`subtom_parallel_ccmatrix`
* :doc:`subtom_parallel_eigencoeffs_pca`
* :doc:`subtom_parallel_eigenvolumes`
* :doc:`subtom_parallel_xmatrix_pca`
* :doc:`subtom_prepare_ccmatrix`
* :doc:`subtom_svds`
