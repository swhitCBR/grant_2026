

tags_dat_raw_wrepID <- readRDS("tmp_data/tags_dat_raw_wrepID.rds")

tags_dat_ALIVE_EUTH_wrepID <- readRDS("tmp_data/tags_dat_ALIVE_EUTH_wrepID.rds")


source("R/get_conting_tabs.R")

CT_raw_ls <- get_conting_tabs(tags_dat_in = tags_dat_raw_wrepID)

CT_ALIVE_EUTH_ls <- get_conting_tabs(tags_dat_in = tags_dat_ALIVE_EUTH_wrepID)


saveRDS(CT_raw_ls,"tmp_data/CT_raw_ls.rds")
saveRDS(CT_ALIVE_EUTH_ls,"tmp_data/CT_ALIVE_EUTH_ls.rds")
