====================
subtom_even_odd_motl
====================

Split a MOTL file into even odd halves.

.. code-block:: Matlab

    subtom_even_odd_motl(
        'input_motl_fn', input_motl_fn (''),
        'output_motl_fn', output_motl_fn (''),
        'even_motl_fn', even_motl_fn, (''),
        'odd_motl_fn', odd_motl_fn (''),
        'split_row', split_row (4))

Takes the MOTL file specified by ``input_motl_fn`` and writes out seperate MOTL
files with ``even_motl_fn`` and ``odd_motl_fn`` where each output file
corresponds to roughly half of ``input_motl_fn``. The motive list can also write
a single motive list file with the half split described using the iclass (20th
row of the motive list) where the odd half takes particle's current class number
plus 100 and the even half takes the particle's current class number plus 200.
The MOTL is split by the values in ``split_row``, initially just taking even/odd
halves of the unique values in that given row, and then this is slightly
adjusted by naively adding to the lesser half until closest to half is found.

-------
Example
-------

.. code-block:: Matlab

    subtom_even_odd_motl(...
        'input_motl_fn', 'combinedmotl/allmotl_1.em', ...
        'output_motl_fn', 'combinedmotl/allmotl_eo_1.em', ...
        'even_motl_fn', 'even/combinedmotl/allmotl_1.em', ...
        'odd_motl_fn', 'odd/combinedmotl/allmotl_1.em', ...
        'split_row', 4)

--------
See Also
--------

* :doc:`subtom_cat_motls`
* :doc:`subtom_clean_motl`
* :doc:`subtom_compare_motls`
* :doc:`subtom_scale_motl`
* :doc:`subtom_seed_positions`
* :doc:`subtom_split_motl_by_row`
* :doc:`subtom_transform_motl`
