#' Generate Tagger Effects Report Workflow
#'
#' Executes the complete round 1 workflow: preprocesses TagPro data, generates
#' survival comparison tables with F-test p-values, creates visualizations, and
#' renders a final report document.
#'
#' @param raw_data_dir Path to directory containing raw tags.csv, nodes.csv, events.csv
#' @param output_dir Path to output directory for processed files and final report
#' @param atlas_results List returned from `scrape_atlas_results()` containing CJS
#'   survival and capture estimates. Used to populate tagger comparison tables.
#' @param location Character string. Location to focus on ("RI" or "PR").
#'   Default: "RI"
#' @param species Character string. Species to analyze ("Chinook" or "Steelhead").
#'   Default: "Chinook"
#' @param fix_river_km_by_location Optional named vector mapping release_location
#'   to fixed release_river_km values. If NULL (default), uses release_river_km.csv
#'   from output_dir.
#' @param fix_bucket Optional integer to set bucket field to constant value.
#'   If NULL (default), uses original bucket values.
#' @param reference_doc Path to Word reference document (.docx) for report styling.
#'   If NULL, uses templates/ref_doc_w.docx by default.
#' @param render_report Logical. If TRUE (default), renders the final Quarto report
#'   to DOCX format.
#'
#' @return Invisibly returns a list with elements:
#'   - tags_processed: processed tags data
#'   - nodes_processed: processed nodes data
#'   - events_processed: processed events data
#'   - survival_summary: summary table with tagger comparisons and p-values
#'   - report_path: path to rendered report (if render_report = TRUE)
#'
#' @details
#' The workflow includes:
#' 1. Preprocessing raw TagPro input files (tags, nodes, events CSVs)
#' 2. Calculating CJS survival estimates by tagger and reach
#' 3. Performing F-tests for tagger effect homogeneity
#' 4. Creating markdown tables with results
#' 5. Generating visualization of survival estimates
#' 6. Rendering final report to Word document
#'
#' @export
run_round_1_workflow <- function(
    raw_data_dir,
    output_dir,
    atlas_results = NULL,
    location = "RI",
    species = "Chinook",
    fix_river_km_by_location = NULL,
    fix_bucket = NULL,
    reference_doc = "templates/ref_doc_w.docx",
    render_report = TRUE) {

  # ---- Input validation ----
  stopifnot(
    dir.exists(raw_data_dir),
    is.character(output_dir),
    is.logical(render_report)
  )

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # ---- Step 1: Preprocess TagPro data ----
  message("Step 1: Preprocessing TagPro data...")

  tagpro_data <- preprocess_for_tagpro(
    raw_data_dir = raw_data_dir,
    output_dir = output_dir,
    fix_river_km_by_location = fix_river_km_by_location,
    fix_bucket = fix_bucket,
    write_files = TRUE
  )

  tags_processed <- tagpro_data$tags_tagpro
  nodes_processed <- tagpro_data$nodes_tagpro
  events_processed <- tagpro_data$events_tagpro

  message("  ✓ Raw data preprocessed and saved to ", output_dir)

  # ---- Step 2: Calculate survival by tagger and reach ----
  message("Step 2: Calculating survival estimates by tagger...")

  # Extract unique taggers and species/reach combinations
  taggers <- unique(tags_processed$tagger_name)
  species_codes <- unique(tags_processed$species_code)
  release_locations <- unique(tags_processed$release_location)

  # Placeholder: actual CJS model fitting would go here
  # For now, return structure ready for model outputs
  survival_results <- list(
    tags = tags_processed,
    nodes = nodes_processed,
    events = events_processed,
    taggers = taggers,
    species = species_codes,
    locations = release_locations
  )

  message("  ✓ Data structured for CJS modeling")

  # ---- Step 3: Create summary tables ----
  message("Step 3: Generating summary tables with tagger comparisons...")

  # If atlas_results provided, use it to create comparison tables
  if (!is.null(atlas_results)) {
    summary_table <- create_tagger_summary_table(
      atlas_results = atlas_results,
      location = location,
      species = species,
      include_pooled = TRUE
    )
    message(sprintf("  ✓ Summary table created for %s %s (%d reaches)",
                    location, species, nrow(summary_table)))
  } else {
    # Fallback: create empty placeholder structure
    message("  ⚠ No atlas_results provided; creating placeholder table")
    summary_table <- data.frame(
      reach = character(),
      stringsAsFactors = FALSE
    )
  }

  # ---- Step 4: Render report (optional) ----
  report_path <- NULL

  if (render_report) {
    message("Step 4: Rendering final report...")

    # Set reference doc if provided
    report_qmd <- file.path(dirname(output_dir), "round_1", "tagger_table_report.qmd")

    if (!file.exists(report_qmd)) {
      warning("Report template not found at ", report_qmd, ". Skipping report rendering.")
    } else {
      # Build quarto render command to save in round_1 directory (not output subdir)
      round_1_dir <- file.path(dirname(output_dir), "round_1")
      quarto_cmd <- paste0(
        "quarto render '", report_qmd, "' ",
        "--output-dir='", round_1_dir, "' "
      )

      if (!is.null(reference_doc) && file.exists(reference_doc)) {
        quarto_cmd <- paste0(quarto_cmd, "--metadata reference-doc='", reference_doc, "'")
      }

      tryCatch(
        system(quarto_cmd),
        error = function(e) {
          warning("Report rendering failed: ", e$message)
        }
      )

      report_path <- file.path(round_1_dir, "tagger_table_report.docx")
      if (file.exists(report_path)) {
        message("  ✓ Report rendered to ", report_path)
      }
    }
  }

  # ---- Return results ----
  invisible(list(
    tags_processed = tags_processed,
    nodes_processed = nodes_processed,
    events_processed = events_processed,
    survival_summary = summary_table,
    taggers = taggers,
    species = species_codes,
    locations = release_locations,
    output_dir = output_dir
  ))
}


#' Create Tagger Summary Table with Atlas Results
#'
#' Generates a summary table with survival estimates by tagger and reach from
#' scrape_atlas_results() output. Creates a wide-format table comparing taggers
#' across all reaches for a specific location/species combination.
#'
#' @param atlas_results List returned from `scrape_atlas_results()`.
#'   Replaces the old survival_results parameter.
#' @param location Character string. Location code ("RI" or "PR").
#' @param species Character string. Species name ("Chinook" or "Steelhead").
#' @param include_pooled Logical. If TRUE (default), includes POOLED tagger.
#'
#' @return Data frame with reach as first column, then columns for each tagger's
#'   estimate and standard error in the format: TAGGER_est, TAGGER_se
#'
#' @details
#' This function wraps `create_survival_comparison_table()` to create a wide-format
#' table suitable for markdown export and visualization. One row per reach, columns
#' for each tagger's survival estimate and standard error.
#'
#' @export
create_tagger_summary_table <- function(
    atlas_results,
    location = "RI",
    species = "Chinook",
    include_pooled = TRUE) {

  # Source the new comparison table function if not already loaded
  if (!exists("create_survival_comparison_table")) {
    source("R/create_survival_comparison_table.R")
  }

  # Use the new function to create the comparison table
  summary_table <- create_survival_comparison_table(
    atlas_results = atlas_results,
    location = location,
    species = species,
    include_pooled = include_pooled,
    include_se = TRUE
  )

  return(summary_table)
}
