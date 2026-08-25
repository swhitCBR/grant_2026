get_tagger_rel_loc_status_tb_ls <- function (tags_dat_wrepID_in){
  # tagger vs. rel location vs. tag_group
  tags_dat_raw_location_repID_tagger_summ <-  tags_dat_wrepID_in |>
    group_by(spp,tag_group,release_location,tagger,repID) |>
    summarize(n_tags=length(unique(tag_code))) |>
    pivot_wider(names_from = tagger,values_from = n_tags)|>
    arrange(spp,release_location)
  
  list(
    "CHN_live"=tags_dat_raw_location_repID_tagger_summ |> filter(spp=="CHN" & tag_group=="live_release"),
    "CHN_dead"=tags_dat_raw_location_repID_tagger_summ |> filter(spp=="CHN" & tag_group=="dead_release"),
    "STH_live"=tags_dat_raw_location_repID_tagger_summ |> filter(spp=="STH" & tag_group=="live_release"),
    "STH_dead"=tags_dat_raw_location_repID_tagger_summ |> filter(spp=="STH" & tag_group=="dead_release"))
  
  }

