import streamlit as st
import os
from hpc_client_ssh import HPCSSHClient


st.set_page_config(page_title="Job Manager", page_icon="🚀", layout="wide")

st.title("🚀 Job Manager")

# Check connection
if not st.session_state.get("connected", False) or not st.session_state.get("client"):
    st.error("❌ Not connected to HPC cluster. Please connect using the sidebar.")
    st.stop()

client = st.session_state.client
username = st.session_state.username

# Initialize job history
if "job_history" not in st.session_state:
    st.session_state.job_history = []

# Create tabs
tab1, tab2, tab3 = st.tabs(["🐳 Apptainer", "🔧 Scripts", "🔄 Workflows"])

# ============================================================================
# TAB 1: APPTAINER
# ============================================================================
with tab1:
    st.header("Submit Batch Apptainer Jobs")
    st.write("Run containerized applications on the HPC cluster.")
    
    with st.form("apptainer_form"):
        image_path = st.text_input(
            "Apptainer Image Path", 
            f"/home/{username}/images/my_container.sif",
            help="Path to your .sif container image"
        )
        
        command = st.text_input(
            "Command", 
            "python /app/run_pipeline.py --input data/",
            help="Command to execute inside the container"
        )
        
        work_dir = st.text_input(
            "Working Directory", 
            f"/home/{username}/projects/my_project",
            help="Directory where the job will run"
        )
        
        col1, col2, col3, col4 = st.columns(4)
        with col1:
            cpus = st.number_input("CPUs", min_value=1, max_value=64, value=4)
        with col2:
            mem = st.text_input("Memory", "16G")
        with col3:
            gpus = st.number_input("GPUs", min_value=0, max_value=8, value=0)
        with col4:
            time = st.text_input("Time Limit", "04:00:00")
        
        job_name = st.text_input("Job Name", "apptainer_job")
        output_log = st.text_input("Output Log", "slurm-%j.out")
        
        submit = st.form_submit_button("🚀 Submit Job", use_container_width=True)
        
        if submit:
            try:
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
                st.session_state.job_history.append({
                    "job_id": job["job_id"],
                    "type": "Apptainer",
                    "name": job_name
                })
                st.success(f"✅ Submitted job {job['job_id']}")
            except Exception as e:
                st.error(f"❌ Failed to submit job: {e}")

# ============================================================================
# TAB 2: Scripts
# ============================================================================
with tab2:
    st.header("Run Pre-configured Script")
    st.write("Execute pipeline scripts with specific configurations.")
    
    # Script definitions
    scripts = {
        "Structural Segmentation": f"/home/{username}/scripts/run_segmentation.sh",
        "DTI Pipeline": f"/home/{username}/scripts/run_dti.sh",
        "fMRI Preprocessing": f"/home/{username}/scripts/run_fmri.sh",
        "Hello World": f"/home/{username}/scripts/hello_world.sh",
    }
    
    col1, col2 = st.columns([1, 1])
    
    with col1:
        selected_script = st.selectbox(
            "Select Script",
            options=list(scripts.keys()),
            help="Choose a pre-configured pipeline script to run"
        )
        
        # Get project directories
        try:
            project_dirs = client.list_project_directories()
            if project_dirs:
                selected_project = st.selectbox(
                    "Select Project",
                    options=project_dirs,
                    help="Projects found in ~/projects/"
                )
            else:
                st.warning("No projects found in ~/projects/")
                selected_project = st.text_input("Project Name", "my_project")
        except Exception as e:
            st.warning(f"Could not load projects: {e}")
            selected_project = st.text_input("Project Name", "my_project")
    
    with col2:
        st.info(f"**Script:** `{scripts[selected_script]}`")
        st.info(f"**Project Path:** `~/projects/{selected_project}`")
    
    if st.button("👾 Submit Script Job", use_container_width=True):
        script = scripts[selected_script]
        job_name = selected_script.replace(" ", "_")
        
        try:
            with st.spinner("Submitting script job..."):
                job = client.submit_job(script, job_name=job_name)
            st.session_state.job_id = job["job_id"]
            st.session_state.job_history.append({
                "job_id": job["job_id"],
                "type": "Script",
                "name": selected_script,
                "project": selected_project
            })
            st.success(f"✅ Submitted job {job['job_id']}")
        except Exception as e:
            st.error(f"❌ Failed to submit job: {e}")

# ============================================================================
# TAB 3: WORKFLOWS
# ============================================================================
with tab3:
    st.header("Multi-Step Workflows")
    st.write("Chain multiple jobs together with dependencies.")
    
    st.info("🚧 Workflow feature coming soon! This will allow you to create complex pipelines with multiple dependent jobs.")
    
    st.markdown("""
    ### Planned Features:
    - **Job Dependencies**: Chain jobs so they run in sequence
    - **Parallel Execution**: Run multiple independent jobs simultaneously
    - **Conditional Logic**: Branch workflows based on results
    - **Workflow Templates**: Save and reuse common workflows
    - **Visual Pipeline Builder**: Drag-and-drop interface for creating workflows
    """)
    
    # Placeholder for future workflow builder
    with st.expander("Example Workflow Structure"):
        st.code("""
        workflow:
          name: "MRI Processing Pipeline"
          steps:
            - id: preprocessing
              type: node
              node: "Structural Segmentation"
              
            - id: dti
              type: node
              node: "DTI Pipeline"
              depends_on: [preprocessing]
              
            - id: fmri
              type: node
              node: "fMRI Preprocessing"
              depends_on: [preprocessing]
        """, language="yaml")

# ============================================================================
# JOB MONITORING SECTION
# ============================================================================
st.divider()
st.header("📊 Job Monitoring")

col1, col2 = st.columns([2, 1])

with col1:
    if "job_id" in st.session_state:
        job_id = st.session_state.job_id
        
        if st.button("🔄 Check Job Status", use_container_width=True):
            try:
                status = client.job_status(job_id)
                
                status_colors = {
                    "RUNNING": "🟢",
                    "PENDING": "🟡",
                    "COMPLETED": "✅",
                    "FAILED": "❌",
                    "CANCELLED": "🚫"
                }
                
                status_icon = status_colors.get(status, "⚪")
                st.info(f"{status_icon} Job **{job_id}** status: **{status}**")
            except Exception as e:
                st.error(f"Failed to check status: {e}")
    else:
        st.info("No active job. Submit a job to monitor its status.")

with col2:
    if st.session_state.job_history:
        st.metric("Total Jobs Submitted", len(st.session_state.job_history))
    else:
        st.metric("Total Jobs Submitted", 0)

# Job history
if st.session_state.job_history:
    with st.expander("📜 Job History", expanded=False):
        for idx, job in enumerate(reversed(st.session_state.job_history[-10:])):
            st.text(f"{idx+1}. Job {job['job_id']} - {job['type']}: {job['name']}")