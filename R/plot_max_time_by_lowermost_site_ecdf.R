#' Plot empirical CDF of maximum activation-to-detection time by lowermost site
#'
#' Builds an empirical cumulative distribution (ECDF) plot of
#' \code{max_days_activate_to_detect} from
#' \code{\link{compute_max_time_by_lowermost_site}}, colored by each tag's
#' lowermost (furthest downstream) detected site, faceted by species.
#'
#' @inheritParams compute_max_time_by_lowermost_site
#'
#' @return A ggplot object.
#'
#' @keywords QAQC visualization
plot_max_time_by_lowermost_site_ecdf <- function(tags_dat_wrepID_in, events_dat_in, node_dat_in) {

  library(ggplot2)
  source("R/get_lowermost_site_palette.R")

  tag_max_times <- compute_max_time_by_lowermost_site(tags_dat_wrepID_in, events_dat_in, node_dat_in)

  # Order sites upstream to downstream for a sensible legend order
  site_order <- tag_max_times |>
    dplyr::distinct(lowermost_site, river_kilometer) |>
    dplyr::arrange(dplyr::desc(river_kilometer)) |>
    dplyr::pull(lowermost_site)

  site_palette <- get_lowermost_site_palette(tag_max_times)

  tag_max_times <- tag_max_times |>
    dplyr::mutate(lowermost_site = factor(lowermost_site, levels = site_order))

  ggplot(tag_max_times, aes(x = max_days_activate_to_detect, color = lowermost_site)) +
    stat_ecdf() +
    facet_wrap(~spp) +
    scale_color_manual(values = site_palette[site_order]) +
    labs(
      title = "Empirical CDF of maximum time from activation to detection, by lowermost site reached",
      x = "Max days from activation to detection",
      y = "Cumulative proportion of tags",
      color = "Lowermost site"
    ) +
    theme_minimal()
}
