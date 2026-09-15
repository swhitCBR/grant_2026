library(dplyr)
library(openxlsx)

# Source the preprocessing function
source("preprocess_for_tagpro.R")

# Paths are relative to the assumption_checking/ working directory
raw_data_dir <- "../data/Round 2"
tagpro_dir <- file.path(raw_data_dir, "for tagpro")

# Run preprocessing with updated river_km for Rock Island Tailrace
result <- preprocess_for_tagpro(
  raw_data_dir = raw_data_dir,
  output_dir = tagpro_dir,
  fix_river_km_by_location = c(
    "Rock Island Tailrace" = 246.001 + 103,
    "Priest Rapids Tailrace" = 246.0015
  ),
  write_files = TRUE
)

# Make processed dataframes available in the environment
tags_tagpro <- result$tags_tagpro
nodes_tagpro <- result$nodes_tagpro
events_tagpro <- result$events_tagpro
tags_required_cols <- result$tags_required_cols
nodes_required_cols <- result$nodes_required_cols
events_required_cols <- result$events_required_cols
