#!/bin/bash
#SBATCH --partition=batch 
#SBATCH --nodes=1
#SBATCH --account=cedar_amlrecovery
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4gb
#SBATCH --time=4:00:00
#SBATCH --gres=disk:1024 
#SBATCH --job-name=merge_test

srun mkdir-scratch.sh
SCRATCH_PATH="/mnt/scratch/${SLURM_JOB_ID}"

# define args
inputs=""
outdir=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --in=*) inputs="${1#*=}"; shift ;;
        --outdir=*) outdir="${1#*=}"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
done

if [[ -z "$inputs" || -z "$outdir"  ]]; then
    echo "Error: One or more required arguments are missing."
    exit 1
fi

if [ ! -d $outdir ]; then
    mkdir -p $outdir
fi

IFS=' ' read -r -a bam_array <<< "$inputs"

echo "Copying input files to scratch: $SCRATCH_PATH"
scratch_bams=()

for bam in "${bam_array[@]}"; do
    filename=$(basename "$bam")
    cp "$bam" "$SCRATCH_PATH/"
    scratch_bams+=("$SCRATCH_PATH/$filename")
done

cd $SCRATCH_PATH

declare -A bam_by_sample_and_id

for bam in "${scratch_bams[@]}"; do
    filename=$(basename "$bam")
    
    # Extract sample name between '-' and '-'
    if [[ $filename =~ -([^-]+)- ]]; then
        sample_name="${BASH_REMATCH[1]}"
    else
        echo "Could not extract sample name from $filename"
        continue
    fi

    # Extract sample ID between '_' and '_R1'
    if [[ $filename =~ _([0-9]+)_R1 ]]; then
        sample_id="${BASH_REMATCH[1]}"
    else
        echo "Could not extract sample ID from $filename"
        continue
    fi

    key="${sample_name}_${sample_id}"
    bam_by_sample_and_id[$key]="${bam_by_sample_and_id[$key]} $bam"

done


for key in "${!bam_by_sample_and_id[@]}"; do
    files=${bam_by_sample_and_id[$key]}
    echo "Processing files for $key: $files"

    output_file="$outdir/${key}_R1_val_1_bismark_bt2_pe.bam"
    scratch_out="$SCRATCH_PATH/${key}_R1_val_1_bismark_bt2_pe.bam"

    file_count=$(wc -w <<< "$files")

    if [[ $file_count -eq 1 ]]; then
        echo "Only one file for $key, copying it."
        mv $files $output_file
    else
        echo "Merging $file_count files for $key."
        samtools merge "$scratch_out" $files
        mv $scratch_out $output_file
    fi
done


