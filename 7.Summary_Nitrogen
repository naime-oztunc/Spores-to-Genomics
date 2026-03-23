#!/bin/bash -l
#SBATCH --job-name=sum_nitrogen
#SBATCH --account=project_2014298
#SBATCH --output=00_LOGS/sum_nitrogen.out
#SBATCH --error=00_LOGS/sum_nitrogen.err
#SBATCH --time=00:20:00
#SBATCH --partition=small
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G

FILTER_DIR="05_DIAMOND/Filtered_Nitrogen"
SUMMARY_DIR="05_DIAMOND/Summary"
mkdir -p "$SUMMARY_DIR"

genes=(AmoA NxrA NarG NapA NirS NirK NrfA NosZ HzsA NifH NorB Nod)
samples=( $(cat sample_names.txt) )

# header
echo -e "gene\t$(printf "%s\t" "${samples[@]}" | sed 's/\t$//')" > "${SUMMARY_DIR}/nitrogen_gene_counts_matrix.tsv"

for g in "${genes[@]}"; do
    line="$g"
    for s in "${samples[@]}"; do
        if [[ -f "${FILTER_DIR}/${s}_${g}_filtered.txt" ]]; then
            cnt=$(wc -l < "${FILTER_DIR}/${s}_${g}_filtered.txt")
        else
            cnt=0
        fi
        line="${line}\t${cnt}"
    done
    echo -e "$line" >> "${SUMMARY_DIR}/nitrogen_gene_counts_matrix.tsv"
done

echo "Nitrogen summary written to ${SUMMARY_DIR}/nitrogen_gene_counts_matrix.tsv"
