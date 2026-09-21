#' Create Wide-Format Survival Comparison Table by Reach and Tagger
#'
#' Converts the long-format CJS survival estimates from `scrape_atlas_results()`
#' into a wide-format table with reaches as rows and tagger-specific estimates
#' (estimate and standard error) as columns. Useful for comparing tagger effects
#' across reaches within a single location/species combination.
#'
#' @param atlas_results List returned from `scrape_atlas_results()`
#' @param location Character string. Location to filter (e.g., "RI" or "PR")
#' @param species Character string. Species to filter (e.g., "Chinook" or "Steelhead")
#' @param include_pooled Logical. If TRUE, includes POOLED tagger data. Default: FALSE
#' @param include_se Logical. If TRUE (default), includes standard error columns
#'
#' @return Data frame with columns:
#'   - reach: The reach name
#'   - [TAGGER]_est: Survival estimate for each tagger
#'   - [TAGGER]_se: Standard error for each tagger (if include_se = TRUE)
#'
#' @details
#' Creates a compact table comparing survival estimates across taggers for a specific
#' location/species combination. One row per reach, columns for each tagger's
#' estimate and optionally standard error.
#'
#' Example output for RI Chinook:
#' ```
#' reach                    | POOLED_est | POOLED_se | TAGGER A_est | TAGGER A_se | ...
#' Release to Crescent Bar  | 0.9915     | 0.003193  | 0.9849       | 0.006684    | ...
#' ```
#'
#' @keywords assumption_check
#' @export
#' @examples
#' \dontrun{
#' atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")
#' 
#' # Create table for Rock Island Chinook
#' ri_chn_table <- create_survival_comparison_table(
#'   atlas_results,
#'   location = "RI",
#'   species = "Chinook"
#' )
#' print(ri_chn_table)
#' }

create_survival_comparison_table <- function(
    atlas_results,
    location,
    species,
    include_pooled = FALSE,
    include_se = TRUE) {
  
  library(dplyr, quietly = TRUE)
  library(tidyr, quietly = TRUE)
  
  # Validate inputs
  if (!is.list(atlas_results)) {
    stop("atlas_results must be a list returned from scrape_atlas_results()")
  }
  
  if (is.null(atlas_results$cjs_survival_long)) {
    stop("atlas_results must contain cjs_survival_long component")
  }
  
  # Get the long-format data
  data <- atlas_results$cjs_survival_long
  
  # Filter by location and species
  filtered_data <- data |>
    filter(
      location == {{ location }},
      species == {{ species }}
    )
  
  if (nrow(filtered_data) == 0) {
    stop(sprintf("No data found for location='%s', species='%s'", location, species))
  }
  
  # Optionally filter out POOLED
  if (!include_pooled) {
    filtered_data <- filtered_data |>
      filter(tagger != "POOLED")
  }
  
  # Create pivot table: reaches as rows, taggers as columns
  if (include_se) {
    # Include both estimate and SE columns
    # First pivot estimates
    est_wide <- filtered_data |>
      mutate(est_col = paste0(tagger, "_est")) |>
      select(reach, est_col, estimate) |>
      distinct() |>  # Remove duplicates if any
      pivot_wider(
        names_from = est_col,
        values_from = estimate,
        values_fill = NA
      )
    
    # Then pivot SEs
    se_wide <- filtered_data |>
      mutate(se_col = paste0(tagger, "_se")) |>
      select(reach, se_col, se) |>
      distinct() |>  # Remove duplicates if any
      pivot_wider(
        names_from = se_col,
        values_from = se,
        values_fill = NA
      )
    
    # Combine and interleave columns (est, se, est, se, etc.)
    result <- est_wide |>
      left_join(se_wide, by = "reach")
  } else {
    # Include only estimates
    result <- filtered_data |>
      mutate(col_name = paste0(tagger, "_est")) |>
      select(reach, col_name, estimate) |>
      distinct() |>  # Remove duplicates if any
      pivot_wider(
        names_from = col_name,
        values_from = estimate,
        values_fill = NA
      )
  }
  
  # Order columns: reach first, then taggers in logical order
  col_order <- c("reach")
  
  # Determine tagger order
  tagger_order <- c("POOLED", "TAGGER A", "TAGGER B", "TAGGER C")
  taggers_in_data <- unique(filtered_data$tagger)
  taggers_ordered <- intersect(tagger_order, taggers_in_data)
  
  # Build column order
  for (tagger in taggers_ordered) {
    col_order <- c(col_order, paste0(tagger, "_est"))
    if (include_se) {
      col_order <- c(col_order, paste0(tagger, "_se"))
    }
  }
  
  # Select and reorder columns
  available_cols <- col_order[col_order %in% names(result)]
  result <- result |>
    select(all_of(available_cols))
  
  # Order rows by reach (in logical order if possible)
  reach_order <- c(
    "Release to Lower Ringold",
    "Release to Crescent Bar",
    "Crescent Bar to Sunland",
    "Sunland to Wanapum BRZ",
    "Wanapum BRZ to Mattawa",
    "Mattawa to Priest BRZ",
    "Priest BRZ to Lower Ringold"
  )
  
  reaches_in_data <- unique(result$reach)
  reaches_ordered <- intersect(reach_order, reaches_in_data)
  
  # Reorder result by reach
  result$reach <- factor(result$reach, levels = reaches_ordered)
  result <- result |> arrange(reach)
  result$reach <- as.character(result$reach)
  
  # Compute F-tests for homogeneous survival across taggers for each reach
  f_test_results <- compute_f_tests_by_reach(filtered_data)
  
  # Join F-test results to the main table
  result <- result |>
    left_join(f_test_results, by = "reach")
  
  return(result)
}


