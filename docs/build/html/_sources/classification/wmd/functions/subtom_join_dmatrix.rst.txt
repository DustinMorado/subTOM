===================
subtom_join_dmatrix
===================

Combines chunks of D-Matrix into the final matrix.

.. code-block:: Matlab

    subtom_join_dmatrix(
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'dmatrix_fn_prefix', dmatrix_fn_prefix ('class/dmatrix_wmd'),
        'ptcl_fn_prefix', ptcl_fn_prefix ('subtomograms/subtomo'),
        'mask_fn', mask_fn ('none'),
        'iteration', iteration (1),
        'num_dmatrix_batch', num_dmatrix_batch (1))

Looks for partial chunks of the D-matrix with the file name given by
``dmatrix_fn_prefix``, ``iteration``, and # where # is from 1 to
``num_dmatrix_batch``, and combines them into a final matrix of differences
written out as described by ``dmatrix_fn_prefix`` and ``iteration``.

-------
Example
-------

.. code-block:: Matlab

    subtom_join_dmatrix(
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'dmatrix_fn_prefix', 'class/dmatrix', ...
        'ptcl_fn_prefix', 'subtomograms/subtomo', ...
        'mask_fn', 'otherinputs/classification_mask.em', ...
        'iteration', 1, ...
        'num_dmatrix_batch', 100);

--------
See Also
--------

* :doc:`subtom_eigenvolumes_wmd`
* :doc:`subtom_join_coeffs`
* :doc:`subtom_parallel_coeffs`
* :doc:`subtom_parallel_dmatrix`
