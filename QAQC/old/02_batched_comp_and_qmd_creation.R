#' QAQC analysis and report generation
#'
#' Loads tag subsets created by data_cleaning/01_create_tag_subsets.R,
#' generates contingency tables, and creates Quarto report with QAQC summaries.
#'
#' Prerequisites: Run data_cleaning/01_create_tag_subsets.R first

library(dplyr)
library(ggplot2) 
library(tidyr)
library(quarto)

if(getwd() != "c:/repos/grant_2026/QAQC"){
  setwd("c:/repos/grant_2026/QAQC")}

source("R/get_rel_loc_by_repID_tabs.R")
source("R/build_tag_subsets.R")
source("R/get_conting_tabs.R")
source("R/append_to_qmd_etc.R")
source("R/get_tagger_rel_loc_status_tb_ls.R")

# Load tag subsets created by data_cleaning/01_create_tag_subsets.R
tag_subsets_ls <- readRDS("tmp_data/tag_subsets_ls.rds")

# Reconstruct tags_dat_raw_wrepID from RAW subset for downstream analysis
tags_dat_raw_wrepID <- tag_subsets_ls[["RAW"]]

tags_dat_ALIVE_EUTH_wrepID <- tags_dat_raw_wrepID |> filter(fish_status %in% c("Alive","Euthanized"))

# example extraction of contingency table
get_conting_tabs_by_name(tags_dat_in = tags_dat_raw_wrepID,tb_nm_in = "usable_CT_tab")
get_conting_tabs_by_name(tags_dat_in = tag_subsets_ls[["tags_SURVUSE_AND_ALIVE_or_EUTH"]],tb_nm_in = "usable_CT_tab")
get_conting_tabs_by_name(tags_dat_in = tag_subsets_ls[["RAW"]],tb_nm_in = "tags_dat_raw_tagger_relID_summ_ls")
get_conting_tabs_by_name(tags_dat_in = tag_subsets_ls[["RAW"]],tb_nm_in = "repID_RL_CT_tab")

tags_dat_raw_tagger_summ <- tag_rel_tagger_summ_tb(tags_dat_wrepID_in = tag_subsets_ls[["RAW"]])
tags_dat_ALIVE_EUTH_tagger_summ <- tag_rel_tagger_summ_tb(tags_dat_wrepID_in = tag_subsets_ls[["tags_SURVUSE_AND_ALIVE_or_EUTH"]])
tags_dat_ALIVE_or_EUTH_tagger_summ <- tag_rel_tagger_summ_tb(tags_dat_wrepID_in = tag_subsets_ls[["tags_ALIVE_or_EUTH"]])


tags_dat_raw_tagger_relID_summ_ls <- get_tagger_rel_loc_status_tb_ls(tags_dat_wrepID_in = tag_subsets_ls[["RAW"]])
tags_dat_ALIVE_EUTH_tagger_relID_summ_ls <- get_tagger_rel_loc_status_tb_ls(tags_dat_wrepID_in = tag_subsets_ls[["tags_SURVUSE_AND_ALIVE_or_EUTH"]])
names(tags_dat_raw_tagger_relID_summ_ls)

# get_conting_tabs_by_name(tags_dat_in = tag_subsets_ls[["RAW"]],tb_nm_in = "tags_dat_raw_tagger_relID_summ_ls")
# get_conting_tabs_by_name(tags_dat_in = tag_subsets_ls[["RAW"]],tb_nm_in = "rel_loc_by_repID_tabs")

