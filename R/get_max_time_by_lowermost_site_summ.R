#' Compute, for each tag, the maximum time from activation to detection at
#' its furthest-downstream (lowermost) detected site
#'
#' For every tag, identifies the lowermost detection site it reached (the
#' detected location with the smallest river_kilometer), then computes the
#' elapsed time in days between tag activation and the latest
#' (maximum) detection datetime recorded at that site.
#'
#' @param tags_dat_wrepID_in Data frame containing at least the columns
#'   tag_code, spp, and tag_activate_date.
#' @param events_dat_in Data frame of detection events with columns
#'   node_code, tag_code, and first_computed_datetime.
#' @param node_dat_in Data frame of detection nodes with columns node_code,
#'   location, and river_kilometer.
#'
#' @return A tibble with one row per tag_code that was detected at least
#'   once, containing spp, lowermost_site (the furthest-downstream location
#'   reached), river_kilometer (of that site), and
#'   max_days_activate_to_detect (time from activation to the last
#'   detection recorded at that site).
#'
#' @keywords QAQC tabulate
compute_max_time_by_lowermost_site <- function(tags_dat_wrepID_in, events_dat_in, node_dat_in) {

  parse_dt <- function(x) as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

  node_locations <- node_dat_in |>
    dplyr::distinct(node_code, location, river_kilometer)

  # Last detection datetime at each site, per tag
  tag_site_last_detect <- events_dat_in |>
    dplyr::left_join(node_locations, by = "node_code") |>
    dplyr::mutate(first_computed_datetime = parse_dt(first_computed_datetime)) |>
    dplyr::group_by(tag_code, location, river_kilometer) |>
    dplyr::summarise(last_detect = max(first_computed_datetime), .groups = "drop")

  # For each tag, the lowermost (smallest river_kilometer) site it reached
  tag_lowermost_site <- tag_site_last_detect |>
    dplyr::group_by(tag_code) |>
    dplyr::slice_min(river_kilometer, n = 1, with_ties = FALSE) |>
    dplyr::ungroup() |>
    dplyr::rename(lowermost_site = location)

  tags_dat_wrepID_in |>
    dplyr::mutate(tag_activate_date = parse_dt(tag_activate_date)) |>
    dplyr::distinct(tag_code, spp, tag_activate_date) |>
    dplyr::inner_join(tag_lowermost_site, by = "tag_code") |>
    dplyr::mutate(
      max_days_activate_to_detect = as.numeric(difftime(last_detect, tag_activate_date, units = "days"))
    ) |>
    dplyr::select(tag_code, spp, lowermost_site, river_kilometer, max_days_activate_to_detect)
}

#' Summarize maximum activation-to-detection time by lowermost detected site
#'
#' Condensed summary (n, mean, median, min, max) of
#' \code{max_days_activate_to_detect} from
#' \code{\link{compute_max_time_by_lowermost_site}}, broken out by species
#' and by each tag's lowermost detected site. Rows are ordered from
#' furthest upstream to furthest downstream site.
#'
#' @inheritParams compute_max_time_by_lowermost_site
#'
#' @return A tibble with one row per spp x lowermost_site combination,
#'   containing n, mean, median, min, and max of
#'   max_days_activate_to_detect.
#'
#' @keywords QAQC tabulate
get_max_time_by_lowermost_site_summ <- function(tags_dat_wrepID_in, events_dat_in, node_dat_in) {

  tag_max_times <- compute_max_time_by_lowermost_site(tags_dat_wrepID_in, events_dat_in, node_dat_in)

  tag_max_times |>
    dplyr::group_by(spp, lowermost_site, river_kilometer) |>
    dplyr::summarise(
      n = dplyr::n(),
      mean_max_days_activate_to_detect = mean(max_days_activate_to_detect, na.rm = TRUE),
      median_max_days_activate_to_detect = median(max_days_activate_to_detect, na.rm = TRUE),
      min_max_days_activate_to_detect = suppressWarnings(min(max_days_activate_to_detect, na.rm = TRUE)),
      max_max_days_activate_to_detect = suppressWarnings(max(max_days_activate_to_detect, na.rm = TRUE)),
      .groups = "drop"
    ) |>
    dplyr::arrange(dplyr::desc(river_kilometer), spp) |>
    dplyr::select(-river_kilometer)
}
