========================
subtom_split_motl_by_row
========================

Split a MOTL file by a given row.

.. code-block:: Matlab

    subtom_split_motl_by_row(
        'input_motl_fn', input_motl_fn (''),
        'output_motl_fn_prefix', output_motl_fn_prefix (''),
        'split_row', split_row (7))

Takes the MOTL file specified by ``input_motl_fn`` and writes out a seperate
MOTL file with ``output_motl_fn_prfx`` as the prefix where each output file
corresponds to a unique value of the row ``split_row`` in ``input_motl_fn``.

-------
Example
-------

.. code-block:: Matlab

    subtom_split_motl_by_row(...
        'input_motl_fn', 'combinedmotl/allmotl_1.em', ...
        'output_motl_fn', 'combinedmotl/allmotl_1_tomo', ...
        'split_row', 7)

--------
See Also
--------

* :doc:`subtom_cat_motls`
* :doc:`subtom_clean_motl`
* :doc:`subtom_compare_motls`
* :doc:`subtom_even_odd_motl`
* :doc:`subtom_random_subset_motl`
* :doc:`subtom_renumber_motl`
* :doc:`subtom_rotx_motl`
* :doc:`subtom_scale_motl`
* :doc:`subtom_seed_positions`
* :doc:`subtom_transform_motl`
* :doc:`subtom_unclass_motl`