#' Title
#'
#' @returns
#'
#' @export
#' @examples
append_conting_tabs_qmd<- function(tab_subset_nm="RAW"){
  unlink("SW_QAQC_new_summ_1_3.qmd")
  file.copy("SW_QAQC_new_summ_1_3_template.qmd", "SW_QAQC_new_summ_1_3.qmd")

  # top matter
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n{{< pagebreak >}}\n')
  if(tab_subset_nm=="RAW"){
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'# Summaries for all tags in the full data set (unfiltered)')
  } else{
      append_to_qmd("SW_QAQC_new_summ_1_3.qmd",paste0('# Summaries for all tags in the `',tab_subset_nm,'` subset'))
  }

  append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'Includes "Tarmac" and "Mortality" groups (i.e., fish dropped on the ground and that died during handing, respectively)')
  # append_to_qmd("SW_QAQC_new_summ_1_3.qmd",top_matter)
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", "\n## Contingency Tables\n")

  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Live/Dead Status vs. Survival_use",tb_nm_in="usable_CT_tab",tag_sub_nm=tab_subset_nm))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Live/Dead Status vs. Tagger",tb_nm_in="fish_status_tagger_CT_tab",tag_sub_nm=tab_subset_nm))

  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Release location vs. tagger",tb_nm_in="RL_tagger_CT_tab",tag_sub_nm=tab_subset_nm))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Release Location vs. Release Type",tb_nm_in="RL_helicopter_CT_tab",tag_sub_nm=tab_subset_nm))

  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Tag lot vs. Tagger",tb_nm_in="lot_tagger_CT_tab",tag_sub_nm=tab_subset_nm))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Tag lot vs. Release location",tb_nm_in="lot_RL_CT_tab",tag_sub_nm=tab_subset_nm))

  append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n#### Rock Island\n')
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="CHN",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "CHN.Rock Island Tailrace"))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="STH",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "STH.Rock Island Tailrace"))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n#### Priest Rapids\n')
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="CHN",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "CHN.Priest Rapids Tailrace"))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="STH",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "STH.Priest Rapids Tailrace"))

  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Replicate vs. Tagger",tb_nm_in="repID_tagger_CT_tab",tag_sub_nm=tab_subset_nm))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Replicate vs. Release location",tb_nm_in="repID_RL_CT_tab",tag_sub_nm=tab_subset_nm))

  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Fish released by location, status, and tagger",tb_nm_in="tags_dat_raw_tagger_summ",tag_sub_nm=tab_subset_nm,header_level = "##"))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n### Chinook\n')
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="Live fish",tb_nm_in="tags_dat_raw_tagger_relID_summ_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "CHN_live",header_level = "####"))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="Dead fish",tb_nm_in="tags_dat_raw_tagger_relID_summ_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "CHN_dead",header_level = "####"))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n### Steelhead\n')
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="Live fish",tb_nm_in="tags_dat_raw_tagger_relID_summ_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "STH_live",header_level = "####"))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="Dead fish",tb_nm_in="tags_dat_raw_tagger_relID_summ_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "STH_dead",header_level = "####"))

  append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n{{< pagebreak >}}\n')
  
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n## Fish Released by Location, Replicate, and Status\n')
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\nRock Island and Priest Rapids are abbreviated and the "_d" refers to release of "Euthanized" fish\n')
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="CHN",tb_nm_in="rel_loc_by_repID_tabs",tag_sub_nm=tab_subset_nm,ele_nm_in = "CHN",header_level = "####"))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="STH",tb_nm_in="rel_loc_by_repID_tabs",tag_sub_nm=tab_subset_nm,ele_nm_in = "STH",header_level = "####"))


 return(NULL) 
}


# unlink("SW_QAQC_new_summ_1_3.qmd")
# file.copy("SW_QAQC_new_summ_1_3_template.qmd", "SW_QAQC_new_summ_1_3.qmd")

