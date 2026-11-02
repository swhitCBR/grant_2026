# Quick Start Guide: QAQC Tables to Word Document

## 5-Minute Workflow

### 1. Create a `.qmd` File
Create a new file named `my_report.qmd` with this basic structure:

```yaml
---
title: "My QAQC Report"
format: docx
---
```

### 2. Add R Code to Create Tables

```r
# Load data
tags_dat <- readRDS("data/clean/tag_subsets_ls.rds")[["RAW"]]

# Create summary
summary_table <- tag_rel_tagger_summ_tb(tags_dat)

# Display table
knitr::kable(summary_table, caption = "Tag Summary")
```

### 3. Render to Word

```r
quarto::quarto_render("my_report.qmd", output_format = "docx")
```

That's it! A Word document (`my_report.docx`) will be created.

---

## Common Tasks

### Task: Display a Simple Table

```r
# In your .qmd file:
knitr::kable(my_data, caption = "My Table Title")
```

### Task: Create Multiple Tables by Group

```r
# Create a list of tables (one per species)
tables_by_species <- get_rel_loc_by_repID_tabs(tags_dat)

# Display each
for (spp in names(tables_by_species)) {
  cat("\n## Species:", spp, "\n\n")
  print(knitr::kable(tables_by_species[[spp]]))
}
```

### Task: Add Formatted Text Between Tables

Use markdown:

```markdown
## My Section Title

Some explanatory text about the tables below.

### Subsection

More details here.
```

### Task: Change Table of Contents or Numbering

Modify the YAML header:

```yaml
---
title: "My Report"
format:
  docx:
    number-sections: true
    toc: true
    toc-depth: 2
---
```

Options:
- `number-sections: false` - Don't number headings
- `toc: false` - Don't create table of contents
- `toc-depth: 1` - Only show top-level headings in TOC

### Task: Apply Custom Word Styling

Create a reference Word document with your preferred styles, then add to YAML:

```yaml
---
format:
  docx:
    reference-doc: path/to/my-reference.docx
---
```

### Task: Move Output to a Specific Directory

After rendering:

```r
# Render document
quarto::quarto_render("my_report.qmd")

# Move to output directory
file.rename(
  "my_report.docx",
  file.path("output/directory", "my_report.docx")
)
```

Or in one step (as in QAQC_tables_full_set.R):

```r
quarto::quarto_render("my_report.qmd")
file.rename(
  "my_report.docx",
  file.path(output_dir_docx, "my_report.docx")
)
```

---

## Function Reference

### `tag_rel_tagger_summ_tb(tags_dat_wrepID_in)`

```r
# Input: data frame with columns: spp, tag_group, release_location, tagger, tag_code
# Output: pivot table with tagger counts

result <- tag_rel_tagger_summ_tb(tags_dat)
knitr::kable(result)
```

**Example output:**
```
spp   tag_group        release_location         Tagger_A  Tagger_B  Tagger_C
CHN   live_release     Rock Island Tailrace          5         3         2
CHN   live_release     Priest Rapids Tailrace        4         3         3
STH   dead_release     Rock Island Tailrace          2         1         2
...
```

### `get_rel_loc_by_repID_tabs(tags_dat_raw_wrepID)`

```r
# Input: data frame with columns: spp, release_location, repID, rel_date, tag_group
# Output: list of data frames (one per species)

result_list <- get_rel_loc_by_repID_tabs(tags_dat)

# Access results by species
chinook_table <- result_list[["CHN"]]
steelhead_table <- result_list[["STH"]]
```

**Example output per species:**
```
spp   repID  RI_live_release  RI_dead_release  PR_live_release  PR_dead_release  date_RI   date_PR
CHN      1               10                5               12                8      06-01  06-01
CHN      2                8                4               10                6      06-05  06-05
STH      1               15                7               18               10      06-01  06-02
...
```

---

## Troubleshooting

**Q: Document doesn't render**
- Verify file paths are correct
- Check that required packages are loaded (`dplyr`, `tidyr`, `knitr`)
- Look for error messages in the console

**Q: Tables look ugly in Word**
- Use simpler tables (fewer columns)
- Consider breaking into multiple smaller tables
- Use `kableExtra` for custom formatting (advanced)

**Q: How do I include plots?**
```r
# Just like normal R code in a .qmd file
library(ggplot2)
ggplot(my_data, aes(x, y)) + geom_point()
```

**Q: How do I hide code in the Word output?**
Add `#| echo: false` to the code chunk:
```r
#| echo: false
# This code runs but won't show in Word document
```

---

## See Also

- [Full Vignette](qaqc-tables-vignette.qmd) - Complete example with all features
- [Quarto MS Word Guide](https://quarto.org/docs/output-formats/ms-word.html)
- [QAQC_tables_full_set.R](../QAQC/QAQC_tables_full_set.R) - Production workflow
