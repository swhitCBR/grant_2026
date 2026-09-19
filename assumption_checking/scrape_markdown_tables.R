#' Scrape Markdown Tables from Tagger Effects Reports
#'
#' Extracts capture history summary tables from markdown files
#' in the tagger_effects directory.
#'
#' @param round_dir Character string. Path to round directory (e.g., "round_3")
#'
#' @return List with extracted data:
#'   - Nested list organized by location and tagger

library(dplyr)
library(stringr)

# ============================================================================
# Main Scraping Function
# ============================================================================

scrape_capture_history <- function(round_dir = "round_3") {
  
  if (!dir.exists(round_dir)) {
    stop("Round directory not found: ", round_dir)
  }
  
  tagger_effects_dir <- file.path(round_dir, "tagger_effects")
  
  if (!dir.exists(tagger_effects_dir)) {
    stop("tagger_effects directory not found in ", round_dir)
  }
  
  # Find all capture history markdown files
  capture_files <- list.files(
    tagger_effects_dir,
    pattern = "Capture History",
    recursive = TRUE,
    full.names = TRUE
  )
  
  cat("Found", length(capture_files), "capture history files\n")
  
  # Container for results
  results <- list()
  
  # Process each file
  for (filepath in capture_files) {
    content <- readLines(filepath, warn = FALSE)
    
    # Extract metadata from path
    path_parts <- str_split(filepath, "/")[[1]]
    tagger_dir <- path_parts[length(path_parts) - 2]  # POOLED or TAGGER X
    location_species <- path_parts[length(path_parts) - 1]  # RI_CHN, etc
    
    # Parse location and species
    if (str_detect(location_species, "CHN")) {
      species <- "Chinook"
      location_code <- str_sub(location_species, 1, 2)  # RI or PR
    } else if (str_detect(location_species, "STH")) {
      species <- "Steelhead"
      location_code <- str_sub(location_species, 1, 2)
    } else {
      next
    }
    
    # Skip steelhead (empty data)
    if (species == "Steelhead") {
      next
    }
    
    # Extract the title line
    title_line <- content[3]
    
    # Find data rows: starts with |, contains numbers, not the separator line
    table_rows <- which(
      str_detect(content, "^\\|[0-9]") 
    )
    
    # Filter to just the data rows (before Configuration section)
    config_line <- which(str_detect(content, "^Configuration:"))[1]
    if (!is.na(config_line)) {
      table_rows <- table_rows[table_rows < config_line]
    }
    
    # Parse each table row
    capture_patterns <- list()
    
    for (row_idx in table_rows) {
      line <- content[row_idx]
      
      # Split by pipe and trim
      parts <- str_split(line, "\\|")[[1]] %>%
        str_trim() %>%
        .[. != ""]
      
      if (length(parts) >= 2) {
        pattern <- parts[1]
        count <- suppressWarnings(as.numeric(parts[2]))
        
        if (!is.na(count)) {
          capture_patterns[[pattern]] <- count
        }
      }
    }
    
    # Create data frame
    if (length(capture_patterns) > 0) {
      df <- data.frame(
        Pattern = names(capture_patterns),
        Count = unlist(capture_patterns),
        row.names = NULL,
        stringsAsFactors = FALSE
      )
      
      # Create key for storage
      key <- paste0(location_code, "_", tagger_dir)
      
      results[[key]] <- list(
        data = df,
        tagger = tagger_dir,
        location = location_code,
        location_full = title_line,
        species = species,
        n_patterns = nrow(df),
        total_fish = sum(df$Count),
        file = filepath
      )
      
      cat("✓", sprintf("%-15s %-10s %d patterns, %d total", 
                       tagger_dir, location_code, nrow(df), sum(df$Count)), "\n")
    }
  }
  
  cat("\nTotal tables extracted:", length(results), "\n")
  return(results)
}

# ============================================================================
# Functions to format for report inclusion
# ============================================================================

#' Format capture history tables as markdown for insertion into reports
#'
#' @param scraped_data List from scrape_capture_history()
#' @return Character string with markdown formatted tables

format_capture_history_tables <- function(scraped_data) {
  
  if (length(scraped_data) == 0) {
    return("")
  }
  
  # Organize by location
  ri_tables <- Filter(function(x) x$location == "RI", scraped_data)
  pr_tables <- Filter(function(x) x$location == "PR", scraped_data)
  
  output <- ""
  
  # Rock Island section
  if (length(ri_tables) > 0) {
    output <- paste0(output, "## Rock Island Tailrace (RI) - Capture History Summary\n\n")
    
    # Sort by tagger
    ri_names <- names(ri_tables)[order(names(ri_tables))]
    
    for (name in ri_names) {
      item <- ri_tables[[name]]
      
      # Create subsection
      output <- paste0(output, sprintf("### Tagger %s\n\n", item$tagger))
      
      # Create markdown table
      output <- paste0(
        output,
        "|Capture Pattern|Count|\n",
        "|---|---|\n"
      )
      
      for (i in 1:nrow(item$data)) {
        output <- paste0(
          output,
          sprintf("|%s|%d|\n", item$data$Pattern[i], item$data$Count[i])
        )
      }
      
      output <- paste0(
        output,
        sprintf("\n_Total: %d fish with %d unique capture patterns_\n\n",
                item$total_fish, item$n_patterns)
      )
    }
  }
  
  # Priest Rapids section
  if (length(pr_tables) > 0) {
    output <- paste0(output, "## Priest Rapids Tailrace (PR) - Capture History Summary\n\n")
    
    # Sort by tagger
    pr_names <- names(pr_tables)[order(names(pr_tables))]
    
    for (name in pr_names) {
      item <- pr_tables[[name]]
      
      # Create subsection
      output <- paste0(output, sprintf("### Tagger %s\n\n", item$tagger))
      
      # Create markdown table
      output <- paste0(
        output,
        "|Capture Pattern|Count|\n",
        "|---|---|\n"
      )
      
      for (i in 1:nrow(item$data)) {
        output <- paste0(
          output,
          sprintf("|%s|%d|\n", item$data$Pattern[i], item$data$Count[i])
        )
      }
      
      output <- paste0(
        output,
        sprintf("\n_Total: %d fish with %d unique capture patterns_\n\n",
                item$total_fish, item$n_patterns)
      )
    }
  }
  
  return(output)
}

#' Save capture history tables to a markdown file
#'
#' @param scraped_data List from scrape_capture_history()
#' @param output_file Path to write markdown file

save_capture_history_markdown <- function(scraped_data, output_file) {
  
  markdown_content <- format_capture_history_tables(scraped_data)
  
  writeLines(markdown_content, output_file)
  
  cat("Saved capture history markdown to:", output_file, "\n")
  
  invisible(markdown_content)
}

# ============================================================================
# Example usage:
# 
# scraped <- scrape_capture_history("assumption_checking/round_3")
# markdown <- format_capture_history_tables(scraped)
# cat(markdown)
# save_capture_history_markdown(scraped, "assumption_checking/round_3/capture_history_tables.md")
