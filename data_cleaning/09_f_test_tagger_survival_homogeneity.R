#' F-test for homogeneous survival across taggers
#'
#' Tests whether reach-specific survival estimates differ significantly between
#' taggers using F-tests. For each reach and release location, constructs an
#' F-statistic comparing the variance of tagger-specific estimates to the
#' pooled sampling variance.
#'
#' Methodology from "Test of Tagger Effects" statistical plan:
#' F = (sum of squared deviations from pooled estimate) / (pooled sampling variance)
#'
#' Output: Results table with F-statistics, degrees of freedom, and p-values

if(getwd() != "c:/repos/grant_2026"){
  setwd("c:/repos/grant_2026")}

library(dplyr)
library(tidyr)
library(stringr)

# ============================================================================
# Load survival estimates
# ============================================================================

survival_est <- readRDS("assumption_checking/cjs_survival_estimates.rds")

cat("Loaded survival estimates:\n")
print(head(survival_est))

# ============================================================================
# Prepare data: reshape to long format for F-test calculation
# ============================================================================

# Get only tagger-specific estimates (A, B, C) - exclude POOLED
tagger_survival <- survival_est |>
  filter(tagger %in% c("A", "B", "C")) |>
  select(location_group, tagger, ends_with("_est"), ends_with("_se"))

# Reach columns (exclude POOLED estimates which are single values)
reach_cols <- colnames(survival_est)[grep("_est$", colnames(survival_est))]
reach_keys <- str_remove(reach_cols, "_est$")

# Map reach keys to display names
reach_names <- c(
  "Release_to_CB" = "Release to CB",
  "CB_to_Sunland" = "CB to Sunland",
  "Sunland_to_WanBRZ" = "Sunland to Wanapum BRZ",
  "WanBRZ_to_Mattawa" = "Wanapum BRZ to Mattawa",
  "Mattawa_to_PrBRZ" = "Mattawa to Priest BRZ",
  "PrBRZ_to_LowerRingold" = "Priest BRZ to Lower Ringold",
  "Release_to_LowerRingold" = "Release to Lower Ringold"
)

# ============================================================================
# F-test function
# ============================================================================

f_test_survival <- function(estimates, ses, reach_name) {
  # estimates: vector of 3 survival estimates (A, B, C)
  # ses: vector of 3 standard errors
  # Returns: list with F-stat, df1, df2, p-value
  # 
  # Formula (per "Test of Tagger Effects" methodology):
  # F_{k-1,∞} = [S²_{Ŝᵢ}] / [mean(Var(Ŝᵢ))]
  # where:
  #   S²_{Ŝᵢ} = sample variance of estimates = Σ(Ŝᵢ - Ŝ̄)² / (k-1)
  #   Ŝ̄ = simple (unweighted) mean of estimates
  #   mean(Var(Ŝᵢ)) = average of sampling variances
  # df1 = k - 1 (k = number of taggers = 3, so df1 = 2)
  # df2 = ∞ (use large number like 1000 in computation)
  
  # Remove NAs
  valid_idx <- !is.na(estimates) & !is.na(ses)
  if (sum(valid_idx) < 2) {
    return(list(F_stat = NA, df1 = NA, df2 = NA, p_value = NA, n_taggers = 0))
  }
  
  estimates <- estimates[valid_idx]
  ses <- ses[valid_idx]
  k <- length(estimates)  # number of taggers
  
  # Calculate individual variances
  variances <- ses^2
  
  # Calculate simple (unweighted) mean of estimates
  simple_mean <- mean(estimates)
  
  # Numerator: Sample variance of the k estimates
  # S²_{Ŝᵢ} = Σ(Ŝᵢ - Ŝ̄)² / (k-1)
  sum_sq_deviations <- sum((estimates - simple_mean)^2)
  sample_var <- sum_sq_deviations / (k - 1)
  
  # Denominator: Mean (average) of individual sampling variances
  mean_var <- mean(variances)
  
  # Degrees of freedom
  df1 <- k - 1
  df2 <- Inf  # Formula uses F(k-1, ∞)
  
  if (mean_var == 0 || is.na(mean_var)) {
    return(list(F_stat = NA, df1 = NA, df2 = NA, p_value = NA, n_taggers = k))
  }
  
  # Calculate F-statistic
  F_stat <- sample_var / mean_var
  
  # p-value from F-distribution (use large df2 as approximation for infinity)
  p_value <- 1 - pf(F_stat, df1, 1000)
  
  return(list(
    F_stat = F_stat,
    df1 = df1,
    df2 = df2,
    p_value = p_value,
    n_taggers = k,
    simple_mean = simple_mean
  ))
}

