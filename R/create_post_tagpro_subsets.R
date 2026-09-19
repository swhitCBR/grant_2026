#' Create TagPro output subsets by tagger from ATLAS files
#'
#' Reads processed TagPro files and ATLAS files, creates subsets by tagger,
#' and saves tagger-specific ATLAS files to output directory.
#'
#' @param tags_df Data frame with processed tags from TagPro preprocessing.
#'   Must contain columns: tag_code, tagger_name
#' @param events_df Data frame with processed events from TagPro preprocessing.
#'   Must contain columns: tag_code, node_code
#' @param nodes_df Data frame with processed nodes from TagPro preprocessing.
#'   Must contain columns: node_code
#' @param atlas_files List of ATLAS data frames. Each element should have 
#'   tag_code in the third column (V3). 
#'   Example: list(init_tagger = df1, pr_init_runs = df2, pr_comparison = df3)
#' @param atlas_file_names Character vector of ATLAS base names (without extension).
#'   These are used to construct output filenames.
#'   Example: c("init_tagger_assumpt_ATLAS", "PR_init_runs_ATLAS", "PR_tagger_comparison_ATLAS")
#' @param output_dir Output directory for tagger-specific ATLAS files.
#'   Default: "data/clean/post_tagpro"
#'
#' @return Invisibly returns a list with:
#'   - created_files: vector of created file paths
#'   - summary: data frame with file creation summary
#'
#' @details
#' This function processes ATLAS files by filtering them to include only rows
#' where the tag_code (V3 column) belongs to each tagger. Output files are named
#' with the pattern: {basename}_tagger_{tagger}.csv
#'
#' @export
create_post_tagpro_subsets <- function(
    tags_df,
    events_df,
    nodes_df,
    atlas_files,
    atlas_file_names,
    output_dir = "data/clean/post_tagpro") {
  
  # Validate inputs ----
  stopifnot(
    is.data.frame(tags_df),
    is.data.frame(events_df),
    is.data.frame(nodes_df),
    is.list(atlas_files),
    is.character(atlas_file_names),
    length(atlas_files) == length(atlas_file_names),
    "tag_code" %in% colnames(tags_df),
    "tagger_name" %in% colnames(tags_df),
    "tag_code" %in% colnames(events_df),
    "node_code" %in% colnames(events_df),
    "node_code" %in% colnames(nodes_df)
  )
  
  # Create output directory ----
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  cat("Output directory:", output_dir, "\n\n")
  
  # Get unique taggers ----
  taggers <- sort(unique(tags_df$tagger_name))
  cat("Taggers found:", paste(taggers, collapse = ", "), "\n\n")
  
  # Store file creation summary
  file_summary <- data.frame(
    tagger = character(),
    atlas_file = character(),
    n_rows = integer(),
    n_tags = integer(),
    n_events = integer(),
    n_nodes = integer(),
    output_file = character(),
    stringsAsFactors = FALSE
  )
  
  created_files <- character()
  
  # Create subsets for each tagger ----
  for (tagger in taggers) {
    cat("Processing tagger:", tagger, "\n")
    
    # Filter tags by tagger
    tags_subset <- tags_df |> dplyr::filter(tagger_name == tagger)
    tag_codes <- unique(tags_subset$tag_code)
    
    # Filter events and nodes
    events_subset <- events_df |> dplyr::filter(tag_code %in% tag_codes)
    node_codes <- unique(events_subset$node_code)
    nodes_subset <- nodes_df |> dplyr::filter(node_code %in% node_codes)
    
    # Create suffix for output files
    suffix <- paste0("_tagger_", tagger)
    
    # Process each ATLAS file
    for (i in seq_along(atlas_files)) {
      atlas_df <- atlas_files[[i]]
      atlas_basename <- atlas_file_names[i]
      
      # Validate that ATLAS file has V3 column
      if (!"V3" %in% colnames(atlas_df)) {
        warning("ATLAS file ", atlas_basename, " does not have V3 column. Skipping.")
        next
      }
      
      # Filter ATLAS by tag codes
      atlas_subset <- atlas_df |> dplyr::filter(V3 %in% tag_codes)
      
      # Create output filename
      output_file <- file.path(output_dir, paste0(atlas_basename, suffix, ".csv"))
      
      # Write subset
      utils::write.table(
        atlas_subset,
        output_file,
        row.names = FALSE,
        col.names = FALSE,
        sep = ",",
        quote = FALSE
      )
      
      created_files <- c(created_files, output_file)
      
      # Add to summary
      file_summary <- rbind(
        file_summary,
        data.frame(
          tagger = tagger,
          atlas_file = atlas_basename,
          n_rows = nrow(atlas_subset),
          n_tags = length(unique(tags_subset$tag_code)),
          n_events = nrow(events_subset),
          n_nodes = nrow(nodes_subset),
          output_file = basename(output_file),
          stringsAsFactors = FALSE
        )
      )
      
      cat("  ✓", atlas_basename, ":", nrow(atlas_subset), "rows ->", basename(output_file), "\n")
    }
    
    cat("    (Tags:", nrow(tags_subset), "| Events:", nrow(events_subset), 
        "| Nodes:", nrow(nodes_subset), ")\n\n")
  }
  
  cat("════════════════════════════════════════════════════════════\n")
  cat("Post-TagPro subset creation complete!\n")
  cat("Created", length(created_files), "files in:", output_dir, "\n")
  cat("════════════════════════════════════════════════════════════\n")
  
  # Return invisibly
  invisible(list(
    created_files = created_files,
    summary = file_summary
  ))
}
