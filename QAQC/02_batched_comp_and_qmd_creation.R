library(dplyr)
library(ggplot2) 
library(tidyr)

if(getwd() != "c:/repos/grant_2026/QAQC"){
  setwd("c:/repos/grant_2026/QAQC")}

source("R/get_rel_loc_by_repID_tabs.R")
source("R/build_tag_subsets.R")
source("R/get_conting_tabs.R")
source("R/append_to_qmd_etc.R")
source("R/get_tagger_rel_loc_status_tb_ls.R")


build_tag_subsets <- function(tags_dat_raw_wrepID, filter_strs) {
  purrr::map(
    filter_strs,
    ~ dplyr::filter(tags_dat_raw_wrepID, !!rlang::parse_expr(.x))
  )
}

csv_fl_ls <- readRDS("tmp_data/csv_fl_ls.rds")
tags_dat_raw <- csv_fl_ls$GPUD2026_tags_17Aug2026

# additional fields
tags_dat_raw$spp_code=substr(tags_dat_raw$species,start = 1,stop = 2)
tags_dat_raw$spp=ifelse(tags_dat_raw$spp_code=="11","CHN","STH")
tags_dat_raw$reartype=substr(tags_dat_raw$species,start = 3,stop = 3)
tags_dat_raw$rel_date=as.Date(substr(tags_dat_raw$tag_release_date,start = 1,stop = 10))

tags_dat_raw$release_location <- factor(tags_dat_raw$release_location,c("Rock Island Tailrace","Priest Rapids Tailrace"))

tags_dat_raw_summ <- tags_dat_raw |>  
  group_by(spp,project_code,tag_group,release_location,rel_date) |>
  summarize(n_tags=length(unique(tag_code)))

tags_dat_raw$rep_loc <- substr(tags_dat_raw$tag_AssignedRelease,1,2)
tags_dat_raw$rep_num <- as.numeric(substr(tags_dat_raw$tag_AssignedRelease,3,4))

tmp_summ <- tags_dat_raw |> group_by(spp,release_location,tag_AssignedRelease,tag_release_date) |> summarize(n_tags=length(unique(tag_code)))
tmp_summ <- tags_dat_raw |> group_by(spp,release_location,rep_loc,rep_num,tag_release_date) |> summarize(n_tags=length(unique(tag_code)))

# adding replicate IDs to traw tag data
tags_dat_raw_wrepID <- tags_dat_raw |>
  mutate(code=paste(spp,project_code,release_location,rel_date,sep="_")) 
tags_dat_raw_wrepID$repID <- tags_dat_raw_wrepID$rep_num

tmp_summ <- tags_dat_raw_wrepID |> 
  group_by(spp,release_location,rep_loc,repID,tag_release_date,survival_use) |>
  summarize(n_tags=length(unique(tag_code))) |> 
  pivot_wider(names_from = survival_use,values_from = n_tags)

# tags_dat_raw_wrepID |> 
#   group_by(spp,release_location,rep_loc,repID,rel_date,survival_use) |>
#   summarize(n_tags=length(unique(tag_code))) |> 
#   pivot_wider(names_from = c(survival_use,release_location),values_from = c(n_tags,rel_date)) 

rel_loc_by_repID_tabs <- get_rel_loc_by_repID_tabs(tags_dat_raw_wrepID)



tag_subsets_ls <- list(
  "RAW"=tags_dat_raw_wrepID,
  #old bad
  "tags_ALIVE_or_EUTH"=tags_dat_raw_wrepID |> filter(fish_status %in% c("Alive","Euthanized")),
  # not good
  "tags_SURVUSE_AND_ALIVE_or_EUTH"=tags_dat_raw_wrepID |> filter( survival_use & fish_status %in% c("Alive","Euthanized") ),
  # Corr v. (what I thought I was using)
  "tags_SURVUSE_OR_ALIVE_or_EUTH"=tags_dat_raw_wrepID |> filter( survival_use | fish_status %in% c("Alive","Euthanized") ),
  # RAB1
  "tags_SURVUSE_OR_EUTH_&_ACTIVE"=tags_dat_raw_wrepID |> filter( survival_use | (fish_status %in% c("Euthanized") & tag_status=="Active")),
  # RAB2
  "tags_ALIVE_ACTIVE_OTHER_OR_EUTH_ACTIVE_OTHER"=tags_dat_raw_wrepID |> filter( 
                                (fish_status %in% c("Alive") & tag_status=="Active" & release_type=="Other") | 
                                  (fish_status %in% c("Euthanized") & tag_status=="Active" & release_type=="Other"))
                              )
