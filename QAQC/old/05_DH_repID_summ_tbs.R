library(dplyr)
library(tidyr)

csv_fl_ls <- readRDS("tmp_data/csv_fl_ls.rds")
events_dat <- csv_fl_ls$GPUD2026_events_17Aug2026
node_dat <- csv_fl_ls$GPUD2026_nodes_12Aug2026
tags_dat_ALIVE_EUTH_wrepID <- readRDS("tmp_data/tags_dat_ALIVE_EUTH_wrepID.rds")

tags_dat_raw_wrepID <- readRDS("tmp_data/tags_dat_raw_wrepID.rds")

source("R/get_DH_tag_code_summ.R")


tag_ALIVE_EUTH_DH_summ <- get_DH_tag_code_summ(node_dat_in = node_dat,events_dat_in = events_dat,tags_dat_wrepID_in = tags_dat_ALIVE_EUTH_wrepID)
tag_raw_DH_summ <- get_DH_tag_code_summ(node_dat_in = node_dat,events_dat_in = events_dat,tags_dat_wrepID_in = tags_dat_raw_wrepID)


tag_raw_DH_summ <- tag_raw_DH_summ |> 
  rename(rel_loc=release_location,
         status=fish_status,CBAR=Crescent.Bar,WAN=Wanapum,WAN.BRZ=Wanapum.BRZ,WAN.TR=Wanapum.Tailrace,WB=White.Bluffs,HAN=Hanford,VRBR=Vernita.Bridge,PR.TR=Priest.Tailrace,PR.BRZ=Priest.BRZ,MATT=Mattawa,SUN=Sunland,LRNG=Lower.Ringold,PR=Priest) |>
  mutate(rel_loc=ifelse(rel_loc=="Rock Island Tailrace","RI","PR"))
tag_ALIVE_EUTH_DH_summ <- tag_ALIVE_EUTH_DH_summ |> 
  rename(rel_loc=release_location,status=fish_status,CBAR=Crescent.Bar,WAN=Wanapum,WAN.BRZ=Wanapum.BRZ,WB=White.Bluffs,HAN=Hanford,VRBR=Vernita.Bridge,PR.TR=Priest.Tailrace,PR.BRZ=Priest.BRZ,MATT=Mattawa,SUN=Sunland,LRNG=Lower.Ringold,PR=Priest) |>
  mutate(rel_loc=ifelse(rel_loc=="Rock Island Tailrace","RI","PR"))

names(tag_ALIVE_EUTH_DH_summ)

# AE_RI_summ <- tag_ALIVE_EUTH_DH_summ |> filter(rel_loc=="Rock Island Tailrace")
# AE_PR_summ <-  tag_ALIVE_EUTH_DH_summ |> filter(rel_loc=="Priest Rapids Tailrace")
# 
# raw_RI_summ <- tag_raw_DH_summ |> filter(rel_loc=="Rock Island Tailrace")
# raw_PR_summ <-  tag_raw_DH_summ |> filter(rel_loc=="Priest Rapids Tailrace")


AE_RI_summ <- tag_ALIVE_EUTH_DH_summ |> filter(rel_loc=="RI")
AE_PR_summ <-  tag_ALIVE_EUTH_DH_summ |> filter(rel_loc=="PR")

raw_RI_summ <- tag_raw_DH_summ |> filter(rel_loc=="RI")
raw_PR_summ <-  tag_raw_DH_summ |> filter(rel_loc=="PR")


tag_DH_ls <- list(
   "AE_RI_summ"=AE_RI_summ,
   "AE_PR_summ"=AE_PR_summ,
   "raw_RI_summ"=raw_RI_summ,
   "raw_PR_summ"=raw_PR_summ
   )


saveRDS(tag_DH_ls,"tmp_data/tag_DH_ls.rds")



head(tag_DH_ls$raw_PR_summ)
tail(tag_DH_ls$AE_PR_summ)


head(tag_DH_ls$raw_PR_summ)
tail(tag_DH_ls$AE_PR_summ)
