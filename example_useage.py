from hpc_client_ssh import HPCSSHClient

# Connect to the HPC (using your SSH key)
client = HPCSSHClient(hostname="@login1.nan.kcl.ac.uk", username="k2252514")

# List projects
print("Projects:")
for p in client.list_projects("/home/k2252514/projects"):
    print("  -", p)

# Submit a job (assuming test_job.sh exists on HPC)
job = client.submit_job("/home/k2252514/projects/remoteTest/hello_world.sh")
print("Submitted:", job)

# Check status
status = client.job_status(job["job_id"])
print("Status:", status)

# Download result file
client.download_results("/home/k2252514/projects/remoteTest/output/results.zip", "results.zip")

client.close()
