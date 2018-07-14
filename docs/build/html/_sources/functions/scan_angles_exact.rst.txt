=================
scan_angles_exact
=================

Find best alignment for a particle batch over local angles.

.. code-block:: Matlab

    scan_angles_exact(
        ptcl_start_idx,
        iteration,
        ali_batch_size,
        ref_fn_prefix,
        all_motl_fn_prefix,
        ptcl_motl_fn_prefix,
        ptcl_fn_prefix,
        tomo_row,
        weight_fn_prefix,
        apply_weight,
        align_mask_fn,
        apply_mask,
        cc_mask_fn,
        psi_angle_step,
        psi_angle_shells,
        phi_angle_step,
        phi_angle_shells,
        high_pass_fp,
        low_pass_fp,
        nfold,
        threshold,
        iclass)

Aligns a batch of particles from the collective motive list with the name format
``all_motl_fn_prefix_#.em`` where # is the number ``iteration``. The batch start
at ``ptcl_start_idx`` and contains ``ali_batch_size`` number of particles. A
motive list for the best determined alignment parameters is written out for each
particle with the name format ``ptct_motl_fn_prefix_#_#.em`` where the first #
is the subtomogram ID from the fourth field in the all motive list, and the
second # is the number ``iteration`` + 1.

Particles, with the name format ``ptcl_fn_prefx_#.em`` where # is the
subtomogram ID, are aligned against the reference with the name format
``ref_fn_prefix_#.em`` where # is ``iteration``. Before the comparison is made a
number of alterations are made to both the particle and reference:

* If ``nfold`` is greater than 1 then C#-symmetry is applied along the Z-axis to
  the reference where # is ``nfold``.

* The reference is masked in real space with the mask ``align_mask_fn``, and if
  ``apply_mask`` evaluates to true as a boolean, then this mask is also applied
  to the particle. A sphere mask is applied to the particle to reduces the
  artifacts caused by the box-edges on the comparison. This sphere has a
  diameter that is 80% the boxsize and falls of with a sigma that is 15% half
  the boxsize.

    - The mask is rotated and shifted with the currently existing alignment
      parameters for the particle as to best center the mask on the particle
      density.

    - ``apply_mask`` can help alignment and suppress alignment to other features
      when the particle is well-centered or already reasonably well aligned, but
      if this is not the case there is the risk that a tight alignment will
      cutoff parts of the particle.

* Both the particle and the reference are bandpass filtered in the Fourier
  domain defined by ``high_pass_fp`` and ``low_pass_fp``, which are both in the
  units of Fourier pixels.

* A Fourier weight volume with the name format ``weight_fn_prefix_#.em`` where #
  corresponds to the tomogram from which the particle came from, which is found
  from the field ``tomo_row`` in the motive list, is applied to the reference in
  the Fourier domain, after the reference has been rotated with the currently
  existing alignment parameters.  If ``apply_weight`` evaluates to true as a
  boolean, then this weight is also applied to the particle with no rotation.
  This Fourier weight is designed to compensate for the missing wedge.

    - If a binary wedge is used, then it is reasonable to apply the weight to
      the particle, however, for more complicated weights, like the average
      amplitude spectrum, it should not be done.

The local rotations searched during alignment are deteremined by the four
parameters ``psi_angle_step``, ``psi_angle_shells``, ``phi_angle_step``, and
``phi_angle_shells``. They describe a search where the currently existing
alignment parameters for azimuth and zenith are used to define a "pole" to
search about in ``psi_angle_shells`` cones. The change in zenith between each
cone is ``psi_angle_step`` and the azimuth around the cone is close to the same
angle but is adjusted slightly to account for bias near the pole. The final spin
angle of the search is done with a change in spin of ``phi_angle_step`` in
``phi_angle_shells`` steps. The spin is applied in both clockwise and
counter-clockwise fashion.

    - The angles phi, and psi here are flipped in their sense of every other
      package for EM image processing, which is absolutely infuriating and
      confusing, but maintained for historical reasons, however most
      descriptions use the words azimuth, zenith, and spin to avoid ambiguity.

Finally after the constrained cross-correlation function is calculated it is
masked with ``cc_mask_fn`` to limit the shifts to inside this volume, and a peak
is found and it's location is determined to sub-pixel accuracy using
interpolation. The rotations and shifts that gives the highest cross-correlation
coefficient are then chosen as the new alignments parameters. Particles with a
coefficient lower than ``threshold`` are placed into class 2 and ignored in
later processing, and particles with class ``iclass`` are the only particles
processed.

    - If ``iclass`` is 0 all particles will be considered. If ``iclass`` is
      nonzero than particles above ``threshold`` will be reassigned to class
      number ``iclass``

    - The class number is stored in the 20th field of the motive list.

--------
Example:
--------

.. code-block:: Matlab

    scan_angles_exact(1, 1, 100, 'ref/ref', 'combinedmotl/allmotl', ...
        'motls/motl', 'subtomograms/subtomo', 7, 'otherinputs/binary', ...
        1, 'otherinputs/alignmask.em', 0, 'otherinputs/ccmask.em', 2, 3, ...
        2, 4, 1, 10, 2, -1, 0);


