#!/bin/bash -l
#SBATCH --job-name=annotate_isolates
#SBATCH --account=project_2014298
#SBATCH --time=12:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=8
#SBATCH --partition=small
#SBATCH --array=1-7
#SBATCH --output=10_ANNOTATION/LOGS/annotate_%A_%a.out
#SBATCH --error=10_ANNOTATION/LOGS/annotate_%A_%a.err

cd /scratch/project_2014298/oztunaim/WGS

# Create directories
mkdir -p 10_ANNOTATION/{LOGS,bakta,amrfinder}

echo "============================================"
echo "Genome Annotation: Bakta + AMRFinderPlus"
echo "Job started at: $(date)"
echo "Array task ID: $SLURM_ARRAY_TASK_ID"
echo "============================================"
echo ""

# Load environment
export PATH="/projappl/project_2014298/tykky_bakta/bin:$PATH"

# Read sample name
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" sample_names.txt)
echo "Processing isolate: $SAMPLE"
echo ""

# Set paths
ASSEMBLY="05_AUTOCYCLER/${SAMPLE}_autocycler/consensus_assembly.fasta"
BAKTA_OUT="10_ANNOTATION/bakta/${SAMPLE}"
AMR_OUT="10_ANNOTATION/amrfinder/${SAMPLE}"
BAKTA_DB="/scratch/project_2014298/oztunaim/BAKTA_DB/db"
AMR_DB="/scratch/project_2014298/oztunaim/AMRFINDER_DB"
THREADS=8

# Verify assembly exists
if [ ! -f "$ASSEMBLY" ]; then
    echo "ERROR: Assembly not found: $ASSEMBLY"
    exit 1
fi

echo "Assembly: $ASSEMBLY"
echo "Contigs: $(grep -c '^>' $ASSEMBLY)"
echo ""

#==============================================
# STEP 1: Bakta Annotation
#==============================================
echo "STEP 1: Running Bakta annotation..."
echo "Start time: $(date)"
echo ""

bakta \
  --db $BAKTA_DB \
  --output $BAKTA_OUT \
  --prefix ${SAMPLE} \
  --threads $THREADS \
  --verbose \
  --complete \
  --min-contig-length 200 \
  --keep-contig-headers \
  $ASSEMBLY

if [ $? -eq 0 ]; then
    echo "Bakta annotation completed"
else
    echo "Bakta annotation failed"
    exit 1
fi

echo ""

#==============================================
# STEP 2: AMRFinderPlus Analysis
#==============================================
echo "STEP 2: Running AMRFinderPlus..."
echo "Start time: $(date)"
echo ""

mkdir -p $AMR_OUT

# Run AMRFinderPlus on protein sequences from Bakta
PROTEINS="$BAKTA_OUT/${SAMPLE}.faa"
GENES="$BAKTA_OUT/${SAMPLE}.ffn"

if [ -f "$PROTEINS" ]; then

    amrfinder \
      --protein $PROTEINS \
      --nucleotide $GENES \
      --gff $BAKTA_OUT/${SAMPLE}.gff3 \
      --database $AMR_DB \
      --threads $THREADS \
      --plus \
      --output $AMR_OUT/${SAMPLE}_amr.tsv \
      --mutation_all $AMR_OUT/${SAMPLE}_mutations.tsv

    if [ $? -eq 0 ]; then
        echo "AMRFinderPlus completed"
    else
        echo "AMRFinderPlus failed"
    fi
else
    echo "ERROR: Protein file not found: $PROTEINS"
fi

echo ""

#==============================================
# STEP 3: Summarize Results
#==============================================
echo "STEP 3: Summarizing results..."
echo ""

echo "=== BAKTA SUMMARY ==="
if [ -f "$BAKTA_OUT/${SAMPLE}.txt" ]; then
    cat $BAKTA_OUT/${SAMPLE}.txt
fi

echo ""
echo "=== ANNOTATION STATISTICS ==="
GFF="$BAKTA_OUT/${SAMPLE}.gff3"
if [ -f "$GFF" ]; then
    echo "CDS: $(grep -c 'CDS' $GFF)"
    echo "tRNA: $(grep -c 'tRNA' $GFF)"
    echo "rRNA: $(grep -c 'rRNA' $GFF)"
fi

echo ""
echo "=== AMR GENES DETECTED ==="
AMR_TSV="$AMR_OUT/${SAMPLE}_amr.tsv"
if [ -f "$AMR_TSV" ]; then
    AMR_COUNT=$(tail -n +2 $AMR_TSV | wc -l)
    echo "Total AMR genes: $AMR_COUNT"

    if [ $AMR_COUNT -gt 0 ]; then
        echo ""
        echo "Top AMR genes found:"
        tail -n +2 $AMR_TSV | cut -f6,7 | head -10
    else
        echo "No AMR genes detected"
    fi
else
    echo "AMR results file not found"
fi

echo ""

#==============================================
# STEP 4: Functional Categories
#==============================================
echo "STEP 4: Extracting functional categories..."
echo ""

if [ -f "$GFF" ]; then

    echo "=== GENES OF INTEREST ==="
    echo ""

    echo "Sulfur metabolism:"
    grep -i "sulfur\|sulph\|sox\|dsr\|sqr" $GFF | grep "CDS" | wc -l

    echo "Nitrogen metabolism:"
    grep -i "nitrogen\|nitro\|nir\|nar\|nos\|nrf" $GFF | grep "CDS" | wc -l

    echo "Spore formation:"
    grep -i "spore\|sporulation" $GFF | grep "CDS" | wc -l

    echo "Stress response:"
    grep -i "stress\|heat\|cold\|desiccation" $GFF | grep "CDS" | wc -l

fi

echo ""

#==============================================
# COMPLETION
#==============================================
echo "============================================"
echo "Annotation complete for $SAMPLE!"
echo "Job finished at: $(date)"
echo "============================================"
echo ""
echo "Results:"
echo "  Bakta: $BAKTA_OUT"
echo "  AMRFinder: $AMR_OUT"
echo ""
echo "Key files:"
echo "  - ${SAMPLE}.gff3 (annotations)"
echo "  - ${SAMPLE}.faa (proteins)"
echo "  - ${SAMPLE}_amr.tsv (AMR genes)"
echo ""

