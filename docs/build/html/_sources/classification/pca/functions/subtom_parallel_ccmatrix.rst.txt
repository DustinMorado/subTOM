========================
subtom_parallel_ccmatrix
========================

Calculates pairwise Constrained Cross-Correlation scores of aligned particles.

.. code-block:: Matlab

    subtom_parallel_ccmatrix(
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'ccmatrix_fn_prefix', ccmatrix_fn_prefix ('pca/ccmatrix'),
        'weight_fn_prefix', weight_fn_prefix ('otherinputs/ampspec'),
        'ptcl_fn_prefix', ptcl_fn_prefix ('subtomograms/subtomo'),
        'mask_fn', mask_fn ('none'),
        'high_pass_fp', high_pass_fp (0),
        'high_pass_sigma', high_pass_sigma (0),
        'low_pass_fp', low_pass_fp (0),
        'low_pass_sigma', low_pass_sigma (0),
        'nfold', nfold (1),
        'iteration', iteration (1),
        'tomo_row', tomo_row (7),
        'prealigned', prealigned (0),
        'num_ccmatrix_batch', num_ccmatrix_batch (1),
        'process_idx', process_idx (1))

Aligns a subset of particles using the rotations and shifts in the file given by
``all_motl_fn_prefix`` and ``iteration``. If ``prealigned`` evaluates to true as
boolean, then the particles in ``ptcl_fn_prefix`` are assumed to be prealigned,
which should increase the speed of the processing. The subset of particles
compared is specified by the file given by ``ccmatrix_fn_prefix``,
``iteration``, and ``process_idx`` appended with '_pairs', and the output list
of cross-correlation coefficients will be written out to the file specified by
``ccmatrix_fn_prefix``, ``iteration``, and ``process_idx``. Fourier weight
volumes with name prefix ``weight_fn_prefix`` will also be aligned so that the
cross-correlation cofficient can be constrained to only overlapping shared
regions of Fourier space. ``tomo_row`` describes which row of the MOTL file is
used to determine the correct tomogram Fourier weight file. The correlation is
also constrained by a bandpass filter specified by ``high_pass_fp``,
``high_pass_sigma``, ``low_pass_fp`` and ``low_pass_sigma``.

-------
Example
-------

.. code-block:: Matlab

    subtom_parallel_ccmatrix(
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'ccmatrix_fn_prefix', 'pca/ccmatrix', ...
        'weight_fn_prefix', 'otherinputs/ampspec', ...
        'ptcl_fn_prefix', 'subtomograms/alisubtomo', ...
        'mask_fn', 'otherinputs/classification_mask.em', ...
        'high_pass_fp', 1, ...
        'high_pass_sigma', 2, ...
        'low_pass_fp', 15, ...
        'low_pass_sigma', 3, ...
        'nfold', 1, ...
        'iteration', 1, ...
        'tomo_row', 7, ...
        'prealigned', 1, ...
        'num_ccmatrix_batch', 100, ...
        'process_idx', 1)

--------
See Also
--------

* :doc:`subtom_cluster`
* :doc:`subtom_eigs`
* :doc:`subtom_join_ccmatrix`
* :doc:`subtom_join_eigencoeffs`
* :doc:`subtom_join_eigenvolumes`
* :doc:`subtom_parallel_eigencoeffs`
* :doc:`subtom_parallel_eigenvolumes`
* :doc:`subtom_parallel_prealign`
* :doc:`subtom_parallel_sums`
* :doc:`subtom_parallel_xmatrix`
* :doc:`subtom_prepare_ccmatrix`
* :doc:`subtom_svds`
* :doc:`subtom_weighted_average`
