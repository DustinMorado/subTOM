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
# If the number of alignment jobs is greater than 1000, this script
# automatically splits the job into multiple arrays and launches them. It will
# not run if you have more than 4000 alignment jobs, as this is the current
# maximum per user.
#
# This subtomogram averaging script uses three MATLAB compiled scripts below:
# - will_scan_angles_exact6
# - will_parallel_create_average3
# - will_averageref_weighted2
# WW 02-2016
################################################################################
# I do NOT change anything in the MATLAB scripts and only re-compile them with
# the LMB MATLAB. To let it run on the LMB cluster, the job submitting command
# is changed from bsub to qsub.
#
# K.Q. at the Briggs Lab
# 01-2017
################################################################################
set -e           # Crash on error
set -o nounset   # Crash on unset variables
################################################################################
#                                 DIRECTORIES                                  #
################################################################################
# Root folder on the scratch
scratch_dir="${nfs6}/VMV013/20170404/subtomo/bin2/even"

# Folder on group shares
local_dir="${bstore1}/VMV013/20170404/subtomo/bin2/even/local"

# MRC directory for each job
mcrcachedir='mcr'

# A completion file will be written out after each step, so this script can be
# re-run after a crash and figure out where to start from.
compdir='complete'

# Directory for scripts
scriptdir=${bstore1}/software/clusterscripts/

# Directory for executables
execdir=${bstore1}/software/clusterscripts/Matlab_compiled

################################################################################
#                                  VARIABLES                                   #
################################################################################
# Alignment executable
aliexec=${execdir}/will_scan_angles_exact6

# Parallel Averaging executable
paral_avgexec=${execdir}/will_parallel_create_average3

# Final Averaging executable
avgexec=${execdir}/will_averageref_weighted2
# listdir script (???)
listdir=${scriptdir}/listdir/listdir

################################################################################
#                                MEMORY OPTIONS                                #
################################################################################
# The amount of memory your job requires
memfree_ali='2G'

# The upper bound on the amount of memory your job is allowed to use
memmax_ali='3G'

# The amount of memory your job requires
memfree_avg='2G'

# The upper bound on the amount of memory your job is allowed to use
memmax_avg='3G'

# The amount of memory your job requires
memfree_other='2G'

# The upper bound on the amount of memory your job is allowed to use
memmax_other='3G'

################################################################################
#                              OTHER LSF OPTIONS                               #
################################################################################
# BE CAREFUL THAT THE NAME DOESN'T CORRESPOND TO THE BEGINNING OF ANY OTHER FILE
job_name='vmv013'

# write 'no' if you don't want to receive email notification for errors or for
# completed job. Otheriwise write the email address you want notifications to be
# sent. You can filter the emails using their subject starts ERROR: or DONE: and
# are always sent from your embl account.
email='no'

# Maximum number of jobs per array
array_max=1000

# Maximum number of jobs per user
max_jobs=4000

################################################################################
#                                                                              #
#                    SUBTOMOGRAM AVERAGING WORKFLOW OPTIONS                    #
#                                                                              #
################################################################################
#                           PARALLELIZATION OPTIONS                            #
################################################################################
# The index of the reference to start from : input will be
# reference_startindx.em and motilvelist_startindx.em (define as integer e.g.
# start_iteration=3)
start_iteration=1

# Number iterations (big loop) to run: final output will be
# reference_startindx+iterations.em and motilvelist_startindx+iterations.em
iterations=1

# Total number of particles
num_ptcls=26870

# Number of particles in each parallel subtomogram alignment job (define as
# integer e.g. batchnumberofparticles=3)
ali_batch_size=100

# Number of particles in each parallel subtomogram averaging job
avg_batch_size=100

################################################################################
#                                 FILE OPTIONS                                 #
################################################################################
# Relative path and name of the motivelist of the single particle (e.g.
# part_n.em will have a motl_n_iter.em , the variable will be written as a
# string e.g. particlemotlfilename='sub-directory/motl')
particlemotlfilename='motls/motl'

# Relative path and name of the concatenated motivelist of all particles (e.g.
# allmotl_iter.em , the variable will be written as a string e.g.
# allmotlfilename='sub-directory/allmotl')
allmotlfilename='combinedmotl/allmotl'

# Relative path and name of the reference volumes (e.g. ref_iter.em , the
# variable will be written as a string e.g. refilename='sub-directory/ref')
refilename='ref/ref'

