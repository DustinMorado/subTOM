===================
subtom_unclass_motl
===================

Removes the iclass information in the 20th field of a motive list.

This MOTL manipulation script uses one MATLAB compiled scripts below:

- :doc:`../functions/subtom_unclass_motl`

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

unclass_motl_exec
  Unclass motive list executable

File Options
------------

input_motl_fn
  Relative path and name of the input MOTL file to be unclassed.

output_motl_fn
  Relative path and name of the output MOTL file.

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    scale_motl_exec="${exec_dir}/MOTL/subtom_unclass_motl"

    input_motl_fn="combinedmotl/allmotl_wmd_5.em"

    output_motl_fn="combinedmotl/allmotl_wmd_unclassed_1.em"
