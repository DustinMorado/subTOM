====================
subtom_compare_motls
====================

Compares orientations and shifts between two MOTLs.

.. code-block:: Matlab

    subtom_compare_motls(
        'motl_1_fn', motl_1_fn (''),
        'motl_2_fn', motl_2_fn (''),
        'write_diffs', write_diffs (0),
        'output_diffs_fn', output_diffs_fn (''))

Takes the motls given by ``motl_1_fn`` and ``motl_2_fn`` and calculates the
differences for both the orientations and coordinates between corresponding
particles in each motive list. If ``write_diffs`` evaluates to true as a
boolean, then also a CSV file with the differences in coordinates and
orientations to ``diffs_output_fn``.

-------
Example
-------

.. code-block:: Matlab

    subtom_compare_motls(...
        'motl_1_fn', 'combinedmotl/allmotl_1.em', ...
        'motl_2_fn', 'combinedmotl/allmotl_2.em', ...
        'write_diffs', 1, ...
        'output_diffs_fn', 'combinedmotl/allmotl_1_2_diff.csv')

--------
See Also
--------

* :doc:`subtom_cat_motls`
* :doc:`subtom_clean_motl`
* :doc:`subtom_even_odd_motl`
* :doc:`subtom_scale_motl`
* :doc:`subtom_seed_positions`
* :doc:`subtom_split_motl_by_row`
* :doc:`subtom_transform_motl`
