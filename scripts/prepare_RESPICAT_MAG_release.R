# Script to create the public files for RESPICAT
# Takes input the dereplicated genome files, taxonomy and the genome stats file to generate the RESPICAT resource public files.
# Input files:
#   Taxonomy: RESPICAT_MAGs_dRep_Taxonomy_and_Features.txt
# Output files:
#   RESPICAT_MAGs_v1.0.tar.gz
#   RESPICAT_MAG_metadata_v1.0.tsv
#   RESPICAT_MAG_taxonomy_v1.0.tsv
#   RESPICAT_MAG_quality_summary_v1.0.tsv
#   RESPICAT_MAG_id_mapping_v1.0.tsv
#   RESPICAT_MAGs_v1.0.sha256

# Create a new Public MAG id in this format
# MAG-level ID:       RESPICAT_MAG_000001
# Contig-level ID:    RESPICAT_MAG_000001_contig_000001

# ============================================================
# 1. Load environment and init variables
# ============================================================
# ---- 1.1 Load libraries ----
# Load tidyverse for table handling and string operations.
library(tidyverse)

# ---- 1.2 Define input files and folders ----
# Mapping file containing the internal MAG IDs, genome filenames,
# taxonomy, and quality statistics.
RESPICAT_global_map_file <- "RESPICAT_MAGs_dRep_Taxonomy_and_Features.txt"

# Directory containing the original dereplicated MAG FASTA files.
genome_path <- "./dRep_MAGs_compressed/"

# Directory where renamed public FASTA files will be written.
# This avoids overwriting the original internal FASTA files.
public_genome_path <- "./RESPICAT_MAGs_v1.0_public_fasta/"

# ---- 1.3 Check input directory ----
# Stop early if the genome directory does not exist.
# This prevents silent failures later during file renaming.
if (dir.exists(genome_path)) {
    cat("Reading genomes from directory:", genome_path, "\n")
} else {
    stop("Directory not found: ", genome_path)
}

# ---- 1.4 Create output directory ----
# Create a separate output directory for public FASTA files.
# This keeps the original internal files unchanged.
if (!dir.exists(public_genome_path)) {
    dir.create(
        public_genome_path,
        recursive = TRUE
    )
    
    cat("Created public genome directory:", public_genome_path, "\n")
} else {
    cat("Writing renamed genomes to existing directory:", public_genome_path, "\n")
}

# ============================================================
# 2. Read mapping file and add a Public ID column
# ============================================================
# ---- 2.1 Read mapping file ----
# Read the dereplicated MAG feature and taxonomy table.
RESPICAT_global_map_df <- read_tsv(
    RESPICAT_global_map_file,
    show_col_types = FALSE
)

# ---- 2.2 Add stable public RESPICAT MAG identifiers ----
# Sort the table before assigning public IDs.
# This makes the ID assignment reproducible from the same input table.
RESPICAT_global_map_df <- 
    RESPICAT_global_map_df %>% 
    
    # Arrange by the current internal MAG identifier.
    # This should be stable and unique for each dereplicated MAG.
    arrange(
        Unique_MAG_ID
    ) %>% 
    
    # Add a sequential public MAG identifier.
    # Example: RESPICAT_MAG_000001, RESPICAT_MAG_000002, ...
    mutate(
        Public_MAG_ID = paste0(
            "RESPICAT_MAG_",
            sprintf(
                "%06d",
                row_number()
            )
        )
    ) %>%
    
    # Move the public ID to the first column.
    relocate(
        Public_MAG_ID
    )


# ============================================================
# 3. Prepare FASTA filename mapping
# ============================================================

# ---- 3.1 List FASTA files in genome directory ----
# List only files ending with ".fasta".
# The "\\.fasta$" pattern avoids accidentally matching filenames
# where "fasta" appears in the middle.
dRep_genome_fileNames <- list.files(
    genome_path,
    pattern = "\\.fasta$",
    full.names = FALSE
)

