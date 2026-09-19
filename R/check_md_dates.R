# Function to check markdown files and report last modified dates
check_md_dates <- function(folder_path, recursive = TRUE) {
  #' Check markdown files and report last modified dates
  #'
  #' Recursively scans a folder for .md files and displays the directory tree
  #' diagram with blank file indicators, followed by a summary table showing
  #' file information including last modified date.
  #'
  #' @param folder_path Character string specifying the path to the folder to scan.
  #'        Can be absolute or relative to the working directory.
  #' @param recursive Logical. If TRUE (default), searches all subdirectories.
  #'        If FALSE, only searches the top level.
  #'
  #' @return A data frame with columns:
  #'   - file: filename
  #'   - relative_path: path relative to the start folder
  #'   - file_size: size in bytes
  #'   - is_blank: logical, TRUE if file is empty
  #'   - last_modified: POSIXct datetime of last modification
  #'   - modified_date_str: formatted date string (YYYY-MM-DD HH:MM:SS)
  #'
  #' @examples
  #' \dontrun{
  #'   check_md_dates("assumption_checking/round_3/tagger_effects")
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

  # Print directory tree with blank indicators
  cat("\n=== Directory Structure ===\n\n")
  tree_output <- tree_structure(folder_path)
  cat(tree_output)

  # Create results data frame with file information
  results <- lapply(md_files, function(file) {
    file_info <- file.info(file)
    file_size <- file_info$size
    last_mod <- file_info$mtime

    is_blank <- is.na(file_size) || file_size == 0

    # Get relative path
    relative_path <- sub(
      paste0("^", gsub("\\\\", "\\\\\\\\", folder_path), "[/\\\\]?"),
      "",
      file
    )

    data.frame(
      file = basename(file),
      relative_path = dirname(relative_path),
      file_size = file_size,
      is_blank = is_blank,
      last_modified = last_mod,
      modified_date_str = format(last_mod, "%Y-%m-%d %H:%M:%S"),
      stringsAsFactors = FALSE
    )
  })

  result_df <- do.call(rbind, results)
  rownames(result_df) <- NULL

  # Print summary table
  cat("\n=== File Details ===\n\n")
  display_df <- result_df[, c("file", "relative_path", "file_size", "is_blank", "modified_date_str")]
  colnames(display_df) <- c("file", "path", "size", "blank", "last_modified")
  print(display_df)

  invisible(result_df)
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
