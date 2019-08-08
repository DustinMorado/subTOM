===========================
subtom_parallel_eigencoeffs
===========================

Computes particle Eigencoefficients

.. code-block:: Matlab

    subtom_parallel_eigencoeffs(
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'xmatrix_fn_prefix', xmatrix_fn_prefix ('pca/xmatrix'),
        'ptcl_fn_prefix', ptcl_fn_prefix ('subtomograms/subtomo'),
        'eig_coeff_fn_prefix', eig_coeff_fn_prefix ('pca/eigcoeff'),
        'eig_vec_fn_prefix', eig_vec_fn_prefix ('pca/eigvec'),
        'eig_val_fn_prefix', eig_val_fn_prefix ('pca/eigval'),
        'eig_vol_fn_prefix', eig_vol_fn_prefix ('pca/eigvol'),
        'weight_fn_prefix', weight_fn_prefix ('otherinputs/ampspec'),
        'mask_fn', mask_fn ('none'),
        'use_fast', use_fast (0),
        'use_eig_vec', use_eig_vec (0),
        'apply_weight', apply_weight (0),
        'prealigned', prealigned (0),
        'nfold', nfold (1),
        'iteration', iteration (1),
        'tomo_row', tomo_row (7),
        'num_xmatrix_batch', num_xmatrix_batch (1),
        'process_idx', process_idx (1))

Takes a batch subset of particles described by ``all_motl_fn_prefix`` with
filenames given by ``ptcl_fn_prefix`` and projects them onto by default the
Eigenvolumes specified by ``eig_vol_fn_prefix``. This determines a set of
coefficients describing a low-rank approximation of the data. A subset of this
coefficient matrix is written out based on ``eig_coeff_fn_prefix`` and
``process_idx``, with there being ``num_xmatrix_batch`` batches in total.

The calculation can be performed in a variety of ways with various speeds of
processing. If the subset of particles is the same size as the X-Matrix batch
used to determine the Eigenvolumes (or the conjugate space Eigenvector volume as
described below), then the user can set ``use_fast`` to 1 and a single-step
calculation will be performed to determine an estimate of the coefficients based
on the transition formulas. Otherwise as long as ``apply_weight`` is set to 0
and the particle amplitude spectrum weight (or binary missing wedge) is not
applied to the Eigenvolumes; the batch coefficient matrix is just a simple
matrix product of the X-Matrix chunk with the matrix form of the Eigenvolumes.

If the number of particles in the motive list batch is bigger than the size of
the X-Matrix chunk or if ``apply_weight`` is set to 1 and the Eigenvolumes will
be reweighted using the correct weight of each particle as described by
``weight_fn_prefix`` and ``tomo_row``, then each particle will be read and
projected in a loop. If ``prealigned`` is set to 1, then it is understood that
the particles have been prealigned beforehand and the alignment of the particles
can be skipped to save time.  ``mask_fn`` describes the mask used throughout
classification and 'none' describes a default spherical mask. ``nfold``
describes a C-symmetry number to apply to the Eigenvolume before projection

Also as a consequence of the transition formulas conjugate space Eignvectors can
be used in place of the Eigenvolumes if ``use_eig_vec`` is set to 1, as a means
to calculate the Eigencoefficients, however this should be identical in the
final result and is just for clarity.

-------
Example
-------

.. code-block:: Matlab

    subtom_parallel_eigencoeffs(
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'xmatrix_fn_prefix', 'pca/xmatrix', ...
        'ptcl_fn_prefix', 'subtomograms/subtomo_ali', ...
        'eig_coeff_fn_prefix', 'pca/eigcoeff', ...
        'eig_vec_fn_prefix', 'pca/svdvec', ...
        'eig_val_fn_prefix', 'pca/sval', ...
        'eig_vol_fn_prefix', 'pca/eigvol', ...
        'weight_fn_prefix', 'otherinputs/ampspec', ...
        'mask_fn', 'otherinputs/classification_mask.em', ...
        'use_fast', 0, ...
        'use_eig_vec', 0, ...
        'apply_weight', 1, ...
        'prealigned', 1, ...
        'nfold', 1, ...
        'iteration', 1, ...
        'tomo_row', 7, ...
        'num_xmatrix_batch', 100, ...
        'process_idx', 1)

--------
See Also
--------

* :doc:`subtom_cluster`
* :doc:`subtom_eigs`
* :doc:`subtom_join_ccmatrix`
* :doc:`subtom_join_eigencoeffs`
* :doc:`subtom_join_eigenvolumes`
* :doc:`subtom_parallel_ccmatrix`
* :doc:`subtom_parallel_eigenvolumes`
* :doc:`subtom_parallel_prealign`
* :doc:`subtom_parallel_sums`
* :doc:`subtom_parallel_xmatrix`
* :doc:`subtom_prepare_ccmatrix`
* :doc:`subtom_svds`
* :doc:`subtom_weighted_average`
