# Vignettes Directory

This directory contains documentation and examples for grant_2026 analysis workflows.

## Subdirectories

### [QAQC_docx_creation/](QAQC_docx_creation/)

**Vignette: Programmatically Building Quarto Documents for QAQC Reports**

This folder contains a comprehensive vignette demonstrating how to programmatically construct Quarto (`.qmd`) documents that render to Word (`.docx`) format. It shows the techniques used in `QAQC_tables_full_set.R` to dynamically generate QAQC summary reports.

**Contents:**

- **[qaqc-tables-vignette.qmd](QAQC_docx_creation/qaqc-tables-vignette.qmd)** - Full vignette source (executable Quarto document)
- **[qaqc-tables-vignette.docx](QAQC_docx_creation/qaqc-tables-vignette.docx)** - Rendered Word version
- **[demo_code.R](QAQC_docx_creation/demo_code.R)** - Standalone R script with all code examples
- **[README.md](QAQC_docx_creation/README.md)** - Detailed guide
- **[QUICK_START.md](QAQC_docx_creation/QUICK_START.md)** - Quick reference guide

**Key Topics:**

- How Quarto documents are built from text/markdown
- Helper functions that construct markdown + code block sections
- Programmatic appending of content to `.qmd` files
- Orchestrating document generation with loops
- Why this approach enables flexible, scalable reporting

**Start Here:**

1. Open `qaqc-tables-vignette.docx` to see the rendered output
2. Read `QUICK_START.md` for copy-paste examples
3. Run `demo_code.R` to see the code in action
4. Examine `qaqc-tables-vignette.qmd` for the full explanation
5. Compare with `QAQC/QAQC_tables_full_set.R` to see production usage

---

For more information about the QAQC workflow, see the main [QAQC documentation](../QAQC/).
