# ============================================================
# 1. Create SHA-256 checksums for RESPICAT release files
# ============================================================
# Run code with this cmd: powershell -ExecutionPolicy Bypass -File .\create_checksum_RESPICAT_release_updated.ps1

# ---- 1.1 Define release directory ----
# This should be the local folder that contains the RESPICAT release files.
# Update this path before running the script on a different computer.
$ReleaseDir = "C:\Users\o_shinde\Desktop\MiPORT_Functions_DA\01_C_RESPICAT"

# ---- 1.2 Define checksum output directory ----
# All checksum files will be written into this folder.
# This matches the GitHub repository structure:
# checksums/RESPICAT_MAGs_v1.0.sha256
$ChecksumDir = Join-Path $ReleaseDir "checksums"

# ---- 1.3 Move to the release directory ----
# Stop immediately if the release directory does not exist.
if (-not (Test-Path $ReleaseDir)) {
    throw "Release directory not found: $ReleaseDir"
}

Set-Location $ReleaseDir
Write-Host "Working in release directory: $ReleaseDir"

# ---- 1.4 Create checksum directory if needed ----
# This keeps checksum files organized in one location.
if (-not (Test-Path $ChecksumDir)) {
    New-Item `
        -ItemType Directory `
        -Path $ChecksumDir | Out-Null

    Write-Host "Created checksum directory: $ChecksumDir"
} else {
    Write-Host "Using existing checksum directory: $ChecksumDir"
}


# ============================================================
# 2. Define helper function for sha256sum-compatible output
# ============================================================

# ---- 2.1 Create one checksum line ----
# Linux sha256sum-compatible format is:
# HASH two-spaces FILENAME
# Example:
# abc123...  RESPICAT_MAGs_v1.0.tar.gz
function New-Sha256Line {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # Calculate SHA-256 checksum for the file.
    $HashObject = Get-FileHash `
        -Path $FilePath `
        -Algorithm SHA256

    # Use only the base filename in the checksum file.
    # This makes verification easier after download.
    $BaseName = Split-Path `
        -Path $FilePath `
        -Leaf

    # Return a sha256sum-compatible checksum line.
    return "$($HashObject.Hash.ToLower())  $BaseName"
}


# ============================================================
# 3. Create checksum files for all RESPICAT MAG archive versions
# ============================================================

# ---- 3.1 Find all genome archive versions ----
# This captures all files such as:
# RESPICAT_MAGs_v1.0.tar.gz
# RESPICAT_MAGs_v1.1.tar.gz
# RESPICAT_MAGs_v2.0.tar.gz
$ArchiveFiles = Get-ChildItem `
    -Path $ReleaseDir `
    -Filter "RESPICAT_MAGs_v*.tar.gz" `
    -File

# ---- 3.2 Stop if no archive files are found ----
# The genome archive is the main file that users download from Zenodo.
if ($ArchiveFiles.Count -eq 0) {
    throw "No RESPICAT_MAGs_v*.tar.gz files found in: $ReleaseDir"
}

Write-Host "Genome archive versions found:" $ArchiveFiles.Count

# ---- 3.3 Write one checksum file per archive version ----
# For each archive, create a matching checksum file.
# Example:
# RESPICAT_MAGs_v1.0.tar.gz -> checksums/RESPICAT_MAGs_v1.0.sha256
foreach ($ArchiveFile in $ArchiveFiles) {

    # Remove the .tar.gz suffix to create the checksum filename.
    $ArchiveStem = $ArchiveFile.Name -replace "\.tar\.gz$", ""

    # Define the output checksum file path.
    $ChecksumFile = Join-Path `
        $ChecksumDir `
        "$ArchiveStem.sha256"

    # Create the checksum line in sha256sum-compatible format.
    $ChecksumLine = New-Sha256Line `
        -FilePath $ArchiveFile.FullName

    # Write the checksum file using ASCII encoding.
    # ASCII keeps the file compatible with Linux/macOS checksum tools.
    $ChecksumLine | Out-File `
        -FilePath $ChecksumFile `
        -Encoding ascii

    Write-Host "Saved checksum:" $ChecksumFile
}


