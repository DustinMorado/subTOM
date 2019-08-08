===============================
subtom_multiref_rand_class_motl
===============================

Randomizes a given number of classes in a motive list.

This MOTL manipulation script uses one MATLAB compiled scripts below:

- :doc:`../functions/subtom_rand_class_motl`

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

rand_exec
  Randomize Motive List executable.

File Options
------------

input_motl_fn
  Relative path and name of the input motivelist to be randomized in class.

output_motl_fn
  Relative path and name of the output motivelist.

Randomize MOTL Options
----------------------

num_classes
  The number of classes to split the initial motive list into. The classes will
  be assigned randomly evenly within the valid particles, (non-negative class
  values excluding class 2), with the class number starting at 3 to not
  interfere with the classes 1 and 2 which are reserved for AV3's thresholding
  process.

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    rand_exec="${exec_dir}/classification/multiref/subtom_rand_class_motl

    input_motl_fn="combinedmotl/allmotl_1.em"

    output_motl_fn="combinedmotl/allmotl_multiref_1.em"

    num_classes=2
