==========
join_motls
==========

Combines individual subtomogram motive lists into a single allmotl.

.. code-block:: Matlab

    join_motls(
        iteration,
        all_motl_fn_prefix,
        ptcl_motl_fn_prefix)

Takes the individual subtomogram motive lists with the name format
``PTCL_MOTL_FN_PREFIX_*_#.em`` where the * goes from 1 to the number of
subtomogram motive lists and where # is ``ITERATION`` + 1, and combines all of
them into a single motivelist that is written out as
``ALL_MOTL_FN_PREFIX_#.em``.

--------
Example:
--------

.. code-block:: Matlab

    join_motls(1, 'combinedmotl/allmotl', 'motls/motl')


