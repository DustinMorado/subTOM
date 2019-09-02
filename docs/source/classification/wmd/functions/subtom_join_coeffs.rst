==================
subtom_join_coeffs
==================

Combines coefficient batches into the final matrix.

.. code-block:: Matlab

    subtom_join_coeffs(
        'coeff_fn_prefix', coeff_fn_prefix ('class/coeff_wmd'),
        'iteration', iteration (1),
        'num_coeff_batch', num_coeff_batch (1))

Looks for partial chunks of the low-rank approximation coefficients of projected
particles with the file name given by ``coeff_fn_prefix``, ``iteration`` and
# where # is from 1 to ``num_coeff_batch``, and combines them into a final
matrix of coefficients written out as described by ``coeff_fn_prefix``, and
``iteration``.

-------
Example
-------

.. code-block:: Matlab

    subtom_join_coeffs(...
        'coeff_fn_prefix', 'class/coeff', ...
        'iteration', 1, ...
        'num_coeff_batch', 100)

--------
See Also
--------

* :doc:`subtom_eigenvolumes_wmd`
* :doc:`subtom_join_dmatrix`
* :doc:`subtom_parallel_coeffs`
* :doc:`subtom_parallel_dmatrix`
