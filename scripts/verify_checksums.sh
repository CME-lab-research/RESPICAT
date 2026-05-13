#!/usr/bin/env bash

# ============================================================
# 1. Configure strict shell behavior
# ============================================================

# ---- 1.1 Stop on errors and undefined variables ----
# Exit immediately if a command fails.
# Treat unset variables as errors.
# Make pipeline failures visible instead of silently continuing.
set -euo pipefail


# ============================================================
# 2. Define default input files
# ============================================================

# ---- 2.1 Define default RESPICAT release version ----
# This version string is used to construct the default archive
# and checksum filenames.
RESPICAT_VERSION="v1.0"

# ---- 2.2 Define default genome archive filename ----
# Compressed archive containing all public RESPICAT MAG FASTA files.
DEFAULT_ARCHIVE_FILE="RESPICAT_MAGs_${RESPICAT_VERSION}.tar.gz"

# ---- 2.3 Define default checksum filename ----
# The SHA-256 checksums for the genome archive.
DEFAULT_CHECKSUM_FILE="RESPICAT_MAGs_${RESPICAT_VERSION}.sha256"

# ---- 2.4 Allow user-provided file paths ----
# The default RESPICAT v1.0 filenames.
ARCHIVE_FILE="${1:-${DEFAULT_ARCHIVE_FILE}}"
CHECKSUM_FILE="${2:-${DEFAULT_CHECKSUM_FILE}}"


# ============================================================
# 3. Print usage information
# ============================================================

# ---- 3.1 Define help message ----
# This function explains how to run the checksum verification script.
print_usage() {
    cat <<USAGE
Usage:
  bash verify_checksums.sh [ARCHIVE_FILE] [CHECKSUM_FILE]

Examples:
  bash verify_checksums.sh
  bash verify_checksums.sh RESPICAT_MAGs_v1.0.tar.gz RESPICAT_MAGs_v1.0.sha256
  bash verify_checksums.sh ./downloads/RESPICAT_MAGs_v1.0.tar.gz ./checksums/RESPICAT_MAGs_v1.0.sha256

Default files:
  Archive:  ${DEFAULT_ARCHIVE_FILE}
  Checksum: ${DEFAULT_CHECKSUM_FILE}
USAGE
}

# ---- 3.2 Show help if requested ----
if [[ "${ARCHIVE_FILE}" == "-h" || "${ARCHIVE_FILE}" == "--help" ]]; then
    print_usage
    exit 0
fi


# ============================================================
# 4. Validate required files
# ============================================================

# ---- 4.1 Check that the genome archive exists ----
if [[ ! -f "${ARCHIVE_FILE}" ]]; then
    echo "ERROR: Genome archive not found: ${ARCHIVE_FILE}" >&2
    echo "Run download_RESPICAT_MAGs.sh first, or provide the correct archive path." >&2
    exit 1
fi

# ---- 4.2 Check that the checksum file exists ----
if [[ ! -f "${CHECKSUM_FILE}" ]]; then
    echo "ERROR: Checksum file not found: ${CHECKSUM_FILE}" >&2
    echo "Download the RESPICAT checksum file or provide the correct checksum path." >&2
    exit 1
fi


# ============================================================
# 5. Validate checksum tool availability
# ============================================================

# ---- 5.1 Prefer sha256sum when available ----
if command -v sha256sum >/dev/null 2>&1; then
    CHECKSUM_TOOL="sha256sum"

# ---- 5.2 Fall back to shasum on macOS ----
# macOS usually provides shasum instead of sha256sum.
elif command -v shasum >/dev/null 2>&1; then
    CHECKSUM_TOOL="shasum"

# ---- 5.3 Stop if no supported checksum tool exists ----
# Users need one of these tools to verify the archive.
else
    echo "ERROR: No supported SHA-256 checksum tool found." >&2
    echo "Please install sha256sum or use shasum if available." >&2
    exit 1
fi


# ============================================================
# 6. Prepare checksum file for local verification
# ============================================================

# ---- 6.1 Create temporary working directory ----
# A temporary directory avoids modifying the original checksum file.
TMP_DIR="$(mktemp -d)"

# ---- 6.2 Clean temporary files on exit ----
# This removes temporary files whether the script succeeds or fails.
cleanup() {
    rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

# ---- 6.3 Extract archive basename ----
# Checksum files usually contain the filename without a path.
# If the user provides a path to the archive, we still verify using its basename.
ARCHIVE_BASENAME="$(basename "${ARCHIVE_FILE}")"

# ---- 6.4 Create a local checksum file matching the provided archive path ----
# The checksum file may reference only the archive basename.
# We rewrite only the filename field so checksum verification works
# even when the archive is stored in another directory.
LOCAL_CHECKSUM_FILE="${TMP_DIR}/RESPICAT_local.sha256"

awk -v archive_path="${ARCHIVE_FILE}" -v archive_name="${ARCHIVE_BASENAME}" '
    $0 ~ archive_name {
        print $1 "  " archive_path
        found = 1
    }
    END {
        if (found != 1) {
            exit 2
        }
    }
' "${CHECKSUM_FILE}" > "${LOCAL_CHECKSUM_FILE}" || {
    echo "ERROR: Could not find checksum entry for ${ARCHIVE_BASENAME} in ${CHECKSUM_FILE}" >&2
    exit 1
}


# ============================================================
# 7. Verify SHA-256 checksum
# ============================================================

# ---- 7.1 Print verification target ----
echo "Verifying RESPICAT genome archive checksum..."
echo "Archive file:  ${ARCHIVE_FILE}"
echo "Checksum file: ${CHECKSUM_FILE}"
echo "Checksum tool: ${CHECKSUM_TOOL}"

# ---- 7.2 Run checksum verification on Linux ----
# sha256sum can verify checksum files directly with -c.
if [[ "${CHECKSUM_TOOL}" == "sha256sum" ]]; then
    sha256sum -c "${LOCAL_CHECKSUM_FILE}"

# ---- 7.3 Run checksum verification on macOS ----
else
    shasum -a 256 -c "${LOCAL_CHECKSUM_FILE}"
fi


# ============================================================
# 8. Report successful verification
# ============================================================

# ---- 8.1 Print success message ----
echo "Checksum verification completed successfully."
echo "The RESPICAT genome archive appears intact: ${ARCHIVE_FILE}"
