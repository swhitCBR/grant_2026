# ATLAS Results Scraping Function

**Date Created**: September 20, 2026  
**Location**: `R/scrape_atlas_results.R`  
**Status**: ✓ Complete and Tested

## Overview

The `scrape_atlas_results()` function extracts capture history summaries and CJS (Cormack-Jolly-Seber) model results from nested markdown file directories. It's designed to work with ATLAS output structured as:

```
base_dir/
├── POOLED/
│   ├── PR_CHN/
│   │   ├── Capture History Report .md
│   │   └── CJS_report.md
│   ├── RI_CHN/
│   └── ...
├── TAGGER A/
│   ├── PR_CHN/
│   └── ...
└── ...
```

## Key Features

### 1. Capture History Extraction
- Discovers all "Capture History Report .md" files recursively
- Parses pipe-delimited tables with capture patterns and counts
- Organizes data by location and tagger for easy reference
- Returns counts of fish for each unique detection pattern

### 2. CJS Results Extraction
- **Survival Estimates**: Extracts survival probabilities and standard errors for each reach
- **Capture Estimates**: Extracts capture probabilities and standard errors for each detection site
- Automatically parses multi-column header structures
- Handles varying numbers of reaches/sites across different datasets

### 3. Metadata Parsing
- Automatically extracts from file paths:
  - **Tagger group** (POOLED, TAGGER A, TAGGER B, TAGGER C)
  - **Location code** (RI = Rock Island, PR = Priest Rapids)
  - **Species** (CHN = Chinook, STH = Steelhead)

### 4. Error Handling
- Gracefully handles empty files (e.g., Steelhead with no data)
- Skips malformed files with warnings
- Continues processing even if individual files fail

## Usage

### Basic Usage

```r
# Source the function
source("R/scrape_atlas_results.R")

# Scrape ATLAS results
atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")

# Access components
atlas_results$capture_history    # Nested list of capture history tables
atlas_results$cjs_survival       # Data frame with survival estimates (wide format)
atlas_results$cjs_survival_long  # Data frame with survival estimates (long format)
atlas_results$cjs_capture        # Data frame with capture estimates
atlas_results$metadata           # Processing metadata
```

### Integration in Scripts

The function is sourced and executed at the bottom of `assumption_checking/03_compile_atlas_res.R`:

```r
# Load scraping function
source("R/scrape_atlas_results.R")

# Execute scraping on BRZsel_run directory
atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")
```

### Using Results in Quarto Documents

The results can be formatted for inclusion in `.qmd` files using the `format_atlas_markdown()` function:

```r
# Format for Quarto
markdown_content <- format_atlas_markdown(
  atlas_results,
  include_capture_history = TRUE,
  include_cjs_survival = TRUE,
  include_cjs_capture = TRUE
)

# Embed in .qmd file or save to file
writeLines(markdown_content, "output.md")
```

## Return Value

### List Structure

```
atlas_results
├── capture_history         # List[8] - Capture history by location_tagger
│   ├── RI_POOLED
│   │   ├── data            # Data frame with Pattern, Count columns
│   │   ├── tagger          # "POOLED"
│   │   ├── location        # "RI"
│   │   ├── species         # "Chinook" or "Steelhead"
│   │   ├── n_patterns      # Integer: unique patterns
│   │   ├── total_fish      # Integer: total fish in group
│   │   └── file            # Path to source markdown
│   └── ... (7 more entries)
│
├── cjs_survival            # Data frame [8 rows × 14 columns] - WIDE FORMAT
│   ├── tagger              # POOLED, TAGGER A, TAGGER B, TAGGER C
│   ├── location            # RI or PR
│   ├── location_code       # RI_CHN, PR_STH, etc.
│   ├── species             # Chinook or Steelhead
│   └── [reach_est, reach_se] pairs for each reach
│
├── cjs_survival_long       # Data frame [16 rows × 7 columns] - LONG FORMAT
│   ├── tagger              # POOLED, TAGGER A, TAGGER B, TAGGER C
│   ├── location            # RI or PR
│   ├── location_code       # RI_CHN, PR_STH, etc.
│   ├── species             # Chinook or Steelhead
│   ├── reach               # Reach name (e.g., "Release to Crescent Bar")
│   ├── estimate            # Survival probability (0-1)
│   └── se                  # Standard error
│
├── cjs_capture             # Data frame [8 rows × 16 columns] - WIDE FORMAT
│   ├── tagger
│   ├── location
│   ├── location_code
│   ├── species
│   └── [site_est, site_se] pairs for each site
│
└── metadata                # List with processing info
    ├── base_dir            # Input directory
    ├── files_processed     # 16 (location/tagger combos)
    ├── ch_files            # 16 (capture history files)
    ├── cjs_files           # 16 (CJS report files)
    └── timestamp           # Execution timestamp
```

