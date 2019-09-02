===========
subtom_eigs
===========

Uses MATLAB eigs to calculate a subset of Eigenvalue/vectors.

.. code-block:: Matlab

    subtom_eigs(
        'ccmatrix_fn_prefix', ccmatrix_fn_prefix ('class/ccmatrix_pca'),
        'eig_vec_fn_prefix', eig_vec_fn_prefix ('class/eigvec_pca'),
        'eig_val_fn_prefix', eig_val_fn_prefix ('class/eigval_pca'),
        'iteration', iteration (1),
        'num_eigs', num_eigs (40),
        'eigs_iterations', eigs_iterations ('default'),
        'eigs_tolerance', eig_tolerance ('default'),
        'do_algebraic', do_algebraic (0))

Uses the MATLAB function eigs to calculate a subset of eigenvalues and
eigenvectors given the constrained cross-correlation (covariance) matrix with
the filename given by ``ccmatrix_fn_prefix`` and ``iteration``. ``num_eigs`` of
the largest eigenvalues and eigenvectors will be calculated, and will be written
out as specified by ``eig_val_fn_prefix``, ``eig_vec_fn_prefix`` and
``iteration`` respectively. Two options ``eigs_iterations`` and
``eigs_tolerance`` are also available to tune how eigs is run. If the string
'default' is given for either the default values in eigs will be used. If
``do_algebraic`` evaluates to true as a boolean 'la' will be used in place of
'lm' in the call to eigs, this could be a valid option in the case when 'lm'
returns negative eigenvalues.

-------
Example
-------

.. code-block:: Matlab

    subtom_eigs(...
        'ccmatrix_fn_prefix', 'class/ccmatrix', ...
        'eig_vec_fn_prefix', 'class/eigvec', ...
        'eig_val_fn_prefix', 'class/eigval', ...
        'iteration', 1, ...
        'num_eigs', 50, ...
        'eigs_iterations', 'default', ...
        'eigs_tolerance', 'default', ...
        'do_algebraic', 1)

--------
See Also
--------

* :doc:`subtom_join_ccmatrix`
* :doc:`subtom_join_eigencoeffs_pca`
* :doc:`subtom_join_eigenvolumes`
* :doc:`subtom_parallel_ccmatrix`
* :doc:`subtom_parallel_eigencoeffs_pca`
* :doc:`subtom_parallel_eigenvolumes`
* :doc:`subtom_parallel_xmatrix_pca`
* :doc:`subtom_prepare_ccmatrix`
* :doc:`subtom_svds`
