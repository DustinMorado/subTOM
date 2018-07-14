=============
compare_motls
=============

Compares orientations and shifts between two motls.

.. code-block:: Matlab

    compare_motls(
        motl_a_fn,
        motl_b_fn,
        write_diffs,
        diffs_ouput_fn)

Takes the motls given by ``motl_a_fn`` and ``motl_b_fn`` and calculates the
differences for both the orientations and coordinates between corresponding
particles in each motive list. if ``write_diffs`` evaluates to true as a
boolean, then also a csv file with the differences in coordinates and
orientations to ``diffs_output_fn``.

--------
Example:
--------

.. code-block:: Matlab

    compare_motls('combinedmotl/allmotl_1.em', ...
        'combinedmotl/allmotl_2.em', true, ...
        'combinedmotl/allmotl_1_2_diff.csv')


