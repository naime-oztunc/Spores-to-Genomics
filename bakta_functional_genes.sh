#!/bin/bash
# Run interactively: bash bakta_functional_genes.sh
# Searches Bakta TSV annotation files for functional genes
# Outputs presence/absence matrix for all 7 isolates
# ============================================================

BAKTA_DIR="/scratch/project_2014298/oztunaim/WGS/10_ANNOTATION/BAKTA"
OUT_DIR="/scratch/project_2014298/oztunaim/WGS/13_DIAMOND_ISOLATES/bakta_funcgenes"
mkdir -p "$OUT_DIR"

ISOLATES=(IR4_N1 IR5_05 IR5_08 IR7_03 IR8_08 IR8_13 IR9_07)

# ── GENE SEARCH TERMS ────────────────────────────────────────────────────────
# Format: GENE_NAME|"search term in Bakta"|category
# Search terms match Bakta's gene product descriptions (column 8)
# Using broad enough terms to catch variants but specific enough to avoid false positives

declare -A GENE_SEARCH
declare -A GENE_CATEGORY

# NITROGEN GENES
GENE_SEARCH[AmoA]="ammonia monooxygenase"
GENE_SEARCH[NxrA]="nitrite oxidoreductase"
GENE_SEARCH[NarG]="nitrate reductase"
GENE_SEARCH[NapA]="periplasmic nitrate reductase"
GENE_SEARCH[NirS]="nitrite reductase.*cd1\|cd1.*nitrite reductase\|nitrite reductase.*cytochrome"
GENE_SEARCH[NirK]="copper.*nitrite reductase\|nitrite reductase.*copper"
GENE_SEARCH[NrfA]="nitrite reductase.*formate\|formate.*nitrite reductase\|cytochrome c nitrite"
GENE_SEARCH[NosZ]="nitrous.oxide reductase"
GENE_SEARCH[HzsA]="hydrazine synthase"
GENE_SEARCH[NifH]="nitrogenase iron protein\|dinitrogenase reductase"
GENE_SEARCH[NorB]="nitric oxide reductase"
GENE_SEARCH[Nod]="nodulation protein\|nodulation factor"

GENE_CATEGORY[AmoA]="Nitrogen"
GENE_CATEGORY[NxrA]="Nitrogen"
GENE_CATEGORY[NarG]="Nitrogen"
GENE_CATEGORY[NapA]="Nitrogen"
GENE_CATEGORY[NirS]="Nitrogen"
GENE_CATEGORY[NirK]="Nitrogen"
GENE_CATEGORY[NrfA]="Nitrogen"
GENE_CATEGORY[NosZ]="Nitrogen"
GENE_CATEGORY[HzsA]="Nitrogen"
GENE_CATEGORY[NifH]="Nitrogen"
GENE_CATEGORY[NorB]="Nitrogen"
GENE_CATEGORY[Nod]="Nitrogen"

# SULFUR GENES
GENE_SEARCH[DsrA]="dissimilatory sulfite reductase"
GENE_SEARCH[FCC]="flavocytochrome c\|flavocytochrome c sulfide"
GENE_SEARCH[Sqr]="sulfide.quinone\|sulfide quinone oxidoreductase"
GENE_SEARCH[Sor]="sulfur oxygenase\|sulfur dioxygenase"
GENE_SEARCH[AsrA]="anaerobic sulfite reductase"
GENE_SEARCH[SoxB]="sulfur oxidation protein SoxB\|thiosulfate-oxidizing"

GENE_CATEGORY[DsrA]="Sulfur"
GENE_CATEGORY[FCC]="Sulfur"
GENE_CATEGORY[Sqr]="Sulfur"
GENE_CATEGORY[Sor]="Sulfur"
GENE_CATEGORY[AsrA]="Sulfur"
GENE_CATEGORY[SoxB]="Sulfur"

