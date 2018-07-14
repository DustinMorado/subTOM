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

