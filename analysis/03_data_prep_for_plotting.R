

# left_joins and things for plottin


library(dplyr)
library(ggplot2)

rep_level_ests_Ftests_tb_ls <- readRDS("results/rep_level_ests_Ftests_tb_ls.rds")
tags_new_repID_DF <- readRDS("data/clean/tags_new_repID_DF.rds")


repID_wRelLoc_tb <- tags_new_repID_DF |> group_by(species_code,new_repID,release_location) |> 
  summarize(min_rel_date=as.Date(min(release_date)),
            max_rel_date=as.Date(max(release_date)),
            same=min_rel_date==max_rel_date) |>
  mutate(
    rel_date_rng = case_when(
      same ~ format(min_rel_date, "%b %d"),
      format(min_rel_date, "%b") == format(max_rel_date, "%b") ~
        paste0(format(min_rel_date, "%b %d"), "-", format(max_rel_date, "%d")),
      TRUE ~ paste0(format(min_rel_date, "%b %d"), "-", format(max_rel_date, "%b %d"))
    ),
    # drop leading zeros from day numbers (e.g. "May 05" -> "May 5")
    rel_date_rng = gsub("(?<=\\s|-)0", "", rel_date_rng, perl = TRUE),
    rel_date_rngALT = if_else(
      same,
      format(min_rel_date, "%m/%d"),
      paste0(format(min_rel_date, "%m/%d"), "-", format(max_rel_date, "%m/%d"))
    )
  )


repID_RelLocComb_tb <- tags_new_repID_DF |> group_by(species_code,new_repID) |>#,release_location) |> 
  summarize(min_rel_date=as.Date(min(release_date)),
            max_rel_date=as.Date(max(release_date)),
            same=min_rel_date==max_rel_date) |>
  mutate(
    rel_date_rng = case_when(
      same ~ format(min_rel_date, "%b %d"),
      format(min_rel_date, "%b") == format(max_rel_date, "%b") ~
        paste0(format(min_rel_date, "%b %d"), "-", format(max_rel_date, "%d")),
      TRUE ~ paste0(format(min_rel_date, "%b %d"), "-", format(max_rel_date, "%b %d"))
    ),
    # drop leading zeros from day numbers (e.g. "May 05" -> "May 5")
    rel_date_rng = gsub("(?<=\\s|-)0", "", rel_date_rng, perl = TRUE),
    rel_date_rngALT = if_else(
      same,
      format(min_rel_date, "%m/%d"),
      paste0(format(min_rel_date, "%m/%d"), "-", format(max_rel_date, "%m/%d"))
    )
  )


COMB_spp_ATLAS_ests_wDates <- rep_level_ests_Ftests_tb_ls$COMB_spp_ATLAS_ests |>
  left_join(
    repID_RelLocComb_tb |>
      ungroup() |>
      select(species = species_code, new_repID,
             min_rel_date, max_rel_date, rel_date_rng, rel_date_rngALT),
    by = c("species", "new_repID"),
    # each estimate row matches at most one replicate date range
    relationship = "many-to-one"
  ) |>
  # Rock Island release dates only (one row per species x replicate)
  left_join(
    repID_wRelLoc_tb |>
      ungroup() |>
      filter(release_location == "Rock Island Tailrace") |>
      select(species = species_code, new_repID,
             RI_min_rel_date = min_rel_date, RI_max_rel_date = max_rel_date,
             RI_rel_date_rng = rel_date_rng, RI_rel_date_rngALT = rel_date_rngALT),
    by = c("species", "new_repID"),
    relationship = "many-to-one"
  ) 


# Priest Rapids release dates only (one row per species x replicate)
COMB_spp_ATLAS_ests_wDates <- COMB_spp_ATLAS_ests_wDates |>
  left_join(
    repID_wRelLoc_tb |>
      ungroup() |>
      filter(release_location == "Priest Rapids Tailrace") |>
      select(species = species_code, new_repID,
             PR_min_rel_date = min_rel_date, PR_max_rel_date = max_rel_date,
             PR_rel_date_rng = rel_date_rng, PR_rel_date_rngALT = rel_date_rngALT),
    by = c("species", "new_repID"),
    relationship = "many-to-one"
  )

saveRDS(COMB_spp_ATLAS_ests_wDates,"results/COMB_spp_ATLAS_ests_wDates.rds")


######################## #
# Cumulative Plotting
######################## #

# loading tables compiled from ATLAS files
CHN_ATLAS_TLSR <- readRDS("results/CHN_ATLAS_TLSR_out.rds")
STH_ATLAS_TLSR <- readRDS("results/STH_ATLAS_TLSR_out.rds")


# river kilometer of each detection site (the release locations have no river kilometer in the data)
node_dat <- readRDS("data/clean/csv_fl_ls.rds")$GPUD2026_nodes_12Aug2026
site_km <- node_dat |>
  distinct(site = location, river_kilometer)

# Cumulative survival from the Rock Island release to each downstream site (RI release is the
# only one with the full set of sites; PR releases only have the terminal Lower Ringold reach).
cum_surv_RI <- bind_rows(CHN = CHN_ATLAS_TLSR$"CHN_TL_ModeledCum_tab",
                         STH = STH_ATLAS_TLSR$"STH_TL_ModeledCum_tab", .id = "species") |>
  filter(rel_loc == "RI") |>
  mutate(site = sub("^Release to ", "", reach)) |>
  left_join(site_km, by = "site")
stopifnot(!anyNA(cum_surv_RI$river_kilometer))

# Release point: cumulative survival is 1 by definition, with no uncertainty (SE = 0). The release
# locations have no river kilometer in the data, so release_km is a display placeholder 10 km
# upstream of the first detection site, not the Rock Island Tailrace's actual river kilometer.
release_km <- max(cum_surv_RI$river_kilometer) + 10
cum_surv_RI <- bind_rows(
  cum_surv_RI,
  tibble(species = c("CHN", "STH"), rel_loc = "RI", site = "Release",
         river_kilometer = release_km, est = 1, SE = 0))

# one row per plotted site: where the dotted vertical lines, their labels and the axis ticks go
river_km_tab <- distinct(cum_surv_RI, site, river_kilometer)


saveRDS(river_km_tab,"results/river_km_tab.rds")
saveRDS(cum_surv_RI,"results/cum_surv_RI.rds")

