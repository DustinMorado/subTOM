#!/bin/bash
set -e           # Crash on error
set -o nounset   # Crash on unset variables

## lmb_PCA_classification.sh
# Derived from lsf_PCA_classification.sh by William Wan.
# Converted for use with the LMB SGE cluster.
# will_lsf_prepare_ccmatrix.m had to be changed to use SGE syntax,
# but otherwise the only other changes I made were to the job submission
# commands here and recompiling Will's MATLAB code to use the r2016b MCR.
# AT 07-2017
#
# A script for performing PCA classification on a dataset. Most steps
# are performed on the cluster, but the PCA step can be performed locally,
# as this is not parallelizable. The PCA classification method is 
# essentially that found in dynamo.
#
# To run parts of the script locally, run local_dummy.sh in the local folder.
#
# NOTE: xmatrix files are NOT deleted. They can take up quite a bit of space
# so delete them as necessary.
#
# WW 09-2016

##### INPUTS #####

### Folder Options ###
scratch_dir='/net/nfs6/nfs6/briggsgrp/atan/temp/lmb_pcatest/bin4_pca1_20170628/'     # Root folder on the scratch
local_dir='/net/bstore1/bstore1/briggsgrp/atan/temp/lmb_pcatest/bin4_pca1_20170628/'       # Folder on group shares
mcrcachedir='mcr/'     # MRC directory for each job

### File Options ###
ind=1                                                       # Index of iteration to use.
allmotlname='./combinedmotl/allmotl-subsetforpca'                 # Relative path and name of allmotl file. Give it the complete file name.
wedgelistname='./otherinputs/wedgelist.em'                  # Relative path and name of wedgelist.
wedgemaskname='none'                                        # Relative path and name of non-binary wedgemask. Set to 'none' to use standard binary mask.
tomonum=7                                                   # Row number for tomogram number.
subtomoname='./subtomograms/subtomo'                        # Relative path and name of subtomograms.
maskname='./otherinputs/pcamask_hexneig_sph_r20_h20.em'                      # Relative path and name of classification mask. Setting to 'none' results in the use of a spherical mask.
temp_folder='./pca/'                                        # Folder for temporary files. There are deleted after the calculations are over.


### CC-matrix Calculation ###
calculate_ccmatrix=1                    # Calculate CC-matrix. 1 = yes, 0 = no.
n_cores_ccmatrix=500                   # Number of cores to use for CC-matrix calculations. KEEP THIS LIMITED IF RUNNING FROM GROUPSHARES
lowpass=13                              # Low pass filter in Fourier pixels
lpsigma=3                               # Low pass filter dropoff in Fourier pixels
hipass=1                                # High pass filter in Fourier pixels
hpsigma=2                               # High pass filter dropoff in Fourier pixels
ccmatrixname='./pca/ccmatrix'           # Relative path and name of CC-matrix. Give it the complete file name.


### PCA Classification ###
calculate_pca=1                         # Calculate PCA classification of CC-matrix
local_pca=0                             # Calculate locally or on cluster. 1 = locally, 0 = cluster.
eigenvectorname='./pca/eigenvectors'    # Relative path and name of eigenvectors from PCA classification.
n_eigs=30                               # Number of eigenvectors to calculate.

### Xmatrix Calculation ###
calculate_xmatrix=1                     # Calculate xmatrix. 
fullxmatrix=1                           # Calculate a full volume or just the masked area. 1 = full, 0 = masked area.
n_cores_xmatrix=300                     # Number of cores to use for xmatrix calculation, eigenvolume calculation, and eigencoefficient calculation.
xmatrixname='./pca/xmatrix'             # Relative path and name of xmatrix blocks.


### Eigenvolume Calculation ###
calculate_eigenvolumes=1                # Calculate eigenvolumes from xmatrix.
eigenvolumename='./pca/eigenvolume'     # Relative path and name of eigenvolumes. Filenames are eigenvolumes_eigenum_iteration.em.


### Eigencoefficients Calculation ###
calculate_eigencoeff=1                  # Calculate eigencoefficients from xmatrix and eigenvolumes.
eigencoeffname='./pca/eigencoeff'       # Relative path and name of eigencoefficients.

### K-means Calculation ###
calculate_kmeans=1                                         # Calculate k-means clustering from eigencoefficients.
replicates=10                                              # Number of independent k-means clustering runs. Due to the random starting positions, it's best to run a few.
n_clusters=10                                               # Number of clusters to classify into.
vectors='[7,8,13,14,15,16,17,18,19,20,21,22,23]'                                            # Numbers of the eigenvectors to use for k-means classification. Input as a MATLAB-style vector.
newallmotlname='./combinedmotl/allmotl-pcaclassified'        # Relative path and name of classified allmotl file.

### Parallelization Options ###
#queue='medium_priority'     # Cluster queue
#memlimit=2048               # If you use more than this, you will be kicked out
#memusage=2048               # The amount of memory to reserve
#memneed=2560                # The amount of memory the node should have available
memfree='2G'                 # The amount of memory your job requires
memmax='3G'                 # The upper bound on the amount of memory your job is allowed to use


