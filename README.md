# 🧠 HPC Slurm Job Manager

A comprehensive Streamlit-based interface for managing high-performance computing jobs on Slurm clusters. This application provides an intuitive web interface for submitting jobs, monitoring execution, downloading results, and visualizing data from your HPC environment.

## Features

### 🚀 Job Manager
- **Apptainer Jobs**: Submit containerized jobs with custom resource allocations (CPU, memory, GPU)
- **Node Execution**: Run pre-configured pipeline nodes with standardized configurations
- **Workflows**: Chain multiple jobs together with dependencies for complex pipelines
- **Real-time Monitoring**: Check job status and progress with live updates
- **Job History**: Track all submitted jobs and their outcomes

### 📥 Download Data
- **Smart File Browser**: Navigate remote directories with an intuitive interface
- **Batch Downloads**: Download multiple files simultaneously
- **Auto-detection**: Automatically locate output files from your jobs
- **Progress Tracking**: Monitor download progress for large file transfers
- **Remote Directory Navigation**: Browse the HPC filesystem without command-line access

### 📊 Visualize Data
- **Interactive Plots**: Create dynamic visualizations of your results
- **Data Exploration**: Browse and analyze datasets directly in the browser
- **Export Options**: Save visualizations in multiple formats
- **Custom Dashboards**: Build personalized analytics views for your data

## Prerequisites

- Python 3.8 or higher
- SSH access to an HPC cluster running Slurm
- SSH key-based authentication configured
- Apptainer/Singularity installed on the HPC cluster (for container jobs)

## Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd hpc-slurm-job-manager
```

2. Install required dependencies:
```bash
pip install -r requirements.txt
```

3. Ensure you have SSH key-based authentication set up for your HPC cluster:
```bash
ssh-keygen -t rsa -b 4096
ssh-copy-id username@your-hpc-cluster.edu
```

## Usage

### Starting the Application

1. Launch the Streamlit app:
```bash
streamlit run Home.py
```

2. Open your web browser and navigate to the URL displayed (typically `http://localhost:8501`)

### Connecting to Your HPC Cluster

1. In the sidebar, enter your connection details:
   - **Hostname**: Your HPC login node (e.g., `login1.your-cluster.edu`)
   - **Username**: Your HPC username
   - **SSH Key Path**: Path to your private SSH key (default: `~/.ssh/id_rsa`)

2. Click **Connect**

3. Once connected, you'll see a success message and can access all features

### Submitting Jobs

#### Apptainer Container Jobs

1. Navigate to **Job Manager**
2. Select the **Apptainer Jobs** tab
3. Configure your job:
   - Container image path on the HPC cluster
   - Command to run inside the container
   - Resource requirements (CPUs, memory, GPUs)
   - Working directory
   - Output/error log paths
4. Click **Submit Job**

#### Pre-configured Node Jobs

1. Navigate to **Job Manager**
2. Select the **Node Execution** tab
3. Choose from available pre-configured pipeline nodes
4. Provide required input parameters
5. Submit the job

#### Creating Workflows

1. Navigate to **Job Manager**
2. Select the **Workflows** tab
3. Add multiple job steps with dependencies
4. Configure each step's parameters
5. Submit the entire workflow

### Downloading Results

1. Navigate to **Download Data**
2. Browse the remote filesystem
3. Select files or directories to download
4. Choose local destination
5. Click **Download** and monitor progress

### Visualizing Data

1. Navigate to **Visualize Data**
2. Select or upload data files
3. Choose visualization type (plots, charts, tables)
4. Customize appearance and parameters
5. Export visualizations as needed

## Configuration

### Environment Variables

You can set default values using environment variables:

```bash
export HPC_HOSTNAME="login1.your-cluster.edu"
export HPC_USERNAME="your-username"
export HPC_SSH_KEY="~/.ssh/id_rsa"
```

### SSH Configuration

For easier connection, add your HPC cluster to `~/.ssh/config`:

```
Host hpc-cluster
    HostName login1.your-cluster.edu
    User your-username
    IdentityFile ~/.ssh/id_rsa
    ServerAliveInterval 60
```

## Project Structure

```
hpc-slurm-job-manager/
├── Home.py                 # Main application entry point
├── hpc_client_ssh.py      # SSH client wrapper for HPC operations
├── pages/
│   ├── 1_Job_Manager.py   # Job submission and management interface
│   ├── 2_Visualize_Data.py # Data visualization tools
│   └── 3_Download_Data.py  # File download interface
├── requirements.txt        # Python dependencies
└── README.md              # This file
```

## Dependencies

Key dependencies include:
- `streamlit` - Web application framework
- `paramiko` - SSH protocol implementation
- `pandas` - Data manipulation and analysis
- `plotly` / `matplotlib` - Data visualization
- Additional dependencies listed in `requirements.txt`

## Troubleshooting

### Connection Issues

**Problem**: Cannot connect to HPC cluster

**Solutions**:
- Verify hostname is correct and accessible
- Ensure SSH key has correct permissions (`chmod 600 ~/.ssh/id_rsa`)
- Test SSH connection manually: `ssh username@hostname`
- Check if SSH key is added to `~/.ssh/authorized_keys` on the cluster

### Job Submission Failures

**Problem**: Jobs fail to submit

**Solutions**:
- Verify Slurm is accessible: test with `sinfo` command on cluster
- Check resource requests don't exceed cluster limits
- Ensure container paths are correct and accessible
- Verify working directories exist and are writable

### Download Problems

**Problem**: File downloads fail or are slow

**Solutions**:
- Check network connectivity to HPC cluster
- Verify file permissions on remote system
- For large files, consider using batch download mode
- Ensure sufficient local disk space

## Security Considerations

- SSH keys are never transmitted or stored by the application
- All connections use SSH key-based authentication
- Session state is stored locally in the browser
- Disconnect from the cluster when not in use
- Use appropriate file permissions for SSH keys (`600`)

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Support

For issues, questions, or feature requests:
- Check the documentation in each page of the application
- Review example workflows in the Workflow tab
- Open an issue on the project repository

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

Built with:
- [Streamlit](https://streamlit.io/) - Web application framework
- [Paramiko](https://www.paramiko.org/) - SSH implementation
- [Slurm](https://slurm.schedmd.com/) - HPC workload manager
- [Apptainer](https://apptainer.org/) - Container platform

---

**Note**: This application is designed for use with Slurm-based HPC clusters. Ensure you have proper authorization and follow your institution's acceptable use policies when accessing HPC resources.
