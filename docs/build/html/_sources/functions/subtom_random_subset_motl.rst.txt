=========================
subtom_random_subset_motl
=========================

Generates a random subset of a motive list.

.. code-block:: Matlab

    subtom_random_subset_motl(
        'input_motl_fn', input_motl_fn (''),
        'output_motl_fn', output_motl_fn (''),
        'subset_size', subset_size (1000),
        'subset_row', subset_row (7))

Takes the motive list given by ``input_motl_fn``, and generates a random
subset of ``subset_size`` particles where the subset is distributed equally
over the motive list field ``subset_row``, and then writes the subset motive
list out as ``output_motl_fn``.

-------
Example
-------

.. code-block:: Matlab

    subtom_random_subset_motl(...
        'input_motl_fn', 'combinedmotl/allmotl_2.em', ...
        'output_motl_fn', 'combinedmotl/s5kmotl_2.em', ...
        'subset_size', 5000, ...
        'subset_row', 7)

--------
See Also
--------

* :doc:`subtom_cat_motls`
* :doc:`subtom_clean_motl`
* :doc:`subtom_compare_motls`
* :doc:`subtom_even_odd_motl`
* :doc:`subtom_renumber_motl`
* :doc:`subtom_rotx_motl`
* :doc:`subtom_scale_motl`
* :doc:`subtom_seed_positions`
* :doc:`subtom_split_motl_by_row`
* :doc:`subtom_transform_motl`
* :doc:`subtom_unclass_motl`
