================
subtom_cat_motls
================

Concatenate motive lists and print on the standard output.

.. code-block:: matlab

    subtom_cat_motls(
        'write_motl', write_motl (0),
        'output_motl_fn', output_motl_fn (''),
        'write_star', write_star (0),
        'output_star_fn', output_star_fn (''),
        'sort_row' sort_row (0),
        'do_quiet', do_quiet (0),
        input_motl_fns)

Takes the motive lists given in ``input_motl_fns``, and concatenates them all
together.  If ``write_motl`` evaluates to True as a boolean then the joined
motive lists are written out as ``ouput_motl_fn``. The function writes the
motive list information in STAR format and if ``write_star`` evaluates to True
as a boolean then the joined motive lists are also written out as
``output_star_fn``. Since the input motive lists can be in any order and this
does not guarantee that the output motive list will have any form of sorting, if
``sort_row`` is a valid field number the output motive list will be sorted by
``sort_row``.

The motive list is also printed to standard ouput. An arbitrary choice has been
made to ouput the motive list in STAR format, since it is used in other more
well-known EM software packages. If this screen output is not desired set
``do_quiet`` to evaluate to true as a boolean.

-------
Example
-------

.. code-block:: matlab

    subtom_cat_motls(...
        'write_motl', 1, ...
        'output_motl_fn', 'combinedmotl/allmotl_1_joined.em', ...
        'write_star', 1, ...
        'output_star_fn', 'combinedmotl/allmotl_1_joined.star', ...
        'sort_row', 4, ...
        'do_quiet', 1, ...
        'combinedmotl/allmotl_1_tomo_1.em', ...
        'combinedmotl/allmotl_1_tomo_3.em');

--------
See Also
--------

* :doc:`subtom_clean_motl`
* :doc:`subtom_compare_motls`
* :doc:`subtom_even_odd_motl`
* :doc:`subtom_random_subset_motl`
* :doc:`subtom_scale_motl`
* :doc:`subtom_seed_positions`
* :doc:`subtom_split_motl_by_row`
* :doc:`subtom_transform_motl`
* :doc:`subtom_unclass_motl`
