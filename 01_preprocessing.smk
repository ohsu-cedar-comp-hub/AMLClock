import os 
import logging 
import re 
import pandas as pd 

main_dir = config['raw_data']


if not config.get("manual", False): 
# raw data files should have both R1 and R2 
    FILES = glob_wildcards(os.path.join(main_dir, "{sample_info}_R1.fastq.gz"))
    NAMES = [sample for sample in FILES.sample_info if os.path.exists(os.path.join(main_dir, f"{sample}_R2.fastq.gz"))]

    S_IDS = [re.search(r"_S(\d+)_", s).group(1) for s in NAMES]

    print(NAMES) # sample names 

    W_IDS = {}

    for sample_name in NAMES:
        s_id = re.search(r"_S(\d+)_", sample_name).group(1) 
        barcode_info = pd.read_csv(os.path.join(main_dir, 'SampleSheets', f'S{s_id}_SampleSheet.csv'))
        barcodes = barcode_info['Sample_ID'].astype(str) + '-' + barcode_info['Sample_Name'].astype(str) + '-' + barcode_info['Sample_Barcode'] + '_' + barcode_info['Sample_Index'].astype(str)
        for full_w_id in barcodes: 
            W_IDS[full_w_id] = sample_name 
            


    print(W_IDS)

else: 
    print("Manual set to True. Sample Names will be detected based on the presence of output files in config['raw data']. ") 
    W_IDS = {} # {full_w_id : sample_name}
    trimmed = os.path.join(main_dir, 'Trimmed')
    demuxed = os.path.join(main_dir, 'Demuxed')

    # if trimmed directory exists and there are files in it, we want to build our sample names list from here
    if os.path.exists(trimmed) and len(os.listdir(trimmed)) > 0:
        for filename in os.listdir(trimmed):
            if filename.endswith("_R1_val_1.fq.gz"):
                full_w_id = filename.split("_R1_val_1.fq.gz")[0]
                no_id = full_w_id.rsplit('_', 1)[0]
                W_IDS[full_w_id] = no_id 
            
                print("Trimmed Outputs Detected:", filename)


    if os.path.exists(demuxed) and len(os.listdir(demuxed)) > 0: 
        # files may or may not have had ID added 
        # if not they need to be matched with sep script (user needs to do this themselves)
        # so assume ID added and build W_IDS 
        for filename in (f for f in os.listdir(demuxed) if f.endswith('_R1.fastq.gz')):
            if re.search(r'_\d+_R1\.fastq\.gz$', filename):
                 # id detected 
                id = re.search(r'_(\d+)_R1', filename).group(1)
                full_w_id = filename.split("_R1.fastq.gz")[0]
                W_IDS[full_w_id] = 'EXP' + id
                print("Demultiplexed Outputs with Indexes:", filename)
            else: 
                print("No Indexes Detected in Files:", filename )
                print("ERROR: You must add the sample indexes either manually or with a separate script. If manually, remember that each unique sample index corresponds to unique sample name.")
            
        
    print("Samples Detected for Analysis:", list(W_IDS.values()))






rule all:
    input:
        expand(os.path.join(main_dir, "Aligned_paired/{full_w_id}_R1_val_1.fq.gz_unmapped_reads_1.fq.gz"), full_w_id = W_IDS.keys()), 
        expand(os.path.join(main_dir, "Aligned_paired/{full_w_id}_R2_val_2.fq.gz_unmapped_reads_2.fq.gz"),  full_w_id = W_IDS.keys()), 
        expand(os.path.join(main_dir, "Aligned_paired/{full_w_id}_R1_val_1_bismark_bt2_PE_report.txt"), full_w_id = W_IDS.keys()), 
        expand(os.path.join(main_dir, "Aligned_paired/{full_w_id}_R1_val_1_bismark_bt2_pe.bam"), full_w_id = W_IDS.keys())



rule demux_w_index:
    input:
        raw_1 = os.path.join(main_dir, "{sample_info}_R1.fastq.gz"),
        raw_2 = os.path.join(main_dir, "{sample_info}_R2.fastq.gz")
    output:
        flag = temp(os.path.join(main_dir, "Demuxed/tmp_{sample_info}.demux_done"))
    params:
        demux_dir = os.path.join(main_dir, "Demuxed"), 
        ss_dir = os.path.join(main_dir, "SampleSheets"), 
        metrics_dir = os.path.join(main_dir, "Demuxed/DemuxMetrics")
    resources: 
        time="4:00:00"
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


rule check_demux_w_index:
    input:
        lambda w: f"{main_dir}/Demuxed/tmp_{W_IDS[w.full_w_id]}.demux_done"
    output:
        demux_1 = os.path.join(main_dir, "Demuxed/{full_w_id}_R1.fastq.gz"), 
        demux_2 = os.path.join(main_dir, "Demuxed/{full_w_id}_R2.fastq.gz")


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
        time="04:00:00"  
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
        gres="disk:1024", 
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
            --pbat={config[pbat]} \
            --outdir={params.align_dir}
        """

