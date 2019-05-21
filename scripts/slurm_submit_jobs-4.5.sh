#!/bin/bash
# debug option if uncommented
#set -x
shopt -s nullglob   # empty directory will return empty list

usage() {
echo "usage: $0 [--config <CONFIG_FILE>] [--debug] [--help]"
}

### ARGS ###
SBATCH=/usr/bin/sbatch
DEBUG=
while test $# -gt 0
do
    case "$1" in
          --config)
              shift
              if [[ -d $1 ]]; then
                  echo "no config file $1"
                  exit 1
              fi
              echo $(basename $0) "using config file:" $(basename $1)
              CONFIG=$1
              source $CONFIG
              ;;
          --debug)
              DEBUG=/usr/bin/echo
              ;;
          --help)
              usage
              exit 0
              ;;
          *)
              if [[ -n $1 ]]; then
                  BATCH_DIR=$PWD/$1
                  if [[ ! -d $1 ]]; then
                      echo $0 "$BATCH_DIR does not exist"
                      exit 1
                  fi
               fi
               ;;
    esac
    shift
done

if [[ -z $BATCH_DIR ]]; then
BATCH_DIR=$PWD
fi
echo "Checking $BATCH_DIR for xml files"
if [[ -z $(find $BATCH_DIR -name "*.xml" -print -quit) ]]; then
    echo "No xml files in $BATCH_DIR"
    exit 1
fi

top=$(dirname $(readlink -f $0))

if [ -z $JOB_NAME ]; then
JOB_NAME=$(basename $BATCH_DIR)
fi

cd $BATCH_DIR

# the vars below can be set as env or config vars
# all path vars should be relative to $batch_dir
if [[ -z $PARTITION ]]; then
echo Running jobs on serial_requeue
PARTITION="serial_requeue"
fi
if [[ -z $ARRAY ]]; then
echo Array not defined starting at 0
ARRAY="0"
fi
if [[ -n $RESERVATION ]]; then
reservation_arg="--reservation=\"$RESERVATION\""
fi
if [[ -z $BIN ]]; then
BIN=/n/seage_lab/model_versions/release/transm-v4.5.0
fi
if [[ -z $INFILES ]]; then
INFILES=/n/seage_lab/MIAMI/runs/INFILES
fi
if [[ -z $NEXT_RUN_ID ]]; then
NEXT_RUN_ID=0
fi
if [[ -z $BATCH_PREFIX ]]; then
BATCH_PREFIX=batch_
fi

files=(${BATCH_DIR}/${BATCH_PREFIX})
if [[ -z ${files} ]] || [[ -d ${files[0]} ]] ; then
    echo "No files in $BATCH_DIR with prefix $BATCH_PREFIX"
    exit 1
fi

if [[ -z $SLURM_SCRIPT ]]; then 
SBATCH_SCRIPT=/n/seage_lab/hsphcdm/smanage/scripts/run_trans_model_batches-4.5.sh
fi
if [[ ! -f $SBATCH_SCRIPT ]]; then
   echo "Missing or incorrect path to sbatch script $SBATCH_SCRIPT"
   exit 1
fi

# we are forced to copy the script to the batch directory for
# it to produce output in the same directory
#if [[ ! -f $BATCH_DIR/$SLURM_SCRIPT ]]; then
#ln -s $SBATCH_SCRIPT $BATCH_DIR/$SBATCH_SCRIPT
#fi

output_dir=$BATCH_DIR/output
$DEBUG mkdir -p $output_dir

OUTPUT=$($DEBUG $SBATCH -D $BATCH_DIR -p $PARTITION --job-name="$JOB_NAME" --array="$ARRAY" $reservation_arg $SBATCH_SCRIPT $BIN $BATCH_PREFIX $NEXT_RUN_ID $INFILES)

if [[ $? -ne 0 ]]; then
echo ERROR: $OUTPUT
exit 1
fi

# read the new job number from the sbatch output
echo $OUTPUT
IFS=" " read -ra split <<< "$OUTPUT"
job_id=${split[3]}

# create a report script -- only do this once
if [[ -z $CONFIG ]]; then
echo "creating report ${JOB_NAME}_report.sh"
$DEBUG $HOME/reports/create_report.sh --dir $output_dir --name ${JOB_NAME} $job_id
else
echo "Appending $job_id to $(basename $CONFIG)"
$DEBUG $HOME/reports/create_report.sh --append $CONFIG $job_id
fi

