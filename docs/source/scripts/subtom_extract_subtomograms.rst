===========================
subtom_extract_subtomograms
===========================

This script takes an input number of cores, and on each core extract one
tomogram at a time as written in a specified row of the all motive list.
Parallelization works by writing a start file upon openinig of a tomo, and a
completion file.  After tomogram extraction, it moves on to the next tomogram
that hasn't been started.

This tomogram extraction script uses one MATLAB compiled scripts below:

- :doc:`../functions/subtom_extract_subtomograms`

-------
Options
-------

Directories
-----------

tomogram_dir
  Absolute path to the folder where the tomograms are stored

scratch_dir
  Absolute path to the folder with the input to be processed.
  Other paths are relative to this one.

mcr_cache_dir
  Absolute path to MCR directory for the processing.

exec_dir
  Directory for executables

Variables
---------

extract_exe
  Subtomogram extraction executable

motl_dump_exe
  MOTL dump executable

Memory Options
--------------

mem_free
  The amount of memory the job requires for alignment. This variable determines
  whether a number of CPUs will be requested to be dedicated for each job. At
  24G, one half of the CPUs on a node will be dedicated for each of the
  processes (12 CPUs). At 48G, all of the CPUs on the node will be dedicated for
  each of the processes (24 CPUs).

mem_max
  The upper bound on the amount of memory the alignment job is allowed to use.
  If any of the processes request or require more memory than this, the queue
  will kill the process. This is more of an option for safety of the cluster to
  prevent the user from crashing the cluster requesting too much memory.

Other Cluster Options
---------------------

job_name
  The job name prefix that will be used for the cluster submission scripts, log
  files, and error logs for the processing. Be careful that this name is unique
  because previous submission scripts, logs, and error logs with the same job
  name prefix will be overwritten in the case of a name collision.

run_local
  If the user wants to skip the cluster and run the job locally, this value
  should be set to 1.

Subtomogram Extraction Workflow Options
---------------------------------------

File Options
------------

iteration
  The iteration of the all particle motive list to extract from : input will be
  all_motl_fn_prefix_iteration.em (define as integer)

all_motl_fn_prefix
  Relative path to allmotl file from root folder.

subtomo_fn_prefix
  Relative path and filename for output subtomograms.

stats_fn_prefix
  Relative path and filename for stats .csv files.

  The CSV format of the subtomogram stats is a single file for each tomogram
  with one line per particle in the tomogram with six columns. The particle
  columns are as follows:

+---------------------------+--------------------------------------------------+
| Column                    | Value                                            |
+===========================+==================================================+
| 1                         | Particle Index (Motive List row 4)               |
+---------------------------+--------------------------------------------------+
| 2                         | Mean value for the subtomogram                   |
+---------------------------+--------------------------------------------------+
| 3                         | Maximum value in the subtomogram                 |
+---------------------------+--------------------------------------------------+
| 4                         | Minimum value in the subtomogram                 |
+---------------------------+--------------------------------------------------+
| 5                         | Standard deviation of values in the subtomogram  |
+---------------------------+--------------------------------------------------+
| 6                         | Variance of values in the subtomogram            |
+---------------------------+--------------------------------------------------+

Tomogram Options
----------------

tomo_row
  Which row in the motl file contains the correct tomogram number.
  Usually row 5 and 7 both correspond to the correct value and can be used
  interchangeably, but there are instances when 5 contains a sequential ordered
  value starting from 1, while 7 contains the correct corresponding tomogram.

Extraction Options
------------------

box_size
  Size of subtomogram in pixels

subtomo_digits
  Leading zeros for subtomograms, for AV3, use 1. Other numbers are useful for
  DYNAMO.

reextract
  Set reextract to 1 if you want to force the program to re-extract subtomograms
  even if the stats file and the subtomograms already exist. If the stats file
  for the tomogram exists and is the correct size the whole tomogram will be
  skipped. If the subtomogram exists it will also be skipped, unless this option
  is true.

preload_tomogram
  Set preload_tomogram to 1 if you want to read the whole tomogram into memory
  before extraction. This is the fastest way to extract particles however the
  system needs to be able to have the memory to fit the whole tomogram into
  memory or otherwise it will crash. If it is set to 0, then either the
  subtomograms can be extracted using a memory-map to the data, or read directly
  from the file.

use_tom_red
  Set use_tom_red to 1 if you want to use the AV3/TOM function tom_red to
  extract particles. This requires that preload_tomogram above is set to 1. This
  is the original way to extract particles, but it seemed to sometimes produce
  subtomograms that were incorrectly sized. If it is set to 0 then an inlined
  window function is used instead.

use_memmap
  Set use_memmap to 1 to memory-map the tomogram and read subtomograms from this
  map. This appears to be a little slower than having the tomogram fully in
  memory without the massive memory footprint. However, it also appears to be
  slightly unstable and may crash unexpectedly. If it is set to 0 and
  preload_tomogram is also 0, then subtomograms will be read directly from the
  tomogram on disk. This also requires much less memory, however it appears to
  be extremely slow, so this only makes sense for a large number of tomograms
  being extracted on the cluster.

-------
Example
-------

.. code-block:: bash

    tomogram_dir="/net/dstore2/teraraid/dmorado/subTOM_tutorial/data/tomos/bin8"

    scratch_dir="${PWD}"

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    extract_exe="${exec_dir}/alignment/subtom_extract_subtomograms"

    motl_dump_exe="${exec_dir}/MOTL/motl_dump"

    mem_free="1G"

    mem_max="64G"

    job_name="subTOM"

    run_local=0

    iteration=1

    all_motl_fn_prefix="combinedmotl/allmotl"

    subtomo_fn_prefix="subtomograms/subtomo"

    stats_fn_prefix="subtomograms/stats/tomo"

    tomo_row=7

    box_size=128

    subtomo_digits=1

    reextract=0

    preload_tomogram=1

    use_tom_red=0

    use_memmap=0
