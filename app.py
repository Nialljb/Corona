import streamlit as st
from hpc_client_ssh import HPCSSHClient
import os

st.set_page_config(page_title="HPC Slurm + Apptainer", layout="wide")

st.title("🧠 HPC Slurm Job Manager (Apptainer over SSH)")
st.write("Submit Apptainer-based jobs to a Slurm HPC cluster securely over SSH.")

# Sidebar
st.sidebar.header("🔑 Connection Settings")
hostname = st.sidebar.text_input("Hostname", "login.hpc.example.edu")
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

if client:
    st.divider()
    st.subheader("⚙️ Submit an Apptainer Job")

    image_path = st.text_input("Apptainer Image Path", "/home/nbourke/images/my_gear.sif")
    command = st.text_input("Command to run inside container", "python /app/run_pipeline.py --input data/")
    work_dir = st.text_input("Working Directory", "/home/nbourke/projects/revamp")

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
    # Monitor job
    # -----------------------------
    if "job_id" in st.session_state:
        st.divider()
        st.subheader("📊 Job Status")
        job_id = st.session_state.job_id
        if st.button("Check Job Status"):
            status = client.job_status(job_id)
            st.info(f"Job {job_id} status: **{status}**")

    # -----------------------------
    # Download results
    # -----------------------------
    st.divider()
    st.subheader("📦 Download Results")
    remote_path = st.text_input("Remote File", f"{work_dir}/output/results.zip")
    local_path = st.text_input("Save As", "results.zip")
    if st.button("Download"):
        client.download_results(remote_path, local_path)
        st.success(f"✅ Downloaded {remote_path} → {local_path}")
