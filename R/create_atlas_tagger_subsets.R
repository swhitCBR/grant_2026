#' Create tagger subsets from ATLAS file
#'
#' Processes ATLAS files and creates subsets by tagger, saving each 
#' to a specified output directory.
#'
#' @param atlas_file_path Character. Path to the ATLAS CSV file to process.
#' @param output_dir Character. Directory where output files will be saved.
#'   Defaults to "data/clean/post_tagpro".
#' @param tags_file Character. Path to tags CSV file. 
#'   Defaults to "data/clean/pre_tagpro/tags.csv".
#' @param events_file Character. Path to events CSV file. 
#'   Defaults to "data/clean/pre_tagpro/events.csv".
#' @param nodes_file Character. Path to nodes CSV file. 
#'   Defaults to "data/clean/pre_tagpro/nodes.csv".
#'
#' @return NULL (invisibly). Saves filtered ATLAS files to output_dir.

create_atlas_tagger_subsets <- function(atlas_file_path, 
                                        output_dir = "data/clean/post_tagpro",
                                        tags_file = "data/clean/pre_tagpro/tags.csv",
                                        events_file = "data/clean/pre_tagpro/events.csv",
                                        nodes_file = "data/clean/pre_tagpro/nodes.csv") {
  
  library(dplyr, quietly = TRUE)
  
  # Validate input files exist
  if (!file.exists(atlas_file_path)) {
    stop("ATLAS file not found: ", atlas_file_path)
  }
  if (!file.exists(tags_file)) {
    stop("Tags file not found: ", tags_file)
  }
  if (!file.exists(events_file)) {
    stop("Events file not found: ", events_file)
  }
  if (!file.exists(nodes_file)) {
    stop("Nodes file not found: ", nodes_file)
  }
  
  # Load TagPro files
  tags_tagpro <- read.csv(tags_file, stringsAsFactors = FALSE)
  events_tagpro <- read.csv(events_file, stringsAsFactors = FALSE)
  nodes_tagpro <- read.csv(nodes_file, stringsAsFactors = FALSE)
  
  # Extract the base filename (without path and extension)
  # e.g., "RI_all_sites_ATLAS" from "/path/RI_all_sites_ATLAS.csv"
  base_name <- tools::file_path_sans_ext(basename(atlas_file_path))
  
  cat("\n════════════════════════════════════════════════════════════\n")
  cat("Processing:", base_name, "\n")
  cat("════════════════════════════════════════════════════════════\n\n")
  
  # Load ATLAS file (no headers)
  atlas_data <- read.csv(atlas_file_path, header = FALSE, stringsAsFactors = FALSE)
  cat("Loaded ATLAS file:", nrow(atlas_data), "rows\n")
  cat("Loaded TagPro files: Tags=", nrow(tags_tagpro), "| Events=", 
      nrow(events_tagpro), "| Nodes=", nrow(nodes_tagpro), "\n\n", sep = "")
  
  # Create output directory if needed
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Get unique taggers and create subsets
  taggers <- sort(unique(tags_tagpro$tagger_name))
  cat("Taggers found:", paste(taggers, collapse = ", "), "\n\n")
  
  # Create subsets for each tagger
  for (tagger in taggers) {
    cat("Processing tagger:", tagger, "\n")
    
    # Filter tags by tagger
    tags_subset <- tags_tagpro |> filter(tagger_name == tagger)
    
    # Get tag codes for this tagger
    tag_codes <- unique(tags_subset$tag_code)
    
    # Filter events by tags in this subset
    events_subset <- events_tagpro |> filter(tag_code %in% tag_codes)
    
    # Get nodes that have events from this subset
    node_codes <- unique(events_subset$node_code)
    nodes_subset <- nodes_tagpro |> filter(node_code %in% node_codes)
    
    # Create filenames with tagger suffix
    suffix <- paste0("_tagger_", tagger)
    
    # Filter ATLAS file by tag_code (V3 column) and write
    atlas_subset <- atlas_data |> 
      filter(V3 %in% tag_codes)
    
    atlas_file <- file.path(output_dir, paste0(base_name, suffix, ".csv"))
    write.table(
      atlas_subset,
      atlas_file,
      row.names = FALSE, col.names = FALSE, sep = ",", quote = FALSE
    )
    
    cat("  ✓ Saved", basename(atlas_file), "\n")
    cat("    Rows:", nrow(atlas_subset), "| Tags:", nrow(tags_subset), 
        "| Events:", nrow(events_subset), "| Nodes:", nrow(nodes_subset), "\n\n")
  }
  
  cat("✓ Completed processing:", base_name, "\n")
  invisible(NULL)
}
