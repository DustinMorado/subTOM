====================
subtom_extract_noise
====================

Extract noise amplitude spectra on the cluster.

.. code-block:: Matlab

    subtom_extract_noise(
        'tomogram_dir', tomogram_dir (''),
        'tomo_row', tomo_row (7),
        'ampspec_fn_prefix', ampspec_fn_prefix ('otherinputs/ampspec'),
        'binary_fn_prefix', binary_fn_prefix ('otherinputs/binary'),
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'noise_motl_fn_prefix', noise_motl_fn_prefix ('combinedmotl/noisemotl'),
        'iteration', iteration (1),
        'box_size', box_size (-1),
        'just_extract', just_extract (0),
        'ptcl_overlap_factor', ptcl_overlap_factor (0),
        'noise_overlap_factor', noise_overlap_factor (0),
        'num_noise', num_noise (1000),
        'process_idx', process_idx (1),
        'reextract', reextract (0),
        'preload_tomogram', preload_tomogram (1),
        'use_tom_red', use_tom_red (0),
        'use_memmap', use_memmap (0))

Takes the tomograms given in ``tomogram_dir`` and extracts average amplitude
spectra and binary wedges into files with the name formats ``ampspec_fn_prefix``
_#.em and ``binary_fn_prefix`` _ #.em, respectively where # corresponds to the
tomogram from which it was created.

Tomograms are specified by the field ``tomo_row`` in motive list
``all_motl_fn_prefix`` _#.em where # corresponds to ``iteration``.  and the
tomogram that will be processed is selected by ``process_idx``. Motive lists
with the positions used to generate the amplitude spectrum are written with the
name format ``noise_motl_fn_prefix`` _#.em.

``num_noise`` Noise volumes of size ``box_size`` are first identified that do not
clash with the subtomogram positions in the input motive list or other already
selected noise volumes. ``ptcl_overlap_factor`` and ``noise_overlap_factor``
define how much overlap selected noise volumes can have with subtomograms and
other noise volumes respectively with 1 being complete overlap and 0 being
complete separation.

If ``noise_motl_fn_prefix`` _#.em already exists then if ``just_extract``
evaluates to true as a boolean, then noise volume selection is skipped and the
positions in the motive list are extracted and the amplitude spectrum is
generated, whether or not the length of the motive list is less than
``num_noise``. Otherwise positions will be added to the motive list up to
``num_noise``.

If ``reextract`` evaluates to true as a boolean, than existing amplitude spectra
will be overwritten. Otherwise the program will do nothing and exit if the
volume already exists. This is for in the case that the processing crashed at
some point in execution and then can just be re-run without any alterations.

If ``preload_tomogram`` evaluates to true as a boolean, then the whole tomogram
will be read into memory before extraction begins, otherwise the particles will
be read from disk or from a memory-mapped tomogram. If ``use_tom_red`` evaluates
to true as a boolean the old particle extraction code will be used, but this is
only for legacy support and is not suggested for use. Finally if ``use_memmap``
evaluates to true as a boolean then in place of reading each particle from disk
a memory-mapped version of the file of will be created to attempt faster access
in extraction.

-------
Example
-------

.. code-block:: matlab

    subtom_extract_noise(...
        'tomogram_dir', '../data/tomos/bin8', ...
        'tomo_row', 7, ...
        'ampspec_fn_prefix', 'otherinputs/ampspec', ...
        'binary_fn_prefix', 'otherinputs/binary', ...
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'noise_motl_prefix', 'combinedmotl/noisemotl', ...
        'iteration', 1, ...
        'box_size', 36, ...
        'just_extract', 0, ...
        'ptcl_overlap_factor', 0.0, ...
        'noise_overlap_factor, 0.75, ...
        'num_noise', 1000,
        'process_idx', 1, ...
        'reextract', 1, ...
        'preload_tomogram', 1, ...
        'use_tom_red', 0, ...
        'use_memmap', 0)

--------
See also
--------

* :doc:`subtom_extract_subtomograms`
* :doc:`subtom_parallel_sums`
* :doc:`subtom_scan_angles_exact`
* :doc:`subtom_weighted_average`
