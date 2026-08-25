library(dplyr)
library(ggplot2) 
library(tidyr)

csv_fl_ls <- readRDS("tmp_data/csv_fl_ls.rds")

tags_dat_raw <- csv_fl_ls$GPUD2026_tags_17Aug2026

# release dates 
table(tags_dat_raw$tag_release_date)

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

tags_dat_raw_wrepID |> 
  group_by(spp,release_location,rep_loc,repID,rel_date,survival_use) |>
  summarize(n_tags=length(unique(tag_code))) |> 
  pivot_wider(names_from = c(survival_use,release_location),values_from = c(n_tags,rel_date)) 


# bad code from before
# RI_tmp <- tags_dat_raw_wrepID |> 
#   group_by(spp,release_location,rep_loc,repID,rel_date,survival_use) |>
#   summarize(n_tags=length(unique(tag_code))) |> 
#   pivot_wider(names_from = c(survival_use),values_from = c(n_tags)) |> filter(release_location=="Rock Island Tailrace")
# 
# PR_tmp <- tags_dat_raw_wrepID |> 
#   group_by(spp,release_location,rep_loc,repID,rel_date,survival_use) |>
#   summarize(n_tags=length(unique(tag_code))) |> 
#   pivot_wider(names_from = c(survival_use),values_from = c(n_tags)) |> filter(release_location=="Priest Rapids Tailrace") 
#   
# names(RI_tmp)[5:7] <- c("RI_rel","RI","RI_d")
# names(PR_tmp)[5:7] <- c("PR_rel","PR","PR_d")
# 
# rel_loc_by_repID_tabs_COMB  <- RI_tmp |> ungroup()  |> select(-release_location,-rep_loc) |> mutate(RI_rel=format(RI_rel,"%m-%d")) |> 
#   left_join(PR_tmp  |> ungroup() |> select(-release_location,-rep_loc) |> mutate(PR_rel=format(PR_rel,"%m-%d"))) |>
#   relocate(spp,repID,RI,RI_d,PR,PR_d,RI_rel,PR_rel)
# 
# rel_loc_by_repID_tabs <- list(
#   "CHN"= rel_loc_by_repID_tabs_COMB|> filter(spp=="CHN"),
#   "STH"= rel_loc_by_repID_tabs_COMB|> filter(spp=="STH"))



source("R/get_rel_loc_by_repID_tabs.R")
rel_loc_by_repID_tabs <- get_rel_loc_by_repID_tabs(tags_dat_raw_wrepID)



tags_dat_ALIVE_EUTH_wrepID <- tags_dat_raw_wrepID |> filter(fish_status %in% c("Alive","Euthanized"))








saveRDS(rel_loc_by_repID_tabs,"tmp_data/rel_loc_by_repID_tabs.rds")

saveRDS(tags_dat_raw_wrepID,"tmp_data/tags_dat_raw_wrepID.rds")

saveRDS(tags_dat_ALIVE_EUTH_wrepID,"tmp_data/tags_dat_ALIVE_EUTH_wrepID.rds")



