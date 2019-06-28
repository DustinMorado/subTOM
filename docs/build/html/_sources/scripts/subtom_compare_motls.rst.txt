====================
subtom_compare_motls
====================

Compares the translations and rotations between two MOTLS of different
iterations of alignment.

This MOTL manipulation script uses one MATLAB compiled scripts below:

- :doc:`../functions/subtom_compare_motls`

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

compare_motls_exec
  Comparison MOTLs executable

File Options
------------

motl_1_fn
  Relative path and name of the first MOTL file

motl_2_fn
  Relative path and name of the second MOTL file

output_diffs_fn
  Relative path and name of the optional output difference CSV file. If you do
  not want to write out the differences just leave this as "".

  The CSV format of the output differences file for comparison is one row per
  particle in the motive list that has six columns, and a special final line
  with 22 columns for statistics of differences for the whole motive list. The
  particle columns are as follows:

+---------------------------+--------------------------------------------------+
| Column                    | Value                                            |
+===========================+==================================================+
| 1                         | Particle Index (Motive List row 4)               |
+---------------------------+--------------------------------------------------+
| 2                         | CCC Score for particle in first motive list      |
+---------------------------+--------------------------------------------------+
| 3                         | CCC Score for particle in second motive list     |
+---------------------------+--------------------------------------------------+
| 4                         | Coordinate displacement between motive lists     |
+---------------------------+--------------------------------------------------+
| 5                         | Angular displacement between motive lists        |
+---------------------------+--------------------------------------------------+
| 6                         | Angular displacement ignoring inplane rotations  |
+---------------------------+--------------------------------------------------+

  The special final line columns are as follows:

+---------------------------+--------------------------------------------------+
| Column                    | Value                                            |
+===========================+==================================================+
| 1                         | Mean Coordinate displacement between MOTLs       |
+---------------------------+--------------------------------------------------+
| 2                         | Median Coordinate displacement between MOTLs     |
+---------------------------+--------------------------------------------------+
| 3                         | Coordinate displacement standard deviation       |
+---------------------------+--------------------------------------------------+
| 4                         | Maximum Coordinate displacement between MOTLs    |
+---------------------------+--------------------------------------------------+
| 5                         | Mean Angular displacement between MOTLs          |
+---------------------------+--------------------------------------------------+
| 6                         | Median Angular displacement between MOTLs        |
+---------------------------+--------------------------------------------------+
| 7                         | Angular displacement standard deviation          |
+---------------------------+--------------------------------------------------+
| 8                         | Maximum Angular displacement between MOTLs       |
+---------------------------+--------------------------------------------------+
| 9                         | Same as 5 but ignoring inplane rotations         |
+---------------------------+--------------------------------------------------+
| 10                        | Same as 6 but ignoring inplane rotations         |
+---------------------------+--------------------------------------------------+
| 11                        | Same as 7 but ignoring inplane rotations         |
+---------------------------+--------------------------------------------------+
| 12                        | Same as 8 but ignoring inplane rotations         |
+---------------------------+--------------------------------------------------+
| 13                        | Mean CCC score in the first motive list          |
+---------------------------+--------------------------------------------------+
| 14                        | Median CCC score in the first motive list        |
+---------------------------+--------------------------------------------------+
| 15                        | CCC standard deviation in first motive list      |
+---------------------------+--------------------------------------------------+
| 16                        | Minimum CCC score in the first motive list       |
+---------------------------+--------------------------------------------------+
| 17                        | Maximum CCC score in the first motive list       |
+---------------------------+--------------------------------------------------+
| 18                        | Mean CCC score in the second motive list         |
+---------------------------+--------------------------------------------------+
| 19                        | Median CCC score in the second motive list       |
+---------------------------+--------------------------------------------------+
| 20                        | CCC standard deviation in second motive list     |
+---------------------------+--------------------------------------------------+
| 21                        | Minimum CCC score in the second motive list      |
+---------------------------+--------------------------------------------------+
| 22                        | Maximum CCC score in the second motive list      |
+---------------------------+--------------------------------------------------+

Comparison Options
------------------

write_diffs
  If the following is 1 then the differences will be written out, if 0 then not.

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    compare_motls_exec="${exec_dir}/MOTL/subtom_compare_motls"

    motl_1_fn="combinedmotl/allmotl_1.em"

    motl_2_fn="combinedmotl/allmotl_2.em"

    output_diffs_fn="combinedmotl/allmotl_1_2_diffs.csv"

    write_diffs=1
