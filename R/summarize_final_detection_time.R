#' Summarize and plot time from tag activation to final detection, by
#' assigned release group
#'
#' For each tag, computes the elapsed time (in days) between tag activation
#' and its final (last) detection across all detection events, then
#' summarizes and visualizes that distribution across levels of
#' tag_AssignedRelease.
#'
#' @param events_w_activation_in Data frame of detection events with columns
#'   tag_code, last_datetime, tag_activation_time, tag_AssignedRelease, and
#'   release_location. Datetimes are expected in "%Y-%m-%d %H:%M:%S" format
#'   (as produced by joining data/clean/pre_tagpro/events.csv to tags.csv).
#'
#' @return A named list with:
#'   \describe{
#'     \item{summary_tab_ls}{A list of tibbles, one per release_location,
#'       each with one row per tag_AssignedRelease level containing n_tags
#'       and the mean/median/min/max days from activation to final
#'       detection.}
#'     \item{hist_plot}{A ggplot histogram of days from activation to final
#'       detection, faceted by tag_AssignedRelease.}
#'   }
#'
#' @keywords taglife visualization tabulate
#'
#' @examples
#' \dontrun{
#' final_detect_res <- summarize_final_detection_time(events_w_activation)
#' final_detect_res$summary_tab_ls
#' final_detect_res$hist_plot
#' }
summarize_final_detection_time <- function(events_w_activation_in) {

  library(dplyr)
  library(ggplot2)

  parse_dt <- function(x) as.POSIXct(x, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")

  # One row per tag: time of its last detection across all events, and the
  # elapsed time since activation
  tag_final_detect <- events_w_activation_in |>
    mutate(
      last_dt = parse_dt(last_datetime),
      tag_activation_dt = parse_dt(tag_activation_time)
    ) |>
    group_by(tag_code, tag_AssignedRelease, release_location) |>
    summarise(
      final_detection_time = max(last_dt),
      tag_activation_dt = dplyr::first(tag_activation_dt),
      .groups = "drop"
    ) |>
    mutate(
      days_activation_to_final_detect = as.numeric(
        difftime(final_detection_time, tag_activation_dt, units = "days")
      )
    )

  summary_tab <- tag_final_detect |>
    group_by(release_location, tag_AssignedRelease) |>
    summarise(
      n_tags = n(),
      mean_days = mean(days_activation_to_final_detect, na.rm = TRUE),
      median_days = median(days_activation_to_final_detect, na.rm = TRUE),
      min_days = suppressWarnings(min(days_activation_to_final_detect, na.rm = TRUE)),
      max_days = suppressWarnings(max(days_activation_to_final_detect, na.rm = TRUE)),
      .groups = "drop"
    )

  # Split into a list with one summary table per release location
  summary_tab_ls <- split(summary_tab, summary_tab$release_location)

  hist_plot <- ggplot(tag_final_detect, aes(x = days_activation_to_final_detect)) +
    geom_histogram(binwidth = 2, boundary = 0) +
    facet_wrap(~tag_AssignedRelease) +
    labs(
      title = "last detection - tag activation by replicate",
      x = "Days from activation to final detection",
      y = "Number of tags"
    ) +
    theme_minimal()

  list(summary_tab_ls = summary_tab_ls, hist_plot = hist_plot)
}
