==================
subtom_plot_filter
==================

Creates a graphic of bandpass filters optionally with CTF.

.. code-block:: matlab

    subtom_plot_filter(
        'box_size', box_size (''),
        'pixelsize', pixelsize (1),
        'high_pass_fp', high_pass_fp (0),
        'high_pass_sigma', high_pass_sigma (0),
        'low_pass_fp', low_pass_fp (0),
        'low_pass_sigma', low_pass_sigma (0),
        'defocus', defocus (0),
        'voltage', voltage (300),
        'cs', cs (0),
        'ac', ac ('1.0'),
        'phase_shift', phase_shift (0.0),
        'b_factor', b_factor (0.0),
        'output_fn_prefix', output_fn_prefix (''))

Takes in the local alignment filter parameters used in subTOM, ``high_pass_fp``,
``high_pass_sigma``, ``low_pass_fp``, and ``low_pass_sigma``; then produces a
figure showing the filter that will be applied to the Fourier transform of the
reference during alignment.  The Fourier pixel frequencies are converted into
Angstroms using the given ``box_size`` and ``pixelsize``.  A single CTF can also
be specified with ``defocus``, ``voltage``, ``cs``, ``ac``, ``phase_shift``, and
the root square of this curve will be plotted in addition to how the band-pass
filter affects the amplitude effects of the CTF. Finally a B-factor falloff can
also be specified with ``b_factor``, and this decay curve will also be plotted
and also plotted with the CTF root square, and also the CTF root square and
band-pass filter all together, so a cumulative effect of a specific choice of
filter parameters at a given defocus and falloff can be observed. If
``output_fn_prefix`` is not emtpy it is used to save the graphic in MATLAB
figure, pdf, and png formatted files.

-------
Example
-------

.. code-block:: matlab

    subtom_plot_filter(...
        'box_size', 192, ...
        'pixelsize', 1.35, ...
        'high_pass_fp', 1, ...
        'high_pass_sigma', 2, ...
        'low_pass_fp', 48, ...
        'low_pass_sigma', 3, ...
        'defocus', 15000, ...
        'voltage', 300, ...
        'cs', 2.7, ...
        'ac', 0.07, ...
        'phase_shift', 0.0, ...
        'b_factor', 0, ...
        'output_fn_prefix', 'alignment_1');

--------
See Also
--------

* :doc:`subtom_plot_filter`
* :doc:`subtom_shape`
