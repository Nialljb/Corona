#!/bin/bash
# HPC version of s6_reg.sh - Register to MNI space using existing SPM/MATLAB

# Usage: ./s6_reg.sh <template_path> <data_directory> <modality> <timepoint>

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

echo "Registering to MNI space..."
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
            # Look for flow field and tissue files
            urc1_file=$(find ${anat_dir} -name "u_rc1*.nii" -type f | head -1)
            c1_file=$(find ${anat_dir} -name "c1*.nii" -type f | head -1)
            c2_file=$(find ${anat_dir} -name "c2*.nii" -type f | head -1)
            c3_file=$(find ${anat_dir} -name "c3*.nii" -type f | head -1)
            
            if [ -f "$urc1_file" ] && [ -f "$c1_file" ] && [ -f "$c2_file" ] && [ -f "$c3_file" ]; then
                echo "Processing MNI registration for $subject $session"
                
                # Run MNI registration using MATLAB
                matlab -nodisplay -nosplash -nodesktop -r "addpath('$LIB_DIR'); move_to_mni('$TEMPLATE_PATH', '$urc1_file', '$c1_file', '$c2_file', '$c3_file'); exit"
                    
                if [ $? -eq 0 ]; then
                    echo "✓ Successfully registered $subject $session to MNI"
                else
                    echo "✗ Failed to register $subject $session to MNI"
                    return 1
                fi
            else
                echo "Missing files for MNI registration for $subject $session"
                echo "  urc1: $urc1_file"
                echo "  c1: $c1_file"
                echo "  c2: $c2_file"
                echo "  c3: $c3_file"
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

echo "MNI registration completed!"
echo "Processed $processed_count subjects"