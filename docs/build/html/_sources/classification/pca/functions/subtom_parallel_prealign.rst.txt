========================
subtom_parallel_prealign
========================

Prealigns particles to speed up CC-Matrix calculation.

.. code-block:: Matlab

    subtom_parallel_prealign(
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'ptcl_fn_prefix', ptcl_fn_prefix ('subtomograms/subtomo'),
        'prealign_fn_prefix', prealign_fn_prefix ('subtomograms/subtomo'),
        'iteration', iteration (1),
        'num_prealign_batch', num_prealign_batch (1),
        'process_idx', process_idx (1))

Prerotates and translates particles into alignment as precalculation on disk to
speed up the calculation of the constrained cross-correlation matrix. The
alignments are given in the motive list specified by ``all_motl_fn_prefix`` and
``iteration``, and the particles are based on ``ptcl_fn_prefix`` and # where #
is described in row 4 of the motive list.  Pre-aligned particles will be written
out described by  ``prealign_fn_prefix``, ``iteration`` and #. The process is
designed to be run in parallel on a cluster. The particles will be processed in
``num_prealign_batch`` chunks, with the specific chunk being processed described
by ``process_idx``.

Takes the motive list given by ``input_motl_fn``, and splits it into
``num_classes`` even classes using the 20th row of the motive list, and then
writes the transformed motive list out as ``output_motl_fn``. The values that go
into the 20th row start at 3 and particles that initially have negative or the
value 2 in the 20th row are ignored as described in AV3 documentation for the
behavior of class numbers.

-------
Example
-------

.. code-block:: Matlab

    subtom_parallel_prealign(
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'ptcl_fn_prefix', 'subtomograms/subtomo', ...
        'prealign_fn_prefix', 'subtomograms/alisubtomo', ...
        'iteration', 1, ...
        'num_prealign_batch', 100, ...
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
* :doc:`subtom_parallel_eigencoeffs`
* :doc:`subtom_parallel_eigenvolumes`
* :doc:`subtom_parallel_sums`
* :doc:`subtom_parallel_xmatrix`
* :doc:`subtom_prepare_ccmatrix`
* :doc:`subtom_svds`
* :doc:`subtom_weighted_average`
