#!/bin/bash
################################################################################
# This is a run script for the standard AV3 subtomogram averaging scripts. The
# MATLAB executables for this script were compiled in MATLAB-8.5. The other
# difference is that these scripts have been edited to make sure that the output
# files from each step is readable.
#
# This script is meant to run on the scratch it copies the reference and final
# allmotl file to a local folder after each iteration.
#
# Also, the run script and all the launch scripts are written in bash. This is
# mainly because the behaviour of bash is a bit more predictable.
#
# A script for performing PCA classification on a dataset. Most steps
# are performed on the cluster, but the PCA step can be performed locally,
# as this is not parallelizable. The PCA classification method is 
# essentially that found in dynamo.
#
# NOTE: xmatrix files are NOT deleted. They can take up quite a bit of space
# so delete them as necessary.
#
# This subtomogram averaging script uses five MATLAB compiled scripts below:
# - scan_angles_exact
# - join_motls
# - parallel_sums
# - weighted_average
# - compare_motls
# DRM 11-2017
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Absolute path to the root folder for subtomogram extraction.
# Other paths are relative to this one.
scratch_dir=<SCRATCH_DIR>

# Absolute path to the folder on a group share, if your scratch directory is
# cleaned and deleted regularly you can set a local directory to which you can
# copy the important results. If you do not need to do this, you can skip this
# step with the option skip_local_copy below.
local_dir=<LOCAL_DIR>

# Absolute path to the MCR directory for each job
mcr_cache_dir=${scratch_dir}/mcr

# Directory for executables
exec_dir=XXXINSTALLATION_DIRXXX/bin

################################################################################
#                                  VARIABLES                                   #
################################################################################
# Alignment executable
align_exec=${exec_dir}/scan_angles_exact

# MOTL join executable
join_exec=${exec_dir}/join_motls

# Parallel Averaging executable
paral_avg_exec=${exec_dir}/parallel_sums

# Final Averaging executable
avg_exec=${exec_dir}/weighted_average

# Compare MOTLs executable
compare_exec=${exec_dir}/compare_motls

################################################################################
#                                MEMORY OPTIONS                                #
################################################################################
# The amount of memory your job requires
# e.g. mem_free_ali='2G'
mem_free=<MEM_FREE>

# The upper bound on the amount of memory your job is allowed to use
# e.g. mem_max_ali='3G'
mem_max=<MEM_MAX>

################################################################################
#                              OTHER LSF OPTIONS                               #
################################################################################
# BE CAREFUL THAT THE NAME DOESN'T CORRESPOND TO THE BEGINNING OF ANY OTHER FILE
job_name=<JOB_NAME>

# Maximum number of jobs per array
array_max=1000

# Maximum number of jobs per user
max_jobs=4000

# If you want to skip the cluster and run the job locally set this to 1.
run_local=0

# If you want to skip the copying of data to local_dir set this to 1.
skip_local_copy=1

################################################################################
#                                                                              #
#                     PCA CLASSIFICATION WORKFLOW OPTIONS                      #
#                                                                              #
################################################################################
#                           PARALLELIZATION OPTIONS                            #
################################################################################
# The index of the reference to generate : input will be
# all_motl_fn_prefix_iteration.em (define as integer e.g. iteration=1)
iteration=<ITERATION>

# Number of batches of particle comparisons in each parallel CC-matrix
# calculation job
num_ccmatrix_batch=<NUM_CCMATRIX_BATCH>

# Number of batches of particle comparisons in each parallel X-matrix
# calculation job
num_xmatrix_batch=<NUM_XMATRIX_BATCH>

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name prefix of the concatenated motivelist of all particles
# (e.g.  allmotl_iter.em , the variable will be written as a string e.g.
# all_motl_fn_prefix='sub-directory/allmotl')
all_motl_fn_prefix=<ALL_MOTL_FN_PREFIX>

# Relative path and name prefix of the weight file.
weight_fn_prefix=<WEIGHT_FN_PREFIX>

# Relative path and name of the partial weight files
weight_sum_fn_prefix=<WEIGHT_SUM_FN_PREFIX>

# Relative path and name prefix of the subtomograms (e.g. part_n.em, the
# variable will be written as a string e.g.
# ptcl_fn_prefix='sub-directory/part')
ptcl_fn_prefix=<PTCL_FN_PREFIX>

# Relative path and name of the classification mask
# e.g. class_mask_fn='otherinputs/align_mask_1.em'
class_mask_fn=<CLASS_MASK_FN>

# Relative path and name of the CC-matrix.
# e.g. ccmatrix_fn_prefix='pca/ccmatrix'
ccmatrix_fn_prefix=<CCMATRIX_FN_PREFIX>

# Relative path and name for the eigenvectors from PCA classification.
# e.g. eigen_vec_fn_prefix='pca/eigenvector'
eigen_vec_fn_prefix=<EIGEN_VEC_FN_PREFIX>

# Relative path and name for the eigenvalues from PCA classification.
# e.g. eigen_val_fn_prefix='pca/eigenvalue'
eigen_val_fn_prefix=<EIGEN_VAL_FN_PREFIX>

# Relative path and name for the X-matrix blocks.
# e.g. xmatrix_fn_prefix='pca/xmatrix'
xmatrix_fn_prefix=<XMATRIX_FN_PREFIX>

# Relative path and name for the X-matrix weight blocks.
# e.g. xmatrix_weight_fn_prefix='pca/xmatrix_weight'
xmatrix_weight_fn_prefix=<XMATRIX_WEIGHT_FN_PREFIX>

# Relative path and name for the eigenvolumes from PCA classification.
# e.g. eigen_vol_fn_prefix='pca/eigenvolume'
eigen_vol_fn_prefix=<EIGEN_VOL_FN_PREFIX>

# Relative path and name for the eigencoefficients from PCA classification.
# e.g. eigen_coeff_fn_prefix='pca/eigencoeff'
eigen_coeff_fn_prefix=<EIGEN_COEFF_FN_PREFIX>

# Relative path and name prefix of the concatenated motivelist of all particles
# after PCA classification (e.g.  allmotl_PCA_iter.em , the variable will be
# written as a string e.g.  pca_motl_fn_prefix='sub-directory/allmotl_PCA')
pca_motl_fn_prefix=<PCA_MOTL_FN_PREFIX>

# Relative path and name of the reference volumes (e.g. ref_iter.em , the
# variable will be written as a string e.g. ref_fn_prefix='sub-directory/ref')
ref_fn_prefix=<REF_FN_PREFIX>

