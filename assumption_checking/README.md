# Assumption Checking Pipeline: Scripts 01-03

This folder contains the analysis pipeline for checking assumptions and testing for tagger effects in CJS survival analysis using ATLAS (Automatic Telemetry Location-based Survival Estimation).

## Overview

The scripts process fish telemetry data through three main stages:
1. **Script 01**: Preprocessing for TagPro software
2. **Script 02**: Post-TagPro setup and tagger subsetting  
3. **Script 03**: ATLAS results compilation and analysis

---

## Script 01: `01_tagpro_preprocessing.R`

**Purpose**: Prepare raw telemetry data for TagPro analysis

### What it does:
- Loads raw data from the main data cleaning pipeline:
  - Tag information (tag codes, fish metadata)
  - Detection events (when/where fish were detected)
  - Node information (detection site metadata)
  
- Filters to a specific tag subset:
  - Default: `tags_SURVUSE_no_EUTH` (survival-use fish, excluding euthanized individuals)
  - Creates corresponding subsets of events and nodes

- Runs TagPro preprocessing via `preprocess_for_tagpro()`:
  - Prepares data in TagPro-compatible format
  - Fixes river kilometer positions for release locations:
    - Rock Island Tailrace: 730 km
    - Priest Rapids Tailrace: 246.0015 km
  - Writes output CSVs to `data/clean/pre_tagpro/`

### Inputs:
- `data/clean/csv_fl_ls.rds` - Raw data list (tags, events, nodes)
- `data/clean/tag_subsets_ls.rds` - Pre-defined tag subsets
- Custom river kilometer lookup table

### Outputs:
- `data/clean/pre_tagpro/tags.csv`
- `data/clean/pre_tagpro/events.csv`
- `data/clean/pre_tagpro/nodes.csv`

### Manual Step:
After this script completes, you must:
1. Run TagPro manually with the CSV outputs
2. TagPro produces ATLAS-compatible input files

---

## Script 02: `02_post_tagpro_preATLAS_subsets.R`

**Purpose**: Process ATLAS inputs and create tagger-specific subsets

### What it does:
- Loads ATLAS-formatted detection files from TagPro
- Filters to a subset of validated detection sites:
  - Crescent Bar, Sunland, Wanapum BRZ, Mattawa, Priest BRZ, Lower Ringold, Hanford
  - Removes extraneous sites to focus analysis on main river reaches

- Calls `process_all_atlas_files()` to split ATLAS data by tagger:
  - Creates separate input files for POOLED, TAGGER A, TAGGER B, TAGGER C
  - Each tagger gets its own set of detection files

### Dependencies:
- Must run Script 01 first (generates `data/clean/pre_tagpro/`)
- TagPro must be run manually to generate ATLAS files

### Inputs:
- `data/clean/post_tagpro/RI_all_sites_MOD_ATLAS.csv` (from TagPro)
- Other ATLAS CSV files in `data/clean/post_tagpro/`

### Outputs:
- Tagger-specific ATLAS input directories:
  - `POOLED/`
  - `TAGGER A/`
  - `TAGGER B/`
  - `TAGGER C/`

### Manual Step:
After this script completes, you must:
1. Run ATLAS models in the GUI with each tagger's input files
2. ATLAS produces markdown files with results (CJS_report.md, Cumul_surv.md, etc.)
3. Copy/paste HTML output from ATLAS into corresponding markdown files

---

## Script 03: `03_compile_postATLAS_results_and_perform_F_tests_on_tagger_estimates.R`

**Purpose**: Extract and analyze ATLAS model results; compare tagger effects

### What it does:

#### 1. **ATLAS Output Validation** (Lines 3-34)
   - Validates markdown files exist and contain expected results
   - Checks row counts, missing data, and file modification dates
   - Summarizes which files are blank or incomplete

#### 2. **ATLAS Results Scraping** (Lines 51-112)
   - Calls `scrape_atlas_results()` to extract results from markdown files
   - Extracts three types of survival data:
     - **cjs_survival**: Reach-specific survival estimates (wide format)
     - **cjs_survival_long**: Reach-specific survival (long format for plotting)
     - **cumul_cjs_survival**: Cumulative survival to each downstream location
   - Also extracts capture estimates and detection histories

