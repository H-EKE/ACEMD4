#!/bin/bash

# Configurable Variables
JOB_NAME="ACEMD4"
MEM_PER_CPU="10G"
TIME="72:00:00"
GPU_TYPE="a100_80gb"
NUM_JOBS=20
LICENSE_SERVER="27000@pc16lsr01.pharmazie.uni-marburg.de"
ACEMD_PATH="/home/elkhaoud/.conda/envs/acemd/bin/acemd"  # Corrected path
CONDA_ENV="acemd"
INPUT_FILE="production.yaml"  # Your pre-existing input file
LOG_FILE="production.log"  # Single log file
CPUS_PER_TASK=4

# SLURM job template function
generate_slurm_script() {
    local job_index=$1
    local dependency=$2
    cat << EOF
#!/bin/bash
#SBATCH --job-name=${JOB_NAME}_${job_index}
#SBATCH -n 1
#SBATCH -c $CPUS_PER_TASK
#SBATCH --mem-per-cpu=$MEM_PER_CPU
#SBATCH --time=$TIME
#SBATCH --gpus=$GPU_TYPE
${dependency:+#SBATCH -d afterany:$dependency}
export ACELLERA_LICENSE_SERVER=$LICENSE_SERVER

module load miniconda
source \$CONDA_ROOT/bin/activate
conda activate $CONDA_ENV

$ACEMD_PATH --input $(pwd)/$INPUT_FILE --ncpus \$SLURM_CPUS_PER_TASK >> $LOG_FILE 2>&1
EOF
}

# Submit jobs
rm -f alljobid
prev_job_id=""
for i in $(seq 1 $NUM_JOBS); do
    script_name="acemd_${i}.sh"
    dependency_flag=${prev_job_id:+-d afterany:$prev_job_id}

    # Generate SLURM script for the current job
    generate_slurm_script $i $prev_job_id > $script_name

    # Submit the job and capture the job ID
    job_id=$(sbatch $script_name | awk '{print $4}')
    echo $job_id >> alljobid
    prev_job_id=$job_id
done
