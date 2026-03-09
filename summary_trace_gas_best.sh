#!/bin/bash -l
#SBATCH --job-name=sum_trace_gas
#SBATCH --account=project_2014298
#SBATCH --output=00_LOGS/sum_trace_gas.out
#SBATCH --error=00_LOGS/sum_trace_gas.err
#SBATCH --time=00:20:00
#SBATCH --partition=small
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G

FILTER_DIR="05_DIAMOND/Filtered_Trace_Gas"
SUMMARY_DIR="05_DIAMOND/Summary"
mkdir -p "$SUMMARY_DIR"

genes=( "CoxL" "FeFe" "[Fe]" "NiFe" "PmoA" "MmoA" "McrA" "IsoA" )
samples=( $(cat sample_names.txt) )

# header
echo -e "gene\t$(printf "%s\t" "${samples[@]}" | sed 's/\t$//')" > "${SUMMARY_DIR}/trace_gas_gene_counts_matrix.tsv"

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
    echo -e "$line" >> "${SUMMARY_DIR}/trace_gas_gene_counts_matrix.tsv"
done

echo "Trace gas summary written to ${SUMMARY_DIR}/trace_gas_gene_counts_matrix.tsv"


