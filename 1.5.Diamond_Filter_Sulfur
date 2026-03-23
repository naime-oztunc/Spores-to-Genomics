#!/bin/bash -l
#SBATCH --job-name=filter_sulfur_thr
#SBATCH --account=project_2014298
#SBATCH --output=00_LOGS/filter_sulfur_thr_out.txt
#SBATCH --error=00_LOGS/filter_sulfur_thr_err.txt
#SBATCH --time=02:00:00
#SBATCH --partition=small
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G

RAW_DIR="05_DIAMOND/Raw"
FILTER_DIR="05_DIAMOND/Filtered_Sulfur"
mkdir -p "$FILTER_DIR"

# Genes and thresholds (parallel arrays)
genes=(DsrA FCC Sqr Sor AsrA SoxB)
thresholds=(50 50 50 50 50 50)

for combined in ${RAW_DIR}/*_Funcgenes_Combined.txt; do
    base=$(basename "$combined" _Funcgenes_Combined.txt)
    echo "Processing $base"
    for i in "${!genes[@]}"; do
        gene=${genes[$i]}
        thr=${thresholds[$i]}
        outf="${FILTER_DIR}/${base}_${gene}_filtered.txt"
        # grep case-insensitive for gene name followed by dash OR gene name word boundary
        grep -i -E "${gene}(-|\\b)" "$combined" \
          | awk -F'\t' -v t="$thr" '{ if ($3+0 >= t) print $0 }' > "$outf"
    done
done

echo "Sulfur filtering done; results in $FILTER_DIR"

