#!/bin/bash -l
#SBATCH --job-name=diamond_combine
#SBATCH --account=project_2014298
#SBATCH --output=00_LOGS/diamond_combine_out_%A_%a.txt
#SBATCH --error=00_LOGS/diamond_combine_err_%A_%a.txt
#SBATCH --time=08:00:00
#SBATCH --partition=small
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=40G
#SBATCH --array=1-9


DB="/scratch/project_2014298/00_DATABASES/MeMaGe/funcgenes.dmnd"
OUT_DIR="05_DIAMOND/Raw"
mkdir -p "$OUT_DIR"

SAMPLE=$(sed -n ${SLURM_ARRAY_TASK_ID}p sample_names.txt)
echo "[$(date)] Sample: $SAMPLE on $(hostname)"

# input files 
R1=$(ls 02_TRIMMED/${SAMPLE}_R1*.fastq.gz 2>/dev/null | head -n1)
R2=$(ls 02_TRIMMED/${SAMPLE}_R2*.fastq.gz 2>/dev/null | head -n1)

if [[ -z "$R1" && -z "$R2" ]]; then
  echo "No input files found for $SAMPLE (R1 or R2). Exiting."
  exit 1
fi

# Run DIAMOND for R1 (if exists)
if [[ -n "$R1" ]]; then
  echo "Running DIAMOND R1 for $SAMPLE"
  diamond blastx --db "$DB" --query "$R1" \
    --out "${OUT_DIR}/${SAMPLE}_R1_Funcgenes.txt" \
    --query-cover 80 --max-target-seqs 1 \
    --threads $SLURM_CPUS_PER_TASK \
    --outfmt 6
else
  echo "R1 missing for $SAMPLE"
fi

# Run DIAMOND for R2 (if exists)
if [[ -n "$R2" ]]; then
  echo "Running DIAMOND R2 for $SAMPLE"
  diamond blastx --db "$DB" --query "$R2" \
    --out "${OUT_DIR}/${SAMPLE}_R2_Funcgenes.txt" \
    --query-cover 80 --max-target-seqs 1 \
    --threads $SLURM_CPUS_PER_TASK \
    --outfmt 6 
else
  echo "R2 missing for $SAMPLE"
fi

# Combine R1 and R2 results into a single combined file and collapse by pair id:
# - we extract a pair id by stripping common mate suffixes (/1, /2, _1, _2, :1, :2)
# - for each pair id we keep the line with max bitscore (field 10)
COMBINED="${OUT_DIR}/${SAMPLE}_Funcgenes_Combined.txt"
echo "Combining and deduplicating into $COMBINED"

# cat available files and process with awk
cat ${OUT_DIR}/${SAMPLE}_R1_Funcgenes.txt 2>/dev/null \
    ${OUT_DIR}/${SAMPLE}_R2_Funcgenes.txt 2>/dev/null \
  | awk -F'\t' '
  function pairid(q,   pid) {
    pid=q
    # remove common mate suffixes: /1 or /2 at end
    sub(/\/[12]$/,"",pid)
    # remove _1 or _2 at end
    sub(/_[12]$/,"",pid)
    # remove :1 or :2 at end
    sub(/:[12]$/,"",pid)
    return pid
  }
  {
    q=$1; bits=$10+0
    pid=pairid(q)
    # keep line with highest bitscore per pair id
    if (!(pid in best) || bits > best[pid]) {
       best[pid]=bits
       line[pid]=$0
    }
  }
  END{
    for (p in line) print line[p]
  }' > "$COMBINED"

echo "Done combine for $SAMPLE. Combined file lines: $(wc -l < "$COMBINED")"
echo "Finished $SAMPLE at $(date)"



