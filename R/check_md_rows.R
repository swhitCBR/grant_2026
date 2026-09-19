# Function to check for markdown files that only have titles
check_md_rows <- function(folder_path, recursive = TRUE) {
  #' Check for markdown files with only titles
  #'
  #' Recursively scans a folder for .md files and identifies which ones contain
  #' only markdown headings (titles) with no actual content. Returns a summary
  #' of the directory structure and highlights files with only titles.
  #'
  #' @param folder_path Character string specifying the path to the folder to scan.
  #'        Can be absolute or relative to the working directory.
  #' @param recursive Logical. If TRUE (default), searches all subdirectories.
  #'        If FALSE, only searches the top level.
  #'
  #' @return A list with two elements:
  #'   - directory_tree: Character vector showing the nested folder structure
  #'   - files_summary: Data frame with columns:
  #'       * relative_path: path relative to the start folder
  #'       * file: filename
  #'       * total_lines: total number of lines
  #'       * non_empty_rows: count of non-empty lines
  #'       * has_headings: logical, does file contain markdown headings
  #'       * has_content: logical, does file have non-heading content
  #'       * only_titles: logical, TRUE if file only has headings and no content
  #'
  #' @examples
  #' \dontrun{
  #'   check_md_rows("assumption_checking/round_3/tagger_effects")
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
    return(NULL)
  }

  results <- lapply(md_files, function(file) {
    lines <- readLines(file, warn = FALSE)
    total_lines <- length(lines)
    non_empty_rows <- sum(nzchar(trimws(lines)))

    # Check for markdown headings (lines starting with #)
    heading_lines <- grepl("^\\s*#+\\s", lines)
    has_headings <- any(heading_lines)
    num_headings <- sum(heading_lines)

    # Content is non-heading, non-empty lines
    non_heading_content <- !heading_lines & nzchar(trimws(lines))
    has_content <- any(non_heading_content)

    # "Only titles" means has headings but no other meaningful content
    only_titles <- has_headings && !has_content

    # Get relative path
    relative_path <- sub(
      paste0("^", gsub("\\\\", "\\\\\\\\", folder_path), "[/\\\\]?"),
      "",
      file
    )

    data.frame(
      relative_path = dirname(relative_path),
      file = basename(file),
      total_lines = total_lines,
      non_empty_rows = non_empty_rows,
      has_headings = has_headings,
      num_headings = num_headings,
      has_content = has_content,
      only_titles = only_titles,
      stringsAsFactors = FALSE
    )
  })

  result_df <- do.call(rbind, results)
  rownames(result_df) <- NULL

  # Print directory tree
  cat("\n=== Directory Structure ===\n\n")
  tree_output <- tree_structure(folder_path)
  cat(tree_output)

  cat("\n=== Files with Only Titles ===\n\n")
  only_titles_df <- result_df[result_df$only_titles, ]
  if (nrow(only_titles_df) > 0) {
    for (i in seq_len(nrow(only_titles_df))) {
      full_path <- file.path(only_titles_df$relative_path[i], only_titles_df$file[i])
      cat(sprintf("  %s\n", full_path))
    }
  } else {
    cat("  None found - all files have content beyond titles.\n")
  }

  invisible(list(
    files_summary = result_df,
    files_with_only_titles = only_titles_df
  ))
}

# Helper function to print directory tree with blank file indicator
tree_structure <- function(folder_path, prefix = "", is_last = TRUE) {
  entries <- list.files(folder_path, full.names = FALSE, all.files = FALSE)
  entries <- entries[order(entries)]

  output <- ""
  for (i in seq_along(entries)) {
    entry <- entries[i]
    full_path <- file.path(folder_path, entry)
    is_last_entry <- (i == length(entries))

    connector <- ifelse(is_last_entry, "└── ", "├── ")
    
    # Check if it's a file and if it's blank (0 bytes or only whitespace)
    if (!dir.exists(full_path)) {
      file_size <- file.info(full_path)$size
      is_blank <- is.na(file_size) || file_size == 0
      
      # Add indicator for blank files
      blank_indicator <- if (is_blank) " [BLANK]" else ""
      output <- paste0(output, prefix, connector, entry, blank_indicator, "\n")
    } else {
      output <- paste0(output, prefix, connector, entry, "\n")
      extension <- ifelse(is_last_entry, "    ", "│   ")
      output <- paste0(output, tree_structure(full_path, paste0(prefix, extension), is_last_entry))
    }
  }

  return(output)
}
