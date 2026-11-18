# data/reach_spec_censor_fix/

TagPro input files for the Rock Island Chinook rerun after the censoring check (November 2026). Instructions and screenshots for the TagPro and ATLAS steps are in [`fixing_censoring_TagPro_and_ATLAS_PROTOCOL.md`](../../fixing_censoring_TagPro_and_ATLAS_PROTOCOL.md) at the repo root.

## Why this folder exists

"RAB" had me recompute the tag-life adjusted single release (TLSR) Chinook salmon estimates because the product of the reach probabilities did not match the total survival estimates. While preparing the rerun, two tags that TagPro had censored were examined: `G72790346` and `G72B4A509` (see `assumption_checking/old/sidequest_tagpro_censoring_issue.R`). Both have very long detection intervals at a single site, which is what the censoring responded to.

I considered undoing the censoring for both tags by removing those events. RAB decided not to undo it for one of them, so:

| Tag | Site | Events | Decision |
|---|---|---|---|
| `G72B4A509` | Sunland | 3 rows removed (intervals of 2,456,229, 2,354,768 and 20,094 seconds) | Censoring undone |
| `G72790346` | Wanapum BRZ | 2 rows with intervals of about 1.37 million seconds, kept | Considered, not undone (shown in pink in the workbook, with a note) |

The workbook `media/xlsx/censored_tags_detections.xlsx` shows both tags (ATLAS record on top, pre-ATLAS events below, flagged rows highlighted).

## Files

| File | What it is |
|---|---|
| `events.csv` | Revised events: the original `data/clean/pre_tagpro/events.csv` minus the 3 `G72B4A509` Sunland rows (72,277 rows). Same columns and text format as the original. |
| `nodes.csv`, `tags.csv` | Moved here (not copied) from `data/clean/pre_tagpro/`. Unchanged. |
| `ATLAS_input_file/RI_rerun_after_G72790346_fix_ATLAS.csv` | The ATLAS input produced from these files by TagPro (Rock Island Chinook only). A copy is in `data/clean/post_tagpro/`. |

`data/clean/pre_tagpro/` now holds only the original `events.csv`. TagPro needs all three files together, so load them from this folder.

## How it was made

`analysis/RI_reach_spec_data_comp.R` builds all of it (sections 4 to 7): it writes the workbook, moves `nodes.csv` and `tags.csv`, drops the flagged `G72B4A509` events and writes `events.csv`. It is safe to rerun.
