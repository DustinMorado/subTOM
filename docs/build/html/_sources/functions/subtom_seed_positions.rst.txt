=====================
subtom_seed_positions
=====================

Place particle positions from clicker motive list.

.. code-block:: Matlab

    subtom_seed_positions(
        'input_motl_fn_prefix', input_motl_fn_prefix ('../startset/clicker'),
        'output_motl_fn', output_motl_fn ('combinedmotl/allmotl_1.em'),
        'spacing', spacing (8),
        'do_tubule', do_tubule (0),
        'rand_inplane', rand_inplane (0))

Takes in clicker motive lists from the 'Pick Particle' plugin for Chimera
with a name in the format ``input_motl_fn_prefix`` _#.em, where # should
correspond to the tomogram number the clicker corresponds to. This number
will be used to fill in the 7th field in the output motive list
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
6th field of the output motive list. If both ``do_tubule`` and ``rand_inplane``
evaluate to true as a boolean, then the final Euler angle (phi in AV3 notation,
and psi/spin/inplane in other notations) will be randomized as opposed to
directed along the tubular axis.

-------
Example
-------

.. code-block:: Matlab

    subtom_seed_positions(...
        'input_motl_fn_prefix', '../startset/clicker', ...
        'output_motl_fn', 'combinedmotl/allmotl_1.em', ...
        'spaciing', 4, ...
        'do_tubule', 0, ...
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
* :doc:`subtom_split_motl_by_row`
* :doc:`subtom_transform_motl`
* :doc:`subtom_unclass_motl`