# ---- 3.2 Check that FASTA files were found ----
# Stop if no FASTA files are present in the directory.
if (length(dRep_genome_fileNames) == 0) {
    stop("No .fasta files found in: ", genome_path)
}

cat("Number of FASTA files found:", length(dRep_genome_fileNames), "\n")

# ---- 3.3 Check that the mapping table has the required columns ----
# These columns are needed to connect internal filenames to public IDs.
required_columns <- c(
    "Public_MAG_ID",
    "genome_file"
)

missing_columns <- setdiff(
    required_columns,
    colnames(RESPICAT_global_map_df)
)

if (length(missing_columns) > 0) {
    stop(
        "Missing required columns in mapping file: ",
        paste(missing_columns, collapse = ", ")
    )
}

# ---- 3.4 Create clean filename mapping table ----
# Keep only the columns needed for renaming.
# The public filename is derived directly from Public_MAG_ID.
RESPICAT_fasta_rename_map <- 
    RESPICAT_global_map_df %>% 
    select(
        Public_MAG_ID,
        genome_file
    ) %>% 
    
    # Make sure genome_file only contains the basename.
    # This protects the code if genome_file contains a path.
    mutate(
        original_fasta_filename = basename(genome_file),
        public_fasta_filename = paste0(Public_MAG_ID, ".fna"),
        original_fasta_path = file.path(genome_path, original_fasta_filename),
        public_fasta_path = file.path(public_genome_path, public_fasta_filename)
    )

# ---- 3.5 Check for duplicate public IDs or filenames ----
# Public IDs must be unique because they define final FASTA names.
if (anyDuplicated(RESPICAT_fasta_rename_map$Public_MAG_ID) > 0) {
    stop("Duplicate Public_MAG_ID values detected.")
}

# Original FASTA filenames should also be unique.
if (anyDuplicated(RESPICAT_fasta_rename_map$original_fasta_filename) > 0) {
    stop("Duplicate original FASTA filenames detected in genome_file column.")
}

# ---- 3.6 Check that all mapped FASTA files exist ----
# This confirms that every MAG in the mapping table has a matching FASTA file.
missing_fasta_files <- 
    RESPICAT_fasta_rename_map %>% 
    filter(
        !file.exists(original_fasta_path)
    )

if (nrow(missing_fasta_files) > 0) {
    print(missing_fasta_files)
    stop("Some FASTA files listed in the mapping table were not found.")
}

# ---- 3.7 Check for unmapped FASTA files in the directory ----
# This detects FASTA files present in the folder but absent from the mapping table.
unmapped_fasta_files <- setdiff(
    dRep_genome_fileNames,
    RESPICAT_fasta_rename_map$original_fasta_filename
)

if (length(unmapped_fasta_files) > 0) {
    cat(
        "Warning: FASTA files found in directory but not present in mapping table:\n"
    )
    print(unmapped_fasta_files)
}

# ---- 3.8 Check for existing public FASTA files ----
# Stop if output files already exist.
# This prevents accidental overwriting of a previous public release.
existing_public_files <- 
    RESPICAT_fasta_rename_map %>% 
    filter(
        file.exists(public_fasta_path)
    )

if (nrow(existing_public_files) > 0) {
    print(existing_public_files)
    stop(
        "Some public FASTA files already exist. ",
        "Delete them or use a new output directory before rerunning."
    )
}


# ============================================================
# 4. Copy FASTA files with public RESPICAT filenames
# ============================================================

# ---- 4.1 Copy files instead of renaming in place ----
# file.copy() preserves the original internal FASTA files.
# file.copy() is safer than file.rename() for public release preparation.
copy_success <- file.copy(
    from = RESPICAT_fasta_rename_map$original_fasta_path,
    to = RESPICAT_fasta_rename_map$public_fasta_path,
    overwrite = FALSE
)

