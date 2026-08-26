
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
tmp <- tags_dat_in |> 
    dplyr::group_by(spp,lot,release_location,tagger) |> 
    dplyr::summarize(n_tags=length(unique(tag_code))) |>
    tidyr::pivot_wider(names_from = lot,values_from = n_tags,values_fill = 0) |>
    dplyr::arrange(spp,release_location) #|> dplyr::split(spp)
lot_tagger_RL_CT_tab_ls <- split(tmp,list(tmp$spp,tmp$release_location))
  
  
  #  <- tags_dat_in |> 
  #   dplyr::group_by(spp,lot,tagger) |> 
  #   dplyr::summarize(n_tags=length(unique(tag_code))) |>
  #   tidyr::pivot_wider(names_from = lot,values_from = n_tags,values_fill = 0)
  
  # lot_tagger_RL_CT_tab <- tags_dat_in |> 
  #   dplyr::group_by(spp,lot,tagger) |> 
  #   dplyr::summarize(n_tags=length(unique(tag_code))) |>
  #   tidyr::pivot_wider(names_from = lot,values_from = n_tags,values_fill = 0)

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
    "lot_tagger_RL_CT_tab_ls"=lot_tagger_RL_CT_tab_ls,
    "lot_RL_CT_tab"=lot_RL_CT_tab,
    "fish_status_tagger_CT_tab"=fish_status_tagger_CT_tab,
    "repID_tagger_CT_tab"=repID_tagger_CT_tab,
    "repID_RL_CT_tab"=repID_RL_CT_tab
  )
}



#' Title
#'
#' @param tags_dat_in
#' @param tb_nm_in
#' @param ele_nm_in
#'
#' @returns
#'
#' @export
#' @examples
get_conting_tabs_by_name <- function(tags_dat_in,tb_nm_in,ele_nm_in=NULL){

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
tmp <- tags_dat_in |> 
    dplyr::group_by(spp,lot,release_location,tagger) |> 
    dplyr::summarize(n_tags=length(unique(tag_code))) |>
    tidyr::pivot_wider(names_from = lot,values_from = n_tags,values_fill = 0) |>
    dplyr::arrange(spp,release_location) #|> dplyr::split(spp)
lot_tagger_RL_CT_tab_ls <- split(tmp,list(tmp$spp,tmp$release_location))
  
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

  tags_dat_raw_tagger_relID_summ_ls <- get_tagger_rel_loc_status_tb_ls(tags_dat_wrepID_in = tags_dat_in)

  tags_dat_raw_tagger_summ <- tag_rel_tagger_summ_tb(tags_dat_wrepID_in = tags_dat_in)

  rel_loc_by_repID_tabs_tb <- get_rel_loc_by_repID_tabs(tags_dat_raw_wrepID = tags_dat_in)


  # contingency tables
  
  CT_tab_ls <- list(
    "usable_CT_tab"=usable_CT_tab,
    "RL_tagger_CT_tab"=RL_tagger_CT_tab,
    "RL_helicopter_CT_tab"=RL_helicopter_CT_tab,
    "lot_tagger_CT_tab"=lot_tagger_CT_tab,
    "lot_tagger_RL_CT_tab_ls"=lot_tagger_RL_CT_tab_ls,
    "lot_RL_CT_tab"=lot_RL_CT_tab,
    "fish_status_tagger_CT_tab"=fish_status_tagger_CT_tab,
    "repID_tagger_CT_tab"=repID_tagger_CT_tab,
    "repID_RL_CT_tab"=repID_RL_CT_tab,
    "tags_dat_raw_tagger_relID_summ_ls"=tags_dat_raw_tagger_relID_summ_ls,
    "tags_dat_raw_tagger_summ"=tags_dat_raw_tagger_summ,
    "rel_loc_by_repID_tabs"=rel_loc_by_repID_tabs_tb
  )

if(is.null(ele_nm_in)){
out <- CT_tab_ls[[tb_nm_in]]
} else{
  out <- CT_tab_ls[[tb_nm_in]][[ele_nm_in]]
}
  


return(out)


}


#' Title
#'
#' @param tags_dat_wrepID_in
#'
#' @returns
#'
#' @export
#' @examples
tag_rel_tagger_summ_tb <- function(tags_dat_wrepID_in){
  out <- tags_dat_wrepID_in |>
    group_by(spp,tag_group,release_location,tagger) |>
    summarize(n_tags=length(unique(tag_code))) |>
    pivot_wider(names_from = tagger,values_from = n_tags)|>
    arrange(spp,release_location)
  return(out)
}
