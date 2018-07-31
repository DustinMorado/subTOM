==============
transform_motl
==============

Apply a rotation and a shift to a MOTL file.

.. code-block:: Matlab

    transform_motl(
        input_motl_fn,
        output_motl_fn,
        shift_x,
        shift_y,
        shift_z,
        rotate_phi,
        rotate_psi,
        rotate_theta)

Takes the motl given by ``input_motl_fn``, and first applies the rotation
described by the Euler angles ``rotate_phi``, ``rotate_psi``, ``rotate_theta``,
which correspond to an in-plane spin, azimuthal, and zenithal rotation
respectively. Then a translation specified by ``shift_x``, ``shift_y``,
``shift_z``, is applied to the existing translation. Finally the resulting
transformed motive list is written out as ``output_motl_fn``. Keep in mind that
the motive list transforms describe the alignment of the reference to each
particle, but that the rotation and shift here describe an affine transform of
the reference to a new reference.

There is a long detailed explanation on how the transforms are derived in the
head of the source code file.

--------
Example:
--------

.. code-block:: matlab

    transform_motl('combinedmotl/allmotl_1.em', ...
        'combinedmotl/allmotl_1_shifted.em, 5, 5, -3, 60, 15, 0.5);


