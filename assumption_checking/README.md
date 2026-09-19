# Assumption Checking: Report Generation Pipeline

**Status**: ✓ Production Ready  
**Last Updated**: September 16, 2026  
**Latest Version**: 2.0 (both round_1 and round_3 operational)

## Overview

This directory contains the complete pipeline for generating CJS (Cormack-Jolly-Seber) survival analysis reports comparing tagger effects across release locations and reaches.

## Quick Start

### Generate Reports

**Round 1** (All Fish - Chinook + Steelhead):
```r
setwd("c:/repos/grant_2026/assumption_checking/round_1")
quarto::quarto_render("tagger_table_report.qmd", output_format = "docx")
```
Output: `tagger_table_report.docx` (203 KB)

**Round 3** (Chinook Only):
```r
setwd("c:/repos/grant_2026/assumption_checking/round_3")
quarto::quarto_render("tagger_table_report.qmd", output_format = "docx")
```
Output: `tagger_table_report.docx` (14.5 KB)

## Directory Structure

```
assumption_checking/
│
├── round_1/                         Complete pipeline (all fish)
│   ├── tagger_table_report.qmd      Quarto template
│   ├── tagger_table_report.docx     Generated report (203 KB)
│   ├── tagger_survival_comparison.png
│   ├── render_report.R              Helper script
│   ├── PIPELINE_TEST_REPORT.md      Test results
│   └── tagger_table_*.md            Data & templates
│
├── round_3/                         Complete pipeline (Chinook only)
│   ├── tagger_table_report.qmd      Quarto template
│   ├── tagger_table_report.docx     Generated report (14.5 KB)
│   ├── tagger_table_with_pvalues_chinook_only.md
│   ├── render_report.R              Helper script
│   ├── PIPELINE_TEST_REPORT.md      Test results
│   ├── STEELHEAD_DATA_ANALYSIS.md   Data analysis & decisions
│   └── tagger_table_*.md            Data & templates
│
├── templates/                       Shared Word styling
│   ├── ref_doc_w.docx              (current template)
│   └── ref_doc.docx
│
├── old/                            Archive (previous versions)
│
└── Documentation/
    ├── README.md                   ← You are here
    ├── IMPLEMENTATION_COMPLETE.md  Complete implementation summary
    ├── PIPELINE_SUMMARY.md         Quick start & overview
    ├── ROUND_COMPARISON.md         Detailed round comparison
    ├── WORKFLOW.md                 Architecture & design
    ├── WORKFLOW_QUICKREF.md        Quick reference guide
    └── PIPELINE_SUMMARY.md         (alternate entry point)
```

## Key Differences Between Rounds

| Aspect | Round 1 | Round 3 |
|--------|---------|---------|
| **Scope** | All Fish (CHN + STH) | Chinook Only |
| **Chinook tables** | 2 (RI + PR) | 2 (RI + PR) |
| **Steelhead tables** | 2 (RI + PR) full data | 0 (omitted - empty files) |
| **Visualization** | Yes (PNG included) | No |
| **DOCX size** | 203 KB | 14.5 KB |
| **Data status** | Complete | Partial (CHN ready, STH pending) |

## What's Happened with Round 3 Steelhead Data?

**Finding**: All 8 Steelhead data files are empty (0 bytes)

**Decision**: Omit Steelhead sections entirely from report

**Rationale**:
- ✓ Professional, clean report (only valid data)
- ✓ Transparent scope (title explicitly says "Chinook Only")
- ✓ Better than empty placeholder tables
- ✓ Fully documented (see STEELHEAD_DATA_ANALYSIS.md)
- ✓ Reversible (easy to add STH when data available)

**When STH Data Arrives**: Simply update .qmd to include STH sections and re-render.

## Files at a Glance

### Report Templates (.qmd)
- `round_1/tagger_table_report.qmd` - Full report (4 tables)
- `round_3/tagger_table_report.qmd` - Chinook-only (2 tables)

### Generated Reports (.docx)
- `round_1/tagger_table_report.docx` - 203 KB (all data)
- `round_3/tagger_table_report.docx` - 14.5 KB (Chinook only)

