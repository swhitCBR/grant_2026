# Pipeline File Linkage Documentation

## Overview

This document traces all file I/O operations across the three-stage data processing and reporting pipeline:
1. **Stage 1:** `data_cleaning/01_load_csvs.R` - Load raw CSVs
2. **Stage 2:** `data_cleaning/01_create_tag_subsets.R` - Create tag subsets
3. **Stage 3:** `QAQC/QAQC_tables.R` - Generate QAQC reports

## Stage 1: Load CSV Files

**Script:** `data_cleaning/01_load_csvs.R`

### Input Files
- `data/Round 2/GPUD2026_tags_17Aug2026.csv` - Raw tag metadata (3,496 rows)
- `data/Round 2/GPUD2026_events_17Aug2026.csv` - Detection events (75,866 rows)
- `data/Round 2/GPUD2026_nodes_12Aug2026.csv` - Detection nodes (91 rows)

### Output Files
- **`data/clean/csv_fl_ls.rds`** - RDS list containing loaded CSVs (UPDATED: was `QAQC/tmp_data/csv_fl_ls.rds`)
- **`data/clean/{filename}.rds`** - Individual RDS files for each CSV

### R Objects Created
- `csv_fl_ls` - List with 5 elements (tags, events, nodes, + others)

---

## Stage 2: Create Tag Subsets

**Script:** `data_cleaning/01_create_tag_subsets.R`

### Source Files (Helper functions)
- `QAQC/R/get_rel_loc_by_repID_tabs.R`
- `QAQC/R/build_tag_subsets.R`
- `QAQC/R/get_conting_tabs.R`
- `QAQC/R/append_to_qmd_etc.R`
- `QAQC/R/get_tagger_rel_loc_status_tb_ls.R`

### Input Files
- **`data/clean/csv_fl_ls.rds`** ← From Stage 1 (UPDATED: was `QAQC/tmp_data/csv_fl_ls.rds`)
  - Loads: `csv_fl_ls$GPUD2026_tags_17Aug2026`
  
⚠️ **NOTE:** Script currently still loads from `QAQC/tmp_data/csv_fl_ls.rds` at line 36 — needs to be updated

### Processing Steps
1. Add derived fields to tags data:
   - `spp_code`, `spp`, `reartype`, `rel_date`
   - `rep_loc`, `rep_num`, `repID`, `release_location`
   
2. Create 6 tag subsets with different filtering criteria:
   - `RAW` (n=3,496)
   - `tags_ALIVE_or_EUTH` (n=3,480)
   - `tags_SURVUSE_AND_ALIVE_or_EUTH` (n=2,976)
   - `tags_SURVUSE_OR_ALIVE_or_EUTH` (n=3,480)
   - `tags_SURVUSE_OR_EUTH_&_ACTIVE` (n=3,020)
   - `tags_ALIVE_ACTIVE_OTHER_OR_EUTH_ACTIVE_OTHER` (n=684)

### Output Files
- **`data/clean/tag_subsets_ls.rds`** - RDS list with 6 tag subsets (302 KB)

### R Objects Created
- `tag_subsets_ls` - Named list with 6 data frames
- `tags_dat_raw_wrepID` - Tags with replicate IDs

---

## Stage 3: Generate QAQC Reports

**Script:** `QAQC/QAQC_tables.R`

### Source Files (Helper functions)
- `QAQC/R/get_rel_loc_by_repID_tabs.R`
- `QAQC/R/build_tag_subsets.R`
- `QAQC/R/get_conting_tabs.R`
- `QAQC/R/append_to_qmd_etc.R`
- `QAQC/R/get_tagger_rel_loc_status_tb_ls.R`
- `QAQC/R/get_DH_tag_code_summ.R`

### Input Files (RDS)
- **`../data/clean/tag_subsets_ls.rds`** ← From Stage 2
  - Relative path: from QAQC/ → `../data/clean/tag_subsets_ls.rds`
  - Loads all 6 tag subsets for analysis