# ---- 4.2 Check copy status ----
# Stop if any file failed to copy.
if (!all(copy_success)) {
    failed_files <- RESPICAT_fasta_rename_map %>% 
        filter(
            !copy_success
        )
    
    print(failed_files)
    stop("Some FASTA files failed to copy.")
}

cat("Copied renamed public FASTA files:", sum(copy_success), "\n")


# ============================================================
# 5. Save public FASTA ID mapping file
# ============================================================

# ---- 5.1 Create public ID mapping table ----
# This table connects the original internal filenames to public filenames.
# It should be included with the public RESPICAT release.
RESPICAT_MAG_id_mapping_v1 <- 
    RESPICAT_global_map_df %>% 
    mutate(
        original_fasta_filename = basename(genome_file),
        public_fasta_filename = paste0(Public_MAG_ID, ".fna")
    ) %>% 
    select(
        Public_MAG_ID,
        Unique_MAG_ID,
        public_fasta_filename,
        original_fasta_filename,
        genome_file,
        AT_BatchID,
        user_genome
    )

# ---- 5.2 Write ID mapping table ----
# Save the mapping file as a TSV for easy reuse.
write_tsv(
    RESPICAT_MAG_id_mapping_v1,
    "RESPICAT_MAG_id_mapping_v1.0.tsv"
)

cat("Saved ID mapping file: RESPICAT_MAG_id_mapping_v1.0.tsv\n")

# ============================================================
# 6. Rename contig IDs inside public RESPICAT FASTA files
# ============================================================

# ---- 6.1 Define a helper function to rename FASTA headers ----
# This function takes one FASTA file and one Public_MAG_ID.
# It replaces all FASTA header lines with stable public contig IDs.
# Example:
# >old_header_1
# becomes:
# >RESPICAT_MAG_000001_contig_000001

rename_fasta_contig_headers <- function(
        fasta_path,
        Public_MAG_ID
) {
    
    # Check that the FASTA file exists before reading it.
    if (!file.exists(fasta_path)) {
        stop("FASTA file not found: ", fasta_path)
    }
    
    # Read the FASTA file as plain text.
    fasta_lines <- readLines(
        fasta_path,
        warn = FALSE
    )
    
    # Find the line numbers corresponding to FASTA headers.
    # FASTA headers are the lines that start with ">".
    header_idx <- grep(
        pattern = "^>",
        x = fasta_lines
    )
    
    # Stop if the file does not contain any FASTA headers.
    # A valid FASTA file should contain at least one header.
    if (length(header_idx) == 0) {
        stop("No FASTA headers found in file: ", fasta_path)
    }
    
    # Create new contig IDs for this MAG.
    # The contig counter restarts from 1 for each MAG.
    # Example:
    # RESPICAT_MAG_000001_contig_000001
    # RESPICAT_MAG_000001_contig_000002
    new_contig_ids <- paste0(
        Public_MAG_ID,
        "_contig_",
        sprintf(
            "%06d",
            seq_len(length(header_idx))
        )
    )
    
    # Replace the old FASTA headers with the new public contig IDs.
    # Add ">" symbol as per FASTA headers format.
    fasta_lines[header_idx] <- paste0(
        ">",
        new_contig_ids
    )
    
    # Write first to a temporary file in the same directory.
    # This avoids corrupting the original file if writing fails midway.
    temp_fasta_path <- paste0(
        fasta_path,
        ".tmp"
    )
    
    writeLines(
        text = fasta_lines,
        con = temp_fasta_path
    )
    
    # Replace the original public FASTA file with the updated version.
    # This keeps the filename unchanged but updates the internal headers.
    rename_success <- file.rename(
        from = temp_fasta_path,
        to = fasta_path
    )
    
    # Stop if the temporary file could not replace the original file.
    if (!rename_success) {
        stop("Could not replace original FASTA file with renamed version: ", fasta_path)
    }
    
    # Return a small summary for logging and sanity checks.
    tibble(
        Public_MAG_ID = Public_MAG_ID,
        public_fasta_path = fasta_path,
        n_contigs_renamed = length(header_idx)
    )
}


