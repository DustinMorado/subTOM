=======================
subtom_parallel_dmatrix
=======================

Calculates chunks of the D-matrix for processing.

.. code-block:: Matlab

    subtom_parallel_dmatrix(
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'dmatrix_fn_prefix', dmatrix_fn_prefix ('class/dmatrix_wmd'),
        'ptcl_fn_prefix', ptcl_fn_prefix ('subtomograms/subtomo'),
        'ref_fn_prefix', ref_fn_prefix ('ref/ref'),
        'weight_fn_prefix', weight_fn_prefix ('otherinputs/ampspec'),
        'mask_fn', mask_fn ('none'),
        'high_pass_fp', high_pass_fp (0),
        'high_pass_sigma', high_pass_sigma (0),
        'low_pass_fp', low_pass_fp (0),
        'low_pass_sigma', low_pass_sigma (0),
        'nfold', nfold (1),
        'iteration', iteration (1),
        'tomo_row', tomo_row (7),
        'prealigned', prealigned (0),
        'num_dmatrix_batch', num_dmatrix_batch (1),
        'process_idx', process_idx (1))

Aligns a subset of particles using the rotations and shifts in the file given by
``all_motl_fn_prefix`` and ``iteration`` and then subtracts the particle from
the reference specified by ``ref_fn_prefix`` and ``iteration`` and places these
voxels of the difference as a 1-D row vector in a data sub-matrix which is
denoted as the D-matrix (See Heumann, et al. 2011 J. Struct. Biol.). The
particle and reference are also filtered by a bandpass filter specified by
``high_pass_fp``, ``high_pass_sigma``, ``low_pass_fp`` and ``low_pass_sigma``,
and optionally symmetrized with ``nfold`` C-symmetry, before subtracted.The
reference is masked in Fourier space using the weight specified by
``weight_fn_prefix`` and ``tomo_row``.  The subset of particles compared is
specified by the number of particles in the motive list and the number of
requested batches specified by ``num_dmatrix_batch``, with the specific subset
deteremined by ``process_idx``. The D-matrix chunk will be written out as given
by ``dmatrix_fn_prefix``, ``iteration``, and ``process_idx``. The location of
the particles is specified by ``ptcl_fn_prefix``. If ``prealigned`` evaluates to
true as a boolean then the particles are assumed to be prealigned, which should
increase speed of computation of D-Matrix calculations. Particles in the
D-matrix will be masked by the file given by ``mask_fn``. If the string 'none'
is used in place of ``mask_fn``, a default spherical mask is applied.  This mask
should be a binary mask and only voxels within the mask are placed into the
D-matrix which can greatly speed up computations.

-------
Example
-------

.. code-block:: Matlab

    subtom_parallel_dmatrix(
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'dmatrix_fn_prefix', 'class/dmatrix', ...
        'ptcl_fn_prefix', 'subtomograms/subtomo_ali', ...
        'ref_fn_prefix', 'ref/ref', ...
        'weight_fn_prefix', 'otherinputs/ampspec', ...
        'mask_fn', 'combinedmotl/classification_mask.em', ...
        'high_pass_fp', 1, ...
        'high_pass_sigma', 2, ...
        'low_pass_fp', 15, ...
        'low_pass_sigma', 3, ...
        'nfold', 1, ...
        'iteration', 1, ...
        'prealigned', 1, ...
        'num_dmatrix_batch', 100, ...
        'process_idx', 1)

--------
See Also
--------

* :doc:`subtom_eigenvolumes_wmd`
* :doc:`subtom_join_coeffs`
* :doc:`subtom_join_dmatrix`
* :doc:`subtom_parallel_coeffs`
