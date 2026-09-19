csv_fl_ls <- readRDS("data/clean/csv_fl_ls.rds")

taglife_rawDF <- csv_fl_ls$GPUD2026_taglife_17Aug2026

head(taglife_rawDF)

# Create directory for ATLAS taglife data
atlas_dir <- file.path(dirname(getwd()), "taglife", "ATLAS_taglife_data")
dir.create(atlas_dir, showWarnings = FALSE)

# Export CSV files with only tag_life_days column (renamed from days_difference)
# Lot 1
lot1_export <- data.frame(tag_life_days = taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 1"])
write.csv(lot1_export, file.path(atlas_dir, "Lot_1_taglife.csv"), row.names = FALSE)

# Lot 2
lot2_export <- data.frame(tag_life_days = taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 2"])
write.csv(lot2_export, file.path(atlas_dir, "Lot_2_taglife.csv"), row.names = FALSE)

# Lot 3
lot3_export <- data.frame(tag_life_days = taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 3"])
write.csv(lot3_export, file.path(atlas_dir, "Lot_3_taglife.csv"), row.names = FALSE)

# Pooled (all data)
pooled_export <- data.frame(tag_life_days = taglife_rawDF$days_difference)
write.csv(pooled_export, file.path(atlas_dir, "Pooled_taglife.csv"), row.names = FALSE)

library(failCompare)


# ATLAS Lot 1
# fits with zero omitted
# removing 7-13 tags looks better
# the line is still below the first 4

# ATLAS Lot 2
# remove last 1 to fit model at all
# SW removing 6-13 tags at the end looks better

# ATLAS Lot 3
# fits with zero omitted
# big improvement after removing 1
# SW removing up to 5
