#!/bin/bash
set -e           # Crash on error
set -o nounset   # Crash on unset variables

## lmb_noise_extract.sh
# A script for extraction of tomograms on the cluster. This script takes an
# input number of cores, and each core extract one tomogram at a time as written
# in a specified row of the allmotl. Parallelization works by writing a start
# file upon openinig of a tomo, and a completion file. After tomogram
# extraction, it moves on to the next tomogram that hasn't been started.
#
# WW 09-2016

################################################################################
# This subtomogram extraction script is modified from "lsf_tomo_extract.sh". It
# calls one MATLAB compiled script:
# dustin_extract_noise
#
# I do NOT change anything in the MATLAB scripts and only re-compile them with
# the LMB MATLAB. To let it run on the LMB cluster, the job submitting command
# is changed from bsub to qsub.
#
# K.Q. at the Briggs Lab
# 01-2017

##### FILE OPTIONS #####
## nfs6 - group server. Folders where the tomograms are stored
tomo_folder="${bstore1}/VMV013/20170528/data/tomos/bin8"
## Number of digits in the tomogram numbers
## (tomograms should be named tomonumber.rec)
tomo_digits=2
## nfs6 - SSD server. Root folder for subtomogram extraction. Other paths are
## relative to this one.
rootdir="${nfs6}/VMV013/20170528/subtomo/bin8"
## Row number of allmotl for tomogram numbers.
tomo_row=7
# Relative path to allmotl file from root folder.
allmotlfilename='combinedmotl/allmotl_1.em'
# Total number of tomograms in allmotl file
n_tomos=16

##### EXTRACTION OPTIONS #####
## Size of subtomogram in pixels
subtomosize=36
## Number of noise particles to extract
num_noise=100
## Relative path and filename for output subtomograms
noisename='otherinputs/ampspec'

##### PARALLELIZATION OPTIONS #####
## Number of cores to process on
n_cores=16
## Path and root of starting check file name
checkstartname='complete/noise_checkstart'
## Path and root of completion check file name
checkdonename='complete/noise_checkdone'

##### SET MRC_CACHE_ROOT OPTIONS #####
mcrcachedir='mcr';

##### SET MEMORY OPTIONS #####
#queue_name='medium_priority'
# If you use more than this, you will be kicked out
#memlimit=6000
# The amount of memory to reserve
#memusage=6000
# The amount of memory the node should have available
#memneed=7000

# The amount of memory your job requires
memfree='10G'
# The upper bound on the amount of memory your job is allowed to use
memmax='15G'
if [[ ${memfree%G} -ge 24 ]]; then
    dedmem=',dedicated=12'
else
    dedmem=''
fi

##### OTHER LSF OPTIONS #####
# BE CAREFUL THAT THE NAME DOESN'T CORRESPOND
# TO THE BEGINNING OF ANY OTHER FILE
job_name='VMV013_noise_extract'

################################################################################
# Check check!!
if [ ! -d "checkjobs" ]; then
    mkdir checkjobs
fi

if [ ! -d "mcr" ]; then
    mkdir mcr
fi

### Initialize parallel job array
rm -f ${job_name}_array
cat > ${job_name}_array <<-JOBDATA
#!/bin/bash
#$ -N ${job_name}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=${memfree},h_vmem=${memmax}${dedmem}
#$ -e error_${job_name}_array
#$ -o log_${job_name}_array
#$ -t 1-${n_cores}
set +C # Turn off prevention of redirection file overwriting
set -e # Turn on exit on error
set -f # Turn off filename expansion (globbing)
echo \${HOSTNAME}
execdir="\${bstore1}/software/clusterscripts/Matlab_compiled"
ldpath="/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"
ldpath="/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:\${ldpath}"
ldpath="/lmb/home/public/matlab/jbriggs/bin/glnxa64:\${ldpath}"
ldpath="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:\${ldpath}"
export LD_LIBRARY_PATH=\${ldpath}
cd ${rootdir}
rm -rf ${rootdir}/${mcrcachedir}/${job_name}_\${SGE_TASK_ID}
mkdir ${rootdir}/${mcrcachedir}/${job_name}_\${SGE_TASK_ID}
export MCR_CACHE_ROOT="${rootdir}/${mcrcachedir}/${job_name}_\${SGE_TASK_ID}"
time \${execdir}/dustin_extract_noise \\
    ${tomo_folder} ${tomo_digits} ${rootdir} ${tomo_row} \\
    ${noisename} ${allmotlfilename} ${subtomosize} ${num_noise} \\
    ${checkstartname} ${checkdonename}
rm -rf ${rootdir}/${mcrcachedir}/${job_name}_\${SGE_TASK_ID}
JOBDATA

##### SEND OUT JOB ##########################
qsub ./${job_name}_array

echo "Parallel tomogram extraction submitted"

# Reset counter
check_start=0
check_done=0
# Wait for jobs to finish
while [ ${check_done} -lt ${n_cores} ]; do
    sleep 60s
    check_start=$(ls ${rootdir}/${checkstartname}_* 2>&1 |\
                  grep -v '^ls:' | wc -w)
    echo "Number of tomograms started ${check_start} out of ${n_tomos}"
    check_done=$(ls ${rootdir}/${checkdonename}_* 2>&1 |\
                 grep -v '^ls:' | wc -w)
    echo "Number of tomograms extracted ${check_done} out of ${n_tomos}"
done

### Remove scripts
#rm -f ${job_name}_array
rm -f checkjobs/*
