#!/bin/bash
#
#SBATCH -p shared
#SBATCH --mem=8096          # in MB, pool of memory for all cores
#SBATCH -t 0-6:00          # D-HH:MM format
#SBATCH -n 1                # # cores 
#SBATCH -N 1                # # compute nodes
#SBATCH -o output/batch_%A_%a.out
#SBATCH -e output/batch_%A_%a.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=esurface@hsph.harvard.edu

# load lmod script -- required for running via crontab
source /usr/local/bin/new-modules.sh

# grab our current directory
start_dir=$PWD

print_usage() {
	echo "usage: $0 <transm> <input_prefix> <cepac_dir> [config]"
}

if [ -z $1 ]; then
	print_usage
	echo "No transm version"
	exit 1
fi
transm=$1

# setup the cdm batch directory
if [ -z $2 ]; then
	print_usage
	echo "Missing xml input file or directory"
	exit 1
fi

# setup the cepac input directory
if [ -z $3 ]; then
	print_usage
	echo "No cepac input file directory"
	exit 1
fi
cepac_dir=$3


if [[ -n $4 && -e $(readlink -f $4) ]]; then
	CONFIG=$(readlink -f $4)
	# future: smanage config --get --config NEXT_RUN_ID > NEXT_RUN_ID
	source $CONFIG
	RUN_ID=$(($NEXT_RUN_ID + $SLURM_ARRAY_TASK_ID))
else
	RUN_ID=$SLURM_ARRAY_TASK_ID
fi

batch_dir=$start_dir/$2"${RUN_ID}"

results="results"
results_dir=$batch_dir/$results
rm -rf $results_dir #clean up old results

mkdir -p $start_dir/output

# make our directory on /scratch and copy files to it
work_dir=/scratch/$USER/$SLURM_JOBID/"${RUN_ID}"
mkdir -p $work_dir 

find $batch_dir -name "*.xml" -exec cp -rf {} $work_dir \;
find $cepac_dir -name "*.in" -exec cp -rf {} $work_dir \;

# print some diagnostic stuff out
echo "starting dir is $start_dir"
echo "working on $(hostname):$work_dir"
echo "results will be in $results_dir"
echo "running $transm $work_dir"

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
