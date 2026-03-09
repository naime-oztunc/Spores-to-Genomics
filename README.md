# Kraken2-Bracken Pipeline

Scripts for running Kraken2 taxonomic classification and Bracken abundance estimation.

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

## Workflow

1. **Trimming** : Quality trim your FASTQ files
2. **Kraken2**: Run `kraken2_array.sh` to classify reads
3. **Bracken**: Run `bracken_array.sh` to estimate abundance from Kraken2 reports

## Project Structure
```
.
├── kraken2_array.sh              # Kraken2 classification
├── bracken_array.sh              # Bracken abundance estimation
├── sample_names.txt              # List of sample names
├── 02_TRIMMED/                   # Input trimmed FASTQ files
├── 03_KRAKEN_NEW/
│   ├── kraken_outputs/           # Kraken2 output files
│   └── kraken_reports/           # Kraken2 reports & Bracken outputs
└── 00_LOGS/                      # SLURM log files
```


