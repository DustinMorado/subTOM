===============
subtom_bandpass
===============

Creates and/or applies a bandpass filter to a volume.

This utility script uses one MATLAB compiled script below:

- :doc:`../functions/subtom_bandpass`

-------
Options
-------

Directories
-----------

scratch_dir
  Absolute path to the folder with the input to be processed.
  Other paths are relative to this one.

mcr_cache_dir
  Absolute path to MCR directory for the processing.

exec_dir
  Directory for executables

Variables
---------

bandpass_exec
  Bandpass executable

File Options
------------

input_motl_fn
  Relative path and name of the input volume to build and filter the bandpass
  against. If you just want to visualize an arbitrary filter you can use
  subtom_shape to create a template of the correct size and not ask for the
  filtered output.

filter_fn
  Relative path and name of the Fourier bandpass filter to write. If you do not
  want to output the filter volume simply leave this option blank.

output_fn
  Relative path and name of the filtered volume to write. If you do not want to
  output the filtered volume simply leave this option blank.

Filter Options
--------------

high_pass_fp
  High pass filter cutoff (in transform units (pixels): calculate as
  (box_size*pixelsize)/(resolution_real) (define as integer e.g. high_pass_fp=2)

high_pass_sigma
  High pass filter falloff sigma (in transform units (pixels): describes a
  Gaussian sigma for the falloff of the high-pass filter past the cutoff above.

low_pass_fp
  Low pass filter (in transform units (pixels): calculate as
  (box_size*pixelsize)/(resolution_real) (define as integer e.g. low_pass_fp=7).

low_pass_sigma
  Low pass filter falloff sigma (in transform units (pixels): describes a
  Gaussian sigma for the falloff of the low-pass filter past the cutoff above.

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    bandpass_exec="${exec_dir}/MOTL/subtom_unclass_motl"

    input_fn="ref/ref_1.em"

    filter_fn="otherinputs/bandpass_hp2s2_lp15s3.em"

    output_fn="ref/ref_hp2s2_lp15s3_1.em"

    high_pass_fp=2

    high_pass_sigma=2

    low_pass_fp=15

    low_pass_sigma=3

