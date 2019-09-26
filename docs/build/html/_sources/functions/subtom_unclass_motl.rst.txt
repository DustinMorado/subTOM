===================
subtom_unclass_motl
===================

Removes the iclass information from a motive list.

.. code-block:: Matlab

    subtom_unclass_motl(
        'input_motl_fn', input_motl_fn (''),
        'output_motl_fn', output_motl_fn (''))

Takes the motive list given by ``input_motl_fn``, and removes all of the
iclass information setting all of the particles to 1, this can be useful
when moving from classified motive lists to all-particle alignments.  Then
unclassed motive list is written out as ``output_motl_fn``.

-------
Example
-------

.. code-block:: Matlab

    subtom_unclass_motl(...
        'input_motl_fn', 'combinedmotl/allmotl_wmd_2.em', ...
        'output_motl_fn', 'combinedmotl/allmotl_wmd_unclassed_2.em')

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
* :doc:`subtom_split_motl_by_row`
* :doc:`subtom_transform_motl`
