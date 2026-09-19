# Function to create a general nested directory structure with markdown files
make_dirs_mds_for_pasting <- function(
    base_path,
    outer_folder = "tagger_effects",
    level1_dirs = c("POOLED", "TAGGER A", "TAGGER B", "TAGGER C"),
    level2_dirs = c("PR_CHN", "PR_STH", "RI_CHN", "RI_STH"),
    level3_dirs = NULL,
    md_files = c("Capture History Report .md", "CJS_report.md"),
    additional_mds = list(RI_CHN = c("Cumul_surv.md"), RI_STH = c("Cumul_surv.md"))) {
  #' Create nested directory structure with markdown files
  #'
  #' Creates a nested directory structure at multiple levels with specified
  #' markdown files in the innermost directories. Highly flexible for creating
  #' various nested structures.
  #'
  #' @param base_path Character string specifying where to create the structure.
  #'        Can be absolute or relative to the working directory.
  #'
  #' @param outer_folder Character string specifying the name of the outer folder.
  #'        Default: "tagger_effects". The structure will be created at
  #'        base_path/outer_folder.
  #'
  #' @param level1_dirs Character vector of level 1 directory names.
  #'        Default: c("POOLED", "TAGGER A", "TAGGER B", "TAGGER C")
  #'
  #' @param level2_dirs Character vector of level 2 directory names.
  #'        Default: c("PR_CHN", "PR_STH", "RI_CHN", "RI_STH")
  #'
  #' @param level3_dirs Character vector of level 3 directory names (if you want
  #'        an additional nesting level). Default: NULL (no third level).
  #'        If provided, md_files will be created in level 3 directories.
  #'
  #' @param md_files Character vector of markdown file names to create in each
  #'        leaf directory. Default: c("Capture History Report .md", "CJS_report.md")
  #'
  #' @param additional_mds Named list mapping level2 directory names to character
  #'        vectors of additional markdown files. For example:
  #'        list(RI_CHN = c("Cumul_surv.md"), RI_STH = c("Cumul_surv.md"))
  #'        Default adds Cumul_surv.md to RI_CHN and RI_STH directories.
  #'        Set to NULL or an empty list to disable this feature.
  #'
  #' @return A data frame with columns:
  #'   - path: path created or already existing
  #'   - type: "directory" or "file"
  #'   - action: what action was taken ("created", "already exists")
  #'
  #' @examples
  #' \dontrun{
  #'   # Default: creates the standard tagger_effects structure
  #'   make_dirs_mds_for_pasting("./output")
  #'
  #'   # Custom directories and files
  #'   make_dirs_mds_for_pasting(
  #'     "./output",
  #'     level1_dirs = c("Site A", "Site B"),
  #'     level2_dirs = c("Spring", "Summer", "Fall"),
  #'     md_files = c("summary.md", "details.md"),
  #'     additional_mds = list(Spring = c("notes.md"), Summer = c("report.md"))
  #'   )
  #' }

  if (!dir.exists(base_path)) {
    stop(sprintf("Base path does not exist: %s", base_path))
  }

  root_dir <- file.path(base_path, outer_folder)

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

  # Determine if we have a 3-level structure
  has_level3 <- !is.null(level3_dirs) && length(level3_dirs) > 0

  # Create level 1 directories and their contents
  for (l1_dir in level1_dirs) {
    l1_path <- file.path(root_dir, l1_dir)

    # Create level 1 directory
    if (!dir.exists(l1_path)) {
      dir.create(l1_path)
      results[[length(results) + 1]] <- data.frame(
        path = l1_path,
        type = "directory",
        action = "created",
        stringsAsFactors = FALSE
      )
    } else {
      results[[length(results) + 1]] <- data.frame(
        path = l1_path,
        type = "directory",
        action = "already exists",
        stringsAsFactors = FALSE
      )
    }

    # Create level 2 directories
    for (l2_dir in level2_dirs) {
      l2_path <- file.path(l1_path, l2_dir)

      # Create level 2 directory
      if (!dir.exists(l2_path)) {
        dir.create(l2_path)
        results[[length(results) + 1]] <- data.frame(
          path = l2_path,
          type = "directory",
          action = "created",
          stringsAsFactors = FALSE
        )
      } else {
        results[[length(results) + 1]] <- data.frame(
          path = l2_path,
          type = "directory",
          action = "already exists",
          stringsAsFactors = FALSE
        )
      }

      # If we have a 3rd level, create those directories
      if (has_level3) {
        for (l3_dir in level3_dirs) {
          l3_path <- file.path(l2_path, l3_dir)

          # Create level 3 directory
          if (!dir.exists(l3_path)) {
            dir.create(l3_path)
            results[[length(results) + 1]] <- data.frame(
              path = l3_path,
              type = "directory",
              action = "created",
              stringsAsFactors = FALSE
            )
          } else {
            results[[length(results) + 1]] <- data.frame(
              path = l3_path,
              type = "directory",
              action = "already exists",
              stringsAsFactors = FALSE
            )
          }

          # Create markdown files in level 3 directories
          results <- create_md_in_dir(l3_path, md_files, l3_dir, additional_mds, results)
        }
      } else {
        # Create markdown files in level 2 directories
        results <- create_md_in_dir(l2_path, md_files, l2_dir, additional_mds, results)
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

# Helper function to create markdown files in a directory
create_md_in_dir <- function(dir_path, md_files, dir_name, additional_mds, results) {
  # Create standard markdown files
  for (file_name in md_files) {
    file_path <- file.path(dir_path, file_name)
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

  # Create additional markdown files if specified for this directory
  if (!is.null(additional_mds) && dir_name %in% names(additional_mds)) {
    for (file_name in additional_mds[[dir_name]]) {
      file_path <- file.path(dir_path, file_name)
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
  }

  return(results)
}
