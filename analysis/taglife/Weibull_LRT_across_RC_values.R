# Tag-life (Weibull) likelihood-ratio tests: pooled vs separate lots, across right-censoring values.
# Run from the repo root. Reads the taglife data in data/clean/csv_fl_ls.rds; writes no files.
# The full exploratory version of this script is in old/Weibull_LRT_across_RC_values_ORIG_2026-11-04.R

library(failCompare)
library(dplyr)

source("R/run_mult_rc_lrt.R")

csv_fl_ls <- readRDS("data/clean/csv_fl_ls.rds")

taglife_rawDF <- csv_fl_ls$GPUD2026_taglife_17Aug2026 |> arrange(lot, days_difference)

lot_data_ls <- list(
  "Lot 1" = taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 1"],
  "Lot 2" = taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 2"],
  "Lot 3" = taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 3"])
pooled_data <- taglife_rawDF$days_difference

data.frame(lot = names(lot_data_ls), n_tags = lengths(lot_data_ls))

# LRT of pooled vs separate lots over a grid of right-censoring values
# fc_obj_nll() (R/nll_lookup.R) dispatches to nll_weibull()/nll_weibull3().
rt_results_weibull_ls <- run_mult_rc_lrt(
  group_data_ls = lot_data_ls,
  pooled_data   = pooled_data,
  models        = "weibull",
  rc_values     = 60:80, silent = TRUE
)

# Censoring the 68 longest-lived tags (the model used in ATLAS: Weibull-2, 68 truncated)
sel_rt_results_weibull2_ls <- run_mult_rc_lrt(
  group_data_ls = lot_data_ls,
  pooled_data   = pooled_data,
  models        = "weibull",
  rc_count_back = 69
)

summarize_mult_lrt_grid(rt_results_weibull_ls)
summarize_mult_lrt_grid(sel_rt_results_weibull2_ls)

# Pooled fit with the 68 longest-lived tags censored, and its mean time to failure
weib_mod_68cens <- fc_fit(
  time = pooled_data, model = "weibull",
  censorID = c(rep(TRUE, length(pooled_data) - 68), rep(FALSE, 68)))
mttf_fc_obj(weib_mod_68cens)
plot(weib_mod_68cens)
