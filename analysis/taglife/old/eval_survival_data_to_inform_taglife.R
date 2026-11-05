library(dplyr)

# ============================================================================
# Load raw pre_tagpro data and attach tag activation time to each event
# ============================================================================
events_pretagpro <- read.csv("data/clean/pre_tagpro/events.csv", stringsAsFactors = FALSE)
tags_pretagpro <- read.csv("data/clean/pre_tagpro/tags.csv", stringsAsFactors = FALSE)
nodes_pretagpro <- read.csv("data/clean/pre_tagpro/nodes.csv", stringsAsFactors = FALSE)

# tags_pretagpro has one row per tag_code (no duplicates), so this join adds
# a single tag_activation_time value onto every event row for that tag
events_w_activation <- events_pretagpro |>
  left_join(
    tags_pretagpro |> select(tag_code, tag_activation_time = activation_date,release_location,species_code,lot),
    by = "tag_code"
  ) |>
  mutate(
    first_datetime = as.POSIXct(first_datetime, format = "%Y-%m-%d %H:%M:%S", tz = "UTC"),
    last_datetime = as.POSIXct(last_datetime, format = "%Y-%m-%d %H:%M:%S", tz = "UTC"),
    tag_activation_time = as.POSIXct(tag_activation_time, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
  ) |>
  group_by(tag_code) |>
  mutate(timediff_last = as.numeric(difftime(last_datetime, tag_activation_time, units = "days")),
         timediff_first = as.numeric(difftime(first_datetime, tag_activation_time, units = "days"))) |>
  ungroup() |>
  arrange(tag_AssignedRelease, tag_code)

# nodes_pretagpro has a few node_codes with multiple rows (redeployment on a
# later deploy_date at the same location/river_km) - de-duplicate on node_code
# before joining so this doesn't multiply rows in events_w_activation
nodes_pretagpro_distinct <- nodes_pretagpro |>
  distinct(node_code, location, river_km, .keep_all = TRUE) |>
  distinct(node_code, .keep_all = TRUE)

events_w_activation <- events_w_activation |>
  left_join(
    nodes_pretagpro_distinct |> select(node_code, location, river_km),
    by = "node_code"
  )



repID_tab <- events_w_activation[events_w_activation$timediff_last > 55, ] |> left_join(nodes_pretagpro_distinct)
table(repID_tab$tag_AssignedRelease)


source("R/summarize_final_detection_time.R")
final_detect_res <- summarize_final_detection_time(events_w_activation_in = events_w_activation)
final_detect_res$summary_tab_ls
final_detect_res$hist_plot

source("R/summarize_final_detection_time_threshold.R")
final_detect_over60_res <- summarize_final_detection_time_threshold(events_w_activation_in = events_w_activation, timediff_last_min = 60)
final_detect_over60_res$summary_tab_ls
final_detect_over60_res$hist_plot

final_detect_over55_res <- summarize_final_detection_time_threshold(events_w_activation_in = events_w_activation, timediff_last_min = 55)
final_detect_over55_res$summary_tab_ls
final_detect_over55_res$hist_plot


# events with no matching tag_code in tags_pretagpro end up with NA activation time
sum(is.na(events_w_activation$tag_activation_time))

output_path <- "data/clean/summary_results_SURVUSE_OR_EUTH_ACTIVE.rds"
# saveRDS(summary_results_ls, output_path)

# summary_results_ls <- readRDS(output_path)

# tag_subsets_ls <- readRDS("data/clean/tag_subsets_ls.rds")

# # Load tag detection history list created by data_cleaning/03_create_DH_from_tag_subsets.R
# tag_DH_ls <- readRDS("data/clean/tag_DH_ls.rds")

# # Detection history tables for the tags_SURVUSE_OR_EUTH_&_ACTIVE group
# # (same tables used in QAQC/QAQC_tables.R -> append_DH_tabs_qmd(tag_subset_nm = "tags_SURVUSE_OR_EUTH_&_ACTIVE", ...))
# DH_SU_E_ACT_RI <- tag_DH_ls[["SU_E_ACT_RI_summ"]] # Rock Island-released fish, by node
# DH_SU_E_ACT_PR <- tag_DH_ls[["SU_E_ACT_PR_summ"]] # Priest Rapids-released fish, by node

# DH_SU_E_ACT_RI
# DH_SU_E_ACT_PR


# names(summary_results_ls)

# # ============================================================================
# # Temporal distribution of tag detections relative to activation
# # ============================================================================
# # Question: how is the time between tag activation and detection distributed,
# # and what does the time to *last* detection suggest about tag life?
# # Caveat: last detection is confounded with fish emigrating out of the
# # detection array while still alive, so it's an upper bound on tag life,
# # not a direct estimate of battery failure time.

# library(dplyr)
# library(ggplot2)

# parse_dt <- function(x) as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

# tag_act <- tags_dat_SURVUSE_OR_EUTH_ACTIVE |>
#   distinct(tag_code, lot, spp, tag_status, fish_status, survival_use, tag_activate_date) |>
#   mutate(tag_activate_date = parse_dt(tag_activate_date))

# # events_dat rows whose tag_code isn't in the SURVUSE_OR_EUTH_ACTIVE subset
# # are dropped by the inner_join (this subset is a filtered population of tags)
# events_since_act <- events_dat |>
#   mutate(
#     first_dt = parse_dt(first_computed_datetime),
#     last_dt = parse_dt(last_computed_datetime)
#   ) |>
#   inner_join(tag_act, by = "tag_code") |>
#   mutate(days_since_activation = as.numeric(difftime(first_dt, tag_activate_date, units = "days")))

# # Per-tag time from activation to last detection (upper bound on tag life)
# tag_last_detect <- events_since_act |>
#   group_by(tag_code, lot, spp, tag_status, fish_status) |>
#   summarise(
#     last_days_since_activation = max(days_since_activation),
#     n_events = n(),
#     .groups = "drop"
#   )

# summary(tag_last_detect$last_days_since_activation)

# ggplot(tag_last_detect, aes(x = last_days_since_activation)) +
#   geom_histogram(binwidth = 2, boundary = 0) +
#   facet_wrap(~lot, ncol = 1) +
#   labs(
#     title = "Time from tag activation to last detection, by lot",
#     x = "Days from activation to last detection",
#     y = "Number of tags"
#   ) +
#   theme_minimal()

