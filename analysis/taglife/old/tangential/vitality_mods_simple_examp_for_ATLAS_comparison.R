library(failCompare)
library(dplyr)
library(ggplot2)

source("R/nll_lookup.R")
source("R/fc_lrt.R")
source("R/fc_lrt_table.R")
source("R/run_vitality_lrt_grid.R")

# source("fc_nll.R")
# source("patch_fc_fit.R")

csv_fl_ls <- readRDS("data/clean/csv_fl_ls.rds")

taglife_rawDF <- csv_fl_ls$GPUD2026_taglife_17Aug2026 |> arrange(lot,days_difference)

# taglife_rawDF
# Extract failure times by lot
lot1_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 1"]
lot2_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 2"]
lot3_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 3"]
pooled_data <- taglife_rawDF$days_difference


tmp <- fc_fit(time = pooled_data,model="vitality.ku")
summary(tmp)
tmp$nll

tmp <- fc_fit(time = pooled_data,model="vitality.ku",rc.value = max(pooled_data))
summary(tmp)
tmp$nll