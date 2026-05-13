# ============================================================
# 1. Create SHA-256 checksum for RESPICAT genome archive with Windows Powershell
# ============================================================

# ---- 1.1 Move to the folder containing the archive ----
# Change this path to the folder where your tar.gz file is stored.
cd "C:\Users\o_shinde\Desktop\MiPORT_Functions_DA\01_C_RESPICAT"

# ---- 1.2 Generate SHA-256 checksum ----
# Get-FileHash calculates the checksum of the genome archive.
Get-FileHash `
  -Path "RESPICAT_MAGs_v1.0.tar.gz" `
  -Algorithm SHA256

# ============================================================
# 2. Save checksum in sha256sum-compatible format
# ============================================================

# ---- 2.1 Calculate file hash ----
# Store the hash object so we can format the output manually.
$hash = Get-FileHash `
  -Path "RESPICAT_MAGs_v1.0.tar.gz" `
  -Algorithm SHA256

# ---- 2.2 Write checksum file ----
# This writes the checksum in the standard format:
# HASH two-spaces FILENAME
"$($hash.Hash.ToLower())  RESPICAT_MAGs_v1.0.tar.gz" | Out-File `
  -FilePath "RESPICAT_MAGs_v1.0.sha256" `
  -Encoding ascii

  