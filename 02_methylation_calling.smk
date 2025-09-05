import os 
import logging 
import re 
import pandas as pd 
import glob

main_dir = config['main_dir']
#FILES = glob_wildcards(os.path.join(main_dir, "{full_w_id}_R1_val_1_bismark_bt2_pe.bam"))

#NAMES = [info for info in FILES.full_w_id] 

bam_files = glob.glob(os.path.join(main_dir, "*_R1_val_1_bismark_bt2_pe.bam"))

# Extract only the {full_w_id} portion from filename
NAMES = [os.path.basename(f).replace("_R1_val_1_bismark_bt2_pe.bam", "") for f in bam_files]

ALL_TARGETS=[]

if not config.get("manual", False): 
    if config['merge']: 
        print("Merging is set to True. Workflow will merge based on the following sample name and ID: " )
        MERGED = {}

        pattern = re.compile(r'-(.+?)-.*_(\d+)')

        for full_w_id in NAMES:
            match = pattern.search(full_w_id)
            if match:
                sample_name = match.group(1)
                id = match.group(2)
                MERGED[sample_name + '_' + id ] = full_w_id
                # {samplename _ id} : full_w_id 

        PRE_MERGE = NAMES
        ALL_TARGETS = list(set(MERGED.keys()))
        print("Targeted Samples and IDS are:" , PRE_MERGE)
        print("After Merge:", ALL_TARGETS)


    else: 
        ALL_TARGETS = NAMES
        print("Merging is set to False so merging will NOT occur. ")
        print("Processing is done for each aligned bam aka the following:")
        print(ALL_TARGETS)

else: 
    print("Manual set to True. Based on the presence of output files in config['main_dir'], Snakemake will decide the jobs needed ")
    # if user has deduplicated files and wants to just extract methylation info 
    deduplicated = os.path.join(main_dir, "Deduplicated") 
    if os.path.exists(deduplicated) and len(os.listdir(deduplicated)) > 0:
        for filename in os.listdir(deduplicated):
            if filename.endswith("_R1_val_1_bismark_bt2_pe.deduplicated.bam"):
                full_w_id = filename.split("_R1_val_1_bismark_bt2_pe.deduplicated.bam")[0]
                ALL_TARGETS.append(full_w_id)
                print("Deduplicated Outputs Detected for Files:", filename)
        print(ALL_TARGETS)
    
    # if user has deduplicated bams, wants to rerun merge and other steps
    # will need to make sure bams end in appropriate extension ...

    





rule all: 
    input: 
        expand(os.path.join(main_dir, "Methyl_covs/CpG_context_{info}_R1_val_1_bismark_bt2_pe.deduplicated.txt.gz"), info = ALL_TARGETS), 
        expand(os.path.join(main_dir, "Methyl_covs/Non_CpG_context_{info}_R1_val_1_bismark_bt2_pe.deduplicated.txt.gz"), info = ALL_TARGETS), 
        expand(os.path.join(main_dir, "Methyl_covs/{info}_R1_val_1_bismark_bt2_pe.deduplicated_splitting_report.txt"), info = ALL_TARGETS), 
        expand(os.path.join(main_dir, "Methyl_covs/{info}_R1_val_1_bismark_bt2_pe.deduplicated.bedGraph.gz"), info = ALL_TARGETS), 
        expand(os.path.join(main_dir, "Methyl_covs/{info}_R1_val_1_bismark_bt2_pe.deduplicated.bismark.cov.gz"), info = ALL_TARGETS), 
        expand(os.path.join(main_dir, "Methyl_covs/{info}_R1_val_1_bismark_bt2_pe.deduplicated.CpG_report.txt.gz"), info = ALL_TARGETS), 
        expand(os.path.join(main_dir, "Methyl_covs/{info}_R1_val_1_bismark_bt2_pe.deduplicated.cytosine_context_summary.txt"), info = ALL_TARGETS), 
        expand(os.path.join(main_dir, "Methyl_covs/{info}_R1_val_1_bismark_bt2_pe.deduplicated.M-bias.txt"), info = ALL_TARGETS)