# Relative path and name of the subtomograms (e.g. part_n.em , the variable will
# be written as a string e.g. particlefilename='sub-directory/part')
particlefilename='subtomograms/subtomo'

# Relative path and name of the alignment mask
mask='otherinputs/mask128_r52_h52_g3_pos666670.em'

# Apply mask to subtomograms (1=yes, 0=no)
masksubtomo=1

# Relative path and name of the cross-correlation mask this defines the maximum
# shifts in each direction
ccmask='otherinputs/ccmask128_r6.em'

# Relative path and name of the wedgelist
wedgelist='otherinputs/wedgelist013.em'

################################################################################
#                       ALIGNMENT AND AVERAGING OPTIONS                        #
################################################################################
# Angular increment in degrees, applied during the cone-search, i.e. psi and
# theta (define as real e.g. angincr=3)
angincr=2

# Number of angular iterations, applied to psi and theta  (define as integer
# e.g. angiter=3)
angiter=3

# Angular increment for phi in degrees, (define as real e.g. phi_angincr=3)
phi_angincr=2

# Number of angular iterations for phi, (define as integer e.g. phi_angiter=3)
phi_angiter=3

# High pass filter (in transform units (pixels): calculate as
# (boxsize*pixelsize)/(resolution_real) (define as integer e.g. hipass=2)
hipass=1

# Low pass filter (in transform units (pixels): calculate as
# (boxsize*pixelsize)/(resolution_real) (define as integer e.g. hipass=30), has
# a Gaussian dropoff of ~2 pixels
lowpass=17

# Symmetry, if no symmetry nfold=1 (define as integer e.g. nfold=3)
nfold=2

# Threshold for cross correlation coefficient. Only particles with ccc_new >
# threshold will be added to new average (define as real e.g. threshold=0.5).
# These particles will still be aligned at each iteration
threshold=0

# Particles with that number in position 20 of motivelist will be added to new
# average (define as integer e.g. iclass=1). NOTES: Class 1 is ALWAYS added.
# Negative classes and class 0 are never added.
iclass=1

################################################################################
#                        PARALLEL CHECKJOB FILE OPTIONS                        #
################################################################################
# Checkjob name for alignment
checkfileali='checkjobs/checkfileali'

# Checkjob name for averaging
checkjobavg='checkjobs/checkjobavg'

################################################################################
# Initialize blank folder
rm -rf ${scratch_dir}/blank
mkdir ${scratch_dir}/blank

# Check number of jobs
num_ali_batch=$(((num_ptcls + ali_batch_size - 1) / ali_batch_size))
num_avg_batch=$(((num_ptcls + avg_batch_size - 1) / avg_batch_size))
if [[ ${num_ali_batch} -gt ${max_jobs} || ${num_avg_batch} -gt ${max_jobs} ]]
then
    echo " TOO MANY JOBS!!!!!  I QUIT!!!"
    exit 1
fi

################################################################################
#                                                                              #
#                        SUBTOMOGRAM AVERAGING WORKFLOW                        #
#                                                                              #
################################################################################
end_iteration=$((start_iteration + iterations - 1))
for ((iteration=start_iteration; iteration <= end_iteration; iteration++))
do
    echo "            ITERATION number ${iteration}"
################################################################################
#                            SUBTOMOGRAM ALIGNMENT                             #
################################################################################
    if [[ ! -f ${compdir}/subtomo_ali_${iteration} ]]
    then
        ### Re-initialize checkjobs folder
        rm -rf ${scratch_dir}/checkjobs
        mkdir ${scratch_dir}/checkjobs

        ##  Generate and launch array files
        # Calculate number of job scripts needed
        num_ali_jobs=$(((num_ali_batch + array_max - 1) / array_max))
        array_start=1     # Starting index of array

        # Generate array files
        for ((job_idx=1; job_idx <= num_ali_jobs; job_idx++))
        do
            # Calculate end job
            array_end=$((array_start + array_max - 1)) # Ending job of array
            if [[ ${array_end} -gt ${num_ali_batch} ]]
            then
                array_end=${num_ali_batch}
            fi

            ### Write out script for each node
            cat > ${job_name}_ali_array_${iteration}_${job_idx} <<-ALIJOB
#!/bin/bash
#$ -N ${job_name}_ali_array_${iteration}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${memfree_ali},h_vmem=${memmax_ali}
#$ -o log_${job_name}_ali_array_${iteration}_${job_idx}
#$ -e error_${job_name}_ali_array_${iteration}_${job_idx}
#$ -t ${array_start}-${array_end}
set +o noclobber
set -e

