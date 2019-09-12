=================
subtom_scale_motl
=================

Scales a given motive list by a given factor.

.. code-block:: Matlab

    subtom_scale_motl(
        'input_motl_fn', input_motl_fn (''),
        'output_motl_fn', output_motl_fn (''),
        'scale_factor', scale_factor (1))

Takes the motive list given by ``input_motl_fn``, and scales it by
``scale_factor``, and then writes the transformed motive list out as
``output_motl_fn``.

-------
Example
-------

.. code-block:: Matlab

    subtom_scale_motl(...
        'input_motl_fn', '../bin8/combinedmotl/allmotl_2.em', ...
        'output_motl_fn', 'combinedmotl/allmotl_1.em', ...
        'scale_factor', 2)

--------
See Also
--------

* :doc:`subtom_cat_motls`
* :doc:`subtom_clean_motl`
* :doc:`subtom_compare_motls`
* :doc:`subtom_even_odd_motl`
* :doc:`subtom_random_subset_motl`
* :doc:`subtom_seed_positions`
* :doc:`subtom_split_motl_by_row`
* :doc:`subtom_transform_motl`
* :doc:`subtom_unclass_motl`
