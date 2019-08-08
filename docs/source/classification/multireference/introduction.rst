=============================
Multireference Classification
=============================

In multireference classification the full set of particles are compared to a
predefined number of reference volumes.  Each experimental particle is aligned
with respect to all references and is assigned to one of them based on the
constrained cross-correlation coefficient as a similarity measure.  Averaging
over the subsets determined serves to calculate new, improved references for
further iterations. The user can then iterate this procedure and stop when no
more migration of particles between subsets is observed and the averages within
each subset do not change any more.

Within subTOM a function ``subtom_rand_class_motl`` serves to initialize random
classes and initial references if the user does not alread have them, and then
the subTOM functions ``subtom_scan_angles_exact``, ``subtom_parallel_sums``,
``subtom_weighted_average`` and ``subtom_compare_motls`` have been modified to
fit the new modus of multireference classification and alignment.
