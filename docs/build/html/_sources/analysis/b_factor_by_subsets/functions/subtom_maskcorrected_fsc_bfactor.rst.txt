================================
subtom_maskcorrected_FSC_bfactor
================================

Calculates "mask-corrected" FSC and sharpened refs.

.. code-block:: Matlab

    subtom_maskcorrected_fsc_bfactor(
        'ref_a_fn_prefix', ref_a_fn_prefix ('even/ref/ref'),
        'ref_b_fn_prefix', ref_b_fn_prefix ('odd/ref/ref'),
        'motl_a_fn_prefix', motl_a_fn_prefix ('even/combinedmotl/allmotl'),
        'motl_b_fn_prefix', motl_b_fn_prefix ('odd/combinedmotl/allmotl'),
        'fsc_mask_fn', fsc_mask_fn ('FSC/fsc_mask.em'),
        'output_fn_prefix', output_fn_prefix ('FSC/ref'),
        'filter_a_fn', filter_a_fn (''),
        'filter_b_fn', filter_b_fn (''),
        'do_reweight', do_reweight (0),
        'do_sharpen', do_sharpen (0),
        'plot_fsc', plot_fsc (0),
        'plot_sharpen', plot_sharpen (0),
        'filter_mode', filter_mode (1),
        'pixelsize', pixelsize (1.0),
        'nfold', nfold (1),
        'filter_threshold', filter_threshold (0.143),
        'rand_threshold', rand_threshold (0.8),
        'box_gaussian', box_gaussian (1),
        'iclass', iclass (0),
        'iteration', iteration (1))

Takes in two references ``ref_a_fn_prefix`` _#.em and ``ref_b_fn_prefix`` _#.em
where # corresponds to ``iteration`` and a FSC mask ``fsc_mask_fn`` and
calculates a "mask-corrected" FSC. This works by randomizing the structure
factor phases beyond the point where the unmasked FSC curve falls below a given
threshold (by default 0.8) and calculating an additional FSC between these phase
randomized maps.  This allows for the determination of the extra correlation
caused by effects of the mask, which is then subtracted from the normal masked
FSC curves. The curve will be saved as a Matlab figure and a PDF file, and if
``plot_fsc`` is true it will also be displayed.

The script can also output maps with the prefix ``output_fn_prefix`` that have
been sharpened with ``b_factor`` if ``do_sharpen`` is turned on. This setting
has two threshold settings selected using ``filter_mode``, FSC (1) and pixel
(2).  FSC allows you to use a FSC-value ``filter_threshold`` as a cutoff for the
lowpass filter, while using pixels allows you to use an arbitrary resolution
cutoff in ``filter_threshold``. The sharpening curve will be saved as a Matlab
figure and a pdf file, and if ``plot_sharpen`` is true it will also be
displayed.

This function estimates the B-factor to apply versus applying an ad-hoc
B-factor by fitting a curve to the drop in resolution as the number of
particles decreases. This is detailed in Rosenthal and Henderson, 2003,
doi:10.1016/j.jmb.2003.07.013

Finally this script can also perform and output reweighted maps if
``do_reweight`` is true, and the pre-calculated Fourier weight volumes
``filter_a_fn`` and ``filter_b_fn``.

-------
Example
-------

.. code-block:: Matlab

    subtom_maskcorrected_fsc_bfactor(...
        'ref_a_fn_prefix', 'even/ref/ref', ...
        'ref_b_fn_prefix', 'odd/ref/ref', ...
        'motl_a_fn_prefix', 'even/combinedmotl', ...
        'motl_b_fn_prefix', 'odd/combinedmotl', ...
        'fsc_mask_fn', 'FSC/fsc_mask.em', ...
        'output_fn_prefix', 'FSC/ref', ...
        'filter_a_fn', '', ...
        'filter_b_fn', '', ...
        'do_reweight', 0, ...
        'do_sharpen', 1, ...
        'plot_fsc', 1, ...
        'plot_sharpen', 1, ...
        'filter_mode', 1, ...
        'pixelsize', 1.35, ...
        'nfold', 6, ...
        'filter_threshold', 0.143, ...
        'rand_threshold', 0.8, ...
        'box_gaussian', 3, ...
        'iclass', 0, ...
        'iteration', 1)

--------
See Also
--------

* :doc:`subtom_parallel_sums_bfactor`
* :doc:`subtom_weighted_average_bfactor`