################################################################################
#                               CC-MATRIX OPTIONS                              #
################################################################################
# Calculate CC-matrix. (1 = yes, 0 = no)
calculate_ccmatrix=1

# Which row in the motl file contains the correct tomogram number.
# Usually row 5 and 7 both correspond to the correct value and can be used
# interchangeably, but there are instances when 5 contains a sequential ordered
# value starting from 1, while 7 contains the correct corresponding tomogram.
tomo_row=7

# High pass filter (in transform units (pixels): calculate as
# (boxsize*pixelsize)/(resolution_real) (define as an integer e.g.
# high_pass_fp=2) the filter has a Gaussian drop-off in Fourier pixels specified
# by high_pass_sigma below.
high_pass_fp=<HIGH_PASS_FP>

# High pass filter Gaussian drop-off in Fourier pixels.
high_pass_sigma=2

# Low pass filter (in transform units (pixels): calculate as
# (boxsize*pixelsize)/(resolution_real) (define as integer e.g.
# low_pass_fp=30), the filter has a Gaussian drop-off in Fourier pixels
# specified by low_pass_sigma below.
low_pass_fp=<LOW_PASS_FP>

# Low pass filter Gaussian drop-off in Fourier pixels.
low_pass_sigma=2

### PCA Classification ###
################################################################################
#                     PRINCIPAL COMPONENT ANALYSIS OPTIONS                     #
################################################################################
# Calculate PCA. (1 = yes, 0 = no)
calculate_pca=1

# If you want to skip the cluster and run the PCA job locally set this to 1.
run_pca_local=0

# The number of eigenvectors to calculate.
num_eigen_vec=30

# The two following options are for expert users that want to be able to tune
# more closely how the PCA calculation is performed. If you want to use the
# default values set each variable to 'default'.

# Use the MATLAB function svds to calculate the PCA, by default the function
# eigs is used, but there may be some who prefer SVD to EVD for PCA.
# (1 = yes, 0 = no)
use_svd=0

# Number of iterations to run in estimating the decomposition vectors and
# values.
num_pca_iterations='default'

# The convergence tolerance in estimating the decomposition vectors and values.
pca_tolerance='default'

################################################################################
#                               X-MATRIX OPTIONS                               #
################################################################################
# Calculate X-matrix. (1 = yes, 0 = no)
calculate_xmatrix=1

# Calculate a full volume or just the masked area. (1 = full, 0 = masked area)
full_xmatrix=1                           

################################################################################
#                             EIGENVOLUME OPTIONS                              #
################################################################################
# Calculate eigenvolumes. (1 = yes, 0 = no)
calculate_eigen_vol=1

################################################################################
#                           EIGENCOEFFICIENT OPTIONS                            #
################################################################################
# Calculate eigencoefficients. (1 = yes, 0 = no)
calculate_eigen_val=1

################################################################################
#                          K-MEANS CLUSTERING OPTIONS                          #
################################################################################
# Calculate K-means clustering. (1 = yes, 0 = no)
calculate_kmeans=1

# The eigenvectors onto which the data is projected before K-Means clustering.
# This value must be given as a MATLAB-style vector (e.g kmeans_vectors='[2:5]')
kmeans_vectors=<KMEANS_VECTORS>

# The number of clusters to separate the data into by K-means.
num_kmeans_clusters=10

# The number of independent k-means clustering runs to evaluate. Due to the bias
# of the random starting position, it's a good idea to run several replicate
# clusterings.
num_kmeans_runs=10

################################################################################
#                                                                              #
#                                END OF OPTIONS                                #
#                                                                              #
################################################################################
# Check number of jobs
if [[ ${num_ccmatrix_batch} -gt ${max_jobs} || \
      ${num_xmatrix_batch} -gt ${max_jobs} ]]
then
    echo " TOO MANY JOBS!!!!!  I QUIT!!!"
    exit 1
fi

# Check that other directories exist and if not, make them
if [[ ${skip_local_copy} -ne 1 ]]
then
    if [[ ! -d ${local_dir} ]]
    then
        mkdir -p ${local_dir}
    fi

    if [[ ! -d $(dirname ${local_dir}/${weight_sum_fn_prefix}) ]]
    then
        mkdir -p $(dirname ${local_dir}/${weight_sum_fn_prefix})
    fi

    if [[ ! -d $(dirname ${local_dir}/${ccmatrix_fn_prefix}) ]]
    then
        mkdir -p $(dirname ${local_dir}/${ccmatrix_fn_prefix})
    fi

    if [[ ! -d $(dirname ${local_dir}/${eigen_vec_fn_prefix}) ]]
    then
        mkdir -p $(dirname ${local_dir}/${eigen_vec_fn_prefix})
    fi

    if [[ ! -d $(dirname ${local_dir}/${xmatrix_fn_prefix}) ]]
    then
        mkdir -p $(dirname ${local_dir}/${xmatrix_fn_prefix})
    fi

    if [[ ! -d $(dirname ${local_dir}/${eigen_vol_fn_prefix}) ]]
    then
        mkdir -p $(dirname ${local_dir}/${eigen_vol_fn_prefix})
    fi

    if [[ ! -d $(dirname ${local_dir}/${eigen_val_fn_prefix}) ]]
    then
        mkdir -p $(dirname ${local_dir}/${eigen_val_fn_prefix})
    fi

    if [[ ! -d $(dirname ${local_dir}/${pca_motl_fn_prefix}) ]]
    then
        mkdir -p $(dirname ${local_dir}/${pca_motl_fn_prefix})
    fi

    if [[ ! -d $(dirname ${local_dir}/${ref_fn_prefix}) ]]
    then
        mkdir -p $(dirname ${local_dir}/${ref_fn_prefix})
    fi
fi

oldpwd=$(pwd)
cd ${scratch_dir}
if [[ ! -d ${mcr_cache_dir} ]]
then
    mkdir -p ${mcr_cache_dir}
fi

if [[ ! -d $(dirname ${weight_sum_fn_prefix}) ]]
then
    mkdir -p $(dirname ${weight_sum_fn_prefix})
fi

if [[ ! -d $(dirname ${ccmatrix_fn_prefix}) ]]
then
    mkdir -p $(dirname ${ccmatrix_fn_prefix})
fi

if [[ ! -d $(dirname ${eigen_vec_fn_prefix}) ]]
then
    mkdir -p $(dirname ${eigen_vec_fn_prefix})
fi

if [[ ! -d $(dirname ${xmatrix_fn_prefix}) ]]
then
    mkdir -p $(dirname ${xmatrix_fn_prefix})
