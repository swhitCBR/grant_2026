
# run all the models in ATLAS and then copy and paste full html window output into corresponding.md
source("R/make_dirs_mds_for_pasting.R")
source("R/check_md_rows.R")
source("R/summarize_blank_mds.R")
source("R/check_md_dates.R")

# make_dirs_mds_for_pasting(
#   base_path = "assumption_checking",
#   outer_folder = "all_sites_run",
#   level1_dirs = c("POOLED", "TAGGER A", "TAGGER B", "TAGGER C"),
#   level2_dirs = c("PR_CHN", "PR_STH", "RI_CHN", "RI_STH"),
#   level3_dirs = NULL,
#   md_files = c("Capture History Report .md", "CJS_report.md"),
#   additional_mds = list(RI_CHN = c("Cumul_surv.md"), RI_STH = c("Cumul_surv.md")))

# Run check_md_rows on round_3/tagger_effects folder
check_md_rows("assumption_checking/all_sites_run")
# Summarize blank files by group
summarize_blank_mds("assumption_checking/all_sites_run")
# Check markdown files with last modified dates
check_md_dates("assumption_checking/all_sites_run")


# make_dirs_mds_for_pasting(
#   base_path = "assumption_checking",
#   outer_folder = "BRZsel_run",
#   level1_dirs = c("POOLED", "TAGGER A", "TAGGER B", "TAGGER C"),
#   level2_dirs = c("PR_CHN", "PR_STH", "RI_CHN", "RI_STH"),
#   level3_dirs = NULL,
#   md_files = c("Capture History Report .md", "CJS_report.md"),
#   additional_mds = list(RI_CHN = c("Cumul_surv.md"), RI_STH = c("Cumul_surv.md")))


check_md_rows("assumption_checking/all_sites_run")
check_md_rows("assumption_checking/BRZsel_run")

# =========================================================================================
# SCRAPE ATLAS RESULTS FROM BRZsel_run and all_sites run (MOD version omits extra sites)
# =========================================================================================

# Load scraping function
source("R/scrape_atlas_results.R")

# Execute scraping on BRZsel_run directory
message("Scraping ATLAS results from assumption_checking/BRZsel_run...")
atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")

# Results are now available in the environment:
# - atlas_results$capture_history: List of capture history tables
# - atlas_results$cjs_survival: Data frame with survival estimates
# - atlas_results$cjs_capture: Data frame with capture estimates
# - atlas_results$metadata: Processing metadata

head(atlas_results$cjs_survival)
atlas_results$cjs_4survival_long |> filter(location=="RI")

all_sites_atlas_results <- scrape_atlas_results("assumption_checking/all_sites_run")

# Priest Rapids sites are the same
all_sites_atlas_results$cjs_survival_long |> filter(location=="PR")
atlas_results$cjs_survival_long |> filter(location=="PR")



atlas_results$cjs_survival_long |> filter(location=="RI")
all_sites_atlas_results$cjs_survival_long |> filter(location=="RI")
