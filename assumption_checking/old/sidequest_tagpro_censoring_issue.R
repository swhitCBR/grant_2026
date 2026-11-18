# Load pre-processed TagPro data from pre_tagpro folder
library(dplyr)

# Define paths to pre_tagpro CSV files
pre_tagpro_dir <- "data/clean/pre_tagpro"

# Load CSV files
tags <- read.csv(file.path(pre_tagpro_dir, "tags.csv"))
events <- read.csv(file.path(pre_tagpro_dir, "events.csv"))
nodes <- read.csv(file.path(pre_tagpro_dir, "nodes.csv"))

# tagIDs with censoring 
cens_tags <- c("G72B4A509","G72B4A509")

# G72790346

RI_BRZsel_tagpro_out <- read.csv("C:/repos/grant_2026/data/clean/post_tagpro/RI_BRZsel_ATLAS.csv",header = F)
RI_BRZsel_tagpro_out |> filter(V3 %in% c("G72790346","G72B4A509"))

RI_BRZsel_tagpro_out |> filter(V3 %in% c("G72790346")) 
RI_BRZsel_tagpro_out |> filter(V3 %in% c("G72B4A509")) 


event_tag46 <- events |> filter(tag_code=="G72790346") |> left_join(nodes, by = "node_code") |> left_join(tags, by = "tag_code") |> arrange(-river_km,first_datetime) |> mutate(first_datetime=as.POSIXct(first_datetime),last_datetime=as.POSIXct(last_datetime),interv_time=difftime(last_datetime,first_datetime,units = "secs"))

str(event_tag46)




RI_BRZsel_tagpro_out |> filter(V3 %in% c("G72B4A509")) 
event_tag09 <- events |> filter(tag_code=="G72B4A509") |> left_join(nodes, by = "node_code") |> left_join(tags, by = "tag_code") |> arrange(-river_km,first_datetime) |> mutate(first_datetime=as.POSIXct(first_datetime),last_datetime=as.POSIXct(last_datetime),interv_time=difftime(last_datetime,first_datetime,units = "secs"))


event_tag46
event_tag46 |> select(tag_code,release_location,release_date,location,river_km,first_datetime,last_datetime,interv_time)
event_tag09 |> select(tag_code,release_location,release_date,location,river_km,first_datetime,last_datetime,interv_time)

# ============================================================================
# Export both tags to xlsx, one sheet per tag (sheet name = tag code). Each sheet has the ATLAS
# record on top and the preATLAS events below it; in the events table the two rows with the
# longest interv_time are highlighted
# ============================================================================
library(openxlsx)

tag_sheets <- list(
  "G72B4A509" = event_tag09,
  "G72790346" = event_tag46) |>
  lapply(function(d) {
    d |>
      select(tag_code,release_location,release_date,location,river_km,first_datetime,last_datetime,interv_time) |>
      # difftime is written to xlsx as plain seconds. Datetimes are written as text: a highlight
      # style applied over a date cell replaces its date number format, which garbles the display.
      mutate(interv_time = as.numeric(interv_time, units = "secs"),
             across(c(first_datetime, last_datetime), ~ format(.x, "%Y-%m-%d %H:%M:%S")))
  })

# ATLAS (post-TagPro) rows for each tag; the ATLAS csv has no header, so use the column names
# assigned to this same file further down in this script
atlas_names <- c("release_spp", "num1", "tag_code", "release_time", "detection_time",
                 "site_name", "num2", "lst_dt")
atlas_sheets <- list(
  "G72B4A509" = RI_BRZsel_tagpro_out |> filter(V3 %in% c("G72B4A509")),
  "G72790346" = RI_BRZsel_tagpro_out |> filter(V3 %in% c("G72790346"))) |>
  lapply(function(d) setNames(d, atlas_names))

