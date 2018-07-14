==========
clean_motl
==========

Cleans a given motl file based on distance and or cc scores.

.. code-block:: matlab

    clean_motl(
        input_motl_fn,
        output_motl_fn,
        tomo_row,
        distance_cutoff,
        cc_cutoff)

Takes the motl given by ``input_motl_fn``, and splits it internally by
tomogram given by the row ``tomo_row`` in the motl, and then removes particles
that are within ``distance_cutoff`` pixels of each other, keeping the particle
with the higher ccc, and then particles with a ccc lower than ``cc_cutoff``
are also removed and the final cleaned motl file is written out to
``output_motl_fn``.

--------
Example:
--------

.. code-block:: matlab

    clean_motl('combinedmotl/allmotl_1.em', ...
        'combinedmotl/allmotl_clean_1.em', 7, 6, 0);


