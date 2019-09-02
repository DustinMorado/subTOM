=======================
subtom_eigenvolumes_wmd
=======================

Computes Singular Value Decomposition of D-Matrix and projects data on
right Singular Vectors.

.. code-block:: Matlab

    subtom_eigenvolumes_wmd(
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'ptcl_fn_prefix', ptcl_fn_prefix ('subtomograms/subtomo'),
        'dmatrix_fn_prefix', dmatrix_fn_prefix ('class/dmatrix_wmd'),
        'eig_val_fn_prefix', eig_val_fn_prefix ('class/eigval_wmd'),
        'eig_vol_fn_prefix', eig_vol_fn_prefix ('class/eigvol_wmd'),
        'variance_fn_prefix', variance_fn_prefix ('class/variance_wmd'),
        'mask_fn', mask_fn ('none'),
        'iteration', iteration (1),
        'num_svs', num_svs (40),
        'svds_iterations', svds_iterations ('default'),
        'svds_tolerance', svds_tolerance ('default'))

Calculates ``num_svs`` weighted projections of wedge-masked differences onto the
same number of determined Right-Singular Vectors, by means of the Singular Value
Decomposition of a previously calculated D-matrix, named as given by
``dmatrix_fn_prefix`` and ``iteration`` to produce Eigenvolumes which can then
be used to determine which vectors can best influence classification.  The
Eigenvolumes are also masked by the file specified by ``mask_fn``. The output
weighted Eigenvolume will be written out as specified by ``eig_vol_fn_prefix``,
``iteration`` and #, where the # is the particular Eigenvolume being written
out. The calculated Eigenvalues which correspond to the square of the singular
vectors are also written oun as given by ``eig_val_fn_prefix`` and
``iteration``, and the variance map of the data is written out as determined by
``variance_fn_prefix`` and ``iteration``.  Two options ``svds_iterations`` and
``svds_tolerance`` are also available to tune how svds is run. If the string
'default' is given for either the default values in svds will be used.

-------
Example
-------

.. code-block:: Matlab

    subtom_eigenvolumes_wmd(...
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'ptcl_fn_prefix', 'subtomograms/subtomo', ...
        'dmatrix_fn_prefix', 'class/dmatrix', ...
        'eig_val_fn_prefix', 'class/eigval', ...
        'eig_vol_fn_prefix', 'class/eigvol', ...
        'variance_fn_prefix', 'class/variance', ...
        'mask_fn', 'class/class_mask.em', ...
        'iteration', 1, ...
        'num_svs', 40, ...
        'svds_iterations', 'default', ...
        'svds_tolerance', 'default')

--------
See Also
--------

* :doc:`subtom_join_coeffs`
* :doc:`subtom_join_dmatrix`
* :doc:`subtom_parallel_coeffs`
* :doc:`subtom_parallel_dmatrix`
