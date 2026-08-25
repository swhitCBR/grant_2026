
#' Summarize tag counts by species, rep, date, and survival use, with
#' release locations pivoted to columns
#'
#' @param tags_dat_raw_wrepID Data frame containing at least the columns
#'   spp, release_location, repID, rel_date, and survival_use.
#'
#' @return A tibble with one row per unique combination of spp, repID,
#'   rel_date, and survival_use, and one column per distinct
#'   release_location holding the corresponding count of tags.
#' @param split_var Column used to further split the count columns by
#'   release_location. Defaults to tag_group.
get_rel_loc_by_repID_tabs <- function(tags_dat_raw_wrepID, split_var = tag_group) {
  split_var <- rlang::ensym(split_var)
  split_name <- rlang::as_string(split_var)
  
  # Shorten release location names for use in pivoted column names
  tags_dat_raw_wrepID <- tags_dat_raw_wrepID |>
    dplyr::mutate(
      release_location = dplyr::case_when(
        release_location == "Rock Island Tailrace" ~ "RI",
        release_location == "Priest Rapids Tailrace" ~ "PR",
        TRUE ~ as.character(release_location)
      )
    )
  
  counts_by_location_split <- tags_dat_raw_wrepID |>
    dplyr::group_by(spp, release_location, repID, rel_date, !!split_var) |>
    dplyr::summarise(n = dplyr::n(), .groups = "drop") |>
    tidyr::pivot_wider(
      id_cols = c(spp, repID),
      names_from = c(release_location, !!split_var),
      names_glue = paste0("n_{release_location}_{", split_name, "}"),
      values_from = n
    )
  
  dates_by_location <- tags_dat_raw_wrepID |>
    dplyr::distinct(spp, release_location, repID, rel_date) |>
    tidyr::pivot_wider(
      id_cols = c(spp, repID),
      names_from = release_location,
      names_glue = "rel_date_{release_location}",
      values_from = rel_date
    )
  
  result <- dplyr::left_join(counts_by_location_split, dates_by_location, by = c("spp", "repID")) |>
    # Reformat release dates as mm-dd for display
    dplyr::mutate(dplyr::across(dplyr::starts_with("rel_date_"), ~ format(.x, "%m-%d")))
  
  # For tag_group, shorten the count column suffixes for readability
  if (split_name == "tag_group") {
    result <- result |>
      dplyr::rename_with(
        ~ .x |>
          gsub("_live_release", "", x = _) |>
          gsub("_dead_release", "_d", x = _) |>
          gsub("^n_", "", x = _)
      )
  }
  
  # Split into a named list of tables, one per spp
  split(result, result$spp)
}
