#!/bin/bash
args=("$@")

# Parse inputs
if [ "$#" -ne "3" ]; then
    cat <<-USAGE
	
	Error: Command takes exactly 3 arguments!
	Usage: Command.sh  IterationNumber  AllmotlFilename  NumberOfCores
	Example: ./command.sh 1 combinedmotl/allmotl 3
	
	USAGE
    exit 1
fi

iteration=${args[0]}
allmotlname=${args[1]}
num_cores=${args[2]}
motls="motls/motl"
checkjobs="checkjobs/checksplitmotl"
rootdir=$(pwd)
job_name="VMV013_splitmotl"

if [[ "$num_cores" -le "0" ]]; then
    rm -rf ${checkjobs}* ${job_name}_array
    exit 0
fi

# remove previous job scripts
rm -f ${job_name}_array
### Generate array script
cat > ${job_name}_array <<-JOBDATA
#!/bin/bash
#$ -N ${job_name}
#$ -S /bin/bash
#$ -V
#$ -cwd
#$ -l mem_free=2G,h_vmem=4G
#$ -e error_splitmotl
#$ -o log_splitmotl
#$ -t 1-${num_cores}
set +C # Turn off prevention of redirection file overwriting
set -e # Turn on exit on error
set -f # Turn off filename expansion (globbing)
echo \${HOSTNAME}
execdir="${bstore1}/software/clusterscripts/Matlab_compiled"
ldpath="/lmb/home/public/matlab/jbriggs/sys/opengl/lib/glnxa64"
ldpath="/lmb/home/public/matlab/jbriggs/sys/os/glnxa64:\${ldpath}"
ldpath="/lmb/home/public/matlab/jbriggs/bin/glnxa64:\${ldpath}"
ldpath="/lmb/home/public/matlab/jbriggs/runtime/glnxa64:\${ldpath}"
export LD_LIBRARY_PATH=\${ldpath}
cd ${rootdir}
\${execdir}/will_lsf_splitmotl_parallel \\
    $iteration $allmotlname $motls \\
    $num_cores \${SGE_TASK_ID} $checkjobs
JOBDATA

qsub ${job_name}_array

echo "Parallel split motl job submitted!"
check=0
while [ $check -lt $num_cores ]; do
    sleep 10s
    check=$(ls ./checkjobs/ | wc -l)
    echo "$check jobs out of $num_cores completed..."
done
echo "Parallel split motl job done!"
rm -rf ${checkjobs}*
