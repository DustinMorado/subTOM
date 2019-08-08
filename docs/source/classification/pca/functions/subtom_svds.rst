===========
subtom_svds
===========

Uses MATLAB svds to calculate a subset of singular values/vectors.

.. code-block:: Matlab

    subtom_svds(
        'ccmatrix_fn_prefix', ccmatrix_fn_prefix ('pca/ccmatrix'),
        'eig_vec_fn_prefix', eig_vec_fn_prefix ('pca/eigvec'),
        'eig_val_fn_prefix', eig_val_fn_prefix ('pca/eigval'),
        'iteration', iteration (1),
        'num_svs', num_svs (40),
        'svds_iterations', svds_iterations ('default'),
        'svds_tolerance', svds_tolerance ('default'))

Uses the MATLAB function svds to calculate a subset of singular values and
vectors given the constrained cross-correlation (covariance) matrix with the
filename given by ``ccmatrix_fn_prefix`` and ``iteration``. ``num_svs`` of the
largest singular values and vectors will be calculated, and will be written out
based on ``eig_val_fn_prefix`` and ``iteration``; and ``eig_vec_fn_prefix`` and
``iteration`` respectively. Two options ``svds_iterations`` and
``svds_tolerance`` are also available to tune how svds is run. If the string
'default' is given for either the default values in eigs will be used.

-------
Example
-------

.. code-block:: Matlab

    subtom_svds(...
        'ccmatrix_fn_prefix', 'pca/ccmatrix', ...
        'eig_vec_fn_prefix', 'pca/eigvec', ...
        'eig_val_fn_prefix', 'pca/eigval', ...
        'iteration', 1, ...
        'num_svs', 50, ...
        'svds_iterations', 'default', ...
        'svds_tolerance', 'default')

--------
See Also
--------

* :doc:`subtom_cluster`
* :doc:`subtom_eigs`
* :doc:`subtom_join_ccmatrix`
* :doc:`subtom_join_eigencoeffs`
* :doc:`subtom_join_eigenvolumes`
* :doc:`subtom_parallel_ccmatrix`
* :doc:`subtom_parallel_eigencoeffs`
* :doc:`subtom_parallel_eigenvolumes`
* :doc:`subtom_parallel_prealign`
* :doc:`subtom_parallel_sums`
* :doc:`subtom_parallel_xmatrix`
* :doc:`subtom_prepare_ccmatrix`
* :doc:`subtom_weighted_average`