### Helper Scripts (.R)
- `round_1/render_report.R` - Render with error checking
- `round_3/render_report.R` - Render with error checking

### Test Documentation
- `round_1/PIPELINE_TEST_REPORT.md` - Test results & verification
- `round_3/PIPELINE_TEST_REPORT.md` - Test results & verification
- `round_3/STEELHEAD_DATA_ANALYSIS.md` - Data analysis & decisions

### Root Documentation
- `IMPLEMENTATION_COMPLETE.md` - Complete summary
- `PIPELINE_SUMMARY.md` - Executive overview
- `ROUND_COMPARISON.md` - Detailed comparison
- `WORKFLOW.md` - Original architecture
- `WORKFLOW_QUICKREF.md` - Quick reference

## Test Results

✓ **Round 1**: Renders to valid DOCX (203 KB, 4 tables + PNG)  
✓ **Round 3**: Renders to valid DOCX (14.5 KB, 2 tables)  

Both tested on: September 16, 2026, 14:20-14:26 PDT

## How to Update Reports

### Update Data in Round 1
1. Edit `round_1/tagger_table_with_pvalues.md`
2. Run render script or quarto command (see above)

### Update Data in Round 3
1. Edit `round_3/tagger_table_with_pvalues_chinook_only.md`
2. Run render script or quarto command (see above)

### Add Steelhead to Round 3 (when data available)
1. Create/populate `round_3/tagger_table_with_pvalues_both_species.md`
2. Update `.qmd` file with STH sections
3. Change title from "Chinook Only" to appropriate scope
4. Re-render

## Data Content

### Reaches
- **RI**: Rock Island Tailrace (6 reaches in Chinook data)
- **PR**: Priest Rapids Tailrace (1 reach in Chinook data)

### Tagger Comparison
Tables compare three taggers (A, B, C) for each reach:
- CJS survival estimates
- Standard errors (SE)
- F-test p-values (for testing homogeneity of tagger effects)

### Statistical Tests
- F-test for homogeneity of survival estimates across taggers
- Significant results (p < 0.05) highlighted in reports

## Dependencies

**Required**:
- R
- Quarto package: `install.packages("quarto")`
- Pandoc (included with Quarto)

**Optional**:
- RStudio (for visual rendering interface)
- Word (to view .docx files)

**Not Required**:
- External data sources (embedded in .qmd)
- Active console during rendering (self-contained)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "File not found" | Ensure working directory is set to `round_1` or `round_3` |
| "Reference document not found" | Verify `../templates/ref_doc_w.docx` exists |
| Quarto not found | Install: `install.packages("quarto")` |
| Pandoc error | Quarto should include Pandoc; reinstall if needed |
| Empty Word document | Check YAML metadata in .qmd file |

## Support

### For Round 1 Implementation Details
→ See `round_1/PIPELINE_TEST_REPORT.md`

### For Round 3 Implementation Details
→ See `round_3/PIPELINE_TEST_REPORT.md`

### For Round 3 Steelhead Decision Rationale
→ See `round_3/STEELHEAD_DATA_ANALYSIS.md`

### For Architecture & Design
→ See `WORKFLOW.md`

### For Quick Reference
→ See `WORKFLOW_QUICKREF.md`

## Version History

### Version 2.0 (September 16, 2026)
- ✓ Round 1 pipeline verified and documented
- ✓ Round 3 pipeline created with Chinook-only design
- ✓ Intelligent handling of empty Steelhead data
- ✓ Comprehensive documentation
- ✓ Both pipelines tested and operational

### Version 1.0 (Earlier)
- Initial pipeline in old/ directory

## Status

✅ **Both pipelines operational and tested**  
✅ **All documentation complete**  
✅ **No breaking changes**  
✅ **Ready for production use**  

---

**Next Steps**:
1. Review PIPELINE_SUMMARY.md for overview
2. Review ROUND_COMPARISON.md to understand differences
3. Generate reports using commands above
4. When Round 3 Steelhead data available, update .qmd and re-render

**Questions?** See the comprehensive documentation files listed above.
