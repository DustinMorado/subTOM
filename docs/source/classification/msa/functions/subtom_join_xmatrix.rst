===================
subtom_join_xmatrix
===================

Combines chunks of X-Matrix into the final matrix.

.. code-block:: Matlab

    subtom_join_xmatrix(
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'xmatrix_fn_prefix', xmatrix_fn_prefix ('class/xmatrix_msa'),
        'ptcl_fn_prefix', ptcl_fn_prefix ('subtomograms/subtomo'),
        'mask_fn', mask_fn ('none'),
        'iteration', iteration (1),
        'num_xmatrix_batch', num_xmatrix_batch (1))

Looks for partial chunks of the X-matrix with the file name given by
``xmatrix_fn_prefix``, ``iteration``, and # where # is from 1 to
``num_xmatrix_batch``, and combines them into a final matrix of coefficients
written out as described by ``xmatrix_fn_prefix`` and ``iteration``.

-------
Example
-------

.. code-block:: Matlab

    subtom_join_xmatrix(
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'xmatrix_fn_prefix', 'class/xmatrix', ...
        'ptcl_fn_prefix', 'subtomograms/subtomo', ...
        'mask_fn', 'otherinputs/classification_mask.em', ...
        'iteration', 1, ...
        'num_xmatrix_batch', 100);

--------
See Also
--------

* :doc:`subtom_eigenvolumes_msa`
* :doc:`subtom_join_eigencoeffs_msa`
* :doc:`subtom_parallel_eigencoeffs_msa`
* :doc:`subtom_parallel_xmatrix_msa`
