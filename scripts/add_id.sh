
#!/bin/bash
#SBATCH --partition=batch 
#SBATCH --nodes=1
#SBATCH --account=cedar_amlrecovery
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=8gb
#SBATCH --gres=disk:1024 
#SBATCH --time=5:00:00
#SBATCH --job-name=add_index_test


srun mkdir-scratch.sh
SCRATCH_PATH="/mnt/scratch/${SLURM_JOB_ID}"


input_files=""


# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
          --in=*)
            inputs="${1#*=}"
            IFS=',' read -r input1 input2 <<< "$inputs"
            ;;
        *)
            echo "Unknown parameter: $1"
            exit 1
            ;;
    esac
    shift
done

if [[ -z "$input1" || -z "$input2" ]]; then
    echo "Error: One or more required arguments are missing."
    exit 1
fi


strings=("P1A03N" "P1A04C" "P1B01N" "P1B03C" "P1B04N" "P1B07N" "P1B10N" "P1B11N" "P1B12N" "P1C01C" "P1C02N" "P1C05N" "P1C08N" "P1C09N" "P1C10N" "P1C12N" "P1D01C" "P1D07N" "P1D09C" "P1D11N" "P1D12C" "P1E01N" "P1E04N" "P1E07C" "P1E12N" "P1F04C" "P1F06C" "P1F10C" "P1F11N" "P1F12N" "P1F07N" "P1G03N" "P1G04N" "P1G05C" "P1G06N" "P1G09N" "P1G10N" "P1H06C" "P1H09N" "P2A03C" "P2A05C" "P2A06C" "P2A07N" "P2A09C" "P2B02C" "P2B03C" "P2B10N" "P2B11C" "P2C09C" "P2C10C" "P2C11N" "P2C12N" "P2D02C" "P2D04C" "P2D07N" "P2D08N" "P2D09N" "P2D10C" "P2E02C" "P2E07C" "P2E09N" "P2E10N" "P2F01C" "P2F07N" "P2F08N" "P2F09C" "P2G02N" "P2G03N" "P2G07C" "P2G08N" "P2G10N" "P2G11N" "P2H01C" "P2H02C" "P2H04C" "P2H06N" "P2H10N" "P2H11N" "P3A02N" "P3A03N" "P3A04C" "P3A05C" "P3A06N" "P3A07C" "P3A09C" "P3B03N" "P3B04C" "P3B05N" "P3B06N" "P3B07C" "P3B08C" "P3B09C" "P3B10N" "P3B12N" "P3C02C" "P3C04N" "P3C05N" "P3C06N" "P3D05C" "P3D08N" "P3D09N" "P3D10C" "P3D11N" "P3E02N" "P3E03N" "P3E05N" "P3E07C" "P3E09C" "P3E11C" "P3E12C" "P3F02C" "P3F05N" "P3F06C" "P3F09C" "P3F11C" "P3F12C" "P3G02N" "P3G06C" "P3G07C" "P3G09C" "P3G10C" "P3G11C" "P3H02N" "P3H04N" "P3H05C" "P3H09C" "P3H10C" "P3H11N" "P4A01N" "P4A02N" "P4A04C" "P4A10N" "P4A11N" "P4A12N" "P4B01N" "P4B04C" "P4B05C" "P4B06C" "P4B07C" "P4B08N" "P4B09C" "P4B10C" "P4B11C" "P4B12N" "P4C01N" "P4C03N" "P4C04C" "P4C05C" "P4C08C" "P4C09N" "P4C10C" "P4C12C" "P4D01C" "P4D03N" "P4D09C" "P4D10C" "P4D11C" "P4D12C" "P4E01C" "P4E04C" "P4E07C" "P4E08N" "P4E09N" "P4E10C" "P4E11C" "P4F04N" "P4F05C" "P4F08C" "P4F09N" "P4F10C" "P4G02N" "P4G07N" "P4G09N" "P4G10N" "P4G11N" "P4G12N" "P4H01C" "P4H03C" "P4H05C" "P4H06N" "P4H07C" "P4H08C" "P4H09C" "P4H10N" "P4H11N" "P5A03N" "P5A05C" "P5A08C" "P5A10C" "P5A11C" "P5B03C" "P5B05C" "P5B06N" "P5B07N" "P5B09N" "P5B10C" "P5C02C" "P5C03C" "P5C04N" "P5C09C" "P5C12N" "P5D01C" "P5D02N" "P5D05C" "P5D07N" "P5D09C" "P5D10N" "P5D11C" "P5D12C" "P5E02C" "P5E03N" "P5E04C" "P5E05C" "P5E08C" "P5E09C" "P5E11C" "P5E12C" "P5F02C" "P5F04C" "P5F05C" "P5F08N" "P5F09C" "P5F10N" "P5F11C" "P5F12N" "P5G02N" "P5G03N" "P5G06C" "P5G07C" "P5G09N" "P5G11N" "P5H01N" "P5H04C" "P5H05C" "P6A03N" "P6A04N" "P6A05C" "P6A06N" "P6A10C" "P6B01N" "P6B02N" "P6B03C" "P6B09N" "P6B10N" "P6B11N" "P6C01N" "P6C02N" "P6C03N" "P6C04C" "P6D01N" "P6D02N" "P6D03C" "P6D04C" "P6D05N" "P6D06N" "P6D07C" "P6D08N" "P6D09N" "P6D10C" "P6D11N" "P6D12N" "P6E01C" "P6E02N" "P6E05N" "P6E09C" "P6E10N" "P6E11N" "P6F01C" "P6F02N" "P6F04C" "P6F05C" "P6F09C" "P6G01C" "P6G05N" "P6G09C" "P6G10N" "P6G12C" "P6H01C" "P6H08C" "P6H10N" "P6H11N" "P6H12N" "P7A01C" "P7A02N" "P7A05N" "P7A08N" "P7A11C" "P7A12N" "P7B01N" "P7B02N" "P7B03N" "P7B04N" "P7B05N" "P7B09C" "P7B10N" "P7B12N" "P7C02C" "P7C03N" "P7C04C" "P7C09C" "P7C10C" "P7C12C" "P7D01C" "P7D04C" "P7D07N" "P7D10N" "P7D11N" "P7D12C" "P7E01C" "P7E04N" "P7E05N" "P7E09C" "P7E10C" "P7E11N" "P7E12C" "P7F01C" "P7F02C" "P7F03C" "P7F04N" "P7F09N" "P7F10C" "P7F11N" "P7G01C" "P7G02C" "P7G03N" "P7G04C" "P7G05N" "P7G06N" "P7G07N" "P7G09N" "P7G11N" "P7H01N" "P7H04C" "P7H07N" "P7H08N" "P7H11C" "P7H12C" "P8A10N" "P8A2C" "P8A3N" "P8A4N" "P8A6N" "P8B2C" "P8B3C" "P8B4C" "P8C2N" "P8C3C" "P8C5C" "P8C6N" "P8D2N" "P8D3C" "P8D4N" "P8D7N" "P8D9N" "P8E3C" "P8E6N" "P8E7C" "P8F3C" "P8G2C" "P8G3N" "P8G5N" "P8G6C" "P8G7C" "P8G8N" "P8H1N" "P8H2N" "P8H3C" "P8H5C" "P8H9C")


