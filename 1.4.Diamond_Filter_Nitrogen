#!/bin/bash -l
#SBATCH --job-name=filter_nitrogen_thr
#SBATCH --account=project_2014298
#SBATCH --output=00_LOGS/filter_nitrogen_thr_out.txt
#SBATCH --error=00_LOGS/filter_nitrogen_thr_err.txt
#SBATCH --time=02:00:00
#SBATCH --partition=small
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G

RAW_DIR="05_DIAMOND/Raw"
FILTER_DIR="05_DIAMOND/Filtered_Nitrogen"
mkdir -p "$FILTER_DIR"

genes=(AmoA NxrA NarG NapA NirS NirK NrfA NosZ HzsA NifH NorB Nod)
thresholds=(60 60 50 50 50 50 50 50 50 50 50 50)

for combined in ${RAW_DIR}/*_Funcgenes_Combined.txt; do
    base=$(basename "$combined" _Funcgenes_Combined.txt)
    echo "Processing $base"
    for i in "${!genes[@]}"; do
        gene=${genes[$i]}
        thr=${thresholds[$i]}
        outf="${FILTER_DIR}/${base}_${gene}_filtered.txt"
        grep -i -E "${gene}(-|\\b)" "$combined" \
          | awk -F'\t' -v t="$thr" '{ if ($3+0 >= t) print $0 }' > "$outf"
    done
done

echo "Nitrogen filtering done; results in $FILTER_DIR"
