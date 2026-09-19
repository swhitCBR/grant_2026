library(dplyr)
library(openxlsx)

# Set working directory to project root if not already there
if (!dir.exists("data_cleaning")) {
  setwd("c:/repos/grant_2026")
}

################################################## #
# Source the preprocessing function from R/
# ################################################## #

source("R/preprocess_for_tagpro.R")

################################################## #
# Load data from data_cleaning pipeline
# ################################################## #

# source("C:/repos/grant_2026/data_cleaning/02_create_tag_subsets.R")

csv_fl_ls <- readRDS("data/clean/csv_fl_ls.rds")
tag_subsets_ls <- readRDS("data/clean/tag_subsets_ls.rds")

tags_raw <- csv_fl_ls$GPUD2026_tags_17Aug2026
events_raw <- csv_fl_ls$GPUD2026_events_17Aug2026
nodes_raw <- csv_fl_ls$GPUD2026_nodes_12Aug2026

cat("Data loaded from data/clean//n")
cat("Tags:", nrow(tags_raw), "rows/n")
cat("Events:", nrow(events_raw), "rows/n")
cat("Nodes:", nrow(nodes_raw), "rows/n/n")

cat("Available tag subsets:/n")
cat(paste(" -", names(tag_subsets_ls), collapse = "/n"), "/n/n")

# DEFAULT: Process this subset
# subset_name <- "tags_SURVUSE_OR_ALIVE_or_EUTH" #BAD OLD
subset_name <- "tags_SURVUSE_OR_EUTH_&_ACTIVE"
# subset_name <- "tags_SURVUSE"


cat("Processing tag subset:", subset_name, "/n")
cat("Number of tags:", nrow(tag_subsets_ls[[subset_name]]), "/n")

# Function to filter events and nodes by tag subset
filter_events_nodes <- function(tag_subset, events_raw, nodes_raw) {
  subset_tag_codes <- unique(tag_subset$tag_code)
  events_subset <- events_raw |> filter(tag_code %in% subset_tag_codes)
  node_codes_in_events <- unique(events_subset$node_code)
  nodes_subset <- nodes_raw |> filter(node_code %in% node_codes_in_events)
  return(list(tags = tag_subset, events = events_subset, nodes = nodes_subset))
}

# Filter events and nodes for the selected subset
subset_data <- filter_events_nodes(
  tag_subsets_ls[[subset_name]], 
  events_raw, 
  nodes_raw
)

cat("Number of events:", nrow(subset_data$events), "/n")
cat("Number of nodes:", nrow(subset_data$nodes), "/n/n")

# Create output directory for pre-tagpro CSVs
pre_tagpro_csv_dir <- "data/clean/pre_tagpro"
if (!dir.exists(pre_tagpro_csv_dir)) {
  dir.create(pre_tagpro_csv_dir, recursive = TRUE)
}

# Write subset CSVs to data/clean/pre_tagpro/
write.csv(subset_data$tags, file.path(pre_tagpro_csv_dir, "tags.csv"), row.names = FALSE)
write.csv(subset_data$events, file.path(pre_tagpro_csv_dir, "events.csv"), row.names = FALSE)
write.csv(subset_data$nodes, file.path(pre_tagpro_csv_dir, "nodes.csv"), row.names = FALSE)

cat("Subset CSVs saved to:", pre_tagpro_csv_dir, "/n/n")

# Set output directory for processed TagPro data
output_dir <- "data/clean/pre_tagpro"

# Run preprocessing with river_km lookup
cat("Running TagPro preprocessing.../n")
result <- preprocess_for_tagpro(
  raw_data_dir = pre_tagpro_csv_dir,
  output_dir = output_dir,
  fix_river_km_by_location = c(
    "Rock Island Tailrace" = 730,
    "Priest Rapids Tailrace" = 246.0015
  ),
  write_files = TRUE
)

################################################## #
# Extract results and make available in environment
# ################################################## #

tags_tagpro <- result$tags_tagpro
nodes_tagpro <- result$nodes_tagpro
events_tagpro <- result$events_tagpro
tags_required_cols <- result$tags_required_cols
nodes_required_cols <- result$nodes_required_cols
events_required_cols <- result$events_required_cols

head(tags_tagpro)

table(tags_tagpro$tagger,tags_tagpro$fish_status)
table(tags_tagpro$tagger[tags_tagpro$species_code=="CHN"],tags_tagpro$release_location[tags_tagpro$species_code=="CHN"])
table(tags_tagpro$tagger[tags_tagpro$species_code=="STH"],tags_tagpro$release_location[tags_tagpro$species_code=="STH"])


tags_tagpro |> group_by(species_code,tagger,fish_status,release_location) |> summarize(n=length(unique(tag_code))) |> filter(fish_status=="Euthanized")
tags_tagpro |> group_by(species_code,tagger,fish_status,release_location) |>
  summarize(n=length(unique(tag_code))) |> filter(fish_status!="Euthanized") |> 
  tidyr::pivot_wider(names_from=release_location,values_from=n)# |> split(species_code)

