#!/bin/bash -l
#SBATCH --job-name=gtdbtk_isolates
#SBATCH --account=project_2014298
#SBATCH --time=24:00:00
#SBATCH --mem=120G
#SBATCH --cpus-per-task=16
#SBATCH --partition=longrun
#SBATCH --array=1-30
#SBATCH --output=13_GTDBTK/00_LOGS/gtdbtk_%A_%a.out
#SBATCH --error=13_GTDBTK/00_LOGS/gtdbtk_%A_%a.err
#SBATCH --gres=nvme:500

cd /scratch/project_2014298/oztunaim/WGS

# Create directories
mkdir -p 13_GTDBTK/{00_LOGS,individual_results,genomes}

echo "============================================"
echo "GTDB-Tk Taxonomic Classification - Isolates"
echo "Job started at: $(date)"
echo "Array task ID: $SLURM_ARRAY_TASK_ID"
echo "Node: $SLURMD_NODENAME"
echo "============================================"
echo ""

#==============================================
# SETUP
#==============================================

# Read sample name
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" sample2_names.txt)
echo "Processing isolate: $SAMPLE"

# Set paths
ASSEMBLY="69_AUTOCYCLER/${SAMPLE}_autocycler/consensus_assembly.fasta"
OUTDIR="13_GTDBTK/individual_results/${SAMPLE}"
GENOME_DIR="13_GTDBTK/genomes_${SAMPLE}"
THREADS=16

# Verify assembly exists
if [ ! -f "$ASSEMBLY" ]; then
    echo "ERROR: Assembly not found: $ASSEMBLY"
    exit 1
fi

# Check assembly quality
CONTIGS=$(grep -c "^>" $ASSEMBLY)
SIZE=$(grep -v "^>" $ASSEMBLY | tr -d '\n' | wc -c)

echo "Assembly info:"
echo "  File: $ASSEMBLY"
echo "  Contigs: $CONTIGS"
echo "  Size: $SIZE bp"
echo ""

# Create sample-specific genome directory
mkdir -p $GENOME_DIR
cp $ASSEMBLY $GENOME_DIR/${SAMPLE}.fasta

echo "Genome directory: $GENOME_DIR"
echo "Output directory: $OUTDIR"
echo ""

# Load module
module load gtdbtk

echo "GTDB-Tk version:"
gtdbtk --version
echo ""

#==============================================
# STEP 1: Run GTDB-Tk Classification
#==============================================
echo "STEP 1: Running GTDB-Tk classify_wf..."
echo "Start time: $(date)"
echo ""

gtdbtk classify_wf \
  --genome_dir $GENOME_DIR \
  --out_dir $OUTDIR \
  --extension fasta \
  --cpus $THREADS \
  --pplacer_cpus 4 \
  --skip_ani_screen

GTDBTK_EXIT=$?

echo ""
if [ $GTDBTK_EXIT -eq 0 ]; then
    echo "GTDB-Tk classification completed successfully"
else
    echo "GTDB-Tk classification failed with exit code: $GTDBTK_EXIT"
    exit 1
fi
echo "End time: $(date)"
echo ""

#==============================================
# STEP 2: Parse and Summarize Results
#==============================================
echo "STEP 2: Parsing classification results..."
echo ""

SUMMARY="$OUTDIR/gtdbtk.bac120.summary.tsv"
OUTPUT_SUMMARY="$OUTDIR/${SAMPLE}_classification_summary.txt"

if [ ! -f "$SUMMARY" ]; then
    echo "ERROR: Summary file not found: $SUMMARY"
    exit 1
fi

