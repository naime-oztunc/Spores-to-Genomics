#!/bin/bash
#SBATCH --job-name=autocycler
#SBATCH --account=project_2014298
#SBATCH --time=48:00:00
#SBATCH --mem=120G
#SBATCH --cpus-per-task=16
#SBATCH --partition=longrun
#SBATCH --array=1-30   #includes Taru's isolates too#
#SBATCH --output=69_AUTOCYCLER/00_LOGS/autocycler_%A_%a_out.txt
#SBATCH --error=69_AUTOCYCLER/00_LOGS/autocycler_%A_%a_err.txt


cd /scratch/project_2014298/oztunaim/WGS

# Create directories
mkdir -p 69_AUTOCYCLER/00_LOGS

# Set temp directory to scratch
export TMPDIR=/scratch/project_2014298/oztunaim/WGS/69_AUTOCYCLER/tmp_${SLURM_ARRAY_TASK_ID}
mkdir -p $TMPDIR

echo "Autocycler Pipeline"
echo "Job started at: $(date)"
echo "Array task ID: $SLURM_ARRAY_TASK_ID"

AUTOCYCLER=/projappl/project_2014298/tykky_autocycler/bin/autocycler
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" sample2_names.txt)
READS=003_TRIMMED/${SAMPLE}.filt.fastq.gz
OUTDIR=69_AUTOCYCLER/${SAMPLE}_autocycler
THREADS=16
READ_TYPE="pacbio_hifi"

echo "Processing isolate: $SAMPLE"
echo ""

# Verify input file exists
if [ ! -f "$READS" ]; then
    echo "ERROR: Input reads file not found: $READS"
    exit 1
fi

echo "Reads: $READS"
echo "Output: $OUTDIR"
echo ""


# Estimate genome size

echo "Step 1: Estimating genome size..."
GENOME_SIZE=$($AUTOCYCLER helper genome_size --reads $READS --threads $THREADS)
if [ $? -ne 0 ]; then
    echo "ERROR: Genome size estimation failed"
    exit 1
fi
echo "  Estimated genome size: $GENOME_SIZE"
echo ""


#Subsample reads into 4 files

echo "Step 2: Subsampling reads into 4 files..."
$AUTOCYCLER subsample --reads $READS --out_dir $OUTDIR/subsampled_reads --genome_size $GENOME_SIZE
if [ $? -ne 0 ]; then
    echo "ERROR: Subsampling failed"
    exit 1
fi
echo "  Subsampling complete"
echo ""


#Run all 6 assemblers on each subsample

mkdir -p $OUTDIR/assemblies
echo "Step 3: Running assemblies with 6 assemblers (this will take some fuckin times)..."
echo "Note: Individual assembly failures are normal and will be skipped"
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0

# List of assemblers to use
ASSEMBLERS="flye canu miniasm hifiasm lja raven"

for i in 01 02 03 04; do
    echo "=== Processing subsample $i ==="

    for assembler in $ASSEMBLERS; do
        echo "  Running $assembler on sample $i..."

        # Different assemblers have different requirements
        case $assembler in
            flye)
                $AUTOCYCLER helper flye \
                    --reads $OUTDIR/subsampled_reads/sample_$i.fastq \
                    --out_prefix $OUTDIR/assemblies/${assembler}_$i \
                    --threads $THREADS \
                    --read_type $READ_TYPE
                ;;
            canu)
                $AUTOCYCLER helper canu \
                    --reads $OUTDIR/subsampled_reads/sample_$i.fastq \
                    --out_prefix $OUTDIR/assemblies/${assembler}_$i \
                    --threads $THREADS \
                    --genome_size $GENOME_SIZE \
                    --read_type $READ_TYPE
                ;;
            miniasm)
                $AUTOCYCLER helper miniasm \
                    --reads $OUTDIR/subsampled_reads/sample_$i.fastq \
                    --out_prefix $OUTDIR/assemblies/${assembler}_$i \
                    --threads $THREADS \
                    --read_type $READ_TYPE
                ;;
            hifiasm)
                $AUTOCYCLER helper hifiasm \
                    --reads $OUTDIR/subsampled_reads/sample_$i.fastq \
                    --out_prefix $OUTDIR/assemblies/${assembler}_$i \
                    --threads $THREADS \
                    --read_type $READ_TYPE
                ;;
            lja)
                $AUTOCYCLER helper lja \
                    --reads $OUTDIR/subsampled_reads/sample_$i.fastq \
                    --out_prefix $OUTDIR/assemblies/${assembler}_$i \
                    --threads $THREADS
                ;;
            raven)
                $AUTOCYCLER helper raven \
                    --reads $OUTDIR/subsampled_reads/sample_$i.fastq \
                    --out_prefix $OUTDIR/assemblies/${assembler}_$i \
                    --threads $THREADS
                ;;
        esac

        if [ $? -eq 0 ]; then
            echo "     $assembler $i succeeded"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            echo "     $assembler $i failed (will continue)"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    done

    echo "  Subsample $i complete"
    echo ""
