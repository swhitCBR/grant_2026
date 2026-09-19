# QAQC Data Summarization

Code for running QAQC data summarization for 2026 Grant Survival study.

## Main Script: `QAQC_tables.R`

This script generates quality assurance/quality control tables and reports:

- **Output directory**: Generated Word documents (.docx files) are saved to `media/docx/QAQC word docs/`
  - `SW_QAQC_tabs_1_2.docx` — Contingency tables (Part 1)
  - `SW_QAQC_tabs_2_2.docx` — Detection history summaries (Part 2)

### Sourced Functions

#### Functions Used (Directly or Indirectly)

- **`get_rel_loc_by_repID_tabs.R`** — Generates release location summaries by replicate
- **`get_tagger_rel_loc_status_tb_ls.R`** — Generates tagger/location/status summaries
- **`get_conting_tabs.R`** — Generates contingency tables (used indirectly)
- **`append_to_qmd_etc.R`** — Provides `append_to_qmd()`, `add_qsec3()`, `add_qsec3_elwise()` functions
- **`create_qmd_template.R`** — Creates Quarto template files (called indirectly via `create_qmd_templates_dir()`)
- **`create_qmd_templates_dir.R`** — Wrapper that creates both report templates
- **`get_conting_tbs_qmd_els.R`** — Appends contingency table content to Quarto reports
- **`add_DH_qsec3_elwise.R`** — Generates detection history table Quarto code blocks (used indirectly)
- **`append_DH_tabs_qmd.R`** — Appends detection history content to Quarto reports

#### Unused Functions

The following sourced files are **not used** and can be removed:

- **`build_tag_subsets.R`** (line 29) — Never called directly or indirectly
- **`get_DH_tag_code_summ.R`** (line 33) — Never called directly or indirectly

## Prerequisites

**Important:** The following scripts must be run in order before running `QAQC_tables.R`:

### 1. `data_cleaning/01_load_csvs.R`
- **Purpose**: Loads all CSV files from `data/Round 2/` directory
- **Output**: `data/clean/csv_fl_ls.rds` (list of data frames with raw event and node data)
- **Dependencies**: Raw CSV files in `data/Round 2/`

### 2. `data_cleaning/02_create_tag_subsets.R`
- **Purpose**: Creates tag subsets for QAQC and TagPro analysis
  - Loads raw CSV files
  - Adds derived fields (species, rearing type, release date, replicate IDs)
  - Creates multiple tag subsets based on fish status and survival use criteria
- **Output**: `data/clean/tag_subsets_ls.rds` (list of tag subset data frames)
- **Dependencies**: Requires output from `01_load_csvs.R`
- **Tag subsets created**:
  - `RAW` — All tags
  - `tags_ALIVE_or_EUTH` — Alive or Euthanized fish
  - `tags_SURVUSE_AND_ALIVE_or_EUTH` — Survival use AND (Alive or Euthanized)
  - `tags_SURVUSE_OR_ALIVE_or_EUTH` — Survival use OR (Alive or Euthanized)
  - `tags_SURVUSE_OR_EUTH_&_ACTIVE` — Survival use OR (Euthanized AND Active)
  - `tags_ALIVE_ACTIVE_OTHER_OR_EUTH_ACTIVE_OTHER` — (Alive AND Active AND Other) OR (Euthanized AND Active AND Other)

### 3. `data_cleaning/03_create_DH_from_tag_subsets.R`
- **Purpose**: Creates detection history summaries from tag subsets
- **Output**: `data/clean/tag_DH_ls.rds` (list of detection history data frames)
- **Dependencies**: Requires outputs from both `01_load_csvs.R` and `02_create_tag_subsets.R`
- **Detection histories**: Creates detection history summaries for multiple tag subsets across Rock Island and Priest Rapids release locations

### Running the Pipeline

```r
# Run in this order:
source("data_cleaning/01_load_csvs.R")
source("data_cleaning/02_create_tag_subsets.R")
source("data_cleaning/03_create_DH_from_tag_subsets.R")

# Then run the QAQC report generation:
source("QAQC/QAQC_tables.R")
```
