# Spores-to-Genomics

A comprehensive Master's thesis project for analyzing microbial genomics data from environmental spores using metagenomic and genomic workflows.

## Overview

This repository contains a complete bioinformatic pipeline for analyzing microbial communities from environmental samples across three analysis layers:
- **Metagenomic (Layer 1)**: Taxonomic classification and functional gene profiling
- **Metagenomic Assembly (Layer 2)**: Genome assembly, quality assessment, and binning
- **Isolate Genomes (Layer 3)**: Long-read assembly, annotation, and secondary metabolite detection

## Project Structure

### Layer 1: Metagenomic Analysis

| Script | Purpose |
|--------|---------|
| `1.1.Kraken2` | Taxonomic classification using Kraken2 database |
| `1.2.Bracken` | Abundance estimation and statistical analysis |
| `1.3.Diamond_Raw` | Homology search against NCBI NR database |
| `1.4.Diamond_Filter_Nitrogen` | Filter DIAMOND results for nitrogen-cycling genes |
| `1.5.Diamond_Filter_Sulfur` | Filter DIAMOND results for sulfur-cycling genes |
| `1.6.Diamond_Filter_Trace_Gas` | Filter DIAMOND results for trace gas metabolism genes |
| `1.7.Summary_Nitrogen` | Aggregate nitrogen gene abundance data |
| `1.8.Summary_Sulfur` | Aggregate sulfur gene abundance data |
| `1.9.Summary_Trace_Gas` | Aggregate trace gas gene abundance data |

**Key Features:**
- Taxonomic profiling of metagenomic reads
- Functional annotation of environmental genes
- Focus on nitrogen, sulfur, and trace gas metabolism genes

### Layer 2: Metagenomic Assembly

| Script | Purpose |
|--------|---------|
| `2.1.Megahit` | De novo metagenomic assembly |
| `2.2.Quast` | Assembly quality assessment and statistics |
| `2.3.Mapping` | Map reads back to assembled contigs for abundance |
| `2.4.Metabat` | Genome binning from assembled contigs |
| `2.5.CheckM2` | Assess bin quality (completeness and contamination) |
| `2.6.Taxonomy` | Taxonomic assignment of metagenomic bins (MAGs) |

**Key Features:**
- High-performance assembly with MEGAHIT
- Contig-based abundance profiling via read mapping
- Automatic binning into metagenome-assembled genomes (MAGs)
- Quality control and taxonomic classification of bins

### Layer 3: Isolate Genome Analysis

| Script | Purpose |
|--------|---------|
| `3.1.Autocycler` | Long-read assembly using PacBio/Oxford Nanopore data |
| `3.2.Quast` | Quality assessment of isolate assemblies |
| `3.3.Minimap2` | High-accuracy long-read mapping and polishing |
| `3.4.CheckM2` | Validate completeness and contamination of assemblies |
| `3.5.Taxonomy` | Assign taxonomy to isolate genomes |
| `3.6.Annotation` | Functional gene annotation using Bakta/NCBI |
| `3.7.Antismash` | Secondary metabolite cluster detection |

**Key Features:**
- Hybrid assembly strategies (long + short reads)
- High-quality genome polishing with Minimap2
- Comprehensive functional annotation
- Biosynthetic gene cluster discovery

## Python Utilities

### `antismash_parse.py`

**Purpose:** Parse antiSMASH JSON output and extract biosynthetic gene cluster (BGC) information.

**Features:**
- Extracts BGC regions from annotated genomes
- Maps regions to MIBiG (Minimum Information about Biosynthetic Gene clusters) database hits
- Generates CSV summary with:
  - Isolate name and region coordinates
  - Predicted cluster product (e.g., PKS, NRPS)
  - Most similar known cluster (from MIBiG)
  - Similarity percentage scores

**Usage:**
```bash
python antismash_parse.py <genbank_file> <json_file> <output_csv>
```