#' Compute F-tests for Homogeneous Survival Across Taggers
#'
#' For each reach, computes the F-statistic and p-value testing whether
#' survival estimates are homogeneous across taggers, following the
#' based on  "Test of Tagger Effects" table 3.2.
#'
#' @param filtered_data Data frame with columns: reach, tagger, estimate, se
#'
#' @return Data frame with columns: reach, F_statistic, p_value
#'
#' @details
#' The test follows this formula:
#'   F = [sum((S_i - mean(S))^2) / (k-1)] / [mean(Var(S_i))]
#' 
#' where:
#'   - S_i are survival estimates
#'   - k is the number of taggers
#'   - Var(S_i) = se_i^2 (sampling variance)
#'
#' @keywords assumption_check
#' @keywords internal

compute_f_tests_by_reach <- function(filtered_data) {
  
  library(dplyr, quietly = TRUE)
  
  # Get unique reaches and exclude POOLED from tagger groups
  reaches <- unique(filtered_data$reach)
  
  results_list <- list()
  
  for (reach in reaches) {
    reach_data <- filtered_data |>
      filter(reach == !!reach, tagger != "POOLED")
    
    if (nrow(reach_data) < 2) {
      # Cannot test homogeneity with fewer than 2 groups
      results_list[[reach]] <- tibble(
        reach = reach,
        F_statistic = NA_real_,
        p_value = NA_real_
      )
      next
    }
    
    estimates <- reach_data$estimate
    variances <- reach_data$se^2  # sampling variance = se^2
    k <- length(estimates)
    mean_estimate <- mean(estimates)
    
    # Calculate numerator: variance of estimates
    numerator <- sum((estimates - mean_estimate)^2) / (k - 1)
    
    # Calculate denominator: mean of sampling variances
    denominator <- mean(variances)
    
    if (denominator == 0 || is.na(denominator)) {
      results_list[[reach]] <- tibble(
        reach = reach,
        F_statistic = NA_real_,
        p_value = NA_real_
      )
      next
    }
    
    # F-statistic with degrees of freedom: (k-1, infinity)
    # When df2 = Inf, use normal approximation
    f_stat <- numerator / denominator
    
    # p-value: upper tail of F distribution
    # With df2 = Inf, this approaches chi-square / (k-1) distribution
    p_val <- pf(f_stat, df1 = k - 1, df2 = Inf, lower.tail = FALSE)
    
    results_list[[reach]] <- tibble(
      reach = reach,
      F_statistic = f_stat,
      p_value = p_val
    )
  }
  
  results_df <- bind_rows(results_list)
  return(results_df)
}


#' Create All Survival Comparison Tables for a Dataset
#'
#' Convenience function that creates comparison tables for all location/species
#' combinations in a scrape_atlas_results() output.
#'
#' @param atlas_results List returned from `scrape_atlas_results()`
#' @param include_pooled Logical. If TRUE, includes POOLED tagger data. Default: FALSE
#' @param include_se Logical. If TRUE (default), includes standard error columns
#'
#' @return List of data frames, one per location/species combination
#'   - `$RI_Chinook`: Rock Island Chinook
#'   - `$RI_Steelhead`: Rock Island Steelhead
#'   - `$PR_Chinook`: Priest Rapids Chinook
#'   - `$PR_Steelhead`: Priest Rapids Steelhead
#'
#' @keywords assumption_check
#' @export
#' @examples
#' \dontrun{
#' atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")
#' 
#' # Create all comparison tables (without POOLED)
#' all_tables <- create_all_survival_tables(atlas_results)
#' 
#' # Create with POOLED included
#' all_tables_with_pooled <- create_all_survival_tables(atlas_results, include_pooled = TRUE)
#' 
#' # Access individual tables
#' print(all_tables$RI_Chinook)
#' print(all_tables$PR_Steelhead)
#' }

create_all_survival_tables <- function(
    atlas_results,
    include_pooled = FALSE,
    include_se = TRUE) {
  
  library(dplyr, quietly = TRUE)
  
  # Get unique location/species combinations
  combos <- atlas_results$cjs_survival_long |>
    distinct(location, species) |>
    arrange(location, species)
  
  # Create list to store results
  result_list <- list()
  
  # Create a table for each combination
  for (i in 1:nrow(combos)) {
    loc <- combos$location[i]
    spec <- combos$species[i]
    
    # Create friendly name for list element
    loc_name <- ifelse(loc == "RI", "RI", "PR")
    spec_name <- ifelse(spec == "Chinook", "Chinook", "Steelhead")
    list_name <- paste0(loc_name, "_", spec_name)
    
    # Create the table
    table <- create_survival_comparison_table(
      atlas_results,
      location = loc,
      species = spec,
      include_pooled = include_pooled,
      include_se = include_se
    )
    
    result_list[[list_name]] <- table
  }
  
  cat("Created", length(result_list), "survival comparison tables:\n")
  for (name in names(result_list)) {
    cat(sprintf("  $%s: %d reaches\n", name, nrow(result_list[[name]])))
  }
  cat("\n")
  
  return(result_list)
}