- **`tmp_data/csv_fl_ls.rds`** ← From Stage 1
  - ⚠️ **BROKEN:** Script loads from `tmp_data/csv_fl_ls.rds` (line 35), but Stage 1 now saves to `data/clean/csv_fl_ls.rds`
  - Used for `events_dat` and `node_dat` (detection histories)

### Template Files (Copied → Modified)
- `QAQC/templates/qmd/SW_QAQC_tabs_1_2_template.qmd`
  → `QAQC/SW_QAQC_tabs_1_2.qmd`
  
- `QAQC/templates/qmd/SW_QAQC_tabs_2_2_template.qmd`
  → `QAQC/SW_QAQC_tabs_2_2.qmd`

### Reference Documents (Referenced in YAML)
- `QAQC/templates/docx/ref_doc.docx` (Style reference for part 1)
- `QAQC/templates/docx/ref_doc_w.docx` (Style reference for part 2)

### Quarto Rendering Process
**Part 1 (Contingency Tables):**
```
QAQC/SW_QAQC_tabs_1_2.qmd
  ↓
Quarto processes R code chunks, loads tag_subsets_ls
  ↓
QAQC/SW_QAQC_tabs_1_2.knit.md (intermediate)
  ↓
Pandoc applies ref_doc.docx styling
  ↓
QAQC/SW_QAQC_tabs_1_2.docx (final output)
```

**Part 2 (Detection Histories):**
```
QAQC/SW_QAQC_tabs_2_2.qmd
  ↓
Quarto processes R code chunks, loads tag_subsets_ls and events data
  ↓
QAQC/SW_QAQC_tabs_2_2.knit.md (intermediate)
  ↓
Pandoc applies ref_doc_w.docx styling
  ↓
QAQC/SW_QAQC_tabs_2_2.docx (final output)
```

### Output Files (Final)
- **`QAQC/SW_QAQC_tabs_1_2.docx`** (17 KB) - Contingency tables report
- **`QAQC/SW_QAQC_tabs_2_2.docx`** (27 KB) - Detection history report

### Output Files (Intermediate)
- `QAQC/SW_QAQC_tabs_1_2.knit.md` - Quarto markdown intermediate
- `QAQC/SW_QAQC_tabs_2_2.knit.md` - Quarto markdown intermediate

### RDS Files Saved (Internal)
- **`QAQC/tmp_data/tag_DH_ls.rds`** - Detection history summaries (line 223)
  - ⚠️ **VIOLATION:** Script saves to `QAQC/tmp_data/` directory (should be `data/clean/` to avoid tmp_data directory)
  - Contains: SU_E_ACT_RI_summ, SU_E_ACT_PR_summ, raw_RI_summ, raw_PR_summ

---

## Complete Dependency Chain

```
Raw Data (data/Round 2/)
    ↓
[Stage 1: 01_load_csvs.R]
    ↓
data/clean/csv_fl_ls.rds ✓ (UPDATED)
    ↓
[Stage 2: 01_create_tag_subsets.R] ❌ Loads from QAQC/tmp_data/csv_fl_ls.rds
    ↓
data/clean/tag_subsets_ls.rds ←─────────────────────┐
                                                     │
data/clean/csv_fl_ls.rds ←──────────┐               │ (but Stage 3 tries to load from tmp_data/)
                                     │               │
QAQC/templates/qmd/*.qmd ←──┐       │               │
QAQC/templates/docx/*.docx ←┤       │               │
                            │       │               │
                [Stage 3: QAQC_tables.R] ❌ Loads from tmp_data/
                            │
                            ↓
            ❌ QAQC/tmp_data/tag_DH_ls.rds (saves to tmp_data — violation)
            QAQC/SW_QAQC_tabs_1_2.docx
            QAQC/SW_QAQC_tabs_2_2.docx
```

---

## Critical Linkage Points

