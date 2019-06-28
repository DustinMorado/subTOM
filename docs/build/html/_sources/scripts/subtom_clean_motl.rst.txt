=================
subtom_clean_motl
=================

Cleans a given MOTL file based on distance and/or CC scores.

This MOTL manipulation script uses one MATLAB compiled scripts below:

- :doc:`../functions/subtom_clean_motl`

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

clean_motl_exec
  Clean MOTLs executable

File Options
------------

input_motl_fn
  Relative path and name of the input MOTL file to be cleaned.

output_motl_fn
  Relative path and name of the output MOTL file.

output_stats_fn
  Relative path and name of the optional output cleaning stats CSV file. If you
  do not want to write out the differences just leave this as "".
  
  The CSV format of the output statistics file for cleaning is a single row with
  the following columns:

+---------------------------+--------------------------------------------------+
| Column                    | Value                                            |
+===========================+==================================================+
| 1                         | Total Initial Number of Particles                |
+---------------------------+--------------------------------------------------+
| 2                         | Number of Particles Removed  in Edge Cleaning    |
+---------------------------+--------------------------------------------------+
| 3                         | Number of Particles Removed in Cluster Cleaning  |
+---------------------------+--------------------------------------------------+
| 4                         | Number of Particles Removed in Distance Cleaning |
+---------------------------+--------------------------------------------------+
| 5                         | Number of Particles Removed in CC Cleaning       |
+---------------------------+--------------------------------------------------+
| 6                         | Total Remaining Number of Particles              |
+---------------------------+--------------------------------------------------+

Clean Options
-------------

tomo_row
  Which row in the motl file contains the correct tomogram number.
  Usually row 5 and 7 both correspond to the correct value and can be used
  interchangeably, but there are instances when 5 contains a sequential ordered
  value starting from 1, while 7 contains the correct corresponding tomogram.

do_ccclean
  If the following is set to 1 then the MOTL will be cleaned by CCC either by
  CCC value or a fraction of the highest CCC values to keep. If it is set to 0
  then CCC cleaning will be skipped.

cc_fraction
  If cleaning by CC then after edge, cluster, and distance cleaning, if any are
  selected, is completed. The MOTL will be sorted by CCC and then the top
  fraction as specified here will be kept with the rest discarded. For example
  if cc_fraction=0.7 the top 70% of the clean data will be kept and the bottom
  30% of the cleaned data will be discarded. A value of 1 here means that data
  is not cleaned by CCC fraction.

cc_cutoff
  If cc_fraction is 1 and therefore not used then particles with a CCC below
  this cutoff will be removed from the output MOTL file. Values must be within
  -1 to 1, with -1 not removing any particles.

do_distance
  If the following is set to 1 then the MOTL will be cleaned by distance. If it
  is set to 0 distance cleaning will be skipped.

distance_cutoff
  Particles that are less than this distance in pixels from another particle
  will be cleaned with the particle with the highest CCC kept while the others
  are removed from the output MOTL file.

do_cluster
  If the following is set to 1 then the MOTL will be cleaned by a clustering
  criteria that enforces kept particles to exist as clusters. This can be useful
  when there is no lattice and clusters of particles makes a good indication
  that a true copy of the reference exists there. If it is set to 0 cluster
  cleaning will be skipped.

cluster_distance
  The following determines the radius that defines what is considered a cluster
  in cluster cleaning.

cluster_size
  The cluster size specifies how many particles must be found within
  cluster_distance for the particle to be considered part of a cluster. The
  particle with the highest CCC in the cluster will be selected as the
  representative particle for the cluster and the remaining clustered points
  will be removed.

do_edge
  If the following is set to 1 then the MOTL will be edge cleaned considering
  the dimensions of the tomogram in which the particles are contained. If any
  part of the particle exists outside of the tomogram it will be removed from
  the MOTL. If it is set to 0 edge cleaning will be skipped.

tomogram_dir
  Absolute path to the folder where the tomograms are stored. If you are not
  edge cleaning leave this set to "".

boxsize
  What is the boxsize of the particle that will be extracted from the tomogram,
  which is necessary to specify to be able to edge clean.

write_stats
  If the following is 1 then the details of how many particles were cleaned in
  each stage will be written out, if 0 then not.

-------
Example
-------

.. code-block:: bash

    scratch_dir="${PWD}"

    mcr_cache_dir="${scratch_dir}/mcr"

    exec_dir="/net/dstore2/teraraid/dmorado/software/subTOM/bin"

    clean_motl_exec="${exec_dir}/MOTL/subtom_clean_motl"

    input_motl_fn="combinedmotl/allmotl_2.em"

    output_motl_fn="combinedmotl/allmotl_cc0.1_dist4_cluster2d10_2.em"

    output_stats_fn="combinedmotl/allmotl_cc0.1_dist4_cluster2d10_stats.csv"

    tomo_row=7

    do_ccclean=1

    cc_fraction=1

    cc_cutoff=0.1

    do_distance=1

    distance_cutoff=4

    do_cluster=1

    cluster_distance=10

    cluster_size=2

    do_edge=1

    tomogram_dir="/net/dstore2/teraraid/dmorado/subTOM_tutorial/data/tomos/bin8"

    boxsize=36

    write_stats=1
