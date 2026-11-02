# data_cleaning

Scripts run in order from the repo root (`c:/repos/grant_2026`). Outputs go to `data/clean/`.

| Script | What it does | Output |
|---|---|---|
| `01_load_csvs.R` | Reads all CSVs in `data/Round 2` into a named list | `csv_fl_ls.rds` |
| `02_create_tag_subsets.R` | Adds species, release date and replicate ID fields; builds tag subsets by fish status / survival use | `tag_subsets_ls.rds` |
| `03_create_DH_from_tag_subsets.R` | Builds detection-history summaries per tag subset, with abbreviated site names | `tag_DH_ls.rds` |
| `04_create_DH_for_spec_repIDs_and_survuse_subset.R` | Pools replicate IDs, joins them to the pooled ATLAS file, and tabulates detection histories (DHcode) by replicate | `media/xlsx/replicate_regrouping/replicate_level_DH_counts_single_sheet.xlsx` |

## Script 04 details
- Uses the `tags_SURVUSE_OR_EUTH_&_ACTIVE` subset and the pooling table in `media/xlsx/replicate_regrouping/`.
- Pooled replicates: CHN 14,15; STH 9,10 / 20,21,22 / 23,24.
- Reads `COMB_REL_lrg_hanf_pooled_ATLAS.csv` (no header, columns named manually) and joins `new_repID` by `tag_code`.
- Workbook sheets: `DH_counts_long` (totals and replicate-level tables, CHN left / STH right) and `DH_counts wide`.
- `old/` holds superseded scripts.
