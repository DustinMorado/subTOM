========================
subtom_maskcorrected_fsc
========================

Calculates a *"mask-corrected"* Fourier Shell Correlation between two volumes
and generates a final average as well as optionally ad-hoc B-factor sharpened
maps.

This script is meant to run on a local workstation with access to an X server
in the case when the user wants to display figures. I am unsure if both
plotting options are disabled if the graphics display is still required, but
if not it could be run remotely on the cluster, but it shouldn't be necessary.

This EM-map analysis script uses just one MATLAB compiled scripts below:

- :doc:`../functions/subtom_maskcorrected_fsc`

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
  Directory for executables.

Variables
---------

fsc_exec
  Mask-corrected FSC executable.

File Options
------------

ref_a_fn_prefix
  Relative path and filename prefix of the first half-map.

ref_b_fn_prefix
  Relative path and filename prefix of the second half-map.

iteration
  The index of the reference to generate : input will be
  ref_{a,b}_fn_prefix_iteration.em (define as integer).

fsc_mask_fn
  Relative path and name of the FSC mask.

filter_a_fn
  Relative path and name of the Fourier filter volume for the first half-map. If
  not using the option do_reweight just leave this set to ""

filter_b_fn
  Relative path and name of the Fourier filter volume for the second half-map.
  If not using the option do_reweight just leave this set to ""

output_fn_prefix
  Relative path and prefix for the name of the output maps and figures.

FSC Options
-----------

pixelsize
  Pixelsize of the half-maps in Angstroms.

nfold
  Symmetry to applied the half-maps before calculating FSC (1 is no symmetry).

rand_threshold
  The Fourier pixel at which phase-randomization begins is set automatically to
  the point where the unmasked FSC falls below this threshold.

plot_fsc
  Plot the FSC curves - 1 = yes, 0 = no

Sharpening Options
------------------

do_sharpen
  Set to 1 to sharpen map or 0 to skip and just calculate the FSC.

b_factor
  B-Factor to be applied; must be negative or zero.

box_gaussian
  To remove some of the edge-artifacts associated with map-sharpening the edges
  of the map can be smoothed with a gaussian. Set to 0 to not smooth the edges,
  otherwise it must be set to an odd number.

filter_mode
  There are two mode used for low pass filtering. The first uses an FSC
  based threshold (mode 1), i.e. after FSC < 0.143, or a pixel-based
  resolution threhsold (mode 2).

filther_threshold
  Set the threshold for the low pass filtering described above. Should be less
  than 1 for FSC based threshold (mode 1), and an integer value for the Fourier
  pixel-based threshold (mode 2).

plot_sharpen
  Plot the sharpening curve - 1 = yes, 0 = no.

Reweighting Options
-------------------

do_reweight
  Set to 1 to apply the externally calculated Fourier weights filter_A_fn and
  filter_B_fn to each half-map to reweight the final output map.

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    fsc_exec="${exec_dir}/analysis/subtom_maskcorrected_fsc"

    ref_a_fn_prefix="even/ref/ref"

    ref_b_fn_prefix="odd/ref/ref"

    iteration=1

    fsc_mask_fn="FSC/fsc_mask.em"

    filter_a_fn=""

    filter_b_fn=""

    output_fn_prefix="FSC/ref"

    pixelsize=1

    nfold=1

    rand_threshold=0.8

    plot_fsc=1

    do_sharpen=1

    b_factor=-150

    box_gaussian=3

    filter_mode=1

    filter_threshold=0.143

    plot_sharpen=1

    do_reweight=0