#### 3. **Comparison Table Generation** (Lines 83-100)
   - Creates wide-format tables comparing taggers for each location/species combo
   - `create_survival_comparison_table()`: Reach-specific survival comparisons
   - `create_cumul_survival_comparison_table()`: Cumulative survival comparisons
   - Includes F-tests for homogeneity of estimates across taggers
   - Tests whether tagger effects are statistically significant

#### 4. **Detection History Analysis** (Lines 103-112)
   - Extracts specific capture patterns across taggers
   - Exports comprehensive results to Excel files:
     - `BRZsel_atlas_results.xlsx` - BRZsel run outputs
     - `allsites_atlas_results.xlsx` - All sites run outputs

#### 5. **Visualization** (Lines 115-127)
   - Creates publication-quality plots:
     - `get_tagger_surv_plot()`: Reach-specific survival with confidence intervals
     - `get_tagger_cumul_surv_plot()`: Cumulative survival with confidence intervals
   - Points dodged by tagger, colored by tagger group (A/B/C/POOLED)
   - Saves to PNG and PDF formats

### Key Functions Called:
- `scrape_atlas_results()` - Extracts data from markdown files
- `create_survival_comparison_table()` - Reach-specific comparisons
- `create_cumul_survival_comparison_table()` - Cumulative survival comparisons
- `get_tagger_comp_tables_MOD()` - Organizes comparisons by species/location
- `get_DH_tab_by_tagger()` - Detection history extraction
- `get_DH_est_comp_xlsx()` - Export to Excel
- `get_tagger_surv_plot()` - Survival visualization
- `get_tagger_cumul_surv_plot()` - Cumulative survival visualization

### Inputs:
- ATLAS markdown output files in:
  - `assumption_checking/BRZsel_run/` (POOLED, TAGGER A/B/C, each with RI_CHN/RI_STH/PR_CHN/PR_STH)
  - `assumption_checking/all_sites_run/` (same structure)
- Release count summaries from QAQC tables

### Outputs:
- **Excel files**:
  - `BRZsel_atlas_results.xlsx`
  - `allsites_atlas_results.xlsx`

- **Plots (PNG & PDF)**:
  - `tagger_survival_comparison.png/pdf` - Reach-specific survival
  - `tagger_cumul_survival_comparison.pdf/pdf` - Cumulative survival

- **Console/Environment**:
  - Comparison tables (reach-specific and cumulative)
  - F-test results embedded in tables

---

## Workflow Summary

```
Raw Data
    ↓
[Script 01] TagPro Preprocessing
    ↓
[Manual] Run TagPro
    ↓
[Script 02] ATLAS Subsetting by Tagger
    ↓
[Manual] Run ATLAS models × 4 taggers × 4 location/species combos
    ↓
[Manual] Copy ATLAS HTML output to markdown files
    ↓
[Script 03] Compile Results & Statistical Tests
    ↓
Excel Files & Publication Plots
```

---

## Key Files in This Directory

### Scripts:
- `01_tagpro_preprocessing.R` - Data prep for TagPro
- `02_post_tagpro_preATLAS_subsets.R` - Create tagger subsets
- `03_compile_postATLAS_results_and_perform_F_tests_on_tagger_estimates.R` - Results analysis

### ATLAS Run Directories:
- `BRZsel_run/` - Analysis using Basin River Zone (BRZ) selected sites only
- `all_sites_run/` - Analysis using all available sites

### Output Files:
- `*.xlsx` - Excel workbooks with comparison tables
- `*.png`, `*.pdf` - Publication-ready plots
- `*.md` - ATLAS markdown reports (generated by ATLAS GUI)

---

## Quick Reference: What to Run

1. **Set up data for TagPro**:
   ```r
   source("01_tagpro_preprocessing.R")
   # Then manually run TagPro
   ```

2. **Create tagger subsets for ATLAS**:
   ```r
   source("02_post_tagpro_preATLAS_subsets.R")
   # Then manually run ATLAS models
   ```

3. **Compile and analyze ATLAS results**:
   ```r
   source("03_compile_postATLAS_results_and_perform_F_tests_on_tagger_estimates.R")
   ```

---

## Functions Used in This Pipeline

### Script 01: TagPro Preprocessing

**Directly Called:**
- `preprocess_for_tagpro()` — Prepares data for TagPro analysis; fixes river kilometers and formats CSVs
  - **Location**: `R/preprocess_for_tagpro.R`
  - **Indirectly uses**: Standard tidyverse functions (dplyr, tidyr)

