#' Plot tagger survival estimates with 95% confidence intervals
#'
#' Creates a ggplot comparing survival estimates across releases, reaches, 
#' and taggers with error bars representing 95% confidence intervals.
#'
#' Output: Saves plot as PNG and PDF to assumption_checking/

if(getwd() != "c:/repos/grant_2026"){
  setwd("c:/repos/grant_2026")}

library(dplyr)
library(tidyr)
library(ggplot2)
library(stringr)

# ============================================================================
# Load survival estimates
# ============================================================================

survival_est <- readRDS("assumption_checking/cjs_survival_estimates.rds")

cat("Loaded survival estimates:\n")
print(head(survival_est))

# ============================================================================
# Prepare data for visualization
# ============================================================================

# Extract reach names and prepare long format
reach_names <- c(
  "Release_to_CB" = "Release to CB",
  "CB_to_Sunland" = "CB to Sunland",
  "Sunland_to_WanBRZ" = "Sunland to WanBRZ",
  "WanBRZ_to_Mattawa" = "WanBRZ to Mattawa",
  "Mattawa_to_PrBRZ" = "Mattawa to PrBRZ",
  "PrBRZ_to_LowerRingold" = "PrBRZ to LowerRingold",
  "Release_to_LowerRingold" = "Release to LowerRingold"  # Priest Rapids reach
)

# Pivot to long format for plotting
plot_data <- survival_est |>
  # Select only estimate and se columns
  select(location_group, tagger, ends_with("_est"), ends_with("_se")) |>
  # Filter out rows with missing tagger
  filter(!is.na(tagger)) |>
  # Separate location and species
  mutate(
    release = ifelse(str_detect(location_group, "Rock Island"), "Rock Island", "Priest Rapids"),
    species = ifelse(str_detect(location_group, "CHN"), "Chinook", "Steelhead")
  ) |>
  select(-location_group) |>
  # Pivot longer for reaches
  pivot_longer(
    cols = -c(tagger, release, species),
    names_to = "reach_col",
    values_to = "value"
  ) |>
  # Separate reach column and estimate type
  mutate(
    reach_key = str_remove(reach_col, "_(est|se)$"),
    estimate_type = str_extract(reach_col, "(est|se)$")
  ) |>
  select(-reach_col) |>
  pivot_wider(
    names_from = estimate_type,
    values_from = value
  ) |>
  # Map reach names
  mutate(
    reach = reach_names[reach_key]
  ) |>
  select(-reach_key) |>
  # Calculate 95% CI (1.96 * SE)
  mutate(
    ci_lower = est - 1.96 * se,
    ci_upper = est + 1.96 * se,
    # Clean up tagger labels and create factor for ordering
    tagger_label = paste("Tagger", tagger),
    # Order release locations: Rock Island first, then Priest Rapids
    release = factor(release, levels = c("Rock Island", "Priest Rapids")),
    # Format reach names: consolidate all "Release" reaches to single label
    # PR reaches (including POOLED) use "PR—\nLowerRingold" to group together
    reach_formatted = case_when(
      reach == "Release to CB" ~ "Release",
      reach == "Release to LowerRingold" ~ "PR—\nLowerRingold",
      TRUE ~ str_replace(reach, " to ", "—\n")
    ),
    # Create ordered factor for reach_formatted to maintain table order
    # Rock Island order: Release, CB-Sunland, Sunland-Wanapum, Wanapum-Mattawa, Mattawa-PrBRZ, PrBRZ-LowerRingold
    # Priest Rapids order: PR-LowerRingold
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
  # Remove rows with NA estimates (e.g., PR reaches without data)
  filter(!is.na(est))

cat("\nData prepared for plotting:\n")
print(head(plot_data, 12))
cat("\nUnique combinations:\n")
print(table(plot_data$release, plot_data$reach, plot_data$tagger))

# ============================================================================
# Create plot
# ============================================================================

# Create color palette: POOLED in black, taggers in distinct colors
color_palette <- c(
  "Tagger A" = "#1B9E77",      # Teal
  "Tagger B" = "#D95F02",      # Orange
  "Tagger C" = "#7570B3",      # Purple
  "Tagger POOLED" = "#000000"  # Black for POOLED
)

# Create size palette: POOLED larger, taggers smaller
size_palette <- c(
  "Tagger A" = 2.5,
  "Tagger B" = 2.5,
  "Tagger C" = 2.5,
  "Tagger POOLED" = 4
)

# Create fill palette (for shape 21)
fill_palette <- c(
  "Tagger A" = "#1B9E77",      # Teal
  "Tagger B" = "#D95F02",      # Orange
  "Tagger C" = "#7570B3",      # Purple
  "Tagger POOLED" = "#000000"  # Black for POOLED
)

plot <- ggplot(plot_data, aes(x = reach_formatted, y = est, color = tagger_label, 
                              fill = tagger_label, size = tagger_label, group = tagger_label)) +
  geom_point(position = position_dodge(width = 0.3), shape = 21, alpha = 0.85) +
  geom_errorbar(
    aes(ymin = ci_lower, ymax = ci_upper),
    position = position_dodge(width = 0.3),
    width = 0.2,
    linewidth = 0.8
  ) +
  facet_grid(species ~ release, scales = "free_x", space = "free_x") +
  scale_y_continuous(
    limits = c(0.67, 1.02),
    labels = scales::label_number(accuracy = 0.01)
  ) +
  scale_color_manual(values = color_palette) +
  scale_fill_manual(values = fill_palette) +
  scale_size_manual(values = size_palette) +
  labs(
    title = "CJS Survival Estimates by Tagger, Release Location, and Reach",
    subtitle = "Error bars represent 95% confidence intervals",
    x = "River Reach",
    y = "Survival Estimate",
    color = "Tagger",
    fill = "Tagger",
    size = "Tagger"
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

# ============================================================================
# Save plot
# ============================================================================

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

# Save as SVG
svg_path <- file.path(output_dir, "tagger_survival_comparison.svg")
ggsave(svg_path, plot, width = 12, height = 8)
cat("✓ Plot saved to:", svg_path, "\n")

# Save as SVG
svg_path <- file.path(output_dir, "tagger_survival_comparison.svg")
ggsave(svg_path, plot, width = 12, height = 8)
cat("✓ Plot saved to:", svg_path, "\n")

# Display plot
print(plot)

cat("\n════════════════════════════════════════════════════════════\n")
cat("Tagger survival comparison plot created!\n")
cat("Outputs saved to assumption_checking/\n")
cat("════════════════════════════════════════════════════════════\n")
