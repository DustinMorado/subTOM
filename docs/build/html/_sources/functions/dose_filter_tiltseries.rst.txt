======================
dose_filter_tiltseries
======================

Generates a tiltseries filtered by applied dose.

.. code-block:: Matlab

    dose_filter_tiltseries(
        input_fn
        output_fn
        dose_fn)

A script to read in a tilt stack with the name format ``input_fn``, and a
CSV-format file with the name formate ``dose_fn`` with the accumulated dose for
each tilt image on each respective line to generate a stack that has been
filtered by dose and is written out as ``output_fn``.

--------
Example:
--------

.. code-block:: Matlab

    dose_filter_tiltseries('ts_01_aligned.st', 'ts_01_dose_filt.st', ...
        'ts_01_dose-list.csv');


