#!/bin/bash
#SBATCH --cpus-per-task 1
#SBATCH --mem 4G
#SBATCH --account=cedar_amlrecovery
#SBATCH --partition batch
#SBATCH --time=36:00:00

ENV_NAME="aml_clock"

if conda env list | grep -q "$ENV_NAME"; then
    echo "Environment '$ENV_NAME' already exists. Activating..."
else
    echo "Environment '$ENV_NAME' does not exist. Creating and initializing..."
    # Create the environment from the YAML file
    conda env create -f aml_clock.yaml
fi

eval "$(conda shell.bash hook)"
conda init
conda activate aml_clock

config=""
until=""
cores=12
s_file=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c) config="$2"; shift ;;
        -u) until="$2"; shift ;;
        -s) s_file="$2"; shift ;;
        --cores) cores="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$config" ]; then
    echo "Error: -c (absolute path to configfile) is required"
    exit 1
fi

if [ -z "$s_file" ]; then
    echo "Error: -s (absolute path to desired snakefile) is required. "
    exit 1
fi

cmd="snakemake -s $s_file --profile config/cluster/ --configfile $config --cores $cores "

if [ -n "$until" ]; then
    cmd="$cmd --until $until"
fi

eval "$cmd"

