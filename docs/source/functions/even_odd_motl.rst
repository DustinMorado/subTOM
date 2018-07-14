=============
even_odd_motl
=============

Split a MOTL file into even odd halves.

.. code-block:: Matlab

    even_odd_motl(
        input_motl_fn,
        even_motl_fn,
        odd_motl_fn)

Takes the motl file specified by ``input_motl_fn`` and writes out seperate
motl files with ``even_motl_fn`` and ``odd_motl_fn`` where each output file
corresponds to a half of ``input_motl_fn``.

--------
Example:
--------

.. code-block:: Matlab

    even_odd_motl('combinedmotl/allmotl_1.em', ...
        'even/combinedmotl/allmotl_1.em', 'odd/combinedmotl/allmotl_1.em');

--------
See Also
--------

:doc:`split_motl_by_row`


