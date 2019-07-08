==========================
subtom_plot_scanned_angles
==========================

Creates a graphic of local search rotations.

.. code-block:: matlab

    subtom_plot_scanned_angles(
        'psi_angle_step', psi_angle_step (0),
        'psi_angle_shells', psi_angl_shells (0),
        'phi_angle_step', phi_angle_step (0),
        'phi_angle_shells', phi_angle_shells (0),
        'initial_phi', initial_phi (0),
        'initial_psi', initial_psi (0),
        'initial_theta', initial_theta (0),
        'angle_fmt', angle_fmt ('degrees'),
        'marker_size', marker_size (0.1),
        'output_fn_prefix', output_fn_prefix (''))

Takes in the local search parameters used in subTOM ``psi_angle_step``,
``psi_angle_shells``, ``phi_angle_step``, and ``phi_angle_shells``; then
produces a figure showing the angles that will be searched using an arrow
marker. The angles are given in either radians or degrees depending on
``angle_fmt``. The marker represents the X-axis after rotation and placed on the
unit sphere.  The initial marker position is at the north pole of the unit
sphere. The size of the marker is determined by ``marker_size``. The rotations
can also be displayed centered on an initial rotation given by ``initial_phi``,
``initial_psi``, and ``initial_theta``. If it is non-empty the figure will be
written out in MATLAB figure, PDF and PNG format using the filename prefix
``output_fn_prefix``.

-------
Example
-------

.. code-block:: matlab

    subtom_plot_scanned_angles(...
        'psi_angle_step', 6, ...
        'psi_angle_shells', 7, ...
        'phi_angle_step', 6, ...
        'phi_angle_shells', 7, ...
        'initial_phi', 0, ...
        'initial_psi', 0, ...
        'initial_theta', 0, ...
        'angle_fmt', 'degrees', ...
        'marker_size', 0.02, ...
        'output_fn_prefix', 'alignment_1');

--------
See Also
--------

* :doc:`subtom_plot_filter`
* :doc:`subtom_shape`
