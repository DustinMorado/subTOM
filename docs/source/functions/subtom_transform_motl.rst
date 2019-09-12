=====================
subtom_transform_motl
=====================

Apply a rotation and a shift to a MOTL file.

.. code-block:: Matlab

    subtom_transform_motl(
        'input_motl_fn', input_motl_fn (''),
        'output_motl_fn', output_motl_fn (''),
        'shift_x', shift_x (0),
        'shift_y', shift_y (0),
        'shift_z', shift_z (0),
        'rotate_phi', rotate_phi (0),
        'rotate_psi', rotate_psi (0),
        'rotate_theta', rotate_theta (0),
        'rand_inplane', rand_inplane (0))

Takes the motl given by ``input_motl_fn``, and first applies the rotation
described by the Euler angles ``rotate_phi``, ``rotate_psi``, ``rotate_theta``,
which correspond to an in-plane spin, azimuthal, and zenithal rotation
respectively. Then a translation specified by ``shift_x``, ``shift_y``,
``shift_z``, is applied to the existing translation. Finally the resulting
transformed motive list is written out as ``output_motl_fn``. Keep in mind that
the motive list transforms describe the alignment of the reference to each
particle, but that the rotation and shift here describe an affine transform of
the reference to a new reference. If ``rand_inplane`` evaluates to true as a
boolean, then the final Euler angle (phi in AV3 notation, and psi/spin/inplane
in other notations) will be randomized after the given transform.

---------------------------------------------
Explanation of how the transforms are derived
---------------------------------------------

.. code-block:: console

        The alignments in the motive list describe the rotation and shift of the
        reference to each particle. Since this is a rotation followed by a shift
        we can describe this as an affine transform 4x4 matrix as follows:

        [ R_1   T_1 ]   [ V ]   [ P ]
        [           ] x [   ] = [   ]                        (1)
        [  0     1  ]   [ 1 ]   [ 1 ]

        Where R_1 is the rotation matrix described by motl(17:19, 1) and T_1 is
        the shift column vector described by motl(11:13, 1), and finally V and P
        are the coordinates in the reference, and the reference in register with
        the particle respectively.

        Likewise the rotation and shift we apply to the reference to get a new
        updated reference is also an affine transform as follows:

        [ R_2   T_2 ]   [ V ]   [  V' ]
        [           ] x [   ] = [     ]                      (2)
        [  0     1  ]   [ 1 ]   [  1  ]

        Where V' is our new reference. Therefore the affine transform we want to
        find and place in our updates motive list is:

        [ R_?   T_? ]   [  V' ]   [ P ]
        [           ] x [     ] = [   ]                      (3)
        [  0     1  ]   [  1  ]   [ 1 ]

        The most logical path is to go from V' to V and V to P, so we have to
        invert the affine transform in (2), and then left multiply it by the
        transform in (1). To find the inverse affine transform of (2) we have
        that:

        R_2 * V + T_2 = V'
        R_2 * V = V' - T_2
        V = R_2^-1 * (V' - T_2)
        V = (R_2^-1 * V') - (R_2^-1 * T_2)

        [ R_2^-1   -R_2^-1 * T_2 ]   [  V' ]   [ V ]
        [                        ] x [     ] = [   ]         (4)
        [    0             1     ]   [  1  ]   [ 1 ]

        So we have that:

        [ R_1  T_1 ]   [ R_2^-1   -R_2^-1 * T_2 ]   [  V' ]   [ P ]
        [          ] x [                        ] x [     ] = [   ]         (5)
        [  0    1  ]   [    0             1     ]   [  1  ]   [ 1 ]

        [ R_1 * R_2^-1  -R_1 * R_2^-1 * T_2 + T_1 ]   [  V' ] = [ P ]
        [                                         ] x [     ] = [   ]       (6)
        [     0                       1           ]   [  1  ] = [ 1 ]

        And finally:

        R_? = R_1 * R_2^-1
        T_? = T_1 - R_1 * R_2^-1 * T_2

-------
Example
-------

.. code-block:: Matlab

    subtom_transform_motl(...
        'input_motl_fn', 'combinedmotl/allmotl_1.em', ...
        'output_motl_fn', 'combinedmotl/allmotl_1_shifted.em', ...
        'shift_x', 5, ...
        'shift_y', 5, ...
        'shift_z', -3, ...
        'rotate_phi', 60, ...
        'rotate_psi', 15, ...
        'rotate_theta', 0.5, ...
        'rand_inplane', 0)

--------
See Also
--------

* :doc:`subtom_cat_motls`
* :doc:`subtom_clean_motl`
* :doc:`subtom_compare_motls`
* :doc:`subtom_even_odd_motl`
* :doc:`subtom_random_subset_motl`
* :doc:`subtom_scale_motl`
* :doc:`subtom_seed_positions`
* :doc:`subtom_split_motl_by_row`
* :doc:`subtom_unclass_motl`
