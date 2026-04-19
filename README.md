# From Spores to Genomics: How Human Interaction Shapes Microbiomes in Archaeological Samples from Turku

#Slides:https://drive.google.com/file/d/1AloB3aY6ZGda-S3fpj1G9mUZgP2Ngoh4/view?usp=sharing

## 0. Abstract

Archaeological sites preserve more than artifacts, they also contain biological traces, including microorganisms that reflect past human activities and environmental changes. Humans leave a biological fingerprint in the soil, much like the physical artifacts they leave behind. While many microbes die over time, some survive, and a few even thrive thanks to their special traits. These resilient microorganisms provide insights into the past and may even offer tools for the future through their unique survival strategies and biosynthetic potential.

This study investigates how human interaction has shaped the diversity, composition, and functional potential of microbial communities preserved in stratified archaeological layers at Itäinen Rantakatu in Turku, Finland. We analyzed nine samples using metagenomic sequencing and performed cultivation on six samples representing a gradient from natural deposits to highly human-impacted latrine layers. Taxonomic profiling and functional gene analysis focused on metabolic pathways related to sulfur and nitrogen cycling, as well as trace gas metabolism. Selected cultivated isolates underwent whole-genome sequencing to explore their biosynthetic potential.

---

## 1. What this repository is (for first-time visitors)

This repository is the computational pipeline for my Master’s thesis.

It combines three analysis layers:

1. **Metagenomic community profiling**  
   - Who is present in each sample (taxonomy)
   - What functions are present (functional genes)

2. **MAG reconstruction (metagenome-assembled genomes)**  
   - Recover draft genomes directly from metagenomic reads
   - Check quality and assign taxonomy

3. **Isolate genome analysis**  
   - Assemble cultured isolates with long reads
   - Annotate genomes and detect biosynthetic potential (antiSMASH)

If you are new to microbial genomics: this README explains not only *what each script does*, but also *why it exists in the pipeline* and *how outputs flow between scripts*.

---

## 2. Biological question and logic of the pipeline

### Main thesis question
How did past human activity (low human impact vs high human impact archaeological layers) shape microbial diversity and microbial functional potential?

### Pipeline logic
The pipeline answers this by moving from broad to detailed:

- **Step A: Community-level view** (Kraken2/Bracken, DIAMOND)  
  Gives a high-level ecological profile.

- **Step B: Genome-resolved view from metagenomes** (MEGAHIT → MetaBAT2 → CheckM2 → GTDB-Tk)  
  Recovers draft genomes (MAGs) to connect functions to genomes.

- **Step C: Cultured isolate genome view** (Autocycler, Bakta, antiSMASH)  
  Provides high-quality isolate genomes for deeper functional and biosynthetic interpretation.

---

## 3. Directory and naming conventions

This section helps you map script inputs/outputs quickly.

### Key sample lists
- `sample_names.txt` → used mostly in metagenome branch
- `sample2_names.txt` → used in isolate branch 

### Important input folders
- `02_TRIMMED/` → trimmed paired-end metagenomic reads
- `003_TRIMMED/` → trimmed isolate HiFi reads

### Major output folders
- `03_KRAKEN_NEW/` → Kraken2 + Bracken outputs
- `05_DIAMOND/` → functional gene hits, filtered files, summary matrices
- `06_ASSEMBLY/`, `07_MAPPING/`, `09_BINNING/`, `10_MAG_QC/`, `13_GTDBTK_OUT/` → MAG workflow
- `69_AUTOCYCLER/`, `12_MAPPING/`, `13_GTDBTK/`, `10_ANNOTATION/`, `12_ANTISMASH/` → isolate workflow

---

## 4. Section A — Metagenomic taxonomy and functional profiling

---

### 4.1 Script: Kraken2 (`1.1.Kraken2`)

#### Purpose
Classify reads taxonomically against a reference standard database.

#### Why it matters
This is the first “who is there?” step.

#### Core command
```bash name=1.1.Kraken2
kraken2 \
  --db /appl/data/bio/biodb/production/kraken/standard \
  --threads $SLURM_CPUS_PER_TASK \
  --paired \
  02_TRIMMED/${name}_R1.fastq.gz 02_TRIMMED/${name}_R2.fastq.gz \
  --output 03_KRAKEN_NEW/kraken_outputs/${name}_output.txt \
  --report 03_KRAKEN_NEW/kraken_reports/${name}_report.txt
```

