# 2026 Grant Survival Study - Analysis Pipeline

This repository contains the complete analysis pipeline for the 2026 Grant Survival Study, including data cleaning, quality assurance/quality control (QAQC), tagger-effect and condition assumption checking, replicate pooling, mixing plots, tag-life analysis, and compilation of ATLAS (CJS survival) results.

## Running the pipeline

Open `grant_2026.Rproj` (the scripts expect the repo root as the working directory) and use [`run_pipeline.R`](run_pipeline.R):

```r
source("run_pipeline.R")                      # defines pipeline_steps and run_pipeline(); runs nothing
pipeline_steps                                # the ordered list of steps (stage, type, script, notes)
run_pipeline(stages = "data_cleaning")        # run one stage
run_pipeline()                                # run every step that can run; prints a status log
```

Each script is sourced in a fresh environment and logged as `ok`, `warning`, `error` or `skipped`. Step types:

- `auto` - runs unattended.
- `manual` - done by hand in TagPro or ATLAS; printed as a reminder (`include_manual = TRUE` pauses for it).
- `after_manual` - a script that needs the output of a manual step. It runs only if its required files/folders exist, otherwise it is `skipped`.

Required inputs (checked at the start): `data/Round 2/` (raw CSVs), `data/Nov_run/` and the pooling spreadsheet `media/xlsx/replicate_regrouping/replicate releases and suggested replicate pooling.xlsx`.

## Stage order

| # | Stage | Scripts | Key outputs |
|---|---|---|---|
| 1 | `data_cleaning` | `data_cleaning/01`-`03` | `data/clean/{csv_fl_ls,tag_subsets_ls,tag_DH_ls}.rds` |
| 2 | `QAQC` | `QAQC/QAQC_tables_full_set.R` | `media/docx/QAQC word docs/SW_QAQC_tabs_{1_2,2_2}.docx` |
| 3 | `replicate_pooling` | `data_cleaning/04_create_DH_for_spec_repIDs_and_survuse_subset.R` | replicate-level detection-history count workbook in `media/xlsx/replicate_regrouping/`; `data/Nov_run/new_rep_ID_attrib_ATLAS.csv` |
| 4 | `tagger_effects` | `assumption_checking/tagger_effects/00`-`03` (TagPro and ATLAS by hand between 01 and 02, and before 03) | `media/xlsx/assumption_checking/*.xlsx`, tagger survival plots |
| 5 | `length_weight_condition` | `assumption_checking/length_weight_condition/condition_factor_plotting_by_species_MOD.R` | condition-factor figures in `media/png/assumption_checking/` |
| 6 | `mixing_plots` | `analysis/mixing plots/more_mixing_plots_live_and_dead_fish.R` | `media/png/mixing_dead_plts/*.png` |
| 7 | `taglife` | `analysis/taglife/Weibull_LRT_across_RC_values.R`, `analysis/taglife/vitality_LRT.R` | LRT summaries; `media/docx/taglife/lrt_table_weibull_rc68.98....docx` (needs flextable) |
| 8 | `analysis` | `analysis/extractinng_ATLAS_rtfs_{CHN,STH}.R` (after the manual ATLAS pooled and replicate-level runs) | `analysis/{CHN,STH}_ATLAS_out.rds` |

## Pipeline diagram

[`repo_diagram.svg`](repo_diagram.svg) shows every pipeline script, the `R/` function files they use, and the data sets and outputs they read and write (columns: inputs, R/ functions, scripts by stage, intermediate data, outputs). Open it in a browser: hover over a line to highlight it and over a box to see its full path. It is built by static analysis of the code (nothing is run) and is regenerated with:

```r
source("R/create_repo_diagram.R")
create_repo_diagram()          # writes repo_diagram.svg; reads the steps from run_pipeline.R
```

It is redrawn automatically at the end of every `run_pipeline()` call (`make_diagram = FALSE` skips it); call it by hand after adding, moving or renaming a script or output. Paths that are built at run time (the QAQC Word reports, the `analysis/*_ATLAS_out.rds` files, the taglife LRT table) and the manual TagPro/ATLAS steps are listed in the `dynamic_io` and `manual_io` arguments of `create_repo_diagram()`; update those if such a path changes.

Manual software steps are documented in `analysis/mixing plots/Creation of mixing plots_PROTOCOL.md`, `analysis/Grant_ATLAS_analysis_PROTOCOL.md` (pooled and replicate-level ATLAS runs) and `assumption_checking/tagger_effects/TagPro settings (all_sites and BRZsel).md` (TagPro for the tagger-effects runs; "BRZsel" = boat restriction zone sites).

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

Here are lines from `data_cleaning/02_create_tag_subsets.R` that show the precise filtering of field names
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
- `QAQC_tables_full_set.R` — Generate QAQC contingency and detection history tables

**Outputs**:
- Word documents (.docx) with contingency tables and detection history summaries
- Quarto-generated reports with summary statistics

**Prerequisites**: 
Must complete Stage 1 (data_cleaning) first.

→ **[See QAQC/README.md for details](QAQC/README.md)**

---

## Stage 4: Tagger effects (assumption checking)

**Location**: [`assumption_checking/tagger_effects/`](assumption_checking/tagger_effects/)

Examines the influence of taggers on survival estimates from single-release models. Preprocesses data for TagPro, creates tagger-specific ATLAS subsets, compiles ATLAS results, and performs F-tests for tagger effects. The `length_weight_condition/` subfolder (condition-factor figures) is independent of the manual steps.

