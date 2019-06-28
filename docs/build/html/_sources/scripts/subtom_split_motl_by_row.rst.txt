========================
subtom_split_motl_by_row
========================

Splits a given MOTL file by unique entries in a given field.

This MOTL manipulation script uses one MATLAB compiled scripts below:

- :doc:`../functions/subtom_split_motl_by_row`

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

split_motl_by_row_exec
  Split MOTL by row executable.

File Options
------------

input_motl_fn
  Relative path and name of the input MOTL file to be split.

output_motl_fn_prefix
  Relative path and filename prefix of output MOTL files.

Split Motl Options
------------------

split_row
  Which row to split the input MOTL file by.

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    split_motl_by_row_exec="${exec_dir}/MOTL/subtom_split_motl_by_row"

    input_motl_fn="combinedmotl/allmotl_1.em"

    output_motl_fn_prefix="combinedmotl/allmotl_1_tomo"

    split_row=7
