#' Create Wide-Format Cumulative Survival Comparison Table by Location and Tagger
#'
#' Converts the cumulative CJS survival estimates from `scrape_atlas_results()`
#' into a wide-format table with downstream locations as rows and tagger-specific estimates
#' (estimate and standard error) as columns. Useful for comparing tagger effects
#' in cumulative survival from release to each downstream location.
#'
#' @param atlas_results List returned from `scrape_atlas_results()`
#' @param location Character string. Location to filter (e.g., "RI" or "PR")
#' @param species Character string. Species to filter (e.g., "Chinook" or "Steelhead")
#' @param include_pooled Logical. If TRUE, includes POOLED tagger data. Default: FALSE
#' @param include_se Logical. If TRUE (default), includes standard error columns
#'
#' @return Data frame with columns:
#'   - reach: The downstream location name
#'   - [TAGGER]_est: Cumulative survival estimate for each tagger
#'   - [TAGGER]_se: Standard error for each tagger (if include_se = TRUE)
#'
#' @details
#' Creates a compact table comparing cumulative survival estimates across taggers for a specific
#' location/species combination. One row per downstream location, columns for each tagger's
#' estimate and optionally standard error. Cumulative survival represents the probability of
#' surviving from release to each downstream location.
#'
#' Example output for RI Chinook:
#' ```
#' reach                      | POOLED_est | POOLED_se | TAGGER A_est | TAGGER A_se | ...
#' Release to Crescent Bar    | 0.9916     | 0.002956  | 0.9878       | 0.006042    | ...
#' Release to Sunland         | 0.9780     | 0.004755  | 0.9696       | 0.009465    | ...
#' ```
#'
#' @keywords assumption_check
#' @export
#' @examples
#' \dontrun{
#' atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")
#' 
#' # Create table for Rock Island Chinook cumulative survival
#' ri_chn_cumul_table <- create_cumul_survival_comparison_table(
#'   atlas_results,
#'   location = "RI",
#'   species = "Chinook"
#' )
#' print(ri_chn_cumul_table)
#' }

