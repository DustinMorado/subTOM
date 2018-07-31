=========
cat_motls
=========

Concatenate motive lists and print on the standard output.

.. code-block:: matlab

    cat_motls(
        write_ouput,
        output_motl_fn,
        sort_row,
        input_motl_fns)

Takes the motive lists ``input_motl_fns``, and concatenates them all together.
If ``write_output`` evaluates to True as a boolean then the joined motive
lists are written out as ``ouput_motl_fn``. Since the 
used to find the files, and this does not guarantee that the output motive
list will have any form of sorting, if ``sort_row`` is a valid field number
the output motive list will be sorted by ``sort_row``.

The motive list is also printed to standard ouput. An arbitrary choice has
been made to ouput the motive list in STAR format, since it is used in
other more well-known EM software packages. 

--------
Example:
--------

.. code-block:: matlab

    cat_motls(1, 'combinedmotl/allmotl_1_joined.em', 4, ...
     'combinedmotl/allmotl_1_tomo_1.em', ...
     'combinedmotl/allmotl_1_tomo_3.em');


