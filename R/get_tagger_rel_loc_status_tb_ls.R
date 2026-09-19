#' Generate tagger/location/status summary tables
#'
#' Creates a list of summary tables showing tag counts by tagger, release
#' location, and tag group (live/dead release). Results are separated by
#' species and tag group status.
#'
#' @param tags_dat_wrepID_in Data frame containing tag data with columns:
#'   spp, tag_group, release_location, tagger, repID, and tag_code.
#'
#' @return A list of four data frames:
#'   \describe{
#'     \item{CHN_live}{Chinook live release tags}
#'     \item{CHN_dead}{Chinook dead release tags}
#'     \item{STH_live}{Steelhead live release tags}
#'     \item{STH_dead}{Steelhead dead release tags}
#'   }
#'   Each data frame is grouped by species, tag_group, release_location,
#'   tagger, and repID with columns for each tagger's tag counts.
#'
#' @keywords QAQC tabulate
#' @export
#'
#' @examples
#' \dontrun{
#' tagger_summ <- get_tagger_rel_loc_status_tb_ls(tags_dat_wrepID_in = tag_subsets_ls[["RAW"]])
#' }
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