# TRACE GAS GENES
GENE_SEARCH[CoxL]="carbon monoxide dehydrogenase"
GENE_SEARCH[FeFe]="Fe. hydrogenase\|\[FeFe\]"
GENE_SEARCH[NiFe]="Ni,Fe. hydrogenase\|\[NiFe\]\|nickel.*iron.*hydrogenase"
GENE_SEARCH[PmoA]="particulate methane monooxygenase\|methane monooxygenase.*particulate"
GENE_SEARCH[MmoA]="soluble methane monooxygenase\|methane monooxygenase.*soluble"
GENE_SEARCH[McrA]="methyl-coenzyme M reductase\|methyl coenzyme M reductase"
GENE_SEARCH[IsoA]="isoprene monooxygenase\|isoprene-degrading"

GENE_CATEGORY[CoxL]="Trace_Gas"
GENE_CATEGORY[FeFe]="Trace_Gas"
GENE_CATEGORY[NiFe]="Trace_Gas"
GENE_CATEGORY[PmoA]="Trace_Gas"
GENE_CATEGORY[MmoA]="Trace_Gas"
GENE_CATEGORY[McrA]="Trace_Gas"
GENE_CATEGORY[IsoA]="Trace_Gas"

# Gene order for output
NITROGEN_GENES=(AmoA NxrA NarG NapA NirS NirK NrfA NosZ HzsA NifH NorB Nod)
SULFUR_GENES=(DsrA FCC Sqr Sor AsrA SoxB)
TRACEG_GENES=(CoxL FeFe NiFe PmoA MmoA McrA IsoA)
ALL_GENES=("${NITROGEN_GENES[@]}" "${SULFUR_GENES[@]}" "${TRACEG_GENES[@]}")

# ── SEARCH ───────────────────────────────────────────────────────────────────
echo "Searching Bakta annotations for functional genes..."
echo ""

# Output matrix file
MATRIX="$OUT_DIR/functional_genes_presence_absence.tsv"

# Header
printf "Isolate\tLayer"
for gene in "${ALL_GENES[@]}"; do
    printf "\t%s" "$gene"
done
printf "\n"

# Layer lookup
declare -A LAYER
LAYER[IR4_N1]="Bottom"
LAYER[IR5_05]="Transitional"
LAYER[IR5_08]="Transitional"
LAYER[IR7_03]="Transitional"
LAYER[IR8_08]="Top"
LAYER[IR8_13]="Top"
LAYER[IR9_07]="Top"

for ISOLATE in "${ISOLATES[@]}"; do
    TSV="${BAKTA_DIR}/${ISOLATE}/${ISOLATE}.tsv"

    if [[ ! -f "$TSV" ]]; then
        echo "WARNING: $TSV not found — skipping"
        continue
    fi

    printf "%s\t%s" "$ISOLATE" "${LAYER[$ISOLATE]}"

    for gene in "${ALL_GENES[@]}"; do
        search="${GENE_SEARCH[$gene]}"
        # Count matching lines (presence = 1 if any hit, 0 if none)
        hits=$(grep -i -E "$search" "$TSV" | wc -l)
        if [ "$hits" -gt 0 ]; then
            printf "\t1"
        else
            printf "\t0"
        fi
    done
    printf "\n"

done > "$MATRIX"

echo "Written: $MATRIX"
echo ""

# ── PRINT SUMMARY ────────────────────────────────────────────────────────────
echo "=== Presence/Absence Summary ==="
echo ""
cat "$MATRIX"
echo ""

# Also save detailed hit counts (not just 0/1) for reference
echo "=== Detailed gene counts per isolate ==="
COUNTS="$OUT_DIR/functional_genes_counts.tsv"

printf "Isolate\tLayer"
for gene in "${ALL_GENES[@]}"; do
    printf "\t%s" "$gene"
done
printf "\n"

for ISOLATE in "${ISOLATES[@]}"; do
    TSV="${BAKTA_DIR}/${ISOLATE}/${ISOLATE}.tsv"
    if [[ ! -f "$TSV" ]]; then continue; fi

    printf "%s\t%s" "$ISOLATE" "${LAYER[$ISOLATE]}"

    for gene in "${ALL_GENES[@]}"; do
        search="${GENE_SEARCH[$gene]}"
        hits=$(grep -i -E "$search" "$TSV" | wc -l)
        printf "\t%s" "$hits"
    done
    printf "\n"

done > "$COUNTS"

echo "Written: $COUNTS"
echo ""
echo "Done! Use functional_genes_presence_absence.tsv for the heatmap in R."
