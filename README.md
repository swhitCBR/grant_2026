# 2026 Grant Survival Study - Analysis Pipeline

This repository contains the complete analysis pipeline for the 2026 Grant Survival Study, including data cleaning, quality assurance/quality control (QAQC), and assumption checking for CJS (Cormack-Jolly-Seber) survival analysis using ATLAS 

## Analysis Pipeline Overview

The analysis follows a three-stage workflow:

```
Raw Data
    ↓
[Stage 1] Data Cleaning & Preprocessing
    ↓
[Stage 2] Quality Assurance/Quality Control (QAQC)
    ↓
[Stage 3] Assumption Checking & Statistical Analysis
    ↓
Publication-Ready Results & Visualizations
```

---

## Stage 1: Data Cleaning & Preprocessing

**Location**: [`data_cleaning/`](data_cleaning/)

The first stage processes raw telemetry data, creates tag subsets, and generates detection histories.

**Key Scripts**:
- `01_load_csvs.R` — Load raw CSV files from data sources
- `02_create_tag_subsets.R` — Create tag subsets with derived fields 
- `03_create_DH_from_tag_subsets.R` — Generate detection history summaries

**Outputs**:
- `data/clean/csv_fl_ls.rds` — named list of files provided by Grant
- `data/clean/tag_subsets_ls.rds` — named list of tag subsets by criteria
	- Named list of tag dataframes that are filtered using boolean commands
- `data/clean/tag_DH_ls.rds` — Detection history summaries

**IMPORTANT**!!!!
Only specific tag subsets should be used for analysis. The tag categories that are most essential are `tags_SURVUSE_AND_ALIVE_or_EUTH` group is what is to be analyzed when Euthanized fish are included. When the euthanized fish are to be ignored the `tags_SURVUSE_no_EUTH` group is used, as in the `assumption checking` directory.

Here are lines from `data_cleaning/create_tag_subsets.R` that show the precise filtering of field names
```
"tags_SURVUSE_OR_EUTH_&_ACTIVE"=tags_dat_raw_wrepID |> filter( survival_use |

                                       (fish_status %in% c("Euthanized") & tag_status=="Active")),
...
"tags_SURVUSE_no_EUTH"=tags_dat_raw_wrepID |> filter( survival_use & fish_status != c("Euthanized") )
```



→ **[See data_cleaning/README.md for details](data_cleaning/README.md)**

---

## Stage 2: Quality Assurance/Quality Control (QAQC)

**Location**: [`QAQC/`](QAQC/)

The QAQC stage generates comprehensive summary tables and reports using the cleaned data from Stage 1.

**Key Script**:
- `QAQC_tables.R` — Generate QAQC contingency and detection history tables

**Outputs**:
- Word documents (.docx) with contingency tables and detection history summaries
- Markdown reports with summary statistics

**Prerequisites**: 
Must complete Stage 1 (data_cleaning) first.

→ **[See QAQC/README.md for details](QAQC/README.md)**

---

## Stage 3: Assumption Checking & Statistical Analysis

**Location**: [`assumption_checking/`](assumption_checking/)

The assumption checking stage preprocesses data for TagPro, creates tagger-specific ATLAS subsets, compiles ATLAS results, and performs statistical tests for tagger effects.

**STEPS**:
1) In R, Run `01_tagpro_preprocessing.R` — Prepare data for TagPro
	- Tagpro has to be pointed at an input directory with specific event, tag, and node .csv files
	- The RAW original .csv files are subset and saved in the `data/clean/pre_tagpro` directory`
2) In TagPro, load all of the files and click through the following settings .
	- → **[See QAQC/README.md for details](assumption_checking/TagPro settings (aall_sites and BRZsel).md)**
	- Once everthing is done in TagPro there files will be output to the `data/clean/post_tagpro` directory
3) In R, use  `02_post_tagpro_preATLAS_subsets.R` to split up the data by Tagger
	- The `_ATLAS.csv` files should be subdivided into `..._ATLAS_tagger_A.csv, ..._ATLAS_tagger_B.csv, ..._ATLAS_tagger_C.csv`
	- If needed create a file structure with empty `.md` files into which ATLAS output will be pasted
4) In ATLAS, load detection histories for the undivided .csv file (POOLED) and for each tagger.
	- Once the data are loaded in double click hyperlinks for "Capture Histories" and "CJS Estimate", and "Cumulative Estimates" (only if using Rock Island releases)
5) In R, use  `03_compile_postATLAS_results_and_perform_F_tests_on_tagger_estimates.R` to extract and consolidate ATLAS output, perform F tests and output XLSX output

**Outputs**:
- Excel workbooks with survival comparison tables
- Statistical test results (F-tests for tagger homogeneity)

**Prerequisites**: 
Must complete Stage 1 and Stage 2 first. Also requires manual runs of TagPro and ATLAS software.

→ **[See assumption_checking/README.md for details](assumption_checking/README.md)**

---

## Quick Start

To run the complete analysis pipeline:

```r
# Stage 1: Data Cleaning (requires raw CSV files in data/Round 2/)
source("data_cleaning/01_load_csvs.R")
source("data_cleaning/02_create_tag_subsets.R")
source("data_cleaning/03_create_DH_from_tag_subsets.R")