### Checkjob options ###
check_ccmatrix_paral='./checkjobs/check_ccmatrix_parallel'
check_ccmatrix_final='./checkjobs/check_ccmatrix_final'
check_pca='./checkjobs/check_pca'
check_paral_xmatrix='./checkjobs/check_xmatrix'
check_paral_eigenvol='./checkjobs/check_paral_eigenvol'
check_final_eigenvol='./checkjobs/check_final_eigenvol'
check_paral_eigencoeff='./checkjobs/check_paral_eigencoeff'
check_final_eigencoeff='./checkjobs/check_final_eigencoeff'
check_paral_kmeans='./checkjobs/check_paral_kmeans'
check_final_kmeans='./checkjobs/check_final_kmeans'

##### COMPLETION DIRECTORY #####
compdir='complete/' 		### A completion file will be written out after each step, so this script can be re-run after a crash and figure out where to start from.




###############################################################################################

##### INITIALIZE BLANK FOLDER #####
rm -rf ${scratch_dir}/blank
mkdir ${scratch_dir}/blank

noemail='no'
errorfile='error.log'





################################################################################################################################################################
### CC-MATRIX CALCULATION
################################################################################################################################################################
if [ $calculate_ccmatrix -eq 1 ]; then

    ############# PREPARE FOR CC-MATRIX CALCULATION	 #############
    if [ ! -f $compdir/prep_cc_matrix ]; then


	    echo "#!/bin/bash" >> prepare_ccmatrix
            echo "#$ -cwd" >> prepare_ccmatrix
            echo "#$ -S /bin/bash" >> prepare_ccmatrix
            #echo "#$ -V" >> prepare_ccmatrix
	    echo 'echo $HOSTNAME' >> prepare_ccmatrix
	    echo 'set +o noclobber' >> prepare_ccmatrix
	    echo 'set -e' >> prepare_ccmatrix
	    echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> prepare_ccmatrix
	    #echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> prepare_ccmatrix
	    echo "cd $scratch_dir" >> prepare_ccmatrix
	    echo "rm -rf $scratch_dir${mcrcachedir}/prepare_ccmatrix/" >> prepare_ccmatrix
	    echo "mkdir $scratch_dir${mcrcachedir}/prepare_ccmatrix/" >> prepare_ccmatrix
	    echo export MCR_CACHE_ROOT="$scratch_dir${mcrcachedir}/prepare_ccmatrix/" >> prepare_ccmatrix
      	echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/ccmatrix/will_lsf_prepare_ccmatrix_sge $allmotlname $ccmatrixname $ind $wedgelistname $wedgemaskname $tomonum $subtomoname $maskname $lowpass $lpsigma $hipass $hpsigma $memfree $memmax $n_cores_ccmatrix $temp_folder $check_ccmatrix_paral" >> prepare_ccmatrix
	    echo "rm -rf $scratch_dir${mcrcachedir}/prepare_ccmatrix/" >> prepare_ccmatrix
	    echo 'exit' >> prepare_ccmatrix
	    chmod +x prepare_ccmatrix


	    ##### SEND OUT JOB ##########################
	    #bsub -M ${memlimit} -R "select[mem > ${memneed}]" -R "rusage[mem=${memusage}]" -q $queue -o log_prepare_ccmatrix -e error_prepare_ccmatrix $scratch_dir/prepare_ccmatrix
	    qsub -cwd -N prepare_ccmatrix -l mem_free=${memfree},h_vmem=${memmax} -o log_prepare_ccmatrix -e error_prepare_ccmatrix $scratch_dir/prepare_ccmatrix
	    echo "Preparing to calculate a CC-matrix!"

	    # Reset counter
	    check_prep=0

	    while [ $check_prep -lt 1 ]; do
		    sleep 10s
            check_prep=$(ls submit_calculate_ccmatrix 2>/dev/null | wc -l)
		    echo "     ...still preparing to calculate the CC-matrix..."
	
	    done
        
        echo "GIRD YOUR LOINS! I AM READY!!!"

	    ### Write out completion file
	    touch $compdir/prep_cc_matrix
    fi


    ############# PARALLEL CC-MATRIX CALCULATION	 #############
    if [ ! -f $compdir/paral_cc_matrix ]; then


	    ##### SEND OUT JOB ##########################
        ./submit_calculate_ccmatrix
	    echo "Parallel CC-matrix calculation submitted!!!"

	    # Reset counter
	    check_paral=0

	    while [ $check_paral -lt $n_cores_ccmatrix ]; do
		    sleep 10s
		    check_paral=$(( $(ls -1 -f ./checkjobs/ | wc -l) - 2 ))
            echo "Calculated $check_paral segments out of $n_cores_ccmatrix"
        done
        
        echo "Parallel CC-matrix calculation complete!!!"

	    ### Write out completion file
	    touch $compdir/paral_cc_matrix

        ### Clear checkjobs
        rsync -a --delete ${scratch_dir}/blank/ ${scratch_dir}/checkjobs/
        rm -f calculate_ccmatrix_*
        rm -f submit_calculate_ccmatrix prepare_ccmatrix
    fi


    ############# FINAL AVERAGE	 #############
    if [ ! -f $compdir/final_cc_matrix ]; then


	    rm -f ccmatrix_Final

	    echo "#!/bin/bash" > ccmatrix_Final
            echo "#$ -S /bin/bash" >> ccmatrix_Final
	    echo 'set +o noclobber' >> ccmatrix_Final
	    echo 'set -e' >> ccmatrix_Final
	    echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> ccmatrix_Final
	    echo "cd $scratch_dir" >> ccmatrix_Final
	    echo "rm -rf $scratch_dir${mcrcachedir}/ccmatrix_Final/" >> ccmatrix_Final
	    echo "mkdir $scratch_dir${mcrcachedir}/ccmatrix_Final/" >> ccmatrix_Final
	    echo export MCR_CACHE_ROOT="$scratch_dir${mcrcachedir}//ccmatrix_Final/" >> ccmatrix_Final
	    echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/ccmatrix/will_lsf_final_ccmatrix $ccmatrixname $ind $n_cores_ccmatrix $check_ccmatrix_final" >> ccmatrix_Final
	    echo "rm -rf $scratch_dir${mcrcachedir}/ccmatrix_Final/" >> ccmatrix_Final
	    echo 'exit' >> ccmatrix_Final
	    chmod +x ccmatrix_Final


	    qsub -cwd -N ccmatrix_Final -l mem_free=${memfree},h_vmem=${memmax} -o log_ccmatrix_Final -e error_ccmatrix_Final ./ccmatrix_Final
            #bsub -M ${memlimit} -R "select[mem > ${memneed}]" -R "rusage[mem=${memusage}]" -q $queue -o log_ccmatrix_Final -e error_ccmatrix_Final ./ccmatrix_Final

	    echo "Waiting for the final CC-matrix..."
	
	    ## Reset counter
	    check_final=0

	    while [ $check_final -lt 1 ]; do
		    sleep 10s
		    check_final=$(( $(ls -1 -f ./checkjobs/ | wc -l) - 2 ))
        done

	    ### Write out completion file
	    touch $compdir/final_cc_matrix

        ### Copy file to group share
        cp ${scratch_dir}${ccmatrixname}_${ind}.em ${local_dir}${ccmatrixname}_${ind}.em

        ### Cleanup ### 
        rm -f $check_ccmatrix_final
        rm -f ccmatrix_Final
        rm -f ${ccmatrixname}_${ind}_*.em
        rm -f ${temp_folder}/job_array_*.em

    fi
    echo "CC-MATRIX CALCULATION COMPLETE"

