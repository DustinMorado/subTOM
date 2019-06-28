=================
subtom_scale_motl
=================

Scales a given MOTL file by a given factor. It also resets the shifts in the
motive list (rows 11 to 13) to values less than 1 so that with a given scale
factor of 1, it can apply the shifts to the tomogram coordinates (rows 8 to 10)
so that particles can be reextracted better centered to allow for tighter CC
masks to be used in further iterations of alignment.

This MOTL manipulation script uses one MATLAB compiled scripts below:

- :doc:`../functions/subtom_scale_motl`

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

scale_motl_exec
  Scale motive list executable

File Options
------------

input_motl_fn
  Relative path and name of the input MOTL file to be unbinned.

output_motl_fn
  Relative path and name of the output MOTL file.

Scaling Options
---------------

scale_factor
  How much to scale up the tomogram coordinate extraction positions (rows 8
  through 10 in the MOTL) and the particle shifts (rows 11 through 13).

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    scale_motl_exec="${exec_dir}/MOTL/subtom_scale_motl"

    input_motl_fn="../bin8/combinedmotl/allmotl_1.em"

    output_motl_fn="combinedmotl/allmotl_1.em"

    scale_factor=2