**STEPS**:
0) In R, run `00_comp_SURVUSE_or_act_euth_tabs_and_plots.R` — summary tables/plots used later
1) In R, Run `01_tagpro_preprocessing.R` — Prepare data for TagPro
	- Tagpro has to be pointed at an input directory with specific event, tag, and node .csv files
	- The RAW original .csv files are subset and saved in the `data/clean/pre_tagpro` directory`
2) In TagPro, load all of the files and click through the settings.
	- → **[TagPro settings (all_sites and BRZsel)](assumption_checking/tagger_effects/TagPro%20settings%20(all_sites%20and%20BRZsel).md)**
	- Once everthing is done in TagPro there files will be output to the `data/clean/post_tagpro` directory
3) In R, use  `02_post_tagpro_preATLAS_subsets.R` to split up the data by Tagger
	- The `_ATLAS.csv` files should be subdivided into `..._ATLAS_tagger_A.csv, ..._ATLAS_tagger_B.csv, ..._ATLAS_tagger_C.csv`
	- The pooled replicate-level file `COMB_REL_*` is skipped
	- If needed create a file structure with empty `.md` files into which ATLAS output will be pasted
4) In ATLAS, load detection histories for the undivided .csv file (POOLED) and for each tagger.
	- Once the data are loaded in double click hyperlinks for "Capture Histories" and "CJS Estimate", and "Cumulative Estimates" (only if using Rock Island releases)
	- Paste the output into the `.md` files under `assumption_checking/tagger_effects/{all_sites_run,BRZsel_run}`
5) In R, use  `03_compile_postATLAS_results_and_perform_F_tests_on tagger esitmates.R` to extract and consolidate ATLAS output, perform F tests and output XLSX output

**Outputs**:
- Excel workbooks with survival comparison tables
- Statistical test results (F-tests for tagger homogeneity)

**Prerequisites**: 
Must complete Stage 1 and Stage 2 first. Also requires manual runs of TagPro and ATLAS software.

→ **[See assumption_checking/tagger_effects/README.md for details](assumption_checking/tagger_effects/README.md)**

---

## Directory Structure

```
grant_2026/
├── run_pipeline.R          # Master script (see "Running the pipeline")
├── repo_diagram.svg        # Pipeline diagram, made by R/create_repo_diagram.R
├── data_cleaning/          # Raw data processing; 01-03, plus 04 replicate pooling
│   ├── 01_load_csvs.R
│   ├── 02_create_tag_subsets.R
│   ├── 03_create_DH_from_tag_subsets.R
│   ├── 04_create_DH_for_spec_repIDs_and_survuse_subset.R
│   └── README.md
│
├── QAQC/                   # Quality control summaries and Word reports
│   ├── QAQC_tables_full_set.R
│   └── README.md
│
├── assumption_checking/
│   ├── tagger_effects/             # tagger influence on single-release survival estimates
│   │   ├── 00_...r, 01_...R, 02_...R, 03_...R
│   │   ├── all_sites_run/, BRZsel_run/   # pasted ATLAS .md output
│   │   └── README.md
│   └── length_weight_condition/    # condition-factor figures
│
├── analysis/               # mixing plots, taglife, pooled/replicate-level ATLAS parsing
│   ├── mixing plots/
│   ├── taglife/
│   ├── pooled/, replicate_level/   # saved ATLAS reports (HTML saved as .rtf)
│   ├── extractinng_ATLAS_rtfs_{CHN,STH}.R
│   └── Grant_ATLAS_analysis_PROTOCOL.md
│
├── R/                      # Shared functions (e.g. extract_atlas_rtf_tables.R, scrape_atlas_results.R, create_repo_diagram.R)
├── data/                   # Round 2 raw CSVs, Nov_run ATLAS inputs, clean/ (processed data)
├── media/                  # Outputs (docx, xlsx, png); git-ignored
├── old/                    # Archive
└── README.md              ← You are here
```

---

## Documentation Last Updated

November 4, 2026

---

## Log: 2026-11-01 - data_cleaning/04_create_DH_for_spec_repIDs_and_survuse_subset.R
Pools replicate IDs (CHN 14,15; STH 9,10 / 20,21,22 / 23,24) and joins them to the pooled ATLAS capture file by tag_code.
Builds detection-history (DHcode) counts per release location, species and replicate, including empty histories as 0.
Writes a replicate-level DH count workbook (DH_counts_long and DH_counts wide sheets) to media/xlsx/replicate_regrouping/.
Fixed 2026-11-04: rel_tot_DF_CHN/STH now read from DH_long_DF (they used tmpDF, which no longer exists).

## Log: 2026-11-04 - run_pipeline.R
New master script: runs the sourceable scripts in stage order, logs ok/warning/error/skipped, and skips scripts whose manual inputs are missing.
Removed setwd/absolute paths from the scripts; fixed stale tagger_effects paths and ATLAS extraction (repID_code attrib, pooled IDs); PR_BRZsel_ATLAS.csv filtered to Priest Rapids rows.

## Log: 2026-11-05 - R/create_repo_diagram.R
create_repo_diagram() parses the pipeline scripts and the R/ files they source and draws repo_diagram.svg (scripts, functions, data sets, outputs).
Regular-expression patterns, dir.create() folders and existence checks are ignored; folders are labelled with their full path; paths built at run time come from dynamic_io.
