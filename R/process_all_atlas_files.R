#' Process all ATLAS files by creating tagger subsets
#'
#' Finds all ATLAS CSV files in a directory that don't contain "tagger" in the 
#' filename and creates tagger-level subdivisions for each.
#'
#' @param atlas_dir Character. Directory containing ATLAS files to process.
#'   Defaults to "data/clean/post_tagpro".
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
#'
#' @keywords assumption_check
#' @export

process_all_atlas_files <- function(atlas_dir = "data/clean/post_tagpro",
                                    output_dir = "data/clean/post_tagpro",
                                    tags_file = "data/clean/pre_tagpro/tags.csv",
                                    events_file = "data/clean/pre_tagpro/events.csv",
                                    nodes_file = "data/clean/pre_tagpro/nodes.csv") {
  
  # Find all ATLAS files that don't have "tagger" in the name
  all_files <- list.files(atlas_dir, pattern = "_ATLAS\\.csv$", full.names = TRUE)
  atlas_files <- all_files[!grepl("tagger", all_files, ignore.case = TRUE)]
  
  if (length(atlas_files) == 0) {
    cat("No ATLAS files found in", atlas_dir, "\n")
    return(invisible(NULL))
  }
  
  cat("\n════════════════════════════════════════════════════════════\n")
  cat("Found", length(atlas_files), "ATLAS file(s) to process:\n")
  cat(paste("  -", basename(atlas_files), collapse = "\n"), "\n\n")
  
  # Process each ATLAS file
  for (atlas_file in atlas_files) {
    create_atlas_tagger_subsets(
      atlas_file_path = atlas_file,
      output_dir = output_dir,
      tags_file = tags_file,
      events_file = events_file,
      nodes_file = nodes_file
    )
  }
  
  cat("\n════════════════════════════════════════════════════════════\n")
  cat("Post-TagPro subset creation complete!\n")
  cat("════════════════════════════════════════════════════════════\n")
  invisible(NULL)
}
