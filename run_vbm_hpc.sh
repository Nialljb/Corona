#!/bin/bash
# HPC Module-based VBM Pipeline Runner
# Uses existing SPM/MATLAB modules instead of containers

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_usage() {
    cat << EOF
HPC VBM Pipeline Runner (Module-based)

Usage: $0 [OPTIONS]

Required Options:
    -d, --data DIR             Path to data directory (contains derivatives/)
    -w, --workspace DIR        Path to workspace directory (for logs/results)

Optional Options:
    -m, --modality MODALITY    Imaging modality (T1w or T2w, default: T2w)
    -t, --timepoint TIMEPOINT  Timepoint to process (default: 6M)
    -j, --jobs JOBS           Number of parallel jobs (default: 4)
    -n, --template-name NAME   Template name prefix (default: Template)
    -s, --step STEP           Run only specific step (1-6)
    --spm-module MODULE       SPM module name (default: spm)
    --matlab-module MODULE    MATLAB module name (default: matlab)
    --modules-init PATH       Path to modules init script (default: auto-detect)
    -h, --help                Show this help message

Steps:
    1. Generate file lists
    2. Tissue segmentation  
    3. Bundle volumes
    4. Create template
    5. Generate flow fields
    6. Register to MNI

Example:
    $0 -d /data/study -w /workspace -m T2w -t 6M -j 4

HPC Module Examples:
    # If your modules are different
    $0 -d /data/study -w /workspace --spm-module spm12 --matlab-module matlab/R2023b
    
    # Custom modules init path
    $0 -d /data/study -w /workspace --modules-init /software/system/modules/latest/init/bash

EOF
}

# Default values
DATA_DIR=""
WORKSPACE_DIR=""
MODALITY="T2w"
TIMEPOINT="6M"
PARALLEL_JOBS=4
TEMPLATE_NAME="Template"
SINGLE_STEP=""
SPM_MODULE="spm"
MATLAB_MODULE="matlab"
MODULES_INIT=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--data)
            DATA_DIR="$2"
            shift 2
            ;;
        -w|--workspace)
            WORKSPACE_DIR="$2"
            shift 2
            ;;
        -m|--modality)
            MODALITY="$2"
            shift 2
            ;;
        -t|--timepoint)
            TIMEPOINT="$2"
            shift 2
            ;;
        -j|--jobs)
            PARALLEL_JOBS="$2"
            shift 2
            ;;
        -n|--template-name)
            TEMPLATE_NAME="$2"
            shift 2
            ;;
        -s|--step)
            SINGLE_STEP="$2"
            shift 2
            ;;
        --spm-module)
            SPM_MODULE="$2"
            shift 2
            ;;
        --matlab-module)
            MATLAB_MODULE="$2"
            shift 2
            ;;
        --modules-init)
            MODULES_INIT="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required arguments
if [ -z "$DATA_DIR" ] || [ -z "$WORKSPACE_DIR" ]; then
    print_error "Missing required arguments"
    show_usage
    exit 1
fi

if [ ! -d "$DATA_DIR" ]; then
    print_error "Data directory not found: $DATA_DIR"
    exit 1
fi

# Auto-detect modules init script if not provided
if [ -z "$MODULES_INIT" ]; then
    for init_path in \
        "/software/system/modules/latest/init/bash" \
        "/usr/share/modules/init/bash" \
        "/opt/modules/init/bash" \
        "/etc/profile.d/modules.sh"; do
        if [ -f "$init_path" ]; then
            MODULES_INIT="$init_path"
            break
        fi
    done
    
    if [ -z "$MODULES_INIT" ]; then
        print_warning "Could not auto-detect modules init script"
        print_warning "Please specify with --modules-init or ensure modules are already loaded"
    fi
fi

# Create workspace directories
mkdir -p "$WORKSPACE_DIR/logs"
mkdir -p "$WORKSPACE_DIR/results"

