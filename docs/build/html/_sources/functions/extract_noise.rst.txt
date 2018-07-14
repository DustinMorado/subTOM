=============
extract_noise
=============

Extract noise amplitude spectra on the cluster.

.. code-block:: Matlab

    extract_noise(
        tomogram_dir,
        scratch_dir,
        tomo_row,
        ampspec_fn_prefix,
        binary_fn_prefix,
        all_motl_fn,
        noise_motl_fn_prefix,
        boxsize,
        just_extract,
        ptcl_overlap_factor,
        noise_overlap_factor,
        num_noise,
        process_idx,
        reextract)

takes the tomograms given in ``tomogram_dir`` and extracts average amplitude
spectra and binary wedges into ``scratch_dir`` with the name formats
``ampspec_fn_prefix_#.em`` and ``binary_fn_prefix_#.em``, respectively where #
corresponds to the tomogram from which it was created.

tomograms are specified by the field ``tomo_row`` in motive list
``all_motl_fn``, and the tomogram that will be processed is selected by
``process_idx``. motive lists with the positions used to generate the amplitude
spectrum are written with the name format ``noise_motl_fn_prefix_#.em``.

``num_noise`` noise volumes of size ``boxsize`` are first identified that do not
clash with the subtomogram positions in ``all_motl_fn`` or other already
selected noise volumes. ``ptcl_overlap_factor`` and ``noise_overlap_factor``
define how much overlap selected noise volumes can have with subtomograms and
other noise volumes respectively with 0 being complete overlap and 1 being
complete separation.

if ``noise_motl_fn_prefix_#.em`` already exists then if ``just_extract``
evaluates to true as a boolean, then noise volume selection is skipped and the
positions in the motive list are extracted and the amplitude spectrum is
generated, whether or not the length of the motive list is less than
``num_noise``. otherwise positions will be added to the motive list up to
``num_noise``.

if ``reextract`` evaluates to true as a boolean, than existing amplitude spectra
will be overwritten. otherwise the program will do nothing and exit if the
volume already exists. this is for in the case that the processing crashed at
some point in execution and then can just be re-run without any alterations.

--------
Example:
--------

.. code-block:: Matlab

    extract_noise(...
        '/net/bstore1/bstore1/user/dataset/date/data/tomos/bin1', ...
        '/net/bstore1/bstore1/user/dataset/date/subtomo/bin1/even', ...
        7, 'otherinputs/ampspec', 'otherinputs/binary', ...
        'combinedmotl/allmotl_1.em', 'combinedmotl/noisemotl', 192, 0, 1, ...
        1, 100, 1, 0)

--------
See also
--------

:doc:`extract_subtomograms`


