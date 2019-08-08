===========
subtom_eigs
===========

Uses MATLAB eigs to calculate a subset of Eigenvalue/vectors.

.. code-block:: Matlab

    subtom_eigs(
        'ccmatrix_fn_prefix', ccmatrix_fn_prefix ('pca/ccmatrix'),
        'eig_vec_fn_prefix', eig_vec_fn_prefix ('pca/eigvec'),
        'eig_val_fn_prefix', eig_val_fn_prefix ('pca/eigval'),
        'iteration', iteration (1),
        'num_eigs', num_eigs (40),
        'eigs_iterations', eigs_iterations ('default'),
        'eigs_tolerance', eig_tolerance ('default'),
        'do_algebraic', do_algebraic (0))

Uses the MATLAB function eigs to calculate a subset of eigenvalues and
eigenvectors given the constrained cross-correlation (covariance) matrix with
the filename ``ccmatrix_fn_prefix``_``iteration``.em. ``num_eigs`` of the
largest eigenvalues and eigenvectors will be calculated, and will be written out
to ``eig_val_fn_prefix``_``iteration``.em and
``eig_vec_fn_prefix``_``iteration``.em respectively. Two options
``eigs_iterations`` and ``eigs_tolerance`` are also available to tune how eigs
is run. If the string 'default' is given for either the default values in eigs
will be used. If ``do_algebraic`` evaluates to true as a boolean 'la' will be
used in place of 'lm' in the call to eigs, this could be a valid option in the
case when 'lm' returns negative eigenvalues.

-------
Example
-------

.. code-block:: Matlab

    subtom_eigs(...
        'ccmatrix_fn_prefix', 'pca/ccmatrix', ...
        'eig_vec_fn_prefix', 'pca/eigvec', ...
        'eig_val_fn_prefix', 'pca/eigval', ...
        'iteration', 1, ...
        'num_eigs', 50, ...
        'eigs_iterations', 'default', ...
        'eigs_tolerance', 'default', ...
        'do_algebraic', 1)

--------
See Also
--------

* :doc:`subtom_cluster`
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
* :doc:`subtom_svds`
* :doc:`subtom_weighted_average`
