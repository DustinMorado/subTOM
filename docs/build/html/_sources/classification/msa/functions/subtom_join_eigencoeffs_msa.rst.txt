===========================
subtom_join_eigencoeffs_msa
===========================

Combines Eigencoefficient batches into final matrix.

.. code-block:: Matlab

    subtom_join_eigencoeffs_msa(
        'eig_coeff_fn_prefix', eig_coeff_fn_prefix ('class/eigcoeff_msa'),
        'iteration', iteration (1),
        'num_coeff_batch', num_coeff_batch (1))

Looks for partial chunks of the low-rank approximation coefficients of projected
particles with the file name given by ``eig_coeff_fn_prefix``, ``iteration`` and
# where # is from 1 to ``num_coeff_batch``, and combines them into a final
matrix of coefficients written out as described by ``eig_coeff_fn_prefix``, and
``iteration``.

-------
Example
-------

.. code-block:: Matlab

    subtom_join_eigencoeffs_msa(...
        'eig_coeff_fn_prefix', 'class/eigcoeff', ...
        'iteration', 1, ...
        'num_coeff_batch', 100)

--------
See Also
--------

* :doc:`subtom_eigenvolumes_msa`
* :doc:`subtom_join_xmatrix`
* :doc:`subtom_parallel_eigencoeffs_msa`
* :doc:`subtom_parallel_xmatrix_msa`
