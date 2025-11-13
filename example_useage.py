from hpc_client_ssh import HPCSSHClient

# Connect to the HPC (using your SSH key)
client = HPCSSHClient(hostname="login.hpc.example.edu", username="nbourke")

# List projects
print("Projects:")
for p in client.list_projects("/home/nbourke/projects"):
    print("  -", p)

# Submit a job (assuming test_job.sh exists on HPC)
job = client.submit_job("/home/nbourke/projects/revamp/run_segmentation.sh")
print("Submitted:", job)

# Check status
status = client.job_status(job["job_id"])
print("Status:", status)

# Download result file
client.download_results("/home/nbourke/projects/revamp/output/results.zip", "results.zip")

client.close()
