# Parse the ATLAS report files (HTML saved as .rtf) for Chinook: replicate folders in
# analysis/replicate_level/CHN and the pooled report in analysis/pooled/CHN_report.
# Run from the repo root. Output: analysis/CHN_ATLAS_out.rds
# (list of CHN_DH_tab, CHN_Cjs_tab, CHN_Pair_CJS_tab). Logic lives in R/extract_atlas_rtf_tables.R

source("R/extract_atlas_rtf_tables.R")

CHN_ATLAS_out <- extract_atlas_rtf_tables("CHN")

CHN_DH_tab <- CHN_ATLAS_out$CHN_DH_tab
CHN_Cjs_tab <- CHN_ATLAS_out$CHN_Cjs_tab
CHN_Pair_CJS_tab <- CHN_ATLAS_out$CHN_Pair_CJS_tab
