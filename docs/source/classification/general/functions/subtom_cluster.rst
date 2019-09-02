==============
subtom_cluster
==============

Classifies particles based on given coefficients.

.. code-block:: Matlab

    subtom_cluster(
        'all_motl_fn_prefix', all_motl_fn_prefix ('combinedmotl/allmotl'),
        'coeff_fn_prefix', coeff_fn_prefix ('class/coeff'),
        'output_motl_fn_prefix', output_motl_fn_prefix ('class/allmotl'),
        'iteration', iteration (1),
        'cluster_type', cluster_type ('kmeans'),
        'eig_idxs', eig_idxs ('all'),
        'num_classes', num_classes ('2'))

Takes the motive list given by ``all_motl_fn_prefix`` and the coefficients
specified by ``coeff_fn_prefix`` for the iteration ``iteration`` and clusters
the data based on the coefficients. Clustering can be done using one of three
methods, which are specfied by ``cluster_type``. The options are K-Means
clustering with 'kmeans', Hierarchical Ascendant Clustering with 'hac' and a
Gaussian Mixture Model with 'gaussmix'. A subset of coefficients can be selected
and are given as a semicolon-separated string of indices as ``coeff_idxs``. The
string can also contain ranges delimited by a dash, for example '1;3;5-10'. The
data will be clustered into ``num_classes`` number of clusters and the clustered
motive list will be written out to a file given by ``output_motl_fn_prefix``.

-------
Example
-------

.. code-block:: Matlab

    subtom_cluster(...
        'all_motl_fn_prefix', 'combinedmotl/allmotl', ...
        'coeff_fn_prefix', 'class/eigcoeff_msa', ...
        'output_motl_fn_prefix', 'class/allmotl_msa', ...
        'iteration', 1, ...
        'cluster_type', 'hac', ...
        'coeff_idxs', '2-5;7;9-20', ...
        'num_classes', '20')

--------
See Also
--------

* :doc:`subtom_parallel_prealign`
* :doc:`subtom_parallel_sums_cls`
* :doc:`subtom_scan_angles_exact_refs`
* :doc:`subtom_weighted_average_cls`
