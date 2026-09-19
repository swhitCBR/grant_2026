# Function to summarize blank markdown files by group
summarize_blank_mds <- function(folder_path, recursive = TRUE, all = FALSE) {
  #' Summarize blank markdown files by group
  #'
  #' Recursively scans a folder for .md files and creates a summary table
  #' showing which groups (directories) have blank files and how many.
  #'
  #' @param folder_path Character string specifying the path to the folder to scan.
  #'        Can be absolute or relative to the working directory.
  #' @param recursive Logical. If TRUE (default), searches all subdirectories.
  #'        If FALSE, only searches the top level.
  #' @param all Logical. If FALSE (default), shows only rows where non_blanks
  #'        equals totals (all files are blank). If TRUE, shows the full table.
  #'
  #' @return A data frame with columns:
  #'   - level1: the first-level directory name (e.g., "POOLED", "TAGGER A")
  #'   - level2: the second-level directory name (e.g., "PR_CHN", "RI_STH")
  #'   - blanks: count of blank .md files
  #'   - non_blanks: count of non-blank .md files
  #'   - total: total number of .md files in that group
  #'
  #' @examples
  #' \dontrun{
  #'   summarize_blank_mds("assumption_checking/round_3/tagger_effects")
  #' }

  if (!dir.exists(folder_path)) {
    stop(sprintf("Folder does not exist: %s", folder_path))
  }

  md_files <- list.files(
    path = folder_path,
    pattern = "\\.md$",
    full.names = TRUE,
    recursive = recursive
  )

  if (length(md_files) == 0) {
    message(sprintf("No .md files found in: %s", folder_path))
    return(data.frame(
      level1 = character(),
      level2 = character(),
      blanks = integer(),
      non_blanks = integer(),
      total = integer()
    ))
  }

  # Create a data frame with file info
  file_info <- data.frame(
    full_path = md_files,
    file_size = file.info(md_files)$size,
    stringsAsFactors = FALSE
  )

  # Extract the group (parent directory) from each file
  file_info$group <- sapply(file_info$full_path, function(path) {
    dirname(path)
  })

  # Extract level1 and level2 directory names
  file_info$level2 <- sapply(file_info$group, function(path) {
    basename(path)
  })

  file_info$level1 <- sapply(file_info$group, function(path) {
    basename(dirname(path))
  })

  # Determine if each file is blank
  file_info$is_blank <- file_info$file_size == 0

  # Summarize by group using base R
  groups <- unique(file_info$group)
  summary_list <- lapply(groups, function(g) {
    group_files <- file_info[file_info$group == g, ]
    total <- nrow(group_files)
    blank <- sum(group_files$is_blank)
    non_blank <- total - blank

    # Get level1 and level2 names from the group files
    level1 <- unique(group_files$level1)[1]
    level2 <- unique(group_files$level2)[1]

    data.frame(
      level1 = level1,
      level2 = level2,
      blanks = blank,
      non_blanks = non_blank,
      total = total,
      stringsAsFactors = FALSE
    )
  })

  summary_df <- do.call(rbind, summary_list)
  rownames(summary_df) <- NULL

  # Sort by level1 then level2 for readability
  summary_df <- summary_df[order(summary_df$level1, summary_df$level2), ]
  rownames(summary_df) <- NULL

  # Filter to only rows where all files are blank if all = FALSE
  if (!all) {
    summary_df_display <- summary_df[summary_df$non_blanks == 0, ]
  } else {
    summary_df_display <- summary_df
  }

  # Print summary table
  if (!all) {
    cat("\n=== Groups with All Blank Files ===\n\n")
  } else {
    cat("\n=== Blank Markdown Files Summary by Group ===\n\n")
  }
  print(summary_df_display)

  cat("\n")
  total_groups <- nrow(summary_df)
  groups_with_blanks <- sum(summary_df$blanks > 0)
  total_blank_files <- sum(summary_df$blanks)
  total_md_files <- sum(summary_df$total)

  cat(sprintf("Total groups: %d\n", total_groups))
  cat(sprintf("Groups with blank files: %d\n", groups_with_blanks))
  cat(sprintf("Blank / Non-blank files: %d / %d (%.1f%% blank)\n\n",
              total_blank_files, total_md_files - total_blank_files,
              100 * total_blank_files / total_md_files))

  invisible(summary_df)
}
