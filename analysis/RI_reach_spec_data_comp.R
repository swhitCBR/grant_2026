# ============================================================================
# RI reach-specific data comparison: the two tags censored in TagPro
#   1. Setup
#   2. Load data
#   3. Explore the two tags (ATLAS record and pre-ATLAS events)
#   4. Export both tags to xlsx (flagged rows highlighted)
#   5. Move nodes.csv and tags.csv to data/reach_spec_censor_fix
#   6. Revised events: drop the flagged rows
#   7. Write the revised events.csv
# Sections 4 and 6 read nodes.csv/tags.csv, so the move (5) comes after them. Run from any
# working directory: all paths below are absolute.
# ============================================================================


# ============================================================================
# 1. Setup
# ============================================================================
library(dplyr)
library(openxlsx)

repo_root <- "C:/repos/grant_2026"
pre_tagpro_dir <- file.path(repo_root, "data/clean/pre_tagpro")
post_tagpro_dir <- file.path(repo_root, "data/clean/post_tagpro")
censor_fix_dir <- file.path(repo_root, "data/reach_spec_censor_fix")
censored_xlsx <- file.path(repo_root, "media/xlsx/censored_tags_detections.xlsx")

# tagIDs with censoring
cens_tags <- c("G72790346", "G72B4A509")

dir(pre_tagpro_dir)


# ============================================================================
# 2. Load data
# ============================================================================

# pre-TagPro inputs. nodes.csv and tags.csv are moved in section 5, so on a rerun they are in
# the new folder instead; read each from wherever it currently is.
find_input <- function(file) {
  p <- file.path(c(pre_tagpro_dir, censor_fix_dir), file)
  p <- p[file.exists(p)]
  if (length(p) == 0) stop(file, " not found in ", pre_tagpro_dir, " or ", censor_fix_dir)
  p[1]
}
tags <- read.csv(find_input("tags.csv"))
events <- read.csv(find_input("events.csv"))
nodes <- read.csv(find_input("nodes.csv"))

# post-TagPro ATLAS output (no header: V3 = tag_code, V7 = number of detections at the site)
RI_BRZsel_tagpro_out <- read.csv(file.path(post_tagpro_dir, "RI_BRZsel_ATLAS.csv"), header = F)


# ============================================================================
# 3. Explore the two tags
# ============================================================================

# ATLAS record
RI_BRZsel_tagpro_out |> filter(V3 %in% cens_tags)
table(RI_BRZsel_tagpro_out$V7)
# (parentheses: %in% and |> share precedence, so without them this reads as (V3 %in% df) |> filter())
RI_BRZsel_tagpro_out |> filter(V3 %in% (RI_BRZsel_tagpro_out |> filter(V7==2) |> pull(V3)))

RI_BRZsel_tagpro_out |> filter(V3 %in% c("G72790346"))
RI_BRZsel_tagpro_out |> filter(V3 %in% c("G72B4A509"))

# pre-ATLAS events, with node locations, release info and the length of each detection interval
event_tag46 <- events |> filter(tag_code=="G72790346") |> left_join(nodes, by = "node_code") |> left_join(tags, by = "tag_code") |> arrange(-river_km,first_datetime) |> mutate(first_datetime=as.POSIXct(first_datetime),last_datetime=as.POSIXct(last_datetime),interv_time=difftime(last_datetime,first_datetime,units = "secs"))

str(event_tag46)

event_tag09 <- events |> filter(tag_code=="G72B4A509") |> left_join(nodes, by = "node_code") |> left_join(tags, by = "tag_code") |> arrange(-river_km,first_datetime) |> mutate(first_datetime=as.POSIXct(first_datetime),last_datetime=as.POSIXct(last_datetime),interv_time=difftime(last_datetime,first_datetime,units = "secs"))

event_tag46
event_tag46 |> select(tag_code,release_location,release_date,location,river_km,first_datetime,last_datetime,interv_time)
event_tag09 |> select(tag_code,release_location,release_date,location,river_km,first_datetime,last_datetime,interv_time)


# ============================================================================
# 4. Export both tags to xlsx, one sheet per tag (sheet name = tag code). Each sheet has the ATLAS
#    record on top and the preATLAS events below it; in the events table the flagged rows are
#    highlighted
# ============================================================================

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

# ATLAS (post-TagPro) rows for each tag; the ATLAS csv has no header, so give it the standard
# ATLAS column names
atlas_names <- c("release_spp", "num1", "tag_code", "release_time", "detection_time",
                 "site_name", "num2", "lst_dt")
atlas_sheets <- list(
  "G72B4A509" = RI_BRZsel_tagpro_out |> filter(V3 %in% c("G72B4A509")),
  "G72790346" = RI_BRZsel_tagpro_out |> filter(V3 %in% c("G72790346"))) |>
  lapply(function(d) setNames(d, atlas_names))

