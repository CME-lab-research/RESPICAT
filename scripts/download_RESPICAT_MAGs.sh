#!/usr/bin/env bash

# ============================================================
# 1. Configure script behavior
# ============================================================

# ---- 1.1 Stop on common shell errors ----
# Exit immediately if a command fails.
# Treat unset variables as errors.
# Make pipelines fail if any command in the pipeline fails.
set -euo pipefail


# ============================================================
# 2. Define RESPICAT download settings
# ============================================================

# ---- 2.1 Define RESPICAT release version ----
# Update this value when preparing a new RESPICAT release.
RESPICAT_VERSION="v1.0"

# ---- 2.2 Define genome archive filename ----
# This is the expected name of the compressed MAG archive.
ARCHIVE_NAME="RESPICAT_MAGs_${RESPICAT_VERSION}.tar.gz"

# ---- 2.3 Define Zenodo download URL ----

# Recommended Zenodo file URL format:
# https://zenodo.org/records/<ZENODO_RECORD_ID>/files/RESPICAT_MAGs_v1.0.tar.gz?download=1

# Replace the placeholder URL below after uploading the archive to Zenodo.
ZENODO_URL="https://zenodo.org/records/<ZENODO_RECORD_ID>/files/${ARCHIVE_NAME}?download=1"

# ---- 2.4 Define checksum URL ----
# This assumes the checksum file is stored in the GitHub repository.
# Replace <ORG_OR_USER> and <REPO_NAME> after the repository is public.
CHECKSUM_URL="https://raw.githubusercontent.com/<ORG_OR_USER>/<REPO_NAME>/main/checksums/RESPICAT_MAGs_${RESPICAT_VERSION}.sha256"

# ---- 2.5 Define local output directory ----
# Users can pass a custom output directory as the first command-line argument.
# If no argument is given, files are downloaded into ./RESPICAT_MAGs_v1.0.
OUTPUT_DIR="${1:-RESPICAT_MAGs_${RESPICAT_VERSION}}"

# ---- 2.6 Define extracted genome directory ----
# The extracted FASTA files will be placed inside this directory.
EXTRACT_DIR="${OUTPUT_DIR}/genomes"


# ============================================================
# 3. Prepare output directories
# ============================================================

# ---- 3.1 Create output directory ----
# This stores the compressed archive and checksum file.
mkdir -p "${OUTPUT_DIR}"

# ---- 3.2 Create genome extraction directory ----
# This stores the extracted public MAG FASTA files.
mkdir -p "${EXTRACT_DIR}"

# ---- 3.3 Report output location ----
# This helps users confirm where files are being written.
echo "RESPICAT version: ${RESPICAT_VERSION}"
echo "Output directory: ${OUTPUT_DIR}"
echo "Genome extraction directory: ${EXTRACT_DIR}"


# ============================================================
# 4. Check required command-line tools
# ============================================================

# ---- 4.1 Check for curl or wget ----
# Either curl or wget can be used to download files.
if command -v curl >/dev/null 2>&1; then
    DOWNLOAD_CMD="curl -L --fail --output"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOAD_CMD="wget --output-document"
else
    echo "ERROR: Neither curl nor wget is available. Please install one of them and rerun this script."
    exit 1
fi

# ---- 4.2 Check for tar ----
# tar is needed to extract the compressed genome archive.
if ! command -v tar >/dev/null 2>&1; then
    echo "ERROR: tar is not available. Please install tar and rerun this script."
    exit 1
fi

# ---- 4.3 Check for sha256sum or shasum ----
# Either tool can be used to verify SHA-256 checksums.
if command -v sha256sum >/dev/null 2>&1; then
    SHA256_CHECK_CMD="sha256sum -c"
elif command -v shasum >/dev/null 2>&1; then
    SHA256_CHECK_CMD="shasum -a 256 -c"
else
    SHA256_CHECK_CMD=""
    echo "WARNING: Neither sha256sum nor shasum is available. Checksum verification will be skipped."
fi


# ============================================================
# 5. Download RESPICAT MAG archive
# ============================================================

# ---- 5.1 Define local archive path ----
# This is where the compressed MAG archive will be saved.
ARCHIVE_PATH="${OUTPUT_DIR}/${ARCHIVE_NAME}"

# ---- 5.2 Download archive if it is not already present ----
# This avoids re-downloading the large archive if the file already exists.
if [[ -f "${ARCHIVE_PATH}" ]]; then
    echo "Archive already exists: ${ARCHIVE_PATH}"
else
    echo "Downloading RESPICAT MAG archive from Zenodo..."
    ${DOWNLOAD_CMD} "${ARCHIVE_PATH}" "${ZENODO_URL}"
    echo "Downloaded archive: ${ARCHIVE_PATH}"
fi


# ============================================================
# 6. Download and verify checksum
# ============================================================

# ---- 6.1 Define local checksum path ----
# This file contains the expected SHA-256 checksum for the archive.
CHECKSUM_PATH="${OUTPUT_DIR}/RESPICAT_MAGs_${RESPICAT_VERSION}.sha256"

# ---- 6.2 Download checksum file if possible ----
# The checksum file is expected to be available from the GitHub repository.
if [[ -f "${CHECKSUM_PATH}" ]]; then
    echo "Checksum file already exists: ${CHECKSUM_PATH}"
else
    echo "Downloading checksum file..."
    if ${DOWNLOAD_CMD} "${CHECKSUM_PATH}" "${CHECKSUM_URL}"; then
        echo "Downloaded checksum file: ${CHECKSUM_PATH}"
    else
        echo "WARNING: Could not download checksum file. Continuing without checksum verification."
        rm -f "${CHECKSUM_PATH}"
    fi
fi

# ---- 6.3 Verify archive checksum if tools and checksum file are available ----
# The checksum file should contain the archive filename expected by sha256sum -c.
# The check is run from the output directory so relative filenames resolve correctly.
if [[ -n "${SHA256_CHECK_CMD}" && -f "${CHECKSUM_PATH}" ]]; then
    echo "Verifying SHA-256 checksum..."
    (
        cd "${OUTPUT_DIR}"
        ${SHA256_CHECK_CMD} "$(basename "${CHECKSUM_PATH}")"
    )
    echo "Checksum verification completed."
else
    echo "Checksum verification skipped."
fi


# ============================================================
# 7. Extract RESPICAT MAG archive
# ============================================================

# ---- 7.1 Extract archive into genome directory ----
# The archive should contain public FASTA files such as:
# RESPICAT_MAG_000001.fna
# RESPICAT_MAG_000002.fna
# RESPICAT_MAG_000003.fna

echo "Extracting archive into: ${EXTRACT_DIR}"
tar -xzf "${ARCHIVE_PATH}" -C "${EXTRACT_DIR}"

# ---- 7.2 Count extracted FASTA files ----
# This gives users a quick sanity check after extraction.
N_FASTA=$(find "${EXTRACT_DIR}" -type f \( -name "*.fna" -o -name "*.fasta" \) | wc -l | tr -d ' ')

echo "Number of extracted FASTA files: ${N_FASTA}"


# ============================================================
# 8. Print completion message
# ============================================================

# ---- 8.1 Report final file locations ----
# This tells users where the downloaded archive and extracted genomes are stored.
echo "RESPICAT MAG download completed."
echo "Archive: ${ARCHIVE_PATH}"
echo "Extracted genomes: ${EXTRACT_DIR}"
