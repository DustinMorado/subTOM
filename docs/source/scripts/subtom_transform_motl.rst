=====================
subtom_transform_motl
=====================

Apply a rotation and a shift to a MOTL file.

This MOTL manipulation script uses one MATLAB compiled scripts below:

- :doc:`../functions/subtom_transform_motl`

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

transform_motl_exec
  Absolute path to transform_motl executable

File Options
------------

input_motl_fn
  Relative path and name of the input MOTL file to be transformed.

output_motl_fn
  Relative path and name of the output MOTL file.

Transform Options
-----------------

shift_x
  How much to shift the reference along the X-Axis, applied after the rotations
  described below.

shift_y
  How much to shift the reference along the Y-Axis, applied after the rotations
  described below.

shift_z
  How much to shift the reference along the Z-Axis, applied after the rotations
  described below.

rotate_phi
  Hom much to finally rotate the reference in-plane about it's final Z-Axis.
  (i.e. Spin rotation corresponding to phi).

rotate_psi
  How much to first rotate the reference about it's initial Z-Axis.
  (i.e. Azimuthal rotation corresponding to psi).

rotate_theta
  How much to second rotate the reference about it's intermediate X-Axis.
  (i.e. Zenithal rotation corresponding to theta).

rand_inplane
  If this is set to 1 (i.e. evaluates to true in Matlab) then the inplane
  rotation of particles will be randomized after the application of the given
  transform.

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    transform_motl_exec="${exec_dir}/MOTL/subtom_transform_motl"

    input_motl_fn="combinedmotl/allmotl_1.em"

    output_motl_fn="combinedmotl/allmotl_transformed_1.em"

    shift_x=0.0

    shift_y=0.0

    shift_z=0.0

    rotate_phi=0.0

    rotate_psi=0.0

    rotate_theta=0.0

    rand_inplane=0