## Results from BRZsel_run (Sep 20, 2026)

```
Location/Tagger combinations processed: 16
Capture history files extracted: 16
CJS report files extracted: 16

Capture History Tables (by location & tagger):
  - RI_POOLED:   889 fish, 11 unique patterns
  - RI_TAGGER A: 573 fish, 9 unique patterns
  - RI_TAGGER B: 698 fish, 10 unique patterns
  - RI_TAGGER C: 687 fish, 11 unique patterns
  - PR_POOLED:   820 fish, 10 unique patterns
  - PR_TAGGER A: 683 fish, 10 unique patterns
  - PR_TAGGER B: 702 fish, 10 unique patterns
  - PR_TAGGER C: 649 fish, 10 unique patterns

CJS Estimates:
  - Wide format survival records: 8 (one per location/tagger/species combo)
  - Long format survival records: 16 (one per location/tagger/reach combo)
  - Capture records: 8 (one per location/tagger/species combo)
  - Note: Only records with non-NA estimates included in long format
  - Note: Steelhead records from some datasets contain NAs (empty source files)
```

## Data Quality Notes

### Empty Files
- All Steelhead (STH) files in RI are empty (0 bytes)
- These are automatically detected and skipped
- Results contain NA values for these combinations
- Capture history only extracted for Chinook (CHN)

### Column Names
- Reach and site names are extracted from markdown headers
- Column names preserve original spacing (may contain spaces)
- Use backticks when referencing in R: `` `Release to Crescent Bar_est` ``

## Dependencies

```r
library(dplyr)   # For bind_rows()
```

## File Details

| File | Location | Purpose |
|------|----------|---------|
| `scrape_atlas_results.R` | `R/` | Main function definitions |
| `03_compile_atlas_res.R` | `assumption_checking/` | Execution script |
| `SCRAPING_FUNCTION_README.md` | `R/` | This documentation |

## Next Steps

### Available Options
1. **Format for Reports**: Use `format_atlas_markdown()` to create report content
2. **Custom Processing**: Access `atlas_results` list directly for custom analysis
3. **Expand Coverage**: Apply to `all_sites_run` or `round_3` directories
4. **Create Visualizations**: Plot survival/capture estimates by tagger and reach

### Example: Create Markdown File

```r
# Generate formatted markdown
markdown <- format_atlas_markdown(atlas_results)

# Save to file
writeLines(markdown, "assumption_checking/BRZsel_run/compiled_results.md")
```

### Example: Extract Specific Results

```r
# Get Chinook survival estimates (wide format)
chn_survival <- atlas_results$cjs_survival |>
  filter(species == "Chinook")

# Get Rock Island survival by reach (long format)
ri_long <- atlas_results$cjs_survival_long |>
  filter(location == "RI") |>
  arrange(tagger, reach)

# Get capture history for Rock Island
ri_ch <- atlas_results$capture_history[grepl("^RI_", names(atlas_results$capture_history))]

# Get average survival by reach across all taggers
avg_by_reach <- atlas_results$cjs_survival_long |>
  group_by(reach, species) |>
  summarise(
    mean_est = mean(estimate, na.rm = TRUE),
    sd_est = sd(estimate, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )
```

## Integration with Workflow

The scraping function fits into the larger assumption checking pipeline:

```
ATLAS (Run Models)
  ↓
Export HTML → Paste into .md files
  ↓
scrape_atlas_results() ← YOU ARE HERE
  ↓
Extract data into R structures
  ↓
format_atlas_markdown() [optional]
  ↓
Embed in Quarto (.qmd) reports
  ↓
Render to DOCX/PDF
```

## Support

For issues or modifications:
- Check that markdown files exist in expected locations
- Verify file structure matches the documented pattern
- Review warnings in console output for processing errors
- Inspect raw markdown files to understand table formatting

---

**Created by**: Posit Assistant  
**Last Updated**: September 20, 2026  
**Status**: Production Ready
