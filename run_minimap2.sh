#!/bin/bash
#SBATCH --job-name=minimap2_array
#SBATCH --account=project_2014298
#SBATCH --time=08:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=16
#SBATCH --partition=small
#SBATCH --array=1-30
#SBATCH --output=12_MAPPING/00_LOGS/minimap2_%A_%a_out.txt
#SBATCH --error=12_MAPPING/00_LOGS/minimap2_%A_%a_err.txt

cd /scratch/project_2014298/oztunaim/WGS

# Create directories
mkdir -p 12_MAPPING/00_LOGS


# Read sample name from isolate list
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" sample2_names.txt)
echo "Processing isolate: $SAMPLE"
echo ""

# Set paths
ASSEMBLY=69_AUTOCYCLER/${SAMPLE}_autocycler/consensus_assembly.fasta
READS=003_TRIMMED/${SAMPLE}.filt.fastq.gz
OUTDIR=12_MAPPING/${SAMPLE}
THREADS=16

# Create output directory
mkdir -p $OUTDIR

# Verify files exist
if [ ! -f "$ASSEMBLY" ]; then
    echo "ERROR: Assembly not found: $ASSEMBLY"
    exit 1
fi

if [ ! -f "$READS" ]; then
    echo "ERROR: Reads not found: $READS"
    exit 1
fi

echo "Assembly: $ASSEMBLY"
echo "Reads: $READS"
echo "Output: $OUTDIR"
echo ""

# Load required modules
module load biokit


echo "STEP 1: Mapping PacBio HiFi reads to assembly..."
echo "Start time: $(date)"

minimap2 -ax map-hifi \
  $ASSEMBLY \
  $READS \
  -t $THREADS \
  2> $OUTDIR/minimap2.log | \
samtools view -bS - | \
samtools sort -@ 4 -o $OUTDIR/${SAMPLE}.sorted.bam

echo "Mapping complete"
echo "End time: $(date)"
echo ""


echo "STEP 2: Indexing BAM file..."

samtools index $OUTDIR/${SAMPLE}.sorted.bam

echo "Indexing complete"
echo ""


echo "STEP 3: Generating mapping statistics..."
echo ""

# Flagstat
echo "=== Flagstat Results ===" | tee $OUTDIR/mapping_stats.txt
samtools flagstat $OUTDIR/${SAMPLE}.sorted.bam | tee -a $OUTDIR/mapping_stats.txt
echo "" | tee -a $OUTDIR/mapping_stats.txt

# Coverage per contig
echo "=== Coverage Statistics ===" | tee -a $OUTDIR/mapping_stats.txt
samtools coverage $OUTDIR/${SAMPLE}.sorted.bam | tee -a $OUTDIR/mapping_stats.txt
echo "" | tee -a $OUTDIR/mapping_stats.txt

# Mean depth
echo "=== Depth Statistics ===" | tee -a $OUTDIR/mapping_stats.txt
samtools depth $OUTDIR/${SAMPLE}.sorted.bam | \
  awk '{sum+=$3; count++} END {print "Mean depth: " sum/count}' | \
  tee -a $OUTDIR/mapping_stats.txt

# Per-base depth distribution
samtools depth $OUTDIR/${SAMPLE}.sorted.bam > $OUTDIR/${SAMPLE}_depth.txt

echo ""
echo "Statistics generated"
echo ""


echo "STEP 4: Extracting key metrics..."

# Get total reads
TOTAL_READS=$(samtools view -c $OUTDIR/${SAMPLE}.sorted.bam)

# Get mapped reads
MAPPED_READS=$(samtools view -c -F 4 $OUTDIR/${SAMPLE}.sorted.bam)

# Calculate mapping rate
MAPPING_RATE=$(echo "scale=2; $MAPPED_READS * 100 / $TOTAL_READS" | bc)

# Get mean coverage
MEAN_COV=$(samtools depth $OUTDIR/${SAMPLE}.sorted.bam | awk '{sum+=$3; count++} END {print sum/count}')

# Summary
echo "=== Summary ===" | tee -a $OUTDIR/mapping_stats.txt
echo "Sample: $SAMPLE" | tee -a $OUTDIR/mapping_stats.txt
echo "Total reads: $TOTAL_READS" | tee -a $OUTDIR/mapping_stats.txt
echo "Mapped reads: $MAPPED_READS" | tee -a $OUTDIR/mapping_stats.txt
echo "Mapping rate: ${MAPPING_RATE}%" | tee -a $OUTDIR/mapping_stats.txt
echo "Mean coverage: ${MEAN_COV}x" | tee -a $OUTDIR/mapping_stats.txt
echo "" | tee -a $OUTDIR/mapping_stats.txt

echo "Metrics extracted"
echo ""

echo "Results location: $OUTDIR"
echo "BAM file: $OUTDIR/${SAMPLE}.sorted.bam"
echo "Statistics: $OUTDIR/mapping_stats.txt"
echo "Depth file: $OUTDIR/${SAMPLE}_depth.txt"
echo ""
echo "Key metrics:"
echo "  - Mapping rate: ${MAPPING_RATE}% (should be >95%)"
echo "  - Mean coverage: ${MEAN_COV}x"
echo ""

