=================
split_motl_by_row
=================

Split a MOTL file by a given row.

.. code-block:: Matlab

    split_motl_by_row(
        input_motl_fn,
        motl_row,
        output_motl_fn_prfx)

Takes the ``motl`` file specified by ``input_motl_fn`` and writes out a seperate
``motl`` file with ``output_motl_fn_prfx`` as the prefix where each output file
corresponds to a unique value of the row ``motl_row`` in ``input_motl_fn``.

--------
Example:
--------

.. code-block:: Matlab

    split_motl_by_row('combinedmotl/allmotl_1.em', 7, ...
        'combinedmotl/allmotl_1_tomo')

--------
See Also
--------

:doc:`scale_motl`


