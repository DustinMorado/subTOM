======================
subtom_scale_noisemotl
======================

Scales a the individual noise motive lists corresponding to a given MOTL file by
a given factor. It first concatenates all the necessary input noise motive
lists, then scales the motive list by factor and then finally splits the motive
list again by tomogram.

This MOTL manipulation script uses three MATLAB compiled scripts below:

- :doc:`../functions/subtom_cat_motls`
- :doc:`../functions/subtom_scale_motl`
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

cat_motls_exec
  Concatenate motive lists executable

scale_motl_exec
  Scale motive list executable

split_motl_by_row_exec
  Split MOTL by row executable.

motl_dump_exec
  MOTL dump executable

File Options
------------

iteration
  The iteration of the all particle motive list to process from: input will be
  all_motl_fn_prefix_iteration.em (define as integer e.g. iteration=1)

all_motl_fn_prefix
  Relative path and prefix to allmotl file from scratch directory.

input_noise_motl_fn_prefix
  Relative path and prefix to input noisemotls.

output_noise_motl_fn_prefix
  Relative path and prefix to output noisemotls.

Tomogram Options
----------------

tomo_row
  Row number of allmotl for tomogram numbers.

Scaling Options
---------------

scale_factor
  How much to scale up the tomogram coordinate extraction positions (rows 8
  through 10 in the MOTL), e.g. To scale from bin8 to bin4 the factor would be
  2.

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    cat_motls_exec="${exec_dir}/MOTL/subtom_cat_motls"

    scale_motl_exec="${exec_dir}/MOTL/subtom_scale_motl"

    split_motl_by_row_exec="${exec_dir}/MOTL/subtom_split_motl_by_row"

    motl_dump_exec="${exec_dir}/MOTL/motl_dump"

    iteration="1"

    all_motl_fn_prefix="combinedmotl/allmotl"

    input_noise_motl_fn_prefix="../bin8/combinedmotl/noisemotl"

    output_noise_motl_fn_prefix="combinedmotl/noisemotl"

    tomo_row="7"

    scale_factor="2"
