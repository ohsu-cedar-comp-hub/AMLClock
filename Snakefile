import os 
import logging 
import re 
import pandas as pd 

main_dir = config['raw_data']

def load_lookup(file):
    lookup = {}
    with open(file) as f:
        for line in f:
            parts = line.strip().split(", ")
            if len(parts) != 2:
                continue
            barcode = parts[0].split(": ")[1]
            id_ = parts[1].split(": ")[1]
            lookup[barcode] = id_
    return lookup
 
LOOKUP_DICT = load_lookup(config['index_dict'])

if not config.get("manual", False): 
# raw data files should have both R1 and R2 
    FILES = glob_wildcards(os.path.join(main_dir, "{sample_info}_R1.fastq.gz"))
    NAMES = [sample for sample in FILES.sample_info if os.path.exists(os.path.join(main_dir, f"{sample}_R2.fastq.gz"))]

    S_IDS = [re.search(r"_S(\d+)_", s).group(1) for s in NAMES]

    print(NAMES) # sample names 

    BY_BARCODE = {}

    for sample_name in NAMES:
        s_id = re.search(r"_S(\d+)_", sample_name).group(1) 
        barcode_info = pd.read_csv(os.path.join(main_dir, 'SampleSheets', f'S{s_id}_SampleSheet.csv'))
        barcodes = barcode_info['Sample_ID'].astype(str) + '-' + barcode_info['Sample_Name'].astype(str) + '-' + barcode_info['Sample_Barcode']

        for barcode in barcodes: 
            BY_BARCODE[barcode] = sample_name

    # by_barcode's format: {barcode_info : sample_name}

    # with IDs 
    W_IDS = {}
    # look up dict has shortened barcode info
    for short_barcode, index_id in LOOKUP_DICT.items(): 
        for full_barcode in BY_BARCODE.keys(): 
            if short_barcode in full_barcode: 
                full_w_id = full_barcode + '_' + str(index_id)
                W_IDS[full_w_id] = full_barcode
                # {full_w_id : full_barcode}

else: 
    print("Manual set to True. Sample names will be detected based on what you've set as raw data in config folder") 
    W_IDS = {}
    BY_BARCODE = {} #{full_barcode : sample_name}
    trimmed = os.path.join(main_dir, 'Trimmed')
    demuxed = os.path.join(main_dir, 'Demuxed')

    # if trimmed directory eexists and there are files in it, we want to build our sample names list from here
    if os.path.exists(trimmed) and len(os.listdir(trimmed)) > 0:
        for filename in os.listdir(trimmed):
            if filename.endswith("_R1_val_1.fq.gz"):
                full_w_id = filename.split("_R1_val_1.fq.gz")[0]
                no_id = full_w_id.rsplit('_', 1)[0]
                W_IDS[full_w_id] = no_id 
            
                print("Trimmed Outputs Detected for Files:", filename)


    if os.path.exists(demuxed) and len(os.listdir(demuxed)) > 0: 
        # either files have id added or id not added yet...
        # either way we need to rebuild W_IDS 
        for filename in (f for f in os.listdir(demuxed) if f.endswith('_R1.fastq.gz')):
            if re.search(r'_\d+_R1\.fastq\.gz$', filename):
                print("IDs Detected in Files:", filename)
                # id detected 
                full_w_id = filename.split("_R1.fastq.gz")[0]
                no_id = full_w_id.rsplit('_', 1)[0]
                W_IDS[full_w_id] = no_id
            elif re.search(r'_R1\.fastq\.gz$', filename): 
                print("No IDs Detected in Files:", filename )
                no_id = filename.split("_R1.fastq.gz")[0]
                for short_barcode, index_id in LOOKUP_DICT.items(): 
                    if short_barcode in no_id: 
                        full_w_id = no_id + '_' + str(index_id)

                W_IDS[full_w_id] = no_id
                BY_BARCODE[no_id] = ''
            
        
    print("Samples Detected for Analysis:", list(W_IDS.values()))


            






