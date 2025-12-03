#!/bin/bash
# HPC version of s2_seg.sh - Tissue segmentation using existing SPM/MATLAB modules

# Usage: ./s2_seg.sh <input_file_or_list> [parallel_jobs]

if [ $# -lt 1 ]; then
    echo "Usage: $0 <input_file_or_list> [parallel_jobs]"
    echo "Example: $0 /workspace/logs/t1w_list.txt 4"
    echo "         $0 /data/single_image.nii"
    exit 1
fi

INPUT=$1
PARALLEL_JOBS=${2:-1}

# Get script directory for MATLAB functions
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
LIB_DIR="$(dirname "$SCRIPT_DIR")/scripts/lib"

# Function to run segmentation on a single file
run_segmentation() {
    local input_file=$1
    local lib_dir=$2
    
    echo "Processing: $input_file"
    
    # Run segmentation using MATLAB with SPM
    matlab -nodisplay -nosplash -nodesktop -r "addpath('$lib_dir'); segment_t1('$input_file'); exit"
        
    if [ $? -eq 0 ]; then
        echo "✓ Successfully processed: $input_file"
    else
        echo "✗ Failed to process: $input_file"
        return 1
    fi
}

export -f run_segmentation
export LIB_DIR

# Process input
if [ -f "$INPUT" ] && [[ "$INPUT" == *.txt ]]; then
    # Input is a list file
    echo "Processing files from list: $INPUT"
    
    if [ ! -s "$INPUT" ]; then
        echo "Error: Input list file is empty!"
        exit 1
    fi
    
    # Run in parallel if specified
    if [ $PARALLEL_JOBS -gt 1 ]; then
        echo "Running $PARALLEL_JOBS parallel segmentation jobs..."
        cat "$INPUT" | xargs -I {} -P $PARALLEL_JOBS bash -c "run_segmentation '{}' '$LIB_DIR'"
    else
        echo "Running sequential segmentation jobs..."
        while IFS= read -r file; do
            if [ -n "$file" ]; then
                run_segmentation "$file" "$LIB_DIR"
            fi
        done < "$INPUT"
    fi
    
elif [ -f "$INPUT" ] && [[ "$INPUT" == *.nii ]]; then
    # Input is a single NIfTI file
    echo "Processing single file: $INPUT"
    run_segmentation "$INPUT" "$LIB_DIR"
    
else
    echo "Error: Input must be either a .nii file or a .txt list file!"
    exit 1
fi

echo "Segmentation processing completed!"