**Indirectly Used:**
- Standard R functions: `readRDS()`, `write.csv()`, `filter()`, `unique()`

---

### Script 02: Post-TagPro ATLAS Subsetting

**Directly Called:**
- `process_all_atlas_files()` — Splits ATLAS detection files by tagger group
  - **Location**: `R/process_all_atlas_files.R`
  - **Calls indirectly**: `create_atlas_tagger_subsets()`

- `create_atlas_tagger_subsets()` — Creates tagger-specific subsets from ATLAS files
  - **Location**: `R/create_atlas_tagger_subsets.R`
  - **Uses**: dplyr functions for filtering and data manipulation

**Indirectly Used:**
- Standard R functions: `read.csv()`, `filter()`, `write.table()`

---

### Script 03: ATLAS Results Compilation and Analysis

#### 3.1: ATLAS Output Validation

**Directly Called:**
- `check_md_rows()` — Validates markdown file row counts
  - **Location**: `R/check_md_rows.R`
  - **Purpose**: Ensures ATLAS markdown files contain expected number of data rows

- `summarize_blank_mds()` — Summarizes blank/incomplete markdown files
  - **Location**: `R/summarize_blank_mds.R`
  - **Purpose**: Identifies which ATLAS results are missing

- `check_md_dates()` — Checks file modification dates
  - **Location**: `R/check_md_dates.R`
  - **Purpose**: Verifies when markdown files were last updated

**Ad-hoc Function (as needed):**
- `make_dirs_mds_for_pasting()` — Creates directory structure for ATLAS results
  - **Location**: `R/make_dirs_mds_for_pasting.R`
  - **Purpose**: Sets up folders and template markdown files for pasting ATLAS HTML output
  - **Usage**: Called manually as needed when setting up new ATLAS run directories (currently commented out in Script 03)

#### 3.2: ATLAS Results Scraping

**Directly Called:**
- `scrape_atlas_results()` — Main function to extract data from ATLAS markdown files
  - **Location**: `R/scrape_atlas_results.R`
  - **Purpose**: Parses markdown tables and extracts:
    - Capture history data
    - Reach-specific CJS survival estimates
    - Cumulative survival estimates
    - Capture estimates by detection site
  - **Indirectly calls**: `.pivot_cjs_survival_long()`

- `.pivot_cjs_survival_long()` — Converts wide-format survival data to long format
  - **Location**: `R/scrape_atlas_results.R` (internal helper)
  - **Purpose**: Transforms reach-specific survival from wide to long format for plotting

**Indirectly Used:**
- `readLines()`, `grep()`, `strsplit()`, `bind_rows()` from base R and dplyr

#### 3.3: Comparison Table Generation

**Directly Called:**
- `create_survival_comparison_table()` — Creates wide-format reach-specific survival comparison tables
  - **Location**: `R/create_survival_comparison_table.R`
  - **Purpose**: Organizes survival estimates by reach (rows) and tagger (columns)
  - **Indirectly calls**: `compute_f_tests_by_reach()`

- `compute_f_tests_by_reach()` — Computes F-statistics for homogeneity of survival across taggers
  - **Location**: `R/create_survival_comparison_table.R` (helper function)
  - **Purpose**: Tests whether tagger effects are statistically significant at each reach
  - **Statistics**: F = [variance of estimates] / [mean sampling variance]

- `create_cumul_survival_comparison_table()` — Creates cumulative survival comparison tables
  - **Location**: `R/create_cumul_survival_comparison_table.R`
  - **Purpose**: Organizes cumulative survival by downstream location (rows) and tagger (columns)
  - **Indirectly calls**: `compute_f_tests_by_reach_cumul()`

- `compute_f_tests_by_reach_cumul()` — Computes F-statistics for cumulative survival homogeneity
  - **Location**: `R/create_cumul_survival_comparison_table.R` (helper function)
  - **Purpose**: Tests tagger effects for cumulative (release-to-location) survival

- `create_all_survival_tables()` — Convenience wrapper creating tables for all location/species combos
  - **Location**: `R/create_survival_comparison_table.R`
  - **Purpose**: Loops through location/species combinations, calls `create_survival_comparison_table()`

- `create_all_cumul_survival_tables()` — Wrapper for all cumulative survival comparison tables
  - **Location**: `R/create_cumul_survival_comparison_table.R`
  - **Purpose**: Loops through location/species combinations, calls `create_cumul_survival_comparison_table()`

