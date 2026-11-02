# QAQC Tables Vignette

This directory contains a minimum example vignette demonstrating how to create Quarto documents (`.qmd`) that render to Word (`.docx`) format with QAQC summary tables.

## Files

- **qaqc-tables-vignette.qmd** - The Quarto source document containing executable R code that demonstrates the workflow
- **qaqc-tables-vignette.docx** - The rendered Word document output

## What This Vignette Covers

The vignette demonstrates the complete workflow used in `QAQC_tables_full_set.R`:

1. **Loading and preparing data** - How to structure tag data for analysis
2. **Creating summary tables** - Implementations of key functions:
   - `tag_rel_tagger_summ_tb()` - Summarize tags by tagger, species, and location
   - `get_rel_loc_by_repID_tabs()` - Summarize tags by replicate and location
3. **Additional QAQC tables** - Fish status breakdowns and tagger performance summaries
4. **Rendering to Word** - How to render `.qmd` files as `.docx` documents with proper formatting

## How to Use

### View the Word Document
Simply open `qaqc-tables-vignette.docx` in Microsoft Word or compatible application.

### Render the Quarto Document
To regenerate the Word document from the `.qmd` source:

```r
# In R:
quarto::quarto_render("vignettes/qaqc-tables-vignette.qmd", output_format = "docx")

# Or from terminal/command line:
# quarto render vignettes/qaqc-tables-vignette.qmd --to docx
```

### Adapt for Your Own Project

The vignette uses example data. To use your actual data:

1. Replace the `example_tags` data frame creation with your actual data loading code
2. Modify the function calls to use your data subset names
3. Adjust table captions and section titles as needed
4. Render to Word as shown above

## Key Functions Demonstrated

### `tag_rel_tagger_summ_tb(tags_dat_wrepID_in)`
Creates a pivot table summarizing tag counts by:
- Species (spp)
- Tag group (live/dead release)
- Release location
- Tagger (as columns for easy comparison)

**Output**: Data frame with one row per species-tag_group-location combination

### `get_rel_loc_by_repID_tabs(tags_dat_raw_wrepID)`
Creates a list of data frames (one per species) summarizing:
- Tag counts by release location and replicate
- Release dates for each location-replicate combination
- Shortens location names to RI (Rock Island) and PR (Priest Rapids)

**Output**: Named list of data frames, split by species

## Integration with QAQC_tables_full_set.R

The main QAQC script (`QAQC_tables_full_set.R`) extends this workflow by:

1. Loading tag subsets from `.rds` files
2. Generating multiple filtered versions (RAW, ALIVE_EUTH, etc.)
3. Creating modular `.qmd` templates with `create_qmd_templates_dir()`
4. Rendering and organizing outputs in a designated directory

This vignette provides a standalone, simplified example that can be understood independently.

## Quarto YAML Options

The document uses these Quarto YAML options:

- `format: docx` - Output format is Word
- `number-sections: true` - Automatically number section headings
- `toc: true` - Generate a table of contents
- `toc-depth: 2` - TOC shows headings up to level 2

For more customization options, see [Quarto MS Word documentation](https://quarto.org/docs/output-formats/ms-word.html).

## Next Steps

- Review the rendered `.docx` file to see the final output format
- Examine `QAQC_tables_full_set.R` to see how this workflow is used in practice
- Review the helper functions in `R/` directory for more advanced implementations
- Customize table formatting using `kableExtra` or other packages if needed
