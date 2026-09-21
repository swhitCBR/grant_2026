#' Pivot CJS Survival to Long Format
#'
#' Converts wide-format CJS survival estimates to long format with one row per
#' tagger/location/reach combination.
#'
#' @param cjs_survival Data frame in wide format (from scrape_atlas_results)
#'
#' @return Data frame in long format with columns:
#'   - tagger, location, location_code, species
#'   - reach (reach name)
#'   - estimate (survival estimate)
#'   - se (standard error)
#'
#' @keywords internal

.pivot_cjs_survival_long <- function(cjs_survival) {
  
  if (is.null(cjs_survival) || nrow(cjs_survival) == 0) {
    return(NULL)
  }
  
  # Identify reach columns (those ending in _est)
  reach_cols <- grep("_est$", names(cjs_survival), value = TRUE)
  
  # Extract reach names by removing _est suffix
  reach_names <- sub("_est$", "", reach_cols)
  
  # Filter out empty reach names
  reach_names <- reach_names[reach_names != ""]
  
  # Build long-format data frame
  long_list <- list()
  
  for (i in 1:nrow(cjs_survival)) {
    row_data <- cjs_survival[i, ]
    
    for (reach in reach_names) {
      est_col <- paste0(reach, "_est")
      se_col <- paste0(reach, "_se")
      
      est_value <- row_data[[est_col]]
      se_value <- row_data[[se_col]]
      
      # Only include if estimate is not NA
      if (!is.na(est_value)) {
        long_list[[length(long_list) + 1]] <- data.frame(
          tagger = row_data$tagger,
          location = row_data$location,
          location_code = row_data$location_code,
          species = row_data$species,
          reach = reach,
          estimate = est_value,
          se = se_value,
          stringsAsFactors = FALSE
        )
      }
    }
  }
  
  # Combine into single data frame
  if (length(long_list) > 0) {
    result <- bind_rows(long_list)
    return(result)
  } else {
    return(NULL)
  }
}


#' Scrape ATLAS Results from Markdown Files
#'
#' Extracts capture history summaries and CJS (Cormack-Jolly-Seber) survival and
#' capture estimates from markdown files organized in a nested directory structure.
#' Processes multiple tagger groups and location/species combinations.
#'
#' @param base_dir Character string. Path to base directory containing tagger subdirectories
#'   (e.g., "assumption_checking/BRZsel_run" or "assumption_checking/round_3/tagger_effects")
#'
#' @return List with three main components:
#'   - capture_history: Nested list by location_tagger, containing capture pattern counts
#'   - cjs_survival: Data frame with survival estimates and standard errors by reach
#'   - cjs_capture: Data frame with capture estimates and standard errors by detection site
#'   - metadata: List with summary counts and processing information
#'
#' @details
#' Expected directory structure:
#' ```
#' base_dir/
#' ├── POOLED/
#' │   ├── PR_CHN/
#' │   │   ├── Capture History Report .md
#' │   │   └── CJS_report.md
#' │   ├── RI_CHN/
#' │   └── ...
#' ├── TAGGER A/
#' │   ├── PR_CHN/
#' │   └── ...
#' └── ...
#' ```
#'
#' @examples
#' \dontrun{
#' results <- scrape_atlas_results("assumption_checking/BRZsel_run")
#' str(results)
#' }
#'
#' @export

