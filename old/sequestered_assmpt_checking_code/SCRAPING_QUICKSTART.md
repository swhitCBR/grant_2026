# Markdown Scraping: Quick Start Guide

**Last Updated**: September 16, 2026

## One-Minute Overview

The assumption_checking pipeline now automatically extracts capture history tables from markdown files and includes them in enhanced Quarto reports.

- **What**: Scrapes 8 capture history tables from tagger_effects/ directories
- **Result**: Enhanced report with 10 total tables (2 survival + 8 capture history)
- **Output**: `tagger_table_report_with_capture_history.docx` (15.7 KB)

## Quick Start

### Generate Enhanced Report for Round 3

```r
setwd("c:/repos/grant_2026/assumption_checking/round_3")
quarto::quarto_render("tagger_table_report_with_capture_history.qmd", output_format = "docx")
```

Output: `tagger_table_report_with_capture_history.docx` ✓

### Extract Capture History Programmatically

```r
setwd("c:/repos/grant_2026")
source("assumption_checking/scrape_markdown_tables.R")

# Extract from round_3
scraped <- scrape_capture_history("assumption_checking/round_3")

# Generate markdown
markdown <- format_capture_history_tables(scraped)

# Save to file
save_capture_history_markdown(scraped, "assumption_checking/round_3/capture_history_tables.md")
```

## Files

### Scripts
| File | Purpose |
|------|---------|
| `scrape_markdown_tables.R` | Main scraping script with all functions |

### Outputs (Round 3)
| File | Content | Size |
|------|---------|------|
| `capture_history_tables.md` | Formatted markdown | 2.1 KB |
| `tagger_table_report_with_capture_history.qmd` | Quarto template | 4.2 KB |
| `tagger_table_report_with_capture_history.docx` | Generated report | 15.7 KB |

### Documentation
| File | Content |
|------|---------|
| `CAPTURE_HISTORY_SCRAPING.md` | Technical details |
| `MARKDOWN_SCRAPING_SUMMARY.md` | Complete overview |
| `SCRAPING_QUICKSTART.md` | This file |

## Key Functions

### scrape_capture_history()
```r
scraped <- scrape_capture_history("assumption_checking/round_3")
```
Extracts all capture history tables from markdown files.

### format_capture_history_tables()
```r
markdown <- format_capture_history_tables(scraped)
```
Converts extracted data to formatted markdown tables.

### save_capture_history_markdown()
```r
save_capture_history_markdown(scraped, "output.md")
```
Saves formatted markdown to file.

## Data Summary

### Round 3 Chinook Data
```
Rock Island (RI):      2,206 fish total (POOLED + A + B + C)
Priest Rapids (PR):    1,788 fish total (POOLED + A + B + C)
TOTAL:                 3,994 fish, 67 unique patterns
```

## Report Options

### Original (Survival Estimates Only)
```r
quarto::quarto_render("tagger_table_report.qmd", output_format = "docx")
# Output: 14.5 KB, 2 tables
```

### Enhanced (Survival + Capture History)
```r
quarto::quarto_render("tagger_table_report_with_capture_history.qmd", output_format = "docx")
# Output: 15.7 KB, 10 tables
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Script not found | Ensure in assumption_checking/ directory |
| 0 tables extracted | Check tagger_effects/ subdirectories exist |
| Empty Steelhead data | Normal - automatically skipped |
| Report won't render | Verify qmd file exists |

## Support

For more details, see:
- `CAPTURE_HISTORY_SCRAPING.md` - Technical documentation
- `MARKDOWN_SCRAPING_SUMMARY.md` - Complete overview

---

**Status**: ✓ Production Ready  
**Version**: 1.0
