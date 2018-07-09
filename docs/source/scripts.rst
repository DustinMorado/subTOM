=======
Scripts
=======

Scripts are the main point of user-interaction with the processing pipeline. As
such care has been taken to make sure that the scripts are well commented and
that the user-defined options are well separated from the actual *black-box*
level processing further down in the code.

Each script is a simple BASH file that generally calls some piece of code from
either IMOD or a subTOM Matlab function. The scripts are meant to be first
edited, filling in the necessary information and then executed in the terminal.
Matlab is not necessary to run the scripts, just the Matlab Compiler Runtime,
which should have been taken care of in the installation.

-----------------------------------------
Links to Individual Script Documentation:
-----------------------------------------

* :doc:`preprocess`: Aligns dose-fractionated data, sorts and stacks aligned
  frames, determines the defocus of the tilt-series using CTFFIND4 and then
  dose-filters the tilt-series in prepartion for alignment using IMOD/eTomo
* :doc:`seed_positions`: Takes the motive lists made from clicker files in
  UCSF Chimera and places a number of points at a given spacing along spherical
  or tubular surfaces.

