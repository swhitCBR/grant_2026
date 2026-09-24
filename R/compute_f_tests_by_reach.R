
#' Compute F-tests for Homogeneous Survival Across Taggers
#'
#' For each reach, computes the F-statistic and p-value testing whether
#' survival estimates are homogeneous across taggers, following the
#' based on  "Test of Tagger Effects" table 3.2.
#'
#' @param filtered_data Data frame with columns: reach, tagger, estimate, se
#' @param est_digits Integer or NULL (default). If an integer is provided,
#'   rounds estimates and standard errors to the specified number of decimal
#'   places before computing F-statistics and p-values. If NULL, uses unrounded values.
#' @param verbose Logical (default FALSE). If TRUE, includes additional columns
#'   in the output: numerator, denominator, df (degrees of freedom), and the estimates
#'   and standard errors. If est_digits is provided, estimates and SEs are shown in
#'   quotes to indicate they were rounded.
#'
#' @return Data frame with columns: reach, F_statistic, p_value. If verbose = TRUE,
#'   also includes numerator, denominator, df, and columns showing tagger-specific
#'   estimates and SEs (as character strings if rounded).
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

compute_f_tests_by_reach <- function(filtered_data, est_digits = NULL, verbose = FALSE) {
  
  library(dplyr, quietly = TRUE)
  
  # Apply rounding to estimates and SEs if est_digits is provided
  if (!is.null(est_digits)) {
    filtered_data <- filtered_data |>
      mutate(
        estimate = round(estimate, digits = est_digits),
        se = round(se, digits = est_digits)
      )
  }
  
  # Get unique reaches and exclude POOLED from tagger groups
  reaches <- unique(filtered_data$reach)
  
  results_list <- list()
  
  for (reach in reaches) {
    reach_data <- filtered_data |>
      filter(reach == !!reach, tagger != "POOLED")
    
    if (nrow(reach_data) < 2) {
      # Cannot test homogeneity with fewer than 2 groups
      if (verbose) {
        results_list[[reach]] <- tibble(
          reach = reach,
          numerator = NA_real_,
          denominator = NA_real_,
          df = NA_integer_,
          F_statistic = NA_real_,
          p_value = NA_real_
        )
      } else {
        results_list[[reach]] <- tibble(
          reach = reach,
          F_statistic = NA_real_,
          p_value = NA_real_
        )
      }
      next
    }
    
    estimates <- reach_data$estimate
    variances <- reach_data$se^2  # sampling variance = se^2
    ses <- reach_data$se
    taggers <- reach_data$tagger
    k <- length(estimates)
    mean_estimate <- mean(estimates)
    
    # Calculate numerator: variance of estimates
    numerator <- sum((estimates - mean_estimate)^2) / (k - 1)
    
    # Calculate denominator: mean of sampling variances
    denominator <- mean(variances)
    
    # Degrees of freedom for the F-statistic
    df <- k - 1
    
    # F-statistic with degrees of freedom: (k-1, infinity)
    # When df2 = Inf, use normal approximation
    f_stat <- numerator / denominator
    
    # p-value: upper tail of F distribution
    # With df2 = Inf, this approaches chi-square / (k-1) distribution
    p_val <- pf(f_stat, df1 = k - 1, df2 = Inf, lower.tail = FALSE)
    
    if (verbose) {
      # Build a data frame with tagger estimates and SEs
      tagger_data <- data.frame(
        tagger = taggers,
        estimate = estimates,
        se = ses
      )
      
      # Format estimates and SEs as strings
      # If rounded (est_digits is not NULL), add single quotes
      if (!is.null(est_digits)) {
        tagger_data <- tagger_data |>
          mutate(
            estimate_str = paste0("'", round(estimate, digits = est_digits), "'"),
            se_str = paste0("'", round(se, digits = est_digits), "'")
          )
      } else {
        tagger_data <- tagger_data |>
          mutate(
            estimate_str = as.character(estimate),
            se_str = as.character(se)
          )
      }
      
      # Create columns for each tagger (e.g., TAGGER.A_est, TAGGER.A_se)
      result_row <- tibble(reach = reach)
      
      # Add tagger-specific columns between reach and numerator
      for (i in seq_len(nrow(tagger_data))) {
        tagger_name <- tagger_data$tagger[i]
        # Sanitize tagger name for column naming (replace spaces with dots)
        tagger_col <- gsub(" ", ".", tagger_name)
        
        result_row[[paste0(tagger_col, "_est")]] <- tagger_data$estimate_str[i]
        result_row[[paste0(tagger_col, "_se")]] <- tagger_data$se_str[i]
      }
      
      # Add F-test components after tagger columns
      # Keep numeric values intact (no rounding)
      result_row$numerator <- numerator
      result_row$denominator <- denominator
      result_row$df <- df
      result_row$F_statistic <- f_stat
      result_row$p_value <- p_val
      
      results_list[[reach]] <- result_row
    } else {
      results_list[[reach]] <- tibble(
        reach = reach,
        F_statistic = f_stat,
        p_value = p_val
      )
    }
  }
  
  results_df <- bind_rows(results_list)
  
  # Create a custom class for formatted numeric display
  # Wrap F_statistic and p_value to display with 4 decimal places
  # while preserving underlying numeric values
  if ("F_statistic" %in% names(results_df)) {
    class(results_df$F_statistic) <- c("numeric_4dp", "numeric")
    class(results_df$p_value) <- c("numeric_4dp", "numeric")
  }
  
  return(results_df)
}

# Custom print method for numeric_4dp class
#' @export
format.numeric_4dp <- function(x, ...) {
  sprintf("%.4f", x)
}