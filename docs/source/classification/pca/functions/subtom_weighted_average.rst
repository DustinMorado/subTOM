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
        'num_avg_batch', num_avg_batch (1))

Takes the ``num_avg_batch`` parallel sum subsets with the name prefix
``ref_fn_prefix``, the all_motl file with name prefix ``motl_fn_prefix`` and
weight volume subsets with the name prefix ``weight_sum_fn_prefix`` to generate
the final average, which should then be used as the reference for iteration
number ``iteration``.

-------
Example
-------

.. code-block:: matlab

    subtom_weighted_average(...
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'ref_fn_prefix', './ref/ref', ...
        'weight_sum_fn_prefix', 'otherinputs/wei', ...
        'iteration', 1, ...
        'num_avg_batch', 1)

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
* :doc:`subtom_parallel_prealign`
* :doc:`subtom_parallel_sums`
* :doc:`subtom_parallel_xmatrix`
* :doc:`subtom_prepare_ccmatrix`
* :doc:`subtom_svds`