# ============================================================================
# Apply F-tests for each reach and release location
# ============================================================================

results_list <- list()
result_idx <- 1

for (location in unique(survival_est$location_group)) {
  # Extract release location and species from location_group
  release <- ifelse(str_detect(location, "Rock Island"), "Rock Island", "Priest Rapids")
  species <- ifelse(str_detect(location, "CHN"), "Chinook", "Steelhead")
  
  # Get tagger-specific data for this location
  loc_data <- tagger_survival |>
    filter(location_group == location)
  
  if (nrow(loc_data) < 2) next  # Need at least 2 taggers
  
  # Test each reach
  for (reach_key in reach_keys) {
    est_col <- paste0(reach_key, "_est")
    se_col <- paste0(reach_key, "_se")
    
    # Get estimates and SEs for this reach
    if (!(est_col %in% colnames(loc_data))) next
    
    estimates <- loc_data[[est_col]]
    ses <- loc_data[[se_col]]
    
    # Skip if all NA
    if (all(is.na(estimates))) next
    
    # Perform F-test
    test_result <- f_test_survival(estimates, ses, reach_key)
    
    results_list[[result_idx]] <- list(
      location_group = location,
      release = release,
      species = species,
      reach_key = reach_key,
      reach_name = reach_names[reach_key],
      F_stat = test_result$F_stat,
      df1 = test_result$df1,
      df2 = test_result$df2,
      p_value = test_result$p_value,
      n_taggers = test_result$n_taggers,
      pooled_estimate = test_result$pooled_est
    )
    
    result_idx <- result_idx + 1
  }
}

# Convert to dataframe
results_df <- bind_rows(results_list) |>
  mutate(
    p_value_formatted = case_when(
      is.na(p_value) ~ "",
      p_value < 0.001 ~ "<0.001",
      TRUE ~ format(round(p_value, 4), nsmall = 4)
    ),
    F_stat_formatted = case_when(
      is.na(F_stat) ~ "",
      TRUE ~ format(round(F_stat, 2), nsmall = 2)
    ),
    significant = if_else(p_value < 0.05 & !is.na(p_value), "✓", "")
  ) |>
  arrange(release, species, reach_name)

cat("\n════════════════════════════════════════════════════════════\n")
cat("F-TEST RESULTS FOR TAGGER SURVIVAL HOMOGENEITY\n")
cat("════════════════════════════════════════════════════════════\n\n")

# Display summary
results_summary <- results_df |>
  select(release, species, reach_name, n_taggers, F_stat_formatted, 
         df1, df2, p_value_formatted, significant) |>
  arrange(release, species, reach_name)

print(results_summary)

cat("\n\nDetailed Results:\n")
print(results_df)

# ============================================================================
# Summary statistics
# ============================================================================

cat("\n════════════════════════════════════════════════════════════\n")
cat("SUMMARY\n")
cat("════════════════════════════════════════════════════════════\n\n")

cat("Total tests performed:", nrow(results_df), "\n")
cat("Significant at α=0.05:", sum(results_df$p_value < 0.05, na.rm = TRUE), "\n")
cat("Not significant:", sum(results_df$p_value >= 0.05, na.rm = TRUE), "\n\n")

cat("Significant differences (p < 0.05) by Release Location:\n")
significant_results <- results_df |>
  filter(p_value < 0.05) |>
  select(release, species, reach_name, F_stat_formatted, p_value_formatted)

if (nrow(significant_results) > 0) {
  print(significant_results)
} else {
  cat("  (None)\n")
}

cat("\n════════════════════════════════════════════════════════════\n")
cat("F-test calculations complete!\n")
cat("════════════════════════════════════════════════════════════\n")
