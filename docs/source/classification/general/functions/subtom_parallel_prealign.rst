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

-------
Example
-------

.. code-block:: Matlab

    subtom_parallel_prealign(
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'ptcl_fn_prefix', 'subtomograms/subtomo', ...
        'prealign_fn_prefix', 'subtomograms/subtomo_ali', ...
        'iteration', 1, ...
        'num_prealign_batch', 100, ...
        'process_idx', 1)

--------
See Also
--------

* :doc:`subtom_cluster`
* :doc:`subtom_parallel_sums_cls`
* :doc:`subtom_scan_angles_exact_refs`
* :doc:`subtom_weighted_average_cls`
