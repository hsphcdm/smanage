# debug option if uncommented
#set -x
shopt -s nullglob   # empty directory will return empty list

top=$(dirname $(readlink -f $0))

batch_dir=$(pwd)
if [[ -e $1 ]]; then
    if [[ -d $1 ]]; then
        batch_dir=$(readlink -f $1)
    else
        echo "$batch_dir does not exist"
        exit 1
    fi
fi

# we are forced to copy the script to the batch directory for
# it to produce output in the same directory
script=run_trans_model_batches-3.6.sh
if [[ ! -f $batch_dir/$script ]]; then
ln -s $top/$script $batch_dir/$script
fi

batch_name=$(basename $batch_dir)
echo "Creating batch array run in $batch_name"
cd $batch_dir

# the vars below can be set as env or script vars
# all path vars should be relative to $batch_dir
if [[ -z $partition ]]; then
partition="serial_requeue"
fi
if [[ -z $array ]]; then
array="0-563"
fi
if [[ -z $bin ]]; then
bin=/n/seage_lab/model_versions/release/transm-v3.6.2
fi
if [[ -z $infiles ]]; then
infiles=/n/seage_lab/esurface/90-90-90/INFILES
fi
if [[ -z $batch ]]; then
batch=batch
fi

output_dir=$batch_dir/output
mkdir -p $output_dir

OUTPUT=$(sbatch -p $partition --job-name="$batch_name" --array="$array" $script $bin $batch $infiles)

if [[ $? -ne 0 ]]; then
echo ERROR: $OUTPUT
exit 1
fi

# read the new job number from the sbatch output
echo $OUTPUT
IFS=" " read -ra split <<< "$OUTPUT"
job_id=${split[3]}

# create a report script -- only do this once
if [[ ! -f ${batch_name}_report.sh ]]; then
echo "creating report ${batch_name}_report.sh"
$HOME/reports/create_report.sh --dir $output_dir --name ${batch_name} $job_id
else
echo "appending $job_id to ${batch_name}_report_config.sh"
$HOME/reports/create_report.sh --append ${batch_name}_report_config.sh $job_id
fi

