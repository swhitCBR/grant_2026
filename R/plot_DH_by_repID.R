#' Plot detection history by replicate ID
#'
#' Creates a series of tile plots showing the count of detected tags at each
#' detection node, organized by replicate ID. One plot is created per species
#' and release location combination. Nodes are ordered by river kilometer from
#' upstream to downstream. For Priest Rapids release locations, only sites
#' downstream of Priest Rapids are included.
#'
#' @param summary_results_ls A named list from \code{get_conting_tabs},
#'   \code{tag_rel_tagger_summ_tb}, etc. Must contain \code{$DH_summ}
#'   element with detection history summaries.
#' @param node_dat_in Data frame with node metadata including \code{location}
#'   and \code{river_kilometer} columns. If NULL, nodes will not be filtered
#'   by release location upstream threshold.
#'
#' @return A list of ggplot objects, one per species-release location combination.
#'   Each plot shows detection nodes on the x-axis (ordered by river km),
#'   replicate IDs on the y-axis, and tile fill color representing tag detection counts.
#'
#' @keywords QAQC quarto tabulate
#' @export
#'
#' @examples
#' \dontrun{
#' dh_plots <- plot_DH_by_repID(summary_results_ls)
#' dh_plots[[1]]  # View first plot
#' }
plot_DH_by_repID <- function(summary_results_ls, node_dat_in = NULL) {
  
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  
  # Extract detection history summary
  DH_summ <- summary_results_ls[["DH_summ"]]
  
  # Get unique species and release locations
  spp_list <- unique(DH_summ$spp)
  rel_loc_list <- unique(DH_summ$release_location)
  
  # Detection node columns (exclude metadata columns)
  node_cols <- setdiff(
    names(DH_summ),
    c("spp", "release_location", "repID", "fish_status")
  )
  
  # Create node ordering from river_kilometer if node_dat provided
  node_order <- NULL
  node_col_to_km <- NULL
  priest_rapids_threshold_km <- NULL
  
  if (!is.null(node_dat_in)) {
    # Get unique nodes with their river_kilometer values, ordered downstream
    node_km_df <- node_dat_in |>
      distinct(location, river_kilometer) |>
      arrange(desc(river_kilometer))  # Upstream to downstream
    
    # Create mapping from location names to river_km
    node_order <- setNames(node_km_df$river_kilometer, node_km_df$location)
    
    # Create mapping from node column names (with dots) to river_km
    node_col_names <- gsub(" ", "\\.", node_km_df$location)  # Convert spaces to dots
    node_col_to_km <- setNames(node_km_df$river_kilometer, node_col_names)
    
    # Find the minimum river_km for Priest Rapids sites
    priest_rapids_sites <- node_km_df |>
      filter(grepl("Priest", location))
    
    if (nrow(priest_rapids_sites) > 0) {
      priest_rapids_threshold_km <- min(priest_rapids_sites$river_kilometer)
    }
  }
  
  # Create a list to store plots
  plot_list <- list()
  plot_names <- character()
  
  # Create one plot per species-release location combination
  for (spp in spp_list) {
    for (rel_loc in rel_loc_list) {
      
      # Skip NA species or release locations
      if (is.na(spp) || is.na(rel_loc)) {
        next
      }
      
      # Filter data for this species and release location
      plot_data <- DH_summ |>
        filter(spp == !!spp, release_location == !!rel_loc) |>
        # Remove rows with NA in fish_status
        filter(!is.na(fish_status)) |>
        # Pivot longer to get nodes as a column
        pivot_longer(
          cols = all_of(node_cols),
          names_to = "node",
          values_to = "count"
        )
      
      # Filter out upstream sites for Priest Rapids releases
      if (grepl("Priest", rel_loc) && !is.null(priest_rapids_threshold_km)) {
        # Map node column names to river_km values
        plot_data <- plot_data |>
          mutate(
            river_km = node_col_to_km[node]
          ) |>
          filter(is.na(river_km) | river_km <= priest_rapids_threshold_km) |>
          select(-river_km)
      }
      
      # Order nodes by river_kilometer if available
      if (!is.null(node_col_to_km)) {
        # Sort node columns by river_km (descending for upstream to downstream order)
        sorted_nodes <- names(sort(node_col_to_km, decreasing = TRUE))
        
        plot_data <- plot_data |>
          mutate(
            node = factor(
              node,
              levels = sorted_nodes
            )
          )
      } else {
        # Fallback to original ordering if no node data provided
        plot_data <- plot_data |>
          mutate(
            node = factor(
              node,
              levels = c(
                "Vernita.Bridge", "Crescent.Bar", "Sunland",
                "Wanapum.BRZ", "Wanapum", "Wanapum.Tailrace",
                "Mattawa", "Lower.Ringold", "White.Bluffs",
                "Priest.BRZ", "Priest", "Priest.Tailrace", "Hanford"
              )
            )
          )
      }
      
      # Sort by repID
      plot_data <- plot_data |> arrange(repID)
      
      # Create the tile plot
      p <- ggplot(plot_data, aes(x = node, y = factor(repID), fill = count)) +
        geom_tile(colour = "white", size = 0.5) +
        scale_fill_viridis_c(option = "plasma", name = "Tag Count") +
        facet_wrap(~fish_status, scales = "free_y") +
        labs(
          title = paste0(spp, " - ", rel_loc),
          x = "Detection Node",
          y = "Replicate ID"
        ) +
        theme_minimal() +
        theme(
          axis.text.x = element_text(angle = 45, hjust = 1),
          plot.title = element_text(face = "bold", size = 12),
          legend.position = "right"
        )
      
      # Store plot and create name
      plot_name <- paste0(spp, "_", gsub(" ", "_", rel_loc))
      plot_list[[plot_name]] <- p
      plot_names <- c(plot_names, plot_name)
    }
  }
  
  return(plot_list)
}
