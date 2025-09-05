#!/bin/bash
#SBATCH --partition=batch 
#SBATCH --nodes=1
#SBATCH --account=cedar_amlrecovery
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=4gb
#SBATCH --time=4:00:00
#SBATCH --job-name=deduplicate_test

# define args
in=""
outdir=""

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --in=*)
            in="${1#*=}"
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


if [[ -z "$in" || -z "$outdir"  ]]; then
    echo "Error: One or more required arguments are missing."
    exit 1
fi


if [ ! -d $outdir ]; then
    mkdir -p $outdir
fi

echo "Performing Deduplication"
echo "Input:" $in
echo "Output Directory:" $outdir


# we want to do grouping as well 


deduplicate_bismark --bam -p --output_dir $outdir $in