# Stage 2: QAQC (uses outputs from Stage 1)
source("QAQC/QAQC_tables.R")

# Stage 3: Assumption Checking & Analysis
#   Part A: Prepare for TagPro
source("assumption_checking/01_tagpro_preprocessing.R")
#   [Then manually run TagPro software]

#   Part B: Create ATLAS subsets
source("assumption_checking/02_post_tagpro_preATLAS_subsets.R")
#   [Then manually run ATLAS software]

#   Part C: Compile results and analyze
source("assumption_checking/03_compile_postATLAS_results_and_perform_F_tests_on_tagger_estimates.R")
```

---

## Directory Structure

```
grant_2026/
├── data_cleaning/          # Stage 1: Raw data processing
│   ├── 01_load_csvs.R
│   ├── 02_create_tag_subsets.R
│   ├── 03_create_DH_from_tag_subsets.R
│   └── README.md          ← See here for detailed documentation
│
├── QAQC/                   # Stage 2: Quality control summaries
│   ├── QAQC_tables.R
│   └── README.md          ← See here for detailed documentation
│
├── assumption_checking/    # Stage 3: Statistical analysis
│   ├── 01_tagpro_preprocessing.R
│   ├── 02_post_tagpro_preATLAS_subsets.R
│   ├── 03_compile_postATLAS_results_and_perform_F_tests_on_tagger_estimates.R
│   └── README.md          ← See here for detailed documentation
│
├── R/                      # Shared utility functions
│   ├── scrape_atlas_results.R
│   ├── create_survival_comparison_table.R
│   ├── create_cumul_survival_comparison_table.R
│   ├── get_tagger_surv_plot.R
│   ├── get_tagger_cumul_surv_plot.R
│   └── ... (23 more utility functions)
│
├── data/                   # Data storage
│   └── clean/             # Cleaned/processed data
│
├── old/                    # Archive
│   └── obsolete_funs/     # Unused functions
│
└── README.md              ← You are here
```

---

## Key Concepts

### Tag Subsets
The analysis works with different subsets of fish tags based on criteria like:
- Survival use status
- Fish status (alive, euthanized)
- Capture/detection activity

### Tagger Groups
Fish are tagged in three physically separate batches (Tagger A, B, C), plus a combined POOLED group. Analysis tests whether survival differs across tagger groups (a potential source of bias).

### Release Locations
Data covers two release locations:
- **RI** (Rock Island Tailrace)
- **PR** (Priest Rapids Tailrace)

### Species
- **CHN** (Chinook salmon)
- **STH** (Steelhead)

### River Reaches
For Rock Island releases, survival is estimated across 7 reaches from release to Lower Ringold. Priest Rapids has a single reach (Release to Lower Ringold).

---

## Software Requirements

This analysis pipeline uses:

- **R** (≥4.5.0) with packages:
  - tidyverse (dplyr, tidyr, ggplot2)
  - openxlsx (Excel export)
  - knitr (markdown formatting)

- **External Software** (required for Stage 3):
  - **TagPro** — Processes raw telemetry into detection arrays for ATLAS
  - **ATLAS** — Estimates CJS survival and capture probabilities

---

## Contact & Questions

For questions about this analysis pipeline, see the detailed README files in each stage directory:
- Data cleaning questions → [`data_cleaning/README.md`](data_cleaning/README.md)
- QAQC questions → [`QAQC/README.md`](QAQC/README.md)
- Assumption checking & statistical questions → [`assumption_checking/README.md`](assumption_checking/README.md)

---

## Documentation Last Updated

September 21, 2026
