#!/bin/bash -l
#SBATCH --job-name=checkm2_IR
#SBATCH --account=project_2014298
#SBATCH --output=00_LOGS/checkm2_%A_%a.out
#SBATCH --error=00_LOGS/checkm2_%A_%a.err
#SBATCH --time=04:00:00
#SBATCH --partition=small
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=40G
#SBATCH --array=4-9
#SBATCH --gres=nvme:500

SAMPLE=IR${SLURM_ARRAY_TASK_ID}

BASE=/scratch/project_2014298/oztunaim/META
BIN_DIR=${BASE}/09_BINNING/METABAT/${SAMPLE}
OUTDIR=${BASE}/10_MAG_QC/CHECKM2/${SAMPLE}

mkdir -p ${OUTDIR}

module load checkm2

checkm2 predict \
  --input ${BIN_DIR} \
  --output-directory ${OUTDIR} \
  --threads ${SLURM_CPUS_PER_TASK} \
  -x fa \
  --tmpdir $LOCAL_SCRATCH

echo "CheckM2 finished for ${SAMPLE}"



