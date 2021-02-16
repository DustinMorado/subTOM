===============
subtom_bandpass
===============

Creates and/or applies a bandpass filter to a volume.

.. code-block:: Matlab

    subtom_bandpass(
        'input_fn', input_fn (''),
        'high_pass_fp', high_pass_fp (0),
        'high_pass_sigma', high_pass_sigma (0),
        'low_pass_fp', low_pass_fp (0),
        'low_pass_sigma', low_pass_sigma (0),
        'filter_fn', filter_fn (''),
        'output_fn', output_fn (''))

Simply creates and/or applies a bandpass filter just as would be done during
alignment, with the option to write out the Fourier Filter volume as well just
for visualization purposes. ``input_fn`` defines the volume to be filtered, or
at minimum the box size used to create the filter volume. The Fourier domain
filter created is dependent on the parameters ``high_pass_fp``,
``high_pass_sigma``, ``low_pass_fp``, ``low_pass_sigma`` which are all in the
units of Fourier pixels. If ``filter_fn`` is a non-empty string then the
bandpass filter volume itself is written to the filename given. If ``output_fn``
is a non-empty string then the bandpass filtered volume is written to the
filename given. 

-------
Example
-------

.. code-block:: Matlab

    subtom_bandpass(...
        'input_fn', 'ref/ref_1.em', ...
        'high_pass_fp', 2, ...
        'high_pass_sigma', 2, ...
        'low_pass_fp', 15, ...
        'low_pass_sigma', 3, ...
        'filter_fn', 'otherinputs/bandpass_hp2s2_lp15s3.em',
        'output_fn', 'ref/ref_hp2s2_lp15s3_1.em')

--------
See Also
--------

* :doc:`subtom_scan_angles_exact`
* :doc:`subtom_plot_filter`