#' Create All Survival Comparison Tables with Formatted Display
#'
#' Convenience function that creates all comparison tables and returns them
#' in a formatted display-ready format with rounded numeric values.
#'
#' @param atlas_results List returned from `scrape_atlas_results()`
#' @param include_pooled Logical. If TRUE, includes POOLED tagger data. Default: FALSE
#' @param include_se Logical. If TRUE (default), includes standard error columns
#' @param survival_digits Integer. Decimal places for survival estimates (default: 4)
#' @param se_digits Integer. Decimal places for standard errors (default: 4)
#' @param fstat_digits Integer. Decimal places for F-statistics (default: 3)
#' @param pval_digits Integer. Decimal places for p-values (default: 4)
#'
#' @return List of formatted data frames, one per location/species combination
#'
#' @keywords assumption_check
#' @export
#' @examples
#' \dontrun{
#' atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")
#' all_tables <- create_all_survival_tables_formatted(atlas_results)
#' all_tables$RI_Chinook
#' }

create_all_survival_tables_formatted <- function(
    atlas_results,
    include_pooled = FALSE,
    include_se = TRUE,
    survival_digits = 4,
    se_digits = 4,
    fstat_digits = 3,
    pval_digits = 4) {
  
  library(dplyr, quietly = TRUE)
  
  # Create unformatted tables
  tables <- create_all_survival_tables(
    atlas_results,
    include_pooled = include_pooled,
    include_se = include_se
  )
  
  # Format each table
  formatted_tables <- lapply(tables, function(tbl) {
    format_survival_table_display(
      tbl,
      survival_digits = survival_digits,
      se_digits = se_digits,
      fstat_digits = fstat_digits,
      pval_digits = pval_digits
    )
  })
  
  return(formatted_tables)
}


#' Format Survival Comparison Table as Markdown
#'
#' Converts a survival comparison table to markdown format for inclusion in
#' Quarto documents or reports.
#'
#' @param survival_table Data frame from `create_survival_comparison_table()`
#' @param caption Optional character string. Table caption.
#'
#' @return Character string with markdown-formatted table
#'
#' @keywords assumption_check
#' @export
#' @examples
#' \dontrun{
#' atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")
#' 
#' table <- create_survival_comparison_table(atlas_results, "RI", "Chinook")
#' markdown <- format_survival_table_markdown(table, caption = "RI Chinook Survival")
#' cat(markdown)
#' }

format_survival_table_markdown <- function(survival_table, caption = NULL) {
  
  # Use knitr::kable for nice markdown formatting
  markdown <- knitr::kable(survival_table, format = "markdown")
  
  # Add caption if provided
  if (!is.null(caption)) {
    markdown <- paste0("\n**", caption, "**\n\n", markdown)
  }
  
  return(markdown)
}


#' Format Survival Comparison Table for Display
#'
#' Formats a survival comparison table with F-test results for clean display,
#' rounding numeric values appropriately.
#'
#' @param survival_table Data frame from `create_survival_comparison_table()`
#' @param survival_digits Integer. Decimal places for survival estimates (default: 4)
#' @param se_digits Integer. Decimal places for standard errors (default: 4)
#' @param fstat_digits Integer. Decimal places for F-statistics (default: 3)
#' @param pval_digits Integer. Decimal places for p-values (default: 4)
#'
#' @return Data frame with formatted numeric values
#'
#' @keywords assumption_check
#' @export
#' @examples
#' \dontrun{
#' atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")
#' table <- create_survival_comparison_table(atlas_results, "RI", "Chinook")
#' formatted <- format_survival_table_display(table)
#' print(formatted)
#' }

format_survival_table_display <- function(
    survival_table,
    survival_digits = 4,
    se_digits = 4,
    fstat_digits = 3,
    pval_digits = 4) {
  
  library(dplyr, quietly = TRUE)
  
  result <- survival_table
  
  # Round survival estimates (columns ending in _est)
  est_cols <- names(result)[grepl("_est$", names(result))]
  for (col in est_cols) {
    result[[col]] <- round(result[[col]], survival_digits)
  }
  
  # Round standard errors (columns ending in _se)
  se_cols <- names(result)[grepl("_se$", names(result))]
  for (col in se_cols) {
    result[[col]] <- round(result[[col]], se_digits)
  }
  
  # Round F-statistic and p-value
  if ("F_statistic" %in% names(result)) {
    result$F_statistic <- round(result$F_statistic, fstat_digits)
  }
  
  if ("p_value" %in% names(result)) {
    result$p_value <- round(result$p_value, pval_digits)
  }
  
  return(result)
}
