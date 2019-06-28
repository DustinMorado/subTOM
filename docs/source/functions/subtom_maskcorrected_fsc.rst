========================
subtom_maskcorrected_FSC
========================

Calculates "mask-corrected" FSC and sharpened refs.

.. code-block:: Matlab

    subtom_maskcorrected_fsc(
        'ref_a_fn_prefix', ref_a_fn_prefix ('even/ref/ref'),
        'ref_b_fn_prefix', ref_b_fn_prefix ('odd/ref/ref'),
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
        'b_factor', b_factor (0),
        'box_gaussian', box_gaussian (1),
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

Finally this script can also perform and output reweighted maps if
``do_reweight`` is true, and the pre-calculated Fourier weight volumes
``filter_a_fn`` and ``filter_b_fn``.

-------
Example
-------

.. code-block:: Matlab

    subtom_maskcorrected_fsc(...
        'ref_a_fn_prefix', 'even/ref/ref', ...
        'ref_b_fn_prefix', 'odd/ref/ref', ...
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
        'b_factor', -1500, ...
        'box_gaussian', 3, ...
        'iteration', 1)
