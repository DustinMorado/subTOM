================
subtom_cat_motls
================

Concatenate motive lists and print on the standard output.

This MOTL manipulation script uses one MATLAB compiled scripts below:

- :doc:`../functions/subtom_cat_motls`

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

cat_exec
  Concatenate MOTLs executable

File Options
------------

input_motl_fns
  Relative path and filename(s) of the input MOTL files to be concatenated. You
  can use shell wildcard characters * and ? to specify a given number of files
  and they will be expanded or you can just list the files one by one.

output_motl_fn
  Relative path and name of the output MOTL file. If you are not going to write
  an output file just set this variable to ''

output_star_fn
  Relative path and name of the output STAR file. If you are not going to write
  an output file just set this variable to ''

Concatenate Options
-------------------

write_motl
  If you want to write out the concatenated MOTL files set this to 1, however if
  you just want to print the MOTL contents to the screen, set this to 0.

write_star
  If you want to write out the concatenated STAR file set this to 1, however if
  you just want to print the MOTL contents to the screen, set this to 0.

sort_row
  If you want to have the output MOTL file sorted by a particular field then
  specify it here. If the given value is not a value between 1-20 then the
  output MOTL file will be sorted arbitrarily based on the dir command in
  Matlab.

do_quiet
  If you just want to write output to files and not print to the screen set this
  to 1, however if you want to see the output printed to the screen leave this
  set to 0.

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    cat_exec="${exec_dir}/MOTL/subtom_cat_motls"

    input_motl_fns=("combinedmotl/allmotl_1_tomo_1.em" \
                    "combinedmotl/allmotl_1_tomo_2.em" \
                    "combinedmotl/allmotl_1_tomo_3.em" \
                    "combinedmotl/allmotl_1_tomo_4.em" \
                    "combinedmotl/allmotl_1_tomo_5.em")

    output_motl_fn="combinedmotl/allmotl_1.em"

    output_star_fn="combinemotl/allmotl_1.star"

    write_motl=1

    write_star=0

    sort_row=4

    do_quiet=1
