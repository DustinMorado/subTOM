============
subtom_shape
============

Produces a volume of a simple shape for masking.

.. code-block:: Matlab

    subtom_shape(
        'shape', shape (''),
        'box_size', box_size (''),
        'radius', radius (box_size / 2),
        'outer_radius', outer_radius (box_size / 2),
        'inner_radius', inner_radius (outer_radius - 2),
        'radius_x', radius_x (box_size / 2),
        'radius_y', radius_y (box_size / 2),
        'radius_z', radius_z (box_size / 2),
        'outer_radius_x', outer_radius_x (box_size / 2),
        'outer_radius_y', outer_radius_y (box_size / 2),
        'outer_radius_z', outer_radius_z (box_size / 2),
        'inner_radius_x', inner_radius_x (outer_radius_x - 2),
        'inner_radius_y', inner_radius_y (outer_radius_y - 2),
        'inner_radius_z', inner_radius_z (outer_radius_z - 2),
        'length_x', length_x (box_size),
        'length_y', length_y (box_size),
        'length_z', length_z (box_size),
        'height', height (box_size),
        'center_x', center_x (floor(box_size / 2) + 1),
        'center_y', center_y (floor(box_size / 2) + 1),
        'center_z', center_z (floor(box_size / 2) + 1),
        'shift_x', shift_x (0),
        'shift_y', shift_y (0),
        'shift_z', shift_z (0),
        'rotate_phi', rotate_phi (0),
        'rotate_psi', rotate_psi (0),
        'rotate_theta', rotate_theta (0),
        'sigma', sigma (0),
        'ref_fn', ref_fn (''),
        'output_fn', output_fn (''))

Creates a volume of a simple shape, with the volume being a cube of ``box_size``
length, and writes out the volume as ``output_fn``. This volume is generally
used for masking.  The shape in the volume is defined by ``shape`` and can be
one of several strings, the available shapes are 'sphere', 'sphere_shell',
'ellipsoid', 'ellipsoid_shell', 'cylinder', 'tube', 'elliptic_cylinder',
'elliptic_tube', and 'cuboid'. For each shape there are a number of options
available to define the shape.

For each shape an optional gaussian smooth edge can be added by defining
``sigma``.

For each shape an optional transform can also be applied to the shape by
specifying a shift through the options ``shift_x``, ``shift_y``, and
``shift_z``, and the shapes initial center can be specified by ``center_x``,
``center_y``, ``center_z``.  Rotations to the shape are applied through the
options ``rotate_phi``, ``rotate_psi``, and ``rotate_theta``. Rotations are done
about the center and shifts are applied after any given rotation.

Finally another volume can be given by passing the option ``ref_fn`` and the
shape will be applied to the volume, which can aid in testing how the shape
masks the underlying density.

If shape is 'sphere', the shape is defined by ``radius``.

If shape is 'sphere_shell', the shape is defined by ``inner_radius`` and
``outer_radius``.

If shape is 'ellipsoid', the shape is defined by ``radius_x``, ``radius_y``, and
``radius_z``.

If shape is 'ellipsoid_shell', the shape is defined by ``inner_radius_x``,
``inner_radius_y``, ``inner_radius_z``, ``outer_radius_x``, ``outer_radius_y``,
and ``outer_radius_z``.

If shape is 'cylinder', the shape is defined by ``radius`` and ``height``.

If shape is 'tube', the shape is defined by ``inner_radius``, ``outer_radius``,
and ``height``.

If shape is 'elliptic_cylinder', the shape is defined by ``radius_x``,
``radius_y``, and ``height``.

If shape is 'elliptic_tube', the shape is defined by ``inner_radius_x``,
``inner_radius_y``, ``outer_radius_x``, ``outer_radius_y``, and ``height``.

Finally if shape is 'cuboid', the shape is defined by ``length_x``,
``length_y``, and ``length_z``.

-------
Example
-------

.. code-block:: Matlab

    subtom_shape(...
        'shape', 'sphere', ...
        'box_size', 128, ...
        'radius', 32, ...
        'sigma', 3, ...
        'output_fn', 'otherinputs/mask.em');

--------
See Also
--------

* :doc:`subtom_plot_filter`
* :doc:`subtom_plot_scanned_angles`
