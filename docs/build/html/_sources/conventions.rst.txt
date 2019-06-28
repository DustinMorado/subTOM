===========
Conventions
===========

-------------
Preprocessing
-------------

Preprocessing is done for dose-fractionated data that comes from detectors that
collect movie tilt-images. Preprocessing is done with several programs from
various sources.

* **Beam-induced Motion Correction**

  * The command ``alignframes`` `alignframes man page
    <https://bio3d.colorado.edu/imod/betaDoc/man/alignframes.html>`_ which is a
    part of the `IMOD`_ package is used to do the beam-induced motion correction
    of the movies. subTOM assumes that the data is collected with `SerialEM`_
    but the program should support MRC and TIFF format movie-frames collected
    with other programs as well. However this requires you to have your movies
    to have the following name-scheme:

    - ``<BASENAME>_<FRAME_IDX>_<ANGLE>.<mrc|tif>``

      + Where ``<BASENAME>`` is your own filename identifier *e.g. TS_01*
      + Where ``<FRAME_IDX>`` is a three digit identifier of the movie that
        describes the order the data was collected in *e.g. 000-040*
      + Where ``<ANGLE>`` is the tilt-angle at which the movie was collected at
        *e.g. 15.0*

* **Defocus Estimation**

  * The programs `CTFFIND4`_, `GCTF`_, and `IMOD`_'s ``ctfplotter`` `ctfplotter
    man page <https://bio3d.colorado.edu/imod/betaDoc/man/ctfplotter.html>`_
    command can all be used to estimate the defocus in the corrected tilt-series

* **Dose Filtering**

  * The command ``alignframes`` which is part of the `IMOD`_ package is also
    used to do the filtering of movies based on the accumulated dose of each
    tilt-image.

--------------
CTF Correction
--------------

CTF correction is done in 3D using the program `novaCTF`_, and a run script
``run_nova.sh`` is included to facilitate performing novaCTF in parallel and on
an SGE cluster.

----------------
Particle Picking
----------------

Particle picking is done using `UCSF Chimera`_. First users use the built-in
`Volume Tracer`_ utility to create a Marker Set of
points at the center of spherical particles onto which seed positions or a
collection of Marker Sets of points along tubular surfaces onto which seed
positions. The number of Marker Sets used is not important in picking points on
spheres, but in picking points on tubes, each tube should correspond to a single
Marker Set. The collection of Marker Sets should be saved to a single file, one
per tomogram with the name format:

* ``<BASENAME>_<TOMOGRAM_IDX>.cmm``
  
  + Where ``<BASENAME>`` is your own filename identifier *e.g. clicker*.
  + Where ``<TOMOGRAM_IDX>`` is the tomogram number *e.g. 1*.
    
Motive Lists are then generated for the picked objects using the *PickParticle*
plug-in developed in the Briggs' lab by Kun Qu. The format of motive lists is
detailed below, and the motive list is assumed to saved to a single file, one
per tomogram with the name format:

* ``<BASENAME>_<TOMOGRAM_IDX>.em``

-----------------------
Alignment and Averaging
-----------------------

The alignment parameters for a set of data are stored in a MOTive List or
so-called MOTL file, which is a table of 20-fields stored in an EM-format binary
data file. Particles are also extracted into subvolumes in EM-format from
tomograms which are expected to be in MRC-format with the name:

* ``<TOMOGRAM_IDX>.rec`` 

Orientations
============

Coordinate System
-----------------

subTOM uses a right-handed coordinate system where positive rotations are
clockwise looking along the directed axis. The orthogonal axes X, Y, Z are with
the positive Z-axis pointing out of the screen out at the user.

Image Center
------------

Since Matlab uses array-indices that start from 1, unlike most other programming
languages which count from zero, the origin of a subvolume with dimensions,
:math:`NX, NY, NZ` is defined as:

.. math::

  O = (\left\lfloor{NX / 2}\right\rfloor + 1,
       \left\lfloor{NY / 2}\right\rfloor + 1,
       \left\lfloor{NZ / 2}\right\rfloor + 1)

Euler Angle Rotations
---------------------

Rotations in MOTLs describe the best-found rotation of the reference to the
particle in terms of ZXZ Euler angles in degrees. The Euler angle definition in
subTOM is:

