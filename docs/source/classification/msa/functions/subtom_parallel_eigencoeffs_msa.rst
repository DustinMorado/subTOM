===============================
subtom_parallel_eigencoeffs_msa
===============================

Computes particle Eigencoefficients

.. code-block:: Matlab

    subtom_parallel_eigencoeffs_msa(
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'xmatrix_fn_prefix', xmatrix_fn_prefix ('class/xmatrix_msa'),
        'ptcl_fn_prefix', ptcl_fn_prefix ('subtomograms/subtomo'),
        'eig_coeff_fn_prefix', eig_coeff_fn_prefix ('class/eigcoeff_msa'),
        'eig_val_fn_prefix', eig_val_fn_prefix ('class/eigval_msa'),
        'eig_vol_fn_prefix', eig_vol_fn_prefix ('class/eigvol_msa'),
        'weight_fn_prefix', weight_fn_prefix ('otherinputs/ampspec'),
        'mask_fn', mask_fn ('none'),
        'high_pass_fp', high_pass_fp (0),
        'high_pass_sigma', high_pass_sigma (0),
        'low_pass_fp', low_pass_fp (0),
        'low_pass_sigma', low_pass_sigma (0),
        'nfold', nfold (1),
        'apply_weight', apply_weight (0),
        'tomo_row', tomo_row (7),
        'iteration', iteration (1),
        'prealigned', prealigned (0),
        'num_coeff_batch', num_coeff_batch (1),
        'process_idx', process_idx (1))

Takes a batch subset of particles described by ``all_motl_fn_prefix`` with
filenames given by ``ptcl_fn_prefix``, band-pass filters them as described by
``high_pass_fp``, ``high_pass_sigma``, ``low_pass_fp``, and ``low_pass_sigma``,
and projects them onto the Eigenvolumes specified by ``eig_vol_fn_prefix``. This
determines a set of coefficients describing a low-rank approximation of the
data. A subset of this coefficient matrix is written out based on
``eig_coeff_fn_prefix`` and ``process_idx``, with there being
``num_coeff_batch`` batches in total.

If ``apply_weight`` is set to 1 the Eigenvolumes will be reweighted using the
correct weight of each particle as described by ``weight_fn_prefix`` and
``tomo_row``, then each particle will be read and projected in a loop. If
``prealigned`` is set to 1, then it is understood that the particles have been
prealigned beforehand and the alignment of the particles can be skipped to save
time.  ``mask_fn`` describes the mask used throughout classification and 'none'
describes a default spherical mask.

-------
Example
-------

.. code-block:: Matlab

    subtom_parallel_eigencoeffs_msa(
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'xmatrix_fn_prefix', 'class/xmatrix', ...
        'ptcl_fn_prefix', 'subtomograms/subtomo_ali', ...
        'eig_coeff_fn_prefix', 'class/eigcoeff', ...
        'eig_val_fn_prefix', 'class/eigval', ...
        'eig_vol_fn_prefix', 'class/eigvol', ...
        'weight_fn_prefix', 'otherinputs/ampspec', ...
        'mask_fn', 'otherinputs/classification_mask.em', ...
        'high_pass_fp', 1, ...
        'high_pass_sigma', 2, ...
        'low_pass_fp', 15, ...
        'low_pass_sigma', 3, ...
        'nfold', 1, ...
        'apply_weight', 1, ...
        'tomo_row', 7, ...
        'iteration', 1, ...
        'prealigned', 1, ...
        'num_coeff_batch', 100, ...
        'process_idx', 1)

--------
See Also
--------

* :doc:`subtom_eigenvolumes_msa`
* :doc:`subtom_join_eigencoeffs_msa`
* :doc:`subtom_join_xmatrix`
* :doc:`subtom_parallel_xmatrix_msa`
