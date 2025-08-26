#SBATCH --partition=batch 
#SBATCH --account=cedar_amlrecovery
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=10gb
#SBATCH --time=5:00:00
#SBATCH --gres=disk:1024 
#SBATCH --job-name=align_test


srun mkdir-scratch.sh
SCRATCH_PATH="/mnt/scratch/${SLURM_JOB_ID}"


inputs=""
genome=""
cores=""
outdir=""

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
          --in=*)
            inputs="${1#*=}"
            IFS=',' read -r input1 input2 <<< "$inputs"
            ;;
        --genome=*)
            genome="${1#*=}"
            ;;
        --cores=*)
            cores="${1#*=}"
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


if [[ -z "$input1" || -z "$input2" || -z "$genome" || -z "$cores" || -z "$outdir" ]]; then
    echo "Error: One or more required arguments are missing."
    exit 1
fi


# Check if output directory exists, if not, create it
if [ ! -d $outdir ]; then
    mkdir -p $outdir
fi
# input = TR2_A1_5-P1A03N-ACAGTG_1_R2_val_2.fq.gz

echo "Aligning..."
echo "Inputs:" $input1 $input2
echo "Genome:" $genome
echo "Bwt2 cores:" $cores 
echo "Output Directory:" $outdir
echo "Running alignment in:" $SCRATCH_PATH


cp $input1 $SCRATCH_PATH/
cp $input2 $SCRATCH_PATH/
cp -r $genome $SCRATCH_PATH/

cd $SCRATCH_PATH/ 

bismark --pbat --parallel $cores --unmapped --output_dir $SCRATCH_PATH --genome $SCRATCH_PATH/$(basename $genome) -1 $SCRATCH_PATH/$(basename $input1) -2 $SCRATCH_PATH/$(basename $input2)

rm $SCRATCH_PATH/$(basename $input1)
rm $SCRATCH_PATH/$(basename $input2)


mv $SCRATCH_PATH/*_bismark_bt2_pe.bam $outdir
mv $SCRATCH_PATH/*_bismark_bt2_PE_report.txt $outdir 
mv $SCRATCH_PATH/*.fq.gz $outdir 


srun rmdir-scratch.sh 



