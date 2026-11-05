# Plots and tables that were made in advance of taglife curve fitting and the creation of mixing plots
# used to be in data_cleaning/04_summarize_w_qmd_fun.r


#' Generate summary tables for tags_SURVUSE_OR_EUTH_&_ACTIVE subset
#'
#' Executes all tabulate functions on the "tags_SURVUSE_OR_EUTH_&_ACTIVE" tag
#' subset sequentially and saves results to a named list. This script generates
#' contingency tables and detection history summaries for downstream analysis.
#'
#' Prerequisites: Run data_cleaning/01_load_csvs.R, 02_create_tag_subsets.R,
#' and 03_create_DH_from_tag_subsets.R first.

library(dplyr)
library(tidyr)

# Working directory: must be the repo root
# (no setwd needed; run from repo root via grant_2026.Rproj or run_pipeline.R)

# ============================================================================
# Load required helper functions
# ============================================================================

source("R/get_rel_loc_by_repID_tabs.R")
source("R/get_conting_tabs.R")
source("R/get_tagger_rel_loc_status_tb_ls.R")
source("R/get_DH_tag_code_summ.R")
source("R/plot_DH_by_repID.R")

# ============================================================================
# Load required data
# ============================================================================

# Load tag subsets created by data_cleaning/02_create_tag_subsets.R
tag_subsets_ls <- readRDS("data/clean/tag_subsets_ls.rds")

# Load raw data for detection history analysis
csv_fl_ls <- readRDS("data/clean/csv_fl_ls.rds")
events_dat <- csv_fl_ls$GPUD2026_events_17Aug2026
node_dat <- csv_fl_ls$GPUD2026_nodes_12Aug2026

# Load tag detection history list created by data_cleaning/03_create_DH_from_tag_subsets.R
tag_DH_ls <- readRDS("data/clean/tag_DH_ls.rds")

# ============================================================================
# Extract the tags_SURVUSE_OR_EUTH_&_ACTIVE subset
# ============================================================================

tags_dat_SURVUSE_OR_EUTH_ACTIVE <- tag_subsets_ls[["tags_SURVUSE_OR_EUTH_&_ACTIVE"]]

cat("Processing tags_SURVUSE_OR_EUTH_&_ACTIVE subset\n")
cat("Number of tags:", nrow(tags_dat_SURVUSE_OR_EUTH_ACTIVE), "\n\n")

# ============================================================================
# Execute tabulate functions sequentially and store results
# ============================================================================

summary_results_ls <- list()

# 1. Generate contingency tables
cat("1. Generating contingency tables...\n")
summary_results_ls[["conting_tabs"]] <- get_conting_tabs(tags_dat_SURVUSE_OR_EUTH_ACTIVE)
cat("   ✓ Generated", length(summary_results_ls[["conting_tabs"]]), "contingency tables\n\n")

# 2. Generate tagger summary
cat("2. Generating tagger summary...\n")
summary_results_ls[["tagger_summ"]] <- tag_rel_tagger_summ_tb(tags_dat_wrepID_in = tags_dat_SURVUSE_OR_EUTH_ACTIVE)
cat("   ✓ Dimensions:", nrow(summary_results_ls[["tagger_summ"]]), "rows x", ncol(summary_results_ls[["tagger_summ"]]), "columns\n\n")

# 3. Generate tagger/location/status summaries
cat("3. Generating tagger/location/status summaries...\n")
summary_results_ls[["tagger_loc_status_ls"]] <- get_tagger_rel_loc_status_tb_ls(tags_dat_wrepID_in = tags_dat_SURVUSE_OR_EUTH_ACTIVE)
cat("   ✓ Generated", length(summary_results_ls[["tagger_loc_status_ls"]]), "sub-tables\n\n")

# 4. Generate release location by replicate summaries
cat("4. Generating release location by replicate summaries...\n")
summary_results_ls[["rel_loc_by_repID"]] <- get_rel_loc_by_repID_tabs(tags_dat_SURVUSE_OR_EUTH_ACTIVE)
cat("   ✓ Generated", length(summary_results_ls[["rel_loc_by_repID"]]), "location summaries\n\n")

# 5. Generate detection history summaries
cat("5. Generating detection history summaries...\n")
summary_results_ls[["DH_summ"]] <- get_DH_tag_code_summ(
  node_dat_in = node_dat,
  events_dat_in = events_dat,
  tags_dat_wrepID_in = tags_dat_SURVUSE_OR_EUTH_ACTIVE
)
cat("   ✓ Dimensions:", nrow(summary_results_ls[["DH_summ"]]), "rows x", ncol(summary_results_ls[["DH_summ"]]), "columns\n\n")

# ============================================================================
# Summary
# ============================================================================

