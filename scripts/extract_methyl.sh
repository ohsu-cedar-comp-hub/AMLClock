#!/bin/bash
#SBATCH --partition=batch 
#SBATCH --nodes=1
#SBATCH --account=cedar_amlrecovery
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=4gb
#SBATCH --time=4:00:00
#SBATCH --job-name=extract_methyl_info_test


srun mkdir-scratch.sh
SCRATCH_PATH="/mnt/scratch/${SLURM_JOB_ID}"
# define args
in=""
outdir=""

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --in=*)
            in="${1#*=}"
            ;;
        --g=*)
            genome="${1#*=}"
            ;;
         --cores=*)
            cores="${1#*=}"
            ;; 
        --ignore_r1=*)
            ignore_r1="${1#*=}"
            ;;  
        --ignore_r2=*)
            ignore_r2="${1#*=}"
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


if [[ -z "$in" || -z "$genome" || -z "$cores" || -z "$ignore_r1" || -z "$ignore_r2" || -z "$outdir"  ]]; then
    echo "Error: One or more required arguments are missing."
    exit 1
fi

echo "Extracting Methylation Information"
echo "Input:" $in 
echo "Genome:" $genome
echo "Cores Used:" $cores
echo "# of Bases to Ignore R1:" $ignore_r1 
echo "# of Bases to Ignore R2:" $ignore_r2 
echo "Output Dir:" $outdir

if [ ! -d $outdir ]; then
    mkdir -p $outdir
fi

cp $in $SCRATCH_PATH/
cp -r $genome $SCRATCH_PATH/

cd $SCRATCH_PATH 

bismark_methylation_extractor --gzip --cytosine_report --comprehensive --merge_non_CpG --parallel $cores --bedGraph -p --ignore $ignore_r1 --ignore_r2 $ignore_r2 --no_overlap -o $SCRATCH_PATH --genome_folder $SCRATCH_PATH/$(basename $genome) $SCRATCH_PATH/$(basename $in)


mv $SCRATCH_PATH/*.txt $outdir 
mv $SCRATCH_PATH/*.gz $outdir 


srun rmdir-scratch.sh 



