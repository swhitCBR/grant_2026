library(dplyr)
library(tidyr)

tags_dat_raw_wrepID <- readRDS("tmp_data/tags_dat_raw_wrepID.rds")
tags_dat_ALIVE_EUTH_wrepID <- readRDS("tmp_data/tags_dat_ALIVE_EUTH_wrepID.rds")


# tagger vs location
tags_dat_raw_tagger_summ <- tags_dat_raw_wrepID |>
  group_by(spp,tag_group,release_location,tagger) |>
  summarize(n_tags=length(unique(tag_code))) |>
  pivot_wider(names_from = tagger,values_from = n_tags)|>
  arrange(spp,release_location)

tags_dat_ALIVE_EUTH_tagger_summ <- tags_dat_ALIVE_EUTH_wrepID |>
  group_by(spp,tag_group,release_location,tagger) |>
  summarize(n_tags=length(unique(tag_code))) |>
  pivot_wider(names_from = tagger,values_from = n_tags)|>
  arrange(spp,release_location)

source("R/get_tagger_rel_loc_status_tb_ls.R")

tags_dat_raw_tagger_relID_summ_ls <- get_tagger_rel_loc_status_tb_ls(tags_dat_wrepID_in = tags_dat_raw_wrepID)

tags_dat_ALIVE_EUTH_tagger_relID_summ_ls <- get_tagger_rel_loc_status_tb_ls(tags_dat_wrepID_in = tags_dat_ALIVE_EUTH_wrepID)


rel_tagger_sum_tb_ls <- list(
  "all"=list(
    "tags_dat_raw_tagger_summ"=tags_dat_raw_tagger_summ,
    "tags_dat_raw_tagger_relID_summ_ls"=tags_dat_raw_tagger_relID_summ_ls),
  "ALIVE_EUTH"=list(
     "tags_dat_ALIVE_EUTH_tagger_summ"=tags_dat_ALIVE_EUTH_tagger_summ,
     "tags_dat_ALIVE_EUTH_tagger_relID_summ_ls"=tags_dat_ALIVE_EUTH_tagger_relID_summ_ls)
  )

saveRDS(rel_tagger_sum_tb_ls,"tmp_data/rel_tagger_sum_tb_ls.rds")

################## #
# By-tagger summary
################## #
# tags_dat_raw_tagger_summ <- tags_dat_raw |>
#   group_by(spp,tag_group,release_location,tagger) |>
#   summarize(n_tags=length(unique(tag_code))) |>
#   pivot_wider(names_from = tagger,values_from = n_tags)|>
#   arrange(release_location)
# 
# tags_dat_tagger_summ <- tags_dat |>
#   group_by(spp,tag_group,release_location,tagger) |>
#   summarize(n_tags=length(unique(tag_code))) |>
#   pivot_wider(names_from = tagger,values_from = n_tags)|>
#   arrange(release_location)
# 
################## #
# 
# 
# QAQC_tabs <- list("QAQC_tab1"=tags_dat_tagger_summ,
#                   "QAQC_tab2"=tags_dat_summ4)
# 
# saveRDS(QAQC_tabs,"QAQC_tabs.rds")
# 
# 
# tarmac_tag_tab <- tags_dat_raw_wrepID |> filter(fish_status=="Tarmac") |> select(species,tag_release_date,release_location,repID,tag_code)
# saveRDS(tarmac_tag_tab,"tarmac_tag_tab.rds")
# 
# 
# mort_tag_tab <- tags_dat_raw_wrepID |> filter(fish_status=="Mortality") |> select(species,tag_release_date,release_location,repID,tag_code)
# saveRDS(mort_tag_tab,"mort_tag_tab.rds")
