
get_conting_tabs <- function(tags_dat_in){

  usable_CT_tab <- tags_dat_in |>
    dplyr::group_by(spp,survival_use,fish_status) |>
    dplyr::summarize(n_tags=length(unique(tag_code))) |>
    tidyr::pivot_wider(names_from = survival_use,values_from = n_tags,values_fill = 0)

  RL_tagger_CT_tab <- tags_dat_in |> 
    dplyr::group_by(spp,release_location,tagger) |> 
    dplyr::summarize(n_tags=length(unique(tag_code))) |>
    tidyr::pivot_wider(names_from = release_location,values_from = n_tags,values_fill = 0)
  
  RL_helicopter_CT_tab <- tags_dat_in |> 
    dplyr::group_by(spp,release_location,release_type) |> 
    dplyr::summarize(n_tags=length(unique(tag_code))) |>
    tidyr::pivot_wider(names_from = release_location,values_from = n_tags,values_fill = 0)

  lot_tagger_CT_tab <- tags_dat_in |> 
    dplyr::group_by(spp,lot,tagger) |> 
    dplyr::summarize(n_tags=length(unique(tag_code))) |>
    tidyr::pivot_wider(names_from = lot,values_from = n_tags,values_fill = 0)

  lot_RL_CT_tab <- tags_dat_in |> 
    dplyr::group_by(spp,lot,release_location) |> 
    dplyr::summarize(n_tags=length(unique(tag_code))) |>
    tidyr::pivot_wider(names_from = lot,values_from = n_tags,values_fill = 0)

  fish_status_tagger_CT_tab <- tags_dat_in |> 
    dplyr::group_by(spp,fish_status,tagger) |> 
    dplyr::summarize(n_tags=length(unique(tag_code))) |>
    tidyr::pivot_wider(names_from = fish_status,values_from = n_tags,values_fill = 0)

  repID_tagger_CT_tab <- tags_dat_in |> 
    dplyr::group_by(spp,repID,tagger) |> 
    dplyr::summarize(n_tags=length(unique(tag_code))) |>
    tidyr::pivot_wider(names_from = tagger,values_from = n_tags,values_fill = 0)

  repID_RL_CT_tab <- tags_dat_in |> 
    dplyr::group_by(spp,repID,release_location) |> 
    dplyr::summarize(n_tags=length(unique(tag_code))) |>
    tidyr::pivot_wider(names_from = release_location,values_from = n_tags,values_fill = 0)

  # contingency tables
  
  CT_tab_ls <- list(
    "usable_CT_tab"=usable_CT_tab,
    "RL_tagger_CT_tab"=RL_tagger_CT_tab,
    "RL_helicopter_CT_tab"=RL_helicopter_CT_tab,
    "lot_tagger_CT_tab"=lot_tagger_CT_tab,
    "lot_RL_CT_tab"=lot_RL_CT_tab,
    "fish_status_tagger_CT_tab"=fish_status_tagger_CT_tab,
    "repID_tagger_CT_tab"=repID_tagger_CT_tab,
    "repID_RL_CT_tab"=repID_RL_CT_tab
  )
}
