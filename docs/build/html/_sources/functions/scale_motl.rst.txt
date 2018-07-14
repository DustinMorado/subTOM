==========
scale_motl
==========

Scales a given motive list by a given factor and writes it out.

.. code-block:: Matlab

    scale_motl(
        input_motl_fn,
        output_motl_fn,
        scale_factor)

Takes the motive list given by ``input_motl_fn``, and scales it by
``scale_factor``, and then writes the transformed motive list out as
``output_motl_fn``.

--------
Example:
--------

.. code-block:: Matlab

    scale_motl('../bin8/combinedmotl/allmotl_2.em', ...
        'combinedmotl/allmotl_1.em', 2);


