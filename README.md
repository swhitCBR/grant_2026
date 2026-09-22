# 2026 Grant Survival Study - Analysis Pipeline

This repository contains the complete analysis pipeline for the 2026 Grant Survival Study, including data cleaning, quality assurance/quality control (QAQC), and assumption checking for CJS (Cormack-Jolly-Seber) survival analysis using ATLAS 

## Tasks Completed and in Progress

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

## 
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

## Documentation Last Updated

September 21, 2026