* The first rotation *Azimuth* or *psi* (:math:`\psi`) about the Z-axis.
* The second rotation *Zenith* or *theta* (:math:`\theta`) about the new X-axis.
* The final rotaiton *Spin* or *phi* (:math:`\phi`) about the final Z-axis.

This is particularly confusing given that phi and psi generally are swapped in
other software packages, but is kept for historical reasons from the
TOM-toolbox. Therefore care has been taken to use the unambiguous notation
azimuth, zenith, and spin in most of the subTOM code and documentation.

Translations
------------

Translations in MOTLs describe the best-found translation of the reference to
the particle in pixels with respect to the subvolume origin. This translation
occurs after the rotation of the reference about the subvolume origin.

-------------------------
Motive List Specification
-------------------------

+--------------------------------------+---------------------------------------+
| Field                                | Contents                              |
+======================================+=======================================+
| 1                                    | Cross-Correlation Coefficient         |
+--------------------------------------+---------------------------------------+
| 2                                    | Marker Set Used from PickParticle     |
+--------------------------------------+---------------------------------------+
| 3                                    | Radius of tube/sphere in PickParticle |
+--------------------------------------+---------------------------------------+
| 4                                    | Particle Number (Running count from 1)|
+--------------------------------------+---------------------------------------+
| 5                                    | Tomogram Number (Running count from 1)|
+--------------------------------------+---------------------------------------+
| 6                                    | PickParticle Object Number (Running)  |
+--------------------------------------+---------------------------------------+
| 7                                    | Tomogram Number (From Filename)       |
+--------------------------------------+---------------------------------------+
| 8                                    | X-coordinate in Tomogram (Integer)    |
+--------------------------------------+---------------------------------------+
| 9                                    | Y-coordinate in Tomogram (Integer)    |
+--------------------------------------+---------------------------------------+
| 10                                   | Z-coordinate in Tomogram (Integer)    |
+--------------------------------------+---------------------------------------+
| 11                                   | X-translation AFTER rotation of Ref.  |
+--------------------------------------+---------------------------------------+
| 12                                   | Y-translation AFTER rotation of Ref.  |
+--------------------------------------+---------------------------------------+
| 13                                   | Z-translation AFTER rotation of Ref.  |
+--------------------------------------+---------------------------------------+
| 14                                   | Not Used (X-shift BEFORE rotation)    |
+--------------------------------------+---------------------------------------+
| 15                                   | Not Used (Y-shift BEFORE rotation)    |
+--------------------------------------+---------------------------------------+
| 16                                   | Not Used (Z-shift BEFORE rotation)    |
+--------------------------------------+---------------------------------------+
| 17                                   | Spin Rotation of Ref. in Degrees      |
+--------------------------------------+---------------------------------------+
| 18                                   | Azimuth Rotation of Ref. in Degrees   |
+--------------------------------------+---------------------------------------+
| 19                                   | Zenith Rotation of Ref. in Degrees    |
+--------------------------------------+---------------------------------------+
| 20                                   | Class Number                          |
+--------------------------------------+---------------------------------------+

Class Number
============

The class number field acts as a field for classification, but also
thresholding. Historically:

* Particles that have class number 1 are always aligned and included in the
  final average.
* Particles that have class number 2 are always aligned but are not included in
  the final average.
* Particles that have class number :math:`\leq 0` are not aligned nor included
  in the final average.

Remaining class numbers :math:`\gt 2` can be used in classification to identify
homogeneous subsets within a heterogeneous dataset.

.. _IMOD: http://bio3d.colorado.edu/imod/
.. _SerialEM: http://bio3d.colorado.edu/SerialEM/
.. _CTFFIND4: http://grigoriefflab.janelia.org/ctffind4
.. _novaCTF: https://github.com/turonova/novaCTF
.. _UCSF Chimera: https://www.cgl.ucsf.edu/chimera/
.. _Volume Tracer: https://www.cgl.ucsf.edu/chimera/docs/ContributedSoftware/volumepathtracer/framevolpath.html
.. _GCTF: https://www.mrc-lmb.cam.ac.uk/kzhang/Gctf
