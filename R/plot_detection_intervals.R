#' Plot Detection Time Intervals by Location
#'
#' Creates a ggplot with horizontal line segments representing the time interval
#' from first_datetime to last_datetime for each detection record, organized by
#' location and ordered by river_km.
#'
#' @param events_data Data frame with columns: first_datetime, last_datetime, 
#'   location, river_km (or location_km). Should include detection time data.
#'
#' @return A ggplot object showing time intervals by location
#'
#' @details
#' Creates a visualization where each horizontal segment represents the detection
#' duration (from first to last detection time) for a record. Locations are
#' ordered along the y-axis by river_km, allowing inspection of temporal patterns
#' across river reaches.
#'
#' @keywords assumption_check
#' @export
#' @examples
#' \dontrun{
#' plot <- plot_detection_intervals(events_df)
#' print(plot)
#' }

plot_detection_intervals <- function(events_data) {
  
  library(ggplot2)
  library(dplyr)
  
  # Prepare data: ensure datetime columns are POSIXct and add row identifiers
  plot_data <- events_data |>
    mutate(
      # Convert to POSIXct if they're character strings
      first_datetime = as.POSIXct(first_datetime),
      last_datetime = as.POSIXct(last_datetime),
      # Add row number for each detection interval
      row_id = row_number()
    ) |>
    # Create a location label with river_km for ordering
    mutate(
      location_label = if ("river_km" %in% names(events_data)) {
        paste0(location, " (", river_km, " km)")
      } else if ("location_km" %in% names(events_data)) {
        paste0(location, " (", location_km, " km)")
      } else {
        location
      }
    )
  
  # Determine river_km column name
  km_col <- if ("river_km" %in% names(events_data)) "river_km" else "location_km"
  
  # Sort by first_datetime to order detections chronologically
  plot_data <- plot_data |>
    arrange(first_datetime)
  
  # Create ordered factor for rows (each row gets its own y position)
  plot_data <- plot_data |>
    mutate(row_label = factor(row_id, levels = unique(row_id)))
  
  # Create the plot - one line segment per row
  ggplot(plot_data, aes(y = row_label, color = location)) +
    geom_segment(
      aes(x = first_datetime, xend = last_datetime, yend = row_label),
      linewidth = 1.2,
      alpha = 0.8
    ) +
    labs(
      title = "Detection Time Intervals by Record",
      subtitle = "Each horizontal segment represents one detection interval (first to last datetime)",
      x = "Detection DateTime",
      y = "Detection Record (ordered by river km)",
      color = "Location"
    ) +
    theme_minimal() +
    theme(
      axis.text.y = element_text(size = 8),
      plot.title = element_text(size = 12, face = "bold"),
      plot.subtitle = element_text(size = 10),
      axis.title = element_text(size = 11, face = "bold"),
      legend.position = "right"
    )
}
