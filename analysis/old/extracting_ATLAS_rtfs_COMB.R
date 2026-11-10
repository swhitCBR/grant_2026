# Parse the ATLAS report files (HTML saved as .rtf) for Chinook: replicate folders in
# analysis/replicate_level/CHN and the pooled report in analysis/pooled/CHN_report.
# Run from the repo root. Output: analysis/CHN_ATLAS_out.rds
# (list of CHN_DH_tab, CHN_Cjs_tab, CHN_Pair_CJS_tab). Logic lives in R/extract_atlas_rtf_tables.R

source("R/extract_atlas_rtf_tables.R")

CHN_ATLAS_out <- extract_atlas_rtf_tables("CHN")

CHN_DH_tab <- CHN_ATLAS_out$CHN_DH_tab
CHN_Cjs_tab <- CHN_ATLAS_out$CHN_Cjs_tab
CHN_Pair_CJS_tab <- CHN_ATLAS_out$CHN_Pair_CJS_tab


# Tag-life adjusted survival estimates and SEs from the single-release pooled ATLAS reports
# (*_Modeled.rtf and *_ModeledCum.rtf in analysis/pooled/Single Release Pooled TL/CHN/{RI,PR}).
# Output: analysis/CHN_ATLAS_TLSR_out.rds (list of CHN_TL_Modeled_tab, CHN_TL_ModeledCum_tab).
# Logic lives in R/extract_atlas_modeled_tl_tables.R
source("R/extract_atlas_modeled_tl_tables.R")

CHN_ATLAS_TL_out <- extract_atlas_modeled_tl_tables("CHN")

CHN_TL_Modeled_tab <- CHN_ATLAS_TL_out$CHN_TL_Modeled_tab
CHN_TL_ModeledCum_tab <- CHN_ATLAS_TL_out$CHN_TL_ModeledCum_tab

# Parse the ATLAS report files (HTML saved as .rtf) for steelhead: replicate folders in
# analysis/replicate_level/STH and the pooled report in analysis/pooled/STH_report.
# Run from the repo root. Output: analysis/STH_ATLAS_out.rds
# (list of STH_DH_tab, STH_Cjs_tab, STH_Pair_CJS_tab). Logic lives in R/extract_atlas_rtf_tables.R

STH_ATLAS_out <- extract_atlas_rtf_tables("STH")

STH_DH_tab <- STH_ATLAS_out$STH_DH_tab
STH_Cjs_tab <- STH_ATLAS_out$STH_Cjs_tab
STH_Pair_CJS_tab <- STH_ATLAS_out$STH_Pair_CJS_tab


# Tag-life adjusted survival estimates and SEs from the single-release pooled ATLAS reports
# (*_Modeled.rtf and *_ModeledCum.rtf in analysis/pooled/Single Release Pooled TL/STH/{RI,PR}).
# Output: analysis/STH_ATLAS_TLSR_out.rds (list of STH_TL_Modeled_tab, STH_TL_ModeledCum_tab).
# Logic lives in R/extract_atlas_modeled_tl_tables.R

STH_ATLAS_TL_out <- extract_atlas_modeled_tl_tables("STH")

STH_TL_Modeled_tab <- STH_ATLAS_TL_out$STH_TL_Modeled_tab
STH_TL_ModeledCum_tab <- STH_ATLAS_TL_out$STH_TL_ModeledCum_tab
