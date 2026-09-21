#' Create tag subsets for QAQC and TagPro analysis
#'
#' Loads raw CSV files, adds derived fields (species, rearing type, release date,
#' replicate IDs), creates tag subsets based on fish status and survival use criteria,
#' and saves to QAQC/tmp_data/tag_subsets_ls.rds
#'
#' Tag subsets:
#' - RAW: All tags
#' - tags_ALIVE_or_EUTH: fish_status in (Alive, Euthanized)
#' - tags_SURVUSE_AND_ALIVE_or_EUTH: survival_use AND fish_status in (Alive, Euthanized)
#' - tags_SURVUSE_OR_ALIVE_or_EUTH: survival_use OR fish_status in (Alive, Euthanized)
#' - tags_SURVUSE_OR_EUTH_&_ACTIVE: survival_use OR (Euthanized AND Active)
#' - tags_ALIVE_ACTIVE_OTHER_OR_EUTH_ACTIVE_OTHER: (Alive AND Active AND Other) OR (Euthanized AND Active AND Other)

library(dplyr)
library(ggplot2) 
library(tidyr)

if(getwd() != "c:/repos/grant_2026"){
  setwd("c:/repos/grant_2026")}

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

csv_fl_ls <- readRDS("data/clean/csv_fl_ls.rds")
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
  "tags_SURVUSE_OR_EUTH_&_ACTIVE"=tags_dat_raw_wrepID |> filter( survival_use |
                                       (fish_status %in% c("Euthanized") & tag_status=="Active")),
  # RAB2
  "tags_ALIVE_ACTIVE_OTHER_OR_EUTH_ACTIVE_OTHER"=tags_dat_raw_wrepID |> filter( 
                                (fish_status %in% c("Alive") & tag_status=="Active" & release_type=="Other") | 
                                  (fish_status %in% c("Euthanized") & tag_status=="Active" & release_type=="Other")),
  "tags_SURVUSE_no_EUTH"=tags_dat_raw_wrepID |> filter( survival_use & fish_status != c("Euthanized") )
                              )
sapply(tag_subsets_ls,nrow)
nrow(tag_subsets_ls[["tags_SURVUSE_AND_ALIVE_or_EUTH"]])
table(tag_subsets_ls[["tags_SURVUSE_AND_ALIVE_or_EUTH"]]$tag_group)
table(tag_subsets_ls[["tags_SURVUSE_AND_ALIVE_or_EUTH"]]$tag_status)
table(tag_subsets_ls[["tags_SURVUSE_AND_ALIVE_or_EUTH"]]$fish_status)

# saveRDS(rel_loc_by_repID_tabs,"tmp_data/rel_loc_by_repID_tabs.rds")
# saveRDS(tags_dat_raw_wrepID,"tmp_data/tags_dat_raw_wrepID.rds")
# saveRDS(tags_dat_ALIVE_EUTH_wrepID,"tmp_data/tags_dat_ALIVE_EUTH_wrepID.rds")
saveRDS(tag_subsets_ls, "data/clean/tag_subsets_ls.rds")

cat("Tag subsets created and saved to data/clean/tag_subsets_ls.rds\n")
