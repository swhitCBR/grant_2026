# Chinook, Rock Island release: TLSR reports

Tag-life adjusted single release (TLSR) ATLAS reports for the Rock Island Chinook release. The extraction function (`R/extract_atlas_modeled_tl_tables.R`) reads the one `*_Modeled.rtf` and one `*_ModeledCum.rtf` file in this folder, so only the current set may sit here. Older sets go in subfolders, which it does not read.

| Location | Contents |
|---|---|
| this folder | `RI_rerun_after_G72790346_fix_ATLAS_*.rtf` (CaptHist, Cjs, CjsCum, Modeled, ModeledCum, TagLife): the current reports, from the November 17, 2026 rerun with the corrected tag choice. |
| `old/` | `RI_BRZsel_ATLAS_*.rtf`: the original reports (November 9, 2026), kept for comparison. |
| `wrong_tag_hist_edit/` | `RI_rerun_after_G72790346_fix_ATLAS_*.rtf` from the earlier rerun on November 17 (made at 16:34). I mistakenly omitted rows for the wrong tag: events were removed for `G72B4A509` instead of `G72790346`, so these reports are not used. Set aside here for reference only (the matching ATLAS input is in `data/reach_spec_censor_fix/ATLAS_input_file/old/`). |

## Why it was rerun

"RAB" had me recompute the TLSR Chinook salmon estimates because the product of the reach probabilities did not match the total survival estimates. The rerun used TagPro input files in which the censoring of one of two flagged tags (`G72790346`) was undone; RAB decided not to undo it for the other (`G72B4A509`). Details are in `data/reach_spec_censor_fix/README.md`. Instructions and screenshots: `rixTagPro_and_ATLAS_PROTOCOL.md` at the repo root.

## Cumulative survival from the Rock Island release

| Site | Original (`old/`) | Earlier rerun, wrong tag (`wrong_tag_hist_edit/`) | Current |
|---|---|---|---|
| Crescent Bar | 0.9916 | 0.9916 | 0.9916 |
| Sunland | 0.9780 | 0.9780 | 0.9780 |
| Wanapum BRZ | 0.9173 | 0.9173 | 0.9173 |
| Mattawa | 0.8269 | 0.8259 | 0.8269 |
| Priest BRZ | 0.7986 | 0.7977 | 0.7986 |
| Lower Ringold | 0.7259 | 0.7251 | 0.7261 |

Values are from the `*_ModeledCum.rtf` reports. The standard error of the Lower Ringold cumulative estimate is 0.014467 (original), 0.014474 (earlier rerun) and 0.014514 (current).

## Reach survival

| Reach | Original (`old/`) | Earlier rerun, wrong tag | Current |
|---|---|---|---|
| Release to Crescent Bar | 0.9916 | 0.9916 | 0.9916 |
| Crescent Bar to Sunland | 0.9862 | 0.9863 | 0.9862 |
| Sunland to Wanapum BRZ | 0.9380 | 0.9379 | 0.9380 |
| Wanapum BRZ to Mattawa | 0.9014 | 0.9004 | 0.9014 |
| Mattawa to Priest BRZ | 0.9658 | 0.9658 | 0.9658 |
| Priest BRZ to Lower Ringold | 0.9091 | 0.9091 | 0.9092 |

Values are from the `*_Modeled.rtf` reports. The current estimates are within 0.0002 of the original at every site; the earlier, wrong-tag rerun was lower by about 0.001 in the cumulative estimates at Mattawa, Priest BRZ and Lower Ringold.