#### Input
- `02_TRIMMED/${sample}_R1.fastq.gz`
- `02_TRIMMED/${sample}_R2.fastq.gz`

#### Output
- `03_KRAKEN_NEW/kraken_outputs/${sample}_output.txt`
- `03_KRAKEN_NEW/kraken_reports/${sample}_report.txt`

---

### 4.2 Script: Bracken (`1.2.Bracken`)

#### Purpose
Refine Kraken2 classification into abundance estimates (species level).

#### Why it matters
Kraken2 gives assignments; Bracken improves quantitative abundance interpretation.

#### Core command
```bash name=1.2.Bracken
bracken \
  -d "$BRACKEN_DB" \
  -i 03_KRAKEN_NEW/kraken_reports/${SAMPLE}_report.txt \
  -o 03_KRAKEN_NEW/kraken_reports/${SAMPLE}_bracken.txt \
  -r 150 \
  -l S
```

#### Input
- Kraken2 report from previous step

#### Output
- Bracken abundance file per sample

---

### 4.3 Script: DIAMOND raw search (`1.3.Diamond_Raw`)

#### Purpose
Map reads to functional gene database (`funcgenes.dmnd`) using `blastx`.

#### Why it matters
This is the core “what functions are present?” stage.

#### Core commands
```bash name=1.3.Diamond_Raw_R1
diamond blastx --db "$DB" --query "$R1" \
  --out "${OUT_DIR}/${SAMPLE}_R1_Funcgenes.txt" \
  --query-cover 80 --max-target-seqs 1 \
  --threads $SLURM_CPUS_PER_TASK \
  --outfmt 6
```

```bash name=1.3.Diamond_Raw_R2
diamond blastx --db "$DB" --query "$R2" \
  --out "${OUT_DIR}/${SAMPLE}_R2_Funcgenes.txt" \
  --query-cover 80 --max-target-seqs 1 \
  --threads $SLURM_CPUS_PER_TASK \
  --outfmt 6
```

Then R1/R2 are merged and deduplicated by read-pair ID using highest bitscore.

#### Input
- Trimmed reads in `02_TRIMMED`

#### Output
- `*_R1_Funcgenes.txt`
- `*_R2_Funcgenes.txt`
- `*_Funcgenes_Combined.txt`

---

### 4.4 Script: Nitrogen filtering (`1.4.Diamond_Filter_Nitrogen`)

#### Purpose
Extract nitrogen-cycle genes from DIAMOND combined output with identity thresholds.

#### Filtering logic
```bash name=1.4.Nitrogen_filter_logic
grep -i -E "${gene}(-|\\b)" "$combined" \
  | awk -F'\t' -v t="$thr" '{ if ($3+0 >= t) print $0 }' > "$outf"
```

#### Genes used
- AmoA, NxrA, NarG, NapA, NirS, NirK, NrfA, NosZ, HzsA, NifH, NorB, Nod

#### Output
- `05_DIAMOND/Filtered_Nitrogen/${sample}_${gene}_filtered.txt`

---

### 4.5 Script: Sulfur filtering (`1.5.Diamond_Filter_Sulfur`)

#### Purpose
Extract sulfur-cycle genes with identity thresholds.

#### Genes used
- DsrA, FCC, Sqr, Sor, AsrA, SoxB

#### Output
- `05_DIAMOND/Filtered_Sulfur/${sample}_${gene}_filtered.txt`

---

### 4.6 Script: Trace gas filtering (`1.6.Diamond_Filter_Trace_Gas`)

#### Purpose
Extract trace-gas/gas-related metabolism markers.

#### Genes used
- CoxL, FeFe, NiFe, PmoA, MmoA, McrA, IsoA

#### Output
- `05_DIAMOND/Filtered_Trace_Gas/${sample}_${gene}_filtered.txt`

---

### 4.7 Summary scripts (`1.7`, `1.8`, `1.9`)

#### Purpose
Build gene-by-sample count matrices from filtered files.

#### Outputs
- `05_DIAMOND/Summary/nitrogen_gene_counts_matrix.tsv`
- `05_DIAMOND/Summary/sulfur_gene_counts_matrix.tsv`
- `05_DIAMOND/Summary/trace_gas_gene_counts_matrix.tsv`