rule all:
    input:
        #expand(os.path.join(main_dir, "Demuxed/unmatched_{sample_info}_R1.fastq.gz"), sample_info = NAMES), 
        #expand(os.path.join(main_dir, "Demuxed/unmatched_{sample_info}_R2.fastq.gz"), sample_info = NAMES), 
        #expand(os.path.join(main_dir, "Demuxed/{full_w_id}_R1.fastq.gz"), full_w_id = W_IDS.keys()), 
        #expand(os.path.join(main_dir, "Demuxed/{full_w_id}_R2.fastq.gz"), full_w_id = W_IDS.keys()), 
        #expand(os.path.join(main_dir, "Trimmed/{full_w_id}_R1.fastq.gz_trimming_report.txt"), full_w_id = W_IDS.keys()), 
        #expand(os.path.join(main_dir, "Trimmed/{full_w_id}_R2.fastq.gz_trimming_report.txt"), full_w_id = W_IDS.keys()), 
        #expand(os.path.join(main_dir, "Trimmed/{full_w_id}_R1_val_1.fq.gz"), full_w_id = W_IDS.keys()), 
        #expand(os.path.join(main_dir, "Trimmed/{full_w_id}_R2_val_2.fq.gz"), full_w_id = W_IDS.keys()),  
        #expand(os.path.join(main_dir, "Trimmed/{full_w_id}_R1_val_1_fastqc.html"), full_w_id = W_IDS.keys()), 
        #expand(os.path.join(main_dir, "Trimmed/{full_w_id}_R2_val_2_fastqc.html"), full_w_id = W_IDS.keys()),  
        #expand(os.path.join(main_dir, "Trimmed/{full_w_id}_R1_val_1_fastqc.zip"), full_w_id = W_IDS.keys()), 
        #expand(os.path.join(main_dir, "Trimmed/{full_w_id}_R2_val_2_fastqc.zip"), full_w_id = W_IDS.keys()), 
        expand(os.path.join(main_dir, "Aligned_paired/{full_w_id}_R1_val_1.fq.gz_unmapped_reads_1.fq.gz"), full_w_id = W_IDS.keys()), 
        expand(os.path.join(main_dir, "Aligned_paired/{full_w_id}_R2_val_2.fq.gz_unmapped_reads_2.fq.gz"),  full_w_id = W_IDS.keys()), 
        expand(os.path.join(main_dir, "Aligned_paired/{full_w_id}_R1_val_1_bismark_bt2_PE_report.txt"), full_w_id = W_IDS.keys()), 
        expand(os.path.join(main_dir, "Aligned_paired/{full_w_id}_R1_val_1_bismark_bt2_pe.bam"), full_w_id = W_IDS.keys())
        #expand(os.path.join(main_dir, "Deduplicated/{full_w_id}_R1_val_1_bismark_bt2_pe.deduplicated.bam"), full_w_id = W_IDS.keys()), 
        #expand(os.path.join(main_dir, "Deduplicated/{full_w_id}_R1_val_1_bismark_bt2_pe.deduplication_report.txt"),full_w_id = W_IDS.keys() )



rule demux:
    input:
        raw_1 = os.path.join(main_dir, "{sample_info}_R1.fastq.gz"),
        raw_2 = os.path.join(main_dir, "{sample_info}_R2.fastq.gz")
    output:
        flag = temp(os.path.join(main_dir, "Demuxed/tmp_{sample_info}.demux_done"))
    params:
        demux_dir = os.path.join(main_dir, "Demuxed"), 
        ss_dir = os.path.join(main_dir, "SampleSheets"), 
        metrics_dir = os.path.join(main_dir, "Demuxed/DemuxMetrics")
    threads: 2
    resources: 
        time ="4:00:00"
    shell:
         """
        {config[demux]} \
            --in={input.raw_1},{input.raw_2} \
            --r={config[demux_read_structure]} \
            --name={wildcards.sample_info} \
            --ssdir={params.ss_dir} \
            --m={params.metrics_dir} \
            --outdir={params.demux_dir}
        
        touch {output.flag}
        """


rule check_demux:
    input:
        lambda w: f"{main_dir}/Demuxed/tmp_{BY_BARCODE[w.barcode_info]}.demux_done"
    output:
        demux_1 = os.path.join(main_dir, "Demuxed/{barcode_info}_R1.fastq.gz"), 
        demux_2 = os.path.join(main_dir, "Demuxed/{barcode_info}_R2.fastq.gz")



rule add_index: 
    input: 
        demux_1 = os.path.join(main_dir, "Demuxed/{barcode_info}_R1.fastq.gz"), 
        demux_2 = os.path.join(main_dir, "Demuxed/{barcode_info}_R2.fastq.gz")
    output:
        temp(os.path.join(main_dir, "Demuxed/tmp_{barcode_info}.index_done"))
    shell:
        """
         {config[add_id]} \
            --in={input.demux_1},{input.demux_2} 

        touch {output}
        """

