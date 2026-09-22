#' Plot Detection Time Intervals with Outlier Comparison
#'
#' Creates a side-by-side ggplot comparison showing detection intervals for the full 
#' dataset and a subset with extreme outliers removed.
#'
#' @param events_data Data frame with columns: first_datetime, last_datetime, 
#'   location, node_code, river_km (or location_km). Should include detection time data.
#' @param exclude_node_codes Numeric vector of node codes to exclude from the subset plot.
#'   Default: c(305, 306) for the extreme Wanapum BRZ outliers.
#'
#' @return A ggplot object showing side-by-side comparison using patchwork
#'
#' @details
#' Creates two plots arranged horizontally:
#' - Left: Full dataset ordered by first_datetime
#' - Right: Subset excluding specified node codes, ordered by first_datetime
#'
#' This visualization helps identify and assess the impact of extreme outliers
#' on data interpretation.
#'
#' @keywords assumption_check
#' @export
#' @examples
#' \dontrun{
#' plot <- plot_detection_intervals_comparison(events_df)
#' print(plot)
#' }

plot_detection_intervals_comparison <- function(events_data, exclude_node_codes = c(305, 306)) {
  
  library(ggplot2)
  library(dplyr)
  library(patchwork)
  
  # Helper function to prepare and plot data
  plot_intervals <- function(data, title_suffix = "") {
    
    plot_data <- data |>
      mutate(
        # Convert to POSIXct if they're character strings
        first_datetime = as.POSIXct(first_datetime),
        last_datetime = as.POSIXct(last_datetime),
        # Add row number for each detection interval
        row_id = row_number()
      ) |>
      # Create a location label with river_km for ordering
      mutate(
        location_label = if ("river_km" %in% names(data)) {
          paste0(location, " (", river_km, " km)")
        } else if ("location_km" %in% names(data)) {
          paste0(location, " (", location_km, " km)")
        } else {
          location
        }
      )
    
    # Sort by first_datetime to order detections chronologically
    plot_data <- plot_data |>
      arrange(first_datetime)
    
    # Create ordered factor for rows (each row gets its own y position)
    plot_data <- plot_data |>
      mutate(row_label = factor(row_id, levels = unique(row_id)))
    
    # Create the plot
    p <- ggplot(plot_data, aes(y = row_label, color = location)) +
      geom_segment(
        aes(x = first_datetime, xend = last_datetime, yend = row_label),
        linewidth = 1.2,
        alpha = 0.8
      ) +
      labs(
        title = paste0("Detection Time Intervals", title_suffix),
        subtitle = paste0("n = ", nrow(plot_data), " records"),
        x = "Detection DateTime",
        y = "Detection Record (ordered by first_datetime)",
        color = "Location"
      ) +
      theme_minimal() +
      theme(
        axis.text.y = element_text(size = 7),
        plot.title = element_text(size = 11, face = "bold"),
        plot.subtitle = element_text(size = 9),
        axis.title = element_text(size = 10, face = "bold"),
        legend.position = "right",
        legend.text = element_text(size = 8),
        legend.title = element_text(size = 9)
      )
    
    return(p)
  }
  
  # Create full dataset plot
  p_full <- plot_intervals(events_data, " (Full Dataset)")
  
  # Create subset plot (excluding outlier node codes)
  events_subset <- events_data |>
    filter(!node_code %in% exclude_node_codes)
  
  p_subset <- plot_intervals(events_subset, paste0(" (Excluding Nodes ", paste(exclude_node_codes, collapse = ", "), ")"))
  
  # Combine plots side-by-side with shared legend
  combined_plot <- p_full + p_subset + 
    plot_layout(ncol = 2, guides = "collect") &
    theme(legend.position = "bottom")
  
  return(combined_plot)
}
