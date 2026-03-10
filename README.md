# Thesis Pipeline

Scripts for running metagenomic analysis including Kraken2 taxonomic classification, Bracken abundance estimation, DIAMOND functional gene analysis, MEGAHIT assembly, and QUAST quality assessment on HPC clusters.

## Scripts

### kraken2_array.sh
Performs paired-end Kraken2 classification using SLURM array jobs.

**Requirements:**
- Kraken2 installed--used the one in Puhti
- Kraken2 database (standard database)
- Input: Paired-end FASTQ files in `02_TRIMMED/` directory

**Usage:**
```bash
sbatch kraken2_array.sh
```

**Parameters:**
- Time limit: 12 hours--depends on your sample number/size
- CPUs per task: 8
- Memory: 76GB
- Array range: 1-9

**Output:**
- Classification outputs: `03_KRAKEN_NEW/kraken_outputs/`
- Reports: `03_KRAKEN_NEW/kraken_reports/`

#You can check your Kraken2 results with Krona it is also in Puhti module biokit
---

### bracken_array.sh
Estimates relative abundance of species/genus using Bracken.

**Requirements:**
- Bracken installed
- Kraken2 database with Bracken database files
- Input: Kraken2 report files from `kraken2_array.sh`

**Usage:**
```bash
sbatch bracken_array.sh
```

**Parameters:**
- Time limit: 4 hours
- CPUs per task: 2
- Memory: 8GB
- Array range: 1-9
- Read length (-r): 150
- Classification level (-l): S (species)

**Output:**
- Bracken abundance estimates: `03_KRAKEN_NEW/kraken_reports/*_bracken.txt`

---

### diamond_combine.sh
Performs functional annotation using DIAMOND against the MeMaGe functional genes database.

**Requirements:**
- DIAMOND installed
- DIAMOND formatted database (MeMaGe funcgenes.dmnd)
- Input: Paired-end trimmed FASTQ files in `02_TRIMMED/` directory

**Usage:**
```bash
sbatch diamond_combine.sh
```

**Parameters:**
- Time limit: 8 hours
- CPUs per task: 4
- Memory: 40GB
- Array range: 1-9
- Query coverage: 80%
- Max target sequences: 1
- Output format: BLAST tabular (format 6)

**Output:**
- R1 results: `05_DIAMOND/Raw/*_R1_Funcgenes.txt`
- R2 results: `05_DIAMOND/Raw/*_R2_Funcgenes.txt`
- Combined & deduplicated: `05_DIAMOND/Raw/*_Funcgenes_Combined.txt`

**Features:**
- Processes both R1 and R2 reads independently
- Combines results from both read pairs
- Deduplicates by pair ID (removes mate suffixes like /1, /2, _1, _2, :1, :2)
- Keeps only the hit with highest bitscore per pair
- Provides detailed logging with timestamps

---

### filter_nitrogen_thr.sh
Filters and extracts nitrogen metabolism genes from DIAMOND results based on sequence identity thresholds.

**Requirements:**
- DIAMOND results in `05_DIAMOND/Raw/` directory
- Input: Combined DIAMOND results from `diamond_combine.sh`

**Usage:**
```bash
sbatch filter_nitrogen_thr.sh
```

**Parameters:**
- Time limit: 2 hours
- CPUs per task: 1
- Memory: 4GB

**Genes and Thresholds:**
| Gene | Identity Threshold (%) | Function |
|------|------------------------|----------|
| AmoA | 60 | Ammonia monooxygenase |
| NxrA | 60 | Nitrite oxidoreductase |
| NarG | 50 | Nitrate reductase |
| NapA | 50 | Periplasmic nitrate reductase |
| NirS | 50 | Nitrite reductase (cd1) |
| NirK | 50 | Nitrite reductase (copper) |
| NrfA | 50 | Nitrite reductase (formate-dependent) |
| NosZ | 50 | Nitrous oxide reductase |
| HzsA | 50 | Hydrazine synthase |
| NifH | 50 | Nitrogenase iron protein |
| NorB | 50 | Nitric oxide reductase |
| Nod | 50 | Nodulation protein |

**Output:**
- Filtered results: `05_DIAMOND/Filtered_Nitrogen/*_<GENE>_filtered.txt`
- One file per gene per sample (12 genes × N samples)

**Features:**
- Case-insensitive gene name matching
- Filters by sequence identity threshold (column 3)
- Separate output files per gene for easy analysis
- Fast single-threaded processing

---

### filter_sulfur_thr.sh
Filters and extracts sulfur metabolism genes from DIAMOND results based on sequence identity thresholds.

**Requirements:**
- DIAMOND results in `05_DIAMOND/Raw/` directory
- Input: Combined DIAMOND results from `diamond_combine.sh`

**Usage:**
```bash
sbatch filter_sulfur_thr.sh
```