sapply(tag_subsets_ls,nrow)
nrow(tag_subsets_ls[["tags_SURVUSE_AND_ALIVE_or_EUTH"]])
table(tag_subsets_ls[["tags_SURVUSE_AND_ALIVE_or_EUTH"]]$tag_group)
table(tag_subsets_ls[["tags_SURVUSE_AND_ALIVE_or_EUTH"]]$tag_status)
table(tag_subsets_ls[["tags_SURVUSE_AND_ALIVE_or_EUTH"]]$fish_status)

# saveRDS(rel_loc_by_repID_tabs,"tmp_data/rel_loc_by_repID_tabs.rds")
# saveRDS(tags_dat_raw_wrepID,"tmp_data/tags_dat_raw_wrepID.rds")
# saveRDS(tags_dat_ALIVE_EUTH_wrepID,"tmp_data/tags_dat_ALIVE_EUTH_wrepID.rds")
saveRDS(tag_subsets_ls,"tmp_data/tag_subsets_ls.rds")

tags_dat_ALIVE_EUTH_wrepID <- tags_dat_raw_wrepID |> filter(fish_status %in% c("Alive","Euthanized"))

# example extraction of contingency table
get_conting_tabs_by_name(tags_dat_in = tags_dat_raw_wrepID,tb_nm_in = "usable_CT_tab")
get_conting_tabs_by_name(tags_dat_in = tag_subsets_ls[["tags_SURVUSE_AND_ALIVE_or_EUTH"]],tb_nm_in = "usable_CT_tab")
get_conting_tabs_by_name(tags_dat_in = tag_subsets_ls[["RAW"]],tb_nm_in = "tags_dat_raw_tagger_relID_summ_ls")
get_conting_tabs_by_name(tags_dat_in = tag_subsets_ls[["RAW"]],tb_nm_in = "repID_RL_CT_tab")

############################################ #
# from 04_tagger_rel_loc_repID_summ
############################################ #

# tags_dat_raw_wrepID <- readRDS("tmp_data/tags_dat_raw_wrepID.rds")
# tags_dat_ALIVE_EUTH_wrepID <- readRDS("tmp_data/tags_dat_ALIVE_EUTH_wrepID.rds")

# #' Title
# #'
# #' @param tags_dat_wrepID_in
# #'
# #' @returns
# #'
# #' @export
# #' @examples
# tag_rel_tagger_summ_tb <- function(tags_dat_wrepID_in){
#   out <- tags_dat_wrepID_in |>
#     group_by(spp,tag_group,release_location,tagger) |>
#     summarize(n_tags=length(unique(tag_code))) |>
#     pivot_wider(names_from = tagger,values_from = n_tags)|>
#     arrange(spp,release_location)
#   return(out)
# }

# # tagger vs location
# tags_dat_raw_tagger_summ <- tags_dat_raw_wrepID |>
#   group_by(spp,tag_group,release_location,tagger) |>
#   summarize(n_tags=length(unique(tag_code))) |>
#   pivot_wider(names_from = tagger,values_from = n_tags)|>
#   arrange(spp,release_location)
# 
# tags_dat_ALIVE_EUTH_tagger_summ <- tags_dat_ALIVE_EUTH_wrepID |>
#   group_by(spp,tag_group,release_location,tagger) |>
#   summarize(n_tags=length(unique(tag_code))) |>
#   pivot_wider(names_from = tagger,values_from = n_tags)|>
#   arrange(spp,release_location)
# rel_tagger_sum_tb_ls

tags_dat_raw_tagger_summ <- tag_rel_tagger_summ_tb(tags_dat_wrepID_in = tag_subsets_ls[["RAW"]])
tags_dat_ALIVE_EUTH_tagger_summ <- tag_rel_tagger_summ_tb(tags_dat_wrepID_in = tag_subsets_ls[["tags_SURVUSE_AND_ALIVE_or_EUTH"]])
tags_dat_ALIVE_or_EUTH_tagger_summ <- tag_rel_tagger_summ_tb(tags_dat_wrepID_in = tag_subsets_ls[["tags_ALIVE_or_EUTH"]])


  # tags_dat_raw_tagger_summ
