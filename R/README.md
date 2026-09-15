# R/ - User-Defined Functions

This directory contains all user-defined functions used throughout the data_cleaning and QAQC pipeline.

## Functions by Module

### append_to_qmd_etc.R
Functions for generating and appending content to Quarto markdown files.

- **`append_to_qmd(file_path, text_lines)`** - Appends text lines to a Quarto file
- **`add_qsec3(header_in, tag_sub_nm, tb_nm_in, header_level)`** - Generates Quarto section for contingency table
- **`add_qsec3_elwise(header_in, tag_sub_nm, tb_nm_in, ele_nm_in, header_level)`** - Generates Quarto section for element-wise contingency table

### build_tag_subsets.R
Function for creating filtered subsets of tag data.

- **`build_tag_subsets(tags_dat_raw_wrepID, filter_strs)`** - Creates named list of tag subsets based on filter conditions

### get_conting_tabs.R
Functions for generating contingency tables from tag data.

- **`get_conting_tabs(tags_dat_in)`** - Creates list of contingency tables (survival_use vs status, location vs tagger, etc.)
- **`get_conting_tabs_by_name(tags_dat_in, tb_nm_in, ele_nm_in)`** - Retrieves specific contingency table by name
- **`tag_rel_tagger_summ_tb(tags_dat_wrepID_in)`** - Summarizes tags by species, tag_group, location, and tagger

### get_DH_tag_code_summ.R
Function for generating detection history summaries.

- **`get_DH_tag_code_summ(node_dat_in, events_dat_in, tags_dat_wrepID_in)`** - Creates detection history summary showing which detection locations each tag was observed at

### get_rel_loc_by_repID_tabs.R
Function for summarizing tag counts by replicate and release location.

- **`get_rel_loc_by_repID_tabs(tags_dat_raw_wrepID, split_var)`** - Generates tables with tag counts by species, replicate, and release location, split by tag_group

### get_tagger_rel_loc_status_tb_ls.R
Function for creating tagger-location-status summary tables.

- **`get_tagger_rel_loc_status_tb_ls(tags_dat_wrepID_in)`** - Creates list of tables summarizing tags by species, tag group, location, tagger, and replicate

## Function Call Chain

```
data_cleaning/01_create_tag_subsets.R
  ├─ build_tag_subsets()
  └─ get_rel_loc_by_repID_tabs()

QAQC/QAQC_tables.R
  ├─ get_conting_tabs_by_name()
  │   ├─ get_tagger_rel_loc_status_tb_ls()
  │   ├─ tag_rel_tagger_summ_tb()
  │   └─ get_rel_loc_by_repID_tabs()
  ├─ append_to_qmd()
  ├─ add_qsec3()
  ├─ add_qsec3_elwise()
  ├─ get_DH_tag_code_summ()
  └─ [functions for report generation]
```

## Usage

These functions are sourced by the main pipeline scripts:

**data_cleaning/01_create_tag_subsets.R:**
```r
source("R/get_rel_loc_by_repID_tabs.R")
source("R/build_tag_subsets.R")
```

**QAQC/QAQC_tables.R:**
```r
source("R/get_rel_loc_by_repID_tabs.R")
source("R/build_tag_subsets.R")
source("R/get_conting_tabs.R")
source("R/append_to_qmd_etc.R")
source("R/get_tagger_rel_loc_status_tb_ls.R")
source("R/get_DH_tag_code_summ.R")
```

## Dependencies

All functions use tidyverse packages (`dplyr`, `tidyr`, `rlang`, `purrr`). Ensure these are installed before using:

```r
install.packages(c("dplyr", "tidyr", "rlang", "purrr"))
```

## Function Descriptions

### Data Transformation Functions
- `build_tag_subsets()` - Filters tag data based on multiple criteria
- `get_conting_tabs()` - Creates 9 different contingency tables
- `get_conting_tabs_by_name()` - Retrieves specific contingency tables and computed summaries
- `get_DH_tag_code_summ()` - Pivots detection event data into detection history format
- `get_rel_loc_by_repID_tabs()` - Aggregates tag counts and dates by replicate and location
- `get_tagger_rel_loc_status_tb_ls()` - Creates tagger-location-status summaries by species and tag group
- `tag_rel_tagger_summ_tb()` - Simple tag count summary by species, tag group, location, and tagger

### Report Generation Functions
- `append_to_qmd()` - Appends text to Quarto markdown file
- `add_qsec3()` - Generates Quarto section with R code block for contingency table
- `add_qsec3_elwise()` - Generates Quarto section for element-wise filtered contingency table

## Notes

- All functions expect data frames with specific columns (documented in roxygen2 comments)
- Functions use `tidyverse` piping (`|>`) and functional programming
- Some functions return nested lists for organizing complex outputs
