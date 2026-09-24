# setwd("c:/repos/grant_2026")

# run all the models in ATLAS and then copy and paste full html window output into corresponding.md
source("R/make_dirs_mds_for_pasting.R")
source("R/check_md_rows.R")
source("R/summarize_blank_mds.R")
source("R/check_md_dates.R")

make_dirs_mds_for_pasting(
  base_path = "assumption_checking",
  outer_folder = "all_sites_run",
  level1_dirs = c("POOLED", "TAGGER A", "TAGGER B", "TAGGER C"),
  level2_dirs = c("PR_CHN", "PR_STH", "RI_CHN", "RI_STH"),
  level3_dirs = NULL,
  md_files = c("Capture History Report .md", "CJS_report.md"),
  additional_mds = list(RI_CHN = c("Cumul_surv.md"), RI_STH = c("Cumul_surv.md")))

# Run check_md_rows on round_3/tagger_effects folder
check_md_rows("assumption_checking/all_sites_run")
# Summarize blank files by group
summarize_blank_mds("assumption_checking/all_sites_run")
# Check markdown files with last modified dates
check_md_dates("assumption_checking/all_sites_run")


make_dirs_mds_for_pasting(
  base_path = "assumption_checking",
  outer_folder = "BRZsel_run",
  level1_dirs = c("POOLED", "TAGGER A", "TAGGER B", "TAGGER C"),
  level2_dirs = c("PR_CHN", "PR_STH", "RI_CHN", "RI_STH"),
  level3_dirs = NULL,
  md_files = c("Capture History Report .md", "CJS_report.md"),
  additional_mds = list(RI_CHN = c("Cumul_surv.md"), RI_STH = c("Cumul_surv.md")))


check_md_rows("assumption_checking/all_sites_run")
check_md_rows("assumption_checking/BRZsel_run")



# Run check_md_rows on round_3/tagger_effects folder
check_md_rows("assumption_checking/round_3/tagger_effects")
# Summarize blank files by group
summarize_blank_mds("assumption_checking/round_3/tagger_effects")

# Check markdown files with last modified dates
check_md_dates("assumption_checking/round_3/tagger_effects")


# # Create a reproduction of the round_3 directory structure in assumption_checking
# make_dirs_mds_for_pasting(
#   base_path = "assumption_checking",
#   outer_folder = "test_dir",
#   level1_dirs = c("POOLED", "TAGGER A", "TAGGER B", "TAGGER C"),
#   level2_dirs = c("PR_CHN", "PR_STH", "RI_CHN", "RI_STH"),
#   level3_dirs = NULL,
#   md_files = c("Capture History Report .md", "CJS_report.md"),
#   additional_mds = list(RI_CHN = c("Cumul_surv.md"), RI_STH = c("Cumul_surv.md"))
# )
# check_md_rows("assumption_checking/test_dir")
