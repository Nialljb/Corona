import os
import paramiko
from pathlib import Path
import tempfile

class HPCSSHClient:
    def __init__(self, hostname, username=None, key_path=None):
        self.hostname = hostname
        self.username = username or os.getenv("USER")
        self.key_path = os.path.expanduser(key_path or "~/.ssh/id_rsa")

        self.ssh_client = paramiko.SSHClient()
        self.ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        self._connect()

    def _connect(self):
        self.ssh_client.connect(
            hostname=self.hostname,
            username=self.username,
            key_filename=self.key_path,
            look_for_keys=True,
            timeout=10,
        )
        print(f"Connected to {self.hostname} as {self.username}")

    def _run(self, command):
        stdin, stdout, stderr = self.ssh_client.exec_command(command)
        out = stdout.read().decode().strip()
        err = stderr.read().decode().strip()
        if err:
            print(f"[stderr] {err}")
        return out

    # --------------------------------------------------------------------
    # Basic filesystem and job management
    # --------------------------------------------------------------------

    def list_projects(self, base_dir="/projects"):
        return self._run(f"ls -d {base_dir}/*/").splitlines()

    def list_project_directories(self, base_path="~/projects"):
        """List all directories in the projects folder."""
        result = self._run(f"ls -d {base_path}/*/")
        if not result:
            return []
        # Extract just the directory names
        dirs = [d.strip().rstrip('/').split('/')[-1] for d in result.splitlines() if d.strip()]
        return sorted(dirs)
    
    def job_status(self, job_id):
        """Return job state (RUNNING, COMPLETED, FAILED, etc.)."""
        state = self._run(f"squeue -j {job_id} -h -o '%T'")
        return state or "COMPLETED"

    def download_results(self, remote_path, local_path):
        sftp = self.ssh_client.open_sftp()
        sftp.get(remote_path, local_path)
        sftp.close()
        print(f"Downloaded {remote_path} → {local_path}")

    def submit_job(self, script_path, job_name="test_job"):
        """Submit a job to the scheduler (example: Slurm)."""
        cmd = f"sbatch --job-name={job_name} {script_path}"
        result = self._run(cmd)
        
        # Check if result is empty or doesn't contain expected output
        if not result:
            raise ValueError(f"sbatch command returned empty result. Command: {cmd}")
        
        # Split and check if we have output
        parts = result.split()
        if not parts:
            raise ValueError(f"sbatch command returned unexpected format: '{result}'")
        
        # Typical sbatch output: "Submitted batch job 12345"
        # Extract job ID (last element)
        job_id = parts[-1]
        
        # Validate it looks like a job ID (numeric)
        if not job_id.isdigit():
            raise ValueError(f"Expected numeric job ID, got: '{job_id}' from output: '{result}'")
        
        return {"job_id": job_id}
    # --------------------------------------------------------------------
    # Slurm + Apptainer job submission
    # --------------------------------------------------------------------

    def submit_apptainer_job(
        self,
        image_path,
        command,
        job_name="apptainer_job",
        work_dir="/home/$USER",
        cpus=2,
        mem="4G",
        gpus=0,
        time="01:00:00",
        output_log="slurm-%j.out",
    ):
        """
        Create and submit a temporary SLURM batch script to run Apptainer.
        """
        slurm_script = f"""#!/bin/bash
#SBATCH --job-name={job_name}
#SBATCH --output={output_log}
#SBATCH --cpus-per-task={cpus}
#SBATCH --mem={mem}
#SBATCH --time={time}
"""

        if gpus > 0:
            slurm_script += f"#SBATCH --gres=gpu:{gpus}\n"

        slurm_script += f"""
cd {work_dir}

echo "Running Apptainer job on $(hostname)"
apptainer exec {image_path} {command}

echo "Job completed at $(date)"
"""

        # Write the script to a temporary file and upload it
        with tempfile.NamedTemporaryFile("w", delete=False) as f:
            f.write(slurm_script)
            tmp_local = f.name

        remote_script = f"{work_dir}/{job_name}.sh"
        sftp = self.ssh_client.open_sftp()
        sftp.put(tmp_local, remote_script)
        sftp.close()
        os.remove(tmp_local)

        # Submit job
        result = self._run(f"sbatch {remote_script}")
        job_id = result.strip().split()[-1]
        print(f"Submitted job {job_id}")
        return {"job_id": job_id, "remote_script": remote_script}

    def close(self):
        self.ssh_client.close()



# Additional methods can be added as needed, for example:

# def upload_file(self, local_path, remote_path):
#     sftp = self.ssh_client.open_sftp()
#     sftp.put(local_path, remote_path)
#     sftp.close()


