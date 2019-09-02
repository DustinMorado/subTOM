=======================
subtom_eigenvolumes_msa
=======================

Computes Eigendecomposition of X-Matrix covariance and projects data on
Eigenvectors.

.. code-block:: Matlab

    subtom_eigenvolumes_msa(
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'ptcl_fn_prefix', ptcl_fn_prefix ('subtomograms/subtomo'),
        'eig_vec_fn_prefix', eig_vec_fn_prefix ('class/eigvec_msa'),
        'eig_val_fn_prefix', eig_val_fn_prefix ('class/eigval_msa'),
        'xmatrix_fn_prefix', xmatrix_fn_prefix ('class/xmatrix_msa'),
        'eig_vol_fn_prefix', eig_vol_fn_prefix ('class/eigvol_msa'),
        'mask_fn', mask_fn ('none'),
        'iteration', iteration (1),
        'num_eigs', num_eigs (40),
        'eigs_iterations', eigs_iterations ('default'),
        'eigs_tolerance', eig_tolerance ('default'))

Calculates ``num_eigs`` weighted projections of particles onto the same number
of determined Eigenvectors, by means of a previously calculated X-matrix,
named as given by ``xmatrix_fn_prefix`` and ``iteration`` to produce Eigenvolumes which can
then be used to determine which vectors can best influence classification.
The Eigenvectors and Eigenvalues are also written out as specified by
``eig_vec_fn_prefix``, ``eig_val_fn_prefix``, and ``iteration`` The
Eigenvolumes are also masked by the file specified by ``mask_fn``.  The output
weighted Eigenvolume will be written out as described by
``eig_vol_fn_prefix``, ``iteration`` and #, where the # is the particular
Eigenvolume being written out. Two options ``eigs_iterations`` and
``eigs_tolerance`` are also available to tune how eigs is run. If the string
'default' is given for either the default values in eigs will be used.

-------
Example
-------

.. code-block:: Matlab

    subtom_eigenvolumes_msa(...
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'ptcl_fn_prefix', 'subtomograms/subtomo', ...
        'eig_vec_fn_prefix', 'class/eigvec', ...
        'eig_val_fn_prefix', 'class/eigval', ...
        'xmatrix_fn_prefix', 'class/xmatrix', ...
        'eig_vol_fn_prefix', 'class/eigvol', ...
        'mask_fn', 'class/class_mask.em', ...
        'iteration', 1, ...
        'num_eigs', 40, ...
        'eigs_iterations', 'default', ...
        'eigs_tolerance', 'default')

--------
See Also
--------

* :doc:`subtom_join_eigencoeffs_msa`
* :doc:`subtom_join_xmatrix`
* :doc:`subtom_parallel_eigencoeffs_msa`
* :doc:`subtom_parallel_xmatrix_msa`
