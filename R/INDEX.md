# R Functions Index

Complete reference for data extraction and table formatting functions for the grant_2026 project.

## Data Extraction

### `scrape_atlas_results()`
**File**: `R/scrape_atlas_results.R`  
**Purpose**: Extract CJS survival/capture estimates and capture history from ATLAS markdown files  
**Input**: Path to directory containing nested tagger/location/species subdirectories  
**Output**: List with:
- `capture_history` - List of capture patterns by location/tagger
- `cjs_survival` - Data frame (wide format, 16 rows × 18 cols)
- `cjs_survival_long` - Data frame (long format, 56 rows × 7 cols)
- `cjs_capture` - Data frame (wide format, 16 rows × 18 cols)
- `metadata` - Processing information

**Example**:
```r
source("R/scrape_atlas_results.R")
atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")
```

**Documentation**: See `R/SCRAPING_FUNCTION_README.md`

---

## Batch Processing

### `get_tagger_comp_tables()`
**File**: `R/get_tagger_comp_tables.R`  
**Purpose**: Create tagger comparison tables for ALL location/species combinations  
**Input**: 
- `atlas_results` - Output from `scrape_atlas_results()`
- `include_pooled` - Include POOLED tagger (default: TRUE)
- `include_se` - Include standard error columns (default: TRUE)
- `quiet` - Suppress progress messages (default: FALSE)

**Output**: Named list with 4 elements:
- `$PR_Chinook`
- `$PR_Steelhead`
- `$RI_Chinook`
- `$RI_Steelhead`

Each element is a data frame with reaches as rows, tagger estimates/SEs as columns.

**Example**:
```r
source("R/get_tagger_comp_tables.R")
tables <- get_tagger_comp_tables(atlas_results)

# Access individual tables
print(tables$RI_Chinook)
print(tables$PR_Steelhead)
```

**Key Feature**: Automatically loops through all 4 location/species combinations, eliminating the need for manual multiple calls.

---

## Table Formatting

### `create_survival_comparison_table()`
**File**: `R/create_survival_comparison_table.R`  
**Purpose**: Create wide-format comparison table for single location/species  
**Input**: 
- `atlas_results` - Output from `scrape_atlas_results()`
- `location` - "RI" or "PR"
- `species` - "Chinook" or "Steelhead"
- `include_pooled` - Include POOLED tagger (default: TRUE)
- `include_se` - Include standard error columns (default: TRUE)

**Output**: Data frame with reaches as rows, tagger estimates/SEs as columns

**Example**:
```r
source("R/create_survival_comparison_table.R")
ri_chn <- create_survival_comparison_table(
  atlas_results,
  location = "RI",
  species = "Chinook"
)
```

---

### `create_all_survival_tables()`
**File**: `R/create_survival_comparison_table.R`  
**Purpose**: Batch create comparison tables for all location/species combos  
**Input**: 
- `atlas_results` - Output from `scrape_atlas_results()`
- `include_pooled` - Include POOLED tagger (default: TRUE)
- `include_se` - Include standard error columns (default: TRUE)

**Output**: Named list with elements:
- `$RI_Chinook`
- `$RI_Steelhead`
- `$PR_Chinook`
- `$PR_Steelhead`

**Example**:
```r
all_tables <- create_all_survival_tables(atlas_results)
print(all_tables$RI_Chinook)
```

---

### `format_survival_table_markdown()`
**File**: `R/create_survival_comparison_table.R`  
**Purpose**: Convert survival comparison table to markdown format  
**Input**:
- `survival_table` - Output from `create_survival_comparison_table()`
- `caption` - Optional table caption

**Output**: Character string with markdown-formatted table

**Example**:
```r
markdown <- format_survival_table_markdown(
  ri_chn,
  caption = "RI Chinook - Survival by Reach"
)
cat(markdown)
```

---

## Workflow Integration

### Updated: `create_tagger_summary_table()`
**File**: `assumption_checking/round_1/round_1_workflow.R`  
**Purpose**: Create tagger comparison table (updated to use new functions)  
**Input**:
- `atlas_results` - Output from `scrape_atlas_results()`
- `location` - Location code (default: "RI")
- `species` - Species (default: "Chinook")
- `include_pooled` - Include POOLED (default: TRUE)

