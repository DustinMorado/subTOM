========================
subtom_parallel_sums_cls
========================

Creates raw sums and Fourier weight sums in a batch.

.. code-block:: Matlab

    subtom_parallel_sums_cls(
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'ref_fn_prefix', ref_fn_prefix ('ref/ref'),
        'ptcl_fn_prefix', ptcl_fn_prefix ('subtomograms/subtomo'),
        'weight_fn_prefix', weight_fn_prefix ('otherinputs/ampspec'),
        'weight_sum_fn_prefix, weight_sum_fn_prefix ('otherinputs/wei'),
        'iteration', iteration (1),
        'tomo_row', tomo_row (7),
        'num_avg_batch', num_avg_batch (1),
        'process_idx', process_idx (1))

Aligns a subset of particles using the rotations and shifts in
``all_motl_fn_prefix`` _#.em where # corresponds to ``iteration`` in
``num_avg_batch`` chunks to make a raw particle sum ``ref_fn_prefix`` _#_###.em
where # corresponds to ``iteration`` and ### corresponds to ``process_idx``.
Fourier weight volumes with name prefix ``weight_fn_prefix`` will also be
aligned and summed to make a weight sum ``weight_sum_fn_prefix`` _#_###.em.
``tomo_row`` describes which row of the motl file is used to determine the
correct tomogram fourier weight file. In this multi-reference version of
parallel sums, each unique value of iclass (row 20 in the motive list) will be
summed and written out (excluding non-positive values).

-------
Example
-------

.. code-block:: Matlab

    subtom_parallel_sums_cls(...
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'ref_fn_prefix', 'ref/ref', ...
        'ptcl_fn_prefix', 'subtomograms/subtomo', ...
        'weight_fn_prefix', 'otherinputs/ampspec', ...
        'weight_sum_fn_prefix, 'otherinputs/wei', ...
        'iteration', 1, ...
        'tomo_row', 7, ...
        'num_avg_batch', 1, ...
        'process_idx', 1)

--------
See Also
--------

* :doc:`subtom_cluster`
* :doc:`subtom_parallel_prealign`
* :doc:`subtom_scan_angles_exact_refs`
* :doc:`subtom_weighted_average_cls`
