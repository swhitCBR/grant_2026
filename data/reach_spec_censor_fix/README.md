# data/reach_spec_censor_fix/

TagPro input files for the Rock Island Chinook rerun after the censoring check (November 2026). Instructions and screenshots for the TagPro and ATLAS steps are in [`rixTagPro_and_ATLAS_PROTOCOL.md`](../../rixTagPro_and_ATLAS_PROTOCOL.md) at the repo root. The screenshots are in `media/png/censoring_fix_for_CHN_RI_single_release/`; `media/` is git-ignored, so they are on the local machine but not in the repository.

## Why this folder exists

"RAB" had me recompute the tag-life adjusted single release (TLSR) Chinook salmon estimates because the product of the reach probabilities did not match the total survival estimates. While preparing the rerun, two tags that TagPro had censored were examined: `G72790346` and `G72B4A509` (see `assumption_checking/old/sidequest_tagpro_censoring_issue.R`). Both have very long detection intervals at a single site, which is what the censoring responded to.

I considered undoing the censoring for both tags by removing those events. RAB decided not to undo it for one of them, so:

| Tag | Site | Flagged events | Decision |
|---|---|---|---|
| `G72790346` | Wanapum BRZ | 2 rows with intervals of about 1.37 million seconds (1,366,803 and 1,365,236) removed | Censoring undone (yellow in the workbook) |
| `G72B4A509` | Sunland | 3 rows with intervals of 2,456,229, 2,354,768 and 20,094 seconds kept | Considered, not undone (pink in the workbook, with a note) |

The workbook `media/xlsx/censored_tags_detections.xlsx` shows both tags (ATLAS record on top, pre-ATLAS events below, flagged rows highlighted).

The ATLAS input confirms the difference: in the current input, `G72790346` is detected down to Hanford, while `G72B4A509` is still not detected beyond Wanapum BRZ.

**I mistakenly omitted the rows for the wrong tag in the first version of the rerun:** events were removed for `G72B4A509` instead of `G72790346`. The input and reports from that version were set aside, not deleted, so they can't be mistaken for the current ones: the ATLAS input is in `ATLAS_input_file/old/`, and the reports are in `results/ATLAS/Single Release Pooled TL/CHN/RI/wrong_tag_hist_edit/` (see below).

## Files

| File | What it is |
|---|---|
| `events.csv` | Revised events: the original `data/clean/pre_tagpro/events.csv` minus the 2 flagged `G72790346` Wanapum BRZ rows (72,278 rows). Same columns and text format as the original. |
| `nodes.csv`, `tags.csv` | Moved here (not copied) from `data/clean/pre_tagpro/`. Unchanged. |
| `ATLAS_input_file/RI_rerun_after_G72790346_fix_ATLAS.csv` | The current ATLAS input, produced from these files by TagPro (Rock Island Chinook only). |
| `ATLAS_input_file/old/wrong_RI_rerun_after_G72790346_fix_ATLAS.csv` | The input from the earlier, wrong-tag version. It is identical to the copy in `data/clean/post_tagpro/`, which is therefore also out of date. |

`data/clean/pre_tagpro/` now holds only the original `events.csv`. TagPro needs all three files together, so load them from this folder.

## How it was made

`analysis/RI_reach_spec_data_comp.R` builds all of it (sections 4 to 7): it writes the workbook, moves `nodes.csv` and `tags.csv`, drops the flagged `G72790346` events and writes `events.csv`. It is safe to rerun. Rerunning it does not redo TagPro or ATLAS: after a change to `events.csv`, rerun those by hand and then the `analysis/` pipeline.
