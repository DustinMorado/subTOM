==========================
subtom_b_factor_by_subsets
==========================

Estimates the B-Factor by determine the resolution of subsets of particles as
described in Rosenthal, Henderson 2003.

This subtomogram averaging analysis script uses three MATLAB compiled scripts
below:

- :doc:`../functions/subtom_maskcorrected_fsc`
- :doc:`../functions/subtom_parallel_sums`
- :doc:`../functions/subtom_weighted_average`

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

sum_exec
  Parallel Summing executable

avg_exec
  Weighted Averaging executable

fsc_exec
  FSC executable

Memory Options
--------------

mem_free
  The amount of memory the job requires for alignment. This variable determines
  whether a number of CPUs will be requested to be dedicated for each job. At
  24G, one half of the CPUs on a node will be dedicated for each of the
  processes (12 CPUs). At 48G, all of the CPUs on the node will be dedicated for
  each of the processes (24 CPUs).

mem_max
  The upper bound on the amount of memory the alignment job is allowed to use.
  If any of the processes request or require more memory than this, the queue
  will kill the process. This is more of an option for safety of the cluster to
  prevent the user from crashing the cluster requesting too much memory.

Other Cluster Options
---------------------

job_name
  The job name prefix that will be used for the cluster submission scripts, log
  files, and error logs for the processing. Be careful that this name is unique
  because previous submission scripts, logs, and error logs with the same job
  name prefix will be overwritten in the case of a name collision.

array_max
  The maximum number of jobs per cluster submission script. Cluster submission
  scripts work using the array feature common to queuing systems, and this value
  is the maximum array size used in a script. If the user requests more batches
  of processing than this value, then the submission scripts will be split into
  files of up to array_max jobs.

max_jobs
  The maximum number of jobs for alignment. If the number of batches / exceeds
  this value the script will immediately quit.

run_local
  If the user wants to skip the cluster and run the job locally, this value
  should be set to 1.

Subtomogram Averaging Workflow Options
--------------------------------------

Parallelization Options
-----------------------

iteration
  The index of the reference to generate : input will be
  all_motl_fn_prefix_iteration.em (define as integer)

num_avg_batch
  The number of batches to split the parallel subtomogram averaging job into.

File Options
------------

all_motl_a_fn_prefix
  Relative path and name prefix of the concatenated motivelist of all particles
  in the first half-map.

all_motl_b_fn_prefix
  Relative path and name prefix of the concatenated motivelist of all particles
  in the second half-map.

ref_a_fn_prefix
  Relative path and name prefix of the reference volumes of the first half-map.

ref_b_fn_prefix
  Relative path and name prefix of the reference volumes of the second half-map.

ptcl_a_fn_prefix
  Relative path and name prefix of the subtomograms that comprise the first
  half-map.

ptcl_b_fn_prefix
  Relative path and name prefix of the subtomograms that comprise the second
  half-map.

weight_a_fn_prefix
  Relative path and name prefix of the weight files for the first half-map.

weight_b_fn_prefix
  Relative path and name prefix of the weight files for the second half-map.

weight_sum_a_fn_prefix
  Relative path and name prefix of the partial weight files of the first
  half-map.

weight_sum_b_fn_prefix
  Relative path and name prefix of the partial weight files of the second
  half-map.

output_fn_prefix
  Relative path and prefix for the name of the output maps and figures.

Averaging Options
-----------------

tomo_row
  Which row in the motl file contains the correct tomogram number.
  Usually row 5 and 7 both correspond to the correct value and can be used
  interchangeably, but there are instances when 5 contains a sequential ordered
  value starting from 1, while 7 contains the correct corresponding tomogram.

iclass
  Particles with that number in position 20 of motivelist will be added to new
  average (define as integer e.g. iclass=1). NOTES: Class 1 is ALWAYS added.
  Negative classes and class 2 are never added.

Mask Corrected FSC Workflow Options
-----------------------------------

File Options
------------

fsc_mask_fn
  Relative or absolute path and name of the FSC mask.

filter_a_fn
  Relative or absolute path and name of the Fourier filter volume for the first
  half-map. If not using the option do_reweight just leave this set to ""

filter_b_fn
  Relative or absolute path and name of the Fourier filter volume for the second
  half-map. If not using the option do_reweight just leave this set to ""

FSC Options
-----------

pixelsize
  Pixelsize of the half-maps in Angstroms

nfold
  Symmetry to applied the half-maps before calculating FSC (1 is no symmetry)

rand_threshold
  The Fourier pixel at which phase-randomization begins is set automatically to
  the point where the unmasked FSC falls below this threshold.

plot_fsc
  Plot the FSC curves - 1 = yes, 0 = no

Sharpening Options
------------------

do_sharpen
  Set to 1 to sharpen map or 0 to skip and just calculate the FSC

box_gaussian
  To remove some of the edge-artifacts associated with map-sharpening the edges
  of the map can be smoothed with a gaussian. Set to 0 to not smooth the edges,
  otherwise it must be set to an odd number. If an even number is given one will
  be added to the value to make it odd.

filter_mode
  There are two mode used for low pass filtering. The first uses an FSC
  based threshold (mode 1), i.e. after FSC < 0.143, or a pixel-based
  resolution threhsold (mode 2).

filter_threshold
  Set the threshold for the low pass filtering described above. Should be less
  than 1 for FSC based threshold (mode 1), and an integer value for the Fourier
  pixel-based threshold (mode 2).

plot_sharpen
  Plot the sharpening curve - 1 = yes, 0 = no

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

    sum_exec="${exec_dir}/alignment/subtom_parallel_sums"

    avg_exec="${exec_dir}/alignment/subtom_weighted_average"

    fsc_exec="${exec_dir}/analysis/b_factor_by_subsets/subtom_maskcorrected_fsc"

    mem_free="1G"

    mem_max="64G"

    job_name="subTOM"

    array_max="1000"

    max_jobs="4000"

    run_local="0"

    iteration="1"

    num_avg_batch="1"

    all_motl_a_fn_prefix="even/combinedmotl/allmotl"

    all_motl_b_fn_prefix="odd/combinedmotl/allmotl"

    ref_a_fn_prefix="FSC/ref_a"

    ref_b_fn_prefix="FSC/ref_b"

    ptcl_a_fn_prefix="subtomograms/subtomo"

    ptcl_b_fn_prefix="subtomograms/subtomo"

    weight_a_fn_prefix="otherinputs/ampspec"

    weight_b_fn_prefix="otherinputs/ampspec"

    weight_sum_a_fn_prefix="FSC/wei_a"

    weight_sum_b_fn_prefix="FSC/wei_b"

    output_fn_prefix="FSC/ref_auto_b"

    tomo_row="7"

    iclass="0"

    fsc_mask_fn="FSC/fsc_mask.em"

    filter_a_fn=""

    filter_b_fn=""

    pixelsize=1

    nfold=1

    rand_threshold=0.8

    plot_fsc=1

    do_sharpen=1

    box_gaussian=1

    filter_mode=1

    filter_threshold=0.143

    plot_sharpen=1

    do_reweight=0
