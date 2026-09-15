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

if(getwd() != "c:/repos/grant_2026/QAQC"){
  setwd("c:/repos/grant_2026/QAQC")}

# ============================================================================
# Load required helper functions and data
# ============================================================================

source("R/get_rel_loc_by_repID_tabs.R")
source("R/build_tag_subsets.R")
source("R/get_conting_tabs.R")
source("R/append_to_qmd_etc.R")
source("R/get_tagger_rel_loc_status_tb_ls.R")
source("R/get_DH_tag_code_summ.R")

# Load tag subsets created by data_cleaning/01_create_tag_subsets.R
tag_subsets_ls <- readRDS("../data/clean/tag_subsets_ls.rds")

# Load raw data for detection history analysis
csv_fl_ls <- readRDS("../data/clean/csv_fl_ls.rds")
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

#' Function: append_conting_tabs_qmd
#'
#' Appends contingency tables to the part 1 Quarto report (SW_QAQC_tabs_1_2.qmd)
#' for a specified tag subset
append_conting_tabs_qmd <- function(tab_subset_nm="RAW"){
  unlink("SW_QAQC_tabs_1_2.qmd")
  file.copy("templates/qmd/SW_QAQC_tabs_1_2_template.qmd", "SW_QAQC_tabs_1_2.qmd")

  # top matter
  append_to_qmd("SW_QAQC_tabs_1_2.qmd",'\n{{< pagebreak >}}\n')
  if(tab_subset_nm=="RAW"){
    append_to_qmd("SW_QAQC_tabs_1_2.qmd",'# Summaries for all tags in the full data set (unfiltered)')
  } else{
    append_to_qmd("SW_QAQC_tabs_1_2.qmd",paste0('# Summaries for all tags in the `',tab_subset_nm,'` subset'))
  }

  append_to_qmd("SW_QAQC_tabs_1_2.qmd",'Includes "Tarmac" and "Mortality" groups (i.e., fish dropped on the ground and that died during handing, respectively)')
  append_to_qmd("SW_QAQC_tabs_1_2.qmd", "\n## Contingency Tables\n")

  append_to_qmd("SW_QAQC_tabs_1_2.qmd", add_qsec3(header_in="Live/Dead Status vs. Survival_use",tb_nm_in="usable_CT_tab",tag_sub_nm=tab_subset_nm))
  append_to_qmd("SW_QAQC_tabs_1_2.qmd", add_qsec3(header_in="Live/Dead Status vs. Tagger",tb_nm_in="fish_status_tagger_CT_tab",tag_sub_nm=tab_subset_nm))

  append_to_qmd("SW_QAQC_tabs_1_2.qmd", add_qsec3(header_in="Release location vs. tagger",tb_nm_in="RL_tagger_CT_tab",tag_sub_nm=tab_subset_nm))
  append_to_qmd("SW_QAQC_tabs_1_2.qmd", add_qsec3(header_in="Release Location vs. Release Type",tb_nm_in="RL_helicopter_CT_tab",tag_sub_nm=tab_subset_nm))

  append_to_qmd("SW_QAQC_tabs_1_2.qmd", add_qsec3(header_in="Tag lot vs. Tagger",tb_nm_in="lot_tagger_CT_tab",tag_sub_nm=tab_subset_nm))
  append_to_qmd("SW_QAQC_tabs_1_2.qmd", add_qsec3(header_in="Tag lot vs. Release location",tb_nm_in="lot_RL_CT_tab",tag_sub_nm=tab_subset_nm))

  append_to_qmd("SW_QAQC_tabs_1_2.qmd",'\n#### Rock Island\n')
  append_to_qmd("SW_QAQC_tabs_1_2.qmd", add_qsec3_elwise(header_in="CHN",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "CHN.Rock Island Tailrace"))
  append_to_qmd("SW_QAQC_tabs_1_2.qmd", add_qsec3_elwise(header_in="STH",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "STH.Rock Island Tailrace"))
  append_to_qmd("SW_QAQC_tabs_1_2.qmd",'\n#### Priest Rapids\n')
  append_to_qmd("SW_QAQC_tabs_1_2.qmd", add_qsec3_elwise(header_in="CHN",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "CHN.Priest Rapids Tailrace"))
  append_to_qmd("SW_QAQC_tabs_1_2.qmd", add_qsec3_elwise(header_in="STH",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "STH.Priest Rapids Tailrace"))

  append_to_qmd("SW_QAQC_tabs_1_2.qmd", add_qsec3(header_in="Replicate vs. Tagger",tb_nm_in="repID_tagger_CT_tab",tag_sub_nm=tab_subset_nm))
  append_to_qmd("SW_QAQC_tabs_1_2.qmd", add_qsec3(header_in="Replicate vs. Release location",tb_nm_in="repID_RL_CT_tab",tag_sub_nm=tab_subset_nm))

  append_to_qmd("SW_QAQC_tabs_1_2.qmd", add_qsec3(header_in="Fish released by location, status, and tagger",tb_nm_in="tags_dat_raw_tagger_summ",tag_sub_nm=tab_subset_nm,header_level = "##"))
  append_to_qmd("SW_QAQC_tabs_1_2.qmd",'\n### Chinook\n')
  append_to_qmd("SW_QAQC_tabs_1_2.qmd", add_qsec3_elwise(header_in="Live fish",tb_nm_in="tags_dat_raw_tagger_relID_summ_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "CHN_live",header_level = "####"))
  append_to_qmd("SW_QAQC_tabs_1_2.qmd", add_qsec3_elwise(header_in="Dead fish",tb_nm_in="tags_dat_raw_tagger_relID_summ_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "CHN_dead",header_level = "####"))
  append_to_qmd("SW_QAQC_tabs_1_2.qmd",'\n### Steelhead\n')
  append_to_qmd("SW_QAQC_tabs_1_2.qmd", add_qsec3_elwise(header_in="Live fish",tb_nm_in="tags_dat_raw_tagger_relID_summ_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "STH_live",header_level = "####"))
  append_to_qmd("SW_QAQC_tabs_1_2.qmd", add_qsec3_elwise(header_in="Dead fish",tb_nm_in="tags_dat_raw_tagger_relID_summ_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "STH_dead",header_level = "####"))

  append_to_qmd("SW_QAQC_tabs_1_2.qmd",'\n{{< pagebreak >}}\n')
  
  append_to_qmd("SW_QAQC_tabs_1_2.qmd",'\n## Fish Released by Location, Replicate, and Status\n')
  append_to_qmd("SW_QAQC_tabs_1_2.qmd",'\nRock Island and Priest Rapids are abbreviated and the "_d" refers to release of "Euthanized" fish\n')
  append_to_qmd("SW_QAQC_tabs_1_2.qmd", add_qsec3_elwise(header_in="CHN",tb_nm_in="rel_loc_by_repID_tabs",tag_sub_nm=tab_subset_nm,ele_nm_in = "CHN",header_level = "####"))
  append_to_qmd("SW_QAQC_tabs_1_2.qmd", add_qsec3_elwise(header_in="STH",tb_nm_in="rel_loc_by_repID_tabs",tag_sub_nm=tab_subset_nm,ele_nm_in = "STH",header_level = "####"))

  return(NULL) 
}

# Generate contingency tables and create part 1 Quarto report
unlink("SW_QAQC_tabs_1_2.qmd")
file.copy("templates/qmd/SW_QAQC_tabs_1_2_template.qmd", "SW_QAQC_tabs_1_2.qmd")
append_conting_tabs_qmd(tab_subset_nm = "RAW")
append_conting_tabs_qmd(tab_subset_nm = "tags_SURVUSE_OR_EUTH_&_ACTIVE")
append_conting_tabs_qmd(tab_subset_nm = "tags_ALIVE_ACTIVE_OTHER_OR_EUTH_ACTIVE_OTHER")

# Render part 1 Quarto report
quarto_render("SW_QAQC_tabs_1_2.qmd")

cat("✓ Part 1 Quarto report (SW_QAQC_tabs_1_2.qmd) generated\n")

# ============================================================================
# PART 2: Generate detection history summaries for part 2 Quarto report
# ============================================================================

# Calculate detection history summaries for each tag subset
tag_SU_EUTH_ACTIVE_DH_summ <- get_DH_tag_code_summ(
  node_dat_in = node_dat,
  events_dat_in = events_dat,
  tags_dat_wrepID_in = tag_subsets_ls[["tags_SURVUSE_OR_EUTH_&_ACTIVE"]]
)

tag_ALIVE_EUTH_DH_summ <- get_DH_tag_code_summ(
  node_dat_in = node_dat,
  events_dat_in = events_dat,
  tags_dat_wrepID_in = tag_subsets_ls[["tags_ALIVE_or_EUTH"]]
)

tag_raw_DH_summ <- get_DH_tag_code_summ(
  node_dat_in = node_dat,
  events_dat_in = events_dat,
  tags_dat_wrepID_in = tag_subsets_ls[["RAW"]]
)

# Standardize column names and abbreviate release locations
tag_raw_DH_summ <- tag_raw_DH_summ |> 
  rename(rel_loc = release_location,
         status = fish_status,
         CBAR = Crescent.Bar,
         WAN = Wanapum,
         WAN.BRZ = Wanapum.BRZ,
         WAN.TR = Wanapum.Tailrace,
         WB = White.Bluffs,
         HAN = Hanford,
         VRBR = Vernita.Bridge,
         PR.TR = Priest.Tailrace,
         PR.BRZ = Priest.BRZ,
         MATT = Mattawa,
         SUN = Sunland,
         LRNG = Lower.Ringold,
         PR = Priest) |>
  mutate(rel_loc = ifelse(rel_loc == "Rock Island Tailrace", "RI", "PR"))

tag_ALIVE_EUTH_DH_summ <- tag_ALIVE_EUTH_DH_summ |> 
  rename(rel_loc = release_location,
         status = fish_status,
         CBAR = Crescent.Bar,
         WAN = Wanapum,
         WAN.BRZ = Wanapum.BRZ,
         WB = White.Bluffs,
         HAN = Hanford,
         VRBR = Vernita.Bridge,
         PR.TR = Priest.Tailrace,
         PR.BRZ = Priest.BRZ,
         MATT = Mattawa,
         SUN = Sunland,
         LRNG = Lower.Ringold,
         PR = Priest) |>
  mutate(rel_loc = ifelse(rel_loc == "Rock Island Tailrace", "RI", "PR"))

tag_SU_EUTH_ACTIVE_DH_summ <- tag_SU_EUTH_ACTIVE_DH_summ |>
  rename(rel_loc = release_location,
         status = fish_status,
         CBAR = Crescent.Bar,
         WAN = Wanapum,
         WAN.BRZ = Wanapum.BRZ,
         WB = White.Bluffs,
         HAN = Hanford,
         VRBR = Vernita.Bridge,
         PR.TR = Priest.Tailrace,
         PR.BRZ = Priest.BRZ,
         MATT = Mattawa,
         SUN = Sunland,
         LRNG = Lower.Ringold,
         PR = Priest) |>
  mutate(rel_loc = ifelse(rel_loc == "Rock Island Tailrace", "RI", "PR"))

# Filter detection history summaries by release location
SU_E_ACT_RI_summ <- tag_SU_EUTH_ACTIVE_DH_summ |> filter(rel_loc == "RI")
SU_E_ACT_PR_summ <- tag_SU_EUTH_ACTIVE_DH_summ |> filter(rel_loc == "PR")

AE_RI_summ <- tag_ALIVE_EUTH_DH_summ |> filter(rel_loc == "RI")
AE_PR_summ <- tag_ALIVE_EUTH_DH_summ |> filter(rel_loc == "PR")

raw_RI_summ <- tag_raw_DH_summ |> filter(rel_loc == "RI")
raw_PR_summ <- tag_raw_DH_summ |> filter(rel_loc == "PR")

# Create list of all detection history summaries
tag_DH_ls <- list(
  "SU_E_ACT_RI_summ" = SU_E_ACT_RI_summ,
  "SU_E_ACT_PR_summ" = SU_E_ACT_PR_summ,
  "raw_RI_summ" = raw_RI_summ,
  "raw_PR_summ" = raw_PR_summ
)

# Save detection history list for use in Quarto reports
saveRDS(tag_DH_ls, "../data/clean/tag_DH_ls.rds")

cat("✓ Detection history summaries generated and saved\n")

#' Function: add_DH_qsec3_elwise
#'
#' Generates Quarto code block for a detection history table filtered by species and status
add_DH_qsec3_elwise <- function(tag_DH_ls_nm_in = "raw_RI_summ",
                                header_in,
                                spp_in,
                                status_in,
                                header_level,
                                status_is = TRUE) {
  c(
    paste(header_level, header_in),
    "```{r,echo=F,eval=T}",
    if(status_is) {
      paste0("knitr::kable(tag_DH_ls$'", tag_DH_ls_nm_in, "' |> filter(spp=='", spp_in, "' & status=='", status_in, "'))")
    } else {
      paste0("knitr::kable(tag_DH_ls$'", tag_DH_ls_nm_in, "' |> filter(spp=='", spp_in, "' & status!='", status_in, "'))")
    },
    "```"
  )
}

#' Function: append_DH_tabs_qmd
#'
#' Appends detection history tables to the part 2 Quarto report (SW_QAQC_tabs_2_2.qmd)
append_DH_tabs_qmd <- function(tab_subset_nm = "RAW") {
  unlink("SW_QAQC_tabs_2_2.qmd")
  file.copy("templates/qmd/SW_QAQC_tabs_2_2_template.qmd", "SW_QAQC_tabs_2_2.qmd")
  
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "\n{{< pagebreak >}}\n")
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "# Detection Histories for All Tags")
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "\n## Live Fish\n")
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "\n### Chinook\n")
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", add_DH_qsec3_elwise(header_in = "Rock Island Release", spp_in = "CHN", status_in = "Alive", header_level = "####", tag_DH_ls_nm_in = "raw_RI_summ"))
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", add_DH_qsec3_elwise(header_in = "Priest Rapids Release", spp_in = "CHN", status_in = "Alive", header_level = "####", tag_DH_ls_nm_in = "raw_PR_summ"))
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "{{< pagebreak >}}")
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "\n### Steelhead\n")
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", add_DH_qsec3_elwise(header_in = "Rock Island Release", spp_in = "STH", status_in = "Alive", header_level = "####", tag_DH_ls_nm_in = "raw_RI_summ"))
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", add_DH_qsec3_elwise(header_in = "Priest Rapids Release", spp_in = "STH", status_in = "Alive", header_level = "####", tag_DH_ls_nm_in = "raw_PR_summ"))
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "{{< pagebreak >}}")
  
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "\n## Dead Fish\n")
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "\n### Chinook\n")
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", add_DH_qsec3_elwise(header_in = "Rock Island Release", spp_in = "CHN", status_in = "Alive", header_level = "####", status_is = FALSE, tag_DH_ls_nm_in = "raw_RI_summ"))
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", add_DH_qsec3_elwise(header_in = "Priest Rapids Release", spp_in = "CHN", status_in = "Alive", header_level = "####", status_is = FALSE, tag_DH_ls_nm_in = "raw_PR_summ"))
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "{{< pagebreak >}}")
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "\n### Steelhead\n")
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", add_DH_qsec3_elwise(header_in = "Rock Island Release", spp_in = "STH", status_in = "Alive", header_level = "####", status_is = FALSE, tag_DH_ls_nm_in = "raw_RI_summ"))
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", add_DH_qsec3_elwise(header_in = "Priest Rapids Release", spp_in = "STH", status_in = "Alive", header_level = "####", status_is = FALSE, tag_DH_ls_nm_in = "raw_PR_summ"))
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "{{< pagebreak >}}")
  
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "\n# Detection Histories for `tags_SURVUSE_OR_EUTH_&_ACTIVE`")
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "\n## Live Fish\n")
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "\n### Chinook\n")
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", add_DH_qsec3_elwise(header_in = "Rock Island Release", spp_in = "CHN", status_in = "Alive", header_level = "####", tag_DH_ls_nm_in = "SU_E_ACT_RI_summ"))
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", add_DH_qsec3_elwise(header_in = "Priest Rapids Release", spp_in = "CHN", status_in = "Alive", header_level = "####", tag_DH_ls_nm_in = "SU_E_ACT_PR_summ"))
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "{{< pagebreak >}}")
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "\n### Steelhead\n")
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", add_DH_qsec3_elwise(header_in = "Rock Island Release", spp_in = "STH", status_in = "Alive", header_level = "####", tag_DH_ls_nm_in = "SU_E_ACT_RI_summ"))
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", add_DH_qsec3_elwise(header_in = "Priest Rapids Release", spp_in = "STH", status_in = "Alive", header_level = "####", tag_DH_ls_nm_in = "SU_E_ACT_PR_summ"))
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "{{< pagebreak >}}")
  
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "\n## Dead Fish\n")
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "\n### Chinook\n")
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", add_DH_qsec3_elwise(header_in = "Rock Island Release", spp_in = "CHN", status_in = "Alive", header_level = "####", status_is = FALSE, tag_DH_ls_nm_in = "SU_E_ACT_RI_summ"))
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", add_DH_qsec3_elwise(header_in = "Priest Rapids Release", spp_in = "CHN", status_in = "Alive", header_level = "####", status_is = FALSE, tag_DH_ls_nm_in = "SU_E_ACT_PR_summ"))
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "{{< pagebreak >}}")
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", "\n### Steelhead\n")
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", add_DH_qsec3_elwise(header_in = "Rock Island Release", spp_in = "STH", status_in = "Alive", header_level = "####", status_is = FALSE, tag_DH_ls_nm_in = "SU_E_ACT_RI_summ"))
  append_to_qmd("SW_QAQC_tabs_2_2.qmd", add_DH_qsec3_elwise(header_in = "Priest Rapids Release", spp_in = "STH", status_in = "Alive", header_level = "####", status_is = FALSE, tag_DH_ls_nm_in = "SU_E_ACT_PR_summ"))

  return(NULL)
}

# Generate detection history tables and create part 2 Quarto report
append_DH_tabs_qmd()
quarto_render("SW_QAQC_tabs_2_2.qmd")

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
