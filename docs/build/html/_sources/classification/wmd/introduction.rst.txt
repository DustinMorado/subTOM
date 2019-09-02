======================================
Wedge-Masked Difference Classification
======================================

In Wedge-Masked Difference (WMD) classification the full set of particles are
simplified into a new lower-dimensional representation by means of Singular
Value decomposition after attempting to take into account the effects of the
missing-wedge. Particles projected onto these most variable basis-vectors then
can be clustered using a variety of methods.

Within subTOM, wedge-masked differences (the result of the subtraction of the
overall reference, weighted with the particles missing-wedge, and the particle
itself) are first compiled into a 2-D Matrix denoted here as the D-Matrix, which
holds the aligned, band-pass filtered and masked difference data. To speed up
calculation particles can be pre-aligned using the function
``subtom_parallel_prealign``. Batches of the D-Matrix are calculated in parallel
with ``subtom_parallel_dmatrix`` and then combined and column-centered with
``subtom_join_dmatrix``. 

Next the D-Matrix is decomposed by Singular Value decomposition as to skip
calculation of the covariance matrix as described in J. Heumann et al.
in J. Struct. Biol. 2011. This determines a set of 
right Singular vectors and Singular values and these are used along with
the D-Matrix to determine the Eigenvolumes of the dataset with
``subtom_eigenvolumes_wmd``.

These volumes are then used to determine the low-rank approximation coefficients
in volume space for clustering. A larger particle superset can be projected onto
the volumes to speed up classification of large datasets. Coefficients are also
calculated in parallel in batches with ``subtom_parallel_coeffs`` and
joined with ``subtom_join_coeffs``.

Finally using a user-selected subset of the determined coefficients, the data is
clustered either by Hierarchical Ascendant Clustering using a Ward distance
criterion, K-Means clustering, or a Gaussian Mixture model with the function
``subtom_cluster``. This clustering is then used to generate the final class
averages.
