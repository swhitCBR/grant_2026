#' Render Tagger Effects Report
#'
#' Renders the tagger_table_report.qmd to DOCX format.
#' Run from within the round_1 directory.
#'
#' Prerequisites:
#'   - tagger_table_report.qmd exists in this directory
#'   - tagger_survival_comparison.png exists in this directory
#'   - templates/ref_doc_w.docx exists in parent directory

# Set working directory to this script's location if needed
script_dir <- dirname(rstudioapi::getActiveDocumentContext()$path)
if (script_dir != "" && !is.na(script_dir)) {
  setwd(script_dir)
  cat("Working directory set to:", getwd(), "\n")
}

# Verify required files exist
required_files <- c(
  "tagger_table_report.qmd",
  "tagger_survival_comparison.png",
  "../templates/ref_doc_w.docx"
)

missing_files <- !file.exists(required_files)
if (any(missing_files)) {
  cat("ERROR: Missing required files:\n")
  cat(paste("  -", required_files[missing_files], collapse = "\n"), "\n")
  stop("Cannot proceed without all required files")
}

cat("All required files found.\n\n")

# Render the report
cat("Rendering tagger_table_report.qmd to DOCX...\n")

tryCatch({
  quarto::quarto_render(
    "tagger_table_report.qmd",
    output_format = "docx"
  )
  
  cat("\n✓ Report rendered successfully!\n")
  cat("Output: tagger_table_report.docx\n")
  
  # Check if output file exists
  if (file.exists("tagger_table_report.docx")) {
    file_info <- file.info("tagger_table_report.docx")
    cat("File size:", round(file_info$size / 1024, 1), "KB\n")
    cat("Last modified:", as.character(file_info$mtime), "\n")
  }
  
}, error = function(e) {
  cat("ERROR during rendering:\n")
  cat(conditionMessage(e), "\n")
  stop("Rendering failed")
})
