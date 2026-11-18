# results/ATLAS/

Saved ATLAS reports (HTML saved as `.rtf`) that `analysis/01_extracting_ATLAS_rtfs_COMB.R` reads.

| Folder | Contents |
|---|---|
| `replicate_level/{CHN,STH}/` | One folder per replicate (paired-release runs). |
| `pooled/{CHN,STH}_report/` | Pooled paired-release reports. |
| `Single Release Pooled TL/{CHN,STH}/{RI,PR}/` | TLSR reports (tag-life adjusted single release). See below. |
| `RI_CHN_censor_fix_11_17/` | Copy of the reports from the November 17 Chinook Rock Island rerun. |

## TLSR and the November 17 Chinook rerun

TLSR means Tag-Life adjusted Single Release: single-release ATLAS models fit post hoc on the pooled data with the tag-life correction. "RAB" had me recompute the TLSR **Chinook salmon** estimates because the product of the reach probabilities did not match the total survival estimates. Only Chinook (Rock Island release) was rerun; steelhead and the Priest Rapids releases are unchanged.

The rerun used TagPro input files with the censoring of one tag undone: two censored tags (`G72790346` and `G72B4A509`) were considered, and RAB decided not to undo the censoring on one of them. The details, the input files and the full list of changes are in `data/reach_spec_censor_fix/README.md`. Step-by-step instructions with screenshots for the TagPro and ATLAS steps are in `fixing_censoring_TagPro_and_ATLAS_PROTOCOL.md` at the repo root.

## Not yet refreshed

The extracted tables in `results/` (for example `CHN_ATLAS_TLSR_out.rds`) were written on November 10, before the rerun, so they still hold the old Chinook values. Rerun `analysis/01_extracting_ATLAS_rtfs_COMB.R` to update them from the new reports, then the later scripts that depend on them.
