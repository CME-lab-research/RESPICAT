# RESPICAT
RESPI-CAT is comprehensive genome catalog of human respiratory tract prokaryotes. 

```text
RESPICAT GitHub repo
├── README.md
├── metadata/
│   ├── RESPICAT_MAG_metadata.tsv
│   ├── RESPICAT_MAG_quality_summary.tsv
│   └── RESPICAT_MAG_taxonomy.tsv
├── scripts/
│   ├── download_RESPICAT_MAGs.sh
│   └── verify_checksums.sh
├── checksums/
│   └── RESPICAT_MAGs.sha256
└── docs/
    └── RESPICAT_MAG_catalog_description.md
```
---

| File                                    | Primary purpose               |
| --------------------------------------- | ----------------------------- |
| `RESPICAT_MAGs_v1.0.tar.gz`             | Actual genome FASTA files     |
| `RESPICAT_MAG_metadata_v1.0.tsv`        | Main user-facing lookup table |
| `RESPICAT_MAG_taxonomy_v1.0.tsv`        | Taxonomy-only file            |
| `RESPICAT_MAG_quality_summary_v1.0.tsv` | Genome quality file           |
| `RESPICAT_MAG_id_mapping_v1.0.tsv`      | Provenance/mapping file       |

---

## Data availability

Raw reads: ENA cite [PRJEB96845](https://www.ebi.ac.uk/ena/browser/view/PRJEB96845) .
Reused data: List of the BioProjects pulled from ENA/SRA is in Supplementary Table-1.


