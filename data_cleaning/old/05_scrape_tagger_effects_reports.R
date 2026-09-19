#' Scrape tagger effects markdown reports into dataframes
#'
#' Reads CJS survival and capture estimates from markdown files in 
#' assumption_checking/tagger_effects/ and creates dataframes with
#' the results organized by tagger (A, B, C, POOLED) and location/species.
#'
#' Output: Two dataframes saved to data/clean/
#'   - cjs_survival_estimates.rds
#'   - cjs_capture_estimates.rds

if(getwd() != "c:/repos/grant_2026"){
  setwd("c:/repos/grant_2026")}

library(dplyr)
library(stringr)
library(readr)

# ============================================================================
# Helper function to extract survival estimates from CJS report
# ============================================================================

extract_survival_from_md <- function(filepath) {
  content <- readLines(filepath)
  
  # Find the line with "Survival Estimates:" and the table that follows
  survival_idx <- grep("Survival Estimates:", content)
  
  if (length(survival_idx) == 0) return(NULL)
  
  # Get the configuration dataset name for context (handle both formats)
  # Format 1: |Dataset|value| (compact)
  # Format 2: | Dataset | value | (spaced)
  config_idx <- grep("Dataset", content, fixed = TRUE)
  dataset <- NA
  if (length(config_idx) > 0) {
    # Find the line with Dataset that's in a config section (after Configuration:)
    config_section_start <- grep("Configuration:", content)
    if (length(config_section_start) > 0) {
      config_idx <- config_idx[config_idx > config_section_start[1]]
    }
    
    if (length(config_idx) > 0) {
      dataset_line <- content[config_idx[1]]
      parts <- str_split(dataset_line, "\\|")[[1]]
      parts <- parts[parts != ""] |> str_trim()
      if (length(parts) >= 2) {
        dataset <- parts[2]
      }
    }
  }
  
  # Look for the data row (starts with a location name like "Rock Island Tailrace CHN")
  # Data rows are after the header rows (---|---|...) and before "Capture Estimates:"
  capture_idx <- grep("Capture Estimates:", content)
  
  # Extract rows between survival table and capture table
  start_row <- survival_idx + 4  # Skip headers
  end_row <- if (length(capture_idx) > 0) capture_idx[1] - 1 else length(content)
  
  # Find the actual data row (contains numbers with decimals and location name)
  data_rows <- content[start_row:end_row]
  # Filter for rows with numbers and location keywords
  data_row <- data_rows[grepl("(Rock Island|Priest Rapids)", data_rows) & 
                        grepl("\\d+\\.\\d+", data_rows)]
  
  if (length(data_row) == 0) return(NULL)
  
  # Parse the data row
  parts <- str_split(data_row[1], "\\|")[[1]]
  parts <- parts[parts != ""] |> str_trim()
  
  if (length(parts) < 2) return(NULL)
  
  location_group <- parts[1]
  estimates <- suppressWarnings(as.numeric(parts[-1]))
  estimates <- estimates[!is.na(estimates)]
  
  # Dynamically extract reach names from the header row (2 rows after survival_idx)
  # The header row has the reach names in merged cells
  header_row <- content[survival_idx + 2]
  header_parts <- str_split(header_row, "\\|")[[1]]
  header_parts <- header_parts[header_parts != ""] |> str_trim()
  
  # Filter out empty and "Estimate"/"s.e." labels to get reach names
  reach_names <- header_parts[!grepl("(^$|Estimate|s\\.e\\.|---)", header_parts)]
  
  # If no reach names found, use defaults based on dataset
  if (length(reach_names) == 0) {
    # Check if this is a Priest Rapids file (PR_init or PR_redo)
    reach_names <- if (grepl("^PR_", dataset)) {
      c("Release_to_LowerRingold")
    } else {
      c("Release_to_CB", "CB_to_Sunland", "Sunland_to_WanBRZ",
        "WanBRZ_to_Mattawa", "Mattawa_to_PrBRZ", "PrBRZ_to_LowerRingold")
    }
  } else {
    # Convert reach names from markdown format to column names
    reach_names <- reach_names |> 
      str_replace_all(" to ", "_to_") |>
      str_replace_all(" ", "")
  }
  
  # Extract estimate and se pairs
  df <- data.frame(
    dataset = dataset,
    location_group = location_group,
    stringsAsFactors = FALSE
  )
  
  # Add survival estimates and standard errors
  for (i in seq_along(reach_names)) {
    idx <- (i - 1) * 2 + 1
    if (idx <= length(estimates)) {
      df[[paste0(reach_names[i], "_est")]] <- if (idx <= length(estimates)) estimates[idx] else NA
      df[[paste0(reach_names[i], "_se")]] <- if (idx + 1 <= length(estimates)) estimates[idx + 1] else NA
    }
  }
  
  return(df)
}

# ============================================================================
# Helper function to extract capture estimates from CJS report
# ============================================================================