scrape_atlas_results <- function(base_dir) {
  
  library(dplyr, quietly = TRUE)
  
  # Validate input
  if (!dir.exists(base_dir)) {
    stop("Base directory not found: ", base_dir)
  }
  
  # Initialize containers
  capture_history <- list()
  cjs_survival_list <- list()
  cjs_capture_list <- list()
  
  # Find all tagger directories
  tagger_dirs <- list.dirs(base_dir, recursive = FALSE, full.names = TRUE)
  tagger_dirs <- tagger_dirs[dir.exists(tagger_dirs)]
  
  cat("Found", length(tagger_dirs), "tagger directories\n")
  
  # Track summary stats
  total_files_processed <- 0
  ch_files_extracted <- 0
  cjs_files_extracted <- 0
  
  # Process each tagger directory
  for (tagger_path in tagger_dirs) {
    tagger_name <- basename(tagger_path)
    
    # Find all location/species subdirectories
    location_dirs <- list.dirs(tagger_path, recursive = FALSE, full.names = TRUE)
    
    for (location_path in location_dirs) {
      location_code <- basename(location_path)
      
      # Parse location and species
      species <- ifelse(grepl("CHN", location_code), "Chinook", "Steelhead")
      location <- substr(location_code, 1, 2)  # RI or PR
      
      # Create unique key (include species to avoid overwrites)
      key <- paste0(location, "_", species, "_", tagger_name)
      
      # ========================================================================
      # CAPTURE HISTORY EXTRACTION
      # ========================================================================
      
      ch_file <- file.path(location_path, "Capture History Report .md")
      
      if (file.exists(ch_file)) {
        tryCatch({
          ch_content <- readLines(ch_file, warn = FALSE)
          
          # Find table rows (pipes with numbers)
          table_rows <- which(
            grepl("^\\|[0-9]", ch_content)
          )
          
          # Find configuration section boundary
          config_line <- which(grepl("^Configuration:", ch_content))[1]
          if (!is.na(config_line)) {
            table_rows <- table_rows[table_rows < config_line]
          }
          
          # Parse capture patterns
          patterns <- list()
          
          for (row_idx in table_rows) {
            line <- ch_content[row_idx]
            parts <- strsplit(line, "\\|")[[1]]
            parts <- trimws(parts[parts != ""])
            
            if (length(parts) >= 2) {
              pattern <- parts[1]
              count <- suppressWarnings(as.numeric(parts[2]))
              
              if (!is.na(count)) {
                patterns[[pattern]] <- count
              }
            }
          }
          
          # Store results if not empty
          if (length(patterns) > 0) {
            df <- data.frame(
              Pattern = names(patterns),
              Count = unlist(patterns),
              row.names = NULL,
              stringsAsFactors = FALSE
            )
            
            capture_history[[key]] <- list(
              data = df,
              tagger = tagger_name,
              location = location,
              location_code = location_code,
              species = species,
              n_patterns = nrow(df),
              total_fish = sum(df$Count),
              file = ch_file
            )
            
            ch_files_extracted <- ch_files_extracted + 1
          }
        }, error = function(e) {
          warning("Error processing ", ch_file, ": ", e$message)
        })
      }
      
      # ========================================================================
      # CJS RESULTS EXTRACTION
      # ========================================================================
      
      cjs_file <- file.path(location_path, "CJS_report.md")
      
      if (file.exists(cjs_file)) {
        tryCatch({
          cjs_content <- readLines(cjs_file, warn = FALSE)
          
          # Extract survival estimates
          surv_section_start <- which(grepl("Survival Estimates:", cjs_content))
          capture_section_start <- which(grepl("Capture Estimates:", cjs_content))
          
          if (length(surv_section_start) > 0) {
            # Find header rows and data row
            search_range <- surv_section_start:(min(capture_section_start) - 1)
            header_rows <- which(grepl("^\\|.*Estimate.*s.e", cjs_content[search_range]))
            
            if (length(header_rows) > 0) {
              # The header with "Estimate" and "s.e." tells us which row has the reach names
              header_estimate_idx <- surv_section_start + header_rows[1] - 1
              reach_names_idx <- header_estimate_idx - 1  # Reach names are one line above
              
              # Extract reach names
              reach_line <- cjs_content[reach_names_idx]
              reach_parts <- strsplit(reach_line, "\\|")[[1]]
              # Trim first, then filter empty (to avoid keeping strings that were only spaces)
              reach_parts <- trimws(reach_parts)
              reach_parts <- reach_parts[reach_parts != ""]
              
              # Extract data row (one line after the header with "Estimate|s.e.")
              data_idx <- header_estimate_idx + 1
              if (data_idx <= length(cjs_content)) {
                data_line <- cjs_content[data_idx]
                data_parts <- strsplit(data_line, "\\|")[[1]]
                data_parts <- trimws(data_parts[data_parts != ""])
                
                if (length(data_parts) >= 2) {
                  # Remove label (first column)
                  values <- suppressWarnings(as.numeric(data_parts[-1]))
                  
                  # Pair estimates with s.e.
                  n_reaches <- length(reach_parts)
                  surv_df <- data.frame(
                    tagger = tagger_name,
                    location = location,
                    location_code = location_code,
                    species = species,
                    stringsAsFactors = FALSE
                  )
                  
                  # Add reach estimates (2 columns per reach: estimate, s.e.)
                  for (i in 1:n_reaches) {
                    col_idx <- (i - 1) * 2 + 1
                    if (col_idx + 1 <= length(values)) {
                      surv_df[[paste0(reach_parts[i], "_est")]] <- values[col_idx]
                      surv_df[[paste0(reach_parts[i], "_se")]] <- values[col_idx + 1]
                    }
                  }
                  
                  cjs_survival_list[[key]] <- surv_df
                }
              }
            }
          }
          
          # Extract capture estimates
          if (length(capture_section_start) > 0) {
            search_range <- capture_section_start:length(cjs_content)
            header_rows <- which(grepl("^\\|.*Estimate.*s.e", cjs_content[search_range]))
            
            if (length(header_rows) > 0) {
              # The header with "Estimate" and "s.e." tells us which row has the site names
              header_estimate_idx <- capture_section_start + header_rows[1] - 1
              site_names_idx <- header_estimate_idx - 1  # Site names are one line above
              
              # Extract site names
              site_line <- cjs_content[site_names_idx]
              site_parts <- strsplit(site_line, "\\|")[[1]]
              # Trim first, then filter empty (to avoid keeping strings that were only spaces)
              site_parts <- trimws(site_parts)
              site_parts <- site_parts[site_parts != ""]
              
              # Extract data row (one line after the header with "Estimate|s.e.")
              data_idx <- header_estimate_idx + 1
              if (data_idx <= length(cjs_content)) {
                data_line <- cjs_content[data_idx]
                data_parts <- strsplit(data_line, "\\|")[[1]]
                data_parts <- trimws(data_parts[data_parts != ""])
                
                if (length(data_parts) >= 2) {
                  # Remove label (first column)
                  values <- suppressWarnings(as.numeric(data_parts[-1]))
                  
                  # Pair estimates with s.e.
                  n_sites <- length(site_parts)
                  cap_df <- data.frame(
                    tagger = tagger_name,
                    location = location,
                    location_code = location_code,
                    species = species,
                    stringsAsFactors = FALSE
                  )
                  
                  # Add site estimates (2 columns per site: estimate, s.e.)
                  for (i in 1:n_sites) {
                    col_idx <- (i - 1) * 2 + 1
                    if (col_idx + 1 <= length(values)) {
                      cap_df[[paste0(site_parts[i], "_est")]] <- values[col_idx]
                      cap_df[[paste0(site_parts[i], "_se")]] <- values[col_idx + 1]
                    }
                  }
                  
                  cjs_capture_list[[key]] <- cap_df
                }
              }
            }
          }
          
          cjs_files_extracted <- cjs_files_extracted + 1
        }, error = function(e) {
          warning("Error processing ", cjs_file, ": ", e$message)
        })
      }
      
      total_files_processed <- total_files_processed + 1
    }
  }
  
  # Combine CJS results into single data frames if available
  cjs_survival <- NULL
  cjs_capture <- NULL
  
  if (length(cjs_survival_list) > 0) {
    cjs_survival <- bind_rows(cjs_survival_list)
  }
  
  if (length(cjs_capture_list) > 0) {
    cjs_capture <- bind_rows(cjs_capture_list)
  }
  
  # Convert CJS survival to long format
  cjs_survival_long <- NULL
  
  if (!is.null(cjs_survival)) {
    cjs_survival_long <- .pivot_cjs_survival_long(cjs_survival)
  }
  
  # Print summary
  cat("\n════════════════════════════════════════════════════════════\n")
  cat("ATLAS Results Scraping Summary\n")
  cat("════════════════════════════════════════════════════════════\n")
  cat(sprintf("Location/Tagger combinations processed: %d\n", total_files_processed))
  cat(sprintf("Capture history files extracted: %d\n", ch_files_extracted))
  cat(sprintf("CJS report files extracted: %d\n", cjs_files_extracted))
  cat(sprintf("Total capture history tables: %d\n", length(capture_history)))
  cat(sprintf("Total CJS survival records (wide): %d\n", nrow(cjs_survival) %||% 0))
  cat(sprintf("Total CJS survival records (long): %d\n", nrow(cjs_survival_long) %||% 0))
  cat(sprintf("Total CJS capture records: %d\n", nrow(cjs_capture) %||% 0))
  cat("════════════════════════════════════════════════════════════\n\n")
  
  # Return results
  invisible(list(
    capture_history = capture_history,
    cjs_survival = cjs_survival,
    cjs_survival_long = cjs_survival_long,
    cjs_capture = cjs_capture,
    metadata = list(
      base_dir = base_dir,
      files_processed = total_files_processed,
      ch_files = ch_files_extracted,
      cjs_files = cjs_files_extracted,
      timestamp = Sys.time()
    )
  ))
}


