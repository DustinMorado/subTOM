========================
subtom_scan_angles_exact
========================

Align a particle batch over local search angles.

.. code-block:: Matlab

    subtom_scan_angles_exact(
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'ref_fn_prefix', ref_fn_prefix ('ref/ref'),
        'ptcl_fn_prefix', ptcl_fn_prefix ('subtomograms/subtomo'),
        'weight_fn_prefix', weight_fn_prefix ('otherinputs/ampspec'),
        'align_mask_fn', align_mask_fn ('none'),
        'cc_mask_fn', cc_mask_fn ('noshift'),
        'apply_weight', apply_weight (0),
        'apply_mask', apply_mask (0),
        'psi_angle_step', psi_angle_step (0),
        'psi_angle_shells', psi_angle_shells (0),
        'phi_angle_step', phi_angle_step (0),
        'phi_angle_shells', phi_angle_shells (0),
        'high_pass_fp', high_pass_fp (0),
        'high_pass_sigma', high_pass_sigma (0),
        'low_pass_fp', low_pass_fp (0),
        'low_pass_sigma', low_pass_sigma (0),
        'nfold', nfold (1),
        'threshold', threshold (-1),
        'iteration', iteration (1),
        'tomo_row', tomo_row (7),
        'iclass', iclass (0),
        'num_ali_batch', num_ali_batch (1),
        'process_idx', process_idx (1))

Aligns a batch of particles from the collective motive list with the name format
``all_motl_fn_prefix`` _#.em where # is the number ``iteration``. The motive
list is split into ``num_ali_batch`` chunks and the specific chunk to process is
specified by ``process_idx`` . A motive list for the best determined alignment
parameters is written out for each batch with the name format
``ptct_motl_fn_prefix`` _#_#.em where the first # is ``iteration`` + 1 and the
second # is the number ``process_idx``.

Particles, with the name format ``ptcl_fn_prefx`` _#.em where # is the
subtomogram ID, are aligned against the reference with the name format
``ref_fn_prefix`` _#.em where # is ``iteration``. Before the comparison is made
a number of alterations are made to both the particle and reference:

    - If ``nfold`` is greater than 1 then C#-symmetry is applied along the
      Z-axis to the reference where # is ``nfold``.

    - The reference is masked in real space with the mask ``align_mask_fn``, and
      if ``apply_mask`` evaluates to true as a boolean, then this mask is also
      applied to the particle. A sphere mask is applied to the particle to
      reduces the artifacts caused by the box-edges on the comparison. This
      sphere has a diameter that is 80% the boxsize and falls of with a sigma
      that is 15% half the boxsize.

        - The mask is rotated and shifted with the currently existing alignment
          parameters for the particle as to best center the mask on the particle
          density.

        - ``apply_mask`` can help alignment and suppress alignment to other
          features when the particle is well-centered or already reasonably well
          aligned, but if this is not the case there is the risk that a tight
          alignment will cutoff parts of the particle.

    - Both the particle and the reference are bandpass filtered in the Fourier
      domain defined by ``high_pass_fp``, ``high_pass_sigma``, ``low_pass_fp``,
      and ``low_pass_sigma`` which are all in the units of Fourier pixels.

    - A Fourier weight volume with the name format ``weight_fn_prefix`` _#.em
      where # corresponds to the tomogram from which the particle came from,
      which is found from the field ``tomo_row`` in the motive list, is applied
      to the reference in the Fourier domain, after the reference has been
      rotated with the currently existing alignment parameters.  If
      ``apply_weight`` evaluates to true as a boolean, then this weight is also
      applied to the particle with no rotation. This Fourier weight is designed
      to compensate for the missing wedge.

        - If a binary wedge is used, then it is reasonable to apply the weight
          to the particle, however, for more complicated weights, like the
          average amplitude spectrum, it should not be done.

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
coefficient are then chosen as the new alignments parameters. Particles with a
coefficient lower than ``threshold`` are placed into class 2 and ignored in
later processing, and particles with class ``iclass`` are the only particles
processed.

    - If ``iclass`` is 0 all particles will be considered, and particles above
      ``threshold`` will be assigned to iclass of 1 and particles below
      ``threshold`` will be assigned to iclass of 2. If ``iclass`` is 1 or 2
      then particles with iclass 0 will be skipped, particles of iclass 1 and 2
      will be aligned and particles with scores above ``threshold`` will be
      assigned to iclass 1 and particles with scores below ``threshold`` will be
      assigned to iclass 2. ``iclass`` of 2 does not make much sense but is set
      this way in case of user mistakes or misunderstandings. If ``iclass`` is
      greater than 2 then particles with iclass of 1, 2, and ``iclass`` will be
      aligned, and particles with a score above ``threshold`` will maintain
      their iclass if it is 1 or ``iclass``, and particles with a previous
      iclass of 2 will be upgraded to an iclass of 1. Particles with a score
      below ``threshold`` will be assigned to iclass 2. 

    - The class number is stored in the 20th field of the motive list.

-------
Example
-------

.. code-block:: Matlab

    subtom_scan_angles(...
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'ref_fn_prefix', 'ref/ref', ...
        'ptcl_fn_prefix', 'subtomograms/subtomo', ...
        'weight_fn_prefix', 'otherinputs/ampspec', ...
        'align_mask_fn', 'otherinputs/align_mask.em', ...
        'cc_mask_fn', 'otherinputs/cc_mask.em', ...
        'apply_weight', 0, ...
        'apply_mask', 1, ...
        'psi_angle_step', 6, ...
        'psi_angle_shells', 8, ...
        'phi_angle_step', 6, ...
        'phi_angle_shells', 8, ...
        'high_pass_fp', 1, ...
        'high_pass_sigma', 2, ...
        'low_pass_fp', 12, ...
        'low_pass_sigma', 3, ...
        'nfold', 6, ...
        'threshold', 0, ...
        'iteration', 1, ...
        'tomo_row', 7, ...
        'iclass', 0, ...
        'num_ali_batch', 1, ...
        'process_idx', 1)

--------
See Also
--------

* :doc:`subtom_extract_noise`
* :doc:`subtom_extract_subtomograms`
* :doc::`subtom_parallel_sums`
* :doc:`subtom_weighted_average`
