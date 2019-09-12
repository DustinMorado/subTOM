=========================
subtom_random_subset_motl
=========================

Draws a random subset from a given MOTL file.

This MOTL manipulation script uses one MATLAB compiled scripts below:

- :doc:`../functions/subtom_random_subset_motl`

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

random_subset_motl_exec
  Random subset motive list executable

File Options
------------

input_motl_fn
  Relative path and name of the input MOTL file to draw the subset from.

output_motl_fn
  Relative path and name of the output MOTL file.

Subset Options
--------------

subset_size
  How many particles to be included in the subset.

subset_row
  The following describes a field in the MOTL to equally distribute particles of
  the subset amongst. Such that if subset_row was the tomogram row (7), and
  there were ten tomograms described in the motive list, then the subset of 1000
  particles would have 100 particles from each tomogram. If there are more
  unique values than the subset size then the field is not taken into account.

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    random_subset_motl_exec="${exec_dir}/MOTL/subtom_random_subset_motl"

    input_motl_fn="combinedmotl/allmotl_1.em"

    output_motl_fn="combinedmotl/s5kmotl_1.em"

    subset_size=5000

    subset_row=7