declare -A string_ids
counter=1
for string in "${strings[@]}"; do
  string_ids["$string"]=$counter
  ((counter++))
done

echo "Adding Index IDs to Demultiplexed FASTQs"
echo "Inputs:" $input1 $input2 

echo "Performed in:" $SCRATCH_PATH/

cp $input1 $SCRATCH_PATH/
cp $input2 $SCRATCH_PATH/ 



find_id() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "Warning: $file not found"
    return
  fi

  for string in "${strings[@]}"; do
    if [[ "$file" == *"$string"* ]]; then
      extension="${file#*.}"
      name="$(echo "$file" | sed 's/_R[12].*$//')" # i made an edit here to accomadate better naming convention 
      read="$(echo "$file" | sed -n 's/.*_\([^\.]*\).*/\1/p')"
      id="${string_ids[$string]}"
      new_filename="${name}_${id}_${read}.${extension}"
      echo "Renaming: $file → $new_filename"
      mv "$file" "$new_filename"
      break
    fi
  done
}

cd $SCRATCH_PATH/ 

find_id $SCRATCH_PATH/$(basename $input1) 
find_id $SCRATCH_PATH/$(basename $input2) 


mv $SCRATCH_PATH/*.fastq.gz $(dirname $input1)


srun rmdir-scratch.sh