fi

if [[ ! -d $(dirname ${eigen_vol_fn_prefix}) ]]
then
    mkdir -p $(dirname ${eigen_vol_fn_prefix})
fi

if [[ ! -d $(dirname ${eigen_val_fn_prefix}) ]]
then
    mkdir -p $(dirname ${eigen_val_fn_prefix})
fi

if [[ ! -d $(dirname ${pca_motl_fn_prefix}) ]]
then
    mkdir -p $(dirname ${pca_motl_fn_prefix})
fi

if [[ ! -d $(dirname ${ref_fn_prefix}) ]]
then
    mkdir -p $(dirname ${ref_fn_prefix})
fi

cd ${oldpwd}
job_name=${job_name}_ccmatrix

if [[ ${mem_free%G} -ge 24 ]]
then
    dedmem_ali=',dedicated=12'
else
    dedmem_ali=''
fi

if [ ${calculate_ccmatrix} -eq 1 ]; then

    ############# PREPARE FOR CC-MATRIX CALCULATION	 #############
    if [ ! -f ${compdir}/prep_cc_matrix ]; then


	    echo "#!/bin/bash" >> prepare_ccmatrix
            echo "#$ -cwd" >> prepare_ccmatrix
            echo "#$ -S /bin/bash" >> prepare_ccmatrix
            #echo "#$ -V" >> prepare_ccmatrix
	    echo 'echo ${HOSTNAME}' >> prepare_ccmatrix
	    echo 'set +o noclobber' >> prepare_ccmatrix
	    echo 'set -e' >> prepare_ccmatrix
	    echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> prepare_ccmatrix
	    #echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> prepare_ccmatrix
	    echo "cd ${scratch_dir}" >> prepare_ccmatrix
	    echo "rm -rf ${scratch_dir}/${mcrcachedir}/prepare_ccmatrix/" >> prepare_ccmatrix
	    echo "mkdir ${scratch_dir}/${mcrcachedir}/prepare_ccmatrix/" >> prepare_ccmatrix
	    echo export MCR_CACHE_ROOT="${scratch_dir}/${mcrcachedir}/prepare_ccmatrix/" >> prepare_ccmatrix
      	echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/ccmatrix/will_lsf_prepare_ccmatrix_sge ${all_motl_fn_prefix} ${ccmatrix_fn_prefix} ${iteration} ${wedgelistname} ${wedgemaskname} ${tomo_row} ${ptcl_fn_prefix} ${class_mask_fn} ${low_pass_fp} ${low_pass_sigma} ${high_pass_fp} ${high_pass_sigma} ${mem_free} ${mem_max} ${ccmatrix_batch_size} ${temp_folder} ${check_ccmatrix_paral}" >> prepare_ccmatrix
	    echo "rm -rf ${scratch_dir}/${mcrcachedir}/prepare_ccmatrix/" >> prepare_ccmatrix
	    echo 'exit' >> prepare_ccmatrix
	    chmod +x prepare_ccmatrix


	    ##### SEND OUT JOB ##########################
	    #bsub -M ${memlimit} -R "select[mem > ${memneed}]" -R "rusage[mem=${memusage}]" -q ${queue} -o log_prepare_ccmatrix -e error_prepare_ccmatrix ${scratch_dir}/prepare_ccmatrix
	    qsub -cwd -N prepare_ccmatrix -l mem_free=${mem_free},h_vmem=${mem_max} -o log_prepare_ccmatrix -e error_prepare_ccmatrix ${scratch_dir}/prepare_ccmatrix
	    echo "Preparing to calculate a CC-matrix!"

	    # Reset counter
	    check_prep=0

	    while [ ${check_prep} -lt 1 ]; do
		    sleep 10s
            check_prep=$(ls submit_calculate_ccmatrix 2>/dev/null | wc -l)
		    echo "     ...still preparing to calculate the CC-matrix..."
	
	    done
        
        echo "GIRD YOUR LOINS! I AM READY!!!"

	    ### Write out completion file
	    touch ${compdir}/prep_cc_matrix
    fi


    ############# PARALLEL CC-MATRIX CALCULATION	 #############
    if [ ! -f ${compdir}/paral_cc_matrix ]; then


	    ##### SEND OUT JOB ##########################
        ./submit_calculate_ccmatrix
	    echo "Parallel CC-matrix calculation submitted!!!"

	    # Reset counter
	    check_paral=0

	    while [ ${check_paral} -lt ${ccmatrix_batch_size} ]; do
		    sleep 10s
		    check_paral=$(( $(ls -1 -f ./checkjobs/ | wc -l) - 2 ))
            echo "Calculated ${check_paral} segments out of ${ccmatrix_batch_size}"
        done
        
        echo "Parallel CC-matrix calculation complete!!!"

	    ### Write out completion file
	    touch ${compdir}/paral_cc_matrix

        ### Clear checkjobs
        rsync -a --delete ${scratch_dir}/blank/ ${scratch_dir}/checkjobs/
        rm -f calculate_ccmatrix_*
        rm -f submit_calculate_ccmatrix prepare_ccmatrix
    fi


    ############# FINAL AVERAGE	 #############
    if [ ! -f ${compdir}/final_cc_matrix ]; then


	    rm -f ccmatrix_Final

	    echo "#!/bin/bash" > ccmatrix_Final
            echo "#$ -S /bin/bash" >> ccmatrix_Final
	    echo 'set +o noclobber' >> ccmatrix_Final
	    echo 'set -e' >> ccmatrix_Final
	    echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> ccmatrix_Final
	    echo "cd ${scratch_dir}" >> ccmatrix_Final
	    echo "rm -rf ${scratch_dir}/${mcrcachedir}/ccmatrix_Final/" >> ccmatrix_Final
	    echo "mkdir ${scratch_dir}/${mcrcachedir}/ccmatrix_Final/" >> ccmatrix_Final
	    echo export MCR_CACHE_ROOT="${scratch_dir}/${mcrcachedir}//ccmatrix_Final/" >> ccmatrix_Final
	    echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/ccmatrix/will_lsf_final_ccmatrix ${ccmatrix_fn_prefix} ${iteration} ${ccmatrix_batch_size} ${check_ccmatrix_final}" >> ccmatrix_Final
	    echo "rm -rf ${scratch_dir}/${mcrcachedir}/ccmatrix_Final/" >> ccmatrix_Final
	    echo 'exit' >> ccmatrix_Final
	    chmod +x ccmatrix_Final


	    qsub -cwd -N ccmatrix_Final -l mem_free=${mem_free},h_vmem=${mem_max} -o log_ccmatrix_Final -e error_ccmatrix_Final ./ccmatrix_Final
            #bsub -M ${memlimit} -R "select[mem > ${memneed}]" -R "rusage[mem=${memusage}]" -q ${queue} -o log_ccmatrix_Final -e error_ccmatrix_Final ./ccmatrix_Final

	    echo "Waiting for the final CC-matrix..."
	
	    ## Reset counter
	    check_final=0

	    while [ ${check_final} -lt 1 ]; do
		    sleep 10s
		    check_final=$(( $(ls -1 -f ./checkjobs/ | wc -l) - 2 ))
        done

	    ### Write out completion file
	    touch ${compdir}/final_cc_matrix

        ### Copy file to group share
        cp ${scratch_dir}/${ccmatrix_fn_prefix}_${iteration}.em ${local_dir}/${ccmatrix_fn_prefix}_${iteration}.em

        ### Cleanup ### 
        rm -f ${check_ccmatrix_final}
        rm -f ccmatrix_Final
        rm -f ${ccmatrix_fn_prefix}_${iteration}_*.em
        rm -f ${temp_folder}/job_array_*.em

    fi
    echo "CC-MATRIX CALCULATION COMPLETE"

