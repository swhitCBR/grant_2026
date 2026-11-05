# Tag-life LRT table for the report: pooled vs separate tag lots, Weibull-2 fit with the 68
# longest-lived tags right-censored (the tag-life model used in ATLAS).
# Run from the repo root. Writes one Word table to media/docx/taglife/lrt_table_weibull_rc<value>.docx
# (needs the flextable package). The earlier exploratory version, with the vitality.ku and
# multi-rc grids, is in old/vitality_LRT_ORIG_2026-11-04.R

library(failCompare)
library(dplyr)

source("R/nll_lookup.R")
source("R/fc_lrt.R")
source("R/fc_lrt_table.R")
source("R/run_vitality_lrt_grid.R")

csv_fl_ls <- readRDS("data/clean/csv_fl_ls.rds")

taglife_rawDF <- csv_fl_ls$GPUD2026_taglife_17Aug2026 |> arrange(lot, days_difference)

lot_data_ls <- list(
  "Lot 1" = taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 1"],
  "Lot 2" = taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 2"],
  "Lot 3" = taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 3"])
pooled_data <- taglife_rawDF$days_difference

# Censoring value: the 69th-longest tag time (same selection as rc_count_back = 69 in
# Weibull_LRT_across_RC_values.R, whose first grid value is n_back = 69)
rc_sel <- sort(pooled_data)[length(pooled_data) - 68]

# fc_obj_nll() (R/nll_lookup.R) dispatches to nll_weibull()
lrt_weibull_sel <- run_vitality_lrt_grid(
  group_data_ls = lot_data_ls,
  pooled_data   = pooled_data,
  models        = "weibull",
  rc_values     = rc_sel
)

summarize_vitality_lrt_grid(lrt_weibull_sel)
