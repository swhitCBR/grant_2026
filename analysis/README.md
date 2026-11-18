# analysis/

Survival analysis that follows data cleaning, QAQC and the assumption checks: mixing plots, tag-life analysis, and compilation of ATLAS (CJS) results. Run scripts from the repo root (open `grant_2026.Rproj`).

## Order to run the scripts

After the ATLAS runs are done and their reports are saved in `results/ATLAS/` (see the protocols below), run the R scripts in this order:

1. **`01_extracting_ATLAS_rtfs_COMB.R`**: parses the saved ATLAS reports for both species (paired-release/CJS tables and the TLSR tables) and writes `results/{CHN,STH}_ATLAS_out.rds` and `results/{CHN,STH}_ATLAS_TLSR_out.rds`. Run this first.
2. **`02_replicate_level_wtavg_F_test_comp.R`**: reads the extracted estimates, runs the replicate-level weighted averages and F tests, and writes the workbook `media/xlsx/COMB_pool_pair_est_output.xlsx`.
3. **`03_data_prep_for_plotting.R`**: joins release dates onto the estimates for plotting (reads `results/rep_level_ests_Ftests_tb_ls.rds`).
4. **`plotting_*.R`**: figures (`plotting_replicate_level_vs. pooled_COMB..R`, `plotting_pooled_cumul_surv.R`).

`extracting_ATLAS_rtfs_STH.R` is an older steelhead-only version of step 1 (it still writes to `analysis/`); use `01_...COMB.R`.

## Censoring check and rerun (November 17, 2026)

**`RI_reach_spec_data_comp.R`** is the script for the censoring fix. "RAB" had me recompute the tag-life adjusted single release (TLSR) **Chinook salmon** estimates because the product of the reach probabilities did not match the total survival estimates. The script looks at two censored tags, `G72790346` and `G72B4A509`, and:

1. writes `media/xlsx/censored_tags_detections.xlsx` (one sheet per tag: ATLAS record on top, pre-ATLAS events below, long-interval rows highlighted; `G72790346` in pink with a note);
2. moves `nodes.csv` and `tags.csv` to `data/reach_spec_censor_fix/`;
3. drops the flagged `G72B4A509` events and writes the revised `events.csv` there.

I considered undoing the censoring for both tags, and RAB decided not to undo it for one of them (`G72790346`; its rows are kept). Details are in `data/reach_spec_censor_fix/README.md`. **`fixing_censoring_TagPro_and_ATLAS_PROTOCOL.md` (repo root) has the instructions and screenshots** for the TagPro and ATLAS steps that produce the rerun reports in `results/ATLAS/Single Release Pooled TL/CHN/RI/` (the original reports are in its `old/` folder).

The extracted tables in `results/` were written before the rerun and still hold the old Chinook TLSR values, so rerun step 1 to refresh them.

## ATLAS protocols (`*_PROTOCOL.md`)

The files with `_PROTOCOL.md` in their names are walkthroughs of the repeatable analysis steps in ATLAS. Each lists, in order, which files to load and which settings to choose, so a run can be repeated and the reports regenerated. Follow them before running step 1.

- `Grant_ATLAS_analysis_PROTOCOL.md` and `ATLAS_calc_CHN_9 & STH_4_PROTOCOL.md`: paired-release pooled and replicate-level runs.
- `ATLAS_calc_pooled_TL_corr_reach_ests_PROTOCOL.md`: the TLSR runs (see below).
- `../fixing_censoring_TagPro_and_ATLAS_PROTOCOL.md`: the TagPro and ATLAS steps for the censoring fix, with screenshots.
- `mixing plots/Creation of mixing plots_PROTOCOL.md`: the mixing-plot steps.

## Contents

| Path | What it is |
|---|---|
| `01_`, `02_`, `03_` scripts and `plotting_*.R` | The analysis scripts, in run order (above). |
| `RI_reach_spec_data_comp.R` | Censoring check and revised TagPro inputs (above). |
| `pooled/`, `replicate_level/` | Earlier copies of the saved ATLAS reports; the current ones are in `results/ATLAS/`. |
| `mixing plots/`, `taglife/` | Mixing plots of live and dead fish; tag-life (Weibull / vitality) analysis. |
| `*_PROTOCOL.md` | ATLAS walkthroughs (above). |

## TLSR: Tag-Life adjusted Single Release models

"TLSR" stands for **T**ag-**L**ife adjusted **S**ingle **R**elease. These are single-release ATLAS survival models that are fit post hoc, using the pooled data (all replicates combined, not tagger-specific), with the tag-life correction applied. They are separate from the paired-release models behind `*_ATLAS_out.rds`.

**How the models are fit** (manual, in ATLAS; see `ATLAS_calc_pooled_TL_corr_reach_ests_PROTOCOL.md`):

- One model per species and release site (Rock Island `RI`, Priest Rapids `PR`), using `data/clean/post_tagpro/{RI,PR}_BRZsel_ATLAS.csv`. Do not use the `all_sites` file.
- Release type "Single Release".
- Tag-life data from `data/Nov_run/Pooled_taglife.csv`, Weibull 2-parameter fit, tag-life corrections and full variance with 10,000 bootstrap iterations.
- Some parameters are constrained (for example, capture probabilities fixed at 1.0 at some sites).
- Reports are saved to `results/ATLAS/Single Release Pooled TL/{CHN,STH}/{RI,PR}/`.
- **Chinook, Rock Island release:** recomputed on November 17, 2026 (see above), using `data/clean/post_tagpro/RI_rerun_after_G72790346_fix_ATLAS.csv`.

**What is extracted** (by `R/extract_atlas_modeled_tl_tables.R`):

| Report | Contents | `param` in output |
|---|---|---|
| `*_Modeled.rtf` | Reach-level survival; capture detail (the last capture reach is the combined Hanford Survival*Capture) | `surv_p`, `capture_p` |
| `*_ModeledCum.rtf` | Cumulative survival from release to each detection site | `cum_surv_p` |

The other reports in those folders (`CaptHist`, `Cjs`, `CjsCum`, `TagLife`) are not read. The function expects one `*_Modeled.rtf` and one `*_ModeledCum.rtf` per folder, so older sets are kept in an `old/` subfolder.

**Outputs**: `results/{CHN,STH}_ATLAS_TLSR_out.rds`, each a list of `<spp>_TL_Modeled_tab` and `<spp>_TL_ModeledCum_tab`. Columns: `rel_loc`, `spp_rel_loc`, `param`, `reach`, `est`, `SE` and `se_method` (survival SEs are bootstrapped; capture SEs are from the inverse Hessian). Objects with the same names are created when the extraction script is sourced.

```r
source("analysis/01_extracting_ATLAS_rtfs_COMB.R")    # also creates CHN_TL_Modeled_tab, CHN_TL_ModeledCum_tab
tlsr <- readRDS("results/CHN_ATLAS_TLSR_out.rds")
```
