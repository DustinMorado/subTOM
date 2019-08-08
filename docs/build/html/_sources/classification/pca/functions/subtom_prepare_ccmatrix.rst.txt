=======================
subtom_prepare_ccmatrix
=======================

Calculates batch of pairwise comparisons of particles.

.. code-block:: Matlab

    subtom_prepare_ccmatrix(
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'ccmatrix_fn_prefix', ccmatrix_fn_prefix ('pca/ccmatrix'),
        'iteration', iteration (1),
        'num_ccmatrix_batch', num_ccmatrix_batch (1))

Figures out the pairwise comparisons to make from the motivelist given by
``all_motl_fn_prefix`` and ``iteration``, and breaks up these comparisons into
``num_ccmatrix_batch`` batches for parallel computation. Each batch is written
out as an array with the 'reference' particle index and 'target' particle index
to an EM-file with the name described by ``ccmatrix_fn_prefix``, ``iteration``,
#, and '_pairs' where the # is the batch index.

-------
Example
-------

.. code-block:: Matlab

    subtom_prepare_ccmatrix(
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'ccmatrix_fn_prefix', 'pca/ccmatrix', ...
        'iteration', 1, ...
        'num_ccmatrix_batch', 1000);

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
* :doc:`subtom_svds`
* :doc:`subtom_weighted_average`
