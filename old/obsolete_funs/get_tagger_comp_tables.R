#' Get Tagger Comparison Tables for All Location/Species Combinations
#'
#' Convenience function that creates tagger comparison tables for all combinations
#' of release location (RI, PR) and species (Chinook, Steelhead). Loops through
#' each combination and calls `create_survival_comparison_table()`.
#'
#' @param atlas_results List returned from `scrape_atlas_results()`.
#'   Must contain `cjs_survival_long` component.
#' @param include_pooled Logical. If TRUE, includes POOLED tagger data. Default: FALSE
#' @param include_se Logical. If TRUE (default), includes standard error columns.
#' @param quiet Logical. If TRUE, suppress progress messages. Default: FALSE.
#'
#' @return List with four named elements corresponding to all location/species
#'   combinations:
#'   - `$RI_Chinook` - Rock Island Chinook (6 reaches)
#'   - `$RI_Steelhead` - Rock Island Steelhead (6 reaches)
#'   - `$PR_Chinook` - Priest Rapids Chinook (1 reach)
#'   - `$PR_Steelhead` - Priest Rapids Steelhead (1 reach)
#'
#'   Each element is a data frame with reaches as rows and tagger columns
#'   (estimate and SE pairs) as columns.
#'
#' @details
#' This function automatically discovers all unique location/species combinations
#' in the provided atlas_results and creates a comparison table for each.
#' Results are organized in a named list for easy access.
#'
#' The function is equivalent to calling:
#' ```r
#' create_survival_comparison_table(atlas_results, "RI", "Chinook")
#' create_survival_comparison_table(atlas_results, "RI", "Steelhead")
#' create_survival_comparison_table(atlas_results, "PR", "Chinook")
#' create_survival_comparison_table(atlas_results, "PR", "Steelhead")
#' ```
#'
#' @export
#' @examples
#' \dontrun{
#' # Get ATLAS results
#' atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")
#'
#' # Create all four comparison tables at once
#' tables <- get_tagger_comp_tables(atlas_results)
#'
#' # Access individual tables
#' print(tables$RI_Chinook)
#' print(tables$PR_Steelhead)
#'
#' # Combine into single markdown document
#' for (name in names(tables)) {
#'   cat(sprintf("\n## %s\n\n", name))
#'   cat(format_survival_table_markdown(tables[[name]]))
#' }
#' }

get_tagger_comp_tables <- function(
    atlas_results,
    include_pooled = FALSE,
    include_se = TRUE,
    quiet = FALSE) {

  library(dplyr, quietly = TRUE)

  # Validate input
  if (!is.list(atlas_results)) {
    stop("atlas_results must be a list returned from scrape_atlas_results()")
  }

  if (is.null(atlas_results$cjs_survival_long)) {
    stop("atlas_results must contain cjs_survival_long component")
  }

  # Source the comparison table function if not already loaded
  if (!exists("create_survival_comparison_table")) {
    source("R/create_survival_comparison_table.R")
  }

  # Get all unique location/species combinations
  combos <- atlas_results$cjs_survival_long |>
    distinct(location, species) |>
    arrange(location, species)

  if (!quiet) {
    cat("Creating tagger comparison tables for", nrow(combos), "combinations...\n\n")
  }

  # Initialize result list
  result_list <- list()

  # Loop through each location/species combination
  for (i in 1:nrow(combos)) {
    location <- combos$location[i]
    species <- combos$species[i]

    # Create list element name
    loc_name <- location  # Already "RI" or "PR"
    spec_name <- species   # Already "Chinook" or "Steelhead"
    list_name <- paste0(loc_name, "_", spec_name)

    # Create the comparison table
    tryCatch({
      table <- create_survival_comparison_table(
        atlas_results = atlas_results,
        location = location,
        species = species,
        include_pooled = include_pooled,
        include_se = include_se
      )

      result_list[[list_name]] <- table

      if (!quiet) {
        cat(sprintf("  ✓ %s - %d reach(es) × %d tagger(s)\n",
                    list_name, nrow(table), (ncol(table) - 1) / 2))
      }
    }, error = function(e) {
      warning(sprintf("Error creating table for %s: %s", list_name, e$message))
    })
  }

  if (!quiet) {
    cat("\n✓ Created", length(result_list), "comparison tables\n\n")
  }

  # Return results invisibly by default, or visibly if requested
  return(result_list)
}
