#' Generate Tagger Effects Report Workflow - Round 2 (Euthanized Excluded)
#'
#' Executes round 2 workflow: loads TagPro-formatted data, excludes euthanized fish,
#' and generates a report document.
#'
#' @param data_dir Path to directory containing tags.csv, nodes.csv, events.csv (TagPro format)
#' @param output_dir Path to output directory for processed files and final report
#' @param reference_doc Path to Word reference document (.docx) for report styling.
#'   If NULL, uses templates/ref_doc_w.docx by default.
#' @param render_report Logical. If TRUE (default), renders the final Quarto report
#'   to DOCX format.
#'
#' @return Invisibly returns a list with elements:
#'   - tags_processed: processed tags data (euthanized fish excluded)
#'   - nodes_processed: processed nodes data
#'   - events_processed: processed events data
#'   - n_excluded: number of fish excluded due to euthanasia
#'   - n_retained: number of fish retained in analysis
#'   - report_path: path to rendered report (if render_report = TRUE)
#'
#' @details
#' The workflow includes:
#' 1. Loading TagPro-formatted input files
#' 2. Excluding euthanized fish from analysis
#' 3. Creating markdown tables with results
#' 4. Rendering final report to Word document
#'
#' ROUND 2 MODIFICATION: Fish with mortality status "Euthanized" are excluded from
#' analysis to focus on natural post-release survival patterns.
#'
#' @export
run_round_2_workflow <- function(
    data_dir,
    output_dir,
    reference_doc = "templates/ref_doc_w.docx",
    render_report = TRUE) {

  # ---- Input validation ----
  stopifnot(
    dir.exists(data_dir),
    is.character(output_dir),
    is.logical(render_report)
  )

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # ---- Step 1: Load and filter TagPro data ----
  message("Step 1: Loading TagPro data and excluding euthanized fish...")

  tags_raw <- read.csv(file.path(data_dir, "tags.csv"), stringsAsFactors = FALSE)
  nodes_raw <- read.csv(file.path(data_dir, "nodes.csv"), stringsAsFactors = FALSE)
  events_raw <- read.csv(file.path(data_dir, "events.csv"), stringsAsFactors = FALSE)

  n_total <- nrow(tags_raw)

  # ROUND 2 FILTER: Remove euthanized fish
  tags_processed <- tags_raw |>
    dplyr::filter(mortality != "Euthanized")

  nodes_processed <- nodes_raw
  events_processed <- events_raw

  n_excluded <- n_total - nrow(tags_processed)
  n_retained <- nrow(tags_processed)

  message("  ✓ Data loaded from ", data_dir)
  message("  ✓ Excluded ", n_excluded, " euthanized fish")
  message("  ✓ Retained ", n_retained, " fish for analysis")

  # ---- Step 2: Save processed data ----
  message("Step 2: Saving processed data...")

  write.csv(tags_processed, file.path(output_dir, "tags.csv"), row.names = FALSE, quote = FALSE)
  write.csv(nodes_processed, file.path(output_dir, "nodes.csv"), row.names = FALSE, quote = FALSE)
  write.csv(events_processed, file.path(output_dir, "events.csv"), row.names = FALSE, quote = FALSE)

  message("  ✓ Processed data saved to ", output_dir)

  # ---- Step 3: Render report (optional) ----
  report_path <- NULL

  if (render_report) {
    message("Step 3: Rendering final report...")

    # Find the report template
    report_qmd <- system.file("round_2", "tagger_table_report.qmd", package = NULL)

    # Try common locations
    if (!file.exists(report_qmd)) {
      possible_locations <- c(
        "assumption_checking/round_2/tagger_table_report.qmd",
        "c:/repos/grant_2026/assumption_checking/round_2/tagger_table_report.qmd",
        "./assumption_checking/round_2/tagger_table_report.qmd"
      )

      for (loc in possible_locations) {
        if (file.exists(loc)) {
          report_qmd <- loc
          break
        }
      }
    }

    if (!file.exists(report_qmd)) {
      warning("Report template not found. Skipping report rendering.")
    } else {
      # Find the round_2 directory (parent of output_dir)
      round_2_dir <- dirname(output_dir)

      # Build quarto render command to save in round_2 directory (not output subdir)
      quarto_cmd <- paste0(
        "quarto render '", report_qmd, "' ",
        "--output-dir='", round_2_dir, "' "
      )

      if (!is.null(reference_doc) && file.exists(reference_doc)) {
        # Create a temporary copy of the quarto file with updated reference-doc
        temp_qmd <- file.path(round_2_dir, "tagger_table_report_temp.qmd")
        file.copy(report_qmd, temp_qmd, overwrite = TRUE)

        # Update the reference-doc in the YAML
        qmd_content <- readLines(temp_qmd)
        qmd_content <- gsub(
          'reference-doc:.*',
          paste0('reference-doc: "', reference_doc, '"'),
          qmd_content
        )
        writeLines(qmd_content, temp_qmd)

        quarto_cmd <- paste0("quarto render '", temp_qmd, "' ", "--output-dir='", round_2_dir, "' ")
      }

      tryCatch(
        system(quarto_cmd, show.output.on.console = TRUE),
        error = function(e) {
          warning("Report rendering failed: ", e$message)
        }
      )

      report_path <- file.path(round_2_dir, "tagger_table_report.docx")
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
    n_excluded = n_excluded,
    n_retained = n_retained,
    output_dir = output_dir,
    report_path = report_path
  ))
}
