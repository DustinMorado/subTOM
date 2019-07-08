==========================
subtom_plot_scanned_angles
==========================

Plots the angles searched for a user-specified set of alignment angles. The
angles can also be centered about a given initial orientation. The marker of the
plot can be adjusted and the plot can also be saved to disk.

This utility script uses one MATLAB compiled scripts below:

- :doc:`../functions/subtom_plot_scanned_angles`

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

plot_angles_exec
  Plot scanned angles executable.

File Options
------------

output_fn_prefix
  Relative path and name prefix of the output plot. If you want to skip this
  output file leave this set to "".

Plot Scanned Angles Options
---------------------------

psi_angle_step
  Angular increment in degrees, applied during the cone-search, i.e. psi and
  theta (define as real e.g. psi_angle_step=3)

psi_angle_shells
  Number of angular iterations, applied to psi and theta  (define as integer
  e.g. psi_angle_shells=3)

phi_angle_step
  Angular increment for phi in degrees, (define as real e.g. phi_angle_step=3)

phi_angle_shells
  Number of angular iterations for phi, (define as integer e.g.
  phi_angle_shells=3)

initial_phi
  Initial first Euler angle rotation around the Z-axis about which the scanned
  angles are centered. (define as real e.g. initial_phi=45).

initial_psi
  Initial third Euler angle rotation around the Z-axis about which the scanned
  angles are centered. (define as real e.g. initial_psi=30).

initial_theta
  Initial second Euler angle rotation around the X-axis about which the scanned
  angles are centered. (define as real e.g. initial_theta=135).

angle_fmt
  If the above angles are specified as degress leave this set to 'degrees', but
  if the angles above are in radian format set this to 'radians'.

marker_size
  Set the marker size of the arrows that are drawn for the rotations, reasonable
  values seem to be around the range of 0.01 to 0.1.

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    plot_angles_exec="${exec_dir}/utils/subtom_plot_scanned_angles"

    output_fn_prefix=""

    psi_angle_step="6"

    psi_angle_shells="7"

    phi_angle_step="6"

    phi_angle_shells="7"

    initial_phi="0"

    initial_psi="0"

    initial_theta="0"

    angle_fmt="degrees"

    marker_size="0.02"
