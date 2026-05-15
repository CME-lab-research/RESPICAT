<p align="center">
  <img src="assets/RESPICAT_logo.png" alt="RESPICAT logo" width="500"/>
</p>

# About

**RESPICAT** is a genome catalogue of human respiratory tract prokaryotes. The catalogue provides dereplicated metagenome-assembled genomes (MAGs), genome-level metadata, taxonomic annotations, genome quality summaries, checksum files, and helper scripts for accessing the RESPICAT v1.0 release.

## RESPICAT v1.0 genome archive

The RESPICAT MAG FASTA files are distributed as a compressed archive:

```text
RESPICAT_MAGs_v1.0.tar.gz
```

The genome archive will be deposited in an external archival repository. The final download link will be added here after deposition:

> **Genome archive:** [RESPICAT_MAGs_v1.0.tar.gz](https://doi.org/10.5281/zenodo.20162797)

After extraction, the archive contains public MAG FASTA files named with stable RESPICAT identifiers:

```text
RESPICAT_MAG_000001.fna
RESPICAT_MAG_000002.fna
RESPICAT_MAG_000003.fna
...
```

Contig identifiers inside each FASTA file follow the same public naming scheme:

```text
>RESPICAT_MAG_000001_contig_000001
>RESPICAT_MAG_000001_contig_000002
```

## Repository structure

The GitHub repository contains metadata, documentation, checksums, and reproducible helper scripts for accessing the RESPICAT v1.0 MAG catalogue.

```text
RESPICAT GitHub repo
├── README.md
├── metadata/
│   ├── RESPICAT_MAG_metadata_v1.0.tsv
│   ├── RESPICAT_MAG_taxonomy_v1.0.tsv
│   ├── RESPICAT_MAG_quality_summary_v1.0.tsv
│   └── RESPICAT_MAG_id_mapping_v1.0.tsv
├── scripts/
│   ├── download_RESPICAT_MAGs.sh
│   ├── verify_checksums.sh
│   └── prepare_RESPICAT_MAG_release.R
├── checksums/
│   └── RESPICAT_MAGs_v1.0.sha256
└── docs/
    └── RESPICAT_MAG_catalog_description_v1.0.md
```

## Public release files

### Metadata files

| File | Description |
|---|---|
| [`metadata/RESPICAT_MAG_metadata_v1.0.tsv`](metadata/RESPICAT_MAG_metadata_v1.0.tsv) | Main MAG-level metadata table containing public MAG IDs, FASTA filenames, basic provenance, taxonomy, and genome quality metrics. |
| [`metadata/RESPICAT_MAG_taxonomy_v1.0.tsv`](metadata/RESPICAT_MAG_taxonomy_v1.0.tsv) | Taxonomy-only table with public MAG IDs and taxonomic ranks. |
| [`metadata/RESPICAT_MAG_quality_summary_v1.0.tsv`](metadata/RESPICAT_MAG_quality_summary_v1.0.tsv) | Genome quality summary table containing completeness, contamination, strain heterogeneity, genome size, N50, and dereplication score. |
| [`metadata/RESPICAT_MAG_id_mapping_v1.0.tsv`](metadata/RESPICAT_MAG_id_mapping_v1.0.tsv) | Mapping table linking public RESPICAT MAG IDs to original internal MAG identifiers, original FASTA filenames, ATLAS batch IDs, and original MAG labels. |

### Checksum file

| File | Description |
|---|---|
| [`checksums/RESPICAT_MAGs_v1.0.sha256`](checksums/RESPICAT_MAGs_v1.0.sha256) | SHA-256 checksum file for validating the downloaded RESPICAT MAG genome archive. |

### Scripts

| File | Description |
|---|---|
| [`scripts/download_RESPICAT_MAGs.sh`](scripts/download_RESPICAT_MAGs.sh) | Helper script for downloading the RESPICAT MAG archive after the external archive link is available. |
| [`scripts/verify_checksums.sh`](scripts/verify_checksums.sh) | Helper script for validating the downloaded genome archive using the SHA-256 checksum file. |
| [`scripts/prepare_RESPICAT_MAG_release.R`](scripts/prepare_RESPICAT_MAG_release.R) | R script used to prepare public MAG identifiers, rename FASTA files, rename contig headers, and generate public metadata files. |

## Downloading the helper scripts

The RESPICAT helper scripts are available in the [`scripts/`](scripts/) directory.

```text
scripts/
├── download_RESPICAT_MAGs.sh
├── verify_checksums.sh
└── prepare_RESPICAT_MAG_release.R
```

#### Option 1: Download from the browser
To download an individual script:

1. Open the [`scripts/`](scripts/) directory.
2. Click the script you want to download, for example `download_RESPICAT_MAGs.sh`.
3. Click Raw.
4. Right-click on the page and choose `Save as`.
5. Save the file with the same filename, for example: `download_RESPICAT_MAGs.sh`

#### Option 2: Download scripts from the command line
Users familiar with the terminal can download the scripts directly.

```bash
# Download the genome archive helper script
curl -L -o download_RESPICAT_MAGs.sh \
  https://raw.githubusercontent.com/CME-lab-research/RESPICAT/main/scripts/download_RESPICAT_MAGs.sh

# Download the checksum verification script
curl -L -o verify_checksums.sh \
  https://raw.githubusercontent.com/CME-lab-research/RESPICAT/main/scripts/verify_checksums.sh
```

After downloading, make the scripts executable:
```bash
chmod +x download_RESPICAT_MAGs.sh
chmod +x verify_checksums.sh
```

Then run:
```bash
./download_RESPICAT_MAGs.sh
./verify_checksums.sh
```

### Documentation

| File | Description |
|---|---|
| [`docs/RESPICAT_MAG_catalog_description_v1.0.md`](docs/RESPICAT_MAG_catalog_description_v1.0.md) | Detailed description of the RESPICAT MAG catalogue, public identifier scheme, metadata fields, and release contents. |

## Public identifier scheme

Each dereplicated MAG receives one stable public MAG identifier:

```text
RESPICAT_MAG_000001
```

Each contig within a MAG receives a contig-level identifier derived from the corresponding public MAG ID:

```text
RESPICAT_MAG_000001_contig_000001
```

The file [`metadata/RESPICAT_MAG_id_mapping_v1.0.tsv`](metadata/RESPICAT_MAG_id_mapping_v1.0.tsv) links public RESPICAT MAG IDs to the original internal genome identifiers and original FASTA filenames.

## Verifying downloaded genome files

After downloading `RESPICAT_MAGs_v1.0.tar.gz`, verify the archive with the provided checksum file:

```bash
sha256sum -c checksums/RESPICAT_MAGs_v1.0.sha256
```

Alternatively, use the helper script:

```bash
# Run as
bash scripts/verify_checksums.sh

# Or run with explicit paths
bash verify_checksums.sh RESPICAT_MAGs_v1.0.tar.gz checksums/RESPICAT_MAGs_v1.0.sha256
```

It supports both `sha256sum` on Linux and `shasum -a 256` on macOS.

## Data availability

Raw sequencing reads are available through ENA under accession [PRJEB96845](https://www.ebi.ac.uk/ena/browser/view/PRJEB96845).

Reused public metagenomic datasets were retrieved from ENA/SRA. The list of reused BioProjects is provided in the manuscript supplementary tables.

The RESPICAT v1.0 MAG genome archive will be made available through an external archival repository:

> **Archive link:** [Zenodo DOI](https://doi.org/10.5281/zenodo.20162797)

## Citation

Citation information will be added after publication or public release of the corresponding manuscript/preprint.
