#' Summarize tag counts by species, tag group, release location, and tagger
#'
#' Creates a summary table of tag counts grouped by species, tag group
#' (live/dead release), release location, and tagger, with taggers as columns.
#'
#' @param tags_dat_wrepID_in Data frame containing tag data with columns:
#'   spp, tag_group, release_location, tagger, and tag_code.
#'
#' @return A data frame with one row per combination of species, tag_group,
#'   and release_location, and columns for each unique tagger value showing
#'   the count of tags for that tagger.
#'
#' @keywords QAQC tabulate
#' @export
#'
#' @examples
#' \dontrun{
#' tagger_summ <- tag_rel_tagger_summ_tb(tags_dat_wrepID_in = tag_subsets_ls[["RAW"]])
#' }
tag_rel_tagger_summ_tb <- function(tags_dat_wrepID_in){
  out <- tags_dat_wrepID_in |>
    group_by(spp,tag_group,release_location,tagger) |>
    summarize(n_tags=length(unique(tag_code))) |>
    pivot_wider(names_from = tagger,values_from = n_tags)|>
    arrange(spp,release_location)
  return(out)
}