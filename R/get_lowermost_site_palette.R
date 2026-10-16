#' Build a color palette for lowermost detection sites, shading sites that
#' share a common first word (e.g. "Wanapum", "Wanapum BRZ",
#' "Wanapum Tailrace") as different shades of the same base color
#'
#' Groups sites by their first word, assigns each group a distinct base hue,
#' and within a group assigns progressively darker shades of that hue going
#' from furthest upstream to furthest downstream. Groups with only one site
#' get the plain base hue.
#'
#' @param site_river_km A data frame (or tibble) with one row per distinct
#'   site, containing columns lowermost_site and river_kilometer.
#'
#' @return A named character vector of hex colors, named by lowermost_site.
#'
#' @keywords QAQC visualization
get_lowermost_site_palette <- function(site_river_km) {

  site_info <- site_river_km |>
    dplyr::distinct(lowermost_site, river_kilometer) |>
    dplyr::mutate(site_group = sub("^(\\S+).*", "\\1", lowermost_site))

  groups <- unique(site_info$site_group)
  base_hues <- stats::setNames(scales::hue_pal()(length(groups)), groups)

  site_info <- site_info |>
    dplyr::group_by(site_group) |>
    # Upstream (larger river_kilometer) sites get lighter shades, downstream
    # sites get darker shades
    dplyr::arrange(dplyr::desc(river_kilometer), .by_group = TRUE) |>
    dplyr::mutate(n_in_group = dplyr::n(), shade_rank = dplyr::row_number()) |>
    dplyr::ungroup()

  site_info$color <- vapply(seq_len(nrow(site_info)), function(i) {
    base <- base_hues[[site_info$site_group[i]]]
    n <- site_info$n_in_group[i]
    if (n == 1) {
      return(base)
    }
    # Shades range from a light tint of the base hue to the full base hue
    grDevices::colorRampPalette(c("gray85", base))(n + 1)[-1][site_info$shade_rank[i]]
  }, character(1))

  stats::setNames(site_info$color, site_info$lowermost_site)
}