wb_cens <- createWorkbook()
highlight_style <- createStyle(fgFill = "yellow")
heading_style <- createStyle(fontSize = 12, textDecoration = "bold")
for (tag in names(tag_sheets)) {
  atlas_tb <- atlas_sheets[[tag]]
  events_tb <- tag_sheets[[tag]]
  addWorksheet(wb_cens, tag)

  # top table: ATLAS record (heading in row 1, column names in row 2)
  writeData(wb_cens, tag, "ATLAS record", startRow = 1)
  addStyle(wb_cens, tag, heading_style, rows = 1, cols = 1)
  writeData(wb_cens, tag, atlas_tb, startRow = 2)

  # bottom table: events preATLAS, after one blank row
  events_heading_row <- 2 + nrow(atlas_tb) + 2
  events_header_row <- events_heading_row + 1   # column names
  writeData(wb_cens, tag, "events preATLAS", startRow = events_heading_row)
  addStyle(wb_cens, tag, heading_style, rows = events_heading_row, cols = 1)
  writeData(wb_cens, tag, events_tb, startRow = events_header_row)

  # highlight events rows (data starts below the column names): all Sunland rows for G72B4A509
  # (its two longest interv_time rows are Sunland rows, plus one shorter Sunland row), otherwise
  # the two rows with the longest interv_time
  highlight_pos <- if (tag == "G72B4A509") {
    which(events_tb$location == "Sunland")
  } else {
    order(events_tb$interv_time, decreasing = TRUE)[1:2]
  }
  highlight_rows <- events_header_row + highlight_pos
  addStyle(wb_cens, tag, highlight_style, rows = highlight_rows, cols = seq_len(ncol(events_tb)), gridExpand = TRUE)

  # widths from the table contents only, so the long headings can overflow instead of widening column A
  n_col <- max(ncol(atlas_tb), ncol(events_tb))
  chars <- sapply(seq_len(n_col), function(j) {
    max(nchar(c(names(atlas_tb)[j], as.character(atlas_tb[[j]]),
                names(events_tb)[j], as.character(events_tb[[j]]))), na.rm = TRUE)
  })
  setColWidths(wb_cens, tag, cols = seq_len(n_col), widths = pmin(chars + 2, 45))
}
saveWorkbook(wb_cens, "media/xlsx/censored_tags_detections.xlsx", overwrite = TRUE)




events |> filter(tag_code=="G72B4A509") |> left_join(nodes, by = "node_code") |> left_join(tags, by = "tag_code") |> arrange(river_km)


eventsDF_censA <- events |> filter(tag_code=="G72790346") |> left_join(nodes, by = "node_code") |> left_join(tags, by = "tag_code") |> arrange(river_km)


# eventsDF_censA$last_datetimeeventsDF_censA$first_datetime
# ============================================================================
# Plot detection time intervals by location
# ============================================================================

source("R/plot_detection_intervals.R")
source("R/plot_detection_intervals_comparison.R")

# Plot full dataset
plot_detection_intervals(eventsDF_censA)

# Plot side-by-side comparison: full vs. excluding extreme outliers
plot_detection_intervals_comparison(eventsDF_censA, exclude_node_codes = c(305, 306))

# ============================================================================
# Compute time differences between first and last detections
# ============================================================================

eventsDF_censA_time_diff <- eventsDF_censA |>
  mutate(
    first_dt = as.POSIXct(first_datetime),
    last_dt = as.POSIXct(last_datetime),
    time_diff = difftime(last_dt, first_dt, units = "mins")
  ) |>
  select(tag_code, node_code, location, river_km, first_datetime, last_datetime, time_diff) |>
  arrange(river_km)

eventsDF_censA_time_diff



brz_sel_atlas <- read.csv(file.path(atlas_dir, "RI_BRZsel_ATLAS.csv"), 
                           header = FALSE) 
names(brz_sel_atlas) <- c("release_spp", "num1", "tag_code", "release_time", 
                          "detection_time", "site_name", "num2", "lst_dt")
brz_sel_atlas |> filter(tag_code=="G72790346")




# Load all_sites ATLAS files (if needed for comparison)
ri_all_sites_atlas <- read.csv(file.path(atlas_dir, "RI_all_sites_ATLAS.csv"), 
                                header = FALSE)
names(ri_all_sites_atlas) <- c("release_spp", "num1", "tag_code", "release_time", 
                               "detection_time", "site_name", "num2", "lst_dt")

cat("\nRI All Sites ATLAS file loaded:\n")
cat(sprintf("  Rows: %d, Columns: %d\n", nrow(ri_all_sites_atlas), ncol(ri_all_sites_atlas)))
cat(sprintf("  Unique sites: %d\n", n_distinct(ri_all_sites_atlas$site_name)))
brz_sel_atlas |> filter(tag_code=="G72790346")




# # ============================================================================
# # Load post-TagPro ATLAS file for BRZsel
# # ============================================================================

# atlas_dir <- "data/clean/post_tagpro"

# # Load BRZsel ATLAS file
# brz_sel_atlas <- read.csv(file.path(atlas_dir, "RI_BRZsel_ATLAS.csv"), 
#                            header = FALSE)

# View(brz_sel_atlas)

# # Set column names based on ATLAS format
# names(brz_sel_atlas) <- c("release_spp", "num1", "tag_code", "release_time", 
#                           "detection_time", "site_name", "num2", "lst_dt")

# cat("\nBRZsel ATLAS file loaded:\n")
# cat(sprintf("  Rows: %d, Columns: %d\n", nrow(brz_sel_atlas), ncol(brz_sel_atlas)))
# cat(sprintf("  Column names: %s\n", paste(names(brz_sel_atlas), collapse = ", ")))

# cat("\nUnique sites in BRZsel ATLAS:\n")
# print(table(brz_sel_atlas$site_name))

# cat("\n=== First few rows of BRZsel ATLAS ===\n")
# head(brz_sel_atlas, 10)


