=======================
subtom_weighted_average
=======================

Joins and weights parallel average subsets.

.. code-block:: matlab

    subtom_weighted_average(
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'ref_fn_prefix', ref_fn_prefix ('ref/ref'),
        'weight_sum_fn_prefix', weight_sum_fn_prefix ('otherinputs/wei'),
        'iteration', iteration (1),
        'iclass', iclass (0),
        'num_avg_batch', num_avg_batch (1))

Takes the ``num_avg_batch`` parallel sum subsets with the name prefix
``ref_fn_prefix``, the all_motl file with name prefix ``motl_fn_prefix`` and
weight volume subsets with the name prefix ``weight_sum_fn_prefix`` to generate
the final average, which should then be used as the reference for iteration
number ``iteration``.  ``iclass`` describes which class outside of one is
included in the final average and is used to correctly scale the average and
weights.

-------
Example
-------

.. code-block:: matlab

    subtom_weighted_average(...
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'ref_fn_prefix', './ref/ref', ...
        'weight_sum_fn_prefix', 'otherinputs/wei', ...
        'iteration', 1, ...
        'iclass', 0, ...
        'num_avg_batch', 1)

--------
See Also
--------

* :doc:`subtom_extract_noise`
* :doc:`subtom_extract_subtomograms`
* :doc::`subtom_parallel_sums`
* :doc:`subtom_scan_angles_exact`