create_cumul_survival_comparison_table <- function(
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
  
  if (is.null(atlas_results$cumul_cjs_survival)) {
    stop("atlas_results must contain cumul_cjs_survival component")
  }
  
  # Get the cumulative survival data
  data <- atlas_results$cumul_cjs_survival
  
  # Filter by location and species
  filtered_data <- data |>
    filter(
      location == {{ location }},
      species == {{ species }}
    )
  
  if (nrow(filtered_data) == 0) {
    stop(sprintf("No cumulative survival data found for location='%s', species='%s'", location, species))
  }
  
  # Convert from wide to long format for processing
  # First pivot longer to get reach columns
  long_data <- filtered_data |>
    select(tagger, location, location_code, species, ends_with("_est"), ends_with("_se")) |>
    pivot_longer(
      cols = -c(tagger, location, location_code, species),
      names_to = "reach_col",
      values_to = "value"
    ) |>
    mutate(
      reach_key = sub("_(est|se)$", "", reach_col),
      estimate_type = sub("^.*_", "", reach_col)
    ) |>
    select(-reach_col) |>
    pivot_wider(
      names_from = estimate_type,
      values_from = value
    ) |>
    rename(reach = reach_key, estimate = est, se = se) |>
    filter(!is.na(estimate))
  
  # Optionally filter out POOLED
  if (!include_pooled) {
    long_data <- long_data |>
      filter(tagger != "POOLED")
  }
  
  # Create pivot table: downstream locations as rows, taggers as columns
  if (include_se) {
    # Include both estimate and SE columns
    # First pivot estimates
    est_wide <- long_data |>
      mutate(est_col = paste0(tagger, "_est")) |>
      select(reach, est_col, estimate) |>
      distinct() |>
      pivot_wider(
        names_from = est_col,
        values_from = estimate,
        values_fill = NA
      )
    
    # Then pivot SEs
    se_wide <- long_data |>
      mutate(se_col = paste0(tagger, "_se")) |>
      select(reach, se_col, se) |>
      distinct() |>
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
    result <- long_data |>
      mutate(col_name = paste0(tagger, "_est")) |>
      select(reach, col_name, estimate) |>
      distinct() |>
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
  taggers_in_data <- unique(long_data$tagger)
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
  
  # Order rows by reach (cumulative survival order: closer to farther downstream)
  reach_order <- c(
    "Release to Crescent Bar",
    "Release to Sunland",
    "Release to Wanapum BRZ",
    "Release to Mattawa",
    "Release to Priest BRZ",
    "Release to Lower Ringold"
  )
  
  reaches_in_data <- unique(result$reach)
  reaches_ordered <- intersect(reach_order, reaches_in_data)
  
  # Reorder result by reach
  result$reach <- factor(result$reach, levels = reaches_ordered)
  result <- result |> arrange(reach)
  result$reach <- as.character(result$reach)
  
  # Compute F-tests for homogeneous cumulative survival across taggers for each downstream location
  f_test_results <- compute_f_tests_by_reach_cumul(long_data)
  
  # Join F-test results to the main table
  result <- result |>
    left_join(f_test_results, by = "reach")
  
  return(result)
}


#' Compute F-tests for Homogeneous Cumulative Survival Across Taggers
#'
#' For each downstream location, computes the F-statistic and p-value testing whether
#' cumulative survival estimates are homogeneous across taggers.
#'
#' @param long_data Data frame with columns: reach, tagger, estimate, se
#'
#' @return Data frame with columns: reach, F_statistic, p_value
#'
#' @details
#' The test follows this formula:
#'   F = [sum((S_i - mean(S))^2) / (k-1)] / [mean(Var(S_i))]
#' 
#' where:
#'   - S_i are cumulative survival estimates
#'   - k is the number of taggers
#'   - Var(S_i) = se_i^2 (sampling variance)
#'
#' @keywords assumption_check
#' @keywords internal

compute_f_tests_by_reach_cumul <- function(long_data) {
  
  library(dplyr, quietly = TRUE)
  
  # Get unique reaches and exclude POOLED from tagger groups
  reaches <- unique(long_data$reach)
  
  results_list <- list()
  
  for (reach in reaches) {
    reach_data <- long_data |>
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


#' Create All Cumulative Survival Comparison Tables for a Dataset
#'
#' Convenience function that creates cumulative survival comparison tables for all 
#' location/species combinations in a scrape_atlas_results() output.
#'
#' @param atlas_results List returned from `scrape_atlas_results()`
#' @param include_pooled Logical. If TRUE, includes POOLED tagger data. Default: FALSE
#' @param include_se Logical. If TRUE (default), includes standard error columns
#'
#' @return List of data frames, one per location/species combination
#'   - `$RI_Chinook`: Rock Island Chinook cumulative survival
#'   - `$RI_Steelhead`: Rock Island Steelhead cumulative survival
#'   - `$PR_Chinook`: Priest Rapids Chinook cumulative survival (if available)
#'   - `$PR_Steelhead`: Priest Rapids Steelhead cumulative survival (if available)
#'
#' @keywords assumption_check
#' @export
#' @examples
#' \dontrun{
#' atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")
#' 
#' # Create all cumulative survival comparison tables (without POOLED)
#' all_cumul_tables <- create_all_cumul_survival_tables(atlas_results)
#' 
#' # Create with POOLED included
#' all_cumul_tables_with_pooled <- create_all_cumul_survival_tables(atlas_results, include_pooled = TRUE)
#' 
#' # Access individual tables
#' print(all_cumul_tables$RI_Chinook)
#' print(all_cumul_tables$RI_Steelhead)
#' }

create_all_cumul_survival_tables <- function(
    atlas_results,
    include_pooled = FALSE,
    include_se = TRUE) {
  
  library(dplyr, quietly = TRUE)
  
  # Get unique location/species combinations from cumulative survival data
  if (is.null(atlas_results$cumul_cjs_survival) || nrow(atlas_results$cumul_cjs_survival) == 0) {
    warning("No cumulative survival data available")
    return(NULL)
  }
  
  combos <- atlas_results$cumul_cjs_survival |>
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
    table <- create_cumul_survival_comparison_table(
      atlas_results,
      location = loc,
      species = spec,
      include_pooled = include_pooled,
      include_se = include_se
    )
    
    result_list[[list_name]] <- table
  }
  
  cat("Created", length(result_list), "cumulative survival comparison tables:\n")
  for (name in names(result_list)) {
    cat(sprintf("  $%s: %d downstream locations\n", name, nrow(result_list[[name]])))
  }
  cat("\n")
  
  return(result_list)
}
