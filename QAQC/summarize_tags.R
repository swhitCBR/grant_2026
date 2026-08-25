library(dplyr)
library(tidyr)
library(rlang)

#' Summarize tag counts by species, release location, rep, date, and survival use
#'
#' @param tags_dat_raw_wrepID Data frame containing at least the columns
#'   spp, release_location, repID, rel_date, and survival_use.
#'
#' @return A tibble with one row per unique combination of spp,
#'   release_location, repID, rel_date, and survival_use, and a count column n.
summarize_tags <- function(tags_dat_raw_wrepID) {
  tags_dat_raw_wrepID |>
    group_by(spp, release_location, repID, rel_date, survival_use) |>
    summarise(n = n(), .groups = "drop")
}

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
  split_var <- ensym(split_var)
  split_name <- as_string(split_var)

  # Shorten release location names for use in pivoted column names
  tags_dat_raw_wrepID <- tags_dat_raw_wrepID |>
    mutate(
      release_location = case_when(
        release_location == "Rock Island Tailrace" ~ "RI",
        release_location == "Priest Rapids Tailrace" ~ "PR",
        TRUE ~ as.character(release_location)
      )
    )

  counts_by_location_split <- tags_dat_raw_wrepID |>
    group_by(spp, release_location, repID, rel_date, !!split_var) |>
    summarise(n = n(), .groups = "drop") |>
    pivot_wider(
      id_cols = c(spp, repID),
      names_from = c(release_location, !!split_var),
      names_glue = paste0("n_{release_location}_{", split_name, "}"),
      values_from = n
    )

  dates_by_location <- tags_dat_raw_wrepID |>
    distinct(spp, release_location, repID, rel_date) |>
    pivot_wider(
      id_cols = c(spp, repID),
      names_from = release_location,
      names_glue = "rel_date_{release_location}",
      values_from = rel_date
    )

  result <- left_join(counts_by_location_split, dates_by_location, by = c("spp", "repID")) |>
    # Reformat release dates as mm-dd for display
    mutate(across(starts_with("rel_date_"), ~ format(.x, "%m-%d")))

  # For tag_group, shorten the count column suffixes for readability
  if (split_name == "tag_group") {
    result <- result |>
      rename_with(
        ~ .x |>
          gsub("_live_release", "", x = _) |>
          gsub("_dead_release", "_d", x = _) |>
          gsub("^n_", "", x = _)
      )
  }

  # Split into a named list of tables, one per spp
  split(result, result$spp)
}

#' Summarize release dates by species and rep, with release locations as columns
#'
#' @param tags_dat_raw_wrepID Data frame containing at least the columns
#'   spp, release_location, repID, and rel_date.
#'
#' @return A tibble with one row per unique combination of spp and repID,
#'   and one column per distinct release_location holding the corresponding
#'   rel_date.
summarize_tags_wide <- function(tags_dat_raw_wrepID) {
  tags_dat_raw_wrepID |>
    distinct(spp, release_location, repID, rel_date) |>
    pivot_wider(
      names_from = release_location,
      values_from = rel_date
    )
}
