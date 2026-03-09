# Kraken2-Bracken-DIAMOND Pipeline

Scripts for running Kraken2 taxonomic classification, Bracken abundance estimation, DIAMOND functional gene analysis .

## Scripts

### kraken2_array.sh
Performs paired-end Kraken2 classification using SLURM array jobs.

**Requirements:**
- SLURM job scheduler
- Kraken2 installed
- Kraken2 database (standard database)
- Input: Paired-end FASTQ files in `02_TRIMMED/` directory

**Usage:**
```bash
sbatch kraken2_array.sh
```

**Parameters:**
- Time limit: 12 hours
- CPUs per task: 8
- Memory: 76GB
- Array range: 1-9

**Output:**
- Classification outputs: `03_KRAKEN_NEW/kraken_outputs/`
- Reports: `03_KRAKEN_NEW/kraken_reports/`

---

### bracken_array.sh
Estimates relative abundance of species/genus using Bracken.

**Requirements:**
- SLURM job scheduler
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
- SLURM job scheduler
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

## Workflow

1. **Trimming** : Quality trim your FASTQ files
2. **Kraken2**: Run `kraken2_array.sh` to classify reads taxonomically
3. **Bracken**: Run `bracken_array.sh` to estimate abundance from Kraken2 reports
4. **DIAMOND**: Run `diamond_combine.sh` to annotate functional genes
5. **Filter Nitrogen**: Run `filter_nitrogen_thr.sh` to extract nitrogen metabolism genes
6. **Filter Sulfur**: Run `filter_sulfur_thr.sh` to extract sulfur metabolism genes
7. **Filter Trace Gas**: Run `filter_trace_gas_thr.sh` to extract trace gas metabolism genes

## Project Structure
```
.
├── kraken2_array.sh              # Kraken2 classification
├── bracken_array.sh              # Bracken abundance estimation
├── diamond_combine.sh            # DIAMOND functional annotation
├── filter_nitrogen_thr.sh        # Nitrogen gene filtering
├── filter_sulfur_thr.sh          # Sulfur gene filtering
├── filter_trace_gas_thr.sh       # Trace gas gene filtering
├── sample_names.txt              # List of sample names
├── 02_TRIMMED/                   # Input trimmed FASTQ files
├── 03_KRAKEN_NEW/
│   ├── kraken_outputs/           # Kraken2 output files
│   └── kraken_reports/           # Kraken2 reports & Bracken outputs
├── 05_DIAMOND/
│   ├── Raw/                      # DIAMOND results
│   ├── Filtered_Nitrogen/        # Filtered nitrogen genes
│   ├── Filtered_Sulfur/          # Filtered sulfur genes
│   └── Filtered_Trace_Gas/       # Filtered trace gas genes
└── 00_LOGS/                      # SLURM log files
```

