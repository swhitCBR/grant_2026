# Survival Comparison Table Functions

**Date Created**: September 21, 2026  
**Location**: `R/create_survival_comparison_table.R`  
**Status**: ✓ Complete and Tested

## Overview

Three new functions that convert the long-format CJS survival estimates from `scrape_atlas_results()` into wide-format tables suitable for reporting and comparison across taggers.

## Functions

### 1. `create_survival_comparison_table()`

Creates a wide-format table comparing survival estimates across taggers for a specific location/species combination.

**Arguments:**
- `atlas_results` - List from `scrape_atlas_results()`
- `location` - "RI" or "PR"
- `species` - "Chinook" or "Steelhead"
- `include_pooled` - Include POOLED tagger (default: TRUE)
- `include_se` - Include standard error columns (default: TRUE)

**Output:**
Data frame with reaches as rows and columns for each tagger's estimate and SE.

**Example:**
```r
source("R/create_survival_comparison_table.R")
atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")

# RI Chinook comparison
ri_chn <- create_survival_comparison_table(
  atlas_results,
  location = "RI",
  species = "Chinook"
)
```

**Output (RI Chinook):**
```
reach                       POOLED_est POOLED_se TAGGER A_est TAGGER A_se ...
Release to Crescent Bar     0.9916     0.003     0.9849       0.00668    ...
Crescent Bar to Sunland     0.9862     0.00379   0.9815       0.00747    ...
Sunland to Wanapum BRZ      0.9379     0.00792   0.9342       0.01388    ...
Wanapum BRZ to Mattawa      0.9014     0.01010   0.9060       0.01690    ...
Mattawa to Priest BRZ       0.9658     0.00650   0.9777       0.00900    ...
Priest BRZ to Lower Ringold 0.9090     0.01045   0.9163       0.01707    ...
```

### 2. `create_all_survival_tables()`

Convenience function that creates comparison tables for all 4 location/species combinations at once.

**Arguments:**
- `atlas_results` - List from `scrape_atlas_results()`
- `include_pooled` - Include POOLED tagger (default: TRUE)
- `include_se` - Include standard error columns (default: TRUE)

**Output:**
Named list with elements: `$RI_Chinook`, `$RI_Steelhead`, `$PR_Chinook`, `$PR_Steelhead`

**Example:**
```r
all_tables <- create_all_survival_tables(atlas_results)

# Access individual tables
print(all_tables$RI_Chinook)
print(all_tables$PR_Steelhead)
```

### 3. `format_survival_table_markdown()`

Converts a survival comparison table to markdown format for inclusion in Quarto documents.

**Arguments:**
- `survival_table` - Data frame from `create_survival_comparison_table()`
- `caption` - Optional table caption

**Output:**
Character string with markdown-formatted table

**Example:**
```r
markdown <- format_survival_table_markdown(
  ri_chn,
  caption = "Rock Island Chinook - Survival by Reach and Tagger"
)
cat(markdown)
```

## Integration with `round_1_workflow.R`

The `create_tagger_summary_table()` function in `round_1_workflow.R` has been updated to use these new functions:

```r
# In round_1_workflow.R
summary_table <- create_tagger_summary_table(
  atlas_results = atlas_results,
  location = location,
  species = species,
  include_pooled = TRUE
)
```

The updated workflow function now accepts:
- `atlas_results` - Output from `scrape_atlas_results()`
- `location` - Location to focus on (default: "RI")
- `species` - Species to analyze (default: "Chinook")

## Usage Examples

### Example 1: Single Location/Species Comparison

```r
library(dplyr)
source("R/scrape_atlas_results.R")
source("R/create_survival_comparison_table.R")

# Scrape ATLAS results
atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")

# Create RI Chinook comparison
ri_chn <- create_survival_comparison_table(
  atlas_results,
  location = "RI",
  species = "Chinook"
)

# Display
print(ri_chn)
```

### Example 2: Create All Tables and Export to Markdown

```r
# Create all tables
all_tables <- create_all_survival_tables(atlas_results)

# Convert each to markdown
for (name in names(all_tables)) {
  markdown <- format_survival_table_markdown(
    all_tables[[name]],
    caption = name
  )
  cat(sprintf("\n## %s\n\n", name))
  cat(markdown)
}
```

### Example 3: Use in Round 1 Workflow

```r
source("R/scrape_atlas_results.R")
source("assumption_checking/round_1/round_1_workflow.R")

# Scrape results from BRZsel_run
atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")

# Run workflow with atlas_results
result <- run_round_1_workflow(
  raw_data_dir = "data/round_1",
  output_dir = "assumption_checking/round_1/output",
  atlas_results = atlas_results,
  location = "RI",
  species = "Chinook",
  render_report = FALSE
)

# Access summary table
print(result$survival_summary)
```

## Test Results (BRZsel_run)

### RI Chinook
- **Reaches**: 6
- **Taggers**: POOLED, TAGGER A, TAGGER B, TAGGER C
- **Columns**: 9 (reach + 8 for taggers)
- **Survival range**: 0.901 - 0.994

### RI Steelhead
- **Reaches**: 6
- **Taggers**: POOLED, TAGGER A, TAGGER B, TAGGER C
- **Columns**: 9 (reach + 8 for taggers)
- **Survival range**: 0.791 - 0.996

### PR Chinook
- **Reaches**: 1 ("Release to Lower Ringold")
- **Taggers**: POOLED, TAGGER A, TAGGER B, TAGGER C
- **Columns**: 9
- **Survival range**: 0.892 - 0.940

### PR Steelhead
- **Reaches**: 1 ("Release to Lower Ringold")
- **Taggers**: POOLED, TAGGER A, TAGGER B, TAGGER C
- **Columns**: 9
- **Survival range**: 0.791 - 0.900

## Features

✅ **Wide-format output** - Easy to scan and compare across taggers  
✅ **Flexible filtering** - Works with any location/species combination  
✅ **Includes standard errors** - Complete uncertainty information  
✅ **Ordered columns** - Consistent tagger column order (POOLED first)  
✅ **Ordered rows** - Reaches in logical downstream order  
✅ **Markdown export** - Seamless integration with Quarto reports  
✅ **Batch processing** - Create all 4 tables at once  

## Dependencies

```r
library(dplyr)     # Data manipulation
library(tidyr)     # Pivoting
library(knitr)     # Markdown formatting
```

## Files

| File | Purpose |
|------|---------|
| `R/create_survival_comparison_table.R` | Main functions |
| `assumption_checking/round_1/round_1_workflow.R` | Updated to use new functions |
| `R/SURVIVAL_COMPARISON_TABLE_README.md` | This documentation |

## Next Steps

- Use in Quarto reports for publication-ready tables
- Add statistical tests (F-tests for tagger effect homogeneity)
- Create visualizations (faceted plots of survival by reach and tagger)
- Export to CSV or Excel for sharing with collaborators

---

**Status**: Production Ready  
**Tested**: September 21, 2026  
**Integration**: Round 1 Workflow updated
