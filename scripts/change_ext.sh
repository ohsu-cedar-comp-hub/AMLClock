#!/bin/bash
#SBATCH --partition=batch 
#SBATCH --nodes=1
#SBATCH --account=cedar_amlrecovery
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8gb
#SBATCH --time=1:00:00
#SBATCH --job-name=change_ext


# need to change files like EXP240521HM_TR2_A1_S1_L004_R1_001.fastq.gz -> EXP240521HM_TR2_A1_S1_L004_R1.fastq.gz


# input = data directory 


data_dir=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --d=*)
            data_dir="${1#*=}"
            ;;
        *)
            echo "Unknown parameter: $1"
            exit 1
            ;;
    esac
    shift
done

if [[ -z "$data_dir" ]]; then
    echo "Error: No data directory given."
    exit 1
fi

for file in $data_dir/*.fastq.gz; do
    base=$(basename "$file")
    
    if [[ "$base" == *_R1* ]]; then
        prefix=${base%%_R1*}
        new_name="${prefix}_R1.fastq.gz"
    else 
        prefix=${base%%_R2*}
        new_name="${prefix}_R2.fastq.gz"

    fi
    mv "$file" "$data_dir/$new_name"
    
done
    



