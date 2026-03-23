#!/bin/bash -l
#SBATCH --job-name=bracken_array
#SBATCH --account=project_2014298
#SBATCH --output=00_LOGS/bracken_out_%A_%a.txt
#SBATCH --error=00_LOGS/bracken_err_%A_%a.txt
#SBATCH --time=04:00:00
#SBATCH --partition=small
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --array=1-9

# Adjust database path
BRACKEN_DB="/appl/data/bio/biodb/production/kraken/standard"

# Sample name
SAMPLE=$(sed -n ${SLURM_ARRAY_TASK_ID}p sample_names.txt)

echo "Running Bracken on $SAMPLE"

bracken \
  -d "$BRACKEN_DB" \
  -i 03_KRAKEN_NEW/kraken_reports/${SAMPLE}_report.txt \
  -o 03_KRAKEN_NEW/kraken_reports/${SAMPLE}_bracken.txt \
  -r 150 \
  -l S

echo "Finished $SAMPLE"


