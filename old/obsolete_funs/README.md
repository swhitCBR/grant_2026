# Obsolete Functions

This directory contains R functions that are no longer used by the active analysis pipeline (data_cleaning, QAQC, and assumption_checking workflows).

These functions have been archived to avoid clutter in the main R/ directory while preserving them for potential future reference or recovery.

## Moved Functions (6 total)

### Explicitly Marked as Unused (per QAQC/README.md)

1. **`build_tag_subsets.R`**
   - Status: Explicitly marked as unused in QAQC/README.md (line 31)
   - Reason: Never called directly or indirectly in QAQC pipeline
   - Note: Tag subsetting now happens in `data_cleaning/02_create_tag_subsets.R`

2. **`get_DH_tag_code_summ.R`**
   - Status: Explicitly marked as unused in QAQC/README.md (line 32)
   - Reason: Never called directly or indirectly in QAQC pipeline
   - Note: Detection history functionality moved to other functions

### Not Documented in Either README

3. **`create_post_tagpro_subsets.R`**
   - Reason: Not called by any active analysis script
   - Possible replacement: `create_atlas_tagger_subsets.R` (currently used)

4. **`get_DH_tab_by_tagger_MOD.R`**
   - Reason: MOD version created but not integrated into pipeline
   - Note: Standard version `get_DH_tab_by_tagger.R` is currently used
   - Status: Appears to be a development/testing variant

5. **`get_tagger_comp_tables.R`**
   - Reason: Superseded by `get_tagger_comp_tables_MOD.R`
   - Comment: Original script marked as "dumb and bad" in `assumption_checking/03_compile_postATLAS_results_and_perform_F_tests_on_tagger_estimates.R` (line 75)
   - Note: MOD version is currently active and documented

6. **`plot_DH_by_repID.R`**
   - Reason: Not called by any active analysis script
   - Possible replacement: `get_tagger_surv_plot.R` or `get_tagger_cumul_surv_plot.R` (currently used for survival plotting)

---

## When to Restore Functions

To restore a function to the active R/ directory:

1. Move it back from `old/obsolete_funs/` to `R/`
2. Update the relevant README.md files to document its use
3. Verify that all dependencies are available
4. Test the function with current data

Example:
```bash
mv old/obsolete_funs/function_name.R R/
```

---

## Archive Date

Functions moved: September 21, 2026

Moved as part of code cleanup and documentation consolidation. See README.md files in:
- `QAQC/README.md` — QAQC pipeline functions
- `assumption_checking/README.md` — Assumption checking pipeline functions