fi

################################################################################################################################################################
### PCA CALCULATION
###############################################################################################################################################################
if [ ${calculate_pca} -eq 1 ]; then

    ############# PCA CALCULATION	 #############
    if [ ! -f ${compdir}/pca_calc ]; then

        # Calculate on cluster
        if [ ${run_pca_local} != 1 ]; then
	        echo "#!/bin/bash" > calculate_PCA
                echo "#$ -S /bin/bash" >> calculate_PCA
	        echo 'echo ${HOSTNAME}' >> calculate_PCA
	        echo 'set +o noclobber' >> calculate_PCA
	        echo 'set -e' >> calculate_PCA
	        echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> calculate_PCA
	        echo "cd ${scratch_dir}" >> calculate_PCA
	        echo "rm -rf ${scratch_dir}/${mcrcachedir}/calculate_PCA/" >> calculate_PCA
	        echo "mkdir ${scratch_dir}/${mcrcachedir}/calculate_PCA/" >> calculate_PCA
	        echo export MCR_CACHE_ROOT="${scratch_dir}/${mcrcachedir}/calculate_PCA/" >> calculate_PCA
          	echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/pca/will_pca_ccmatrix_function ${ccmatrix_fn_prefix} ${iteration} ${num_eigen_vec} ${eigen_vec_fn_prefix} ${check_pca}" >> calculate_PCA
	        echo "rm -rf ${scratch_dir}/${mcrcachedir}/calculate_PCA/" >> calculate_PCA
	        echo 'exit' >> calculate_PCA
	        chmod +x calculate_PCA


	        ##### SEND OUT JOB ##########################
	        qsub -cwd -N calculate_PCA -l mem_free=${mem_free},h_vmem=${mem_max} -o log_calculate_PCA -e error_calculate_PCA ${scratch_dir}/calculate_PCA
	        #bsub -M ${memlimit} -R "select[mem > ${memneed}]" -R "rusage[mem=${memusage}]" -q ${queue} -o log_calculate_PCA -e error_calculate_PCA ${scratch_dir}/calculate_PCA
	        echo "Calculating PCA on the cluster!"

	        # Reset counter
	        check=0

	        while [ ${check} -lt 1 ]; do
		        sleep 10s
       	        check=$(( $(ls -1 -f ./checkjobs/ | wc -l) - 2 ))
		        echo "     ...still calculating PCA ..."
	
	        done
            
            echo "PCA Calculated!!!"

            ### Copy files ###
            cp ${scratch_dir}/${eigen_vec_fn_prefix}_${iteration}.em ${local_dir}/${eigen_vec_fn_prefix}_${iteration}.em 

            ### Cleanup ###
            rm -rf checkjobs/*
            rm -f calculate_PCA

	        ### Write out completion file
	        touch ${compdir}/pca_calc


        # Calculate via local_dummy.sh
        else    

	        echo "#!/bin/bash" > ${local_dir}/calculate_PCA
                echo "#$ -S /bin/bash" >> ${local_dir}/calculate_PCA
	        echo 'echo ${HOSTNAME}' >> ${local_dir}/calculate_PCA
	        echo 'set +o noclobber' >> ${local_dir}/calculate_PCA
	        echo 'set -e' >> ${local_dir}/calculate_PCA
	        echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> ${local_dir}/calculate_PCA
            echo "cd ${local_dir}/" >> ${local_dir}/calculate_PCA
	        echo "rm -rf ${local_dir}/${mcrcachedir}/calculate_PCA/" >> ${local_dir}/calculate_PCA
	        echo "rm -rf ${local_dir}/checkjobs/" >> ${local_dir}/calculate_PCA	        
            echo "mkdir checkjobs" >> ${local_dir}/calculate_PCA
	        echo "mkdir -p ${local_dir}/${mcrcachedir}/calculate_PCA/" >> ${local_dir}/calculate_PCA
	        echo export MCR_CACHE_ROOT="${local_dir}/${mcrcachedir}/calculate_PCA/" >> ${local_dir}/calculate_PCA
          	echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/pca/will_pca_ccmatrix_function ${ccmatrix_fn_prefix} ${iteration} ${num_eigen_vec} ${eigen_vec_fn_prefix} ${check_pca}" >> ${local_dir}/calculate_PCA
	        echo "rm -rf ${local_dir}/${mcrcachedir}/calculate_PCA/" >> ${local_dir}/calculate_PCA
	        echo 'exit' >> ${local_dir}/calculate_PCA
	        chmod +x ${local_dir}/calculate_PCA

            ##### SEND OUT JOB ##########################
	        mv ${local_dir}/calculate_PCA ${local_dir}/dummy_command
	        echo "Calculating PCA locally!"

	        # Reset counter
	        check=0

	        while [ ${check} -lt 1 ]; do
		        sleep 10s
       	        check=$(( $(ls -1 -f ${local_dir}/checkjobs/ | wc -l) - 2 ))
		        echo "     ...still calculating PCA ..."
	
	        done
            
            

            ### Copy files ###
            cp ${local_dir}/${eigen_vec_fn_prefix}_${iteration}.em ${scratch_dir}/${eigen_vec_fn_prefix}_${iteration}.em 

            ### Cleanup ###
            rm -f ${local_dir}/checkjobs/*
            rm -f ${local_dir}/calculate_PCA

	        ### Write out completion file
	        touch ${compdir}/pca_calc

        fi
    fi
    
    echo "PCA Calculated!!!"
fi


################################################################################################################################################################
### XMATRIX CALCULATION
################################################################################################################################################################
if [ ${calculate_xmatrix} -eq 1 ]; then
    if [ ! -f ${compdir}/paral_xmatrix ]; then

	    ### Initialize parallel job number
	    d=1

	    ### Loop to generate parallel scripts
	    while [ ${d} -le ${xmatrix_batch_size} ]; do

		    procnum=${d}
		    echo "#!/bin/bash" > parallel_xmatrix_${procnum}
                    echo "#$ -S /bin/bash" >> parallel_xmatrix_${procnum}
		    echo 'echo ${HOSTNAME}' >> parallel_xmatrix_${procnum}
		    echo 'set +o noclobber' >> parallel_xmatrix_${procnum}
		    echo 'set -e' >> parallel_xmatrix_${procnum}
		    echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> parallel_xmatrix_${procnum}
		    echo "cd ${scratch_dir}" >> parallel_xmatrix_${procnum}
		    echo "rm -rf ${scratch_dir}/${mcrcachedir}/parallel_xmatrix_${procnum}/" >> parallel_xmatrix_${procnum}
		    echo "mkdir ${scratch_dir}/${mcrcachedir}/parallel_xmatrix_${procnum}/" >> parallel_xmatrix_${procnum}
		    echo export MCR_CACHE_ROOT="${scratch_dir}/${mcrcachedir}/parallel_xmatrix_${procnum}/" >> parallel_xmatrix_${procnum}
	      	echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/xmatrix/will_lsf_xmatrix_parallel ${all_motl_fn_prefix} ${xmatrix_fn_prefix} ${full_xmatrix} ${iteration} ${class_mask_fn} ${ptcl_fn_prefix} ${xmatrix_batch_size} ${procnum} ${check_paral_xmatrix}" >> parallel_xmatrix_${procnum}
		    echo "rm -rf ${scratch_dir}/${mcrcachedir}/parallel_xmatrix_${procnum}/" >> parallel_xmatrix_${procnum}
		    echo 'exit' >> parallel_xmatrix_${procnum}
		    chmod +x parallel_xmatrix_${procnum}

		    ((d++))

	    done
        
        ((d--))

	    rm -f parallel_xmatrix_array
	    touch parallel_xmatrix_array

            #echo "#BSUB -J [1-${d}]" >> parallel_xmatrix_array
            #echo "#BSUB -q ${queue}" >> parallel_xmatrix_array
            #echo "${scratch_dir}/parallel_xmatrix_"\$\{LSB_JOBINDEX\} >> parallel_xmatrix_array
            echo "#!/bin/bash" >> parallel_xmatrix_array
            echo "#$ -S /bin/bash" >> parallel_xmatrix_array
	    echo "#$ -t 1-${d}" >> parallel_xmatrix_array
	    echo "#$ -cwd" >> parallel_xmatrix_array
	    echo "${scratch_dir}/parallel_xmatrix_"\$\{SGE_TASK_ID\} >> parallel_xmatrix_array


	    ##### SEND OUT JOB ##########################
	    chmod +x parallel_xmatrix_array
	    qsub -N parallel_xmatrix -l mem_free=${mem_free},h_vmem=${mem_max} -o log_parallel_xmatrix -e error_parallel_xmatrix ./parallel_xmatrix_array
	    #bsub -J "${scratch_dir}/parallel_xmatrix_[1-${d}]" -M ${memlimit} -R "select[mem > ${memneed}]" -R "rusage[mem=${memusage}]" -q ${queue} -o log_parallel_xmatrix -e error_parallel_xmatrix ./parallel_xmatrix_array
	    echo "Parallel xmatrix calculation submitted"

	    # Reset counter
	    check_paral=0

	    while [ ${check_paral} -lt ${xmatrix_batch_size} ]; do
		    sleep 10s

		    check_paral=$(( $(ls -1 -f ./checkjobs/ | wc -l) - 2 ))
		    echo "Done ${check_paral} parallel xmatrix calculations out of ${xmatrix_batch_size}"
	
	    done


	    ### Write out completion file
	    touch ${compdir}/paral_xmatrix
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
if [ ${calculate_eigen_vol} -eq 1 ]; then

    if [ ! -f ${compdir}/paral_eigenvolume ]; then

	    ### Initialize parallel job number
	    d=1

	    ### Loop to generate parallel scripts
	    while [ ${d} -le ${xmatrix_batch_size} ]; do

		    procnum=${d}
		    echo "#!/bin/bash" > parallel_eigenvolume_${procnum}
                    echo "#$ -S /bin/bash" >> parallel_eigenvolume_${procnum}
		    echo 'echo ${HOSTNAME}' >> parallel_eigenvolume_${procnum}
		    echo 'set +o noclobber' >> parallel_eigenvolume_${procnum}
		    echo 'set -e' >> parallel_eigenvolume_${procnum}
		    echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> parallel_eigenvolume_${procnum}
		    echo "cd ${scratch_dir}" >> parallel_eigenvolume_${procnum}
		    echo "rm -rf ${scratch_dir}/${mcrcachedir}/parallel_eigenvolume_${procnum}/" >> parallel_eigenvolume_${procnum}
		    echo "mkdir ${scratch_dir}/${mcrcachedir}/parallel_eigenvolume_${procnum}/" >> parallel_eigenvolume_${procnum}
		    echo export MCR_CACHE_ROOT="${scratch_dir}/${mcrcachedir}/parallel_eigenvolume_${procnum}/" >> parallel_eigenvolume_${procnum}
	      	echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/eigenvol/will_lsf_parallel_eigenvol2 ${all_motl_fn_prefix} ${eigen_vec_fn_prefix} ${xmatrix_fn_prefix} ${eigen_vol_fn_prefix} ${iteration} ${ptcl_fn_prefix} ${temp_folder} ${wedgelistname} ${wedgemaskname} ${tomo_row} ${xmatrix_batch_size} ${procnum} ${check_paral_eigenvol}" >> parallel_eigenvolume_${procnum}
		    echo "rm -rf ${scratch_dir}/${mcrcachedir}/parallel_eigenvolume_${procnum}/" >> parallel_eigenvolume_${procnum}
		    echo 'exit' >> parallel_eigenvolume_${procnum}
		    chmod +x parallel_eigenvolume_${procnum}

		    ((d++))

	    done
        
        ((d--))

	    rm -f parallel_eigenvolume_array
	    touch parallel_eigenvolume_array
	    #echo "#BSUB -J [1-${d}]" >> parallel_eigenvolume_array
            #echo "#BSUB -q ${queue}" >> parallel_eigenvolume_array
            echo "#!/bin/bash" >> parallel_eigenvolume_array
            echo "#$ -S /bin/bash" >> parallel_eigenvolume_array
            echo "#$ -t 1-${d}" >> parallel_eigenvolume_array
	    echo "#$ -cwd" >> parallel_eigenvolume_array
	    echo "${scratch_dir}/parallel_eigenvolume_"\$\{SGE_TASK_ID\} >> parallel_eigenvolume_array


	    ##### SEND OUT JOB ##########################
	    chmod +x parallel_eigenvolume_array
	    qsub -N parallel_eigenvolume -l mem_free=${mem_free},h_vmem=${mem_max} -o log_parallel_eigenvol -e error_parallel_eigenvol ./parallel_eigenvolume_array
	    #bsub -J "${scratch_dir}/parallel_eigenvolume_[1-${d}]" -M ${memlimit} -R "select[mem > ${memneed}]" -R "rusage[mem=${memusage}]" -q ${queue} -o log_parallel_eigenvol -e error_parallel_eigenvol ./parallel_eigenvolume_array
	    echo "Parallel eigenvolume calculation submitted"

	    # Reset counter
	    check_paral=0

	    while [ ${check_paral} -lt ${xmatrix_batch_size} ]; do
		    sleep 10s

		    check_paral=$(( $(ls -1 -f ./checkjobs/ | wc -l) - 2 ))
		    echo "Done ${check_paral} parallel eigenvolume calculations out of ${xmatrix_batch_size}"
	
	    done


	    ### Write out completion file
	    touch ${compdir}/paral_eigenvolume
    fi
    echo "DONE PARALLEL EIGENVOLUME CALCULATIONS!!!!"

    ### Remove scripts
    rm -f parallel_eigenvolume_*

    ### Clear checkjobs folder
    rsync -a --delete ${scratch_dir}/blank/ ${scratch_dir}/checkjobs/




    if [ ! -f ${compdir}/final_eigenvol ]; then


	    rm -f eigenvolume_Final

	    echo "#!/bin/bash" > eigenvolume_Final
            echo "#$ -S /bin/bash" >> eigenvolume_Final
	    echo 'set +o noclobber' >> eigenvolume_Final
	    echo 'set -e' >> eigenvolume_Final
	    echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> eigenvolume_Final
	    echo "cd ${scratch_dir}" >> eigenvolume_Final
	    echo "rm -rf ${scratch_dir}/${mcrcachedir}/eigenvolume_Final/" >> eigenvolume_Final
	    echo "mkdir ${scratch_dir}/${mcrcachedir}/eigenvolume_Final/" >> eigenvolume_Final
	    echo export MCR_CACHE_ROOT="${scratch_dir}/${mcrcachedir}/eigenvolume_Final/" >> eigenvolume_Final
	    echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/eigenvol/will_lsf_final_eigenvol2 ${all_motl_fn_prefix} ${eigen_vol_fn_prefix} ${iteration} ${full_xmatrix} ${class_mask_fn} ${temp_folder} ${xmatrix_batch_size} ${check_final_eigenvol}" >> eigenvolume_Final
	    echo "rm -rf ${scratch_dir}/${mcrcachedir}/eigenvolume_Final/" >> eigenvolume_Final
	    echo 'exit' >> eigenvolume_Final
	    chmod +x eigenvolume_Final


	    qsub -cwd -N eigenvolume_Final -l mem_free=${mem_free},h_vmem=${mem_max} -o log_eigenvolume_Final -e error_eigenvolume_Final ./eigenvolume_Final
	    #bsub -M ${memlimit} -R "select[mem > ${memneed}]" -R "rusage[mem=${memusage}]" -q ${queue} -o log_eigenvolume_Final -e error_eigenvolume_Final ./eigenvolume_Final

	    echo "Waiting for eigenvolumes..."
	
	    ## Reset counter
	    check_final=0

	    while [ ${check_final} -lt 1 ]; do
		    sleep 10s
		    check_final=$(( $(ls -1 -f ./checkjobs/ | wc -l) - 2 ))
        done

	    ### Write out completion file
	    touch ${compdir}/final_eigenvol

        ### Copy files to group share
        c=1
        while [ ${c} -le ${num_eigen_vec} ]; do
            cp ${scratch_dir}/${eigen_vol_fn_prefix}_${c}_${iteration}.em ${local_dir}/${eigen_vol_fn_prefix}_${c}_${iteration}.em 2>/dev/null || :
            ((c++))
        done

        ### Cleanup ### 
        rm -f ${check_final_eigenvol}
        rm -f eigenvolume_Final
        rm -f ${scratch_dir}/${eigen_vol_fn_prefix}*temp.em
        rm -f ${scratch_dir}/${temp_folder}/wfilt*.em

    fi
    echo "EIGENVOLUME CALCULATION COMPLETE"
fi




################################################################################################################################################################
### EIGENCOEFFICIENTS CALCULATION
################################################################################################################################################################
if [ ${calculate_eigen_val} -eq 1 ]; then

    if [ ! -f ${compdir}/paral_eigencoeff ]; then

        ### Initialize parallel job number
        d=1

        ### Loop to generate parallel scripts
        while [ ${d} -le ${xmatrix_batch_size} ]; do

	        procnum=${d}
	        echo "#!/bin/bash" > parallel_eigencoeff_${procnum}
                echo "#$ -S /bin/bash" >> parallel_eigencoeff_${procnum}
	        echo 'echo ${HOSTNAME}' >> parallel_eigencoeff_${procnum}
	        echo 'set +o noclobber' >> parallel_eigencoeff_${procnum}
	        echo 'set -e' >> parallel_eigencoeff_${procnum}
	        echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> parallel_eigencoeff_${procnum}
	        echo "cd ${scratch_dir}" >> parallel_eigencoeff_${procnum}
	        echo "rm -rf ${scratch_dir}/${mcrcachedir}/parallel_eigencoeff_${procnum}/" >> parallel_eigencoeff_${procnum}
	        echo "mkdir ${scratch_dir}/${mcrcachedir}/parallel_eigencoeff_${procnum}/" >> parallel_eigencoeff_${procnum}
	        echo export MCR_CACHE_ROOT="${scratch_dir}/${mcrcachedir}/parallel_eigencoeff_${procnum}" >> parallel_eigencoeff_${procnum}
          	echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/eigencoeff/will_lsf_parallel_eigencoeff ${all_motl_fn_prefix} ${wedgelistname} ${wedgemaskname} ${tomo_row} ${eigen_vol_fn_prefix} ${num_eigen_vec} ${iteration} ${xmatrix_fn_prefix} ${full_xmatrix} ${class_mask_fn} ${eigen_val_fn_prefix} ${xmatrix_batch_size} ${procnum} ${check_paral_eigencoeff}" >> parallel_eigencoeff_${procnum}
	        echo "rm -rf ${scratch_dir}/${mcrcachedir}/parallel_eigencoeff_${procnum}/" >> parallel_eigencoeff_${procnum}
	        echo 'exit' >> parallel_eigencoeff_${procnum}
	        chmod +x parallel_eigencoeff_${procnum}

	        ((d++))

        done
        
        ((d--))

        rm -f parallel_eigencoeff_array
        touch parallel_eigencoeff_array
        #echo "#BSUB -J [1-${d}]" >> parallel_eigencoeff_array
        #echo "#BSUB -q ${queue}" >> parallel_eigencoeff_array
        #echo "${scratch_dir}/parallel_eigencoeff_"\$\{LSB_JOBINDEX\} >> parallel_eigencoeff_array
        echo "#!/bin/bash" >> parallel_eigencoeff_array
        echo "#$ -S /bin/bash" >> parallel_eigencoeff_array
        echo "#$ -t 1-${d}" >> parallel_eigencoeff_array
        echo "#$ -cwd" >> parallel_eigencoeff_array
        echo "${scratch_dir}/parallel_eigencoeff_"\$\{SGE_TASK_ID\} >> parallel_eigencoeff_array


        ##### SEND OUT JOB ##########################
        chmod +x parallel_eigencoeff_array
        qsub -N parallel_eigencoeff -l mem_free=${mem_free},h_vmem=${mem_max} -o log_parallel_eigencoeff -e error_parallel_eigencoeff ./parallel_eigencoeff_array
        #bsub -J "${scratch_dir}/parallel_eigencoeff_[1-${d}]" -M ${memlimit} -R "select[mem > ${memneed}]" -R "rusage[mem=${memusage}]" -q ${queue} -o log_parallel_eigencoeff -e error_parallel_eigencoeff ./parallel_eigencoeff_array
        echo "Parallel eigencoefficient calculation submitted"

        # Reset counter
        check_paral=0

        while [ ${check_paral} -lt ${xmatrix_batch_size} ]; do
	        sleep 10s

	        check_paral=$(( $(ls -1 -f ./checkjobs/ | wc -l) - 2 ))
	        echo "Done ${check_paral} parallel eigencoefficient calculations out of ${xmatrix_batch_size}"

        done


        ### Write out completion file
        touch ${compdir}/paral_eigencoeff
    fi
    echo "DONE PARALLEL EIGENCOEFFICIENT CALCULATIONS!!!!"

    ### Remove scripts
    rm -f parallel_eigencoeff_*

    ### Clear checkjobs folder
    rsync -a --delete ${scratch_dir}/blank/ ${scratch_dir}/checkjobs/


    if [ ! -f ${compdir}/final_eigencoeff ]; then


	    rm -f eigencoeff_Final

	    echo "#!/bin/bash" > eigencoeff_Final
            echo "#$ -S /bin/bash" >> eigencoeff_Final
	    echo 'set +o noclobber' >> eigencoeff_Final
	    echo 'set -e' >> eigencoeff_Final
	    echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> eigencoeff_Final
	    echo "cd ${scratch_dir}" >> eigencoeff_Final
	    echo "rm -rf ${scratch_dir}/${mcrcachedir}/eigencoeff_Final/" >> eigencoeff_Final
	    echo "mkdir ${scratch_dir}/${mcrcachedir}/eigencoeff_Final/" >> eigencoeff_Final
	    echo export MCR_CACHE_ROOT="${scratch_dir}/${mcrcachedir}/eigencoeff_Final/" >> eigencoeff_Final
	    echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/eigencoeff/will_lsf_final_eigencoeff ${all_motl_fn_prefix} ${iteration} ${num_eigen_vec} ${eigen_val_fn_prefix} ${xmatrix_batch_size} ${check_final_eigencoeff}" >> eigencoeff_Final
	    echo "rm -rf ${scratch_dir}/${mcrcachedir}/eigencoeff_Final/" >> eigencoeff_Final
	    echo 'exit' >> eigencoeff_Final
	    chmod +x eigencoeff_Final


	    qsub -cwd -N eigencoeff_Final -l mem_free=${mem_free},h_vmem=${mem_max} -o log_eigencoeff_Final -e error_eigencoeff_Final ./eigencoeff_Final
	    #bsub -M ${memlimit} -R "select[mem > ${memneed}]" -R "rusage[mem=${memusage}]" -q ${queue} -o log_eigencoeff_Final -e error_eigencoeff_Final ./eigencoeff_Final

	    echo "Waiting for eigencoefficient..."
	
	    ## Reset counter
	    check_final=0

	    while [ ${check_final} -lt 1 ]; do
		    sleep 10s
		    check_final=$(( $(ls -1 -f ./checkjobs/ | wc -l) - 2 ))
        done

	    ### Write out completion file
	    touch ${compdir}/final_eigencoeff

        ### Copy files to group share
        cp ${scratch_dir}/${eigen_val_fn_prefix}_${iteration}.em ${local_dir}/${eigen_val_fn_prefix}_${iteration}.em


        ### Cleanup ### 
        rm -f ${check_final_eigencoeff}
        rm -f eigencoeff_Final
        rm -f ${scratch_dir}/${eigen_val_fn_prefix}_${iteration}_*.em

    fi
    echo "EIGENCOEFFICIENT CALCULATION COMPLETE"

fi

################################################################################################################################################################
### K-MEANS CALCULATION
################################################################################################################################################################
if [ ${calculate_kmeans} -eq 1 ]; then


    if [ ! -f ${compdir}/paral_kmeans ]; then

        ### Initialize parallel job number
        d=1

        ### Loop to generate replicate k-means scripts
        while [ ${d} -le ${num_kmeans_runs} ]; do

	        procnum=${d}
	        echo "#!/bin/bash" > parallel_kmeans_${procnum}
                echo "#$ -S /bin/bash" >> parallel_kmeans_${procnum}
	        echo 'echo ${HOSTNAME}' >> parallel_kmeans_${procnum}
	        echo 'set +o noclobber' >> parallel_kmeans_${procnum}
	        echo 'set -e' >> parallel_kmeans_${procnum}
	        echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> parallel_kmeans_${procnum}
	        echo "cd ${scratch_dir}" >> parallel_kmeans_${procnum}
	        echo "rm -rf ${scratch_dir}/${mcrcachedir}/parallel_kmeans_${procnum}/" >> parallel_kmeans_${procnum}
	        echo "mkdir ${scratch_dir}/${mcrcachedir}/parallel_kmeans_${procnum}/" >> parallel_kmeans_${procnum}
	        echo export MCR_CACHE_ROOT="${scratch_dir}/${mcrcachedir}/parallel_kmeans_${procnum}" >> parallel_kmeans_${procnum}
          	echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/kmeans/will_kmeans_eigenvalues_function ${eigen_val_fn_prefix} ${iteration} ${temp_folder} ${kmeans_vectors} ${num_kmeans_clusters} ${procnum} ${check_paral_kmeans}" >> parallel_kmeans_${procnum}
	        echo "rm -rf ${scratch_dir}/${mcrcachedir}/parallel_kmeans_${procnum}/" >> parallel_kmeans_${procnum}
	        echo 'exit' >> parallel_kmeans_${procnum}
	        chmod +x parallel_kmeans_${procnum}

	        ((d++))

        done
        
        ((d--))

        rm -f parallel_kmeans_array
        touch parallel_kmeans_array
        #echo "#BSUB -J [1-${d}]" >> parallel_kmeans_array
        #echo "#BSUB -q ${queue}" >> parallel_kmeans_array
        #echo "${scratch_dir}/parallel_kmeans_"\$\{LSB_JOBINDEX\} >> parallel_kmeans_array
        echo "#!/bin/bash" >> parallel_kmeans_array
        echo "#$ -S /bin/bash" >> parallel_kmeans_array
        echo "#$ -t 1-${d}" >> parallel_kmeans_array
        echo "#$ -cwd" >> parallel_kmeans_array
        echo "${scratch_dir}/parallel_kmeans_"\$\{SGE_TASK_ID\} >> parallel_kmeans_array


        ##### SEND OUT JOB ##########################
        chmod +x parallel_kmeans_array
        qsub -N parallel_kmeans -l mem_free=${mem_free},h_vmem=${mem_max} -o log_parallel_kmeans -e error_parallel_kmeans ./parallel_kmeans_array
        #bsub -J "${scratch_dir}/parallel_kmeans_[1-${d}]" -M ${memlimit} -R "select[mem > ${memneed}]" -R "rusage[mem=${memusage}]" -q ${queue} -o log_parallel_kmeans -e error_parallel_kmeans ./parallel_kmeans_array
        echo "Parallel k-means calculations submitted"

        # Reset counter
        check_paral=0

        while [ ${check_paral} -lt ${num_kmeans_runs} ]; do
	        sleep 10s

	        check_paral=$(( $(ls -1 -f ./checkjobs/ | wc -l) - 2 ))
	        echo "Done ${check_paral} replicate k-means calculations out of ${num_kmeans_runs}"

        done


        ### Write out completion file
        touch ${compdir}/paral_kmeans
    fi
    echo "DONE K-MEANS CALCULATIONS!!!!"

    ### Remove scripts
    rm -f parallel_kmeans_*

    ### Clear checkjobs folder
    rsync -a --delete ${scratch_dir}/blank/ ${scratch_dir}/checkjobs/



    if [ ! -f ${compdir}/final_kmeans ]; then


	    rm -f kmean_Final

	    echo "#!/bin/bash" > kmean_Final
            echo "#$ -S /bin/bash" >> kmean_Final
	    echo 'set +o noclobber' >> kmean_Final
	    echo 'set -e' >> kmean_Final
	    echo 'export LD_LIBRARY_PATH="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:/lmb/home/public/matlab/jbriggs/bin/glnxa64:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"' >> kmean_Final
	    echo "cd ${scratch_dir}" >> kmean_Final
	    echo "rm -rf ${scratch_dir}/${mcrcachedir}/kmean_Final/" >> kmean_Final
	    echo "mkdir ${scratch_dir}/${mcrcachedir}/kmean_Final/" >> kmean_Final
	    echo export MCR_CACHE_ROOT="${scratch_dir}/${mcrcachedir}/kmean_Final/" >> kmean_Final
	    echo "time /net/bstore1/bstore1/briggsgrp/atan/software/Matlab_scripts/cluster_scripts/sge/compile/pca_tools/kmeans/will_kmeans_find_optimum_function ${all_motl_fn_prefix} ${pca_motl_fn_prefix} ${iteration} ${temp_folder} ${num_kmeans_runs} ${check_final_kmeans}" >> kmean_Final
	    echo "rm -rf ${scratch_dir}/${mcrcachedir}/kmean_Final/" >> kmean_Final
	    echo 'exit' >> kmean_Final
	    chmod +x kmean_Final


	    qsub -cwd -N kmean_Final -l mem_free=${mem_free},h_vmem=${mem_max} -o log_kmean_Final -e error_kmean_Final ./kmean_Final
	    #bsub -M ${memlimit} -R "select[mem > ${memneed}]" -R "rusage[mem=${memusage}]" -q ${queue} -o log_kmean_Final -e error_kmean_Final ./kmean_Final

	    echo "Looking for optimal k-means solution..."
	
	    ## Reset counter
	    check_final=0

	    while [ ${check_final} -lt 1 ]; do
		    sleep 10s
		    check_final=$(( $(ls -1 -f ./checkjobs/ | wc -l) - 2 ))
        done

	    ### Write out completion file
	    touch ${compdir}/final_kmeans

        ### Copy files to group share
        cp ${scratch_dir}/${pca_motl_fn_prefix}_${iteration}.em ${local_dir}/${pca_motl_fn_prefix}_${iteration}.em


        ### Cleanup ### 
        rm -f ${check_final_kmeans}
        rm -f kmean_Final
        rm -f ${scratch_dir}/${temp_folder}/tsumd_*.em
        rm -f ${scratch_dir}/${temp_folder}/kmeans_*.em

    fi
    echo "OPTIMAL K-MEANS SOLUTION FOUND!!!!"

fi
