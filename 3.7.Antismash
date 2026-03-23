#!/bin/bash
#SBATCH --job-name=antismash_isolates
#SBATCH --account=project_2014298
#SBATCH --time=24:00:00
#SBATCH --mem=80G
#SBATCH --cpus-per-task=12
#SBATCH --partition=small
#SBATCH --output /scratch/project_2014298/oztunaim/WGS/12_ANTISMASH/antismash_out_%j.txt
#SBATCH --error  /scratch/project_2014298/oztunaim/WGS/12_ANTISMASH/antismash_err_%j.txt

# Load antiSMASH
export PATH="/projappl/project_2014298/antismash_v8.0.4/bin:$PATH"

# Temp directory on scratch — antiSMASH creates large temp files
export TMPDIR=/scratch/project_2014298/oztunaim/WGS/12_ANTISMASH/tmp
mkdir -p $TMPDIR

# ── Paths ─────────────────────────────────────────────────────────────────────
INPUT_FASTA="/scratch/project_2014298/oztunaim/WGS/12_ANTISMASH/input/all_isolates_combined.fasta"
OUTPUT_DIR="/scratch/project_2014298/oztunaim/WGS/12_ANTISMASH/output"
# ─────────────────────────────────────────────────────────────────────────────

# antiSMASH aborts if output dir has existing content — remove and recreate
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "Starting antiSMASH..."
echo "Input:  $INPUT_FASTA"
echo "Output: $OUTPUT_DIR"
date

antismash \
    --genefinding-tool prodigal \
    "$INPUT_FASTA" \
    --output-dir "$OUTPUT_DIR" \
    --output-basename all_isolates \
    --cb-knownclusters \
    --cb-subclusters \
    --cb-general \
    --cc-mibig \
    --rre \
    --asf \
    --clusterhmmer \
    --tigrfam \
    --pfam2go \
    --smcog-trees \
    -c 12

echo ""
echo "antiSMASH finished!"
date
ls -lh "$OUTPUT_DIR"
