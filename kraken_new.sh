#!/bin/bash -l
#SBATCH --job-name=kraken2_array
#SBATCH --account=project_2014298
#SBATCH --output=00_LOGS/kraken2_array_out_%A_%a.txt
#SBATCH --error=00_LOGS/kraken2_array_err_%A_%a.txt
#SBATCH --time=12:00:00
#SBATCH --partition=longrun
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=76000
#SBATCH --array=1-9               

name=$(sed -n ${SLURM_ARRAY_TASK_ID}p sample_names.txt)

# Path to Kraken2 database
DB=/appl/data/bio/biodb/production/kraken/standard

# Run Kraken2 for paired-end reads
kraken2 \
  --db $DB \
  --threads $SLURM_CPUS_PER_TASK \
  --paired \
  02_TRIMMED/${name}_R1.fastq.gz 02_TRIMMED/${name}_R2.fastq.gz \
  --output 03_KRAKEN_NEW/kraken_outputs/${name}_output.txt \
  --report 03_KRAKEN_NEW/kraken_reports/${name}_report.txt

echo "Kraken2 classification finished for $name"
