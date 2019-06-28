====================
subtom_even_odd_motl
====================

Splits a given MOTL file into even/odd halves for gold-standard refinement.

This MOTL manipulation script uses one MATLAB compiled scripts below:

- :doc:`../functions/subtom_even_odd_motl`

-------
Options
-------

Directories
-----------

scratch_dir
  Absolute path to the folder with the input to be processed.
  Other paths are relative to this one.

mcr_cache_dir
  Absolute path to MCR directory for the processing.

exec_dir
  Directory for executables

Variables
---------

even_odd_motl_exec
  Even-Odd split motive list executable

File Options
------------

input_motl_fn
  Relative path and name of the input MOTL file to be split.

output_motl_fn
  Relative path and name of the output MOTL file where the even and odd halves
  are specified by the class number in the 20th row of the motive list. The even
  half inherits the current class number plus 200 and the odd half inherits the
  current class numbers plus 100.

even_motl_fn
  Relative path and name of the output even MOTL file.

odd_motl_fn
  Relative path and name of the output odd MOTL file.

Even / Odd Options
------------------

split_row
  The following specifies which row of the MOTL will be used to split the data.
  To simply split into even and odd halves use the particle running ID, which is
  row 4. To split the halves by tomogram use row 5 or 7, and to split the halves
  by tube or sphere use row 6.

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    even_odd_exec="${exec_dir}/MOTL/subtom_even_odd_motl"

    input_motl_fn="combinedmotl/allmotl_1.em"

    output_motl_fn="combinedmotl/allmotl_eo_1.em"

    even_motl_fn="even/combinedmotl/allmotl_1.em"

    odd_motl_fn="odd/combinedmotl/allmotl_1.em"

    split_row=4
