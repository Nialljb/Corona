#!/bin/bash
# HPC version of s3_bundle.sh - Bundle volumetric results

# Usage: ./s3_bundle.sh <data_directory> <output_directory>

if [ $# -ne 2 ]; then
    echo "Usage: $0 <data_directory> <output_directory>"
    echo "Example: $0 /data/derivatives /workspace/results"
    exit 1
fi

source=$1
results_dir=$2

# Create results directory if it doesn't exist
mkdir -p ${results_dir}

echo "Bundling volumetric results..."
echo "Source directory: $source"
echo "Results directory: $results_dir"

# Function to bundle volumes for a modality
bundle_volumes() {
    local modality=$1
    local source_dir=$2
    local output_file=$3
    
    echo "Processing $modality volumes..."
    echo "subject,session,path,gm_vol,wm_vol,csf_vol" > "$output_file"
    
    local count=0
    for subject_dir in $(find ${source_dir} -maxdepth 1 -type d -name "*" | tail -n +2); do
        subject=$(basename ${subject_dir})
        
        for session_dir in $(find ${subject_dir} -maxdepth 1 -type d -name "*" | tail -n +2); do
            session=$(basename ${session_dir})
            
            # Look for volume files in the modality directory
            volsfile_pattern="${session_dir}/anat/${modality}/*_vols.txt"
            
            for volsfile in $volsfile_pattern; do
                if [ -f "$volsfile" ]; then
                    echo "Found: $volsfile"
                    echo -n "${subject},${session}," >> "$output_file"
                    tail -n 1 "$volsfile" >> "$output_file"
                    ((count++))
                else
                    echo "Missing: $volsfile"
                fi
            done
        done
    done
    
    echo "Bundled $count $modality volume files"
}

# Bundle T1w volumes
bundle_volumes "T1w" "$source" "${results_dir}/T1w_volumes.csv"

# Bundle T2w volumes  
bundle_volumes "T2w" "$source" "${results_dir}/T2w_volumes.csv"

echo "Volume bundling completed!"
echo "Results saved to: $results_dir"
ls -la ${results_dir}/*.csv