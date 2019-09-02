========================
Classification in subTOM
========================

There are several classification strategies within subTOM. Three are variants of
Multivariate Statistical Analysis (MSA), and the final is Multireference
alignment.  Within all of these there are some functions which are generally
applicable and so they are shared between each modus of classification. This
includes the clustering of MSA data (``subtom_cluster``), as well as the
averaging of data that has been classified (``subtom_parallel_sums_cls`` and
``subtom_weighted_average_cls``). Since classification, particularly prinicipal
component analysis (PCA), is very operation intensive there is also a function
to pre-align all extracted particles and write them to disk to speed up later
processing steps (``subtom_parallel_prealign``).
