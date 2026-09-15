#' Build a named list of tag data subsets from filter condition strings
#'
#' @param tags_dat_raw_wrepID Data frame containing at least the columns
#'   fish_status, survival_use, tag_status, and release_type.
#' @param filter_strs A named character vector, where each element is a
#'   string of arguments to be parsed and passed to dplyr::filter(), and
#'   each name becomes the name of the corresponding element in the
#'   returned list.
#'
#' @return A named list of data frames, one per entry in filter_strs, each
#'   filtered from tags_dat_raw_wrepID using the corresponding condition.
build_tag_subsets <- function(tags_dat_raw_wrepID, filter_strs) {
  purrr::map(
    filter_strs,
    ~ dplyr::filter(tags_dat_raw_wrepID, !!rlang::parse_expr(.x))
  )
}
