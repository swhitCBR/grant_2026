# assumption_checking - Quick Reference

## Typical Analysis Workflow

### Phase 1: Data Preprocessing
```r
# Run 01_tagpro_preprocessing.R
# Loads raw data from data/clean/
# Outputs: data/clean/pre_tagpro/ 
#   - tags.csv
#   - events.csv  
#   - nodes.csv
```

### Phase 2: Create Tagger Subsets
```r
# Run 02_post_tagpro_preATLAS_subsets.R
# Requires ATLAS files in data/clean/post_tagpro/
# Outputs: Tagger-specific ATLAS files
#   - RI_tagger_comparison_ATLAS_tagger_A.csv
#   - PR_tagger_comparison_ATLAS_tagger_A.csv
#   - etc. for taggers B, C, ...
```

### Phase 3: Run External Analysis
```
Feed tagger-specific ATLAS files to external analysis tool
Generate CJS survival estimates and F-test p-values
```

### Phase 4: Report Generation
```r
# 1. Create/update markdown table with results
#    Template: tagger_table_template.md
#    Fill with: estimates, standard errors, p-values
#    Output: tagger_table_with_pvalues.md

# 2. Create/update Quarto report
#    Template: tagger_table_report.qmd
#    Embed tables from step 1
#    Include visualization: tagger_survival_comparison.png

# 3. Render to Word
quarto::quarto_render("tagger_table_report.qmd", output_format = "docx")
```

## File Organization by Round

Each round (round_1, round_2, round_3) contains:
```
round_X/
├── tagger_table_template.md          # Empty template
├── tagger_table_filled.md            # Populated version
├── tagger_table_with_pvalues.md      # With p-values
├── tagger_table_report.qmd           # Quarto report
├── tagger_survival_comparison.png    # Visualization
└── tagger_effects/                   # External analysis output
    ├── POOLED/
    │   ├── PR_CHN/
    │   │   ├── Capture History Report.md
    │   │   └── CJS_report.md
    │   └── ...
    └── TAGGER A/
        ├── PR_CHN/
        └── ...
```

## Table Structure

All markdown tables follow this pattern:
```
| Reach | Tagger A: Estimate | Tagger A: SE | Tagger B: Estimate | ... | P-value |
|-------|-------------------|--------------|-------------------|-----|---------|
| (data) |                   |              |                   |     |         |
```

Grouped by:
- Release location (RI, PR)
- Species (CHN = Chinook, STH = Steelhead)
- Reach (segments between acoustic nodes)

## Key Functions

### From `R/preprocess_for_tagpro.R`:
- `preprocess_for_tagpro()` - Main preprocessing function
- `filter_events_nodes()` - Subset events/nodes by tag_code

### Workflow Functions (round_3):
- `run_round_1_workflow()` - Complete reproducible workflow

## Rendering Command

```r
# From round_X directory or with full path:
quarto::quarto_render(
  "tagger_table_report.qmd",
  output_format = "docx"
)

# Uses reference doc: templates/ref_doc_w.docx
# Outputs: tagger_table_report.docx
```

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| ATLAS files not found | Run external analysis tool to generate RI/PR comparison ATLAS files |
| Missing figures | Ensure tagger_survival_comparison.png exists in report directory |
| Table formatting wrong | Check markdown syntax in tagger_table_with_pvalues.md |
| Word styling off | Verify reference-doc path in YAML header of .qmd |
| Tagger subsets empty | Check filter logic in 02_post_tagpro_preATLAS_subsets.R |
