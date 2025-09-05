#!/bin/bash
#SBATCH --partition=batch 
#SBATCH --account=cedar_amlrecovery
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=8gb
#SBATCH --time=8:00:00
#SBATCH --job-name=trimming_test




inputs=""
clip_r1=""
clip_r2=""
clip_3prime=""
outdir=""

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --in=*)
            inputs="${1#*=}"
            IFS=',' read -r input1 input2 <<< "$inputs"
            ;;
         --clip_r1=*)
            clip_r1="${1#*=}"
            ;;
        --clip_r2=*)
            clip_r2="${1#*=}"
            ;;
        --clip_3prime=*)
            clip_3prime="${1#*=}"
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


if [[ -z "$input1" || -z "$input2" || -z "$clip_r1" || -z "$clip_r2" || -z "$clip_3prime" || -z "$outdir" ]]; then
    echo "Error: One or more required arguments are missing."
    exit 1
fi

# Check if output directory exists, if not, create it
if [ ! -d $outdir ]; then
    mkdir -p $outdir
fi


echo "Trimming..."
echo "Inputs:" $input1 $input2
echo "R1 Clip:" $clip_r1
echo "R2 Clip:" $clip_r2 
echo "R2 3' Clip:" $clip_3prime
echo "Output Directory:" $outdir



trim_galore --gzip \
  --clip_R1 "$clip_r1" \
  --clip_R2 "$clip_r2" \
  --three_prime_clip_R2 "$clip_3prime" \
  --paired \
  --fastqc \
  --output_dir $outdir \
  $input1 \
  $input2

