#' Plot tagger survival estimates with error bars
#'
#' Creates a ggplot comparing survival estimates across reaches, species, 
#' locations, and taggers with error bars representing 95% confidence intervals.
#'
#' @param cjs_survival_long A data frame with columns: tagger, location, species, 
#'   reach, estimate, and se. Alternatively, can pass the wide-format cjs_survival
#'   data frame which will be pivoted to long format.
#' @param save_plot Logical. If TRUE, saves the plot to assumption_checking/. 
#'   Default is FALSE.
#'
#' @return A ggplot object
#'
#' @details
#' The plot displays survival estimates by reach, faceted by species and location.
#' POOLED results are shown in black with larger points, while individual taggers
#' are shown in distinct colors with smaller points.
#'
#' @keywords assumption_check
#' @export
#' @examples
#' \dontrun{
#' plot <- get_tagger_surv_plot(atlas_results$cjs_survival_long)
#' plot
#' }

get_tagger_surv_plot <- function(cjs_survival_long, save_plot = FALSE) {
  
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(stringr)
  
  # If input is wide format (cjs_survival), convert to long format
  if ("Release to Lower Ringold_est" %in% names(cjs_survival_long)) {
    cjs_survival_long <- cjs_survival_long |>
      select(tagger, location, location_code, species, ends_with("_est"), ends_with("_se")) |>
      pivot_longer(
        cols = -c(tagger, location, location_code, species),
        names_to = "reach_col",
        values_to = "value"
      ) |>
      mutate(
        reach_key = str_remove(reach_col, "_(est|se)$"),
        estimate_type = str_extract(reach_col, "(est|se)$")
      ) |>
      select(-reach_col) |>
      pivot_wider(
        names_from = estimate_type,
        values_from = value
      ) |>
      rename(reach = reach_key, estimate = est, se = se) |>
      select(tagger, location, location_code, species, reach, estimate, se) |>
      filter(!is.na(estimate))
  }
  
  # Map reach names for cleaner display
  reach_names <- c(
    "Release to Crescent Bar" = "Release",
    "Release to Lower Ringold" = "PR—\nLowerRingold",
    "Crescent Bar to Sunland" = "CB—\nSunland",
    "Sunland to Wanapum BRZ" = "Sunland—\nWanBRZ",
    "Wanapum BRZ to Mattawa" = "WanBRZ—\nMattawa",
    "Mattawa to Priest BRZ" = "Mattawa—\nPrBRZ",
    "Priest BRZ to Lower Ringold" = "PrBRZ—\nLowerRingold"
  )
  
  # Prepare data for visualization
  plot_data <- cjs_survival_long |>
    filter(!is.na(tagger)) |>
    mutate(
      # Calculate 95% CI (1.96 * SE)
      ci_lower = estimate - 1.96 * se,
      ci_upper = estimate + 1.96 * se,
      # Clean up tagger labels - remove "TAGGER" prefix, keep just the letter or POOLED
      tagger_label = ifelse(tagger == "POOLED", "POOLED", 
                           ifelse(str_starts(tagger, "TAGGER"), str_trim(str_remove(tagger, "TAGGER")), tagger)),
      # Map location codes to release location names
      release = ifelse(location == "RI", "Rock Island", "Priest Rapids"),
      # Order release locations
      release = factor(release, levels = c("Rock Island", "Priest Rapids")),
      # Format reach names
      reach_formatted = reach_names[reach],
      # If reach not in mapping, use original
      reach_formatted = ifelse(is.na(reach_formatted), reach, reach_formatted),
      # Create ordered factor for reach_formatted
      reach_formatted = factor(
        reach_formatted,
        levels = c("Release", 
                   "CB—\nSunland", 
                   "Sunland—\nWanBRZ", 
                   "WanBRZ—\nMattawa", 
                   "Mattawa—\nPrBRZ", 
                   "PrBRZ—\nLowerRingold",
                   "PR—\nLowerRingold"),
        ordered = TRUE
      )
    ) |>
    # Remove rows with NA estimates
    filter(!is.na(estimate))
  
  # Create fill palette: POOLED in black, taggers in distinct colors
  fill_palette <- c(
    "A" = "#1B9E77",      # Teal
    "B" = "#D95F02",      # Orange
    "C" = "#7570B3",      # Purple
    "POOLED" = "#000000"  # Black for POOLED
  )
  
  # Create size palette: POOLED larger, taggers smaller
  size_palette <- c(
    "A" = 2.5,
    "B" = 2.5,
    "C" = 2.5,
    "POOLED" = 4
  )
  
  # Create the plot
  plot <- ggplot(plot_data, aes(x = reach_formatted, y = estimate, 
                                fill = tagger_label, 
                                size = tagger_label, 
                                group = tagger_label)) +
    geom_errorbar(
      aes(ymin = ci_lower, ymax = ci_upper),
      position = position_dodge(width = 0.3),
      width = 0.2,
      linewidth = 0.8,
      color = "gray30"
    ) +
    geom_point(position = position_dodge(width = 0.3), shape = 21, alpha = 0.85, color = "black", stroke = 0.3) +
    facet_grid(species ~ release, scales = "free_x", space = "free_x") +
    scale_y_continuous(
      limits = c(0.67, 1.02),
      labels = scales::label_number(accuracy = 0.01)
    ) +
    scale_fill_manual(values = fill_palette) +
    scale_size_manual(values = size_palette) +
    labs(
      title = "CJS Survival Estimates by Tagger, Release Location, and Reach",
      x = "River Reach",
      y = "Survival Estimate",
      fill = "",
      size = ""
    ) +
    theme_gray() +
    theme(
      axis.text.x = element_text(angle = 0, hjust = 0.5, size = 9, lineheight = 1.2),
      axis.title = element_text(size = 11, face = "bold"),
      plot.title = element_text(size = 13, face = "bold"),
      plot.subtitle = element_text(size = 10),
      legend.position = "bottom",
      legend.box = "horizontal",
      strip.text = element_text(size = 10, face = "bold")
    )
  
  # Optionally save the plot
  if (save_plot) {
    output_dir <- "assumption_checking"
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE)
    }
    
    # Save as PNG
    png_path <- file.path(output_dir, "tagger_survival_comparison.png")
    ggsave(png_path, plot, width = 12, height = 8, dpi = 300)
    cat("✓ Plot saved to:", png_path, "\n")
    
    # Save as PDF
    pdf_path <- file.path(output_dir, "tagger_survival_comparison.pdf")
    ggsave(pdf_path, plot, width = 12, height = 8)
    cat("✓ Plot saved to:", pdf_path, "\n")
  }
  
  return(plot)
}
