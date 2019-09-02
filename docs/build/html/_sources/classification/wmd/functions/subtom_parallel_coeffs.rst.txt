======================
subtom_parallel_coeffs
======================

Computes wedge-masked difference coefficients.

.. code-block:: Matlab

    subtom_parallel_coeffs(
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'dmatrix_fn_prefix', dmatrix_fn_prefix ('class/dmatrix_wmd'),
        'ptcl_fn_prefix', ptcl_fn_prefix ('subtomograms/subtomo'),
        'ref_fn_prefix', ref_fn_prefix ('ref/ref'),
        'coeff_fn_prefix', coeff_fn_prefix ('class/coeff_wmd'),
        'eig_val_fn_prefix', eig_val_fn_prefix ('class/eigval_wmd'),
        'eig_vol_fn_prefix', eig_vol_fn_prefix ('class/eigvol_wmd'),
        'weight_fn_prefix', weight_fn_prefix ('otherinputs/ampspec'),
        'mask_fn', mask_fn ('none'),
        'high_pass_fp', high_pass_fp (0),
        'high_pass_sigma', high_pass_sigma (0),
        'low_pass_fp', low_pass_fp (0),
        'low_pass_sigma', low_pass_sigma (0),
        'nfold', nfold (1),
        'prealigned', prealigned (0),
        'iteration', iteration (1),
        'tomo_row', tomo_row (7),
        'num_coeff_batch', num_coeff_batch (1),
        'process_idx', process_idx (1))

Takes a batch subset of particles described by ``all_motl_fn_prefix`` with
filenames given by ``ptcl_fn_prefix``, band-pass filters them as described by
``high_pass_fp``, ``high_pass_sigma``, ``low_pass_fp``, and ``low_pass_sigma``,
optionally applies ``nfold`` C-symmetry, and projects them onto the Eigenvolumes
specified by ``eig_vol_fn_prefix``. This determines a set of coefficients
describing a low-rank approximation of the data. A subset of this coefficient
matrix is written out based on ``coeff_fn_prefix`` and ``process_idx``, with
there being ``num_coeff_batch`` batches in total.

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

    subtom_parallel_coeffs(
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'dmatrix_fn_prefix', 'class/dmatrix', ...
        'ptcl_fn_prefix', 'subtomograms/subtomo_ali', ...
        'ref_fn_prefix', 'ref/ref', ...
        'coeff_fn_prefix', 'class/coeff', ...
        'eig_val_fn_prefix', 'class/eigval', ...
        'eig_vol_fn_prefix', 'class/eigvol', ...
        'weight_fn_prefix', 'otherinputs/ampspec', ...
        'mask_fn', 'otherinputs/classification_mask.em', ...
        'high_pass_fp', 1, ...
        'high_pass_sigma', 2, ...
        'low_pass_fp', 15, ...
        'low_pass_sigma', 3, ...
        'nfold', 1, ...
        'prealigned', 1, ...
        'iteration', 1, ...
        'tomo_row', 7, ...
        'num_coeff_batch', 100, ...
        'process_idx', 1)

--------
See Also
--------

* :doc:`subtom_eigenvolumes_wmd`
* :doc:`subtom_join_coeffs`
* :doc:`subtom_join_dmatrix`
* :doc:`subtom_parallel_dmatrix`
