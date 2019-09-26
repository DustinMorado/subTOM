================
subtom_rotx_motl
================

Transforms a given MOTL file so that it matches a tomogram rotated or not
rotated by IMOD's 'clip rotx' command.

This MOTL manipulation script uses one MATLAB compiled scripts below:

- :doc:`../functions/subtom_rotx_motl`

-------
Options
-------

Directories
-----------

tomogram_dir
  Absolute path to the folder where the tomograms used in the INPUT motive list
  are stored. 

scratch_dir
  Absolute path to the folder with the input to be processed.
  Other paths are relative to this one.

mcr_cache_dir
  Absolute path to MCR directory for the processing.

exec_dir
  Directory for executables

Variables
---------

rotx_motl_exec
  Rotx motive list executable

File Options
------------

input_motl_fn
  Relative path and name of the input MOTL file to be transformed.

output_motl_fn
  Relative path and name of the output MOTL file.

Rotx Options
------------

tomo_row
  Row number of allmotl for tomogram numbers.

do_rotx
  If the following is set to 1 the input MOTL will be transformed in the same
  way as done by 'clip rotx'. If it is set to 0 the input MOTL will be
  transformed by the inverse operation (a positive 90 degree rotation about the
  X-axis).

-------
Example
-------

.. code-block:: bash

    tomogram_dir="/net/dstore2/teraraid/dmorado/subTOM_tutorial/data/tomos/bin4"

    scratch_dir="${PWD}"

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    rotx_motl_exec="${exec_dir}/MOTL/subtom_rotx_motl"

    input_motl_fn="../bin4/combinedmotl/allmotl_1.em"

    output_motl_fn="combinedmotl/allmotl_1.em"

    tomo_row="7"

    do_rotx="0"