echo \${HOSTNAME}
ldpath=/lmb/home/public/matlab/jbriggs/runtime/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/bin/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=\${ldpath}
cd ${scratch_dir}
batch_idx=\${SGE_TASK_ID}
MCRDIR=${scratch_dir}/${mcrcachedir}
rm -rf \${MCRDIR}/${job_name}_ali_\${batch_idx}
mkdir \${MCRDIR}/${job_name}_ali_\${batch_idx}
export MCR_CACHE_ROOT=\${MCRDIR}/${job_name}_ali_\${batch_idx}
ptcl_start=\$(((${ali_batch_size} * (batch_idx - 1)) + 1))
time ${aliexec} \\
    \${ptcl_start} \\
    ${iteration} \\
    ${ali_batch_size} \\
    ${refilename} \\
    ${allmotlfilename} \\
    ${particlemotlfilename} \\
    ${particlefilename} \\
    ${wedgelist} \\
    ${mask} \\
    ${masksubtomo} \\
    ${ccmask} \\
    ${checkfileali} \\
    ${angincr} \\
    ${angiter} \\
    ${phi_angincr} \\
    ${phi_angiter} \\
    ${hipass} \\
    ${lowpass} \\
    ${nfold} \\
    ${threshold} \\
    ${iclass}
rm -rf \${MCRDIR}/${job_name}_ali_\${batch_idx}
ALIJOB

            qsub ${job_name}_ali_array_${iteration}_${job_idx}
            array_start=$((array_start + array_max))
        done

        echo "Aligning subtomograms in iteration number ${iteration}"
################################################################################
#                              ALIGNMENT PROGRESS                              #
################################################################################
        num_ali_ptcls=0
        while [[ ${num_ali_ptcls} -lt ${num_ptcls} ]]
        do
            sleep 10s
            num_ali_ptcls=$(($(${listdir} ./checkjobs/ | wc -l) - 2))
            echo "Number of subtomograms aligned:"
            echo "${num_ali_ptcls} out of ${num_ptcls}"
        done

        ### Write out completion file
        touch ${compdir}/subtomo_ali_${iteration}
    fi

    ### Remove align scripts
    #rm -f ${job_name}_ali_array_${iteration}_*

    ### Clear checkjobs folder
    mv ${scratch_dir}/checkjobs \
        ${scratch_dir}/checkjobs_subtomo_ali_${iteration}
    mkdir ${scratch_dir}/checkjobs
    echo "DONE ALIGNMENT in iteration number ${iteration}"
################################################################################
#                              PARALLEL AVERAGING                              #
################################################################################
    if [[ ! -f ${compdir}/paral_avg_${iteration} ]]
    then
        # Generate and launch array files
        # Calculate number of job scripts needed
        num_avg_jobs=$(((num_avg_batch + array_max - 1) / array_max))
        array_start=1

        ### Loop to generate parallel alignment scripts
        for ((job_idx=1; job_idx <= num_avg_jobs; job_idx++))
        do
            array_end=$((array_start + array_max - 1))
            if [[ ${array_end} -gt ${num_avg_batch} ]]
            then
                array_end=${num_avg_batch}
            fi

            cat > ${job_name}_paral_avg_array_${iteration}_${job_idx}<<-PAVGJOB
#!/bin/bash
#$ -N ${job_name}_paral_avg_${iteration}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${memfree_avg},h_vmem=${memmax_avg}
#$ -o log_${job_name}_paral_avg_array_${iteration}_${job_idx}
#$ -e error_${job_name}_paral_avg_array_${iteration}_${job_idx}
#$ -t ${array_start}-${array_end}
set +o noclobber
set -e

echo \${HOSTNAME}
ldpath=/lmb/home/public/matlab/jbriggs/runtime/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/bin/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=\${ldpath}
cd ${scratch_dir}
batch_idx=\${SGE_TASK_ID}
MCRDIR=${scratch_dir}/${mcrcachedir}
rm -rf \${MCRDIR}/${job_name}_paral_avg_\${batch_idx}
mkdir \${MCRDIR}/${job_name}_paral_avg_\${batch_idx}
export MCR_CACHE_ROOT=\${MCRDIR}/${job_name}_paral_avg_\${batch_idx}
ptcl_start=\$(((${avg_batch_size} * (batch_idx - 1)) + 1))
time ${paral_avgexec} \\
    \${ptcl_start} \\
    ${avg_batch_size} \\
    ${num_ptcls} \\
    ${iteration} \\
    ${particlemotlfilename} \\
    ${allmotlfilename} \\
    ${refilename} \\
    ${particlefilename} \\
    ${wedgelist} \\
    ${iclass} \\
    \${batch_idx} \\
    ${checkjobavg}
