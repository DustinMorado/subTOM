====================
subtom_renumber_motl
====================

Renumbers particle indices in a motive list.

.. code-block:: Matlab

    subtom_renumber_motl(
        'input_motl_fn', input_motl_fn (''),
        'output_motl_fn', output_motl_fn (''),
        'sort_row', sort_row (0),
        'do_sequential', do_sequential (0))

Takes the motive list given by ``input_motl_fn``, and renumbers the particles in
field 4 of the MOTL and writes out the renumbered list to ``output_motl_fn``. If
``do_sequential`` evaluates to true as a boolean then the motive list will just
be renumbered from 1 to the number of particles in the MOTL, and the initial
particle indices will be lost. If ``do_sequential`` evaluates to false as a
boolean, then particle indices will be kept with any duplicates of the particle
index incremented by the largest particle index found in the motive list.

For example if ``do_sequential`` is 0, and we have 100 particles where the first
particle index is 4, and the largest particle index in the motive list is 325.
If there are 3 copies of particle index 16 in the motive list, then it will be
renumbered so that these 3 copies correspond to particle indices 16, 341, and
666. In this way as long as we keep the original motive list we can trace back
the origin of each particle.

-------
Example
-------

.. code-block:: Matlab

    subtom_renumber_motl(...
        'input_motl_fn', 'combinedmotl/allmotl_1.em', ...
        'output_motl_fn', 'combinedmotl/allmotl_unique_1.em', ...
        'sort_row', 4, ...
        'do_sequential', 0)

--------
See Also
--------

* :doc:`subtom_cat_motls`
* :doc:`subtom_clean_motl`
* :doc:`subtom_compare_motls`
* :doc:`subtom_even_odd_motl`
* :doc:`subtom_random_subset_motl`
* :doc:`subtom_rotx_motl`
* :doc:`subtom_scale_motl`
* :doc:`subtom_seed_positions`
* :doc:`subtom_split_motl_by_row`
* :doc:`subtom_transform_motl`
* :doc:`subtom_unclass_motl`
