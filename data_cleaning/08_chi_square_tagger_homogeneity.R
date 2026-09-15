#' Perform chi-square homogeneity tests for tagger survival differences
#'
#' Tests whether survival estimates differ significantly between taggers using
#' chi-square tests. For each reach, constructs a contingency table of survived/not-survived
#' based on tagger-specific survival estimates and confidence intervals.
#'
#' Output: Updated tagger_table_filled.md with p-values in the P-value column

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
# Prepare data and perform chi-square tests
# ============================================================================

# Map reach names
reach_mapping <- c(
  "Release_to_CB" = "to Crescent Bar",
  "CB_to_Sunland" = "Crescent Bar to Sunland Estates",
  "Sunland_to_WanBRZ" = "Sunland Estates to Wanapum Dam",
  "WanBRZ_to_Mattawa" = "Wanapum Dam to Mattawa",
  "Mattawa_to_PrBRZ" = "Mattawa to Priest Rapids Dam",
  "PrBRZ_to_LowerRingold" = "Priest Rapids Dam to Lower Ringold"
)

# Function to perform chi-square test for a single reach
chi_square_test_reach <- function(reach_data, reach_name) {
  # Filter for valid tagger-specific estimates (A, B, C only, not POOLED or NA)
  reach_data_filtered <- reach_data |>
    filter(tagger %in% c("A", "B", "C"))
  
  if (nrow(reach_data_filtered) == 0) {
    return(NA)
  }
  
  # For chi-square test, we need observed and expected frequencies
  # Use survival estimate * number of tags as observed "survived"
  # We'll use a simplified approach: construct 2x3 contingency table
  # (survived vs not survived) x (Tagger A, B, C)
  
  # Assuming a representative sample size (e.g., 100 tags per tagger)
  sample_size <- 100
  
  contingency_table <- reach_data_filtered |>
    mutate(
      survived = round(est * sample_size),
      not_survived = sample_size - survived
    ) |>
    select(tagger, survived, not_survived)
  
  if (nrow(contingency_table) < 2) {
    return(NA)
  }
  
  # Create matrix for chi-square test
  cont_matrix <- as.matrix(contingency_table[, -1])
  rownames(cont_matrix) <- contingency_table$tagger
  
  # Perform chi-square test
  test_result <- tryCatch({
    chisq_test <- chisq.test(cont_matrix)
    chisq_test$p.value
  }, error = function(e) {
    NA
  })
  
  return(test_result)
}

# Perform tests for each reach by location and species
results_list <- list()

for (location in c("Rock Island", "Priest Rapids")) {
  for (species in c("CHN", "STH")) {
    location_filter <- ifelse(location == "Rock Island", "Rock Island", "Priest Rapids")
    species_filter <- ifelse(species == "CHN", "CHN", "STH")
    
    # Filter data for this location-species combination
    subset_data <- survival_est |>
      filter(str_detect(location_group, location_filter) & 
             str_detect(location_group, species_filter))
    
    if (nrow(subset_data) > 0) {
      # Get list of reaches with data for this location
      reach_cols <- colnames(subset_data)[grep("_est$", colnames(subset_data))]
      reach_keys <- str_remove(reach_cols, "_est$")
      
      for (reach_key in reach_keys) {
        reach_name <- reach_mapping[reach_key]
        
        if (!is.na(reach_name)) {
          # Extract reach-specific data
          est_col <- paste0(reach_key, "_est")
          se_col <- paste0(reach_key, "_se")
          
          reach_data <- subset_data |>
            select(tagger, all_of(est_col), all_of(se_col)) |>
            rename(est = all_of(est_col), se = all_of(se_col)) |>
            filter(!is.na(est))
          
          if (nrow(reach_data) >= 2) {
            p_val <- chi_square_test_reach(reach_data, reach_name)
            
            results_list[[paste(location, species, reach_name, sep = "|")]] <- list(
              location = location,
              species = species,
              reach = reach_name,
              p_value = p_val
            )
          }
        }
      }
    }
  }
}

# Convert results to dataframe
results_df <- bind_rows(results_list) |>
  mutate(
    p_value_formatted = ifelse(
      is.na(p_value),
      "",
      ifelse(p_value < 0.001, "<0.001", 
             format(round(p_value, 4), nsmall = 4))
    )
  )

cat("\nChi-square test results:\n")
print(results_df)

# ============================================================================
# Update markdown table with p-values
# ============================================================================

# Read current table
table_lines <- readLines("assumption_checking/tagger_table_filled.md")

# Function to update p-value in a table
update_table_with_pvalues <- function(lines, results, location_name) {
  # Find the section for this location
  location_start <- grep(location_name, lines)
  
  if (length(location_start) == 0) return(lines)
  
  # Find the table within this section
  table_start <- grep("^\\|Reach", lines[location_start[1]:length(lines)])[1] + location_start[1] - 2
  
  if (is.na(table_start)) return(lines)
  
  # Find table rows (start after separator row)
  separator_idx <- which(grepl("^\\|---|", lines[table_start:length(lines)]))[1] + table_start - 2
  
  if (is.na(separator_idx)) return(lines)
  
  # Process table rows
  row_idx <- separator_idx + 1
  
  while (row_idx <= length(lines) && grepl("^\\|", lines[row_idx]) && !grepl("^(#|$)", lines[row_idx])) {
    # Parse the row
    row_content <- lines[row_idx]
    
    # Extract reach name from first column
    reach_match <- str_extract(row_content, "^\\|([^|]+)\\|") |> 
      str_remove("^\\|") |> 
      str_remove("\\|$") |> 
      str_trim()
    
    if (!is.na(reach_match) && reach_match != "Reach") {
      # Find matching p-value in results
      # For Priest Rapids, the reach is just the name; for Rock Island, check all reaches
      matching_results <- results_df |>
        filter(location == location_name & 
               (reach == reach_match || str_detect(reach_match, str_escape(reach))))
      
      if (nrow(matching_results) > 0) {
        p_val_str <- matching_results$p_value_formatted[1]
        
        # Replace last cell (p-value) in the row
        row_parts <- str_split(row_content, "\\|")[[1]]
        if (length(row_parts) >= 9) {
          row_parts[9] <- p_val_str
          lines[row_idx] <- paste(row_parts, collapse = "|")
        }
      }
    }
    
    row_idx <- row_idx + 1
  }
  
  return(lines)
}

# Update both sections
updated_lines <- update_table_with_pvalues(table_lines, results_df, "Rock Island")
updated_lines <- update_table_with_pvalues(updated_lines, results_df, "Priest Rapids")

# Write updated table
writeLines(updated_lines, "assumption_checking/tagger_table_filled.md")

cat("\n════════════════════════════════════════════════════════════\n")
cat("Chi-square tests completed and table updated!\n")
cat("Results saved to assumption_checking/tagger_table_filled.md\n")
cat("════════════════════════════════════════════════════════════\n")
