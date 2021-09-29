============
Installation
============

The installation of subTOM is relatively straight-forward. subTOM is currently
only built for 64-bit linux computers, with no plans currently to produce builds
for Windows or Mac.

1. ``git clone /net/dstore2/teraraid/dmorado/software/subTOM``
2. ``cd subTOM``
3. ``chmod u+x install.sh``
4. ``./install.sh <INSTALL_DIR> <MCR_DIR>``

Since subTOM is written in Matlab, having a license to use Matlab is preferable,
and makes some tasks simpler, while also allowing for doing your own scripting
with the TOM toolbox. However, the effort has been made to make sure that the
pipeline can run as a whole using only the Matlab Compiler Runtime, which is
freely available software, and can be found here:

`<https://uk.mathworks.com/products/compiler/matlab-runtime.html>`_

subTOM is currently built against the 2021b/v911 MCR so that is the one that you
need to have downloaded and have access to.

At the LMB we have the MCR already installed at
``/lmb/home/public/matlab/jbriggs``, which you can use for your installation.

subTOM is also distributed like most software nowadays as a Git repository, so
if you do not have Git you can find out how to install and use Git here:

`<https://git-scm.com/doc>`_

-------------------------
Step-by-Step Instructions
-------------------------

1. From the directory in which you want to install subTOM clone the repository.

  * ``git clone /net/dstore2/teraraid/dmorado/software/subTOM``

2. Change into the newly created subTOM directory.

  * ``cd subTOM``

3. Make the installation script user-executable, so that you can run it.

  * ``chmod u+x install.sh``

4. Run the install script specifying the installation directory and the
   directory that contains the MCR installation.

  * ``./install.sh <INSTALL_DIR> <MCR_DIR>``

    * *example* ``./install.sh /net/dstore2/teraraid/dmorado/software/subTOM
      /lmb/home/public/matlab/jbriggs``

--------
Building
--------

If you have access to the MATLAB compiler you can also build subTOM from the
source simply following the steps here, beginning in the subTOM installation
directory:

1. ``cd src``
2. Edit ``subtom_mcc_build.m`` and change the top three variables to point
   correctly at:

   * The subTOM source directory
   * The root folder of the TOM Toolbox
   * The path to the MATLAB Toolbox directory
     * The Statistics and Machine Learning Toolbox is needed for
     :doc:`classification/general/functions/subtom_cluster`

3. Run ``subtom_mcc_build.m`` in MATLAB and it should correctly compile all
   neccessary functions and place them in the correct locations.
4. If you run into an issue with a MEX-function in TOM toolbox (such as
   tom_rotate), then you can recompile such a function with the command ``mex
   -R2018a <filename>`` and then recompile subTOM.