# append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Replicate vs. Tagger",tb_nm_in="repID_tagger_CT_tab",tag_sub_nm="RAW"))

source("R/get_tagger_rel_loc_status_tb_ls.R")

# tags_dat_raw_tagger_relID_summ_ls <- get_tagger_rel_loc_status_tb_ls(tags_dat_wrepID_in = tags_dat_raw_wrepID)
# tags_dat_ALIVE_EUTH_tagger_relID_summ_ls <- get_tagger_rel_loc_status_tb_ls(tags_dat_wrepID_in = tags_dat_ALIVE_EUTH_wrepID)

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



library(quarto)
quarto_render("SW_QAQC_new_summ_1_3.qmd")

















# #' Title
# #'
# #' @returns
# #'
# #' @export
# #' @examples
# append_conting_tabs_qmdORIG<- function(tab_subset_nm="RAW"){
#   unlink("SW_QAQC_new_summ_1_3.qmd")
#   file.copy("SW_QAQC_new_summ_1_3_template.qmd", "SW_QAQC_new_summ_1_3.qmd")

#   # top matter
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n{{< pagebreak >}}\n')
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'# Summaries for all tags')
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'Includes "Tarmac" and "Mortality" groups (i.e., fish dropped on the ground and that died during handing, respectively)')
#   # append_to_qmd("SW_QAQC_new_summ_1_3.qmd",top_matter)
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd", "\n## Contingency Tables\n")

#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Live/Dead Status vs. Survival_use",tb_nm_in="usable_CT_tab",tag_sub_nm="RAW"))
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Live/Dead Status vs. Tagger",tb_nm_in="fish_status_tagger_CT_tab",tag_sub_nm="RAW"))

#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Release location vs. tagger",tb_nm_in="RL_tagger_CT_tab",tag_sub_nm="RAW"))
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Release Location vs. Release Type",tb_nm_in="RL_helicopter_CT_tab",tag_sub_nm="RAW"))

#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Tag lot vs. Tagger",tb_nm_in="lot_tagger_CT_tab",tag_sub_nm="RAW"))
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Tag lot vs. Release location",tb_nm_in="lot_RL_CT_tab",tag_sub_nm="RAW"))

#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n#### Rock Island\n')
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="CHN",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm="RAW",ele_nm_in = "CHN.Rock Island Tailrace"))
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="STH",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm="RAW",ele_nm_in = "STH.Rock Island Tailrace"))
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n#### Priest Rapids\n')
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="CHN",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm="RAW",ele_nm_in = "CHN.Priest Rapids Tailrace"))
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="STH",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm="RAW",ele_nm_in = "STH.Priest Rapids Tailrace"))

#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Replicate vs. Tagger",tb_nm_in="repID_tagger_CT_tab",tag_sub_nm="RAW"))
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Replicate vs. Release location",tb_nm_in="repID_RL_CT_tab",tag_sub_nm="RAW"))

#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Fish released by location, status, and tagger",tb_nm_in="tags_dat_raw_tagger_summ",tag_sub_nm="RAW",header_level = "##"))
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n### Chinook\n')
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="Live fish",tb_nm_in="tags_dat_raw_tagger_relID_summ_ls",tag_sub_nm="RAW",ele_nm_in = "CHN_live",header_level = "####"))
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="Dead fish",tb_nm_in="tags_dat_raw_tagger_relID_summ_ls",tag_sub_nm="RAW",ele_nm_in = "CHN_dead",header_level = "####"))
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n### Steelhead\n')
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="Live fish",tb_nm_in="tags_dat_raw_tagger_relID_summ_ls",tag_sub_nm="RAW",ele_nm_in = "STH_live",header_level = "####"))
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="Dead fish",tb_nm_in="tags_dat_raw_tagger_relID_summ_ls",tag_sub_nm="RAW",ele_nm_in = "STH_dead",header_level = "####"))

#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n{{< pagebreak >}}\n')
  
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n## Fish Released by Location, Replicate, and Status\n')
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\nRock Island and Priest Rapids are abbreviated and the "_d" refers to release of "Euthanized" fish\n')
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="CHN",tb_nm_in="rel_loc_by_repID_tabs",tag_sub_nm="RAW",ele_nm_in = "CHN",header_level = "####"))
#   append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="STH",tb_nm_in="rel_loc_by_repID_tabs",tag_sub_nm="RAW",ele_nm_in = "STH",header_level = "####"))