# Function to load modules
load_modules() {
    if [ -n "$MODULES_INIT" ] && [ -f "$MODULES_INIT" ]; then
        print_status "Loading modules from: $MODULES_INIT"
        source "$MODULES_INIT"
        
        # Load required modules
        print_status "Loading module: $MATLAB_MODULE"
        module load "$MATLAB_MODULE" || print_warning "Failed to load $MATLAB_MODULE"
        
        print_status "Loading module: $SPM_MODULE" 
        module load "$SPM_MODULE" || print_warning "Failed to load $SPM_MODULE"
        
        # Show loaded modules
        print_status "Currently loaded modules:"
        module list 2>&1 | grep -E "(matlab|spm)" || print_warning "No matlab/spm modules visible"
    else
        print_warning "Modules init not found, assuming modules are pre-loaded"
    fi
}

# Function to run MATLAB command
run_matlab() {
    local matlab_cmd="$1"
    local description="$2"
    
    print_status "$description"
    print_status "MATLAB command: $matlab_cmd"
    
    # Add our script path to the MATLAB command
    local full_cmd="addpath('$(pwd)/scripts/lib'); $matlab_cmd"
    
    matlab -nodisplay -nosplash -nodesktop -r "$full_cmd"
}

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

print_status "Starting HPC VBM Pipeline"
print_status "Data directory: $DATA_DIR"
print_status "Workspace: $WORKSPACE_DIR"
print_status "Modality: $MODALITY"
print_status "Timepoint: $TIMEPOINT"
print_status "Parallel jobs: $PARALLEL_JOBS"
print_status "Template name: $TEMPLATE_NAME"

# Load modules
load_modules

# Function to run a pipeline step
run_step() {
    local step_num=$1
    local step_name="$2"
    local step_cmd="$3"
    
    if [ -n "$SINGLE_STEP" ] && [ "$SINGLE_STEP" != "$step_num" ]; then
        return 0
    fi
    
    print_status "Step $step_num: $step_name"
    
    if eval "$step_cmd"; then
        print_success "Step $step_num completed successfully"
    else
        print_error "Step $step_num failed"
        exit 1
    fi
    echo ""
}

# Define file paths
LOGS_DIR="$WORKSPACE_DIR/logs"
RESULTS_DIR="$WORKSPACE_DIR/results"
DERIVATIVES_DIR="$DATA_DIR/derivatives"
TEMPLATE_DIR="$DATA_DIR/DARTEL_Templates/${TIMEPOINT}_${MODALITY}"
TEMPLATE_PATH="$TEMPLATE_DIR/$TEMPLATE_NAME"

# Run pipeline steps using HPC modules
run_step 1 "Generate file lists" \
    "$SCRIPT_DIR/hpc_scripts/s1_list.sh '$DERIVATIVES_DIR' '$LOGS_DIR'"

run_step 2 "Tissue segmentation" \
    "$SCRIPT_DIR/hpc_scripts/s2_seg.sh '$LOGS_DIR/${MODALITY,,}_list.txt' $PARALLEL_JOBS"

run_step 3 "Bundle volumes" \
    "$SCRIPT_DIR/hpc_scripts/s3_bundle.sh '$DERIVATIVES_DIR' '$RESULTS_DIR'"

run_step 4 "Create template" \
    "$SCRIPT_DIR/hpc_scripts/s4_template.sh '$DATA_DIR' '$TEMPLATE_NAME' '$MODALITY' '$TIMEPOINT'"

run_step 5 "Generate flow fields" \
    "$SCRIPT_DIR/hpc_scripts/s5_flow.sh '$TEMPLATE_PATH' '$DERIVATIVES_DIR' '$MODALITY' '$TIMEPOINT'"

run_step 6 "Register to MNI" \
    "$SCRIPT_DIR/hpc_scripts/s6_reg.sh '$TEMPLATE_PATH' '$DERIVATIVES_DIR' '$MODALITY' '$TIMEPOINT'"

if [ -z "$SINGLE_STEP" ]; then
    print_success "Complete VBM pipeline finished successfully!"
    print_status "Results can be found in: $RESULTS_DIR"
    print_status "Templates can be found in: $TEMPLATE_DIR"
else
    print_success "Step $SINGLE_STEP completed successfully!"
fi