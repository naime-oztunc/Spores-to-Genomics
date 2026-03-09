# Spores-to-Genomics

# Kraken2 

SLURM batch scripts for running Kraken2 taxonomic classification on HPC clusters.

## Scripts

### kraken2_array
Performs paired-end Kraken2 classification using SLURM array jobs.

**Requirements:**
- Kraken2 installed
- Kraken2 database (standard database in this project)
- Input: Paired-end FASTQ files in `02_TRIMMED/` directory
- Sample names in `sample_names.txt` file

**Usage:**
```bash
sbatch kraken2_array.sh
```

**Parameters:**
- Job name: kraken2_array
- Time limit: 12 hours
- CPUs per task: 8
- Memory: 76GB
- Array range: 1-9 (processes 9 samples)

**Output:**
- Classification outputs: `03_KRAKEN_NEW/kraken_outputs/`
- Reports: `03_KRAKEN_NEW/kraken_reports/`

## Project Structure
```
.
├── kraken2_array.sh          # Main SLURM script
├── sample_names.txt          # List of sample names
├── 02_TRIMMED/               # Input trimmed FASTQ files
├── 03_KRAKEN_NEW/
│   ├── kraken_outputs/       # Kraken2 output files
│   └── kraken_reports/       # Classification reports
└── 00_LOGS/                  # SLURM log files
```
