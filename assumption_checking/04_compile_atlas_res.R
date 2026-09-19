

setwd("c:/repos/grant_2026/assumption_checking")
# Load workflow function

source("round_1/round_1_workflow.R")




# ---- Configuration ----
# Paths should be adjusted to your actual directory structure
RAW_DATA_DIR <- "path/to/raw/data"        # Directory with tags.csv, nodes.csv, events.csv
OUTPUT_DIR <- "path/to/output"             # Where to save processed files and report
REFERENCE_DOC <- "ref_doc_w.docx"          # Word template for report styling (optional)

# ---- Run workflow ----
results <- run_round_1_workflow(
  raw_data_dir = RAW_DATA_DIR,
  output_dir = OUTPUT_DIR,
  fix_river_km_by_location = NULL,        # Or provide named vector: c("Location1" = km_value, ...)
  fix_bucket = NULL,                       # Or provide integer to standardize bucket
  reference_doc = REFERENCE_DOC,
  render_report = TRUE
)

# ---- Access results ----
# View processed tags
head(results$tags_processed)

# View summary table with p-values
results$survival_summary

# Check output directory
list.files(results$output_dir)
