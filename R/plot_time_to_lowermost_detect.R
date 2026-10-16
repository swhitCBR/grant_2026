#' Plot histograms and empirical CDFs of time to lowermost-site detection
#'
#' Builds histograms and empirical cumulative distribution (ECDF) plots,
#' by species, of the elapsed time in days between tag activation/release
#' and first detection at the lowermost detection site, for tags released
#' at Rock Island Tailrace.
#'
#' @inheritParams compute_time_to_lowermost_detect
#'
#' @return A named list of ggplot objects: hist_activate_to_detect,
#'   hist_release_to_detect, ecdf_activate_to_detect, and
#'   ecdf_release_to_detect.
#'
#' @keywords QAQC visualization
plot_time_to_lowermost_detect <- function(tags_dat_wrepID_in, events_dat_in, node_dat_in) {

  library(ggplot2)

  tag_times <- compute_time_to_lowermost_detect(tags_dat_wrepID_in, events_dat_in, node_dat_in) |>
    dplyr::filter(!is.na(days_activate_to_detect))

  lowermost_site <- unique(tag_times$lowermost_site)

  make_hist <- function(var, x_lab) {
    ggplot(tag_times, aes(x = .data[[var]], fill = spp)) +
      geom_histogram(position = "identity", alpha = 0.6, bins = 30) +
      labs(
        title = paste0("Time to first detection at ", lowermost_site),
        x = x_lab,
        y = "Number of tags",
        fill = "Species"
      ) +
      theme_minimal()
  }

  make_ecdf <- function(var, x_lab) {
    ggplot(tag_times, aes(x = .data[[var]], color = spp)) +
      stat_ecdf() +
      labs(
        title = paste0("Empirical CDF of time to first detection at ", lowermost_site),
        x = x_lab,
        y = "Cumulative proportion of tags",
        color = "Species"
      ) +
      theme_minimal()
  }

  list(
    hist_activate_to_detect = make_hist("days_activate_to_detect", "Days from activation to detection"),
    hist_release_to_detect = make_hist("days_release_to_detect", "Days from release to detection"),
    ecdf_activate_to_detect = make_ecdf("days_activate_to_detect", "Days from activation to detection"),
    ecdf_release_to_detect = make_ecdf("days_release_to_detect", "Days from release to detection")
  )
}
