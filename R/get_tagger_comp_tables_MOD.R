#' Organize Survival Comparison Tables by Species and Location
#'
#' Creates survival comparison tables for all location/species combinations
#' and organizes them into a nested list structure for easy access.
#'
#' @param atlas_results_in List returned from \code{scrape_atlas_results()}
#'
#' @return Nested list with structure: \code{CHN/STH} (species) × \code{RI/PR} (location)
#'   containing survival comparison tables
#'
#' @details
#' Returns a nested list with two levels:
#' - Level 1: Species (CHN = Chinook, STH = Steelhead)
#' - Level 2: Location (RI = Rock Island, PR = Priest Rapids)
#'
#' Each element contains a data frame from \code{create_survival_comparison_table()}
#'
#' @keywords assumption_check
#' @export
#' @examples
#' \dontrun{
#' atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")
#' comp_tables <- get_tagger_comp_tables_MOD(atlas_results)
#' print(comp_tables$CHN$RI)  # Chinook at Rock Island
#' }

get_tagger_comp_tables_MOD <- function(atlas_results_in){

  # Create comparison table
  ri_chn <- create_survival_comparison_table(
    atlas_results_in,
    location = "RI",
    species = "Chinook"
  )

  pr_chn <- create_survival_comparison_table(
    atlas_results_in,
    location = "PR",
    species = "Chinook"
  )

  ri_sth <- create_survival_comparison_table(
    atlas_results_in,
    location = "RI",
    species = "Steelhead"
  )
  pr_sth <- create_survival_comparison_table(
    atlas_results_in,
    location = "PR",
    species = "Steelhead"
  )

  ls_out=list(
    "CHN"=list(
      "RI"=ri_chn,
      "PR"= pr_chn),
    "STH" = list(
      "RI"= ri_sth,
      "PR"= pr_sth)
  )

  return(ls_out)
  
  chn_stacked <- bind_rows(
    ri_chn,
    data.frame(reach=matrix(NA)),
    pr_chn)
  
  sth_stacked <- bind_rows(
    ri_sth,
    data.frame(reach=matrix(NA)),
    pr_sth)
  
  list(
    CHN=chn_stacked,
    STH=chn_stacked)

}