# ============================================================
# 4. Create a combined checksum file for public release files
# ============================================================

# ---- 4.1 Define public release file patterns ----
# These patterns cover genome archives, metadata, documentation,
# scripts, and README files used in the public RESPICAT release.
$ReleaseFilePatterns = @(
    "RESPICAT_MAGs_v*.tar.gz",
    "README.md",
    "metadata\RESPICAT_MAG_metadata_v*.tsv",
    "metadata\RESPICAT_MAG_taxonomy_v*.tsv",
    "metadata\RESPICAT_MAG_quality_summary_v*.tsv",
    "metadata\RESPICAT_MAG_id_mapping_v*.tsv",
    "docs\RESPICAT_MAG_catalog_description_v*.md",
    "scripts\download_RESPICAT_MAGs.sh",
    "scripts\verify_checksums.sh",
    "scripts\prepare_RESPICAT_MAG_release.R"
)

# ---- 4.2 Collect all public release files ----
# Resolve-Path returns only files that actually exist.
# Missing optional files are skipped with a warning.
$ReleaseFiles = @()

foreach ($Pattern in $ReleaseFilePatterns) {

    # Join the release directory with the file pattern.
    $FullPattern = Join-Path `
        $ReleaseDir `
        $Pattern

    # Find matching files.
    $MatchedFiles = Get-ChildItem `
        -Path $FullPattern `
        -File `
        -ErrorAction SilentlyContinue

    # Add matched files to the release file list.
    if ($MatchedFiles.Count -gt 0) {
        $ReleaseFiles += $MatchedFiles
    } else {
        Write-Host "Optional file pattern not found:" $Pattern
    }
}

# ---- 4.3 Remove duplicate file entries ----
# This protects against overlap between patterns.
$ReleaseFiles = $ReleaseFiles | Sort-Object FullName -Unique

# ---- 4.4 Stop if no public release files are found ----
# This prevents writing an empty combined checksum file.
if ($ReleaseFiles.Count -eq 0) {
    throw "No public release files found for combined checksum file."
}

Write-Host "Public release files included in combined checksum:" $ReleaseFiles.Count

# ---- 4.5 Create combined checksum lines ----
# Use paths relative to the release directory so the checksum file
# remains portable across computers.
$CombinedChecksumLines = foreach ($File in $ReleaseFiles) {

    # Calculate SHA-256 checksum.
    $HashObject = Get-FileHash `
        -Path $File.FullName `
        -Algorithm SHA256

    # Convert the full path into a relative path.
    $RelativePath = Resolve-Path `
        -Path $File.FullName `
        -Relative

    # Remove leading .\ or ./ from relative paths.
    $RelativePath = $RelativePath -replace "^\.\\", ""
    $RelativePath = $RelativePath -replace "^\./", ""

    # Convert Windows backslashes to forward slashes.
    # This makes the checksum file easier to read on GitHub.
    $RelativePath = $RelativePath -replace "\\", "/"

    # Return a sha256sum-compatible checksum line.
    "$($HashObject.Hash.ToLower())  $RelativePath"
}

# ---- 4.6 Save combined checksum file ----
# This file is useful for validating the full public release folder.
$CombinedChecksumFile = Join-Path `
    $ChecksumDir `
    "RESPICAT_public_release_all_files.sha256"

$CombinedChecksumLines | Out-File `
    -FilePath $CombinedChecksumFile `
    -Encoding ascii

Write-Host "Saved combined checksum file:" $CombinedChecksumFile


# ============================================================
# 5. Print checksum creation summary
# ============================================================

# ---- 5.1 List checksum files written ----
# This provides a final sanity check for the user.
$WrittenChecksumFiles = Get-ChildItem `
    -Path $ChecksumDir `
    -Filter "*.sha256" `
    -File | Sort-Object Name

Write-Host "Checksum files currently available:"
$WrittenChecksumFiles | Select-Object Name, Length, LastWriteTime

Write-Host "Finished creating RESPICAT checksum files."
