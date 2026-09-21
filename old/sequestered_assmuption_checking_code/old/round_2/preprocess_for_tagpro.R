#' Preprocess raw tag, node, and event data for TagPro (Round 2: Exclude Euthanized)
#'
#' Reads raw CSVs (tags, nodes, events) from a data directory, applies TagPro-
#' compatible formatting to required fields, and optionally fixes release_river_km
#' to a constant per location and/or fixes bucket to a constant value. 
#' Filters out fish in the "Euthanized" group. Writes formatted CSVs and a review workbook.
#'
#' @param raw_data_dir Path to directory containing tags.csv, nodes.csv, events.csv
#' @param output_dir Path to output directory for TagPro-formatted files
#' @param fix_river_km_by_location Optional named vector mapping release_location
#'   values to fixed release_river_km values (e.g., c("Rock Island Tailrace" = 730,
#'   "Priest Rapids Tailrace" = 246.0015)). If NULL (default), uses the lookup
#'   table from release_river_km.csv in output_dir. If provided, overrides the
#'   lookup table for specified locations.
#' @param fix_bucket Optional integer. If provided, sets the bucket field to this
#'   constant value across all rows. If NULL (default), uses the original bucket
#'   values from the raw data.
#' @param write_files Logical. If TRUE (default), write CSVs and workbook to disk.
#'   If FALSE, only return the processed dataframes as a list.
#'
#' @return Invisibly returns a list with elements:
#'   - tags_tagpro: processed tags data (euthanized fish excluded)
#'   - nodes_tagpro: processed nodes data
#'   - events_tagpro: processed events data
#'   - tags_required_cols, nodes_required_cols, events_required_cols: column vectors
#'   - n_excluded: number of fish excluded due to euthanasia status
#'
#' @details
#' Required columns (TagPro manual, Appendix A):
#' - tags: tagger_name, bucket, length, weight, tag_code, lot, species_code,
#'         tag_date, activation_date, release_date, release_location, release_river_km, mortality
#' - nodes: node_code, deploy_date, location, river_km
#' - events: node_code, tag_code, first_datetime, last_datetime
#'
#' ROUND 2 MODIFICATION: Fish with mortality status "Euthanized" are excluded from
#' analysis to focus on natural post-release survival.
#'
preprocess_for_tagpro_r2 <- function(
    raw_data_dir,
    output_dir,
    fix_river_km_by_location = NULL,
    fix_bucket = NULL,
    write_files = TRUE) {

  # Helper functions ----

  #' Reorder a data frame so required_cols come first (in that order),
  #' followed by all remaining columns in their original order
  reorder_required_first <- function(df, required_cols) {
    dplyr::select(df, dplyr::all_of(required_cols), dplyr::everything())
  }

  #' Add df to wb as a new sheet, with required_cols ordered first and
  #' highlighted with a light green fill (header and data cells)
  add_tagpro_sheet <- function(wb, sheet_name, df, required_cols) {
    df <- reorder_required_first(df, required_cols)
    openxlsx::addWorksheet(wb, sheet_name)
    openxlsx::writeData(wb, sheet_name, df)
    highlight_style <- openxlsx::createStyle(fgFill = "#C6EFCE")
    openxlsx::addStyle(
      wb, sheet_name, highlight_style,
      rows = 1:(nrow(df) + 1), cols = seq_along(required_cols),
      gridExpand = TRUE
    )
  }

  #' Reformat an ISO date (yyyy-mm-dd) or datetime (yyyy-mm-ddTHH:MM:SSZ)
  #' string as a TagPro-compatible datetime: yyyy-mm-dd hh:mm:ss
  format_tagpro_date <- function(date_str) {
    dt <- as.POSIXct(gsub("T", " ", gsub("Z$", "", date_str)), tz = "UTC")
    format(dt, "%Y-%m-%d %H:%M:%S")
  }

  # Required columns per TagPro manual ----
  tags_required_cols <- c(
    "tagger_name", "bucket", "length", "weight", "tag_code", "lot",
    "species_code", "tag_date", "activation_date", "release_date",
    "release_location", "release_river_km", "mortality"
  )
  nodes_required_cols <- c("node_code", "deploy_date", "location", "river_km")
  events_required_cols <- c("node_code", "tag_code", "first_datetime", "last_datetime")

  # Find input files ----
  csv_files <- list.files(raw_data_dir, pattern = "\\.csv$", full.names = TRUE)
  tags_file <- csv_files[grepl("tags", basename(csv_files), ignore.case = TRUE)]
  events_file <- csv_files[grepl("events", basename(csv_files), ignore.case = TRUE)]
  nodes_file <- csv_files[grepl("nodes", basename(csv_files), ignore.case = TRUE)]

  stopifnot(
    length(tags_file) == 1,
    length(events_file) == 1,
    length(nodes_file) == 1
  )

  # Set up river_km lookup ----
  if (is.null(fix_river_km_by_location)) {
    # Use lookup table from release_river_km.csv (default behavior)
    release_river_km_file <- file.path(output_dir, "release_river_km.csv")
    if (!file.exists(release_river_km_file)) {
      stop("release_river_km.csv not found in output_dir, and ",
           "fix_river_km_by_location was not provided")
    }
    release_river_km_tab <- read.csv(release_river_km_file, stringsAsFactors = FALSE)
    release_river_km_lookup <- stats::setNames(
      release_river_km_tab$release_river_km,
      release_river_km_tab$release_location
    )
  } else {
    # Use provided mapping, optionally merging with lookup table
    release_river_km_file <- file.path(output_dir, "release_river_km.csv")
    if (file.exists(release_river_km_file)) {
      release_river_km_tab <- read.csv(release_river_km_file, stringsAsFactors = FALSE)
      release_river_km_lookup <- stats::setNames(
        release_river_km_tab$release_river_km,
        release_river_km_tab$release_location
      )
      # Override with provided values
      release_river_km_lookup[names(fix_river_km_by_location)] <- fix_river_km_by_location
    } else {
      # Use only provided mapping
      release_river_km_lookup <- fix_river_km_by_location
    }
  }

  # Process tags ----
  tags_raw <- read.csv(tags_file, stringsAsFactors = FALSE)

  n_total <- nrow(tags_raw)

  tags_tagpro <- tags_raw |>
    dplyr::mutate(
      fish_tag_date = format_tagpro_date(fish_tag_date),
      species_code = dplyr::if_else(substr(species, 1, 2) == "11", "CHN", "STH"),
      tag_date = fish_tag_date,
      activation_date = format_tagpro_date(tag_activate_date),
      release_date = format_tagpro_date(tag_release_date),
      release_river_km = round(release_river_km_lookup[release_location]),
      bucket = if (!is.null(fix_bucket)) fix_bucket else bucket,
      tagger_name = tagger,
      mortality = mort_xlat,
      lot = as.integer(gsub("[^0-9]", "", lot))
    ) |>
    # ROUND 2 FILTER: Remove euthanized fish
    dplyr::filter(mortality != "Euthanized")

  n_excluded <- n_total - nrow(tags_tagpro)

  # Process nodes ----
  nodes_raw <- read.csv(nodes_file, stringsAsFactors = FALSE)

  nodes_tagpro <- nodes_raw |>
    dplyr::mutate(
      river_km = river_kilometer,
      deploy_date = format_tagpro_date(deploy_date),
      recovery_date = format_tagpro_date(recovery_date)
    )

  # Process events ----
  events_raw <- read.csv(events_file, stringsAsFactors = FALSE)

  events_tagpro <- events_raw |>
    dplyr::mutate(
      first_datetime = format_tagpro_date(first_computed_datetime),
      last_datetime = format_tagpro_date(last_computed_datetime)
    ) |>
    dplyr::select(-first_computed_datetime, -last_computed_datetime)

  # Write files if requested ----
  if (write_files) {
    if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

    write.csv(
      dplyr::select(tags_tagpro, dplyr::all_of(tags_required_cols)),
      file.path(output_dir, "tags.csv"),
      row.names = FALSE, quote = FALSE
    )

    write.csv(
      dplyr::select(nodes_tagpro, dplyr::all_of(nodes_required_cols)),
      file.path(output_dir, "nodes.csv"),
      row.names = FALSE, quote = FALSE
    )

    write.csv(
      dplyr::select(events_tagpro, dplyr::all_of(events_required_cols), tag_AssignedRelease),
      file.path(output_dir, "events.csv"),
      row.names = FALSE, quote = FALSE
    )

    # Create review workbook
    tagpro_wb <- openxlsx::createWorkbook()
    add_tagpro_sheet(tagpro_wb, "tags", tags_tagpro, tags_required_cols)
    add_tagpro_sheet(tagpro_wb, "nodes", nodes_tagpro, nodes_required_cols)
    add_tagpro_sheet(tagpro_wb, "events", events_tagpro, events_required_cols)
    openxlsx::saveWorkbook(
      tagpro_wb,
      file.path(output_dir, "tagpro_inputs.xlsx"),
      overwrite = TRUE
    )
  }

  # Return processed data invisibly
  invisible(list(
    tags_tagpro = tags_tagpro,
    nodes_tagpro = nodes_tagpro,
    events_tagpro = events_tagpro,
    tags_required_cols = tags_required_cols,
    nodes_required_cols = nodes_required_cols,
    events_required_cols = events_required_cols,
    n_excluded = n_excluded,
    n_retained = nrow(tags_tagpro)
  ))
}
