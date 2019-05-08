#!/bin/bash
#
#SBATCH -p shared
## uncomment to exclude nodes when using serial_requeue
## Old AMD processors and GPU nodes:
#SBATCH --exclude=holy2b[05101-05108,05201-05208,05301-05308,07101-07108,07201-07208,09101-09108,09201-09208],holygpu[01-16],aaggpu[01-08],aagk80gpu[01-64],holyseasgpu[01-13],supermicgpu01
#
#SBATCH --mem=64G          # in MB, pool of memory for all cores
#SBATCH -t 0-4:00           # D-HH:MM format
#SBATCH -n 1                # # cores 
#SBATCH -N 1                # # compute nodes
#SBATCH -o output/batch_%A_%a.out
#SBATCH -e output/batch_%A_%a.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=esurface@hsph.harvard.edu

module load python/3.4.1-fasrc01
source activate ody2

set -x
python analyse_batches.py -f -s 2002 2012 ../Scenarios/00_StatusQuo postcalib_032614.out 00_StatusQuo_REDO_2012.xlsx
