# User-Defined Functions Summary

Complete inventory of all user-defined functions used in the data_cleaning → QAQC pipeline, now centralized in the top-level `R/` directory.

## Overview

**Total Functions:** 10 user-defined functions across 6 modules
**Total Code:** ~36 KB
**Location:** `R/` directory at repo root

## Functions Inventory

### 1. Data Filtering & Subsetting
**File:** `R/build_tag_subsets.R`
- `build_tag_subsets(tags_dat_raw_wrepID, filter_strs)` - Creates filtered tag subsets from named filter conditions

### 2. Contingency Table Generation
**File:** `R/get_conting_tabs.R`
- `get_conting_tabs(tags_dat_in)` - Generates 9 contingency tables from tag data
- `get_conting_tabs_by_name(tags_dat_in, tb_nm_in, ele_nm_in)` - Retrieves specific contingency table
- `tag_rel_tagger_summ_tb(tags_dat_wrepID_in)` - Summarizes tags by species, tag_group, location, tagger

### 3. Detection History Summarization
**File:** `R/get_DH_tag_code_summ.R`
- `get_DH_tag_code_summ(node_dat_in, events_dat_in, tags_dat_wrepID_in)` - Creates detection history by location for each tag

### 4. Release Location Summary
**File:** `R/get_rel_loc_by_repID_tabs.R`
- `get_rel_loc_by_repID_tabs(tags_dat_raw_wrepID, split_var)` - Summarizes tag counts by species, replicate, and release location

### 5. Tagger-Location-Status Summary
**File:** `R/get_tagger_rel_loc_status_tb_ls.R`
- `get_tagger_rel_loc_status_tb_ls(tags_dat_wrepID_in)` - Creates list of tagger-location-status summary tables by species and tag group

### 6. Report Generation (Quarto)
**File:** `R/append_to_qmd_etc.R`
- `append_to_qmd(file_path, text_lines)` - Appends text to Quarto markdown file
- `add_qsec3(header_in, tag_sub_nm, tb_nm_in, header_level)` - Generates Quarto section with contingency table
- `add_qsec3_elwise(header_in, tag_sub_nm, tb_nm_in, ele_nm_in, header_level)` - Generates Quarto section for element-wise table

## Function Dependencies

### By Pipeline Stage

**Stage 1: data_cleaning/01_load_csvs.R**
- No functions sourced

**Stage 2: data_cleaning/01_create_tag_subsets.R**
- `build_tag_subsets()`
- `get_rel_loc_by_repID_tabs()`

**Stage 3: QAQC/QAQC_tables.R**
- `append_to_qmd()`
- `add_qsec3()`
- `add_qsec3_elwise()`
- `get_conting_tabs_by_name()`
  - Internally calls:
    - `get_tagger_rel_loc_status_tb_ls()`
    - `tag_rel_tagger_summ_tb()`
    - `get_rel_loc_by_repID_tabs()`
- `get_DH_tag_code_summ()`

### Function Call Graph

```
data_cleaning/01_create_tag_subsets.R
  │
  ├─ R/build_tag_subsets.R
  │   └─ build_tag_subsets()
  │
  └─ R/get_rel_loc_by_repID_tabs.R
      └─ get_rel_loc_by_repID_tabs()

QAQC/QAQC_tables.R
  │
  ├─ R/append_to_qmd_etc.R
  │   ├─ append_to_qmd()
  │   ├─ add_qsec3()
  │   └─ add_qsec3_elwise()
  │
  ├─ R/get_conting_tabs.R
  │   ├─ get_conting_tabs_by_name()
  │   │   ├─ get_tagger_rel_loc_status_tb_ls()
  │   │   ├─ tag_rel_tagger_summ_tb()
  │   │   └─ get_rel_loc_by_repID_tabs()
  │   │
  │   └─ tag_rel_tagger_summ_tb()
  │
  ├─ R/get_rel_loc_by_repID_tabs.R
  │   └─ get_rel_loc_by_repID_tabs()
  │
  ├─ R/get_tagger_rel_loc_status_tb_ls.R
  │   └─ get_tagger_rel_loc_status_tb_ls()
  │
  └─ R/get_DH_tag_code_summ.R
      └─ get_DH_tag_code_summ()
```

## Sourcing Instructions

### Current Method (from QAQC/)
```r
source("R/function_name.R")
source("QAQC/R/function_name.R")
```

### Updated Method (from repo root via R/)
```r
source("R/function_name.R")
```

## Package Dependencies

All functions depend on tidyverse packages:
- `dplyr` - Data manipulation (group_by, summarize, filter, select, mutate, etc.)
- `tidyr` - Data reshaping (pivot_wider, pivot_longer)
- `rlang` - Metaprogramming (ensym, parse_expr, as_string)
- `purrr` - Functional programming (map)

## Migration Status

✓ **All user-defined functions copied to R/ directory**
✓ **README.md created with function documentation**
✓ **Function call dependency graph documented**

## Next Steps (Optional)

To fully migrate from QAQC/R/ to R/:
1. Update all `source()` calls in scripts to use `source("R/function_name.R")`
2. Remove QAQC/R/ directory (keeping only as backup if needed)
3. Update script headers with new sourcing instructions

Current setup allows:
- Functions accessible from repo root
- Easier code maintenance and reuse
- Clear separation of utility functions from analysis scripts
