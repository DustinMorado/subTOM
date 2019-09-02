====================
subtom_join_ccmatrix
====================

Combines chunks of the Cross-Correlation matrix into the final full matrix.

.. code-block:: Matlab

    subtom_join_ccmatrix(
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'ccmatrix_fn_prefix', ccmatrix_fn_prefix ('class/ccmatrix_pca'),
        'iteration', iteration (1),
        'num_ccmatrix_batch', num_ccmatrix_batch (1))

Looks for partial chunks of the ccmatrix with the file name given by
``ccmatrix_fn_prefix``, ``iteration``  and # where # is from 1 to
``num_ccmatrix_batch``, and then combines these chunks into the final ccmatrix
and writes it out to the file specified by ``ccmatrix_fn_prefix`` and
``iteration``

-------
Example
-------

.. code-block:: Matlab

    subtom_join_ccmatrix(...
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'ccmatrix_fn_prefix', 'class/ccmatrix', ...
        'iteration', 1, ...
        'num_ccmatrix_batch', 1)

--------
See Also
--------

* :doc:`subtom_eigs`
* :doc:`subtom_join_eigencoeffs_pca`
* :doc:`subtom_join_eigenvolumes`
* :doc:`subtom_parallel_ccmatrix`
* :doc:`subtom_parallel_eigencoeffs_pca`
* :doc:`subtom_parallel_eigenvolumes`
* :doc:`subtom_parallel_xmatrix_pca`
* :doc:`subtom_prepare_ccmatrix`
* :doc:`subtom_svds`