fi

################################################################################################################################################################
### PCA CALCULATION
###############################################################################################################################################################
if [ $calculate_pca -eq 1 ]; then

    ############# PCA CALCULATION	 #############
    if [ ! -f $compdir/pca_calc ]; then

        # Calculate on cluster
        if [ $local_pca != 1 ]; then
	        echo "#!/bin/bash" > calculate_PCA
                echo "#$ -S /bin/bash" >> calculate_PCA
	        echo 'echo $HOSTNAME' >> calculate_PCA
	        echo 'set +o noclobber' >> calculate_PCA
	        echo 'set -e' >> calculate_PCA
	        echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> calculate_PCA
	        echo "cd $scratch_dir" >> calculate_PCA
	        echo "rm -rf $scratch_dir${mcrcachedir}/calculate_PCA/" >> calculate_PCA
	        echo "mkdir $scratch_dir${mcrcachedir}/calculate_PCA/" >> calculate_PCA
	        echo export MCR_CACHE_ROOT="$scratch_dir${mcrcachedir}/calculate_PCA/" >> calculate_PCA
          	echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/pca/will_pca_ccmatrix_function $ccmatrixname $ind $n_eigs $eigenvectorname $check_pca" >> calculate_PCA
	        echo "rm -rf $scratch_dir${mcrcachedir}/calculate_PCA/" >> calculate_PCA
	        echo 'exit' >> calculate_PCA
	        chmod +x calculate_PCA


	        ##### SEND OUT JOB ##########################
	        qsub -cwd -N calculate_PCA -l mem_free=${memfree},h_vmem=${memmax} -o log_calculate_PCA -e error_calculate_PCA $scratch_dir/calculate_PCA
	        #bsub -M ${memlimit} -R "select[mem > ${memneed}]" -R "rusage[mem=${memusage}]" -q $queue -o log_calculate_PCA -e error_calculate_PCA $scratch_dir/calculate_PCA
	        echo "Calculating PCA on the cluster!"

	        # Reset counter
	        check=0

	        while [ $check -lt 1 ]; do
		        sleep 10s
       	        check=$(( $(ls -1 -f ./checkjobs/ | wc -l) - 2 ))
		        echo "     ...still calculating PCA ..."
	
	        done
            
            echo "PCA Calculated!!!"

            ### Copy files ###
            cp ${scratch_dir}/${eigenvectorname}_${ind}.em ${local_dir}/${eigenvectorname}_${ind}.em 

            ### Cleanup ###
            rm -rf checkjobs/*
            rm -f calculate_PCA

	        ### Write out completion file
	        touch $compdir/pca_calc


        # Calculate via local_dummy.sh
        else    

	        echo "#!/bin/bash" > ${local_dir}/calculate_PCA
                echo "#$ -S /bin/bash" >> ${local_dir}/calculate_PCA
	        echo 'echo $HOSTNAME' >> ${local_dir}/calculate_PCA
	        echo 'set +o noclobber' >> ${local_dir}/calculate_PCA
	        echo 'set -e' >> ${local_dir}/calculate_PCA
	        echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> ${local_dir}/calculate_PCA
            echo "cd ${local_dir}/" >> ${local_dir}/calculate_PCA
	        echo "rm -rf ${local_dir}${mcrcachedir}/calculate_PCA/" >> ${local_dir}/calculate_PCA
	        echo "rm -rf ${local_dir}/checkjobs/" >> ${local_dir}/calculate_PCA	        
            echo "mkdir checkjobs" >> ${local_dir}/calculate_PCA
	        echo "mkdir -p ${local_dir}/${mcrcachedir}/calculate_PCA/" >> ${local_dir}/calculate_PCA
	        echo export MCR_CACHE_ROOT="${local_dir}${mcrcachedir}/calculate_PCA/" >> ${local_dir}/calculate_PCA
          	echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/pca/will_pca_ccmatrix_function $ccmatrixname $ind $n_eigs $eigenvectorname $check_pca" >> ${local_dir}/calculate_PCA
	        echo "rm -rf ${local_dir}/${mcrcachedir}/calculate_PCA/" >> ${local_dir}/calculate_PCA
	        echo 'exit' >> ${local_dir}/calculate_PCA
	        chmod +x ${local_dir}/calculate_PCA

            ##### SEND OUT JOB ##########################
	        mv ${local_dir}/calculate_PCA ${local_dir}/dummy_command
	        echo "Calculating PCA locally!"

	        # Reset counter
	        check=0

	        while [ $check -lt 1 ]; do
		        sleep 10s
       	        check=$(( $(ls -1 -f ${local_dir}/checkjobs/ | wc -l) - 2 ))
		        echo "     ...still calculating PCA ..."
	
	        done
            
            

            ### Copy files ###
            cp ${local_dir}/${eigenvectorname}_${ind}.em ${scratch_dir}/${eigenvectorname}_${ind}.em 

            ### Cleanup ###
            rm -f ${local_dir}/checkjobs/*
            rm -f ${local_dir}/calculate_PCA

	        ### Write out completion file
	        touch $compdir/pca_calc

        fi
    fi
    
    echo "PCA Calculated!!!"
fi


################################################################################################################################################################
### XMATRIX CALCULATION
################################################################################################################################################################
if [ $calculate_xmatrix -eq 1 ]; then
    if [ ! -f $compdir/paral_xmatrix ]; then

	    ### Initialize parallel job number
	    d=1

	    ### Loop to generate parallel scripts
	    while [ $d -le $n_cores_xmatrix ]; do

		    procnum=$d
		    echo "#!/bin/bash" > parallel_xmatrix_$procnum
                    echo "#$ -S /bin/bash" >> parallel_xmatrix_$procnum
		    echo 'echo $HOSTNAME' >> parallel_xmatrix_$procnum
		    echo 'set +o noclobber' >> parallel_xmatrix_$procnum
		    echo 'set -e' >> parallel_xmatrix_$procnum
		    echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> parallel_xmatrix_$procnum
		    echo "cd $scratch_dir" >> parallel_xmatrix_$procnum
		    echo "rm -rf $scratch_dir${mcrcachedir}/parallel_xmatrix_$procnum/" >> parallel_xmatrix_$procnum
		    echo "mkdir $scratch_dir${mcrcachedir}/parallel_xmatrix_$procnum/" >> parallel_xmatrix_$procnum
		    echo export MCR_CACHE_ROOT="$scratch_dir${mcrcachedir}/parallel_xmatrix_$procnum/" >> parallel_xmatrix_$procnum
	      	echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/xmatrix/will_lsf_xmatrix_parallel $allmotlname $xmatrixname $fullxmatrix $ind $maskname $subtomoname $n_cores_xmatrix $procnum $check_paral_xmatrix" >> parallel_xmatrix_$procnum
		    echo "rm -rf $scratch_dir${mcrcachedir}/parallel_xmatrix_$procnum/" >> parallel_xmatrix_$procnum
		    echo 'exit' >> parallel_xmatrix_$procnum
		    chmod +x parallel_xmatrix_$procnum

		    ((d++))

	    done
        
        ((d--))

	    rm -f parallel_xmatrix_array
	    touch parallel_xmatrix_array

            #echo "#BSUB -J [1-$d]" >> parallel_xmatrix_array
            #echo "#BSUB -q $queue" >> parallel_xmatrix_array
            #echo "${scratch_dir}/parallel_xmatrix_"\$\{LSB_JOBINDEX\} >> parallel_xmatrix_array
            echo "#!/bin/bash" >> parallel_xmatrix_array
            echo "#$ -S /bin/bash" >> parallel_xmatrix_array
	    echo "#$ -t 1-$d" >> parallel_xmatrix_array
	    echo "#$ -cwd" >> parallel_xmatrix_array
	    echo "${scratch_dir}/parallel_xmatrix_"\$\{SGE_TASK_ID\} >> parallel_xmatrix_array


	    ##### SEND OUT JOB ##########################
	    chmod +x parallel_xmatrix_array
	    qsub -N parallel_xmatrix -l mem_free=${memfree},h_vmem=${memmax} -o log_parallel_xmatrix -e error_parallel_xmatrix ./parallel_xmatrix_array
	    #bsub -J "${scratch_dir}/parallel_xmatrix_[1-$d]" -M ${memlimit} -R "select[mem > ${memneed}]" -R "rusage[mem=${memusage}]" -q $queue -o log_parallel_xmatrix -e error_parallel_xmatrix ./parallel_xmatrix_array
	    echo "Parallel xmatrix calculation submitted"

	    # Reset counter
	    check_paral=0

	    while [ $check_paral -lt $n_cores_xmatrix ]; do
		    sleep 10s

		    check_paral=$(( $(ls -1 -f ./checkjobs/ | wc -l) - 2 ))
		    echo "Done $check_paral parallel xmatrix calculations out of $n_cores_xmatrix"
	
	    done


	    ### Write out completion file
	    touch $compdir/paral_xmatrix
    fi
    echo "DONE PARALLEL XMATRIX CALCULATIONS!!!!"

    ### Remove scripts
    rm -f parallel_xmatrix_*

    ### Clear checkjobs folder
    rsync -a --delete ${scratch_dir}/blank/ ${scratch_dir}/checkjobs/
fi




################################################################################################################################################################
### EIGENVOLUME CALCULATION
################################################################################################################################################################
if [ $calculate_eigenvolumes -eq 1 ]; then

    if [ ! -f $compdir/paral_eigenvolume ]; then

	    ### Initialize parallel job number
	    d=1

	    ### Loop to generate parallel scripts
	    while [ $d -le $n_cores_xmatrix ]; do

		    procnum=$d
		    echo "#!/bin/bash" > parallel_eigenvolume_$procnum
                    echo "#$ -S /bin/bash" >> parallel_eigenvolume_$procnum
		    echo 'echo $HOSTNAME' >> parallel_eigenvolume_$procnum
		    echo 'set +o noclobber' >> parallel_eigenvolume_$procnum
		    echo 'set -e' >> parallel_eigenvolume_$procnum
		    echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> parallel_eigenvolume_$procnum
		    echo "cd $scratch_dir" >> parallel_eigenvolume_$procnum
		    echo "rm -rf $scratch_dir${mcrcachedir}/parallel_eigenvolume_$procnum/" >> parallel_eigenvolume_$procnum
		    echo "mkdir $scratch_dir${mcrcachedir}/parallel_eigenvolume_$procnum/" >> parallel_eigenvolume_$procnum
		    echo export MCR_CACHE_ROOT="$scratch_dir${mcrcachedir}/parallel_eigenvolume_$procnum/" >> parallel_eigenvolume_$procnum
	      	echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/eigenvol/will_lsf_parallel_eigenvol2 $allmotlname $eigenvectorname $xmatrixname $eigenvolumename $ind $subtomoname $temp_folder $wedgelistname $wedgemaskname $tomonum $n_cores_xmatrix $procnum $check_paral_eigenvol" >> parallel_eigenvolume_$procnum
		    echo "rm -rf $scratch_dir${mcrcachedir}/parallel_eigenvolume_$procnum/" >> parallel_eigenvolume_$procnum
		    echo 'exit' >> parallel_eigenvolume_$procnum
		    chmod +x parallel_eigenvolume_$procnum

		    ((d++))

	    done
        
        ((d--))

	    rm -f parallel_eigenvolume_array
	    touch parallel_eigenvolume_array
	    #echo "#BSUB -J [1-$d]" >> parallel_eigenvolume_array
            #echo "#BSUB -q $queue" >> parallel_eigenvolume_array
            echo "#!/bin/bash" >> parallel_eigenvolume_array
            echo "#$ -S /bin/bash" >> parallel_eigenvolume_array
            echo "#$ -t 1-$d" >> parallel_eigenvolume_array
	    echo "#$ -cwd" >> parallel_eigenvolume_array
	    echo "${scratch_dir}/parallel_eigenvolume_"\$\{SGE_TASK_ID\} >> parallel_eigenvolume_array


	    ##### SEND OUT JOB ##########################
	    chmod +x parallel_eigenvolume_array
	    qsub -N parallel_eigenvolume -l mem_free=${memfree},h_vmem=${memmax} -o log_parallel_eigenvol -e error_parallel_eigenvol ./parallel_eigenvolume_array
	    #bsub -J "${scratch_dir}/parallel_eigenvolume_[1-$d]" -M ${memlimit} -R "select[mem > ${memneed}]" -R "rusage[mem=${memusage}]" -q $queue -o log_parallel_eigenvol -e error_parallel_eigenvol ./parallel_eigenvolume_array
	    echo "Parallel eigenvolume calculation submitted"

	    # Reset counter
	    check_paral=0

	    while [ $check_paral -lt $n_cores_xmatrix ]; do
		    sleep 10s

		    check_paral=$(( $(ls -1 -f ./checkjobs/ | wc -l) - 2 ))
		    echo "Done $check_paral parallel eigenvolume calculations out of $n_cores_xmatrix"
	
	    done


	    ### Write out completion file
	    touch $compdir/paral_eigenvolume
    fi
    echo "DONE PARALLEL EIGENVOLUME CALCULATIONS!!!!"

    ### Remove scripts
    rm -f parallel_eigenvolume_*

    ### Clear checkjobs folder
    rsync -a --delete ${scratch_dir}/blank/ ${scratch_dir}/checkjobs/




    if [ ! -f $compdir/final_eigenvol ]; then


	    rm -f eigenvolume_Final

	    echo "#!/bin/bash" > eigenvolume_Final
            echo "#$ -S /bin/bash" >> eigenvolume_Final
	    echo 'set +o noclobber' >> eigenvolume_Final
	    echo 'set -e' >> eigenvolume_Final
	    echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> eigenvolume_Final
	    echo "cd $scratch_dir" >> eigenvolume_Final
	    echo "rm -rf $scratch_dir${mcrcachedir}/eigenvolume_Final/" >> eigenvolume_Final
	    echo "mkdir $scratch_dir${mcrcachedir}/eigenvolume_Final/" >> eigenvolume_Final
	    echo export MCR_CACHE_ROOT="$scratch_dir${mcrcachedir}/eigenvolume_Final/" >> eigenvolume_Final
	    echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/eigenvol/will_lsf_final_eigenvol2 $allmotlname $eigenvolumename $ind $fullxmatrix $maskname $temp_folder $n_cores_xmatrix $check_final_eigenvol" >> eigenvolume_Final
	    echo "rm -rf $scratch_dir${mcrcachedir}/eigenvolume_Final/" >> eigenvolume_Final
	    echo 'exit' >> eigenvolume_Final
	    chmod +x eigenvolume_Final


	    qsub -cwd -N eigenvolume_Final -l mem_free=${memfree},h_vmem=${memmax} -o log_eigenvolume_Final -e error_eigenvolume_Final ./eigenvolume_Final
	    #bsub -M ${memlimit} -R "select[mem > ${memneed}]" -R "rusage[mem=${memusage}]" -q $queue -o log_eigenvolume_Final -e error_eigenvolume_Final ./eigenvolume_Final

	    echo "Waiting for eigenvolumes..."
	
	    ## Reset counter
	    check_final=0

	    while [ $check_final -lt 1 ]; do
		    sleep 10s
		    check_final=$(( $(ls -1 -f ./checkjobs/ | wc -l) - 2 ))
        done

	    ### Write out completion file
	    touch $compdir/final_eigenvol

        ### Copy files to group share
        c=1
        while [ $c -le $n_eigs ]; do
            cp ${scratch_dir}/${eigenvolumename}_${c}_$ind.em ${local_dir}/${eigenvolumename}_${c}_$ind.em 2>/dev/null || :
            ((c++))
        done

        ### Cleanup ### 
        rm -f $check_final_eigenvol
        rm -f eigenvolume_Final
        rm -f ${scratch_dir}/${eigenvolumename}*temp.em
        rm -f ${scratch_dir}/${temp_folder}/wfilt*.em

    fi
    echo "EIGENVOLUME CALCULATION COMPLETE"
fi




################################################################################################################################################################
### EIGENCOEFFICIENTS CALCULATION
################################################################################################################################################################
if [ $calculate_eigencoeff -eq 1 ]; then

    if [ ! -f $compdir/paral_eigencoeff ]; then

        ### Initialize parallel job number
        d=1

        ### Loop to generate parallel scripts
        while [ $d -le $n_cores_xmatrix ]; do

	        procnum=$d
	        echo "#!/bin/bash" > parallel_eigencoeff_$procnum
                echo "#$ -S /bin/bash" >> parallel_eigencoeff_$procnum
	        echo 'echo $HOSTNAME' >> parallel_eigencoeff_$procnum
	        echo 'set +o noclobber' >> parallel_eigencoeff_$procnum
	        echo 'set -e' >> parallel_eigencoeff_$procnum
	        echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> parallel_eigencoeff_$procnum
	        echo "cd $scratch_dir" >> parallel_eigencoeff_$procnum
	        echo "rm -rf $scratch_dir${mcrcachedir}/parallel_eigencoeff_$procnum/" >> parallel_eigencoeff_$procnum
	        echo "mkdir $scratch_dir${mcrcachedir}/parallel_eigencoeff_$procnum/" >> parallel_eigencoeff_$procnum
	        echo export MCR_CACHE_ROOT="$scratch_dir${mcrcachedir}/parallel_eigencoeff_$procnum" >> parallel_eigencoeff_$procnum
          	echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/eigencoeff/will_lsf_parallel_eigencoeff $allmotlname $wedgelistname $wedgemaskname $tomonum $eigenvolumename $n_eigs $ind $xmatrixname $fullxmatrix $maskname $eigencoeffname $n_cores_xmatrix $procnum $check_paral_eigencoeff" >> parallel_eigencoeff_$procnum
	        echo "rm -rf $scratch_dir${mcrcachedir}/parallel_eigencoeff_$procnum/" >> parallel_eigencoeff_$procnum
	        echo 'exit' >> parallel_eigencoeff_$procnum
	        chmod +x parallel_eigencoeff_$procnum

	        ((d++))

        done
        
        ((d--))

        rm -f parallel_eigencoeff_array
        touch parallel_eigencoeff_array
        #echo "#BSUB -J [1-$d]" >> parallel_eigencoeff_array
        #echo "#BSUB -q $queue" >> parallel_eigencoeff_array
        #echo "${scratch_dir}/parallel_eigencoeff_"\$\{LSB_JOBINDEX\} >> parallel_eigencoeff_array
        echo "#!/bin/bash" >> parallel_eigencoeff_array
        echo "#$ -S /bin/bash" >> parallel_eigencoeff_array
        echo "#$ -t 1-$d" >> parallel_eigencoeff_array
        echo "#$ -cwd" >> parallel_eigencoeff_array
        echo "${scratch_dir}/parallel_eigencoeff_"\$\{SGE_TASK_ID\} >> parallel_eigencoeff_array


        ##### SEND OUT JOB ##########################
        chmod +x parallel_eigencoeff_array
        qsub -N parallel_eigencoeff -l mem_free=${memfree},h_vmem=${memmax} -o log_parallel_eigencoeff -e error_parallel_eigencoeff ./parallel_eigencoeff_array
        #bsub -J "${scratch_dir}/parallel_eigencoeff_[1-$d]" -M ${memlimit} -R "select[mem > ${memneed}]" -R "rusage[mem=${memusage}]" -q $queue -o log_parallel_eigencoeff -e error_parallel_eigencoeff ./parallel_eigencoeff_array
        echo "Parallel eigencoefficient calculation submitted"

        # Reset counter
        check_paral=0

        while [ $check_paral -lt $n_cores_xmatrix ]; do
	        sleep 10s

	        check_paral=$(( $(ls -1 -f ./checkjobs/ | wc -l) - 2 ))
	        echo "Done $check_paral parallel eigencoefficient calculations out of $n_cores_xmatrix"

        done


        ### Write out completion file
        touch $compdir/paral_eigencoeff
    fi
    echo "DONE PARALLEL EIGENCOEFFICIENT CALCULATIONS!!!!"

    ### Remove scripts
    rm -f parallel_eigencoeff_*

    ### Clear checkjobs folder
    rsync -a --delete ${scratch_dir}/blank/ ${scratch_dir}/checkjobs/


    if [ ! -f $compdir/final_eigencoeff ]; then


	    rm -f eigencoeff_Final

	    echo "#!/bin/bash" > eigencoeff_Final
            echo "#$ -S /bin/bash" >> eigencoeff_Final
	    echo 'set +o noclobber' >> eigencoeff_Final
	    echo 'set -e' >> eigencoeff_Final
	    echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> eigencoeff_Final
	    echo "cd $scratch_dir" >> eigencoeff_Final
	    echo "rm -rf $scratch_dir${mcrcachedir}/eigencoeff_Final/" >> eigencoeff_Final
	    echo "mkdir $scratch_dir${mcrcachedir}/eigencoeff_Final/" >> eigencoeff_Final
	    echo export MCR_CACHE_ROOT="$scratch_dir${mcrcachedir}/eigencoeff_Final/" >> eigencoeff_Final
	    echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/eigencoeff/will_lsf_final_eigencoeff $allmotlname $ind $n_eigs $eigencoeffname $n_cores_xmatrix $check_final_eigencoeff" >> eigencoeff_Final
	    echo "rm -rf $scratch_dir${mcrcachedir}/eigencoeff_Final/" >> eigencoeff_Final
	    echo 'exit' >> eigencoeff_Final
	    chmod +x eigencoeff_Final


	    qsub -cwd -N eigencoeff_Final -l mem_free=${memfree},h_vmem=${memmax} -o log_eigencoeff_Final -e error_eigencoeff_Final ./eigencoeff_Final
	    #bsub -M ${memlimit} -R "select[mem > ${memneed}]" -R "rusage[mem=${memusage}]" -q $queue -o log_eigencoeff_Final -e error_eigencoeff_Final ./eigencoeff_Final

	    echo "Waiting for eigencoefficient..."
	
	    ## Reset counter
	    check_final=0

	    while [ $check_final -lt 1 ]; do
		    sleep 10s
		    check_final=$(( $(ls -1 -f ./checkjobs/ | wc -l) - 2 ))
        done

	    ### Write out completion file
	    touch $compdir/final_eigencoeff

        ### Copy files to group share
        cp ${scratch_dir}/${eigencoeffname}_$ind.em ${local_dir}/${eigencoeffname}_$ind.em


        ### Cleanup ### 
        rm -f $check_final_eigencoeff
        rm -f eigencoeff_Final
        rm -f ${scratch_dir}/${eigencoeffname}_${ind}_*.em

    fi
    echo "EIGENCOEFFICIENT CALCULATION COMPLETE"

fi

################################################################################################################################################################
### K-MEANS CALCULATION
################################################################################################################################################################
if [ $calculate_kmeans -eq 1 ]; then


    if [ ! -f $compdir/paral_kmeans ]; then

        ### Initialize parallel job number
        d=1

        ### Loop to generate replicate k-means scripts
        while [ $d -le $replicates ]; do

	        procnum=$d
	        echo "#!/bin/bash" > parallel_kmeans_$procnum
                echo "#$ -S /bin/bash" >> parallel_kmeans_$procnum
	        echo 'echo $HOSTNAME' >> parallel_kmeans_$procnum
	        echo 'set +o noclobber' >> parallel_kmeans_$procnum
	        echo 'set -e' >> parallel_kmeans_$procnum
	        echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> parallel_kmeans_$procnum
	        echo "cd $scratch_dir" >> parallel_kmeans_$procnum
	        echo "rm -rf $scratch_dir${mcrcachedir}/parallel_kmeans_$procnum/" >> parallel_kmeans_$procnum
	        echo "mkdir $scratch_dir${mcrcachedir}/parallel_kmeans_$procnum/" >> parallel_kmeans_$procnum
	        echo export MCR_CACHE_ROOT="$scratch_dir${mcrcachedir}/parallel_kmeans_$procnum" >> parallel_kmeans_$procnum
          	echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/kmeans/will_kmeans_eigenvalues_function $eigencoeffname $ind $temp_folder $vectors $n_clusters $procnum $check_paral_kmeans" >> parallel_kmeans_$procnum
	        echo "rm -rf $scratch_dir${mcrcachedir}/parallel_kmeans_$procnum/" >> parallel_kmeans_$procnum
	        echo 'exit' >> parallel_kmeans_$procnum
	        chmod +x parallel_kmeans_$procnum

	        ((d++))

        done
        
        ((d--))

        rm -f parallel_kmeans_array
        touch parallel_kmeans_array
        #echo "#BSUB -J [1-$d]" >> parallel_kmeans_array
        #echo "#BSUB -q $queue" >> parallel_kmeans_array
        #echo "${scratch_dir}/parallel_kmeans_"\$\{LSB_JOBINDEX\} >> parallel_kmeans_array
        echo "#!/bin/bash" >> parallel_kmeans_array
        echo "#$ -S /bin/bash" >> parallel_kmeans_array
        echo "#$ -t 1-$d" >> parallel_kmeans_array
        echo "#$ -cwd" >> parallel_kmeans_array
        echo "${scratch_dir}/parallel_kmeans_"\$\{SGE_TASK_ID\} >> parallel_kmeans_array


        ##### SEND OUT JOB ##########################
        chmod +x parallel_kmeans_array
        qsub -N parallel_kmeans -l mem_free=${memfree},h_vmem=${memmax} -o log_parallel_kmeans -e error_parallel_kmeans ./parallel_kmeans_array
        #bsub -J "${scratch_dir}/parallel_kmeans_[1-$d]" -M ${memlimit} -R "select[mem > ${memneed}]" -R "rusage[mem=${memusage}]" -q $queue -o log_parallel_kmeans -e error_parallel_kmeans ./parallel_kmeans_array
        echo "Parallel k-means calculations submitted"

        # Reset counter
        check_paral=0

        while [ $check_paral -lt $replicates ]; do
	        sleep 10s

	        check_paral=$(( $(ls -1 -f ./checkjobs/ | wc -l) - 2 ))
	        echo "Done $check_paral replicate k-means calculations out of $replicates"

        done


        ### Write out completion file
        touch $compdir/paral_kmeans
    fi
    echo "DONE K-MEANS CALCULATIONS!!!!"

    ### Remove scripts
    rm -f parallel_kmeans_*

    ### Clear checkjobs folder
    rsync -a --delete ${scratch_dir}/blank/ ${scratch_dir}/checkjobs/



    if [ ! -f $compdir/final_kmeans ]; then


	    rm -f kmean_Final

	    echo "#!/bin/bash" > kmean_Final
            echo "#$ -S /bin/bash" >> kmean_Final
	    echo 'set +o noclobber' >> kmean_Final
	    echo 'set -e' >> kmean_Final
	    echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> kmean_Final
	    echo "cd $scratch_dir" >> kmean_Final
	    echo "rm -rf $scratch_dir${mcrcachedir}/kmean_Final/" >> kmean_Final
	    echo "mkdir $scratch_dir${mcrcachedir}/kmean_Final/" >> kmean_Final
	    echo export MCR_CACHE_ROOT="$scratch_dir${mcrcachedir}/kmean_Final/" >> kmean_Final
	    echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/kmeans/will_kmeans_find_optimum_function $allmotlname $newallmotlname $ind $temp_folder $replicates $check_final_kmeans" >> kmean_Final
	    echo "rm -rf $scratch_dir${mcrcachedir}/kmean_Final/" >> kmean_Final
	    echo 'exit' >> kmean_Final
	    chmod +x kmean_Final


	    qsub -cwd -N kmean_Final -l mem_free=${memfree},h_vmem=${memmax} -o log_kmean_Final -e error_kmean_Final ./kmean_Final
	    #bsub -M ${memlimit} -R "select[mem > ${memneed}]" -R "rusage[mem=${memusage}]" -q $queue -o log_kmean_Final -e error_kmean_Final ./kmean_Final

	    echo "Looking for optimal k-means solution..."
	
	    ## Reset counter
	    check_final=0

	    while [ $check_final -lt 1 ]; do
		    sleep 10s
		    check_final=$(( $(ls -1 -f ./checkjobs/ | wc -l) - 2 ))
        done

	    ### Write out completion file
	    touch $compdir/final_kmeans

        ### Copy files to group share
        cp ${scratch_dir}/${newallmotlname}_$ind.em ${local_dir}/${newallmotlname}_$ind.em


        ### Cleanup ### 
        rm -f $check_final_kmeans
        rm -f kmean_Final
        rm -f ${scratch_dir}/${temp_folder}/tsumd_*.em
        rm -f ${scratch_dir}/${temp_folder}/kmeans_*.em

    fi
    echo "OPTIMAL K-MEANS SOLUTION FOUND!!!!"

fi
































