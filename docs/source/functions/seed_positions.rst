==============
seed_positions
==============

Place particle positions with alignment to clicker motive list.

.. code-block:: Matlab

    seed_positions(
        input_motl_fn_prefix,
        output_motl_fn,
        spacing,
        do_tubule)

Takes in clicker motive lists from the 'Pick Particle' plugin for Chimera
with a name in the format ``input_motl_fn_prefix_#.em``, where # should
correspond to the tomogram number the clicker corresponds to. This number
will be used to fill in the 5th and 7th field in the output motive list
``output_motl_fn``.

Points are added with roughly a pixel distance ``spacing`` apart. These points
are also set with Euler angles that place them normal to the surface of
the sphere or tube on which they lie. Points take the form of a tube is
``do_tubule`` evaluates to true as a boolean otherwise the clickers are
assumed to correspond to spheres. In the case of both the radius is
encoded in the 3rd field of the clicker motive and carried over to the
output motive list. The second field corresponds to the marker set the
clicker file was created from, which is not used in placing spheres but is
considered in seeding tubules to delineate between multiple tubules in
each tomogram. Finally a running index of tube or sphere is added to the
6th field of the output motive list.

--------
Example:
--------

.. code-block:: Matlab

    seed_positions('../startset/clicker', 'combinedmotl/allmotl_1.em', 8, 1);


