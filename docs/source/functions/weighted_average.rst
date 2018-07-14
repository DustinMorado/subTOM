================
weighted_average
================

Joins and weights parallel average subsets.

.. code-block:: matlab

    weighted_average(
        ref_fn_prefix,
        motl_fn_prefix,
        wegiht_fn_prefix,
        iteration,
        iclass)

Takes the parallel average subsets with the name prefix ``ref_fn_prefix``, the
allmotl file with name prefix ``motl_fn_prefix`` and weight volume subsets with
the name prefix ``weight_fn_prefix`` to generate the final average, which should
then be used as the reference for iteration number ``iteration``.  ``iclass``
describes which class outside of one is included in the final average and is
used to correctly scale the average and weights.

--------
Example:
--------

.. code-block:: matlab

    weighted_average('./ref/ref', './combinedmotl/allmotl', ...
        './otherinputs/wei', 3, 1)

Would average all average batches './ref/ref_3_*.em', average all weights
'./otherinputs/wei_3_*.em', using the particles with class number 1, apply
the inverse averaged weight to the average and write out:

* './ref/ref_debug_raw_3.em' - The unweighted average
* './ref/ref_3.em' - The weighted average
* './otherinputs/wei_debug_3.em' - The average weight volume
* './otherinputs/wei_debug_inv_3.em' - The inverse weight applied

--------
See Also
--------

::doc::`parallel_sums`