#' Format Scraped ATLAS Results for Report Inclusion
#'
#' Converts scraped capture history and CJS estimates into markdown formatted tables
#' suitable for inclusion in Quarto (.qmd) documents.
#'
#' @param scraped List returned from \code{scrape_atlas_results()}
#' @param include_capture_history Logical. Include capture history tables. Default TRUE.
#' @param include_cjs_survival Logical. Include CJS survival estimates. Default TRUE.
#' @param include_cjs_capture Logical. Include CJS capture estimates. Default TRUE.
#'
#' @return Character string with markdown formatted content
#'
#' @export

format_atlas_markdown <- function(
    scraped,
    include_capture_history = TRUE,
    include_cjs_survival = TRUE,
    include_cjs_capture = TRUE) {
  
  output <- ""
  
  # ========================================================================
  # CAPTURE HISTORY SECTION
  # ========================================================================
  
  if (include_capture_history && !is.null(scraped$capture_history)) {
    
    ch_list <- scraped$capture_history
    
    # Organize by location
    ri_ch <- Filter(function(x) x$location == "RI", ch_list)
    pr_ch <- Filter(function(x) x$location == "PR", ch_list)
    
    # Rock Island
    if (length(ri_ch) > 0) {
      output <- paste0(output, "## Rock Island Tailrace (RI) - Capture History\n\n")
      
      ri_names <- names(ri_ch)[order(names(ri_ch))]
      
      for (name in ri_names) {
        item <- ri_ch[[name]]
        output <- paste0(output, sprintf("### Tagger %s\n\n", item$tagger))
        output <- paste0(output, "|Capture Pattern|Count|\n|---|---|\n")
        
        for (i in 1:nrow(item$data)) {
          output <- paste0(
            output,
            sprintf("|%s|%d|\n", item$data$Pattern[i], item$data$Count[i])
          )
        }
        
        output <- paste0(
          output,
          sprintf("\n_Total: %d fish with %d unique patterns_\n\n",
                  item$total_fish, item$n_patterns)
        )
      }
    }
    
    # Priest Rapids
    if (length(pr_ch) > 0) {
      output <- paste0(output, "## Priest Rapids Tailrace (PR) - Capture History\n\n")
      
      pr_names <- names(pr_ch)[order(names(pr_ch))]
      
      for (name in pr_names) {
        item <- pr_ch[[name]]
        output <- paste0(output, sprintf("### Tagger %s\n\n", item$tagger))
        output <- paste0(output, "|Capture Pattern|Count|\n|---|---|\n")
        
        for (i in 1:nrow(item$data)) {
          output <- paste0(
            output,
            sprintf("|%s|%d|\n", item$data$Pattern[i], item$data$Count[i])
          )
        }
        
        output <- paste0(
          output,
          sprintf("\n_Total: %d fish with %d unique patterns_\n\n",
                  item$total_fish, item$n_patterns)
        )
      }
    }
  }
  
  # ========================================================================
  # CJS SURVIVAL SECTION
  # ========================================================================
  
  if (include_cjs_survival && !is.null(scraped$cjs_survival)) {
    output <- paste0(output, "## CJS Survival Estimates\n\n")
    output <- paste0(output, knitr::kable(scraped$cjs_survival, format = "markdown"))
    output <- paste0(output, "\n\n")
  }
  
  # ========================================================================
  # CJS CAPTURE SECTION
  # ========================================================================
  
  if (include_cjs_capture && !is.null(scraped$cjs_capture)) {
    output <- paste0(output, "## CJS Capture Estimates\n\n")
    output <- paste0(output, knitr::kable(scraped$cjs_capture, format = "markdown"))
    output <- paste0(output, "\n\n")
  }
  
  return(output)
}
