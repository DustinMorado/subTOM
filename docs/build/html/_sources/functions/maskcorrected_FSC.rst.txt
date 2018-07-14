=================
maskcorrected_FSC
=================

Calculates "mask-corrected" FSC and sharpened volumes.

.. code-block:: Matlab

    maskcorrected_fsc(
        reference_a_fn,
        reference_b_fn,
        fsc_mask_fn,
        output_fn_prefix,
        pixelsize,
        nfold,
        rand_threshold,
        plot_fsc,
        do_sharpen,
        b_factor,
        box_gaussian,
        filter_mode,
        filter_threshold,
        plot_sharpen,
        do_reweight,
        filter_a_fn,
        filter_b_fn)

Takes in two references ``reference_a_fn`` and ``reference_b_fn`` and a FSC mask
``fsc_mask_fn`` and calculates a "mask-corrected" FSC. This works by randomizing
the structure factor phases beyond the point where the unmasked FSC curve falls
below a given threshold (by default 0.8) and calculating an additional FSC
between these phase randomized maps.  This allows for the determination of the
extra correlation caused by effects of the mask, which is then subtracted from
the normal masked FSC curves. The curve will be saved as a Matlab figure and a
PDF file, and if ``plot_fsc`` is true it will also be displayed.

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

--------
Example:
--------

.. code-block:: Matlab

    maskcorrected_fsc('even/ref/ref_1.em', 'odd/ref/ref_1.em', ...
        'fscmask.em', 'ref_1', 1.177, 2, 0.8, 1, 1, -100, 1, 1, 0.143, 1, ...
        'ctffilter_even.em', 'ctffilter_odd.em')

Would calculate the mask-corrected FSC between the two maps with two-fold
nfold and under the mask. The FSC curve and curve used in sharpening will
be displayed. The map will be filtered using the mask-corrected curve
where it falls below 0.143. The map will also be reweighted using the
given Fourier reweighting volumes. The function will write out the
following files:

* 'ref_1_unsharpref.em' - The joined map with no sharpening applied
* 'ref_1_finalsharpref_100.em' - The joined map sharpened with a
  B-Factor of -100.
* 'ref_1_finalsharpref_100_reweight.em' - The joined map sharpened
  with a B-Factor of -100 and reweighted.
* 'ref_1_FSC.fig' - The unmasked, masked, phase-randomized, and
  mask-corrected FSC curves in Matlab figure format.
* 'ref_1_FSC.pdf' - The unmasked, masked, phase-randomized, and
  mask-corrected FSC curves in PDF format.
* 'ref_1_sharp.fig' - The curve  used to FSC-filter and sharpen the
  map in Matlab figure format.
* 'ref_1_sharp.pdf' - The curve  used to FSC-filter and sharpen the
  map in PDF format.