**Parameters:**
- Time limit: 2 hours
- CPUs per task: 1
- Memory: 4GB

**Genes and Thresholds:**
| Gene | Identity Threshold (%) | Function |
|------|------------------------|----------|
| DsrA | 50 | Dissimilatory sulfite reductase |
| FCC | 50 | Flavocytochrome c |
| Sqr | 50 | Sulfide quinone oxidoreductase |
| Sor | 50 | Sulfide oxidation protein |
| AsrA | 50 | Anaerobic sulfite reductase |
| SoxB | 50 | Sulfur oxidation protein |

**Output:**
- Filtered results: `05_DIAMOND/Filtered_Sulfur/*_<GENE>_filtered.txt`
- One file per gene per sample (6 genes × N samples)

**Features:**
- Case-insensitive gene name matching
- Filters by sequence identity threshold (column 3)
- Separate output files per gene for easy analysis
- Fast single-threaded processing

---

### filter_trace_gas_thr.sh
Filters and extracts trace gas metabolism genes from DIAMOND results based on sequence identity thresholds.

**Requirements:**
- DIAMOND results in `05_DIAMOND/Raw/` directory
- Input: Combined DIAMOND results from `diamond_combine.sh`

**Usage:**
```bash
sbatch filter_trace_gas_thr.sh
```

**Parameters:**
- Time limit: 2 hours
- CPUs per task: 1
- Memory: 4GB

**Genes and Thresholds:**
| Gene | Identity Threshold (%) | Function |
|------|------------------------|----------|
| CoxL | 60 | Carbon monoxide dehydrogenase |
| FeFe | 60 | [FeFe] Hydrogenase |
| [Fe] | 50 | [Fe] Hydrogenase |
| NiFe | 50 | [NiFe] Hydrogenase |
| PmoA | 50 | Particulate methane monooxygenase |
| MmoA | 60 | Soluble methane monooxygenase |
| McrA | 50 | Methyl-coenzyme M reductase |
| IsoA | 70 | Isoprenyl diphosphate isomerase |

**Output:**
- Filtered results: `05_DIAMOND/Filtered_Trace_Gas/*_<GENE>_filtered.txt`
- One file per gene per sample (8 genes × N samples)

**Features:**
- Case-insensitive gene name matching
- Filters by sequence identity threshold (column 3)
- Separate output files per gene for easy analysis
- Fast single-threaded processing

---

### megahit_array.sh
Performs metagenomic assembly using MEGAHIT on paired-end reads.

**Requirements:**
- MEGAHIT installed--used version 2.17, 2.18 is not working properly in Puhti
- Input: Paired-end trimmed FASTQ files in `02_TRIMMED/` directory
- Local scratch space available (`$LOCAL_SCRATCH`)

**Usage:**
```bash
sbatch megahit_array.sh
```

**Parameters:**
- Time limit: 12 hours
- CPUs per task: 8
- Memory: 40GB
- Array range: 1-9
- Minimum contig length: 200 bp
- Temporary directory: `$LOCAL_SCRATCH` (fast local storage)
- GPU scratch allocation: 500GB

**Output:**
- Assembled contigs: `06_ASSEMBLY/MEGAHIT/<SAMPLE>/<SAMPLE>.contigs.fa`
- Additional MEGAHIT output files in sample-specific directories

**Features:**
- Parallel assembly for all samples
- Uses local scratch for faster temporary file operations
- Detailed logging with timestamps
- Error handling and validation
- Automatic directory creation

**Notes:**
- Each sample assembly runs independently and in parallel
- MEGAHIT uses all 8 available CPUs for optimal performance
- Requires sufficient local scratch space on compute nodes
- Run QUAST after MEGAHIT completes for quality assessment

---

### quast_array.sh
Performs quality assessment of assembled contigs using QUAST.

**Requirements:**
- SLURM job scheduler
- QUAST installed
- Input: Assembled contigs from `megahit_array.sh`
- Output from MEGAHIT in `06_ASSEMBLY/MEGAHIT/` directory

**Usage:**
```bash
sbatch quast_array.sh
```

**Parameters:**
- Time limit: 4 hours
- CPUs per task: 4
- Memory: 16GB
- Partition: small
- Array range: 1-9
- Minimum contig length: 200 bp

**Output:**
- Quality reports: `06_ASSEMBLY/QUAST/<SAMPLE>/report.html`
- Detailed statistics: `06_ASSEMBLY/QUAST/<SAMPLE>/report.txt`
- Additional metrics in sample-specific directories

**Features:**
- Parallel quality assessment for all samples
- Validates assembly file existence before running
- Detailed logging with timestamps
- Error handling and validation
- Generates comprehensive quality metrics

**Notes:**
- Run MEGAHIT before running QUAST
- Script checks if assembly files exist before starting
- Each sample quality assessment runs independently
- QUAST reports include N50, L50, number of contigs, and more

