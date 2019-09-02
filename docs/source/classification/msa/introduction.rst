================================================
Multivariate Statistical Analysis Classification
================================================

In Multivariate Statistical Analysis (MSA) classification the full set of
particles are simplified into a new lower-dimensional representation by means of
EigenValue decomposition. Particles projected onto these most variable
basis-vectors then can be clustered using a variety of methods.

Within subTOM particles are first compiled into a 2-D Matrix denoted here as the
X-Matrix, which holds the aligned, band-pass filtered and masked particle data.
To speed up calculation particles can be pre-aligned using the function
``subtom_parallel_prealign``. Batches of the X-Matrix are calculated in parallel
with ``subtom_parallel_xmatrix_msa`` and then combined and column-centered with
``subtom_join_xmatrix``. 

Next the X-Matrix is used to calculated the covariance matrix which is scaled
using the so-called 'modulation metric' as described in L. Borland and M. van
Heel in J. Opt. Soc. Am. A 1990, which is similar to the Chi-Square metrics used
in Correspondance Analysis of ordinal data. This covariance matrix is then
decomposed into it's Eigenvectors and Eigenvalues and these are used along with
the X-Matrix to determine the Eigenvolumes of the dataset with
``subtom_eigenvolumes_msa``.

These volumes are then used to determine the low-rank approximation coefficients
in volume space for clustering. A larger particle superset can be projected onto
the volumes to speed up classification of large datasets. Coefficients are also
calculated in parallel in batches with ``subtom_parallel_eigcoeffs_msa`` and
joined with ``subtom_join_eigencoeffs_msa``.

Finally using a user-selected subset of the determined coefficients, the data is
clustered either by Hierarchical Ascendant Clustering using a Ward distance
criterion, K-Means clustering, or a Gaussian Mixture model with the function
``subtom_cluster``. This clustering is then used to generate the final class
averages.
