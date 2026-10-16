#' Plot cumulative count (not proportion) of tags reaching detection, by
#' lowermost site
#'
#' Builds a step plot of the cumulative number of tags (not the cumulative
#' proportion, as in an ECDF) whose max_days_activate_to_detect from
#' \code{\link{compute_max_time_by_lowermost_site}} has been reached,
#' colored by each tag's lowermost (furthest downstream) detected site and
#' faceted by species. Because the y-axis is a raw count, each line's final
#' height is the number of tags with that lowermost site rather than 1, so
#' lines end at different heights.
#'
#' @inheritParams compute_max_time_by_lowermost_site
#'
#' @return A ggplot object.
#'
#' @keywords QAQC visualization
plot_cumulative_count_by_lowermost_site <- function(tags_dat_wrepID_in, events_dat_in, node_dat_in) {

  library(ggplot2)
  source("R/get_lowermost_site_palette.R")

  tag_max_times <- compute_max_time_by_lowermost_site(tags_dat_wrepID_in, events_dat_in, node_dat_in) |>
    dplyr::filter(!is.na(max_days_activate_to_detect))

  # Order sites upstream to downstream for a sensible legend order
  site_order <- tag_max_times |>
    dplyr::distinct(lowermost_site, river_kilometer) |>
    dplyr::arrange(dplyr::desc(river_kilometer)) |>
    dplyr::pull(lowermost_site)

  site_palette <- get_lowermost_site_palette(tag_max_times)

  cumul_dat <- tag_max_times |>
    dplyr::group_by(spp, lowermost_site) |>
    dplyr::arrange(max_days_activate_to_detect, .by_group = TRUE) |>
    dplyr::mutate(cum_n = dplyr::row_number()) |>
    dplyr::ungroup()

  # Prepend a (0, 0) point per group so each step function starts at the
  # origin rather than jumping straight to a count of 1
  start_dat <- cumul_dat |>
    dplyr::distinct(spp, lowermost_site) |>
    dplyr::mutate(max_days_activate_to_detect = 0, cum_n = 0)

  cumul_dat <- dplyr::bind_rows(start_dat, cumul_dat) |>
    dplyr::mutate(lowermost_site = factor(lowermost_site, levels = site_order)) |>
    dplyr::arrange(spp, lowermost_site, max_days_activate_to_detect)

  ggplot(cumul_dat, aes(x = max_days_activate_to_detect, y = cum_n, color = lowermost_site)) +
    geom_step(direction = "hv") +
    facet_wrap(~spp) +
    scale_color_manual(values = site_palette[site_order]) +
    labs(
      title = "Cumulative number of tags reaching detection, by lowermost site reached",
      x = "Max days from activation to detection",
      y = "Cumulative number of tags",
      color = "Lowermost site"
    ) +
    theme_minimal()
}