---

## Complete Workflow

```
Step 1: Quality Trimming 
    ↓
Step 2: Kraken2 Taxonomic Classification
    sbatch kraken2_array.sh
    ↓
Step 3: Bracken Abundance Estimation
    sbatch bracken_array.sh
    ↓
Step 4: DIAMOND Functional Annotation
    sbatch diamond_combine.sh
    ↓
Step 5a: Filter Nitrogen Genes          Step 5b: Filter Sulfur Genes          Step 5c: Filter Trace Gas Genes
    sbatch filter_nitrogen_thr.sh           sbatch filter_sulfur_thr.sh          sbatch filter_trace_gas_thr.sh
    (can run in parallel)
    ↓
Step 6: MEGAHIT Assembly
    sbatch megahit_array.sh
    ↓
Step 7: QUAST Quality Assessment
    sbatch quast_array.sh
```

## Project Structure
```
.
├── kraken2_array.sh              # Kraken2 classification
├── bracken_array.sh              # Bracken abundance estimation
├── diamond_combine.sh            # DIAMOND functional annotation
├── filter_nitrogen_thr.sh        # Nitrogen gene filtering
├── filter_sulfur_thr.sh          # Sulfur gene filtering
├── filter_trace_gas_thr.sh       # Trace gas gene filtering
├── megahit_array.sh              # MEGAHIT assembly
├── quast_array.sh                # QUAST quality assessment
├── sample_names.txt              # List of sample names (one per line)
├── 02_TRIMMED/                   # Input trimmed FASTQ files
├── 03_KRAKEN_NEW/
│   ├── kraken_outputs/           # Kraken2 output files
│   └── kraken_reports/           # Kraken2 reports & Bracken outputs
├── 05_DIAMOND/
│   ├── Raw/                      # DIAMOND results
│   ├── Filtered_Nitrogen/        # Filtered nitrogen genes
│   ├── Filtered_Sulfur/          # Filtered sulfur genes
│   └── Filtered_Trace_Gas/       # Filtered trace gas genes
├── 06_ASSEMBLY/
│   ├── MEGAHIT/                  # MEGAHIT assembly results
│   ├── QUAST/                    # QUAST quality reports
│   └── LOGS/                     # Assembly job logs
└── 00_LOGS/                      # Other SLURM job logs
```

## Getting Started

### Prerequisites
1. Ensure you have a `sample_names.txt` file with one sample name per line (9 samples for array range 1-9)
2. Trimmed FASTQ files in `02_TRIMMED/` directory following naming convention: `{SAMPLE}_R1.fastq.gz` and `{SAMPLE}_R2.fastq.gz`
3. All required tools installed and loaded via modules

### Quick Start Example
```bash
# 1. Create sample_names.txt
cat > sample_names.txt << EOF
sample1
sample2
sample3
sample4
sample5
sample6
sample7
sample8
sample9
EOF

# 2. Create necessary directories
mkdir -p 02_TRIMMED 03_KRAKEN_NEW/kraken_outputs 03_KRAKEN_NEW/kraken_reports
mkdir -p 05_DIAMOND/Raw 05_DIAMOND/Filtered_Nitrogen 05_DIAMOND/Filtered_Sulfur 05_DIAMOND/Filtered_Trace_Gas
mkdir -p 06_ASSEMBLY/MEGAHIT 06_ASSEMBLY/QUAST 06_ASSEMBLY/LOGS
mkdir -p 00_LOGS

# 3. Submit jobs in sequence
sbatch kraken2_array.sh
# Wait for completion...
sbatch bracken_array.sh
sbatch diamond_combine.sh
sbatch filter_nitrogen_thr.sh
sbatch filter_sulfur_thr.sh
sbatch filter_trace_gas_thr.sh
sbatch megahit_array.sh
# Wait for MEGAHIT...
sbatch quast_array.sh
```

## Monitoring Jobs

```bash
# Check job status
squeue --me

# Check specific job details
scontrol show job <JOB_ID>

# Cancel a job
scancel <JOB_ID>

# View job logs
tail -f 00_LOGS/kraken2_array_out_*.txt
```

## Important Notes

- Make sure `sample_names.txt` contains exactly 9 sample names (one per line)
- Update database paths if using different databases:
  - Kraken2: `/appl/data/bio/biodb/production/kraken/standard`
  - DIAMOND: `/scratch/project_2014298/00_DATABASES/MeMaGe/funcgenes.dmnd`
- Array jobs allow samples to be processed in parallel, significantly reducing total runtime
- Filtering scripts (nitrogen, sulfur, trace gas) can run in parallel after DIAMOND completes
- Always run MEGAHIT before QUAST for quality assessment
- Adjust resource parameters (CPUs, memory, time) based on your data size
- Use `$LOCAL_SCRATCH` for temporary files to improve I/O performance on MEGAHIT