#### Why it matters
These matrices are final comparative functional datasets for downstream plotting/statistics.

---

## 5. Section B — MAG reconstruction from metagenomes

---

### 5.1 Script: MEGAHIT (`2.1.Megahit`)

#### Purpose
Assemble short-read metagenomic reads into contigs.

```bash name=2.1.Megahit
megahit \
  -1 02_TRIMMED/${SAMPLE}_R1.fastq.gz \
  -2 02_TRIMMED/${SAMPLE}_R2.fastq.gz \
  -o 06_ASSEMBLY/MEGAHIT/${SAMPLE} \
  --out-prefix ${SAMPLE} \
  -t 8 \
  --min-contig-len 200
```

---

### 5.2 Script: QUAST (`2.2.Quast`)

#### Purpose
Evaluate assembly quality metrics (contig statistics, lengths, etc.).

---

### 5.3 Script: Bowtie2 mapping (`2.3.Mapping`)

#### Purpose
Map reads back to contigs and create depth-supported BAM files for binning.

#### Important details
- Filters contigs to >1000 bp before mapping
- Builds Bowtie2 index
- Produces sorted + indexed BAM
- Adds MD tags (`samtools calmd`)

#### Why it matters
Coverage/depth across contigs is essential input for MetaBAT2 binning.

---

### 5.4 Script: MetaBAT2 (`2.4.Metabat`)

#### Purpose
Create bins (candidate MAGs) using contig composition + coverage depth.

```bash name=2.4.Metabat
jgi_summarize_bam_contig_depths --outputDepth ${OUTDIR}/${SAMPLE}.depth.txt ${BAM}
metabat2 -i ${CONTIGS} -a ${OUTDIR}/${SAMPLE}.depth.txt \
  -o ${OUTDIR}/${SAMPLE}_bin -t ${SLURM_CPUS_PER_TASK}
```

---

### 5.5 Script: CheckM2 (`2.5.CheckM2`)

#### Purpose
Assess MAG quality (completeness/contamination).

---

### 5.6 Script: GTDB-Tk taxonomy (`2.6.Taxonomy`)

#### Purpose
Assign taxonomy to MAG bins using GTDB-Tk workflow.

---

## 6. Section C — Isolate long-read genome workflow

---

### 6.1 Script: Autocycler (`3.1.Autocycler`)

#### Purpose
Generate robust consensus assemblies from long-read isolates.

#### Workflow inside script
1. Estimate genome size  
2. Subsample reads into 4 subsets  
3. Run six assemblers on each subset  
4. Compress/cluster graph  
5. Trim/resolve clusters  
6. Combine to final consensus assembly

#### Final output
- `69_AUTOCYCLER/${SAMPLE}_autocycler/consensus_assembly.fasta`

---

### 6.2 Script: QUAST (`3.2.Quast`)

#### Purpose
Quality check of isolate consensus assemblies.

---

### 6.3 Script: Minimap2 (`3.3.Minimap2`)

#### Purpose
Map HiFi reads back to isolate consensus assembly and calculate mapping metrics.

```bash name=3.3.Minimap2
minimap2 -ax map-hifi $ASSEMBLY $READS -t $THREADS \
  | samtools view -bS - \
  | samtools sort -o $OUTDIR/${SAMPLE}.sorted.bam
```

#### Outputs include
- sorted/indexed BAM
- flagstat / coverage stats
- depth file
- mapping summary (mapping rate, mean depth)

---

### 6.4 Script: CheckM2 (`3.4.CheckM2`)

#### Purpose
QC metrics for isolate assemblies.

---

### 6.5 Script: GTDB-Tk (`3.5.Taxonomy`)

#### Purpose
Taxonomic assignment of isolate genomes with additional parsed summary outputs:
- full lineage
- ANI and AF metrics
- novelty assessment from ANI thresholds
- simplified taxonomy TSV

---

### 6.6 Script: Bakta annotation (`3.6.Annotation`)

#### Purpose
Functional annotation of isolate genomes.

```bash name=3.6.Annotation
bakta \
  --db $BAKTA_DB \
  --output $BAKTA_OUT \
  --prefix ${SAMPLE} \
  --threads 8 \
  --verbose \
  --complete \
  --min-contig-length 200 \
  --keep-contig-headers \
  $ASSEMBLY
```

