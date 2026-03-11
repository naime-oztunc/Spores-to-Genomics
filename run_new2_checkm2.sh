#!/bin/bash
#SBATCH --job-name=checkm2
#SBATCH --account=project_2014298
#SBATCH --time=02:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=4
#SBATCH --partition=small
#SBATCH --array=1-30
#SBATCH --output=69_AUTOCYCLER/02_CHECKM2/00_LOGS/checkm2_out_%A_%a.txt
#SBATCH --error=69_AUTOCYCLER/02_CHECKM2/00_LOGS/checkm2_err_%A_%a.txt

cd /scratch/project_2014298/oztunaim/WGS

# Create directories
mkdir -p 69_AUTOCYCLER/02_CHECKM2/00_LOGS

# Get sample name for this array task
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" sample2_names.txt)

# Safety check
if [[ -z "${SAMPLE}" ]]; then
    echo "ERROR: No sample name found for array task ${SLURM_ARRAY_TASK_ID}"
    exit 1
fi

# Set temp directory (per-sample, avoids collisions)
TMPDIR="/scratch/project_2014298/oztunaim/WGS/69_AUTOCYCLER/02_CHECKM2/tmp/${SAMPLE}"
export TMPDIR
export TEMP=$TMPDIR
export TMP=$TMPDIR
mkdir -p "$TMPDIR"

echo "============================================"
echo "CheckM2 Genome Quality Assessment"
echo "Sample: ${SAMPLE}"
echo "Job ID: ${SLURM_JOB_ID}"
echo "Array task ID: ${SLURM_ARRAY_TASK_ID}"
echo "Job started at: $(date)"
echo "Temp directory: ${TMPDIR}"
echo "============================================"
echo ""

# Load CheckM2
module load checkm2

# Define input and output
ASSEMBLY="69_AUTOCYCLER/${SAMPLE}_autocycler/consensus_assembly.fasta"
OUTDIR="69_AUTOCYCLER/02_CHECKM2/${SAMPLE}_checkm2"

# Check input exists
if [[ ! -f "${ASSEMBLY}" ]]; then
    echo "ERROR: Assembly not found: ${ASSEMBLY}"
    exit 1
fi

# Run CheckM2
echo "Running CheckM2 on ${ASSEMBLY}"
checkm2 predict \
  --input "${ASSEMBLY}" \
  --output-directory "${OUTDIR}" \
  --threads 4 \
  --tmpdir "${TMPDIR}" \
  -x fasta

echo ""

# Clean up temp files
rm -rf "${TMPDIR}"

echo "============================================"
echo "CheckM2 Complete for ${SAMPLE}"
echo "Job finished at: $(date)"
echo "============================================"

