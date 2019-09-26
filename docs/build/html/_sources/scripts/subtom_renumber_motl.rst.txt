====================
subtom_renumber_motl
====================

Renumbers the particle indices in a motive list, either sequentially or in a way
that preserves particle indices while still making sure there are no duplicates
in the list of indices.

This MOTL manipulation script uses one MATLAB compiled scripts below:

- :doc:`../functions/subtom_renumber_motl`

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

renumber_motl_exec
  Renumber motive list executable

File Options
------------

input_motl_fn
  Relative path and name of the input MOTL file to be renumbered.

output_motl_fn
  Relative path and name of the output MOTL file.

Renumber Options
----------------

sort_row
  If you want to have the output MOTL file sorted by a particular field before
  renumbering then specify it here.

do_sequential
  If the following is 1, particles will be completely renumbered from 1 to the
  number of particles in the motive list. If it is 0, particles will be
  renumbered in a way that preserves the original index while still removing any
  duplicate indices. As a guide you probably want to renumber sequentially after
  cleaning from initial oversampled coordinates, but do not want to renumber
  sequentially in other cases.

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    renumber_motl_exec="${exec_dir}/MOTL/subtom_renumber_motl"

    input_motl_fn="combinedmotl/allmotl_1.em"

    output_motl_fn="combinedmotl/allmotl_unique_1.em"

    sort_row="4"

    do_sequential="0"
