# Function to create directory and markdown file structure for pasting
create_dirs_mds_for_pasting <- function(base_path) {
  #' Create directory structure with blank markdown files
  #'
  #' Creates a complete directory structure with blank .md files for pasting.
  #' Replicates the tagger_effects structure as found in round_3, populated with
  #' blank .md files for each analysis type. Does not overwrite existing files
  #' or directories.
  #'
  #' @param base_path Character string specifying where to create the structure.
  #'        The structure will be created at base_path/tagger_effects.
  #'        Can be absolute or relative to the working directory.
  #'
  #' @return A data frame with columns:
  #'   - path: path created or already existing
  #'   - type: "directory" or "file"
  #'   - action: what action was taken ("created", "already exists")
  #'
  #' @examples
  #' \dontrun{
  #'   create_dirs_mds_for_pasting("./new_location")
  #' }

  if (!dir.exists(base_path)) {
    stop(sprintf("Base path does not exist: %s", base_path))
  }

  # Define the directory structure
  root_dir <- file.path(base_path, "tagger_effects")
  
  # Tagger categories
  taggers <- c("POOLED", "TAGGER A", "TAGGER B", "TAGGER C")
  
  # Subcategories
  subcats <- c("PR_CHN", "PR_STH", "RI_CHN", "RI_STH")
  
  # File types to create in each subcategory
  file_types <- c("Capture History Report .md", "CJS_report.md")
  
  # RI_ directories also get Cumul_surv.md
  ri_file <- "Cumul_surv.md"
  
  results <- list()
  
  # Create root directory
  if (!dir.exists(root_dir)) {
    dir.create(root_dir)
    results[[length(results) + 1]] <- data.frame(
      path = root_dir,
      type = "directory",
      action = "created",
      stringsAsFactors = FALSE
    )
  } else {
    results[[length(results) + 1]] <- data.frame(
      path = root_dir,
      type = "directory",
      action = "already exists",
      stringsAsFactors = FALSE
    )
  }
  
  # Create tagger directories and their subdirectories
  for (tagger in taggers) {
    tagger_dir <- file.path(root_dir, tagger)
    
    # Create tagger directory
    if (!dir.exists(tagger_dir)) {
      dir.create(tagger_dir)
      results[[length(results) + 1]] <- data.frame(
        path = tagger_dir,
        type = "directory",
        action = "created",
        stringsAsFactors = FALSE
      )
    } else {
      results[[length(results) + 1]] <- data.frame(
        path = tagger_dir,
        type = "directory",
        action = "already exists",
        stringsAsFactors = FALSE
      )
    }
    
    # Create subcategory directories and files
    for (subcat in subcats) {
      subcat_dir <- file.path(tagger_dir, subcat)
      
      # Create subcategory directory
      if (!dir.exists(subcat_dir)) {
        dir.create(subcat_dir)
        results[[length(results) + 1]] <- data.frame(
          path = subcat_dir,
          type = "directory",
          action = "created",
          stringsAsFactors = FALSE
        )
      } else {
        results[[length(results) + 1]] <- data.frame(
          path = subcat_dir,
          type = "directory",
          action = "already exists",
          stringsAsFactors = FALSE
        )
      }
      
      # Create markdown files
      for (file_type in file_types) {
        file_path <- file.path(subcat_dir, file_type)
        if (!file.exists(file_path)) {
          file.create(file_path)
          results[[length(results) + 1]] <- data.frame(
            path = file_path,
            type = "file",
            action = "created",
            stringsAsFactors = FALSE
          )
        } else {
          results[[length(results) + 1]] <- data.frame(
            path = file_path,
            type = "file",
            action = "already exists",
            stringsAsFactors = FALSE
          )
        }
      }
      
      # Create Cumul_surv.md for RI_ directories
      if (grepl("^RI_", subcat)) {
        ri_path <- file.path(subcat_dir, ri_file)
        if (!file.exists(ri_path)) {
          file.create(ri_path)
          results[[length(results) + 1]] <- data.frame(
            path = ri_path,
            type = "file",
            action = "created",
            stringsAsFactors = FALSE
          )
        } else {
          results[[length(results) + 1]] <- data.frame(
            path = ri_path,
            type = "file",
            action = "already exists",
            stringsAsFactors = FALSE
          )
        }
      }
    }
  }
  
  result_df <- do.call(rbind, results)
  rownames(result_df) <- NULL
  
  # Print summary
  cat("\n=== Directory Structure Creation Summary ===\n\n")
  created_dirs <- sum(result_df$type == "directory" & result_df$action == "created")
  existing_dirs <- sum(result_df$type == "directory" & result_df$action == "already exists")
  created_files <- sum(result_df$type == "file" & result_df$action == "created")
  existing_files <- sum(result_df$type == "file" & result_df$action == "already exists")
  
  cat(sprintf("Directories created: %d\n", created_dirs))
  cat(sprintf("Directories already existing: %d\n", existing_dirs))
  cat(sprintf("Files created: %d\n", created_files))
  cat(sprintf("Files already existing: %d\n", existing_files))
  cat(sprintf("\nStructure location: %s\n\n", root_dir))
  
  invisible(result_df)
}
