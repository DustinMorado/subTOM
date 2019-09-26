=================
subtom_clean_motl
=================

Cleans a given MOTL file based on distance and or CC scores.

.. code-block:: matlab

    subtom_clean_motl(
        'input_motl_fn', input_motl_fn (''),
        'output_motl_fn', output_motl_fn (''),
        'tomo_row', tomo_row (7),
        'do_ccclean', do_ccclean (0),
        'cc_fraction', cc_fraction (1),
        'cc_cutoff', cc_cutoff (-1),
        'do_distance', do_distance (0),
        'distance_cutoff', distance_cutoff (Inf),
        'do_cluster', do_cluster (0),
        'cluster_distance', cluster_distance (0),
        'cluster_size', cluster_size (1),
        'do_edge', do_edge (0),
        'tomogram_dir', tomogram_dir (''),
        'box_size', box_size (0),
        'write_stats', write_stats (0),
        'output_stats_fn', output_stats_fn (''))

Takes the motl given by ``input_motl_fn``, and splits it internally by
tomogram given by the row ``tomo_row`` in the MOTL, and then removes particles
by one or multiple methods, if ``do_ccclean`` evaluates to true as a boolean
then one of two methods can be applied. Either ``cc_cutoff`` is specified and
particles that have a CCC less than ``cc_cutoff`` will be discarded.
Alternatively ``cc_fraction`` can be specified as a number between 0 and 1 and
that fraction of the data with the highest CCCs will be kept and the rest
discarded. If ``do_distance`` evaluates to true as a boolean then particles
that are within ``distance_cutoff`` pixels of each other will be determined
and only the particle with the highest CCC, will be kept. If
``do_cluster`` evaluates to true as a boolean,then particles must have at
least ``cluster_size`` neighbor particles within ``cluster_distance`` to be kept
after cleaning. Finally if ``do_edge`` evaluates to true as a boolean then the
program will look for a tomogram in ``tomogram_dir``, and if a particle of
box size ``box_size`` would extend outside of the tomogram it will be removed.

-------
Example
-------

.. code-block:: matlab

    subtom_clean_motl(...
        'input_motl_fn', 'combinedmotl/allmotl_3.em', ...
        'output_motl_fn', 'combinedmotl/allmotl_3_cc0.1_dist4_c2d10.em', ...
        'tomo_row', 7, ...
        'do_ccclean', 1, ...
        'cc_fraction', 1, ...
        'cc_cutoff', 0.1, ...
        'do_distance', 1, ...
        'distance_cutoff', 4, ...
        'do_cluster', 1, ...
        'cluster_distance', 10, ...
        'cluster_size, 2, ...
        'do_edge', 1, ...
        'tomogram_dir', '../../tomos/bin8', ...
        'box_size', 36, ...
        'write_stats', 1, ...
        'output_stats_fn', 'combinedmotl/allmotl_3_cleaned_stats.csv')

--------
See Also
--------

* :doc:`subtom_cat_motls`
* :doc:`subtom_compare_motls`
* :doc:`subtom_even_odd_motl`
* :doc:`subtom_random_subset_motl`
* :doc:`subtom_renumber_motl`
* :doc:`subtom_rotx_motl`
* :doc:`subtom_scale_motl`
* :doc:`subtom_seed_positions`
* :doc:`subtom_split_motl_by_row`
* :doc:`subtom_transform_motl`
* :doc:`subtom_unclass_motl`