done

echo "Assembly Summary:"
echo "  Successful assemblies: $SUCCESS_COUNT / 24"
echo "  Failed assemblies: $FAIL_COUNT / 24"
echo ""

# Check if we have enough successful assemblies (at least 6)
if [ $SUCCESS_COUNT -lt 6 ]; then
    echo "ERROR: Too few successful assemblies ($SUCCESS_COUNT). Need at least 6."
    exit 1
fi

echo "Continuing with $SUCCESS_COUNT assemblies (sufficient for consensus)"
echo ""


#Remove subsampled reads to save space

echo "Cleaning up subsampled reads to save disk space..."
rm -f $OUTDIR/subsampled_reads/*.fastq
echo ""

#Compress assemblies

echo "Step 4: Compressing assemblies into unitig graph..."
$AUTOCYCLER compress -i $OUTDIR/assemblies -a $OUTDIR
if [ $? -ne 0 ]; then
    echo "ERROR: Compression failed"
    exit 1
fi
echo "  Compression complete"
echo ""


#Cluster contigs

echo "Step 5: Clustering contigs..."
$AUTOCYCLER cluster -a $OUTDIR
if [ $? -ne 0 ]; then
    echo "ERROR: Clustering failed"
    exit 1
fi
echo "  Clustering complete"
echo ""


#Trim and resolve each QC-pass cluster

echo "Step 6 & 7: Trimming and resolving clusters..."
CLUSTER_COUNT=0
for c in $OUTDIR/clustering/qc_pass/cluster_*; do
    if [ -d "$c" ]; then
        CLUSTER_COUNT=$((CLUSTER_COUNT + 1))
        echo "  Processing cluster: $(basename $c)"
        $AUTOCYCLER trim -c "$c"
        $AUTOCYCLER resolve -c "$c"
    fi
done

if [ $CLUSTER_COUNT -eq 0 ]; then
    echo "  WARNING: No QC-pass clusters found!"
    echo "  Check $OUTDIR/clustering/ for details"
    exit 1
else
    echo "  Processed $CLUSTER_COUNT cluster(s)"
fi
echo ""


#Combine into final assembly

echo "Step 8: Combining into final consensus assembly..."
$AUTOCYCLER combine -a $OUTDIR -i $OUTDIR/clustering/qc_pass/cluster_*/5_final.gfa
if [ $? -ne 0 ]; then
    echo "ERROR: Combine step failed"
    exit 1
fi
echo "  Final assembly created"
echo ""


#Quality assessment

echo "Step 9: Quick quality check..."

# Count contigs
CONTIG_COUNT=$(grep -c "^>" $OUTDIR/consensus_assembly.fasta)
echo "  Number of contigs: $CONTIG_COUNT"

# Get assembly size
ASSEMBLY_SIZE=$(grep -v "^>" $OUTDIR/consensus_assembly.fasta | tr -d '\n' | wc -c)
echo "  Assembly size: $ASSEMBLY_SIZE bp"

echo ""

echo "Cleaning up temporary files..."
rm -rf $TMPDIR
echo ""

echo "Autocycler Pipeline Complete!"
echo "Job finished at: $(date)"
echo "Assembly Summary:"
echo "  Sample: $SAMPLE"
echo "  Successful assemblies used: $SUCCESS_COUNT / 24"
echo "  Failed assemblies skipped: $FAIL_COUNT / 24"
echo "  Final contigs: $CONTIG_COUNT"
echo "  Assembly size: $ASSEMBLY_SIZE bp"
echo ""
echo "Results location: $OUTDIR"
echo "Final assembly: $OUTDIR/consensus_assembly.fasta"
echo ""




