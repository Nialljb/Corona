#!/bin/bash
# HPC version of s4_template.sh - Create DARTEL template using existing SPM/MATLAB

# Usage: ./s4_template.sh <data_directory> <template_name> <modality> <timepoint>

if [ $# -ne 4 ]; then
    echo "Usage: $0 <data_directory> <template_name> <modality> <timepoint>"
    echo "Example: $0 /data/derivatives Template_6M T2w 6M"
    echo "Modality: T1w or T2w"
    echo "Timepoint: 3M, 6M, etc."
    exit 1
fi

DATA_DIR=$1
TEMPLATE_NAME=$2
MODALITY=$3
TIMEPOINT=$4

# Get script directory for MATLAB functions
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
LIB_DIR="$(dirname "$SCRIPT_DIR")/scripts/lib"

echo "Creating DARTEL template..."
echo "Data directory: $DATA_DIR"
echo "Template name: $TEMPLATE_NAME"
echo "Modality: $MODALITY"
echo "Timepoint: $TIMEPOINT"

# Create template output directory
TEMPLATE_DIR="${DATA_DIR}/DARTEL_Templates/${TIMEPOINT}_${MODALITY}"
mkdir -p "$TEMPLATE_DIR"

# Collect segmentation files
echo "Collecting segmentation files..."
files_matlab_array=""

count=0
for subject_dir in $(find ${DATA_DIR}/derivatives -maxdepth 1 -type d -name "*" | tail -n +2); do
    subject=$(basename ${subject_dir})
    
    for session_dir in $(find ${subject_dir} -maxdepth 1 -type d -name "*" | tail -n +2); do
        session=$(basename ${session_dir})
        
        # Check if session matches timepoint
        if [[ "$session" == *"${TIMEPOINT}"* ]]; then
            anat_dir="${session_dir}/anat/${MODALITY}"
            
            if [ -d "$anat_dir" ]; then
                # Look for segmented files (c1, c2, c3)
                c1_file=$(find ${anat_dir} -name "c1*.nii" -type f | head -1)
                c2_file=$(find ${anat_dir} -name "c2*.nii" -type f | head -1)  
                c3_file=$(find ${anat_dir} -name "c3*.nii" -type f | head -1)
                
                if [ -f "$c1_file" ] && [ -f "$c2_file" ] && [ -f "$c3_file" ]; then
                    echo "Found segmentation for $subject $session"
                    
                    # Add to MATLAB array format
                    if [ $count -gt 0 ]; then
                        files_matlab_array="$files_matlab_array, "
                    fi
                    files_matlab_array="$files_matlab_array'$c1_file', '$c2_file', '$c3_file'"
                    ((count++))
                else
                    echo "Missing segmentation files for $subject $session"
                fi
            fi
        fi
    done
done

if [ $count -eq 0 ]; then
    echo "Error: No segmentation files found for timepoint $TIMEPOINT and modality $MODALITY"
    exit 1
fi

echo "Found segmentation files for $count subjects"

# Create template path
TEMPLATE_PATH="${TEMPLATE_DIR}/${TEMPLATE_NAME}"

# Run template creation using MATLAB
echo "Running DARTEL template creation..."
matlab -nodisplay -nosplash -nodesktop -r "addpath('$LIB_DIR'); make_template('$TEMPLATE_PATH', $files_matlab_array); exit"

if [ $? -eq 0 ]; then
    echo "✓ Successfully created template: ${TEMPLATE_DIR}/${TEMPLATE_NAME}"
    ls -la ${TEMPLATE_DIR}/
else
    echo "✗ Failed to create template"
    exit 1
fi

echo "Template creation completed!"