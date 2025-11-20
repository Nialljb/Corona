import streamlit as st
import os
from hpc_client_ssh import HPCSSHClient

st.set_page_config(
    page_title="Home",
    page_icon="🏠",
    layout="wide",
    initial_sidebar_state="expanded"
)

st.title("🏠 Home")


# Initialize session state
if "client" not in st.session_state:
    st.session_state.client = None
if "connected" not in st.session_state:
    st.session_state.connected = False

# Sidebar connection settings
st.sidebar.title("🧠 HPC Manager")
st.sidebar.divider()

st.sidebar.header("🔑 Connection")

# Connection status indicator
if st.session_state.connected and st.session_state.client:
    st.sidebar.success("✅ Connected")
    if st.sidebar.button("Disconnect", use_container_width=True):
        if st.session_state.client:
            st.session_state.client.close()
        st.session_state.client = None
        st.session_state.connected = False
        st.rerun()
else:
    st.sidebar.info("Not connected")
    
    hostname = st.sidebar.text_input("Hostname", "login1.nan.kcl.ac.uk")
    username = st.sidebar.text_input("Username", os.getenv("USER", ""))
    key_path = st.sidebar.text_input("SSH Key Path", "~/.ssh/id_rsa")
    
    if st.sidebar.button("Connect", use_container_width=True):
        try:
            with st.spinner("Connecting..."):
                client = HPCSSHClient(hostname, username, key_path)
                st.session_state.client = client
                st.session_state.connected = True
                st.session_state.hostname = hostname
                st.session_state.username = username
            st.success(f"✅ Connected to {hostname}")
            st.rerun()
        except Exception as e:
            st.error(f"Connection failed: {e}")

# Main page content
st.title("🧠 HPC Slurm Job Manager")
st.write("Welcome to the HPC Slurm Job Manager - manage your cluster jobs with ease.")

if st.session_state.connected:
    st.success(f"Connected to **{st.session_state.hostname}** as **{st.session_state.username}**")

    st.divider()

    col1, col2, col3, col4 = st.columns(4)

    with col1:
        st.markdown("### 🚀 Job Manager")
        st.write("Submit and manage Slurm jobs, run Apptainer containers, and create workflows.")
        if st.button("Go to Job Manager", use_container_width=True):
            st.switch_page("pages/1_Job_Manager.py")

    with col2:
        st.markdown("### 📊 Visualize Data")
        st.write("Visualize and analyze your results with interactive plots and dashboards.")
        if st.button("Go to Visualize", use_container_width=True):
            st.switch_page("pages/2_Visualize_Data.py")

    with col3:
        st.markdown("### 📥 Download Data")
        st.write("Download results and outputs from your HPC jobs to your local machine.")
        if st.button("Go to Download", use_container_width=True):
            st.switch_page("pages/3_Download_Data.py")

    # with col4:
    #     st.markdown("### 📚 Data Explorer")
    #     st.write("Explore and visualize your data files interactively.")
    #     if st.button("Go to Data Explorer", use_container_width=True):
    #         st.switch_page("pages/4_Data_Explorer.py")

    with col4:
        st.markdown("### 📚 Data Explorer")
        st.write("Explore and visualize your data files interactively.")
        if st.button("Go to Data Explorer", use_container_width=True):
            st.switch_page("pages/4_Projects.py")


    st.divider()

    st.divider()
    st.markdown("""
    ## 🧠 NaN Slurm Job Manager

    A comprehensive interface for managing high-performance computing jobs on Slurm clusters.

    ### Features

    #### 🚀 Job Manager
    - **Apptainer Jobs**: Submit containerized jobs with custom resource allocations
    - **Node Execution**: Run pre-configured pipeline nodes
    - **Workflows**: Chain multiple jobs together with dependencies
    - **Real-time Monitoring**: Check job status and progress

    #### 📥 Download Data
    - **Smart File Browser**: Navigate remote directories with ease
    - **Batch Downloads**: Download multiple files at once
    - **Auto-detection**: Automatically find output files from your jobs
    - **Progress Tracking**: Monitor download progress for large files

    #### 📊 Visualize Data
    - **Interactive Plots**: Create dynamic visualizations of your results
    - **Data Exploration**: Browse and analyze datasets
    - **Export Options**: Save visualizations in multiple formats
    - **Custom Dashboards**: Build personalized analytics views

    ### Quick Start

    1. Connect to your HPC cluster using the sidebar
    2. Navigate to Job Manager to submit jobs
    3. Monitor job status in real-time
    4. Download results when complete
    5. Visualize and analyze your data

    ### Need Help?

    - Check the documentation for each page
    - View example workflows in the Workflow tab
    - Contact support if you encounter issues
    """)

else:
    st.info("👈 Please connect to your HPC cluster using the sidebar to get started.")
    
    st.markdown("""
    ### Getting Started
    
    1. **Connect to HPC**
       - Enter your hostname (e.g., `login1.nan.kcl.ac.uk`)
       - Enter your username
       - Provide your SSH key path
       - Click Connect
    
    2. **Manage Jobs**
       - Submit Apptainer containers
       - Run pre-configured nodes
       - Create multi-step workflows
       - Monitor job status
    
    3. **Download Results**
       - Browse output directories
       - Download files to local machine
       - Batch download multiple files
    
    4. **Visualize Data**
       - Create plots and charts
       - Interactive data exploration
       - Export visualizations
    """)