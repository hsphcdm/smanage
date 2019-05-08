#!/bin/bash
#
#SBATCH -p shared 
#SBATCH --mem=120G          # in MB, pool of memory for all cores
#SBATCH -t 0-8:00           # D-HH:MM format
#SBATCH -n 1                # # cores 
#SBATCH -N 1                # # compute nodes
#SBATCH -o output/batch_%A_%a.out
#SBATCH -e output/batch_%A_%a.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=esurface@hsph.harvard.edu

usage(){
echo "$0: [-d|--dir <directory>] [-s|--start_year <YYYY>] [-e|--end_year <YYYY>] [--single]"
}

while test $# -gt 0
do
    case "$1" in
        -d|--dir)
            shift
            if [ -z $1 ]; then
               usage
               exit 1
            fi
            start_dir=$1
            ;;
        -h|--help)
            usage
            exit 1
            ;;
        -s|--start_year)
            shift
            if [ -z $1 ]; then
               usage
               exit 1
            fi
            start_year=$1
            ;;
        -e|--end_year)
            shift
            if [ -z $1 ]; then
               usage
               exit 1
            fi
            end_year=$1
            ;;
        --single)
            single=1
            ;;
    esac
    shift
done

# grab our current directory
if [[ -z $start_dir ]]; then
	start_dir=$(pwd)
else
    if [[ ! -d $start_dir ]]; then
        echo "$1 is not a directory"
        exit 1
    fi
fi
dir_name=$(basename $start_dir)

if [[ -z $start_year ]]; then
    start_year=2014
fi

if [[ -z $end_year ]]; then
    end_year=2029
fi

module load python/3.4.1-fasrc01
source activate ody2

if [[ -n $single ]]; then
    python analyse_batches.py -f $start_year $end_year $start_dir postcalib_032614.out ${dir_name}_REDO_${end_year}.xlsx
else
    python analyse_batches.py -f -q 00_StatusQuo $start_year $end_year $start_dir postcalib_032614.out ${dir_name}_REDO_${end_year}.xlsx
fi
