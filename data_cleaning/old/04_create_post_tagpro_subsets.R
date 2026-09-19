#' Create TagPro output subsets by tagger
#'
#' Reads processed TagPro files from data/clean/pre_tagpro/ and creates subsets
#' by tagger (A, B, C), saving each to data/clean/post_tagpro/
#'
#' Prerequisites:
#'   - Run 03_pre_tagpro_runscript.R first to generate processed TagPro files

if(getwd() != "c:/repos/grant_2026"){
  setwd("c:/repos/grant_2026")}

library(dplyr)

# ============================================================================
# Load processed TagPro files and ATLAS files
# ============================================================================

tags_tagpro <- read.csv("data/clean/pre_tagpro/tags.csv", stringsAsFactors = FALSE)
events_tagpro <- read.csv("data/clean/pre_tagpro/events.csv", stringsAsFactors = FALSE)
nodes_tagpro <- read.csv("data/clean/pre_tagpro/nodes.csv", stringsAsFactors = FALSE)

cat("Loaded processed TagPro files:\n")
cat("  Tags:", nrow(tags_tagpro), "rows\n")
cat("  Events:", nrow(events_tagpro), "rows\n")
cat("  Nodes:", nrow(nodes_tagpro), "rows\n\n")

# Load ATLAS files (no headers)
init_tagger_atlas <- read.csv("data/clean/post_tagpro/init_tagger_assumpt_ATLAS.csv", 
                              header = FALSE, stringsAsFactors = FALSE)
pr_init_runs_atlas <- read.csv("data/clean/post_tagpro/PR_init_runs_ATLAS.csv", 
                               header = FALSE, stringsAsFactors = FALSE)

cat("Loaded ATLAS files:\n")
cat("  init_tagger_assumpt_ATLAS.csv:", nrow(init_tagger_atlas), "rows\n")
cat("  PR_init_runs_ATLAS.csv:", nrow(pr_init_runs_atlas), "rows\n\n")

# The third column (V3) contains tag_code
# Create a mapping of tag_code to tagger_name
tag_to_tagger <- tags_tagpro |> 
  select(tag_code, tagger_name) |> 
  rename(V3 = tag_code, tagger = tagger_name)

# ============================================================================
# Create output directory
# ============================================================================

output_dir <- "data/clean/post_tagpro"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

cat("Output directory:", output_dir, "\n\n")

# ============================================================================
# Get unique taggers and create subsets
# ============================================================================

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
  
  # Create filenames with tagger suffix (ATLAS files only)
  suffix <- paste0("_tagger_", tagger)
  
  # Filter ATLAS files by tag_code (V3 column) and write
  init_tagger_subset <- init_tagger_atlas |> 
    filter(V3 %in% tag_codes)
  init_tagger_file <- file.path(output_dir, paste0("init_tagger_assumpt_ATLAS", suffix, ".csv"))
  write.table(
    init_tagger_subset,
    init_tagger_file,
    row.names = FALSE, col.names = FALSE, sep = ",", quote = FALSE
  )
  
  pr_init_runs_subset <- pr_init_runs_atlas |> 
    filter(V3 %in% tag_codes)
  pr_init_runs_file <- file.path(output_dir, paste0("PR_init_runs_ATLAS", suffix, ".csv"))
  write.table(
    pr_init_runs_subset,
    pr_init_runs_file,
    row.names = FALSE, col.names = FALSE, sep = ",", quote = FALSE
  )
  
  cat("  ✓ Saved ATLAS files with suffix:", suffix, "\n")
  cat("    init_tagger_assumpt_ATLAS:", nrow(init_tagger_subset), "rows\n")
  cat("    PR_init_runs_ATLAS:", nrow(pr_init_runs_subset), "rows\n")
  cat("    (Tags:", nrow(tags_subset), "| Events:", nrow(events_subset), 
      "| Nodes:", nrow(nodes_subset), ")\n\n")
}

cat("════════════════════════════════════════════════════════════\n")
cat("Post-TagPro subset creation complete!\n")
cat("Output directory: ", output_dir, "\n")
cat("════════════════════════════════════════════════════════════\n")


# # 
# ################################################## #
# # Create post-TagPro subsets by tagger
# # ################################################## #

# cat("\n════════════════════════════════════════════════════════════\n")
# cat("CREATING POST-TAGPRO SUBSETS BY TAGGER\n")
# cat("════════════════════════════════════════════════════════════\n\n")

# # Source the function
# source("R/create_post_tagpro_subsets.R")

# # Find all ATLAS CSV files in the post_tagpro directory
# atlas_dir <- "data/clean/post_tagpro"
# if (!dir.exists(atlas_dir)) {
#   dir.create(atlas_dir, recursive = TRUE)
# }

# # Find all ATLAS CSV files (excluding those with tagger suffix already applied)
# atlas_files_list <- list.files(
#   atlas_dir,
#   pattern = "_ATLAS\\.csv$",
#   full.names = TRUE
# )

# # Filter to exclude files that already have tagger suffix (but keep PR_tagger_comparison)
# atlas_files_list <- atlas_files_list[
#   !grepl("_tagger_[A-C]\\.csv$", basename(atlas_files_list))
# ]

# if (length(atlas_files_list) > 0) {
#   cat("Found", length(atlas_files_list), "ATLAS files:\n")
#   cat(paste("  -", basename(atlas_files_list), collapse = "\n"), "\n\n")
  
#   # Load ATLAS files (no headers)
#   atlas_dfs <- lapply(atlas_files_list, function(f) {
#     read.csv(f, header = FALSE, stringsAsFactors = FALSE)
#   })
  
#   # Extract base names (without _ATLAS.csv)
#   atlas_basenames <- sub("_ATLAS\\.csv$", "", basename(atlas_files_list))
  
#   cat("Loaded ATLAS files:\n")
#   for (i in seq_along(atlas_files_list)) {
#     cat("  ", atlas_basenames[i], ":", nrow(atlas_dfs[[i]]), "rows\n")
#   }
#   cat("\n")
  
#   # Create post-TagPro subsets by tagger
#   cat("Creating tagger-specific ATLAS subsets...\n\n")
  
#   post_tagpro_result <- create_post_tagpro_subsets(
#     tags_df = tags_tagpro,
#     events_df = events_tagpro,
#     nodes_df = nodes_tagpro,
#     atlas_files = atlas_dfs,
#     atlas_file_names = atlas_basenames,
#     output_dir = atlas_dir
#   )
  
#   # Display summary of created files
#   cat("\nFile Creation Summary:\n")
#   print(post_tagpro_result$summary)
  
# } else {
#   cat("No ATLAS CSV files found in", atlas_dir, "\n")
#   cat("Skipping post-TagPro subset creation.\n")
#   cat("(ATLAS files will be needed from TagPro output)\n\n")
# }

