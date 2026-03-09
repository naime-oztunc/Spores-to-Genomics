#!/bin/bash -l
#SBATCH --job-name=quast_array
#SBATCH --account=project_2014298
#SBATCH --output=06_ASSEMBLY/LOGS/quast_array_out_%A_%a.txt
#SBATCH --error=06_ASSEMBLY/LOGS/quast_array_err_%A_%a.txt
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=small
#SBATCH --array=1-9

module load quast

# Get sample name from sample_names.txt
SAMPLE=$(sed -n ${SLURM_ARRAY_TASK_ID}p sample_names.txt)

echo "[$(date)] Starting QUAST quality assessment for sample: $SAMPLE on $(hostname)"

ASSEMBLY="06_ASSEMBLY/MEGAHIT/${SAMPLE}/${SAMPLE}.contigs.fa"
OUTDIR="06_ASSEMBLY/QUAST/${SAMPLE}"

# Check if assembly file exists
if [[ ! -f "$ASSEMBLY" ]]; then
    echo "[$(date)] ERROR: Assembly file not found: $ASSEMBLY" >&2
    exit 1
fi

mkdir -p $OUTDIR

quast.py $ASSEMBLY \
    -o $OUTDIR \
    --threads $SLURM_CPUS_PER_TASK \
    --min-contig 200

if [ $? -eq 0 ]; then
    echo "[$(date)] SUCCESS: QUAST quality assessment finished for $SAMPLE"
else
    echo "[$(date)] ERROR: QUAST quality assessment failed for $SAMPLE" >&2
    exit 1
fi
