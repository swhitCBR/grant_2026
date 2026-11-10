# analysis/

Survival analysis that follows data cleaning, QAQC and the assumption checks: mixing plots, tag-life analysis, and compilation of ATLAS (CJS) results. Run scripts from the repo root (open `grant_2026.Rproj`).

## Order to run the scripts

After the ATLAS runs are done and their reports are saved (see the protocols below), run the R scripts in this order:

1. **`extract*`**: `extractinng_ATLAS_rtfs_CHN.R` and `extractinng_ATLAS_rtfs_STH.R`. They parse the saved ATLAS reports and write the `.rds` files the later scripts read. Run these first.
2. **`replicate*`**: `replicate_level_wtavg_F_test_comp.R`. It reads the extracted estimates and writes `rep_level_ests_Ftests_tb_ls.rds`.
3. **`plotting*`**: `plotting_replicate_level_vs. pooled..R` and `plotting_replicate_level_vs. pooled_COMB..R`. The `_COMB` script reads `rep_level_ests_Ftests_tb_ls.rds`, so it needs step 2 to have been run.

The `replicate*` and `plotting*` scripts also source the `extract*` scripts themselves, but running the `extract*` scripts first is the intended order.

## ATLAS protocols (`*_PROTOCOL.md`)

The files with `_PROTOCOL.md` in their names are walkthroughs of the repeatable analysis steps in ATLAS. Each lists, in order, which files to load and which settings to choose, so a run can be repeated and the reports regenerated. Follow them before running the `extract*` scripts.

- `Grant_ATLAS_analysis_PROTOCOL.md` and `ATLAS_calc_CHN_9 & STH_4_PROTOCOL.md`: paired-release pooled and replicate-level runs.
- `ATLAS_calc_pooled_TL_corr_reach_ests_PROTOCOL.md`: the TLSR runs (see below).
- `mixing plots/Creation of mixing plots_PROTOCOL.md`: the mixing-plot steps.

## Contents

| Path | What it is |
|---|---|
| `extractinng_ATLAS_rtfs_{CHN,STH}.R` | Parse the saved ATLAS reports (HTML saved as `.rtf`) for one species. Writes `{CHN,STH}_ATLAS_out.rds` (paired-release and CJS estimates) and `{CHN,STH}_ATLAS_TLSR_out.rds` (TLSR, see below). |
| `pooled/`, `replicate_level/` | Saved ATLAS reports: pooled, and one folder per replicate. |
| `pooled/Single Release Pooled TL/{CHN,STH}/{RI,PR}/` | TLSR reports (see below). |
| `replicate_level_wtavg_F_test_comp.R`, `plotting_replicate_level_vs. pooled..R`, `plotting_replicate_level_vs. pooled_COMB..R` | Compare replicate-level and pooled paired-release estimates (F tests, plots). The `_COMB` script reads `rep_level_ests_Ftests_tb_ls.rds`. |
| `mixing plots/`, `taglife/` | Mixing plots of live and dead fish; tag-life (Weibull / vitality) analysis. |
| `Grant_ATLAS_analysis_PROTOCOL.md`, `ATLAS_calc_CHN_9 & STH_4_PROTOCOL.md` | ATLAS walkthroughs for the paired-release pooled and replicate-level runs. |
| `ATLAS_calc_pooled_TL_corr_reach_ests_PROTOCOL.md` | ATLAS walkthrough for the TLSR runs. |

## TLSR: Tag-Life adjusted Single Release models

"TLSR" stands for **T**ag-**L**ife adjusted **S**ingle **R**elease. These are single-release ATLAS survival models that are fit post hoc, using the pooled data (all replicates combined, not tagger-specific), with the tag-life correction applied. They are separate from the paired-release models behind `*_ATLAS_out.rds`.

**How the models are fit** (manual, in ATLAS; see `ATLAS_calc_pooled_TL_corr_reach_ests_PROTOCOL.md`):

- One model per species and release site (Rock Island `RI`, Priest Rapids `PR`), using `data/clean/post_tagpro/{RI,PR}_BRZsel_ATLAS.csv`. Do not use the `all_sites` file.
- Release type "Single Release".
- Tag-life data from `data/Nov_run/Pooled_taglife.csv`, Weibull 2-parameter fit, tag-life corrections and full variance with 10,000 bootstrap iterations.
- Some parameters are constrained (for example, capture probabilities fixed at 1.0 at some sites).
- Reports are saved to `pooled/Single Release Pooled TL/{CHN,STH}/{RI,PR}/`.

**What is extracted** (by `R/extract_atlas_modeled_tl_tables.R`):

| Report | Contents | `param` in output |
|---|---|---|
| `*_Modeled.rtf` | Reach-level survival; capture detail (the last capture reach is the combined Hanford Survival*Capture) | `surv_p`, `capture_p` |
| `*_ModeledCum.rtf` | Cumulative survival from release to each detection site | `cum_surv_p` |

The other reports in those folders (`CaptHist`, `Cjs`, `CjsCum`, `TagLife`) are not read.

**Outputs**: `{CHN,STH}_ATLAS_TLSR_out.rds`, each a list of `<spp>_TL_Modeled_tab` and `<spp>_TL_ModeledCum_tab`. Columns: `rel_loc`, `spp_rel_loc`, `param`, `reach`, `est`, `SE` and `se_method` (survival SEs are bootstrapped; capture SEs are from the inverse Hessian). Objects with the same names are created when the extraction scripts are sourced.

```r
source("analysis/extractinng_ATLAS_rtfs_CHN.R")    # also creates CHN_TL_Modeled_tab, CHN_TL_ModeledCum_tab
tlsr <- readRDS("analysis/CHN_ATLAS_TLSR_out.rds")
```
