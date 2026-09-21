#' Execute Round 2 Workflow (Euthanized Fish Excluded)
#'
#' This script demonstrates how to run the complete round 2 analysis workflow.
#' Round 2 filters out fish in the "Euthanized" mortality status to focus on
#' natural post-release survival patterns.
#'
#' Modify the parameters below to point to your actual data directories.

# Load workflow function
source("round_2_workflow.R")

# ---- Configuration ----
# Paths should be adjusted to your actual directory structure
RAW_DATA_DIR <- "path/to/raw/data"        # Directory with tags.csv, nodes.csv, events.csv
OUTPUT_DIR <- "path/to/output"             # Where to save processed files and report
REFERENCE_DOC <- "ref_doc_w.docx"          # Word template for report styling (optional)

# ---- Run workflow ----
results <- run_round_2_workflow(
  raw_data_dir = RAW_DATA_DIR,
  output_dir = OUTPUT_DIR,
  fix_river_km_by_location = NULL,        # Or provide named vector: c("Location1" = km_value, ...)
  fix_bucket = NULL,                       # Or provide integer to standardize bucket
  reference_doc = REFERENCE_DOC,
  render_report = TRUE
)

# ---- Access results ----
# View processed tags (euthanized fish excluded)
head(results$tags_processed)

# Check how many fish were excluded
cat("Fish excluded (Euthanized):", results$n_excluded, "\n")
cat("Fish retained in analysis:", results$n_retained, "\n")

# View summary table with p-values
results$survival_summary

# Check output directory
list.files(results$output_dir)