append_conting_tabs_qmd<- function(tab_subset_nm="RAW"){
  # top matter
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n{{< pagebreak >}}\n')
  if(tab_subset_nm=="RAW"){
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'# Summaries for all tags in the full data set (unfiltered)')
  } else{
      append_to_qmd("SW_QAQC_new_summ_1_3.qmd",paste0('# Summaries for all tags in the `',tab_subset_nm,'` subset'))
  }

  append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'Includes "Tarmac" and "Mortality" groups (i.e., fish dropped on the ground and that died during handing, respectively)')
  # append_to_qmd("SW_QAQC_new_summ_1_3.qmd",top_matter)
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", "\n## Contingency Tables\n")

  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Live/Dead Status vs. Survival_use",tb_nm_in="usable_CT_tab",tag_sub_nm=tab_subset_nm))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Live/Dead Status vs. Tagger",tb_nm_in="fish_status_tagger_CT_tab",tag_sub_nm=tab_subset_nm))

  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Release location vs. tagger",tb_nm_in="RL_tagger_CT_tab",tag_sub_nm=tab_subset_nm))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Release Location vs. Release Type",tb_nm_in="RL_helicopter_CT_tab",tag_sub_nm=tab_subset_nm))

  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Tag lot vs. Tagger",tb_nm_in="lot_tagger_CT_tab",tag_sub_nm=tab_subset_nm))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Tag lot vs. Release location",tb_nm_in="lot_RL_CT_tab",tag_sub_nm=tab_subset_nm))

  append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n#### Rock Island\n')
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="CHN",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "CHN.Rock Island Tailrace"))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="STH",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "STH.Rock Island Tailrace"))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n#### Priest Rapids\n')
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="CHN",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "CHN.Priest Rapids Tailrace"))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="STH",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "STH.Priest Rapids Tailrace"))

  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Replicate vs. Tagger",tb_nm_in="repID_tagger_CT_tab",tag_sub_nm=tab_subset_nm))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Replicate vs. Release location",tb_nm_in="repID_RL_CT_tab",tag_sub_nm=tab_subset_nm))

  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Fish released by location, status, and tagger",tb_nm_in="tags_dat_raw_tagger_summ",tag_sub_nm=tab_subset_nm,header_level = "##"))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n### Chinook\n')
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="Live fish",tb_nm_in="tags_dat_raw_tagger_relID_summ_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "CHN_live",header_level = "####"))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="Dead fish",tb_nm_in="tags_dat_raw_tagger_relID_summ_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "CHN_dead",header_level = "####"))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n### Steelhead\n')
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="Live fish",tb_nm_in="tags_dat_raw_tagger_relID_summ_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "STH_live",header_level = "####"))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="Dead fish",tb_nm_in="tags_dat_raw_tagger_relID_summ_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "STH_dead",header_level = "####"))

  append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n{{< pagebreak >}}\n')
  
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n## Fish Released by Location, Replicate, and Status\n')
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\nRock Island and Priest Rapids are abbreviated and the "_d" refers to release of "Euthanized" fish\n')
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="CHN",tb_nm_in="rel_loc_by_repID_tabs",tag_sub_nm=tab_subset_nm,ele_nm_in = "CHN",header_level = "####"))
  append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="STH",tb_nm_in="rel_loc_by_repID_tabs",tag_sub_nm=tab_subset_nm,ele_nm_in = "STH",header_level = "####"))


 return(NULL) 
}


names(tag_subsets_ls)


# rel_loc_by_repID_tabs

unlink("SW_QAQC_new_summ_1_3.qmd")
file.copy("SW_QAQC_new_summ_1_3_template.qmd", "SW_QAQC_new_summ_1_3.qmd")
append_conting_tabs_qmd(tab_subset_nm = "RAW")
# append_conting_tabs_qmd(tab_subset_nm = "tags_ALIVE_or_EUTH")
append_conting_tabs_qmd(tab_subset_nm = "tags_SURVUSE_OR_EUTH_&_ACTIVE" )
append_conting_tabs_qmd(tab_subset_nm = "tags_ALIVE_ACTIVE_OTHER_OR_EUTH_ACTIVE_OTHER" )


quarto::quarto_render("SW_QAQC_new_summ_1_3.qmd")

# Process each tag subset
for (subset_name in c("RAW", "tags_SURVUSE_OR_EUTH_&_ACTIVE", "tags_ALIVE_ACTIVE_OTHER_OR_EUTH_ACTIVE_OTHER")) {
  append_conting_tabs_qmd(tab_subset_nm = subset_name)
}