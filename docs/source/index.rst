.. subTOM documentation master file, created by
   sphinx-quickstart on Wed Jul  4 18:29:14 2018.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

======
subTOM
======

**SubTOM** - *Subvolume processing scripts with the TOM toolbox* is a collection
of scripts form a pipeline for subvolume alignment and averaging of electron
cryo-tomography data.

.. toctree::
    :maxdepth: 1
    :caption: Table of Contents:

    installation
    conventions
    tutorial

.. toctree::
    :maxdepth: 1
    :caption: Links to Individual Script Documentation:

    Introduction <scripts/introduction>
    clean_motl.sh <scripts/clean_motl>
    compare_motls.sh <scripts/compare_motls>
    even_odd_motl.sh <scripts/even_odd_motl>
    extract_noise.sh <scripts/extract_noise>
    extract_subtomograms.sh <scripts/extract_subtomograms>
    maskcorrected_FSC.sh <scripts/maskcorrected_FSC>
    parallel_average.sh <scripts/parallel_average>
    preprocess.sh <scripts/preprocess>
    run_1.sh <scripts/run_1>
    run_nova.sh <scripts/run_nova>
    scale_motl.sh <scripts/scale_motl>
    seed_positions.sh <scripts/seed_positions>
    split_motl_by_row.sh <scripts/split_motl_by_row>

.. toctree::
    :maxdepth: 1
    :caption: Links to Individual Function Documentation:

    Introduction <functions/introduction>
    clean_motl.m <functions/clean_motl>
    compare_motls.m <functions/compare_motls>
    dose_filter_tiltseries.m <functions/dose_filter_tiltseries>
    even_odd_motl.m <functions/even_odd_motl>
    extract_noise.m <functions/extract_noise>
    extract_subtomograms.m <functions/extract_subtomograms>
    join_motls.m <functions/join_motls>
    maskcorrected_FSC.m <functions/maskcorrected_FSC>
    parallel_sums.m <functions/parallel_sums>
    scale_motl.m <functions/scale_motl>
    scan_angles_exact.m <functions/scan_angles_exact>
    seed_positions.m <functions/seed_positions>
    split_motl_by_row.m <functions/split_motl_by_row>
    weighted_average.m <functions/weighted_average>

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
