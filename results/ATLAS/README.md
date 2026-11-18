# results/ATLAS/

Saved ATLAS reports (HTML saved as `.rtf`) that `analysis/01_extracting_ATLAS_rtfs_COMB.R` reads.

| Folder | Contents |
|---|---|
| `replicate_level/{CHN,STH}/` | One folder per replicate (paired-release runs). |
| `pooled/{CHN,STH}_report/` | Pooled paired-release reports. |
| `Single Release Pooled TL/{CHN,STH}/{RI,PR}/` | TLSR reports (tag-life adjusted single release). See below. |
| `RI_CHN_censor_fix_11_17/` | Dated copy of the current reports from the November 17 Chinook Rock Island rerun (the folder the ATLAS output was first saved to). |

## TLSR and the November 17 Chinook rerun

TLSR means Tag-Life adjusted Single Release: single-release ATLAS models fit post hoc on the pooled data with the tag-life correction. "RAB" had me recompute the TLSR **Chinook salmon** estimates because the product of the reach probabilities did not match the total survival estimates. Only Chinook (Rock Island release) was rerun; steelhead and the Priest Rapids releases are unchanged.

The rerun used TagPro input files with the censoring of one tag undone. Two censored tags (`G72790346` and `G72B4A509`) were considered, and RAB decided not to undo the censoring on one of them: it was undone for `G72790346` (2 Wanapum BRZ events removed) and kept for `G72B4A509` (considered, not undone). The details, the input files and the full list of changes are in `data/reach_spec_censor_fix/README.md`. Step-by-step instructions with screenshots for the TagPro and ATLAS steps are in `rixTagPro_and_ATLAS_PROTOCOL.md` at the repo root.

I mistakenly omitted rows for the wrong tag in an earlier rerun the same day (`G72B4A509` instead of `G72790346`). Its reports are set aside, not deleted, in `Single Release Pooled TL/CHN/RI/wrong_tag_hist_edit/`; the original reports from November 9 are in `Single Release Pooled TL/CHN/RI/old/`. A before-and-after table of the estimates for all three sets is in `Single Release Pooled TL/CHN/RI/README.md`.

## Extracted tables

The tables extracted from these reports (`results/*.rds`), the workbook `media/xlsx/COMB_pool_pair_est_output.xlsx` and the cumulative survival figures were rerun on November 17 from the current reports. After any new ATLAS run, rerun the `analysis/` scripts in order (see `analysis/README.md`).
