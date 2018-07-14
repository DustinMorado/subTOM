====================
extract_subtomograms
====================

Extract subtomograms on the cluster.

.. code-block:: Matlab

    EXTRACT_SUBTOMOGRAMS(...
        TOMOGRAM_DIR, ...
        SCRATCH_DIR, ...
        TOMO_ROW, ...
        SUBTOMO_FN_PREFIX, ...
        SUBTOMO_DIGITS, ...
        ALL_MOTL_FN, ...
        BOXSIZE, ...
        STATS_FN_PREFIX, ...
        PROCESS_IDX, ...
        REEXTRACT)

takes the tomograms given in ``tomogram_dir`` and extracts subtomograms
specified in ``all_motl_fn`` with size ``boxsize`` into ``scratch_dir`` with the
name formats ``subtomo_fn_prefix_#.em`` where # corresponds to the entry in
field 4 in ``all_motl_fn`` zero-padded to have at least ``subtomo_digits``
digits.

tomograms are specified by the field ``tomo_row`` in motive list
``all_motl_fn``, and the tomogram that will be processed is selected by
``process_idx``. a CSV-format file with the subtomogram ID-number, average, min,
max, standard deviation and variance for each subtomogram in the tomogram is
also written with the name format ``stats_fn_prefix_#.em`` where # corresponds
to the tomogram from which subtomograms were extracted. 

if ``reextract`` evaluates to true as a boolean, than existing subtomograms will
be overwritten. otherwise the program will do nothing and exit if
``stats_fn_prefix_#.em`` already exists, or will also skip any subtomogram it is
trying to extract that already exists. this is for in the case that the
processing crashed at some point in execution and then can just be re-run
without any alterations.

--------
Example:
--------

.. code-block:: Matlab

    extract_subtomograms(...
        '/net/bstore1/bstore1/user/dataset/date/data/tomos/bin1', ...
        '/net/bstore1/bstore1/user/dataset/date/subtomo/bin1/even', ...
        7, 'subtomograms/subtomo', 1, 'combinedmotl/allmotl_1.em', ...
        192, 'subtomograms/stats/subtomo_stats', 1, 0)

--------
See also
--------

:doc:`extract_noise`


