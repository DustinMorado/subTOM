===========================
subtom_parallel_xmatrix_pca
===========================

Calculates chunks of the X-matrix for processing.

.. code-block:: Matlab

    subtom_parallel_xmatrix_pca(
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'xmatrix_fn_prefix', xmatrix_fn_prefix ('class/xmatrix_pca'),
        'ptcl_fn_prefix', ptcl_fn_prefix ('subtomograms/subtomo'),
        'mask_fn', mask_fn ('none'),
        'high_pass_fp', high_pass_fp (0),
        'high_pass_sigma', high_pass_sigma (0),
        'low_pass_fp', low_pass_fp (0),
        'low_pass_sigma', low_pass_sigma (0),
        'nfold', nfold (1),
        'iteration', iteration (1),
        'prealigned', prealigned (0),
        'num_xmatrix_batch', num_xmatrix_batch (1),
        'process_idx', process_idx (1))

Aligns a subset of particles using the rotations and shifts given by
``all_motl_fn_prefix`` and ``iteration``, band-pass filters the particle as
described by ``high_pass_fp``, ``high_pass_sigma``, ``low_pass_fp``, and
``low_pass_sigma``, optionally applies ``nfold`` C-symmetry, and then places
these voxels as a 1-D row vector in a data sub-matrix which is historically
known as the X-matrix (See Borland, Van Heel 1990 J. Opt. Soc. Am. A). This
X-matrix can then be used to speed up the calculation of Eigenvolumes and
Eigencoefficients used for classification. The subset of particles compared is
specified by the number of particles in the motive list and the number of
requested batches specified by ``num_xmatrix_batch``, with the specific subset
deteremined by ``process_idx``.  The X-matrix chunk will be written out as
specified by ``xmatrix_fn_prefix``, ``iteration`` and ``process_idx``. The
location of the particles is specified by ``ptcl_fn_prefix``. If ``prealigned``
evaluates to true as a boolean then the particles are assumed to be prealigned,
which should increase speed of computation of CC-Matrix calculations. Particles
in the X-matrix will be masked by the file given by ``mask_fn``. If the string
'none' is used in place of ``mask_fn``, a default spherical mask is applied.
This mask should be a binary mask and only voxels within the mask are placed
into the X-matrix which can greatly speed up computations.

-------
Example
-------

.. code-block:: Matlab

    subtom_parallel_xmatrix_pca(
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'xmatrix_fn_prefix', 'class/xmatrix', ...
        'ptcl_fn_prefix', 'subtomograms/alisubtomo', ...
        'mask_fn', 'combinedmotl/classification_mask.em', ...
        'high_pass_fp', 1, ...
        'high_pass_sigma', 2, ...
        'low_pass_fp', 15, ...
        'low_pass_sigma', 3, ...
        'nfold', 1, ...
        'iteration', 1, ...
        'prealigned', 1, ...
        'num_xmatrix_batch', 100, ...
        'process_idx', 1)

--------
See Also
--------

* :doc:`subtom_eigs`
* :doc:`subtom_join_ccmatrix`
* :doc:`subtom_join_eigencoeffs_pca`
* :doc:`subtom_join_eigenvolumes`
* :doc:`subtom_parallel_ccmatrix`
* :doc:`subtom_parallel_eigencoeffs_pca`
* :doc:`subtom_parallel_eigenvolumes`
* :doc:`subtom_prepare_ccmatrix`
* :doc:`subtom_svds`
