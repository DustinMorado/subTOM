===========================================
Principal Component Analysis Classification
===========================================

In principal component analysis (PCA) classification the full set of particles
are simplified into a new lower-dimensional representation by means of Eigen or
Singular Value decomposition methods. Particles projected onto these most
variable basis-vectors then can be clustered using a variety of methods.

Within subTOM particles are first compared using Constrained Cross-Correlation
taking into account the missing wedge. The pairs used in comparison are
pre-calculated with the function ``subtom_prepare_ccmatrix``. To speed up
calculation particles can be pre-aligned using the function
``subtom_parallel_prealign``.

The comparisons are calculated in parallel batches with
``subtom_parallel_ccmatrix`` and the results are combined with
``subtom_join_ccmatrix``. The Cross-Correlation matrix is then decomposed into a
user-given number of basis vectors using either Eigenvalue decomposition with
``subtom_eigs`` or Singular Value decomposition with ``subtom_svds``, which the
basis vectors and their respective weights.

The particles that were compared against are then projected onto these vectors
by first constructing a matrix of the aligned data with
``subtom_parallel_xmatrix`` and then projected in parallel batches with
``subtom_parallel_eigenvolumes`` and joined with ``subtom_join_eigenvolumes``.
These volumes are then used to determine the low-rank approximation coefficients
in volume space for clustering. A larger particle superset can be projected onto
the volumes to speed up classification of large datasets. Coefficients are also
calculated in parallel in batches with ``subtom_parallel_eigcoeffs`` and joined
with ``subtom_join_eigencoeffs``.

Finally using a user-selected subset of the determined coefficients, the data is
clustered either by Hierarchical Ascendant Clustering using a Ward distance
criterion, K-Means clustering, or a Gaussian Mixture model with the function
``subtom_cluster``. This clustering is then used to generate the final class
averages.