rm -rf \${MCRDIR}/${job_name}_paral_avg_\${batch_idx}
PAVGJOB
            qsub ${job_name}_paral_avg_array_${iteration}_${job_idx}
            array_start=$((array_start + array_max))
        done

        echo "Parallel average in iteration number ${iteration}"
################################################################################
#                         PARALLEL AVERAGING PROGRESS                          #
################################################################################
        num_ptcl_avgs=0
        while [[ ${num_ptcl_avgs} -lt ${num_avg_batch} ]]
        do
            sleep 10s
            num_ptcl_avgs=$(($(${listdir} ./checkjobs/ | wc -l) - 2))
            echo "Number of parallel averages generated:"
            echo "${num_ptcl_avgs} out of ${num_avg_batch}"
        done

        ### Write out completion file
        touch ${compdir}/paral_avg_${iteration}
    fi

    ### Remove scripts
    #rm -f ${job_name}_paral_avg_array_${iteration}_*

    ### Clear checkjobs folder
    mv ${scratch_dir}/checkjobs \
        ${scratch_dir}/checkjobs_paral_avg_${iteration}
    mkdir ${scratch_dir}/checkjobs
    echo "DONE PARALLEL AVERAGE in iteration number ${iteration}"
################################################################################
#                                FINAL AVERAGE                                 #
################################################################################
    if [[ ! -f ${compdir}/final_avg_${iteration} ]]
    then
        rm -f ${scratch_dir}/checkjob_aver.txt

        cat > ${job_name}_avg_${iteration} <<-AVGJOB
#!/bin/bash
#$ -N ${job_name}_avg_${iteration}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${memfree_avg},h_vmem=${memmax_avg}
#$ -o log_${job_name}_avg_${iteration}
#$ -e error_${job_name}_avg_${iteration}
set +o noclobber
set -e

echo \${HOSTNAME}
ldpath=/lmb/home/public/matlab/jbriggs/runtime/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/bin/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/sys/os/glnxa64
ldpath=\${ldpath}:/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64
export LD_LIBRARY_PATH=\${ldpath}
cd ${scratch_dir}
MCRDIR=${scratch_dir}/${mcrcachedir}/${job_name}_avg_iteration
rm -rf \${MCRDIR}
mkdir \${MCRDIR}
export MCR_CACHE_ROOT=\${MCRDIR}
time ${avgexec} \\
    ${refilename} \\
    ${allmotlfilename} \\
    ${avg_batch_size} \\
    ${num_ptcls} \\
    ${iteration} \\
    ${iclass}
rm -rf \${MCRDIR}
AVGJOB

        qsub ${job_name}_avg_${iteration}
        echo "Final average in iteration number ${iteration}"
################################################################################
#                            FINAL AVERAGE PROGRESS                            #
################################################################################
        check_avg=0
        echo "Waiting for the final average ..."
        while [[ ${check_avg} -lt 1 ]]
        do
            sleep 10s
            check_avg=$(ls ${scratch_dir}/checkjob_aver.txt 2>/dev/null | wc -l)
        done

        ### Write out completion file
        touch ${compdir}/final_avg_${iteration}

        ### Copy file to group share
        next_iteration=$((iteration + 1))
        cp ${scratch_dir}/${allmotlfilename}_${next_iteration}.em \
            ${local_dir}/${allmotlfilename}_${next_iteration}.em
        cp ${scratch_dir}/${refilename}_${next_iteration}.em \
            ${local_dir}/${refilename}_${next_iteration}.em
    fi

    ### Clean up from the iteration
    rm -f ${job_name}_avg_${iteration}
    rm -f ${scratch_dir}/checkjob_aver.txt
    rm -f ${scratch_dir}/${refilename}_*_*.em
    rm -f ${scratch_dir}/otherinputs/wei_*_*.em
    rm -f ${allmotlfilename}_*_*.em

    echo "AVERAGE DONE IN ITERATION NUMBER ${iteration}"
done

if [[ ${email} != 'no' ]]
then
    echo " " > ${scratch_dir}/check.log
    Mail -s 'DONE: job '"${job_name}"' in directory '"${scratch_dir}" \
        ${email} < ${scratch_dir}/check.log
    rm -f ${scratch_dir}/check.log
fi
exit
