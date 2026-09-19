#' Generate QAQC contingency tables and detection histories
#'
#' Comprehensive script that generates all QAQC contingency tables and detection
#' history summaries, then renders Quarto reports.
#'
#' This script combines:
#' - 02_batched_comp_and_qmd_creation.R: Contingency table generation and part 1 Quarto report
#' - 05_DH_repID_summ_tbs_and_qmd_comp.R: Detection history summaries and part 2 Quarto report
#'
#' Prerequisites: Run data_cleaning/01_create_tag_subsets.R first to generate tag_subsets_ls.rds

library(dplyr)
library(ggplot2) 
library(tidyr)
library(quarto)

# Set working directory to top-level repo directory
if(getwd() != "c:/repos/grant_2026"){
  setwd("c:/repos/grant_2026")}

# ============================================================================
# Load required helper functions and data
# ============================================================================

source("R/get_rel_loc_by_repID_tabs.R")
source("R/build_tag_subsets.R")
source("R/get_conting_tabs.R")
source("R/append_to_qmd_etc.R")
source("R/get_tagger_rel_loc_status_tb_ls.R")
source("R/get_DH_tag_code_summ.R")

source("R/create_qmd_template.R")
source("R/create_qmd_templates_dir.R")
source("R/get_conting_tbs_qmd_els.R")
source("R/add_DH_qsec3_elwise.R")
source("R/append_DH_tabs_qmd.R")

# Load tag subsets created by data_cleaning/01_create_tag_subsets.R
tag_subsets_ls <- readRDS("data/clean/tag_subsets_ls.rds")

# Load raw data for detection history analysis
csv_fl_ls <- readRDS("data/clean/csv_fl_ls.rds")
events_dat <- csv_fl_ls$GPUD2026_events_17Aug2026
node_dat <- csv_fl_ls$GPUD2026_nodes_12Aug2026

# Reconstruct derived data from subsets for downstream analysis
tags_dat_raw_wrepID <- tag_subsets_ls[["RAW"]]
tags_dat_ALIVE_EUTH_wrepID <- tags_dat_raw_wrepID |> 
  filter(fish_status %in% c("Alive","Euthanized"))

# ============================================================================
# PART 1: Generate contingency table summaries for part 1 Quarto report
# ============================================================================

# Generate tagger summaries by release location and replicate
tags_dat_raw_tagger_summ <- tag_rel_tagger_summ_tb(tags_dat_wrepID_in = tag_subsets_ls[["RAW"]])
tags_dat_ALIVE_EUTH_tagger_summ <- tag_rel_tagger_summ_tb(tags_dat_wrepID_in = tag_subsets_ls[["tags_SURVUSE_AND_ALIVE_or_EUTH"]])
tags_dat_ALIVE_or_EUTH_tagger_summ <- tag_rel_tagger_summ_tb(tags_dat_wrepID_in = tag_subsets_ls[["tags_ALIVE_or_EUTH"]])

# Generate tagger-replicate-status summaries
tags_dat_raw_tagger_relID_summ_ls <- get_tagger_rel_loc_status_tb_ls(tags_dat_wrepID_in = tag_subsets_ls[["RAW"]])
tags_dat_ALIVE_EUTH_tagger_relID_summ_ls <- get_tagger_rel_loc_status_tb_ls(tags_dat_wrepID_in = tag_subsets_ls[["tags_SURVUSE_AND_ALIVE_or_EUTH"]])

# Generate replicate summaries by release location
rel_loc_by_repID_tabs <- get_rel_loc_by_repID_tabs(tags_dat_raw_wrepID)

# ============================================================================
# Create Quarto templates for report generation
# ============================================================================

create_qmd_templates_dir(output_dir = "QAQC/qmd_templates", overwrite = TRUE)

# Generate contingency table summaries
get_conting_tbs_qmd_els(tab_subset_nm = "RAW", overwrite = TRUE)
get_conting_tbs_qmd_els(tab_subset_nm = "tags_SURVUSE_OR_EUTH_&_ACTIVE")
get_conting_tbs_qmd_els(tab_subset_nm = "tags_ALIVE_ACTIVE_OTHER_OR_EUTH_ACTIVE_OTHER")

# Render part 1 Quarto report
quarto_render("QAQC/SW_QAQC_tabs_1_2.qmd")

cat("✓ Part 1 Quarto report (SW_QAQC_tabs_1_2.qmd) generated\n")

# ============================================================================
# PART 2: Generate detection history summaries for part 2 Quarto report
# ============================================================================
tag_DH_ls <-  readRDS("data/clean/tag_DH_ls.rds")


cat("✓ Detection history summaries generated and saved\n")

# Generate detection history tables for each tag subset (similar to contingency tables)
# Each call specifies which tag_DH_ls items to use for Rock Island and Priest Rapids
append_DH_tabs_qmd(tag_subset_nm = "RAW", 
                   tag_DH_ls_nm_RI = "raw_RI_summ", 
                   tag_DH_ls_nm_PR = "raw_PR_summ", 
                   overwrite = TRUE)
append_DH_tabs_qmd(tag_subset_nm = "tags_SURVUSE_OR_EUTH_&_ACTIVE",
                   tag_DH_ls_nm_RI = "SU_E_ACT_RI_summ",
                   tag_DH_ls_nm_PR = "SU_E_ACT_PR_summ")
append_DH_tabs_qmd(tag_subset_nm = "tags_ALIVE_ACTIVE_OTHER_OR_EUTH_ACTIVE_OTHER",
                   tag_DH_ls_nm_RI = "AE_RI_summ",
                   tag_DH_ls_nm_PR = "AE_PR_summ")

# Render part 2 Quarto report
quarto_render("QAQC/SW_QAQC_tabs_2_2.qmd")

cat("✓ Part 2 Quarto report (SW_QAQC_tabs_2_2.qmd) generated\n")

# ============================================================================
# Summary
# ============================================================================

cat("\n")
cat("════════════════════════════════════════════════════════════\n")
cat("QAQC Table Generation Complete\n")
cat("════════════════════════════════════════════════════════════\n")
cat("✓ Part 1 (Contingency Tables): SW_QAQC_tabs_1_2.docx\n")
cat("✓ Part 2 (Detection Histories): SW_QAQC_tabs_2_2.docx\n")
cat("════════════════════════════════════════════════════════════\n")
