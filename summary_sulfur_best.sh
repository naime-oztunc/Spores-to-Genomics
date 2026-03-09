#!/bin/bash -l
#SBATCH --job-name=sum_sulfur
#SBATCH --account=project_2014298
#SBATCH --output=00_LOGS/sum_sulfur.out
#SBATCH --error=00_LOGS/sum_sulfur.err
#SBATCH --time=00:20:00
#SBATCH --partition=small
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G

FILTER_DIR="05_DIAMOND/Filtered_Sulfur"
SUMMARY_DIR="05_DIAMOND/Summary"
mkdir -p "$SUMMARY_DIR"

genes=(DsrA FCC Sqr Sor AsrA SoxB)
samples=( $(cat sample_names.txt) )

# header
echo -e "gene\t$(printf "%s\t" "${samples[@]}" | sed 's/\t$//')" > "${SUMMARY_DIR}/sulfur_gene_counts_matrix.tsv"

for g in "${genes[@]}"; do
    line="$g"
    for s in "${samples[@]}"; do
        f="${FILTER_DIR}/${s}_Funcgenes_Combined_${g}_filtered.txt"
        # older naming: our scripts produced ${base}_${gene}_filtered.txt, where base is sample
        # try both naming variants for safety:
        if [[ -f "${FILTER_DIR}/${s}_${g}_filtered.txt" ]]; then
            cnt=$(wc -l < "${FILTER_DIR}/${s}_${g}_filtered.txt")
        elif [[ -f "${FILTER_DIR}/${s}_Funcgenes_Combined_${g}_filtered.txt" ]]; then
            cnt=$(wc -l < "${FILTER_DIR}/${s}_Funcgenes_Combined_${g}_filtered.txt")
        else
            cnt=0
        fi
        line="${line}\t${cnt}"
    done
    echo -e "$line" >> "${SUMMARY_DIR}/sulfur_gene_counts_matrix.tsv"
done

echo "Sulfur summary written to ${SUMMARY_DIR}/sulfur_gene_counts_matrix.tsv"


