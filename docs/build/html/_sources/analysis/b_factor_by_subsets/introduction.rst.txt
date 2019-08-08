===================
B-Factor by Subsets
===================

To estimate the B-factor in maps of low to intermediate resolution, Guinier plot
analysis is unsuitable because the structure factor dominates the appearance and
slope of the amplitude decay at resolutions up to 10 Angstroms.

Therefore another way to estimate the B-factor is to look at how the Resolution
decays over smaller and smaller subsets of the particles that form each
half-map. A linear function is fit to the reciprocal square of resolutions
determined by Gold-standard FSCs against the natural log of asymmetric units.

The method is described in detail in Rosenthal, Henderson 2003, and here the
averaging and analysis functions ``subtom_maskcorrected_fsc``,
``subtom_parallel_sums``, and ``subtom_weighted_average`` have been slightly
modified to first generate the average of successively smaller subsets, with
each subset being roughly half of the subset before it until the subset would be
less than 128 particles. Then the resolution of each subset is determined and
the B-factor is estimated and this estimate B-factor can then be used to sharpen
the final post-processed map.
