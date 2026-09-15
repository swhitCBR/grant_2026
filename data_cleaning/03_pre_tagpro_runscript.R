#' Run script for TagPro preprocessing
#'
#' Incorporates the preprocess_for_tagpro function and executes it on 2026 data
#' using the tags_SURVUSE_OR_ALIVE_or_EUTH subset by default.
#'
#' Loads tag subsets pre-built by data_cleaning/01_create_tag_subsets.R
#' and raw CSV data from data_cleaning/01_load_csvs.R. Filters data to the 
#' specified subset, saves subset CSVs to data/clean/pre_tagpro/, and runs
#' TagPro preprocessing to generate formatted outputs and review workbook.
#'
#' To process a different subset, modify the subset_name variable below.
#'
#' Prerequisites: 
#'   - Run 01_load_csvs.R first to generate data/clean/csv_fl_ls.rds
#'   - Run 01_create_tag_subsets.R to generate data/clean/tag_subsets_ls.rds

if(getwd() != "c:/repos/grant_2026"){
  setwd("c:/repos/grant_2026")}

library(dplyr)
library(openxlsx)

# ============================================================================
# TagPro Preprocessing Function
# ============================================================================
#' Preprocess raw tag, node, and event data for TagPro
#'
#' Reads raw CSVs (tags, nodes, events) from a data directory, applies TagPro-
#' compatible formatting to required fields, and optionally fixes release_river_km
#' to a constant per location and/or fixes bucket to a constant value. Writes 
#' formatted CSVs and a review workbook.
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
#'   - tags_tagpro: processed tags data
#'   - nodes_tagpro: processed nodes data
#'   - events_tagpro: processed events data
#'   - tags_required_cols, nodes_required_cols, events_required_cols: column vectors

preprocess_for_tagpro <- function(
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
    )

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
    events_required_cols = events_required_cols
  ))
}

# ============================================================================
# Main Execution
# ============================================================================

# Load pre-built data from the pipeline
csv_fl_ls <- readRDS("data/clean/csv_fl_ls.rds")
tag_subsets_ls <- readRDS("data/clean/tag_subsets_ls.rds")

tags_raw <- csv_fl_ls$GPUD2026_tags_17Aug2026
events_raw <- csv_fl_ls$GPUD2026_events_17Aug2026
nodes_raw <- csv_fl_ls$GPUD2026_nodes_12Aug2026

cat("Data loaded from data/clean/\n")
cat("Tags:", nrow(tags_raw), "rows\n")
cat("Events:", nrow(events_raw), "rows\n")
cat("Nodes:", nrow(nodes_raw), "rows\n\n")

cat("Available tag subsets:\n")
cat(paste(" -", names(tag_subsets_ls), collapse = "\n"), "\n\n")

# DEFAULT: Process this subset
subset_name <- "tags_SURVUSE_OR_ALIVE_or_EUTH"

cat("Processing tag subset:", subset_name, "\n")
cat("Number of tags:", nrow(tag_subsets_ls[[subset_name]]), "\n")

# Function to filter events and nodes by tag subset
filter_events_nodes <- function(tag_subset, events_raw, nodes_raw) {
  subset_tag_codes <- unique(tag_subset$tag_code)
  events_subset <- events_raw |> filter(tag_code %in% subset_tag_codes)
  node_codes_in_events <- unique(events_subset$node_code)
  nodes_subset <- nodes_raw |> filter(node_code %in% node_codes_in_events)
  return(list(tags = tag_subset, events = events_subset, nodes = nodes_subset))
}

# Filter events and nodes for the selected subset
subset_data <- filter_events_nodes(
  tag_subsets_ls[[subset_name]], 
  events_raw, 
  nodes_raw
)

cat("Number of events:", nrow(subset_data$events), "\n")
cat("Number of nodes:", nrow(subset_data$nodes), "\n\n")

# Create output directory for pre-tagpro CSVs
pre_tagpro_csv_dir <- "data/clean/pre_tagpro"
if (!dir.exists(pre_tagpro_csv_dir)) {
  dir.create(pre_tagpro_csv_dir, recursive = TRUE)
}

# Write subset CSVs to data/clean/pre_tagpro/
write.csv(subset_data$tags, file.path(pre_tagpro_csv_dir, "tags.csv"), row.names = FALSE)
write.csv(subset_data$events, file.path(pre_tagpro_csv_dir, "events.csv"), row.names = FALSE)
write.csv(subset_data$nodes, file.path(pre_tagpro_csv_dir, "nodes.csv"), row.names = FALSE)

cat("Subset CSVs saved to:", pre_tagpro_csv_dir, "\n\n")

# Set output directory for processed TagPro data
output_dir <- "data/clean/pre_tagpro"

# Run preprocessing with river_km lookup
cat("Running TagPro preprocessing...\n")
tryCatch({
  preprocess_for_tagpro(
    raw_data_dir = pre_tagpro_csv_dir,
    output_dir = output_dir,
    fix_river_km_by_location = c(
      "Rock Island Tailrace" = 730,
      "Priest Rapids Tailrace" = 246.0015
    ),
    write_files = TRUE
  )
  cat("\n✓ TagPro preprocessing complete!\n")
  cat("  Subset:", subset_name, "\n")
  cat("  Number of tags:", nrow(subset_data$tags), "\n")
  cat("  Number of events:", nrow(subset_data$events), "\n")
  cat("  Number of nodes:", nrow(subset_data$nodes), "\n")
  cat("  Intermediate CSVs saved to:", pre_tagpro_csv_dir, "\n")
  cat("  Processed output saved to:", output_dir, "\n")
}, error = function(e) {
  cat("\n✗ Error during preprocessing\n")
  cat("  Error message:", e$message, "\n")
})
