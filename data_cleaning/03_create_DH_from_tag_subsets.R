
library(dplyr)
source("R/get_DH_tag_code_summ.R")

# Load raw data for detection history analysis
csv_fl_ls <- readRDS("data/clean/csv_fl_ls.rds")
events_dat <- csv_fl_ls$GPUD2026_events_17Aug2026
node_dat <- csv_fl_ls$GPUD2026_nodes_12Aug2026

tag_subsets_ls <- readRDS("data/clean/tag_subsets_ls.rds")

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
  "AE_RI_summ" = AE_RI_summ,
  "AE_PR_summ" = AE_PR_summ,
  "raw_RI_summ" = raw_RI_summ,
  "raw_PR_summ" = raw_PR_summ
)

# Save detection history list for use in Quarto reports
saveRDS(tag_DH_ls, "data/clean/tag_DH_ls.rds")
