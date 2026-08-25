
library(dplyr)
library(tidyr)

tags_dat_raw_wrepID <- readRDS("QAQC/tmp_data/tags_dat_raw_wrepID.rds")
# tags_dat_ALIVE_EUTH_wrepID <- readRDS("QAQC/tmp_data/tags_dat_ALIVE_EUTH_wrepID.rds")

get_rel_loc_by_repID_tabs
source("QAQC/summarize_tags.R")
tags_summary_by_location <- summarize_tags_by_location(tags_dat_raw_wrepID)

getwd()
dir()
source("QAQC/R/get_rel_loc_by_repID_tabs.R")
get_rel_loc_by_repID_tabs(tags_dat_raw_wrepID)


# summarize_tags(tags_dat_raw_wrepID)
# summarize_tags_wide(tags_dat_raw_wrepID)
# summarize_tags_by_location(tags_dat_raw_wrepID,split_var = "tag_group")
# table(tags_dat_raw_wrepID$tag_status)
# # dir()
# View(tags_summary_test)
