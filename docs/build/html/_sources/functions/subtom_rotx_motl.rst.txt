=================
subtom_rotx_motl
=================

Transforms a motive list to (un)apply a tomogram rotx operation.

.. code-block:: Matlab

    subtom_rotx_motl(
        'tomogram_dir', tomogram_dir (''),
        'tomo_row', tomo_row (7),
        'input_motl_fn', input_motl_fn (''),
        'output_motl_fn', output_motl_fn (''),
        'do_rotx', do_rotx (0))

Takes the motive list given by ``input_motl_fn``, and if ``do_rotx`` evaluates to
true as a boolean applies the same transformation as applied by 'clip
rotx' in the IMOD package, and else applies the inverse transformation.
The resulting motive list is then written out as ``output_motl_fn``. The
location of the tomograms needs to be given in ``tomogram_dir``, as well as
the field that specifies which tomogram to use for each particle in
``tomo_row``. The size of the tomogram needs to be known to correctly
transform the particle center coordinates in fields 8-10 in the motive
list.

-------
Example
-------

.. code-block:: Matlab

    subtom_rotx_motl(...
        'tomogram_dir', '/net/teraraid/dmorado/sample/date/tomos/bin4', ...
        'tomo_row', 7, ...
        'input_motl_fn', '../bin4/combinedmotl/allmotl_2.em', ...
        'output_motl_fn', 'combinedmotl/allmotl_bin4_rotx_1.em', ...
        'do_rotx', 0)

--------
See Also
--------

* :doc:`subtom_cat_motls`
* :doc:`subtom_clean_motl`
* :doc:`subtom_compare_motls`
* :doc:`subtom_even_odd_motl`
* :doc:`subtom_random_subset_motl`
* :doc:`subtom_renumber_motl`
* :doc:`subtom_scale_motl`
* :doc:`subtom_seed_positions`
* :doc:`subtom_split_motl_by_row`
* :doc:`subtom_transform_motl`
* :doc:`subtom_unclass_motl`
