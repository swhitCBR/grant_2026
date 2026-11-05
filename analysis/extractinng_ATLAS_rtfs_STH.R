# Parse the ATLAS report files (HTML saved as .rtf) for steelhead: replicate folders in
# analysis/replicate_level/STH and the pooled report in analysis/pooled/STH_report.
# Run from the repo root. Output: analysis/STH_ATLAS_out.rds
# (list of STH_DH_tab, STH_Cjs_tab, STH_Pair_CJS_tab). Logic lives in R/extract_atlas_rtf_tables.R

source("R/extract_atlas_rtf_tables.R")

STH_ATLAS_out <- extract_atlas_rtf_tables("STH")

STH_DH_tab <- STH_ATLAS_out$STH_DH_tab
STH_Cjs_tab <- STH_ATLAS_out$STH_Cjs_tab
STH_Pair_CJS_tab <- STH_ATLAS_out$STH_Pair_CJS_tab