#  return(NULL) 
# }
# # {{< pagebreak >}}




# rel_tagger_sum_tb_ls <- list(
#   "all"=list(
#     "tags_dat_raw_tagger_summ"=tags_dat_raw_tagger_summ,
#     "tags_dat_raw_tagger_relID_summ_ls"=tags_dat_raw_tagger_relID_summ_ls),
#   "ALIVE_EUTH"=list(
#      "tags_dat_ALIVE_EUTH_tagger_summ"=tags_dat_ALIVE_EUTH_tagger_summ,
#      "tags_dat_ALIVE_EUTH_tagger_relID_summ_ls"=tags_dat_ALIVE_EUTH_tagger_relID_summ_ls)
#   )

# saveRDS(rel_tagger_sum_tb_ls,"tmp_data/rel_tagger_sum_tb_ls.rds")








# new set of tables begins here
# "repID_RL_CT_tab"
# add_qsec3_elwise(header_in="TEST",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm="RAW",ele_nm_in = "STH.Priest Rapids Tailrace")
# # get_conting_tabs_by_name 
# get_conting_tabs_by_name(tags_dat_in = tag_subsets_ls[["RAW"]],tb_nm_in = "lot_tagger_RL_CT_tab_ls",ele_nm_in = "STH.Priest Rapids Tailrace")
# # rel_tagger_sum_tb_ls <- readRDS("tmp_data/rel_tagger_sum_tb_ls.rds")

# library(quarto)

# quarto_render("SW_QAQC_new_summ_1_3.qmd")

# append_to_qmd("SW_QAQC_new_summ_1_3.qmd", quarto_chunk_raw)








# # top matter
# append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n{{< pagebreak >}}\n')
# append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'# Summaries for all tags')
# append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'Includes "Tarmac" and "Mortality" groups (i.e., fish dropped on the ground and that died during handing, respectively)')
# # append_to_qmd("SW_QAQC_new_summ_1_3.qmd",top_matter)
# append_to_qmd("SW_QAQC_new_summ_1_3.qmd", "\n## Contingency Tables\n")

# append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Live/Dead Status vs. Survival_use",tb_nm_in="usable_CT_tab",tag_sub_nm="RAW"))
# append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Live/Dead Status vs. Tagger",tb_nm_in="fish_status_tagger_CT_tab",tag_sub_nm="RAW"))

# append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Release location vs. tagger",tb_nm_in="RL_tagger_CT_tab",tag_sub_nm="RAW"))
# append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Release Location vs. Release Type",tb_nm_in="RL_helicopter_CT_tab",tag_sub_nm="RAW"))

# append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Tag lot vs. Tagger",tb_nm_in="lot_tagger_CT_tab",tag_sub_nm="RAW"))
# append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Tag lot vs. Release location",tb_nm_in="lot_RL_CT_tab",tag_sub_nm="RAW"))

# append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n#### Rock Island\n')
# append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="CHN",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm="RAW",ele_nm_in = "CHN.Rock Island Tailrace"))
# append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="STH",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm="RAW",ele_nm_in = "STH.Rock Island Tailrace"))
# append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n#### Priest Rapids\n')
# append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="CHN",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm="RAW",ele_nm_in = "CHN.Priest Rapids Tailrace"))
# append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3_elwise(header_in="STH",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm="RAW",ele_nm_in = "STH.Priest Rapids Tailrace"))

# append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Replicate vs. Tagger",tb_nm_in="repID_tagger_CT_tab",tag_sub_nm="RAW"))
# append_to_qmd("SW_QAQC_new_summ_1_3.qmd", add_qsec3(header_in="Replicate vs. Release location",tb_nm_in="repID_RL_CT_tab",tag_sub_nm="RAW"))






# append_to_qmd <- function(file_path, text_lines) {
#   cat(text_lines, sep = "\n", file = file_path, append = TRUE)
# }

# # Example: Adding an executable R code block to a Quarto file
# quarto_chunk <- c(
#   "## Automated Plot",
#   "```{r}",
#   "#| echo: false",
#   "plot(cars)",
#   "```"
# )

# append_to_qmd("SW_QAQC_new_summ_1_3.qmd", quarto_chunk)
