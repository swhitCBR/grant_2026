# Load pre-processed TagPro data from pre_tagpro folder
library(dplyr)

# Define paths to pre_tagpro CSV files
pre_tagpro_dir <- "data/clean/pre_tagpro"

# Load CSV files
tags <- read.csv(file.path(pre_tagpro_dir, "tags.csv"))
events <- read.csv(file.path(pre_tagpro_dir, "events.csv"))
nodes <- read.csv(file.path(pre_tagpro_dir, "nodes.csv"))

# Display basic information
cat("Tags loaded:\n")
cat(sprintf("  Rows: %d, Columns: %d\n", nrow(tags), ncol(tags)))
cat(sprintf("  Column names: %s\n", paste(names(tags), collapse = ", ")))

cat("\nEvents loaded:\n")
cat(sprintf("  Rows: %d, Columns: %d\n", nrow(events), ncol(events)))
cat(sprintf("  Column names: %s\n", paste(names(events), collapse = ", ")))

cat("\nNodes loaded:\n")
cat(sprintf("  Rows: %d, Columns: %d\n", nrow(nodes), ncol(nodes)))
cat(sprintf("  Column names: %s\n", paste(names(nodes), collapse = ", ")))

# Examine first few rows
cat("\n=== First few rows of tags ===\n")
head(tags)

cat("\n=== First few rows of events ===\n")
head(events)

cat("\n=== First few rows of nodes ===\n")
head(nodes)

events[events$tag_code=="G72B4A509",]


events |> filter(tag_code=="G72B4A509")
events |> filter(tag_code=="G72790346") |> left_join(nodes, by = "node_code") |> left_join(tags, by = "tag_code") |> arrange(river_km)
events |> filter(tag_code=="G72B4A509") |> left_join(nodes, by = "node_code") |> left_join(tags, by = "tag_code") |> arrange(river_km)


eventsDF_censA <- events |> filter(tag_code=="G72790346") |> left_join(nodes, by = "node_code") |> left_join(tags, by = "tag_code") |> arrange(river_km)


# eventsDF_censA$last_datetimeeventsDF_censA$first_datetime
# ============================================================================
# Plot detection time intervals by location
# ============================================================================

source("R/plot_detection_intervals.R")
source("R/plot_detection_intervals_comparison.R")

# Plot full dataset
plot_detection_intervals(eventsDF_censA)

# Plot side-by-side comparison: full vs. excluding extreme outliers
plot_detection_intervals_comparison(eventsDF_censA, exclude_node_codes = c(305, 306))

# ============================================================================
# Compute time differences between first and last detections
# ============================================================================

eventsDF_censA_time_diff <- eventsDF_censA |>
  mutate(
    first_dt = as.POSIXct(first_datetime),
    last_dt = as.POSIXct(last_datetime),
    time_diff = difftime(last_dt, first_dt, units = "mins")
  ) |>
  select(tag_code, node_code, location, river_km, first_datetime, last_datetime, time_diff) |>
  arrange(river_km)

eventsDF_censA_time_diff



brz_sel_atlas <- read.csv(file.path(atlas_dir, "RI_BRZsel_ATLAS.csv"), 
                           header = FALSE) 
names(brz_sel_atlas) <- c("release_spp", "num1", "tag_code", "release_time", 
                          "detection_time", "site_name", "num2", "lst_dt")
brz_sel_atlas |> filter(tag_code=="G72790346")




# Load all_sites ATLAS files (if needed for comparison)
ri_all_sites_atlas <- read.csv(file.path(atlas_dir, "RI_all_sites_ATLAS.csv"), 
                                header = FALSE)
names(ri_all_sites_atlas) <- c("release_spp", "num1", "tag_code", "release_time", 
                               "detection_time", "site_name", "num2", "lst_dt")

cat("\nRI All Sites ATLAS file loaded:\n")
cat(sprintf("  Rows: %d, Columns: %d\n", nrow(ri_all_sites_atlas), ncol(ri_all_sites_atlas)))
cat(sprintf("  Unique sites: %d\n", n_distinct(ri_all_sites_atlas$site_name)))
brz_sel_atlas |> filter(tag_code=="G72790346")




# # ============================================================================
# # Load post-TagPro ATLAS file for BRZsel
# # ============================================================================

# atlas_dir <- "data/clean/post_tagpro"

# # Load BRZsel ATLAS file
# brz_sel_atlas <- read.csv(file.path(atlas_dir, "RI_BRZsel_ATLAS.csv"), 
#                            header = FALSE)

# View(brz_sel_atlas)

# # Set column names based on ATLAS format
# names(brz_sel_atlas) <- c("release_spp", "num1", "tag_code", "release_time", 
#                           "detection_time", "site_name", "num2", "lst_dt")

# cat("\nBRZsel ATLAS file loaded:\n")
# cat(sprintf("  Rows: %d, Columns: %d\n", nrow(brz_sel_atlas), ncol(brz_sel_atlas)))
# cat(sprintf("  Column names: %s\n", paste(names(brz_sel_atlas), collapse = ", ")))

# cat("\nUnique sites in BRZsel ATLAS:\n")
# print(table(brz_sel_atlas$site_name))

# cat("\n=== First few rows of BRZsel ATLAS ===\n")
# head(brz_sel_atlas, 10)