# ---- 6.2 Create full public FASTA paths ----
# Use the public filename and public output directory to locate
# the renamed public FASTA files.
RESPICAT_fasta_rename_map <- 
    RESPICAT_fasta_rename_map %>% 
    mutate(
        public_fasta_path = file.path(
            public_genome_path,
            public_fasta_filename
        )
    )


# ---- 6.3 Check that all public FASTA files exist ----
# The files should already exist because they were copied in Step 4.
missing_public_fasta_files <- 
    RESPICAT_fasta_rename_map %>% 
    filter(
        !file.exists(public_fasta_path)
    )

if (nrow(missing_public_fasta_files) > 0) {
    print(missing_public_fasta_files)
    stop("Some public FASTA files were not found before contig renaming.")
}


# ---- 6.4 Rename contig headers in all public FASTA files ----
# pmap_dfr() loops over each row of the mapping table.
# For each MAG, it sends the public FASTA path and Public_MAG_ID
# to the helper function defined above.
RESPICAT_contig_rename_summary <- 
    RESPICAT_fasta_rename_map %>% 
    select(
        Public_MAG_ID,
        public_fasta_path
    ) %>% 
    pmap_dfr(
        function(
        Public_MAG_ID,
        public_fasta_path
        ) {
            
            # Print progress so long runs are easy to monitor.
            cat("Renaming contigs for:", Public_MAG_ID, "\n")
            
            # Rename all contig headers for this one MAG.
            rename_fasta_contig_headers(
                fasta_path = public_fasta_path,
                Public_MAG_ID = Public_MAG_ID
            )
        }
    )

cat(
    "Finished renaming contig headers for",
    nrow(RESPICAT_contig_rename_summary),
    "MAG FASTA files.\n"
)


# ============================================================
# 7. Save contig-renaming summary
# ============================================================

# ---- 7.1 Save number of renamed contigs per MAG ----
# This file is useful as a sanity check.
# It records how many contigs were detected and renamed in each MAG.
write_tsv(
    RESPICAT_contig_rename_summary,
    "RESPICAT_MAG_contig_rename_summary_v1.0.tsv"
)

cat("Saved contig rename summary: RESPICAT_MAG_contig_rename_summary_v1.0.tsv\n")


# ============================================================
# 8. Sanity-check renamed FASTA headers
# ============================================================

# ---- 8.1 Read the first few headers from the first public FASTA ----
# This gives a quick visual confirmation that the new header format worked.
example_public_fasta <- RESPICAT_fasta_rename_map$public_fasta_path[1]

example_headers <- readLines(
    example_public_fasta,
    warn = FALSE
) %>% 
    str_subset(
        "^>"
    ) %>% 
    head(
        10
    )

cat("Example renamed FASTA headers:\n")
print(example_headers)


# ---- 8.2 Confirm that all public FASTA files still exist ----
# This checks that no file was lost during temporary-file replacement.
stopifnot(
    all(
        file.exists(RESPICAT_fasta_rename_map$public_fasta_path)
    )
)

cat("All public FASTA files exist after contig header renaming.\n")
# ============================================================
# 9. Define columns for RESPICAT public share files
# ============================================================

# ---- 9.1 FASTA archive renaming columns ----
# Useful for tracking which internal genome file
# corresponds to each public RESPICAT MAG ID.
RESPICAT_MAGs_v1_columns <- c(
    "Public_MAG_ID",
    "Unique_MAG_ID",
    "genome_file"
)