- `format_survival_table_display()` — Formats tables with rounded numeric values for display
  - **Location**: `R/create_survival_comparison_table.R`
  - **Purpose**: Rounds estimates, SEs, F-stats, and p-values to appropriate decimal places

- `format_survival_table_markdown()` — Converts survival tables to markdown format
  - **Location**: `R/create_survival_comparison_table.R`
  - **Purpose**: Uses `knitr::kable()` for markdown table formatting

- `get_tagger_comp_tables_MOD()` — Organizes comparison tables by species and location
  - **Location**: `R/get_tagger_comp_tables_MOD.R`
  - **Purpose**: Creates nested list structure (CHN/STH × RI/PR)
  - **Calls**: `create_survival_comparison_table()` multiple times

#### 3.4: Detection History Analysis

**Directly Called:**
- `get_DH_tab_by_tagger()` — Extracts specific capture patterns (detection histories) by tagger
  - **Location**: `R/get_DH_tab_by_tagger.R`
  - **Purpose**: Looks up which fish showed specific capture histories across taggers

- `get_DH_est_comp_xlsx()` — Exports detection history and survival comparisons to Excel
  - **Location**: `R/get_DH_est_comp_xlsx.R`
  - **Purpose**: Creates comprehensive Excel workbooks with multiple sheets:
    - Survival estimates
    - Capture histories
    - Comparison tables

**Indirectly Used:**
- `openxlsx::createWorkbook()`, `openxlsx::writeData()` for Excel file generation

#### 3.5: Visualization

**Directly Called:**
- `get_tagger_surv_plot()` — Creates reach-specific survival comparison plot
  - **Location**: `R/get_tagger_surv_plot.R`
  - **Purpose**: Generates ggplot with:
    - Points dodged by reach
    - Error bars (95% CIs)
    - Separate panels for species and location
    - Color-coding by tagger (A/B/C/POOLED)
  - **Indirectly uses**: ggplot2, dplyr, tidyr, stringr

- `get_tagger_cumul_surv_plot()` — Creates cumulative survival comparison plot
  - **Location**: `R/get_tagger_cumul_surv_plot.R`
  - **Purpose**: Same visualization approach as above but for cumulative survival

**Indirectly Used:**
- `ggplot2::ggplot()`, `ggplot2::geom_point()`, `ggplot2::geom_errorbar()`, `ggplot2::facet_grid()`
- `ggplot2::ggsave()` for saving PNG/PDF outputs
- `tidyr::pivot_longer()`, `tidyr::pivot_wider()` for data reshaping

---

## Function Dependency Tree

```
Script 03 Main Execution
├── check_md_rows()
├── summarize_blank_mds()
├── check_md_dates()
├── scrape_atlas_results()
│   └── .pivot_cjs_survival_long()
├── get_tagger_comp_tables_MOD()
│   └── create_survival_comparison_table()
│       └── compute_f_tests_by_reach()
├── create_survival_comparison_table()
│   └── compute_f_tests_by_reach()
├── create_cumul_survival_comparison_table()
│   └── compute_f_tests_by_reach_cumul()
├── create_all_cumul_survival_tables()
│   └── create_cumul_survival_comparison_table()
│       └── compute_f_tests_by_reach_cumul()
├── get_DH_tab_by_tagger()
├── get_DH_est_comp_xlsx()
├── get_tagger_surv_plot()
│   └── Uses: tidyr::pivot_longer(), tidyr::pivot_wider(), 
│        stringr::str_*(), ggplot2::*()
└── get_tagger_cumul_surv_plot()
    └── Uses: tidyr::pivot_longer(), tidyr::pivot_wider(),
         stringr::str_*(), ggplot2::*()
```

---

## Notes

- **Tagger Groups**: Data is split by physical tagging group (A, B, C) plus POOLED (all fish combined)
- **Location/Species**: Separate analyses for Rock Island (RI) and Priest Rapids (PR), Chinook (CHN) and Steelhead (STH)
- **F-tests**: Homogeneity tests indicate whether tagger effects are statistically significant at each reach/location
- **Cumulative Survival**: Represents the product of survivals across all preceding reaches; declines steadily moving downstream
- **Reach-specific Survival**: Represents survival within a single reach, independent of upstream mortality
