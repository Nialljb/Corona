#!/bin/bash
# HPC version of s1_list.sh - Generate file lists for VBM pipeline
# Uses existing filesystem, no container needed

# Usage: ./s1_list.sh <data_directory> <output_directory>

if [ $# -ne 2 ]; then
    echo "Usage: $0 <data_directory> <output_directory>"
    echo "Example: $0 /data/derivatives /workspace/logs"
    exit 1
fi

source=$1
wd=$2

# Create output directory if it doesn't exist
mkdir -p ${wd}

# Make a list of all scans
echo -n "" > ${wd}/t1w_list.txt
echo -n "" > ${wd}/t2w_list.txt
echo -n "" > ${wd}/dwi_list.txt

echo "Processing subjects in: $source"
echo "Output logs to: $wd"

for s in $(find ${source} -maxdepth 1 -type d -name "*" | tail -n +2); do
    subj=$(basename ${s})
    echo "Processing subject: $subj"
    
    for session in $(find ${source}/${subj} -maxdepth 1 -type d -name "*" | tail -n +2); do
        ses=$(basename ${session});
        echo "  Processing session: $ses"
        
        # Handle T1w files
        t1_dir=${source}/${subj}/${ses}/anat/T1w
        if [ -d "$t1_dir" ]; then
            # Decompress if needed
            find ${t1_dir} -name "*.gz" -exec gunzip {} \; 2>/dev/null || true
            
            # Find T1 files
            find ${t1_dir} -name "*.nii" -type f >> ${wd}/t1w_list.txt
        fi
        
        # Handle T2w files  
        t2_dir=${source}/${subj}/${ses}/anat/T2w
        if [ -d "$t2_dir" ]; then
            # Decompress if needed
            find ${t2_dir} -name "*.gz" -exec gunzip {} \; 2>/dev/null || true
            
            # Find T2 files
            find ${t2_dir} -name "*.nii" -type f >> ${wd}/t2w_list.txt
        fi
        
        # Handle DWI files
        dwi_dir=${source}/${subj}/${ses}/dwi/dti
        if [ -d "$dwi_dir" ]; then
            find ${dwi_dir} -name "*.nii.gz" -type f >> ${wd}/dwi_list.txt
        fi
    done
done

echo "File listing completed!"
echo "T1w files: $(wc -l < ${wd}/t1w_list.txt)"
echo "T2w files: $(wc -l < ${wd}/t2w_list.txt)" 
echo "DWI files: $(wc -l < ${wd}/dwi_list.txt)"