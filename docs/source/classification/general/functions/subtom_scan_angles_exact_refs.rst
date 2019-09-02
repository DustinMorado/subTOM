=============================
subtom_scan_angles_exact_refs
=============================

Align a particle class averages to a single class average reference.

.. code-block:: Matlab

    subtom_scan_angles_exact_refs(
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'ref_fn_prefix', ref_fn_prefix ('ref/ref'),
        'align_mask_fn', align_mask_fn ('none'),
        'cc_mask_fn', cc_mask_fn ('noshift'),
        'apply_mask', apply_mask (0),
        'ref_class', ref_class (3),
        'psi_angle_step', psi_angle_step (0),
        'psi_angle_shells', psi_angle_shells (0),
        'phi_angle_step', phi_angle_step (0),
        'phi_angle_shells', phi_angle_shells (0),
        'high_pass_fp', high_pass_fp (0),
        'high_pass_sigma', high_pass_sigma (0),
        'low_pass_fp', low_pass_fp (0),
        'low_pass_sigma', low_pass_sigma (0),
        'nfold', nfold (1),
        'iteration', iteration (1))

Aligns class averages from the collective motive list with the name format
``all_motl_fn_prefix`` _#.em where # is the number ``iteration``. A motive list
for the best determined alignment parameters against the class average specified
by ``ref_class`` is written out in two motive lists as given by
``output_motl_fn_prefix``. The first with 'classed' keeps the class information
to generate new class averages. The second with 'unclassed' discards the class
information so a cumulative average can be generated.

Class averages, with the name format ``ref_fn_prefx`` _class_#_#.em where the
first # is the iclass number, and the the second # is ``iteration``, are aligned
against the reference class average.  Before the comparison is made a number of
alterations are made to both the class average and reference:

    - If ``nfold`` is greater than 1 then C#-symmetry is applied along the
      Z-axis to the reference where # is ``nfold``.

    - The reference is masked in real space with the mask ``align_mask_fn``, and
      if ``apply_mask`` evaluates to true as a boolean, then this mask is also
      applied to the class average. A sphere mask is applied to the particle to
      reduces the artifacts caused by the box-edges on the comparison. This
      sphere has a diameter that is 80% the box size and falls of with a sigma
      that is 15% half the box size.

        - ``apply_mask`` can help alignment and suppress alignment to other
          features when the particle is well-centered or already reasonably well
          aligned, but if this is not the case there is the risk that a tight
          alignment will cutoff parts of the particle.

    - Both the particle and the reference are bandpass filtered in the Fourier
      domain defined by ``high_pass_fp``, ``high_pass_sigma``, ``low_pass_fp``,
      and ``low_pass_sigma`` which are all in the units of Fourier pixels.

The local rotations searched during alignment are deteremined by the four
parameters ``psi_angle_step``, ``psi_angle_shells``, ``phi_angle_step``, and
``phi_angle_shells``. They describe a search where the currently existing
alignment parameters for azimuth and zenith are used to define a "pole" to
search about in the ceiling of half ``psi_angle_shells`` cones. The change in
zenith between each cone is ``psi_angle_step`` and the azimuth around the cone
is close to the same angle but is adjusted slightly to account for bias near the
pole. The final spin angle of the search is done with a change in spin of
``phi_angle_step`` in ``phi_angle_shells`` steps. The spin is applied in both
clockwise and counter-clockwise fashion.

    - The angles phi, and psi here are flipped in their sense of every other
      package for EM image processing, which is absolutely infuriating and
      confusing, but maintained for historical reasons, however most
      descriptions use the words azimuth, zenith, and spin to avoid ambiguity.

Finally after the constrained cross-correlation function is calculated it is
masked with ``cc_mask_fn`` to limit the shifts to inside this volume, and a peak
is found and it's location is determined to sub-pixel accuracy using
interpolation. The rotations and shifts that gives the highest cross-correlation
coefficient are then chosen as the new alignments parameters.

-------
Example
-------

.. code-block:: Matlab

    subtom_scan_angles(...
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'ref_fn_prefix', 'ref/ref', ...
        'align_mask_fn', 'otherinputs/align_mask.em', ...
        'cc_mask_fn', 'otherinputs/cc_mask.em', ...
        'apply_mask', 1, ...
        'ref_class', 3, ...
        'psi_angle_step', 1, ...
        'psi_angle_shells', 8, ...
        'phi_angle_step', 1, ...
        'phi_angle_shells', 8, ...
        'high_pass_fp', 1, ...
        'high_pass_sigma', 2, ...
        'low_pass_fp', 10, ...
        'low_pass_sigma', 3, ...
        'nfold', 1, ...
        'iteration', 1)

--------
See Also
--------

* :doc:`subtom_cluster`
* :doc:`subtom_parallel_prealign`
* :doc:`subtom_parallel_sums_cls`
* :doc:`subtom_weighted_average_cls`
