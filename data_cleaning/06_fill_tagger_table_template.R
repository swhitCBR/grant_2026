#' Fill tagger table template with scraped survival estimates
#'
#' Reads the scraped CJS survival estimates and fills the template markdown table
#' with wide-format data organized by tagger, reach, and location (Rock Island and Priest Rapids).
#'
#' Output: tagger_table_filled.md in assumption_checking/

if(getwd() != "c:/repos/grant_2026"){
  setwd("c:/repos/grant_2026")}

library(dplyr)
library(tidyr)
library(stringr)

# ============================================================================
# Load scraped survival estimates
# ============================================================================

survival_est <- readRDS("assumption_checking/cjs_survival_estimates.rds")

cat("Loaded survival estimates:\n")
print(head(survival_est))
cat("\nUnique datasets:", unique(survival_est$dataset), "\n")
cat("Unique taggers:", unique(survival_est$tagger), "\n")
cat("Unique locations:", unique(survival_est$location_group), "\n\n")

# ============================================================================
# Reshape data to wide format
# ============================================================================

# Map reach names from template to column names
reach_mapping <- c(
  "Release_to_CB" = "to Crescent Bar",
  "CB_to_Sunland" = "Crescent Bar to Sunland Estates",
  "Sunland_to_WanBRZ" = "Sunland Estates to Wanapum Dam",
  "WanBRZ_to_Mattawa" = "Wanapum Dam to Mattawa",
  "Mattawa_to_PrBRZ" = "Mattawa to Priest Rapids Dam",
  "PrBRZ_to_LowerRingold" = "Priest Rapids Dam to Lower Ringold"
)

# Prepare data for each location
prepare_location_data <- function(data, location_name, location_filter) {
  
  # Filter for this location and CHN species
  data_subset <- data |>
    filter(str_detect(location_group, location_filter) & 
           str_detect(location_group, "CHN")) |>
    filter(!is.na(tagger))  # Remove rows without tagger info
  
  if (nrow(data_subset) == 0) {
    cat("Warning: No data found for", location_name, "\n")
    return(NULL)
  }
  
  cat("Processing", location_name, "- Found", nrow(data_subset), "rows\n")
  
  # Extract just the survival segments (est and se columns)
  data_wide <- data_subset |>
    select(tagger, ends_with("_est"), ends_with("_se"))
  
  # Create a result dataframe with reaches (all character to avoid type conflicts)
  result_df <- data.frame(
    Reach = character(),
    Tagger_A_Est = character(),
    Tagger_A_SE = character(),
    Tagger_B_Est = character(),
    Tagger_B_SE = character(),
    Tagger_C_Est = character(),
    Tagger_C_SE = character(),
    P_value = character(),
    stringsAsFactors = FALSE
  )
  
  # Process each reach
  for (reach_col in names(reach_mapping)) {
    reach_name <- reach_mapping[reach_col]
    est_col <- paste0(reach_col, "_est")
    se_col <- paste0(reach_col, "_se")
    
    # Check if columns exist
    if (!est_col %in% names(data_wide) || !se_col %in% names(data_wide)) {
      next
    }
    
    row_data <- data.frame(Reach = reach_name)
    
    # Add tagger-specific estimates
    for (tagger in c("A", "B", "C")) {
      tagger_data <- data_subset |> filter(tagger == !!tagger)
      
      if (nrow(tagger_data) > 0) {
        est_val <- tagger_data[[est_col]][1]
        se_val <- tagger_data[[se_col]][1]
        
        row_data[[paste0("Tagger_", tagger, "_Est")]] <- if (is.na(est_val)) "" else as.character(round(est_val, 4))
        row_data[[paste0("Tagger_", tagger, "_SE")]] <- if (is.na(se_val)) "" else as.character(round(se_val, 4))
      } else {
        row_data[[paste0("Tagger_", tagger, "_Est")]] <- ""
        row_data[[paste0("Tagger_", tagger, "_SE")]] <- ""
      }
    }
    
    # Add P-value column (empty for now) as character
    row_data$P_value <- as.character("")
    
    result_df <- bind_rows(result_df, row_data)
  }
  
  return(result_df)
}

# ============================================================================
# Prepare data for both locations
# ============================================================================

ri_data <- prepare_location_data(survival_est, "Rock Island", "Rock Island")
pr_data <- prepare_location_data(survival_est, "Priest Rapids", "Priest Rapids")

cat("\nRock Island data prepared:\n")
if (!is.null(ri_data)) print(ri_data)

cat("\nPriest Rapids data prepared:\n")
if (!is.null(pr_data)) print(pr_data)

# ============================================================================
# Create markdown table for each location
# ============================================================================

create_md_table <- function(data, location_name, location_type = "RI") {
  if (is.null(data) || nrow(data) == 0) {
    return("")
  }
  
  table_lines <- c(
    "",
    paste0(location_name, " tailrace"),
    "",
    "|   |   |   |   |   |   |   |   |",
    "|---|---|---|---|---|---|---|---|",
    "|Reach|Tagger A: Estimate|Tagger A: SE|Tagger B: Estimate|Tagger B: SE|Tagger C: Estimate|Tagger C: SE|P-value|"
  )
  
  # For Priest Rapids, only show one row with special title
  if (location_type == "PR") {
    row <- data[1, ]
    table_row <- sprintf("|R_2 to Lower Ringold|%s|%s|%s|%s|%s|%s|%s|",
      row$Tagger_A_Est,
      row$Tagger_A_SE,
      row$Tagger_B_Est,
      row$Tagger_B_SE,
      row$Tagger_C_Est,
      row$Tagger_C_SE,
      row$P_value
    )
    table_lines <- c(table_lines, table_row)
  } else {
    # For Rock Island, show all rows with their reach names
    for (i in seq_len(nrow(data))) {
      row <- data[i, ]
      table_row <- sprintf("|%s|%s|%s|%s|%s|%s|%s|%s|",
        row$Reach,
        row$Tagger_A_Est,
        row$Tagger_A_SE,
        row$Tagger_B_Est,
        row$Tagger_B_SE,
        row$Tagger_C_Est,
        row$Tagger_C_SE,
        row$P_value
      )
      table_lines <- c(table_lines, table_row)
    }
  }
  
  return(paste(table_lines, collapse = "\n"))
}

# ============================================================================
# Combine and save filled table
# ============================================================================

output_content <- c(
  "a.       Rock Island tailrace (_R_1)",
  create_md_table(ri_data, "", location_type = "RI"),
  "",
  "b.       Priest Rapids tailrace (_R_2)",
  create_md_table(pr_data, "", location_type = "PR")
)

output_path <- "assumption_checking/tagger_table_filled.md"
writeLines(output_content, output_path)

cat("\n════════════════════════════════════════════════════════════\n")
cat("Tagger table template filled!\n")
cat("Output saved to:", output_path, "\n")
cat("════════════════════════════════════════════════════════════\n")
