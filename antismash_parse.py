# coding: utf-8
"""
antiSMASH region parser with MIBiG similarity information
For isolates: IR4_N1, IR5_05, IR5_08, IR7_03, IR8_08, IR8_13, IR9_07
Usage: python antismash_parse.py all_isolates.gbk all_isolates.json antismash_regions.csv
"""
import sys
import json
from Bio import SeqIO
import pandas as pd

# ── Command line arguments ────────────────────────────────────────────────────
if len(sys.argv) < 4:
    print("Usage: python antismash_parse.py <genbank_file> <json_file> <output_csv>")
    print("Example: python antismash_parse.py all_isolates.gbk all_isolates.json antismash_regions.csv")
    sys.exit(1)

gbk_file    = sys.argv[1]
json_file   = sys.argv[2]
output_name = sys.argv[3]

ISOLATES = ["IR4_N1", "IR5_05", "IR5_08", "IR7_03", "IR8_08", "IR8_13", "IR9_07"]

def get_isolate_name(contig_id):
    """Extract isolate name from renamed contig e.g. IR4_N1_ptg000001l -> IR4_N1"""
    for isolate in ISOLATES:
        if contig_id.startswith(isolate + "_"):
            return isolate
    return "Unknown"

# ── Load JSON for MIBiG similarity scores ────────────────────────────────────
print("Loading JSON file...")
with open(json_file, 'r') as f:
    json_data = json.load(f)

similarity_map = {}
for record in json_data['records']:
    record_id = record['id']
    if 'modules' in record and 'antismash.modules.clusterblast' in record['modules']:
        cb_module = record['modules']['antismash.modules.clusterblast']
        if 'knowncluster' in cb_module and 'results' in cb_module['knowncluster']:
            for result in cb_module['knowncluster']['results']:
                region_num = result['region_number']
                if 'ranking' in result and result['ranking']:
                    top_hit       = result['ranking'][0]
                    cluster_info  = top_hit[0]
                    match_details = top_hit[1]
                    key = (record_id, region_num)
                    similarity_map[key] = {
                        'cluster_name': cluster_info.get('description', 'Unknown'),
                        'bgc_id':       cluster_info.get('accession', 'Unknown'),
                        'similarity':   match_details.get('similarity', 0)
                    }

print(f"Found MIBiG similarity data for {len(similarity_map)} regions")

# ── Parse GenBank for BGC regions ────────────────────────────────────────────
print("Parsing GenBank file...")
all_regions = []
contig_n = 1

for record in SeqIO.parse(gbk_file, "genbank"):
    regions = [
        f for f in record.features
        if f.type == "region" and f.qualifiers.get("tool") == ['antismash']
    ]
    for region in regions:
        r_num_int = int(region.qualifiers["region_number"][0])
        sim_key   = (record.id, r_num_int)
        sim_info  = similarity_map.get(sim_key, {
            'cluster_name': 'No match',
            'bgc_id': 'N/A',
            'similarity': 0
        })
        all_regions.append({
            "isolate":                    get_isolate_name(record.id),
            "region":                     f"Region {contig_n}.{r_num_int}",
            "region_product":             str(region.qualifiers["product"])[2:-1].replace("'", ""),
            "region_start":               int(region.location.start) + 1,
            "region_end":                 int(region.location.end),
            "region_contig":              record.id,
            "most_similar_known_cluster": sim_info['cluster_name'],
            "mibig_bgc_id":               sim_info['bgc_id'],
            "similarity_percentage":      sim_info['similarity']
        })
    contig_n += 1

# ── Write output ──────────────────────────────────────────────────────────────
regions_df = pd.DataFrame(all_regions)
regions_df.to_csv(output_name, index=False)
print(f"\nDone! {len(regions_df)} BGC regions written to {output_name}")

print("\nSummary per isolate:")
summary = regions_df.groupby("isolate")["region_product"].count().rename("BGC_count")
print(summary.to_string())
