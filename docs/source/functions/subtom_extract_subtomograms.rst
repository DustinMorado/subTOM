===========================
subtom_extract_subtomograms
===========================

Extract subtomograms on the cluster.

.. code-block:: Matlab

    subtom_extract_subtomograms(
        'tomogram_dir', tomogram_dir (''),
        'tomo_row', tomo_row (7),
        'subtomo_fn_prefix', subtom_fn_prefix ('subtomograms/subtomo'),
        'subtomo_digits', subtomo_digits (1),
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'stats_fn_prefix', stats_fn_prefix ('subtomograms/stats/tomo'),
        'iteration', iteration (1),
        'box_size', box_size (-1),
        'process_idx', process_idx (1),
        'reextract', reextract (0),
        'preload_tomogram', preload_tomogram (1),
        'use_tom_red', use_tom_red (0),
        'use_memmap', use_memmap (0))

Takes the tomograms given in ``tomogram_dir`` and extracts subtomograms
specified in ``all_motl_fn_prefix`` _#.m where # corresponds to ``iteration``
with size ``box_size`` into ``scratch_dir`` with the name formats
``subtomo_fn_prefix`` _#.em where # corresponds to the entry in field 4 in
``all_motl_fn_prefix`` _#.em zero-padded to have at least ``subtomo_digits``
digits.

Tomograms are specified by the field ``tomo_row`` in motive list
``all_motl_fn_prefix`` _#.em, and the tomogram that will be processed is
selected by ``process_idx``. A CSV-format file with the subtomogram ID-number,
average, min, max, standard deviation and variance for each subtomogram in the
tomogram is also written with the name format ``stats_fn_prefix`` _#.em where #
corresponds to the tomogram from which subtomograms were extracted. 

If ``reextract`` evaluates to true as a boolean, than existing subtomograms will
be overwritten. Otherwise the program will do nothing and exit if
``stats_fn_prefix`` _#.em already exists, or will also skip any subtomogram it
is trying to extract that already exists. This is for in the case that the
processing crashed at some point in execution and then can just be re-run
without any alterations.

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

.. code-block:: Matlab

    subtom_extract_subtomograms(...
        'tomogram_dir', '../data/tomos/bin8', ...
        'tomo_row', 7, ...
        'subtomo_fn_prefix', 'subtomograms/subtomo', ...
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'stats_fn_prefix', 'subtomograms/stats/tomo', ...
        'iteration', 1, ...
        'box_size', 36, ...
        'process_idx', 1, ...
        'reextract', 0, ...
        'preload_tomogram', 1, ...
        'use_tom_red', 0, ...
        'use_memmap', 0)

--------
See also
--------

* :doc:`subtom_extract_noise`
* :doc:`subtom_parallel_sums`
* :doc:`subtom_scan_angles_exact`
* :doc:`subtom_weighted_average`
