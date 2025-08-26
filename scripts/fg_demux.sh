#!/bin/bash
#SBATCH --partition=batch 
#SBATCH --nodes=1
#SBATCH --account=cedar_amlrecovery
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8gb
#SBATCH --gres=disk:1024 
#SBATCH --time=5:00:00
#SBATCH --job-name=fg_demux_test


srun mkdir-scratch.sh
SCRATCH_PATH="/mnt/scratch/${SLURM_JOB_ID}"
# define args
inputs=""
read_structure=""
s_id=""
outdir=""
metrics_dir=""
ssdir=""

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --in=*)
            inputs="${1#*=}"
            IFS=',' read -r input1 input2 <<< "$inputs"
            ;;
         --r=*)
            read_structure="${1#*=}"
            IFS=',' read -r rs_1 rs_2 <<< "$read_structure"
            ;;
        --name=*)
            s_info="${1#*=}"
            ;;
         --ssdir=*)
            ssdir="${1#*=}"
            ;;
         --m=*)
            metrics_dir="${1#*=}"
            ;;
        --outdir=*)
            outdir="${1#*=}"
            ;;
        *)
            echo "Unknown parameter: $1"
            exit 1
            ;;
    esac
    shift
done


if [[ -z "$input1" || -z "$input2" || -z "$rs_1" || -z "$rs_2" || -z "$s_info" || -z "$outdir" || -z "$metrics_dir" || -z "$ssdir" ]]; then
    echo "Error: One or more required arguments are missing."
    exit 1
fi
# inputs will be EXP240521HM_TR2_A1_S1_L004_R1_001.fastq.gz, EXP240521HM_TR2_A1_S1_L004_R2_001.fastq.gz

# Check if output directory exists, if not, create it
if [ ! -d $outdir ]; then
    mkdir -p $outdir
fi

# s_id: is the # after S
s_id=$(echo "$s_info" | grep -oP '(?<=_S)\d+')

full_ss="${ssdir}/S${s_id}_SampleSheet.csv"

if [ ! -f $full_ss ]; then
    echo "ERROR: Sample sheet not found at $full_ss" >&2
    exit 1
fi

if [ ! -d $metrics_dir ]; then
    mkdir -p $metrics_dir
fi

metrics_file="$metrics_dir/S${s_id}_demux_barcode_metrics.txt"

echo "Performing Demultiplexing"
echo "Inputs:" $input1 $input2 
echo "Read Structure:" $rs_1 $rs_2 
echo "Sample Sheet:" $full_ss
echo "Output Directory:" $outdir
echo "Metrics will be put as:" $metrics_file
echo "Demultiplexing will occur in:" $SCRATCH_PATH

cp $input1 $SCRATCH_PATH/
cp $input2 $SCRATCH_PATH/
cp $full_ss $SCRATCH_PATH/

cd $SCRATCH_PATH/  

fgbio DemuxFastqs \
    --output-type Fastq \
    -u unmatched_$s_info \
    --include-all-bases-in-fastqs TRUE \
    --inputs $SCRATCH_PATH/$(basename "$input1") $SCRATCH_PATH/$(basename "$input2") \
    -r $rs_1 $rs_2 \
    -x $SCRATCH_PATH/$(basename "$full_ss") \
    -m $SCRATCH_PATH/metrics.txt \
    -o $SCRATCH_PATH

# remove the input files bc no longer needed from local scratch
rm $SCRATCH_PATH/$(basename "$input1")
rm $SCRATCH_PATH/$(basename "$input2") 

# move all output files out back to Demuxed 
mv $SCRATCH_PATH/*_R1.fastq.gz $outdir 
mv $SCRATCH_PATH/*_R2.fastq.gz $outdir 
mv $SCRATCH_PATH/*.txt $metrics_file 


srun rmdir-scratch.sh
