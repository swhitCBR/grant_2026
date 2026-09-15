
library(dplyr)

#' Load CSV files from data/Round 2
#'
#' Loads all CSV files from data/Round 2/ directory and saves as an RDS list
#' for use in downstream QAQC analyses.
#'
#' Output: QAQC/tmp_data/csv_fl_ls.rds

getwd()

# Load CSV files from data/Round 2
csv_fl_nms <- dir("data/Round 2", pattern = "\\.csv$")
csv_fl_ls <- lapply(csv_fl_nms, function(x) {
  read.csv(file.path("data/Round 2", x), stringsAsFactors = FALSE)
})

# Extract file names (without extension) as list names
names(csv_fl_ls) <- sapply(csv_fl_nms, function(x) {
  strsplit(x, "[.]")[[1]][1]
})

names(csv_fl_ls)

# Save to data/clean directory for use by downstream scripts
if (!dir.exists("data/clean")) {
  dir.create("data/clean", recursive = TRUE)
}

# Save the consolidated list for downstream scripts
saveRDS(csv_fl_ls, "data/clean/csv_fl_ls.rds")

cat("CSV files loaded and saved to data/clean/csv_fl_ls.rds\n")



# View(csv_fl_ls)

# csv_fl_ls$GPUD2026_tags_12Aug2026