extract_capture_from_md <- function(filepath) {
  content <- readLines(filepath)
  
  # Find the line with "Capture Estimates:"
  capture_idx <- grep("Capture Estimates:", content)
  
  if (length(capture_idx) == 0) return(NULL)
  
  # Get the configuration dataset name (handle both formats)
  config_idx <- grep("Dataset", content, fixed = TRUE)
  dataset <- NA
  if (length(config_idx) > 0) {
    # Find the line with Dataset that's in a config section (after Configuration:)
    config_section_start <- grep("Configuration:", content)
    if (length(config_section_start) > 0) {
      config_idx <- config_idx[config_idx > config_section_start[1]]
    }
    
    if (length(config_idx) > 0) {
      dataset_line <- content[config_idx[1]]
      parts <- str_split(dataset_line, "\\|")[[1]]
      parts <- parts[parts != ""] |> str_trim()
      if (length(parts) >= 2) {
        dataset <- parts[2]
      }
    }
  }
  
  # Find data rows (after headers, before Configuration)
  config_start <- grep("Configuration:", content)
  start_row <- capture_idx + 4  # Skip headers
  end_row <- if (length(config_start) > 0) config_start[1] - 1 else length(content)
  
  data_rows <- content[start_row:end_row]
  # Filter for rows with numbers and location keywords
  data_row <- data_rows[grepl("(Rock Island|Priest Rapids)", data_rows) & 
                        grepl("\\d+\\.\\d+", data_rows)]
  
  if (length(data_row) == 0) return(NULL)
  
  # Parse the data row
  parts <- str_split(data_row[1], "\\|")[[1]]
  parts <- parts[parts != ""] |> str_trim()
  
  if (length(parts) < 2) return(NULL)
  
  location_group <- parts[1]
  estimates <- suppressWarnings(as.numeric(parts[-1]))
  estimates <- estimates[!is.na(estimates)]
  
  # Create column names for capture sites
  capture_sites <- c(
    "Crescent_Bar", "Sunland", "Wanapum_BRZ", "Mattawa",
    "Priest_BRZ", "Lower_Ringold", "Hanford_Surv_Cap"
  )
  
  df <- data.frame(
    dataset = dataset,
    location_group = location_group,
    stringsAsFactors = FALSE
  )
  
  # Add capture estimates and standard errors
  for (i in seq_along(capture_sites)) {
    idx <- (i - 1) * 2 + 1
    if (idx <= length(estimates)) {
      df[[paste0(capture_sites[i], "_est")]] <- if (idx <= length(estimates)) estimates[idx] else NA
      df[[paste0(capture_sites[i], "_se")]] <- if (idx + 1 <= length(estimates)) estimates[idx + 1] else NA
    }
  }
  
  return(df)
}

# ============================================================================
# Find all CJS report markdown files
# ============================================================================

cjs_files <- list.files(
  "assumption_checking/tagger_effects",
  pattern = "CJS_report\\.md$",
  full.names = TRUE,
  recursive = TRUE
)

cat("Found", length(cjs_files), "CJS report files\n\n")

# Extract metadata from file paths
file_metadata <- data.frame(
  filepath = cjs_files,
  stringsAsFactors = FALSE
) |>
  mutate(
    relative_path = str_replace(filepath, ".*tagger_effects/", ""),
    parts = str_split(relative_path, "/"),
    tagger = sapply(parts, function(x) x[1]),
    location_species = sapply(parts, function(x) x[2])
  ) |>
  select(-parts, -relative_path)

cat("Taggers found:", unique(file_metadata$tagger), "\n")
cat("Location/Species combinations:", unique(file_metadata$location_species), "\n\n")

# ============================================================================
# Extract survival and capture estimates
# ============================================================================

cat("Extracting survival estimates...\n")
survival_estimates <- lapply(cjs_files, extract_survival_from_md) |>
  bind_rows()

cat("Extracted", nrow(survival_estimates), "survival estimate rows\n\n")

cat("Extracting capture estimates...\n")
capture_estimates <- lapply(cjs_files, extract_capture_from_md) |>
  bind_rows()

cat("Extracted", nrow(capture_estimates), "capture estimate rows\n\n")

# ============================================================================
# Add tagger and location/species information
# ============================================================================

# Parse dataset name to add tagger and location info
for (i in seq_len(nrow(survival_estimates))) {
  dataset <- survival_estimates$dataset[i]
  if (!is.na(dataset)) {
    if (str_detect(dataset, "tagger_A")) {
      survival_estimates$tagger[i] <- "A"
    } else if (str_detect(dataset, "tagger_B")) {
      survival_estimates$tagger[i] <- "B"
    } else if (str_detect(dataset, "tagger_C")) {
      survival_estimates$tagger[i] <- "C"
    } else {
      survival_estimates$tagger[i] <- "POOLED"
    }
  }
}

for (i in seq_len(nrow(capture_estimates))) {
  dataset <- capture_estimates$dataset[i]
  if (!is.na(dataset)) {
    if (str_detect(dataset, "tagger_A")) {
      capture_estimates$tagger[i] <- "A"
    } else if (str_detect(dataset, "tagger_B")) {
      capture_estimates$tagger[i] <- "B"
    } else if (str_detect(dataset, "tagger_C")) {
      capture_estimates$tagger[i] <- "C"
    } else {
      capture_estimates$tagger[i] <- "POOLED"
    }
  }
}

# ============================================================================
# Save to RDS files
# ============================================================================

output_dir <- "assumption_checking"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

saveRDS(survival_estimates, file.path(output_dir, "cjs_survival_estimates.rds"))
saveRDS(capture_estimates, file.path(output_dir, "cjs_capture_estimates.rds"))

cat("════════════════════════════════════════════════════════════\n")
cat("Tagger effects reports scraping complete!\n")
cat("Survival estimates:", nrow(survival_estimates), "rows\n")
cat("Capture estimates:", nrow(capture_estimates), "rows\n")
cat("Saved to assumption_checking/\n")
cat("════════════════════════════════════════════════════════════\n")