rule check_index:
    input:
        lambda w: f"{main_dir}/Demuxed/tmp_{W_IDS[w.full_w_id]}.index_done"   
    output:
        w_id1 = os.path.join(main_dir, "Demuxed/{full_w_id}_R1.fastq.gz"), 
        w_id2 = os.path.join(main_dir, "Demuxed/{full_w_id}_R2.fastq.gz")


rule trim: 
    input: 
        w_id1 = os.path.join(main_dir, "Demuxed/{full_w_id}_R1.fastq.gz"), 
        w_id2 = os.path.join(main_dir, "Demuxed/{full_w_id}_R2.fastq.gz")
    output:
        trim_report_1 = os.path.join(main_dir, "Trimmed/{full_w_id}_R1.fastq.gz_trimming_report.txt"), 
        trim_report_2 = os.path.join(main_dir, "Trimmed/{full_w_id}_R2.fastq.gz_trimming_report.txt"), 
        trimmed_1 = os.path.join(main_dir, "Trimmed/{full_w_id}_R1_val_1.fq.gz"), 
        trimmed_2 = os.path.join(main_dir, "Trimmed/{full_w_id}_R2_val_2.fq.gz"), 
        val_report_1 = os.path.join(main_dir, "Trimmed/{full_w_id}_R1_val_1_fastqc.html"), 
        val_report_2 = os.path.join(main_dir, "Trimmed/{full_w_id}_R2_val_2_fastqc.html"), 
        zip_1 = os.path.join(main_dir, "Trimmed/{full_w_id}_R1_val_1_fastqc.zip"), 
        zip_2 = os.path.join(main_dir, "Trimmed/{full_w_id}_R2_val_2_fastqc.zip")
    threads: 2
    resources: 
        time ="4:00:00"  
    params:
        trim_dir = os.path.join(main_dir, "Trimmed")
    shell: 
        """
        {config[trim]} \
            --in={input.w_id1},{input.w_id2} \
            --clip_r1={config[clip_r1]} \
            --clip_r2={config[clip_r2]} \
            --clip_3prime={config[clip_3prime]} \
            --outdir={params.trim_dir}

        """


rule align: 
    input: 
        trimmed_1 = os.path.join(main_dir, "Trimmed/{full_w_id}_R1_val_1.fq.gz"), 
        trimmed_2 = os.path.join(main_dir, "Trimmed/{full_w_id}_R2_val_2.fq.gz")
    output: 
        unmap_1 = os.path.join(main_dir, "Aligned_paired/{full_w_id}_R1_val_1.fq.gz_unmapped_reads_1.fq.gz"), 
        unmap_2 = os.path.join(main_dir, "Aligned_paired/{full_w_id}_R2_val_2.fq.gz_unmapped_reads_2.fq.gz"), 
        report = os.path.join(main_dir, "Aligned_paired/{full_w_id}_R1_val_1_bismark_bt2_PE_report.txt"),
        aligned =  os.path.join(main_dir, "Aligned_paired/{full_w_id}_R1_val_1_bismark_bt2_pe.bam")
    resources: 
        time="10:00:00",
        mem_mb=40000  
    threads: 12
    params: 
        align_dir = os.path.join(main_dir, "Aligned_paired")
    shell: 
        """
        {config[align]} \
            --in={input.trimmed_1},{input.trimmed_2} \
            --genome={config[genome]} \
            --cores={config[bwt2cores]} \
            --outdir={params.align_dir}
        """


# combine aligned reads from other lanes/ previous sequencing project for the same sample/tech replicate
# and then deduplication is performed 
# should this be separate from workflow? 

# could design a rule that combines aligned reads grouped by Rep2_? and then do bismarck deduplicate? 

#rule deduplicate: 
  #  input: 
    #    aligned = os.path.join(main_dir, "Aligned_paired/{full_w_id}_R1_val_1_bismark_bt2_pe.bam")
   # output: 
     #   deduplicated = os.path.join(main_dir, "Deduplicated/{full_w_id}_R1_val_1_bismark_bt2_pe.deduplicated.bam"), 
     #   report = os.path.join(main_dir, "Deduplicated/{full_w_id}_R1_val_1_bismark_bt2_pe.deduplication_report.txt")
   # params: 
   #     deduplicate_dir = os.path.join(main_dir, "Deduplicated")
   # shell: 
    #    """
     #   {config[deduplicate]} \
     #       --in={input.aligned} \
      #      --outdir={params.deduplicate_dir}
    #    """