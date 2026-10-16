# `tag_DH_ls.rds` is stale relative to the current tag subsets

**Status:** unresolved as of 2026-09-29. Regeneration was attempted but the
edit to `data_cleaning/03_create_DH_from_tag_subsets.R` was declined before
rerunning, so `data/clean/tag_DH_ls.rds` on disk is still the stale version
described below.

## Where this came up

`taglife/eval_survival_data_to_inform_taglife.R` loads `tag_DH_ls.rds` and
pulls out `DH_SU_E_ACT_RI <- tag_DH_ls[["SU_E_ACT_RI_summ"]]` and
`DH_SU_E_ACT_PR <- tag_DH_ls[["SU_E_ACT_PR_summ"]]` — the detection-history
tables (detections per node, by spp/release location/repID/fish status) for
the `tags_SURVUSE_OR_EUTH_&_ACTIVE` tag subset, which is the same population
as `tags_dat_SURVUSE_OR_EUTH_ACTIVE` (3,360 tags). These tables were being
treated as ground truth for the taglife analysis before checking freshness.

## Evidence that it's stale

| Check | Result |
|---|---|
| File mtimes | `data/clean/tag_DH_ls.rds` written 2026-09-18 17:36; `data/clean/tag_subsets_ls.rds` written **later**, 2026-09-20 15:26 |
| Recompute vs. stored | Rebuilding `SU_E_ACT_RI_summ`/`SU_E_ACT_PR_summ` from the *current* `tag_subsets_ls[["tags_SURVUSE_OR_EUTH_&_ACTIVE"]]` (3,360 tags, matches live `tags_dat_SURVUSE_OR_EUTH_ACTIVE`) yields **129** spp/rel_loc/repID/status groups vs. **128** stored (45 RI + 83 PR) |
| The extra group | An all-`NA` (spp/rel_loc/repID/status) bucket capturing **115** detected `tag_code`s from `events_dat` that no longer fall inside the current `tags_SURVUSE_OR_EUTH_&_ACTIVE` subset, with substantial detection counts (112 at Crescent Bar, 111 at Sunland, 98 at Wanapum.BRZ, etc.) |
| Stored version | Has **no** NA bucket — every detected tag matched the subset definition in place on 9/18 |

Conclusion: between 9/18 and 9/20 the `tags_SURVUSE_OR_EUTH_&_ACTIVE` subset
definition (or the underlying tag metadata feeding it) changed enough that
~115 tags which are now detected-but-excluded were not excluded (or did not
exist as excluded) when `tag_DH_ls.rds` was last built. The node-count tables
currently read by `eval_survival_data_to_inform_taglife.R` reflect that
**older** population, not the current 3,360-tag
`tags_dat_SURVUSE_OR_EUTH_ACTIVE`.

## Complication when trying to regenerate

`data_cleaning/03_create_DH_from_tag_subsets.R` sources
`get_DH_tag_code_summ()` from `R/get_DH_tag_code_summ.R`, but that function
has since been moved to `old/obsolete_funs/get_DH_tag_code_summ.R`. The
script will fail with `ENOENT` if rerun as-is; the `source()` path needs to
be updated to point at the new location before rerunning.

## Suggested next steps

1. Edit `data_cleaning/03_create_DH_from_tag_subsets.R`:
   `source("R/get_DH_tag_code_summ.R")` -> `source("old/obsolete_funs/get_DH_tag_code_summ.R")`.
2. Rerun the script to regenerate and overwrite `data/clean/tag_DH_ls.rds`
   from the current `tag_subsets_ls.rds`.
3. Re-pull `DH_SU_E_ACT_RI`/`DH_SU_E_ACT_PR` in
   `taglife/eval_survival_data_to_inform_taglife.R` and confirm the NA/mismatch
   bucket disappears (i.e., recompute-vs-stored check above returns 0 rows
   different).
4. Separately worth investigating: *why* 115 tags dropped out of
   `tags_SURVUSE_OR_EUTH_&_ACTIVE` between 9/18 and 9/20 — this could reflect
   an intentional subset refinement, or a bug introduced in
   `data_cleaning/02_create_tag_subsets.R` (or upstream tag metadata) in that
   window. Worth checking before trusting the regenerated table for the
   taglife analysis.
