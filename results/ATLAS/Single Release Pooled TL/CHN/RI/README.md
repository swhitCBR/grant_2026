# Chinook, Rock Island release: TLSR reports

Tag-life adjusted single release (TLSR) ATLAS reports for the Rock Island Chinook release. The extraction function (`R/extract_atlas_modeled_tl_tables.R`) reads the one `*_Modeled.rtf` and one `*_ModeledCum.rtf` file in this folder, so only the current set may sit here. Older sets go in `old/`.

| Location | Contents |
|---|---|
| this folder | `RI_rerun_after_G72790346_fix_ATLAS_*.rtf` (CaptHist, Cjs, CjsCum, Modeled, ModeledCum, TagLife): the rerun of November 17, 2026. These are the current reports. |
| `old/` | `RI_BRZsel_ATLAS_*.rtf`: the original reports (November 9, 2026), kept for comparison. |

## Why it was rerun

"RAB" had me recompute the TLSR Chinook salmon estimates because the product of the reach probabilities did not match the total survival estimates. The rerun used TagPro input files in which the censoring of one of two flagged tags was undone (details in `data/reach_spec_censor_fix/README.md`). Instructions and screenshots: `fixing_censoring_TagPro_and_ATLAS_PROTOCOL.md` at the repo root.

## Cumulative survival from the Rock Island release, before and after

| Site | Original (`old/`) | Rerun |
|---|---|---|
| Crescent Bar | 0.9916 | 0.9916 |
| Sunland | 0.9780 | 0.9780 |
| Wanapum BRZ | 0.9173 | 0.9173 |
| Mattawa | 0.8269 | 0.8259 |
| Priest BRZ | 0.7986 | 0.7977 |
| Lower Ringold | 0.7259 | 0.7251 |

Values are from the `*_ModeledCum.rtf` reports. The reach estimates also changed slightly (Mattawa 0.9014 to 0.9004; Sunland 0.9862 to 0.9863; Wanapum BRZ 0.9380 to 0.9379).
