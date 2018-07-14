==========
clean_motl
==========

Cleans a given MOTL file based on distance and/or CC scores.

This MOTL manipulation script uses one MATLAB compiled scripts below:

- :doc:`../functions/clean_motl`

-------
Options
-------

Directories
-----------

scratch_dir
  Absolute path to the folder with the input to be processed.
  Other paths are relative to this one.

  * **Example**
    - /net/dstore2/teraraid/dmorado/subTOM_tutorial/subtomo/bin1/even

mcr_cache_dir
  Absolute path to MCR directory for the processing.

  * **Example**
    - ${scratch_dir}/mcr

exec_dir
  Directory for executables

  * **Example**
    - /net/dstore2/teraraid/dmorado/software/subTOM/bin

File Options
------------

input_motl_fn
  Relative or absolute path and name of the input MOTL file to be cleaned.

  * **Example**
    - combinedmotl/allmotl_2.em

output_motl_fn
  Relative or absolute path and name of the output MOTL file.

  * **Example**
    - combinedmotl/allmotl_clean_d2_c0_2.em

Variables
---------

clean_motl_exec
  clean_motl executable

  * **Example**
    - ${exec_dir}/clean_motl

Clean Options
-------------

tomo_row
  Which row in the motl file contains the correct tomogram number.
  Usually row 5 and 7 both correspond to the correct value and can be used
  interchangeably, but there are instances when 5 contains a sequential ordered
  value starting from 1, while 7 contains the correct corresponding tomogram.

  * **Example**
    - 7

distance_cutoff
  Particles that are less than this distance in pixels from another particle
  will be cleaned with the particle with the highest CCC kept while the others
  are removed from the output MOTL file.

  * **Example**
    - 2

cc_cutoff
  Particles with a CCC below this cutoff will be removed from the output MOTL
  file. Use a value of -1 to only clean by distance.

  * **Example**
    - 0

