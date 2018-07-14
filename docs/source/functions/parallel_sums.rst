=============
parallel_sums
=============

Creates raw sums and sums of Fourier weights sum in a batch.

.. code-block:: Matlab

    parallel_sums(
        ptcl_start_idx,
        avg_batch_size,
        iteration,
        allmotl_fn_prefix,
        ref_fn_prefix,
        ptcl_fn_prefix,
        tomo_row,
        weight_fn_prefix,
        weight_sum_fn_prefix,
        iclass,
        process_idx)

Aligns a subset of particles using the rotations and shifts in
``allmotl_fn_prefix_iteration`` starting from ``ptcl_start_idx`` and with a
subset size of ``avg_batch_size`` to make a raw particle sum
``ref_fn_prefix_iteration_process_idx``. Fourier weight volumes with name prefix
``weight_fn_prefix`` will also be aligned and summed to make a weight sum
``weight_sum_fn_prefix_iteration_process_idx``. ``tomo_row`` describes which row
of the motl file is used to determine the correct tomogram fourier weight file.
``iclass`` describes which class outside of one is included in the averaging. 

--------
Example:
--------

.. code-block:: Matlab

    parallel_sums(1, 100, 3, 'combinedmotl/allmotl', 'ref/ref', ...
        'subtomograms/subtomo', 5, 'otherinputs/ampspec', ...
        'otherinputs/wei', 1, 1)

Would sum the first hundred particles, using particles with class number 1, and
the first hundred corresponding weight volumes using the tomogram number stored
in the fifth row of the allmotl file 'combinedmotl/allmotl_3.em'. The function
will write out the follwing files:

* 'ref/ref_3_1.em' - The first subset of sums generated in parallel
* 'otherinputs/wei_3_1.em' - The corresponding subset sum of weights

--------
See Also
--------

:doc:`weighted_average`


