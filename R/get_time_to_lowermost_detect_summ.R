#' Compute per-tag time from activation and release to detection at the
#' lowermost detection site, for tags released at Rock Island Tailrace
#'
#' @param tags_dat_wrepID_in Data frame containing at least the columns
#'   tag_code, spp, release_location, tag_activate_date, and
#'   tag_release_date. Filtered internally to
#'   release_location == "Rock Island Tailrace".
#' @param events_dat_in Data frame of detection events with columns
#'   node_code, tag_code, and first_computed_datetime.
#' @param node_dat_in Data frame of detection nodes with columns node_code,
#'   location, and river_kilometer. The lowermost site is taken as the
#'   location with the smallest river_kilometer.
#'
#' @return A tibble with one row per tag (tag_code, spp, lowermost_site,
#'   days_activate_to_detect, days_release_to_detect), for tag_codes
#'   released at Rock Island Tailrace. Tags never detected at the lowermost
#'   site have NA time values.
#'
#' @keywords QAQC tabulate
compute_time_to_lowermost_detect <- function(tags_dat_wrepID_in, events_dat_in, node_dat_in) {

  parse_dt <- function(x) as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

  # Lowermost site = smallest river_kilometer among detection nodes
  lowermost_site <- node_dat_in |>
    dplyr::slice_min(river_kilometer, n = 1, with_ties = FALSE) |>
    dplyr::pull(location)

  lowermost_nodes <- node_dat_in |>
    dplyr::filter(location == lowermost_site) |>
    dplyr::pull(node_code)

  tags_RI <- tags_dat_wrepID_in |>
    dplyr::filter(release_location == "Rock Island Tailrace") |>
    dplyr::mutate(
      tag_activate_date = parse_dt(tag_activate_date),
      tag_release_date = parse_dt(tag_release_date)
    ) |>
    dplyr::distinct(tag_code, spp, tag_activate_date, tag_release_date)

  first_arrival_lowermost <- events_dat_in |>
    dplyr::filter(node_code %in% lowermost_nodes) |>
    dplyr::mutate(first_computed_datetime = parse_dt(first_computed_datetime)) |>
    dplyr::group_by(tag_code) |>
    dplyr::summarise(first_arrival = min(first_computed_datetime), .groups = "drop")

  tags_RI |>
    dplyr::left_join(first_arrival_lowermost, by = "tag_code") |>
    dplyr::mutate(
      lowermost_site = lowermost_site,
      days_activate_to_detect = as.numeric(difftime(first_arrival, tag_activate_date, units = "days")),
      days_release_to_detect = as.numeric(difftime(first_arrival, tag_release_date, units = "days"))
    ) |>
    dplyr::select(tag_code, spp, lowermost_site, days_activate_to_detect, days_release_to_detect)
}

#' Summarize time from tag activation and release to detection at the
#' lowermost detection site, by species
#'
#' Condensed summary (mean, median, min, max) of the elapsed time in days
#' between tag activation/release and first detection at the lowermost
#' detection site, for tags released at Rock Island Tailrace. See
#' \code{\link{compute_time_to_lowermost_detect}} for the per-tag values
#' this summarizes.
#'
#' @inheritParams compute_time_to_lowermost_detect
#'
#' @return A tibble with one row per species (spp), containing the mean,
#'   median, min, and max of days_activate_to_detect and
#'   days_release_to_detect, restricted to tags actually detected at the
#'   lowermost site.
#'
#' @keywords QAQC tabulate
get_time_to_lowermost_detect_summ <- function(tags_dat_wrepID_in, events_dat_in, node_dat_in) {

  tag_times <- compute_time_to_lowermost_detect(tags_dat_wrepID_in, events_dat_in, node_dat_in)

  tag_times |>
    dplyr::group_by(spp) |>
    dplyr::summarise(
      mean_activate_to_detect = mean(days_activate_to_detect, na.rm = TRUE),
      median_activate_to_detect = median(days_activate_to_detect, na.rm = TRUE),
      min_activate_to_detect = suppressWarnings(min(days_activate_to_detect, na.rm = TRUE)),
      max_activate_to_detect = suppressWarnings(max(days_activate_to_detect, na.rm = TRUE)),
      mean_release_to_detect = mean(days_release_to_detect, na.rm = TRUE),
      median_release_to_detect = median(days_release_to_detect, na.rm = TRUE),
      min_release_to_detect = suppressWarnings(min(days_release_to_detect, na.rm = TRUE)),
      max_release_to_detect = suppressWarnings(max(days_release_to_detect, na.rm = TRUE)),
      .groups = "drop"
    )
}