# ---- 9.2 Main MAG metadata columns ----
# File: RESPICAT_MAG_metadata_v1.0.tsv
# Broad user-facing metadata file.
# It contains public MAG IDs, basic provenance, compact taxonomy,
# and key genome quality statistics.
RESPICAT_MAG_metadata_v1_columns <- c(
    "Public_MAG_ID",
    "genome_file",
    "AT_BatchID",
    "user_genome",
    "Domain",
    "phylum",
    "class",
    "order",
    "family",
    "genus",
    "species",
    "no_species_assignment",
    "Completeness",
    "Contamination",
    "Strain_heterogeneity",
    "Size",
    "N50"
)


# ---- 9.3 MAG taxonomy columns ----
# File: RESPICAT_MAG_taxonomy_v1.0.tsv
# File focusing only on taxonomic annotation.
RESPICAT_MAG_taxonomy_v1_columns <- c(
    "Public_MAG_ID",
    "Domain",
    "phylum",
    "class",
    "order",
    "family",
    "genus",
    "species",
    "no_species_assignment"
)


# ---- 9.4 MAG quality summary columns ----
# File: RESPICAT_MAG_quality_summary_v1.0.tsv
# File for genome quality and assembly statistics.
RESPICAT_MAG_quality_summary_v1_columns <- c(
    "Public_MAG_ID",
    "Completeness",
    "Contamination",
    "Strain_heterogeneity",
    "Size",
    "N50",
    "score"
)

# ---- 9.5 MAG ID mapping columns ----
# File: RESPICAT_MAG_id_mapping_v1.0.tsv
# Mapping file to link the public RESPICAT MAG ID to the original
# internal MAG identifier and source genome filename.
RESPICAT_MAG_id_mapping_v1_columns <- c(
    "Public_MAG_ID",
    "Unique_MAG_ID",
    "genome_file",
    "AT_BatchID",
    "user_genome"
)


# ============================================================
# 10. Check required columns before creating public files
# ============================================================

# ---- 10.1 Combine all required column names ----
# This creates one non-redundant list of all columns needed
# across the four public TSV files.
RESPICAT_public_required_columns <- unique(
    c(
        RESPICAT_MAG_metadata_v1_columns,
        RESPICAT_MAG_taxonomy_v1_columns,
        RESPICAT_MAG_quality_summary_v1_columns,
        RESPICAT_MAG_id_mapping_v1_columns
    )
)

# ---- 10.2 Check for missing columns in the global map table ----
# This prevents the script from silently creating incomplete files.
missing_public_columns <- setdiff(
    RESPICAT_public_required_columns,
    colnames(RESPICAT_global_map_df)
)

# ---- 10.3 Stop if required columns are missing ----
# A hard stop is safer here because these files are intended
# for public release.
if (length(missing_public_columns) > 0) {
    stop(
        "Missing required columns in RESPICAT_global_map_df: ",
        paste(
            missing_public_columns,
            collapse = ", "
        )
    )
}

cat(
    "All required columns are present in RESPICAT_global_map_df.\n"
)


# ============================================================
# 11. Add public FASTA filename information
# ============================================================

# ---- 11.1 Prepare FASTA filename lookup table ----
# The global map already has the genome_file column.
# The rename map contains the public FASTA filename and paths.
RESPICAT_fasta_filename_lookup <- 
    RESPICAT_fasta_rename_map %>% 
    select(
        Public_MAG_ID,
        original_fasta_filename,
        public_fasta_filename
    )

# ---- 11.2 Join public FASTA filenames to the global map ----
# This makes the metadata files more useful because users can directly
# connect each MAG ID to the released FASTA file.
RESPICAT_global_map_public_df <- 
    RESPICAT_global_map_df %>% 
    left_join(
        RESPICAT_fasta_filename_lookup,
        by = "Public_MAG_ID"
    )

# ---- 11.3 Check that every MAG has a public FASTA filename ----
# Every public MAG should have one corresponding public FASTA file.
missing_public_fasta_names <- 
    RESPICAT_global_map_public_df %>% 
    filter(
        is.na(public_fasta_filename)
    )

