=====================
subtom_seed_positions
=====================

Takes the motive lists made from clicker files in UCSF Chimera and places a
number of points at a given spacing along spherical or tubular surfaces.

This MOTL manipulation script uses one MATLAB compiled scripts below:

- :doc:`../functions/subtom_seed_positions`

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
  Directory for executables.

Variables
---------

seed_pos_exec
  Seed positions on motive list executable.

File Options
------------

input_motl_fn_prefix
  Relative path and prefix of the input MOTL files to be seeded. The files are
  expected to have the format input_motl_fn_prefix_#.em where # is the number
  corresponding to the tomogram corresponding to the motive list and this value
  will go into row 7 of the output motive list.

output_motl_fn
  Relative path and name of the output MOTL file.

Seed Options
------------

spacing
  The spacing in pixels at which positions will be added to the surface. 

do_tubule
  If this is set to 1 (i.e. evaluates to true in Matlab) then the clicker
  motive list is assumed to correspond to tubules and points will be added along
  the tubule-axis. Otherwise the clicker file is assumed to correspond to
  spheres.

rand_inplane
  If this is set to 1 (i.e. evaluates to true in Matlab) then the inplane
  rotation of particles along a tubule will be randomized as opposed to the
  default which is to place the X-axis orthogonal to the longest tubule axis.

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    seed_pos_exec="${exec_dir}/MOTL/subtom_seed_positions"

    input_motl_fn_prefix="../startset/clicker"

    output_motl_fn="combinedmotl/allmotl_1.em"

    spacing=8

    do_tubule=0

    rand_inplane=0
