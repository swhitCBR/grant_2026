# data/clean/

This directory contains cleaned and processed data outputs from the data cleaning pipeline.

## tag_subsets_ls.rds

### Overview

`tag_subsets_ls.rds` is an R RDS (R Data Serialization) file containing a list of six tag subsets created from the raw GRANT 2026 fish tagging data. Each subset applies different filtering criteria to the raw tag dataset for specific QAQC (Quality Assurance/Quality Control) and analysis purposes.

### Source

**Created by:** `data_cleaning/01_create_tag_subsets.R`

**Input data:**
- CSV files from `data/Round 2/` directory:
  - `GPUD2026_tags_17Aug2026.csv` - Raw tag metadata
  - `GPUD2026_events_17Aug2026.csv` - Tag detection events
  - `GPUD2026_nodes_12Aug2026.csv` - Detection node information

### File Format

- **Type:** R RDS (binary format)
- **Load command:** `readRDS("data/clean/tag_subsets_ls.rds")`
- **Data structure:** Named list with 6 elements, each containing a data frame

### Tag Subsets

The `tag_subsets_ls` list contains the following subsets:

1. **RAW** - All tags (no filtering; n = 3,496 tags)
   - Baseline dataset including all fish regardless of status
   - Includes "Tarmac" and "Mortality" groups

2. **tags_ALIVE_or_EUTH** - Fish with status Alive or Euthanized (n = 3,480 tags)
   - Excludes "Tarmac" and "Mortality" groups
   - Filter: `fish_status %in% c("Alive", "Euthanized")`

3. **tags_SURVUSE_AND_ALIVE_or_EUTH** - Survival study fish that are Alive or Euthanized (n = 2,976 tags)
   - Fish designated for survival analysis AND with known status
   - Filter: `survival_use & fish_status %in% c("Alive", "Euthanized")`

4. **tags_SURVUSE_OR_ALIVE_or_EUTH** - Survival study fish OR Alive/Euthanized fish (n = 3,480 tags)
   - Fish either designated for survival analysis OR with known status
   - Filter: `survival_use | fish_status %in% c("Alive", "Euthanized")`

5. **tags_SURVUSE_OR_EUTH_&_ACTIVE** - Survival study fish OR (Euthanized AND Active tags) (n = 3,020 tags)
   - Survival fish plus dead fish with active tags
   - Filter: `survival_use | (fish_status %in% c("Euthanized") & tag_status == "Active")`

6. **tags_ALIVE_ACTIVE_OTHER_OR_EUTH_ACTIVE_OTHER** - Live/dead fish with Active tags and Other release type (n = 684 tags)
   - Subset for specific replicate analysis
   - Filter: `(fish_status %in% c("Alive") & tag_status == "Active" & release_type == "Other") | (fish_status %in% c("Euthanized") & tag_status == "Active" & release_type == "Other")`

### Data Processing Steps

The script `data_cleaning/01_create_tag_subsets.R` performs the following:

1. **Loads CSV files** from `data/Round 2/` into R
2. **Adds derived fields** to the raw tag data:
   - `spp_code`: Species code (11 = Chinook, 01 = Steelhead)
   - `spp`: Species name (CHN or STH)
   - `reartype`: Rearing type (H = Hatchery, W = Wild, etc.)
   - `rel_date`: Release date (parsed from tag_release_date)
   - `rep_loc`: Replicate location abbreviation (RI or PR)
   - `rep_num`: Replicate number
   - `repID`: Replicate ID
   - `code`: Composite code for grouping
   - `release_location`: Factored as Rock Island Tailrace or Priest Rapids Tailrace

3. **Creates six filtered subsets** based on fish_status, survival_use, tag_status, and release_type criteria
4. **Validates data** by counting tags in each subset and checking value distributions
5. **Saves the list** to this file for use in downstream analyses

### Downstream Usage

`tag_subsets_ls.rds` is loaded and used by:
- **QAQC/QAQC_tables.R** - Generates contingency tables and detection history reports
- Reports reference specific subsets (e.g., RAW, tags_SURVUSE_OR_EUTH_&_ACTIVE) for different analyses

### Related Files

- **Input:** `data/Round 2/GPUD2026_tags_17Aug2026.csv` and related CSVs
- **Script:** `data_cleaning/01_create_tag_subsets.R`
- **Consumer:** `QAQC/QAQC_tables.R`
- **Output:** QAQC reports (`SW_QAQC_tabs_1_2.docx`, `SW_QAQC_tabs_2_2.docx`)

### Updating the Data

To regenerate this file with updated raw data:

```r
# From the repo root directory
setwd("c:/repos/grant_2026")
source("data_cleaning/01_load_csvs.R")      # Load raw CSVs
source("data_cleaning/01_create_tag_subsets.R")  # Create tag subsets and save
```

### Notes

- All dates are formatted as YYYY-MM-DD or YYYY-MM-DD HH:MM:SS
- Species codes: 11 = Chinook (CHN), 01 = Steelhead (STH)
- Release locations are standardized to "Rock Island Tailrace" or "Priest Rapids Tailrace"
- The script includes data validation steps with `table()` and `sapply()` calls to check subset creation