if config['merge']: 
    rule merge: 
        input:
            all_aligned = expand(os.path.join(main_dir, "{full_w_id}_R1_val_1_bismark_bt2_pe.bam"), full_w_id = PRE_MERGE) 
        output: 
            flag = temp(os.path.join(main_dir, "Merged/tmp.merge_done"))
        params: 
            merge_dir = os.path.join(main_dir, "Merged")
        resources: 
            time ="6:00:00", 
            gres="disk:1024"
        shell: 
            """
            {config[merge_script]} \
                --in="{input.all_aligned}" \
                --outdir={params.merge_dir}

            touch {output.flag}
            """


    rule check_merge: 
        input: 
            lambda w: f"{main_dir}/Merged/tmp.merge_done"
        output:
            expand(os.path.join(main_dir, "Merged/{info}_R1_val_1_bismark_bt2_pe.bam"), info = ALL_TARGETS)

        

rule deduplicate:
    input:
        aligned = os.path.join(main_dir, "Merged/{info}_R1_val_1_bismark_bt2_pe.bam") if config.get("merge", False) else os.path.join(main_dir, "{info}_R1_val_1_bismark_bt2_pe.bam")
    output: 
        report = os.path.join(main_dir, "Deduplicated/{info}_R1_val_1_bismark_bt2_pe.deduplication_report.txt"), 
        deduplicated = os.path.join(main_dir, "Deduplicated/{info}_R1_val_1_bismark_bt2_pe.deduplicated.bam")
    params: 
        deduplicate_dir = os.path.join(main_dir, "Deduplicated")
    shell: 
        """
        {config[deduplicate]} \
            --in={input.aligned} \
            --outdir={params.deduplicate_dir}
        """


rule get_methyl_info: 
    input: 
        deduplicated = os.path.join(main_dir, "Deduplicated/{info}_R1_val_1_bismark_bt2_pe.deduplicated.bam")
    output: 
        cpg_context = os.path.join(main_dir, "Methyl_covs/CpG_context_{info}_R1_val_1_bismark_bt2_pe.deduplicated.txt.gz"), 
        noncpg_context = os.path.join(main_dir, "Methyl_covs/Non_CpG_context_{info}_R1_val_1_bismark_bt2_pe.deduplicated.txt.gz"), 
        splitting_report = os.path.join(main_dir, "Methyl_covs/{info}_R1_val_1_bismark_bt2_pe.deduplicated_splitting_report.txt"),
        bedgraph = os.path.join(main_dir, "Methyl_covs/{info}_R1_val_1_bismark_bt2_pe.deduplicated.bedGraph.gz"), 
        coverage_report = os.path.join(main_dir, "Methyl_covs/{info}_R1_val_1_bismark_bt2_pe.deduplicated.bismark.cov.gz"),
        cpg_report = os.path.join(main_dir, "Methyl_covs/{info}_R1_val_1_bismark_bt2_pe.deduplicated.CpG_report.txt.gz"),
        cytosine_summary = os.path.join(main_dir, "Methyl_covs/{info}_R1_val_1_bismark_bt2_pe.deduplicated.cytosine_context_summary.txt"),
        m_bias = os.path.join(main_dir, "Methyl_covs/{info}_R1_val_1_bismark_bt2_pe.deduplicated.M-bias.txt")
    threads: 2
    resources: 
        time ="10:00:00", 
        gres="disk:1024"
    params: 
        methyl_dir = os.path.join(main_dir, "Methyl_covs")
    shell: 
        """
        {config[extract_methyl_info]} \
            --in={input.deduplicated} \
            --g={config[genome]} \
            --cores={config[cores]} \
            --ignore_r1={config[ignore_r1]} \
            --ignore_r2={config[ignore_r2]} \
            --outdir={params.methyl_dir}
        """