if (nrow(missing_public_fasta_names) > 0) {
    print(missing_public_fasta_names)
    stop("Some MAGs are missing public FASTA filename information.")
}

cat(
    "Public FASTA filenames successfully joined to metadata table.\n"
)


# ============================================================
# 12. Create RESPICAT public metadata files
# ============================================================

# ---- 12.1 Create main MAG metadata table ----
# Main user-facing lookup table.
RESPICAT_MAG_metadata_v1 <- 
    RESPICAT_global_map_public_df %>% 
    # Add public_fasta_filename next to Public_MAG_ID
    select(
        Public_MAG_ID,
        public_fasta_filename,
        all_of(
            setdiff(
                RESPICAT_MAG_metadata_v1_columns,
                "Public_MAG_ID"
            )
        )
    )

# ---- 12.2 Create taxonomy-only table ----
RESPICAT_MAG_taxonomy_v1 <- 
    RESPICAT_global_map_public_df %>% 
    select(
        all_of(
            RESPICAT_MAG_taxonomy_v1_columns
        )
    )

# ---- 12.3 Create quality-summary table ----
# This file contains public MAG ID and genome quality statistics.
RESPICAT_MAG_quality_summary_v1 <- 
    RESPICAT_global_map_public_df %>% 
    select(
        all_of(
            RESPICAT_MAG_quality_summary_v1_columns
        )
    )

# ---- 12.4 Create ID-mapping table ----
# This file links public RESPICAT IDs to original internal identifiers.
# Include public_fasta_filename so users can connect the mapping table
# directly to the released FASTA archive.
RESPICAT_MAG_id_mapping_v1 <- 
    RESPICAT_global_map_public_df %>% 
    select(
        Public_MAG_ID,
        public_fasta_filename,
        original_fasta_filename,
        all_of(
            setdiff(
                RESPICAT_MAG_id_mapping_v1_columns,
                "Public_MAG_ID"
            )
        )
    )


# ============================================================
# 13. Run sanity checks on public metadata files
# ============================================================

# ---- 13.1 Check row counts ----
# Each public table should have one row per dereplicated MAG.
stopifnot(
    nrow(RESPICAT_MAG_metadata_v1) == nrow(RESPICAT_global_map_df),
    nrow(RESPICAT_MAG_taxonomy_v1) == nrow(RESPICAT_global_map_df),
    nrow(RESPICAT_MAG_quality_summary_v1) == nrow(RESPICAT_global_map_df),
    nrow(RESPICAT_MAG_id_mapping_v1) == nrow(RESPICAT_global_map_df)
)

cat(
    "All public metadata files have the expected number of rows:",
    nrow(RESPICAT_global_map_df),
    "\n"
)

# ---- 13.2 Check Public_MAG_ID uniqueness ----
# Public_MAG_ID must be unique in all public files.
stopifnot(
    anyDuplicated(RESPICAT_MAG_metadata_v1$Public_MAG_ID) == 0,
    anyDuplicated(RESPICAT_MAG_taxonomy_v1$Public_MAG_ID) == 0,
    anyDuplicated(RESPICAT_MAG_quality_summary_v1$Public_MAG_ID) == 0,
    anyDuplicated(RESPICAT_MAG_id_mapping_v1$Public_MAG_ID) == 0
)

cat(
    "Public_MAG_ID values are unique in all public metadata files.\n"
)

# ---- 13.3 Check public FASTA filename uniqueness ----
# Each MAG should map to exactly one public FASTA filename.
stopifnot(
    anyDuplicated(RESPICAT_MAG_metadata_v1$public_fasta_filename) == 0,
    anyDuplicated(RESPICAT_MAG_id_mapping_v1$public_fasta_filename) == 0
)

cat(
    "Public FASTA filenames are unique in metadata and ID mapping files.\n"
)