**Output**: Data frame with reach comparisons

**Example**:
```r
source("assumption_checking/round_1/round_1_workflow.R")
table <- create_tagger_summary_table(
  atlas_results,
  location = "RI",
  species = "Chinook"
)
```

---

### Updated: `run_round_1_workflow()`
**File**: `assumption_checking/round_1/round_1_workflow.R`  
**Purpose**: Main workflow function (updated to accept atlas_results)  
**New Parameters**:
- `atlas_results` - Output from `scrape_atlas_results()`
- `location` - Location to focus on (default: "RI")
- `species` - Species to analyze (default: "Chinook")

**Example**:
```r
result <- run_round_1_workflow(
  raw_data_dir = "...",
  output_dir = "...",
  atlas_results = atlas_results,
  location = "RI",
  species = "Chinook"
)
```

---

## Quick Start

### 1. Extract Data
```r
source("R/scrape_atlas_results.R")
atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")
```

### 2. Create Comparison Tables

**Option A: All 4 combinations at once (Recommended)**
```r
source("R/get_tagger_comp_tables.R")
tables <- get_tagger_comp_tables(atlas_results)

# Access as: tables$RI_Chinook, tables$PR_Steelhead, etc.
```

**Option B: Individual location/species**
```r
source("R/create_survival_comparison_table.R")
ri_chn <- create_survival_comparison_table(atlas_results, "RI", "Chinook")
```

**Option C: Batch with more control**
```r
source("R/create_survival_comparison_table.R")
all_tables <- create_all_survival_tables(atlas_results)
```

### 3. Export to Markdown
```r
markdown <- format_survival_table_markdown(ri_chn, "RI Chinook")
cat(markdown)
```

### 4. Use in Round 1 Workflow
```r
source("assumption_checking/round_1/round_1_workflow.R")
result <- run_round_1_workflow(
  raw_data_dir = "...",
  output_dir = "...",
  atlas_results = atlas_results,
  location = "RI",
  species = "Chinook"
)
```

---

## Data Available

### From `scrape_atlas_results()`

**CJS Survival (Wide)**
- 16 rows: 4 location/species × 4 taggers
- 18 columns: metadata + 7 reaches (estimate & SE each)
- Example filter: `atlas_results$cjs_survival[location == "RI", ]`

**CJS Survival (Long)**
- 56 rows: all tagger/location/reach combinations
- 7 columns: tagger, location, location_code, species, reach, estimate, se
- Ready for analysis and visualization

**CJS Capture**
- 16 rows: 4 location/species × 4 taggers
- 18 columns: metadata + 7 detection sites (estimate & SE each)

**Capture History**
- 16 entries: one per location/species/tagger combo
- Each entry contains data frame with capture patterns and counts

---

## Testing Results

All functions tested on `assumption_checking/BRZsel_run/`:

| Function | Test Case | Result |
|----------|-----------|--------|
| `scrape_atlas_results()` | BRZsel_run | ✅ 16 records (wide), 56 (long) |
| `create_survival_comparison_table()` | RI Chinook | ✅ 6 reaches × 9 columns |
| `create_survival_comparison_table()` | PR Steelhead | ✅ 1 reach × 9 columns |
| `create_all_survival_tables()` | All combos | ✅ 4 tables created |
| `format_survival_table_markdown()` | RI Chinook | ✅ Clean markdown output |
| "Priest BRZ to Lower Ringold" | Extraction | ✅ Present in 8 rows |

---

## Documentation Files

| File | Purpose |
|------|---------|
| `R/SCRAPING_FUNCTION_README.md` | Complete guide to `scrape_atlas_results()` |
| `R/SURVIVAL_COMPARISON_TABLE_README.md` | Complete guide to comparison table functions |
| `assumption_checking/WORKFLOW_SUMMARY.md` | Workflow overview and integration |
| `R/INDEX.md` | This file |

---

## Dependencies

All functions load their own dependencies:
```r
library(dplyr)      # Data manipulation
library(tidyr)      # Pivoting
library(knitr)      # Markdown formatting
```

---

**Last Updated**: September 21, 2026  
**Status**: Production Ready  
**Maintenance**: See individual function README files
