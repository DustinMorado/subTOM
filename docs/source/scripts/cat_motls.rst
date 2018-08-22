=========
cat_motls
=========

Concatenate motive lists and print on the standard output.

This MOTL manipulation script uses one MATLAB compiled scripts below:

- :doc:`../functions/cat_motls`

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

input_motl_fns
  Relative or absolute path and filename(s) of the input MOTL files to be
  concatenated. You can use shell wildcard characters * and ? to specify a given
  number of files and they will be expanded or you can just list the files one
  by one.

  * **Example**
    - (combinedmotl/allmotl_1.em combinedmotl/allmotl\_\?\?.em)

output_motl_fn
  Relative or absolute path and name of the output MOTL file. If you are not
  going to write an output file just set this variable to 'none'.

  * **Example**
    - combinedmotl/allmotl_sel.em

Variables
---------

cat_motls_exec
  cat_motls executable

  * **Example**
    - ${exec_dir}/cat_motls

Concatenate Options
-------------------

write_output
  If you want to write out the concatenated MOTL files set this to 1, however if
  you just want to print the MOTL contents to the screen, set this to 0.

  * **Example**
    - 1

sort_row
  If you want to have the output MOTL file sorted by a particular field then
  specify it here. If the given value is not a value between 1-20 then the
  output MOTL file will be sorted arbitrarily based on the dir command in
  Matlab.

  * **Example**
    - 4
