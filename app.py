import streamlit as st
from hpc_client_ssh import HPCSSHClient
import os

st.set_page_config(page_title="HPC Slurm + Apptainer", layout="wide")

st.title("🧠 HPC Slurm Job Manager (Apptainer over SSH)")
st.write("Submit Apptainer-based jobs to a Slurm HPC cluster securely over SSH.")

# Sidebar
st.sidebar.header("🔑 Connection Settings")
hostname = st.sidebar.text_input("Hostname", "login1.nan.kcl.ac.uk")
username = st.sidebar.text_input("Username", os.getenv("USER"))
key_path = st.sidebar.text_input("SSH Key Path", "~/.ssh/id_rsa")
connect_btn = st.sidebar.button("Connect")

if "client" not in st.session_state:
    st.session_state.client = None

if connect_btn:
    try:
        client = HPCSSHClient(hostname, username, key_path)
        st.session_state.client = client
        st.success(f"✅ Connected to {hostname} as {username}")
    except Exception as e:
        st.error(f"Connection failed: {e}")

client = st.session_state.client

# Only show job submission UI if connected
if client:
    st.divider()
    st.subheader("⚙️ Submit an Apptainer Job")

    image_path = st.text_input("Apptainer Image Path", "/home/k2252514/images/my_Node.sif")
    command = st.text_input("Command to run inside container", "python /app/run_pipeline.py --input data/")
    work_dir = st.text_input("Working Directory", "/home/k2252514/projects/revamp")

    col1, col2, col3, col4 = st.columns(4)
    with col1:
        cpus = st.number_input("CPUs", min_value=1, max_value=64, value=4)
    with col2:
        mem = st.text_input("Memory", "16G")
    with col3:
        gpus = st.number_input("GPUs", min_value=0, max_value=8, value=0)
    with col4:
        time = st.text_input("Time Limit", "04:00:00")

    job_name = st.text_input("Job Name", "apptainer_test")
    output_log = st.text_input("Output Log File", "slurm-%j.out")

    if st.button("🚀 Submit Job"):
        with st.spinner("Submitting job..."):
            job = client.submit_apptainer_job(
                image_path=image_path,
                command=command,
                job_name=job_name,
                work_dir=work_dir,
                cpus=cpus,
                mem=mem,
                gpus=gpus,
                time=time,
                output_log=output_log,
            )
        st.session_state.job_id = job["job_id"]
        st.success(f"✅ Submitted job {job['job_id']}")

    # -----------------------------
    # Node / Module selection
    # -----------------------------
    st.divider()
    st.subheader("⚙️ Run a Node")
    node = {
        "Structural Segmentation": "/home/k2252514/nodes/run_segmentation.sh",
        "DTI Pipeline": "/home/k2252514/nodes/run_dti.sh",
        "fMRI Preprocessing": "/home/k2252514/nodes/run_fmri.sh",
        "Hello World": "/home/k2252514/nodes/hello_world.sh",
    }

    selected_node = st.selectbox("Select a Node to run:", list(node.keys()))
    
    # Get project directories dropdown
    try:
        project_dirs = client.list_project_directories()
        if project_dirs:
            selected_project = st.selectbox(
                "Select Project",
                options=project_dirs,
                help="Projects found in ~/projects/"
            )
            project_path = f"~/projects/{selected_project}"
        else:
            st.warning("No projects found in ~/projects/")
            project_path = st.text_input("Project Path", "/home/k2252514/projects/remoteTest")
    except Exception as e:
        st.warning(f"Could not load projects: {e}")
        project_path = st.text_input("Project Path", "/home/k2252514/projects/remoteTest")

    if st.button("👾 Submit Node Job"):
        script = node[selected_node]
        with st.spinner("Submitting job..."):
            try:
                job = client.submit_job(script, job_name=selected_node.replace(" ", "_"))
                st.session_state.job_id = job["job_id"]
                st.success(f"✅ Submitted job {job['job_id']}")
            except Exception as e:
                st.error(f"Failed to submit job: {e}")

    # -----------------------------
    # Monitor job
    # -----------------------------
    if "job_id" in st.session_state:
        st.divider()
        st.subheader("📊 Job Status")
        job_id = st.session_state.job_id
        if st.button("Check Job Status"):
            try:
                status = client.job_status(job_id)
                st.info(f"Job {job_id} status: **{status}**")
            except Exception as e:
                st.error(f"Failed to check status: {e}")

    # -----------------------------
    # Download results
    # -----------------------------
    st.divider()
    st.subheader("📦 Download Results")
    
    # Get user's home and downloads directory
    home_dir = os.path.expanduser("~")
    download_dir = os.path.join(home_dir, "Downloads")
    
    # Remote file path with suggestions
    remote_path = st.text_input(
        "Remote File Path", 
        value="",
        help="Enter the full path to the file on the HPC cluster"
    )
    

    # Show helpful suggestions based on context
    if remote_path:
        st.caption(f"📂 Remote: `{remote_path}`")
    elif 'work_dir' in locals():
        st.caption(f"💡 Example: `{work_dir}/output/results.zip`")
    
    # Local save path - auto-generate from remote filename
    default_filename = os.path.basename(remote_path) if remote_path else "results.zip"
    local_path = st.text_input(
        "Save As (Local Path)", 
        value=os.path.join(download_dir, default_filename),
        help="Full path where the file will be saved locally"
    )
    
    # Download button
    col1, col2 = st.columns([1, 4])
    with col1:
        download_btn = st.button("📥 Download", disabled=not remote_path, use_container_width=True)
    with col2:
        if not remote_path:
            st.caption("⚠️ Please enter a remote file path")
    
    if download_btn:
        try:
            # Ensure local directory exists
            local_dir = os.path.dirname(local_path)
            if local_dir:
                os.makedirs(local_dir, exist_ok=True)
            
            with st.spinner(f"Downloading {os.path.basename(remote_path)}..."):
                client.download_results(remote_path, local_path)
            
            st.success(f"✅ Downloaded successfully!")
            st.info(f"📂 Saved to: `{local_path}`")
            
            # Show file info
            if os.path.exists(local_path):
                file_size = os.path.getsize(local_path)
                st.metric("File Size", f"{file_size / (1024*1024):.2f} MB")
        except Exception as e:
            st.error(f"❌ Download failed: {e}")

else:
    # Show message when not connected
    st.info("👈 Please connect to the HPC cluster using the sidebar to get started.")
    st.markdown("""
    ### Getting Started
    1. Enter your HPC hostname (e.g., `login1.nan.kcl.ac.uk`)
    2. Enter your username
    3. Provide the path to your SSH private key
    4. Click **Connect**
    
    Once connected, you'll be able to:
    - Submit Apptainer jobs
    - Run pre-configured nodes
    - Monitor job status
    - Download results
    """)