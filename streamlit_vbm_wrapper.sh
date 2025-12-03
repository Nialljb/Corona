#!/bin/bash
# Streamlit-compatible VBM pipeline wrapper
# This script formats the VBM pipeline for integration with the Job Manager

# Parse arguments from Streamlit job submission
BIDS_DIR=""
OUTPUT_DIR=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --bids_dir)
            BIDS_DIR="$2"
            shift 2
            ;;
        --output_dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$BIDS_DIR" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Error: --bids_dir and --output_dir are required"
    exit 1
fi

echo "Starting VBM Pipeline via Streamlit Job Manager"
echo "================================================"
echo "BIDS Directory: $BIDS_DIR"
echo "Output Directory: $OUTPUT_DIR"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURMD_NODENAME"
echo "Start Time: $(date)"
echo "================================================"

# Create workspace directory
WORKSPACE_DIR="$OUTPUT_DIR/vbm_workspace"
mkdir -p "$WORKSPACE_DIR"

# Get the script directory (where this wrapper is located)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo ""
echo "Starting VBM analysis pipeline..."

# Run the VBM pipeline with default parameters
if "$SCRIPT_DIR/run_vbm_hpc.sh" \
    --data "$BIDS_DIR" \
    --workspace "$WORKSPACE_DIR"; then
    
    echo ""
    echo "✅ VBM Pipeline completed successfully!"
    echo "Results available in: $OUTPUT_DIR"
    
    # Create a summary file for the Streamlit app
    cat > "$OUTPUT_DIR/vbm_summary.txt" << EOF
VBM Analysis Summary
===================
Job ID: $SLURM_JOB_ID
Start Time: $(date)
Input: $BIDS_DIR
Output: $OUTPUT_DIR
Workspace: $WORKSPACE_DIR
Status: SUCCESS

Output Files:
- Segmentation results: $WORKSPACE_DIR/results/
- DARTEL templates: $BIDS_DIR/DARTEL_Templates/
- Volume measurements: $WORKSPACE_DIR/results/*.csv
- Processing logs: $WORKSPACE_DIR/logs/

Pipeline used default settings:
- Modality: T2w
- Timepoint: 6M  
- Parallel Jobs: 4
EOF
    
    exit 0
else
    echo ""
    echo "❌ VBM Pipeline failed!"
    
    # Create error summary
    cat > "$OUTPUT_DIR/vbm_summary.txt" << EOF
VBM Analysis Summary
===================
Job ID: $SLURM_JOB_ID
Start Time: $(date)
Input: $BIDS_DIR
Output: $OUTPUT_DIR
Workspace: $WORKSPACE_DIR
Status: FAILED

Check log files in: $WORKSPACE_DIR/logs/

To debug, check:
1. SLURM job logs
2. MATLAB logs in workspace/logs/
3. Module availability (matlab, spm)
EOF
    
    exit 1
fi