---

### 6.7 Script: antiSMASH (`3.7.Antismash`)

#### Purpose
Detect biosynthetic gene clusters from combined isolate assemblies.

```bash name=3.7.Antismash
antismash \
  --genefinding-tool prodigal \
  "$INPUT_FASTA" \
  --output-dir "$OUTPUT_DIR" \
  --output-basename all_isolates \
  --cb-knownclusters --cb-subclusters --cb-general --cc-mibig \
  --rre --asf --clusterhmmer --tigrfam --pfam2go --smcog-trees \
  -c 12
```

---

## 7. Full script I/O table (compact reference)

```text name=script_io_reference.txt
1.1 Kraken2: trimmed PE reads -> kraken output/report
1.2 Bracken: kraken report -> species abundance report
1.3 Diamond_Raw: trimmed reads -> R1/R2 functional hits + combined dedup hits
1.4 N filter: combined DIAMOND -> per-sample per-gene nitrogen files
1.5 S filter: combined DIAMOND -> per-sample per-gene sulfur files
1.6 Trace filter: combined DIAMOND -> per-sample per-gene trace-gas files
1.7 Summary N: filtered N files -> nitrogen matrix TSV
1.8 Summary S: filtered S files -> sulfur matrix TSV
1.9 Summary Trace: filtered trace files -> trace-gas matrix TSV
2.1 Megahit: PE reads -> contigs
2.2 Quast: contigs -> assembly QC report
2.3 Mapping: contigs + PE reads -> sorted/calmd/indexed BAM
2.4 Metabat: contigs + BAM depth -> MAG bins
2.5 CheckM2: bins -> MAG quality metrics
2.6 GTDB-Tk: MAGs -> MAG taxonomy
3.1 Autocycler: isolate HiFi reads -> consensus assembly
3.2 Quast: isolate consensus assembly -> QC report
3.3 Minimap2: consensus + HiFi reads -> BAM + mapping stats
3.4 CheckM2: isolate assembly -> isolate QC metrics
3.5 GTDB-Tk: isolate assembly -> isolate taxonomy + parsed summary
3.6 Bakta: isolate assembly -> annotation outputs
3.7 AntiSMASH: combined isolates fasta -> BGC predictions
```


## 8. Troubleshooting guide

---

### Problem A: Sample name is empty
**Error pattern:** “No sample name found …”  
**Check:** array size vs lines in sample file.

```bash name=check_sample_list.sh
wc -l sample_names.txt
wc -l sample2_names.txt
```

---

### Problem B: Input FASTQ not found
**Check:** exact expected naming conventions.

```bash name=check_fastq_names.sh
ls 02_TRIMMED/*_R1.fastq.gz | head
ls 003_TRIMMED/*.filt.fastq.gz | head
```

---

### Problem C: DIAMOND filtering gives empty outputs
May be biological absence or threshold too strict.

1. Check raw DIAMOND lines  
2. Test grep pattern manually for one gene

```bash name=debug_gene_hit.sh
wc -l 05_DIAMOND/Raw/SAMPLE_Funcgenes_Combined.txt
grep -i -E "AmoA(-|\\b)" 05_DIAMOND/Raw/SAMPLE_Funcgenes_Combined.txt | head
```

---

### Problem D: Mapping/bam failure in MAG branch
Ensure all three exist:
- contigs
- R1
- R2

The script already checks these, but path mismatches are common.

---

### Problem E: GTDB-Tk crashes due to resources/temp
- increase memory/time
- ensure tmp path exists and is writable
- clean old tmp dirs

---

### Problem F: antiSMASH output exists error
Your script safely removes output dir before rerun:

```bash name=antismash_reset_outdir.sh
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
```


## 9. Final interpretation: what this pipeline delivers

Using this workflow, the thesis can compare archaeological layers by:

- **Taxonomic composition** (community identity shifts)
- **Functional potential** in nitrogen/sulfur/trace-gas cycling
- **Genome-resolved evidence** from MAGs
- **Cultured isolate potential**, including biosynthetic gene clusters

This builds a complete narrative from environmental DNA signals to genome-level interpretation of human-impacted archaeological microbiomes.
