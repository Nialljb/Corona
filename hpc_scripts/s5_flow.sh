#!/bin/bash
# HPC version of s5_flow.sh - Generate flow fields using existing SPM/MATLAB

# Usage: ./s5_flow.sh <template_path> <data_directory> <modality> <timepoint>

if [ $# -ne 4 ]; then
    echo "Usage: $0 <template_path> <data_directory> <modality> <timepoint>"
    echo "Example: $0 /data/templates/Template /data/derivatives T2w 6M"
    exit 1
fi

TEMPLATE_PATH=$1
DATA_DIR=$2
MODALITY=$3
TIMEPOINT=$4

# Get script directory for MATLAB functions
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
LIB_DIR="$(dirname "$SCRIPT_DIR")/scripts/lib"

echo "Generating flow fields..."
echo "Template: $TEMPLATE_PATH"
echo "Data directory: $DATA_DIR"
echo "Modality: $MODALITY"
echo "Timepoint: $TIMEPOINT"

# Function to process a single subject
process_subject() {
    local subject_dir=$1
    local session_dir=$2
    local subject=$(basename ${subject_dir})
    local session=$(basename ${session_dir})
    
    # Check if session matches timepoint
    if [[ "$session" == *"${TIMEPOINT}"* ]]; then
        anat_dir="${session_dir}/anat/${MODALITY}"
        
        if [ -d "$anat_dir" ]; then
            # Look for rc files (imported to template space)
            rc1_file=$(find ${anat_dir} -name "rc1*.nii" -type f | head -1)
            rc2_file=$(find ${anat_dir} -name "rc2*.nii" -type f | head -1)
            rc3_file=$(find ${anat_dir} -name "rc3*.nii" -type f | head -1)
            
            if [ -f "$rc1_file" ] && [ -f "$rc2_file" ] && [ -f "$rc3_file" ]; then
                echo "Processing flow fields for $subject $session"
                
                # Run flow field generation using MATLAB
                matlab -nodisplay -nosplash -nodesktop -r "addpath('$LIB_DIR'); generate_flowfields('$TEMPLATE_PATH', '$rc1_file', '$rc2_file', '$rc3_file'); exit"
                    
                if [ $? -eq 0 ]; then
                    echo "✓ Successfully generated flow fields for $subject $session"
                else
                    echo "✗ Failed to generate flow fields for $subject $session"
                    return 1
                fi
            else
                echo "Missing rc files for $subject $session"
                echo "  rc1: $rc1_file"
                echo "  rc2: $rc2_file" 
                echo "  rc3: $rc3_file"
            fi
        fi
    fi
}

# Process all subjects
echo "Processing subjects..."
processed_count=0

for subject_dir in $(find ${DATA_DIR}/derivatives -maxdepth 1 -type d -name "*" | tail -n +2); do
    for session_dir in $(find ${subject_dir} -maxdepth 1 -type d -name "*" | tail -n +2); do
        if process_subject "$subject_dir" "$session_dir"; then
            ((processed_count++))
        fi
    done
done

echo "Flow field generation completed!"
echo "Processed $processed_count subjects"