cat("════════════════════════════════════════════════════════════\n")
cat("Summary Table Generation Complete\n")
cat("════════════════════════════════════════════════════════════\n")
cat("Results saved to: summary_results_ls\n")
cat("List elements:\n")
for (i in seq_along(summary_results_ls)) {
  cat(" $", names(summary_results_ls)[i], "\n", sep = "")
}
cat("════════════════════════════════════════════════════════════\n\n")

# ============================================================================
# Generate visualizations
# ============================================================================

# cat("Generating visualizations...\n\n")
# 
# # Generate detection history tile plots
# cat("Creating detection history plots by replicate ID...\n")
# DH_plots <- plot_DH_by_repID(summary_results_ls, node_dat_in = node_dat)
# cat("✓ Generated", length(DH_plots), "detection history plots\n\n")
# 
# # Display first plot
# if (length(DH_plots) > 0) {
#   cat("Displaying first plot:\n")
#   print(DH_plots[[1]])
# }

# ============================================================================
# Save results to RDS file
# ============================================================================

output_path <- "data/clean/summary_results_SURVUSE_OR_EUTH_ACTIVE.rds"
saveRDS(summary_results_ls, output_path)
cat("\nSaved to:", output_path, "\n")


names(summary_results_ls)

# ============================================================================
# Summarize time from tag activation and release to detection at the
# lowermost detection site (Rock Island Tailrace releases only)
# ============================================================================

source("R/get_time_to_lowermost_detect_summ.R")
source("R/plot_time_to_lowermost_detect.R")

cat("Generating time-to-lowermost-detection summary...\n")
time_to_lowermost_detect_summ <- get_time_to_lowermost_detect_summ(
  tags_dat_wrepID_in = tags_dat_SURVUSE_OR_EUTH_ACTIVE,
  events_dat_in = events_dat,
  node_dat_in = node_dat
)
time_to_lowermost_detect_summ

cat("Generating time-to-lowermost-detection histograms and ECDFs...\n")
time_to_lowermost_detect_plots <- plot_time_to_lowermost_detect(
  tags_dat_wrepID_in = tags_dat_SURVUSE_OR_EUTH_ACTIVE,
  events_dat_in = events_dat,
  node_dat_in = node_dat
)

library(gridExtra)
grid.arrange(
  time_to_lowermost_detect_plots$hist_activate_to_detect,
  time_to_lowermost_detect_plots$hist_release_to_detect,
  time_to_lowermost_detect_plots$ecdf_activate_to_detect,
  time_to_lowermost_detect_plots$ecdf_release_to_detect)

# ============================================================================
# Summarize maximum activation-to-detection time by each tag's lowermost
# detected site (i.e. the furthest downstream site it actually reached)
# ============================================================================

source("R/get_max_time_by_lowermost_site_summ.R")

cat("Generating max activation-to-detection time by lowermost detected site...\n")
max_time_by_lowermost_site_summ <- get_max_time_by_lowermost_site_summ(
  tags_dat_wrepID_in = tags_dat_SURVUSE_OR_EUTH_ACTIVE,
  events_dat_in = events_dat,
  node_dat_in = node_dat
)
max_time_by_lowermost_site_summ

cat("Generating max activation-to-detection time histogram by lowermost detected site...\n")
source("R/plot_max_time_by_lowermost_site.R")
max_time_by_lowermost_site_hist <- plot_max_time_by_lowermost_site(
  tags_dat_wrepID_in = tags_dat_SURVUSE_OR_EUTH_ACTIVE,
  events_dat_in = events_dat,
  node_dat_in = node_dat
)
max_time_by_lowermost_site_hist

cat("Generating max activation-to-detection time ECDF by lowermost detected site...\n")
source("R/plot_max_time_by_lowermost_site_ecdf.R")
max_time_by_lowermost_site_ecdf <- plot_max_time_by_lowermost_site_ecdf(
  tags_dat_wrepID_in = tags_dat_SURVUSE_OR_EUTH_ACTIVE,
  events_dat_in = events_dat,
  node_dat_in = node_dat
)
max_time_by_lowermost_site_ecdf

ggsave(
  "media/png/max_time_by_lowermost_site_ecdf.png",
  plot = max_time_by_lowermost_site_ecdf,
  width = 8, height = 5, dpi = 300
)

cat("Generating cumulative count plot by lowermost detected site...\n")
source("R/plot_cumulative_count_by_lowermost_site.R")
cumulative_count_by_lowermost_site <- plot_cumulative_count_by_lowermost_site(
  tags_dat_wrepID_in = tags_dat_SURVUSE_OR_EUTH_ACTIVE,
  events_dat_in = events_dat,
  node_dat_in = node_dat
)
cumulative_count_by_lowermost_site

ggsave(
  "media/png/cumulative_count_by_lowermost_site.png",
  plot = cumulative_count_by_lowermost_site,
  width = 8, height = 5, dpi = 300
)

