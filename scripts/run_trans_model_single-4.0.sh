#!/bin/bash
#
#SBATCH -p shared
## uncomment to exclude nodes when using serial_requeue
## Old AMD processors and GPU nodes:
#SBATCH --exclude=holy2b[05101-05108,05201-05208,05301-05308,07101-07108,07201-07208,09101-09108,09201-09208],holygpu[01-16],aaggpu[01-08],aagk80gpu[01-64],holyseasgpu[01-13],supermicgpu01
#
#SBATCH --mem=8096          # in MB, pool of memory for all cores
#SBATCH -t 0-8:00           # D-HH:MM format
#SBATCH -n 1                # # cores 
#SBATCH -N 1                # # compute nodes
#SBATCH -o transm_%A_%a.out
#SBATCH -e transm_%A_%a.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=esurface@hsph.harvard.edu

print_usage() {
	echo "usage: $0 <transm> <input>"
}

if [[ -z $1 || ! -e $1 ]]; then
	print_usage
	exit 1
fi
transm=$1

# setup the cdm batch directory
if [[ -z $2 || ! -e $2 ]]; then
	print_usage
	echo "Missing xml input file directory"
	exit 1
fi
batch_dir=$(readlink -f $2)
results_dir=$batch_dir/results
rm -rf $results_dir #clean up old results

# make our directory on /scratch and copy files to it
work_dir=/scratch/$USER/$SLURM_JOBID
mkdir -p $work_dir 

find $batch_dir -name "*.xml" -exec cp -rf {} $work_dir \;
find $batch_dir -name "*.in" -exec cp -rf {} $work_dir \;

# print some diagnostic stuff out
echo "batch dir is $batch_dir"
echo "working data dir at $work_dir"
echo "results will be in $results_dir"
echo "running $transm $(ls $work_dir/*.xml)"

module load gcc
module load gperftools

$transm $work_dir

if [[ $? -ne 0 ]]; then
	echo "Error running the model"
    exit 1
fi

echo "copying results/ back to $results_dir"
mkdir -p $results_dir
mv $work_dir/results/* $results_dir

rm -rf $work_dir 

echo "Finished!"
exit 0
