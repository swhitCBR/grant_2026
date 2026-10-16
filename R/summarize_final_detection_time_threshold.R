#' Summarize and plot time from tag activation to final detection, for
#' events far past activation
#'
#' Same computation as \code{\link{summarize_final_detection_time}}, but the
#' input event data is first filtered to events whose own time since
#' activation (timediff_last) exceeds a threshold, before summarizing final
#' detection time per tag. Useful for isolating tags with unusually long
#' detection tails (e.g. from emigration well after activation, or from
#' misassigned tag_codes) for the taglife analysis.
#'
#' @param events_w_activation_in Data frame of detection events with columns
#'   tag_code, last_datetime, tag_activation_time, tag_AssignedRelease,
#'   release_location, location, and timediff_last (days from activation to
#'   that event's last_datetime), as produced in
#'   taglife/eval_survival_data_to_inform_taglife.R (location comes from the
#'   nodes_pretagpro join, i.e. the node/location where each event was
#'   detected).
#' @param timediff_last_min Numeric threshold; only events with
#'   timediff_last > timediff_last_min are retained before summarizing.
#'   Defaults to 60.
#'
#' @return A named list with:
#'   \describe{
#'     \item{summary_tab_ls}{A list of tibbles, one per release_location,
#'       each with one row per tag_AssignedRelease level containing n_tags
#'       and the mean/median/min/max days from activation to final
#'       detection, restricted to the filtered events.}
#'     \item{summary_tab_by_last_loc_ls}{A list of tibbles, one per last
#'       detection location (the node location of each tag's final
#'       detection), each with one row per tag_AssignedRelease level
#'       containing n_tags and the mean/median/min/max days from activation
#'       to final detection, restricted to the filtered events.}
#'     \item{hist_plot}{A ggplot histogram of days from activation to final
#'       detection, faceted by tag_AssignedRelease, restricted to the
#'       filtered events.}
#'   }
#'
#' @keywords taglife visualization tabulate
#'
#' @examples
#' \dontrun{
#' final_detect_over60_res <- summarize_final_detection_time_threshold(events_w_activation)
#' final_detect_over60_res$summary_tab_ls
#' final_detect_over60_res$summary_tab_by_last_loc_ls
#' final_detect_over60_res$hist_plot
#' }
summarize_final_detection_time_threshold <- function(events_w_activation_in, timediff_last_min = 60) {

  library(dplyr)
  library(ggplot2)

  parse_dt <- function(x) {
    if (inherits(x, "POSIXct")) return(x)
    as.POSIXct(x, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
  }

  events_subset <- events_w_activation_in |>
    filter(timediff_last > timediff_last_min)

  # One row per tag: time (and location) of its last detection across all
  # (filtered) events, and the elapsed time since activation. slice_max
  # keeps the whole row for the max last_dt, so the node "location" for
  # that row is the tag's last-detection location.
  tag_final_detect <- events_subset |>
    mutate(
      last_dt = parse_dt(last_datetime),
      tag_activation_dt = parse_dt(tag_activation_time)
    ) |>
    group_by(tag_code, tag_AssignedRelease, release_location) |>
    slice_max(last_dt, n = 1, with_ties = FALSE) |>
    ungroup() |>
    rename(final_detection_time = last_dt, last_detection_location = location) |>
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

  # Breakdown by last detection location instead of release location
  summary_tab_by_last_loc <- tag_final_detect |>
    group_by(last_detection_location, tag_AssignedRelease) |>
    summarise(
      n_tags = n(),
      mean_days = mean(days_activation_to_final_detect, na.rm = TRUE),
      median_days = median(days_activation_to_final_detect, na.rm = TRUE),
      min_days = suppressWarnings(min(days_activation_to_final_detect, na.rm = TRUE)),
      max_days = suppressWarnings(max(days_activation_to_final_detect, na.rm = TRUE)),
      .groups = "drop"
    )

  summary_tab_by_last_loc_ls <- split(summary_tab_by_last_loc, summary_tab_by_last_loc$last_detection_location)

  hist_plot <- ggplot(tag_final_detect, aes(x = days_activation_to_final_detect)) +
    geom_histogram(binwidth = 2, boundary = 0) +
    facet_wrap(~tag_AssignedRelease) +
    labs(
      title = paste0("last detection - tag activation by replicate (timediff_last > ", timediff_last_min, ")"),
      x = "Days from activation to final detection",
      y = "Number of tags"
    ) +
    theme_minimal()

  list(
    summary_tab_ls = summary_tab_ls,
    summary_tab_by_last_loc_ls = summary_tab_by_last_loc_ls,
    hist_plot = hist_plot
  )
}