# ---- 13.4 Check public FASTA files exist on disk ----
# This confirms that the metadata points to actual files
# in the public FASTA directory.
missing_public_fasta_files <- 
    RESPICAT_MAG_metadata_v1 %>% 
    mutate(
        public_fasta_path = file.path(
            public_genome_path,
            public_fasta_filename
        )
    ) %>% 
    filter(
        !file.exists(public_fasta_path)
    )

if (nrow(missing_public_fasta_files) > 0) {
    print(missing_public_fasta_files)
    stop("Some public FASTA files listed in metadata were not found on disk.")
}

cat(
    "All public FASTA files listed in metadata exist on disk.\n"
)


# ============================================================
# 14. Save RESPICAT public metadata files
# ============================================================

# ---- 14.1 Define output filenames ----
# These filenames match the public RESPICAT v1.0 release naming scheme.
RESPICAT_MAG_metadata_v1_file <- "RESPICAT_MAG_metadata_v1.0.tsv"
RESPICAT_MAG_taxonomy_v1_file <- "RESPICAT_MAG_taxonomy_v1.0.tsv"
RESPICAT_MAG_quality_summary_v1_file <- "RESPICAT_MAG_quality_summary_v1.0.tsv"
RESPICAT_MAG_id_mapping_v1_file <- "RESPICAT_MAG_id_mapping_v1.0.tsv"

# ---- 14.2 Save main MAG metadata file ----
# This is the primary lookup table for most users.
write_tsv(
    RESPICAT_MAG_metadata_v1,
    RESPICAT_MAG_metadata_v1_file
)

cat(
    "Saved file:",
    RESPICAT_MAG_metadata_v1_file,
    "\n"
)

# ---- 14.3 Save MAG taxonomy file ----
# This file stores only taxonomic annotations.
write_tsv(
    RESPICAT_MAG_taxonomy_v1,
    RESPICAT_MAG_taxonomy_v1_file
)

cat(
    "Saved file:",
    RESPICAT_MAG_taxonomy_v1_file,
    "\n"
)

# ---- 14.4 Save MAG quality summary file ----
# This file stores completeness, contamination, genome size,
# N50, strain heterogeneity, and dereplication score.
write_tsv(
    RESPICAT_MAG_quality_summary_v1,
    RESPICAT_MAG_quality_summary_v1_file
)

cat(
    "Saved file:",
    RESPICAT_MAG_quality_summary_v1_file,
    "\n"
)

# ---- 14.5 Save MAG ID mapping file ----
# This file stores the bridge between public IDs and original IDs.
write_tsv(
    RESPICAT_MAG_id_mapping_v1,
    RESPICAT_MAG_id_mapping_v1_file
)

cat(
    "Saved file:",
    RESPICAT_MAG_id_mapping_v1_file,
    "\n"
)


# ============================================================
# 15. Print compact release summary
# ============================================================

# ---- 15.1 Summarise generated public files ----
# This provides a simple completion report at the end of the script.
RESPICAT_public_file_summary <- tibble(
    file_name = c(
        RESPICAT_MAG_metadata_v1_file,
        RESPICAT_MAG_taxonomy_v1_file,
        RESPICAT_MAG_quality_summary_v1_file,
        RESPICAT_MAG_id_mapping_v1_file
    ),
    n_rows = c(
        nrow(RESPICAT_MAG_metadata_v1),
        nrow(RESPICAT_MAG_taxonomy_v1),
        nrow(RESPICAT_MAG_quality_summary_v1),
        nrow(RESPICAT_MAG_id_mapping_v1)
    ),
    n_columns = c(
        ncol(RESPICAT_MAG_metadata_v1),
        ncol(RESPICAT_MAG_taxonomy_v1),
        ncol(RESPICAT_MAG_quality_summary_v1),
        ncol(RESPICAT_MAG_id_mapping_v1)
    )
)

# ---- 15.2 Print summary table ----
# This helps confirm that the expected files were generated.
print(
    RESPICAT_public_file_summary
)

cat(
    "Finished creating RESPICAT public metadata files.\n"
)