**Example:**
```bash
python antismash_parse.py all_isolates.gbk all_isolates.json antismash_regions.csv
```

**Sample Isolates:** IR4_N1, IR5_05, IR5_08, IR7_03, IR8_08, IR8_13, IR9_07

### `bakta_functional_genes.sh`

**Purpose:** Search Bakta TSV annotation files for functional genes related to biogeochemical cycling.

**Features:**
- Presence/absence matrix for 26 functional genes across 7 isolates
- Three functional categories:
  - **Nitrogen cycling** (12 genes): AmoA, NxrA, NarG, NapA, NirS, NirK, NrfA, NosZ, HzsA, NifH, NorB, Nod
  - **Sulfur cycling** (6 genes): DsrA, FCC, Sqr, Sor, AsrA, SoxB
  - **Trace gas metabolism** (7 genes): CoxL, FeFe, NiFe, PmoA, MmoA, McrA, IsoA

**Usage:**
```bash
bash bakta_functional_genes.sh
```

**Output Files:**
- `functional_genes_presence_absence.tsv` - Binary presence/absence matrix
- `functional_genes_counts.tsv` - Gene copy counts per isolate

**Isolate Stratification:**
- **Bottom layer:** IR4_N1
- **Transitional layer:** IR5_05, IR5_08, IR7_03
- **Top layer:** IR8_08, IR8_13, IR9_07

## Gene Categories

### Nitrogen Metabolism Genes
- **AmoA** - Ammonia monooxygenase (ammonia oxidation)
- **NxrA** - Nitrite oxidoreductase (nitrite oxidation)
- **NarG** - Nitrate reductase (dissimilatory nitrate reduction)
- **NapA** - Periplasmic nitrate reductase
- **NirS/NirK** - Nitrite reductase (denitrification)
- **NrfA** - Formate-dependent nitrite reductase
- **NosZ** - Nitrous oxide reductase
- **HzsA** - Hydrazine synthase (anammox)
- **NifH** - Nitrogenase iron protein (nitrogen fixation)
- **NorB** - Nitric oxide reductase
- **Nod** - Nodulation proteins

### Sulfur Metabolism Genes
- **DsrA** - Dissimilatory sulfite reductase
- **FCC** - Flavocytochrome c (sulfide oxidation)
- **Sqr** - Sulfide:quinone oxidoreductase
- **Sor** - Sulfur oxygenase/dioxygenase
- **AsrA** - Anaerobic sulfite reductase
- **SoxB** - Sulfur oxidation protein

### Trace Gas Metabolism Genes
- **CoxL** - Carbon monoxide dehydrogenase
- **FeFe/NiFe** - Hydrogenases (hydrogen metabolism)
- **PmoA/MmoA** - Methane monooxygenase variants
- **McrA** - Methyl-CoM reductase (methanogenesis)
- **IsoA** - Isoprene monooxygenase

## Repository Statistics

- **Primary Language:** Shell (91.7%)
- **Secondary Language:** Python (8.3%)
- **Total Scripts:** 25+
- **Analysis Stages:** 3 (Metagenomic → Assembly → Isolate)

## Dependencies

The scripts rely on the following bioinformatic tools (typically loaded via module system on HPC):

**Sequence Analysis:** Kraken2, DIAMOND, MEGAHIT, Minimap2
**Quality Assessment:** QUAST, CheckM2
**Annotation:** Bakta, antiSMASH
**Genome Binning:** MetaBat2
**Statistics:** Bracken

## Project Details

**Thesis Focus:** Characterization of microbial metabolic diversity in stratified environmental samples through integrated metagenomic and genomic approaches.

**Isolate Sources:** Environmental spores from bottom, transitional, and top layers of a defined ecological sample.

## Contact & Attribution

This is a Master's thesis project. For questions about specific methodologies or script parameters, refer to the individual script headers which contain detailed documentation.

---

*Last updated: 2026-03-23*