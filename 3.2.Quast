#!/bin/bash
#SBATCH --job-name=quast
#SBATCH --account=project_2014298
#SBATCH --time=01:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=4
#SBATCH --partition=small
#SBATCH --array=1-30
#SBATCH --output=69_AUTOCYCLER/01_QUAST/00_LOGS/quast_out_%A_%a.txt
#SBATCH --error=69_AUTOCYCLER/01_QUAST/00_LOGS/quast_err_%A_%a.txt


cd /scratch/project_2014298/oztunaim/WGS

# Create directories
mkdir -p 69_AUTOCYCLER/01_QUAST/00_LOGS

# Get sample name for this array task
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" sample2_names.txt)

# Safety check
if [[ -z "${SAMPLE}" ]]; then
    echo "ERROR: No sample name found for array task ${SLURM_ARRAY_TASK_ID}"
    exit 1
fi

# Load QUAST module
module load quast

# Define input and output
ASSEMBLY="69_AUTOCYCLER/${SAMPLE}_autocycler/consensus_assembly.fasta"
OUTDIR="69_AUTOCYCLER/01_QUAST/${SAMPLE}_quast"

# Check input exists
if [[ ! -f "${ASSEMBLY}" ]]; then
    echo "ERROR: Assembly not found: ${ASSEMBLY}"
    exit 1
fi

# Run QUAST
echo "Running QUAST on ${ASSEMBLY}"
quast.py \
  "${ASSEMBLY}" \
  -o "${OUTDIR}" \
  --threads 4