# Start output summary
{
    echo "============================================"
    echo "GTDB-Tk Classification Results"
    echo "Sample: $SAMPLE"
    echo "Date: $(date)"
    echo "============================================"
    echo ""

    # Extract full classification
    echo "=== FULL CLASSIFICATION ==="
    CLASSIFICATION=$(tail -n +2 $SUMMARY | cut -f2)
    echo "$CLASSIFICATION"
    echo ""

    # Parse taxonomic levels
    echo "=== TAXONOMIC BREAKDOWN ==="
    DOMAIN=$(echo $CLASSIFICATION | awk -F';' '{print $1}')
    PHYLUM=$(echo $CLASSIFICATION | awk -F';' '{print $2}')
    CLASS=$(echo $CLASSIFICATION | awk -F';' '{print $3}')
    ORDER=$(echo $CLASSIFICATION | awk -F';' '{print $4}')
    FAMILY=$(echo $CLASSIFICATION | awk -F';' '{print $5}')
    GENUS=$(echo $CLASSIFICATION | awk -F';' '{print $6}')
    SPECIES=$(echo $CLASSIFICATION | awk -F';' '{print $7}')

    echo "Domain:  $DOMAIN"
    echo "Phylum:  $PHYLUM"
    echo "Class:   $CLASS"
    echo "Order:   $ORDER"
    echo "Family:  $FAMILY"
    echo "Genus:   $GENUS"
    echo "Species: $SPECIES"
    echo ""

    # Extract metrics
    echo "=== CLASSIFICATION METRICS ==="
    FASTANI_REF=$(tail -n +2 $SUMMARY | cut -f3)
    FASTANI_ANI=$(tail -n +2 $SUMMARY | cut -f8)
    FASTANI_AF=$(tail -n +2 $SUMMARY | cut -f9)
    RED_VALUE=$(tail -n +2 $SUMMARY | cut -f11)

    echo "Closest reference: $FASTANI_REF"
    echo "ANI to reference:  $FASTANI_ANI%"
    echo "Aligned fraction:  $FASTANI_AF%"
    echo "RED value:         $RED_VALUE"
    echo ""

    # Novelty assessment
    echo "=== NOVELTY ASSESSMENT ==="
    if [ ! -z "$FASTANI_ANI" ]; then
        ANI_FLOAT=$(echo $FASTANI_ANI | bc -l 2>/dev/null || echo "0")

        if (( $(echo "$ANI_FLOAT < 95.0" | bc -l) )); then
            echo "Status: POTENTIALLY NOVEL SPECIES "
            echo "Reason: ANI < 95% (${FASTANI_ANI}%)"
        elif (( $(echo "$ANI_FLOAT < 99.0" | bc -l) )); then
            echo "Status: Known species, potentially novel strain"
            echo "Reason: ANI 95-99% (${FASTANI_ANI}%)"
        else
            echo "Status: Matches known species"
            echo "Reason: ANI ≥ 99% (${FASTANI_ANI}%)"
        fi
    else
        echo "Status: Unknown (ANI not available)"
    fi
    echo ""

    # Warnings
    echo "=== QUALITY CHECKS ==="
    if (( $(echo "$FASTANI_AF < 50" | bc -l) )); then
        echo "⚠ WARNING: Low aligned fraction (${FASTANI_AF}%)"
        echo "  This may indicate:"
        echo "  - Fragmented assembly"
        echo "  - Divergent genome"
        echo "  - Poor quality reference match"
    else
        echo " Good aligned fraction (${FASTANI_AF}%)"
    fi

    if [ "$CONTIGS" -gt 10 ]; then
        echo "WARNING: Fragmented assembly ($CONTIGS contigs)"
    else
        echo "Good assembly contiguity ($CONTIGS contigs)"
    fi
    echo ""

    # MSA and placement info
    echo "=== PHYLOGENETIC PLACEMENT ==="
    if [ -f "$OUTDIR/gtdbtk.bac120.markers_summary.tsv" ]; then
        MARKERS=$(tail -n +2 $OUTDIR/gtdbtk.bac120.markers_summary.tsv | cut -f2)
        echo "Single-copy markers found: $MARKERS/120"
    fi

} > $OUTPUT_SUMMARY

# Display summary
cat $OUTPUT_SUMMARY

#==============================================
# STEP 3: Create Simple Output Files
#==============================================
echo "STEP 3: Creating simplified output files..."

# Create simple taxonomy file
{
    echo -e "Sample\tDomain\tPhylum\tClass\tOrder\tFamily\tGenus\tSpecies\tANI\tNovelty"
    echo -e "$SAMPLE\t$DOMAIN\t$PHYLUM\t$CLASS\t$ORDER\t$FAMILY\t$GENUS\t$SPECIES\t$FASTANI_ANI\t$([ ! -z "$FASTANI_ANI" ] && (( $(echo "$FASTANI_ANI < 95.0" | bc -l) )) && echo "Novel" || echo "Known")"
} > $OUTDIR/${SAMPLE}_taxonomy.tsv

echo "  Created: ${SAMPLE}_taxonomy.tsv"

# Copy to main results directory
cp $SUMMARY 13_GTDBTK/${SAMPLE}_gtdbtk_summary.tsv
cp $OUTPUT_SUMMARY 13_GTDBTK/${SAMPLE}_summary.txt
cp $OUTDIR/${SAMPLE}_taxonomy.tsv 13_GTDBTK/${SAMPLE}_taxonomy.tsv

echo "  Copied results to main directory"
echo ""

#==============================================
# STEP 4: Cleanup
#==============================================
echo "STEP 4: Cleanup..."

# Remove temporary genome directory
rm -rf $GENOME_DIR

# Optional: compress large intermediate files
if [ -d "$OUTDIR/align" ]; then
    tar -czf $OUTDIR/align.tar.gz -C $OUTDIR align
    rm -rf $OUTDIR/align
    echo "  Compressed alignment directory"
fi

echo "  Cleanup complete"
echo ""

#==============================================
# COMPLETION
#==============================================
echo "============================================"
echo "GTDB-Tk Complete for $SAMPLE!"
echo "Job finished at: $(date)"
echo "============================================"
echo ""
echo "Results:"
echo "  Main summary:     13_GTDBTK/${SAMPLE}_summary.txt"
echo "  GTDB-Tk output:   13_GTDBTK/${SAMPLE}_gtdbtk_summary.tsv"
echo "  Simple taxonomy:  13_GTDBTK/${SAMPLE}_taxonomy.tsv"
echo "  Full results:     $OUTDIR/"
echo ""
echo "Quick classification:"
echo "  $CLASSIFICATION"
echo ""

# Check for novel species
if [ ! -z "$FASTANI_ANI" ] && (( $(echo "$FASTANI_ANI < 95.0" | bc -l) )); then
    echo "POTENTIAL NOVEL SPECIES DETECTED!"
    echo ""
fi