wb_cens <- createWorkbook()
highlight_style <- createStyle(fgFill = "yellow")
# G72790346: pink instead of yellow, plus a note at the bottom of its sheet (these rows are
# flagged but were NOT removed from the revised events)
pink_style <- createStyle(fgFill = "pink")
note_style <- createStyle(textDecoration = "italic")
tag_notes <- c("G72790346" = "I considered removing these rows but didn't go through with it.")
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
  addStyle(wb_cens, tag, if (tag == "G72790346") pink_style else highlight_style,
           rows = highlight_rows, cols = seq_len(ncol(events_tb)), gridExpand = TRUE)

  # note under the events table, after one blank row
  if (tag %in% names(tag_notes)) {
    note_row <- events_header_row + nrow(events_tb) + 2
    writeData(wb_cens, tag, tag_notes[[tag]], startRow = note_row)
    addStyle(wb_cens, tag, note_style, rows = note_row, cols = 1)
  }

  # widths from the table contents only, so the long headings can overflow instead of widening column A
  n_col <- max(ncol(atlas_tb), ncol(events_tb))
  chars <- sapply(seq_len(n_col), function(j) {
    max(nchar(c(names(atlas_tb)[j], as.character(atlas_tb[[j]]),
                names(events_tb)[j], as.character(events_tb[[j]]))), na.rm = TRUE)
  })
  setColWidths(wb_cens, tag, cols = seq_len(n_col), widths = pmin(chars + 2, 45))
}
saveWorkbook(wb_cens, censored_xlsx, overwrite = TRUE)


# ============================================================================
# 5. Move nodes.csv and tags.csv out of pre_tagpro into data/reach_spec_censor_fix
#    Safe to rerun: a file that is already in the destination (and no longer in pre_tagpro) is
#    skipped. Stops without moving anything if a file exists in both places, so nothing is
#    overwritten. Everything above that reads these two files must run first.
# ============================================================================
move_files <- c("nodes.csv", "tags.csv")

dir.create(censor_fix_dir, showWarnings = FALSE, recursive = TRUE)
to_move <- move_files[file.exists(file.path(pre_tagpro_dir, move_files))]
stopifnot(!any(file.exists(file.path(censor_fix_dir, to_move))))
if (length(to_move) > 0) {
  stopifnot(all(file.rename(from = file.path(pre_tagpro_dir, to_move),
                            to = file.path(censor_fix_dir, to_move))))
}
# both files must now be in the destination
stopifnot(all(file.exists(file.path(censor_fix_dir, move_files))))


# ============================================================================
# 6. Revised events: drop the rows highlighted in media/xlsx/censored_tags_detections.xlsx
# ============================================================================

# events.csv from the same source folder, times as POSIXct, interval length in seconds
eventsDF <- read.csv(file.path(pre_tagpro_dir, "events.csv")) |>
  mutate(first_datetime = as.POSIXct(first_datetime),
         last_datetime = as.POSIXct(last_datetime),
         interv_time = as.numeric(difftime(last_datetime, first_datetime, units = "secs")))

# node locations; nodes.csv is in the new folder once the files above have been moved. It repeats
# some node_code rows, so keep one row per node to avoid duplicating events in the join.
nodes_path <- c(file.path(censor_fix_dir, "nodes.csv"), file.path(pre_tagpro_dir, "nodes.csv"))
nodes_path <- nodes_path[file.exists(nodes_path)][1]
node_loc <- read.csv(nodes_path) |> distinct(node_code, location)
stopifnot(!anyDuplicated(node_loc$node_code))

# Only G72B4A509's flagged rows are removed: its very long detections at Sunland. Long intervals
# are common elsewhere in the data (e.g. tags resting near an antenna), so the rule is scoped to
# the tag and location, and an interval longer than 1 hour (the normal events at this tag/site
# combination are all well under it, the flagged ones far over it). No events are removed for
# G72790346; its Wanapum BRZ rows are shown in pink in the xlsx (section 4) but are kept here.
censor_rules <- data.frame(tag_code = "G72B4A509",
                           location = "Sunland")
interv_threshold_sec <- 3600

eventsDF_revis <- eventsDF |>
  left_join(node_loc, by = "node_code") |>
  mutate(drop_row = paste(tag_code, location) %in% paste(censor_rules$tag_code, censor_rules$location) &
           interv_time > interv_threshold_sec) |>
  filter(!drop_row) |>
  select(-drop_row, -location)

# rows removed (3 expected: the 3 Sunland rows for G72B4A509; none for G72790346)
nrow(eventsDF) - nrow(eventsDF_revis)


# ============================================================================
# 7. Write the revised events next to the moved nodes.csv and tags.csv
#    Same format as the original events.csv: times as "YYYY-MM-DD HH:MM:SS" text, no quotes, no
#    row names, and without interv_time. Overwrites events.csv in the destination folder if it
#    is already there.
# ============================================================================
eventsDF_revis |>
  select(-interv_time) |>
  mutate(across(c(first_datetime, last_datetime), ~ format(.x, "%Y-%m-%d %H:%M:%S"))) |>
  write.csv(file.path(censor_fix_dir, "events.csv"), row.names = FALSE, quote = FALSE)
