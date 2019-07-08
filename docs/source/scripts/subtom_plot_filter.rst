==================
subtom_plot_filter
==================

Plots the filter applied to the reference from a user-specified set of band-pass
settings. The filter can also be plotted in conjunction with a CTF root square
function and a B-factor described exponential decay falloff curve. The plot can
also be saved to disk.

This utility script uses one MATLAB compiled scripts below:

- :doc:`../functions/subtom_plot_filter`

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

plot_filter_exec
  Plot filter executable.

File Options
------------

output_fn_prefix
  Relative path and name prefix of the output plot. If you want to skip this
  output file leave this set to "".

Plot Filter Options
-------------------

box_size
  Size of the volume in pixels. The volume will be a cube with this side length.

pixelsize
  Pixelsize of the data in Angstroms.

high_pass_fp
  High pass filter cutoff (in transform units (pixels): calculate as:

  .. code-block:: matlab

      high_pass_fp = (box_size * pixelsize) / (high_pass_A)

 (define as integer e.g. high_pass_fp=2)

high_pass_sigma
  High pass filter falloff sigma (in transform units (pixels): describes a
  Gaussian sigma for the falloff of the high-pass filter past the cutoff above.

low_pass_fp
  Low pass filter cutoff (in transform units (pixels): calculate as:

  .. code-block:: matlab

      low_pass_fp = (box_size * pixelsize) / (low_pass_A)

 (define as integer e.g. low_pass_fp=48)

low_pass_sigma
  Low pass filter falloff sigma (in transform units (pixels): describes a
  Gaussian sigma for the falloff of the low-pass filter past the cutoff above.

defocus
  Defocus to plot along with band-pass filter in Angstroms with underfocus being
  positive. The graphic will include a line for the CTF root square and how it
  is attenuated by the band-pass which can be useful for understanding how
  amplitudes are modified by the filter. If you do not want to use this option
  just leave it set to "0" or "".

voltage
  Voltage in keV used for calculating the CTF. If you do not want to plot a CTF
  function leave this set to "" or "300".

cs
  Spherical aberration in mm used for calculating the CTF. If you do not want to
  plot a CTF function leave this set to "" or "0.0".

ac
  Amplitude contrast as a fraction of contrast (i.e. between 0 and 1) used for
  calculating the CTF. If you do not want to plot a CTF function leave this set
  to "" or "1".

phase_shift
  Phase shift in degrees used for calculating the CTF. If you do not want to
  plot a CTF function leave this set to "" or "0".

b_factor
  B-Factor describing the falloff of signal in the data by a multitude of
  amplitude decay factors. The graphic will include a line for the falloff and
  how it interacts with both the CTF if one was given and the band-pass filter.
  If you do not want to use this option just leave it set to "" or "0"

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    plot_filter_exec="${exec_dir}/utils/subtom_plot_filter"

    output_fn_prefix=""

    box_size="192"

    pixelsize="1.35"

    high_pass_fp="1"

    high_pass_sigma="2"

    low_pass_fp="48"

    low_pass_sigma="3"

    defocus="15000"

    voltage="300"

    cs="2.7"

    ac="0.07"

    phase_shift="0.0"

    b_factor="-130"
