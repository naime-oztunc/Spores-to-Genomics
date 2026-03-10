#!/bin/bash -l
#SBATCH --job-name=megahit_array
#SBATCH --account=project_2014298
#SBATCH --output=06_ASSEMBLY/LOGS/megahit_array_out_%A_%a.txt
#SBATCH --error=06_ASSEMBLY/LOGS/megahit_array_err_%A_%a.txt
#SBATCH --time=12:00:00
#SBATCH --mem=40G
#SBATCH --cpus-per-task=8
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gres=nvme:500
#SBATCH --array=4-9

cd /scratch/project_2014298/oztunaim/META

module load megahit/1.2.9

# Get sample name from sample_names.txt
SAMPLE=$(sed -n ${SLURM_ARRAY_TASK_ID}p sample_names.txt)

echo "[$(date)] Starting MEGAHIT assembly for sample: $SAMPLE on $(hostname)"

megahit \
    -1 02_TRIMMED/${SAMPLE}_R1.fastq.gz \
    -2 02_TRIMMED/${SAMPLE}_R2.fastq.gz \
    -o 06_ASSEMBLY/MEGAHIT/${SAMPLE} \
    --out-prefix ${SAMPLE} \
    -t 8 \
    --min-contig-len 200 \
    --tmp-dir $LOCAL_SCRATCH

if [ $? -eq 0 ]; then
    echo "[$(date)] SUCCESS: MEGAHIT assembly finished for $SAMPLE"
else
    echo "[$(date)] ERROR: MEGAHIT assembly failed for $SAMPLE" >&2
    exit 1
fi