### Linkage 1: CSV Loading → Tag Subset Creation
- **From:** Stage 1 saves to `data/clean/csv_fl_ls.rds` (UPDATED)
- **To:** Stage 2 loads from `QAQC/tmp_data/csv_fl_ls.rds` (line 36)
- **Status:** ❌ **BROKEN** - Paths do NOT match. Stage 2 needs to be updated to load from `../data/clean/csv_fl_ls.rds`

### Linkage 2: Tag Subset Creation → QAQC Analysis
- **From:** Stage 2 saves to `data/clean/tag_subsets_ls.rds`
- **To:** Stage 3 loads from `../data/clean/tag_subsets_ls.rds` (from QAQC/)
- **Status:** ✓ **VERIFIED** - Relative path resolves correctly
  - From QAQC/ directory: `../data/clean/` → resolves to repo_root/data/clean/

### Linkage 3: Event Data for Detection Histories
- **From:** Stage 1 saves `csv_fl_ls` to `data/clean/csv_fl_ls.rds` (UPDATED)
- **To:** Stage 3 loads from `tmp_data/csv_fl_ls.rds` (line 35)
- **Status:** ❌ **BROKEN** - Path mismatch. Stage 3 needs to load from `../data/clean/csv_fl_ls.rds`

### Linkage 4: Template Files
- **From:** `QAQC/templates/qmd/SW_QAQC_tabs_*.qmd`
- **To:** Copied to QAQC/ and rendered
- **Status:** ✓ **VERIFIED** - file.copy() references updated in QAQC_tables.R

### Linkage 5: Reference Documents (YAML)
- **From:** `QAQC/templates/docx/ref_doc*.docx`
- **To:** Referenced in template YAML under `reference-doc:`
- **Status:** ✓ **VERIFIED** - Paths updated in both template files

---

## Summary

| Stage | Script | Input | Output | Status |
|-------|--------|-------|--------|--------|
| 1 | 01_load_csvs.R | data/Round 2/*.csv | **data/clean/csv_fl_ls.rds** ✓ UPDATED | ✓ OK |
| 2 | 01_create_tag_subsets.R | ❌ QAQC/tmp_data/csv_fl_ls.rds (should be data/clean/) | data/clean/tag_subsets_ls.rds | ❌ BROKEN |
| 3 | QAQC_tables.R | ❌ tmp_data/csv_fl_ls.rds (should be ../data/clean/) | ❌ QAQC/tmp_data/tag_DH_ls.rds (violation) | ❌ BROKEN |

---

## ⚠️ ISSUES FOUND

### Issue 1: Stage 1 → Stage 2 Linkage BROKEN
- **Location:** `data_cleaning/01_create_tag_subsets.R`, line 36
- **Problem:** Loads from `QAQC/tmp_data/csv_fl_ls.rds` but Stage 1 now saves to `data/clean/csv_fl_ls.rds`
- **Fix Required:** Change line 36 to: `csv_fl_ls <- readRDS("../data/clean/csv_fl_ls.rds")`

### Issue 2: Stage 1 → Stage 3 Linkage BROKEN
- **Location:** `QAQC/QAQC_tables.R`, line 35
- **Problem:** Loads from `tmp_data/csv_fl_ls.rds` but Stage 1 now saves to `data/clean/csv_fl_ls.rds`
- **Fix Required:** Change line 35 to: `csv_fl_ls <- readRDS("../data/clean/csv_fl_ls.rds")`

### Issue 3: Stage 3 Saves to QAQC/tmp_data (VIOLATION)
- **Location:** `QAQC/QAQC_tables.R`, line 223
- **Problem:** Saves `tag_DH_ls` to `QAQC/tmp_data/tag_DH_ls.rds`, but requirement is to NOT use `tmp_data` directory
- **Fix Required:** Change line 223 to: `saveRDS(tag_DH_ls, "../data/clean/tag_DH_ls.rds")`
