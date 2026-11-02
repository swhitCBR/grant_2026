
# run all the models in ATLAS and then copy and paste full html window output into corresponding.md
source("R/make_dirs_mds_for_pasting.R")
source("R/check_md_rows.R")
source("R/summarize_blank_mds.R")
source("R/check_md_dates.R")


# Run check_md_rows on ATLAS output directories
# NOTE: These directories are created when you run ATLAS manually.
# Only uncomment these lines after running ATLAS and populating the directories.
# 
# check_md_rows("assumption_checking/all_sites_run")
# summarize_blank_mds("assumption_checking/all_sites_run")
# check_md_dates("assumption_checking/all_sites_run")
# check_md_rows("assumption_checking/BRZsel_run")


# =========================================================================================
# LOOK UP TOTAL RELEASE COUNTS FROM PREVIOUS QAQC TABLE
# =========================================================================================

# get outputs from QAQC tables for tagger-level releases
summary_results_ls <- readRDS("data/clean/summary_results_SURVUSE_OR_EUTH_ACTIVE.rds")
# summary_results_ls$tagger_loc_status_ls$CHN_live
summary_results_ls$tagger_summ

# =========================================================================================
# SCRAPE ATLAS RESULTS FROM BRZsel_run and all_sites run (MOD version omits extra sites)
# =========================================================================================

# Load all required functions first
source("R/scrape_atlas_results.R")
source("R/create_survival_comparison_table.R")
source("R/get_tagger_comp_tables_MOD.R")
source("R/get_DH_tab_by_tagger.R")
source("R/get_DH_est_comp_xlsx.R")

source("R/compute_f_tests_by_reach.R")

# Execute scraping on BRZsel_run directory
message("Scraping ATLAS results from assumption_checking/BRZsel_run...")
# atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")

# Scrape ATLAS results (now includes cumul_cjs_survival from Cumul_surv.md files)
# NOTE: Uncomment after running ATLAS and populating the assumption_checking/BRZsel_run directory
BRZsel_atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")
comp_surv_est_tabs_wFtests <- get_tagger_comp_tables_MOD(
  atlas_results_in=BRZsel_atlas_results)

# Priest Rapids sites are the same
BRZsel_atlas_results$cjs_survival_long |> filter(location=="PR")
BRZsel_atlas_results$cjs_survival_long |> filter(location=="PR")
BRZsel_atlas_results$cjs_survival_long |> filter(location=="RI")
BRZsel_atlas_results$cjs_survival_long |> filter(location=="RI")

get_tagger_comp_tables_MOD(atlas_results_in=BRZsel_atlas_results)

# Load cumulative survival comparison function
source("R/create_cumul_survival_comparison_table.R")

# Create reach-specific survival comparison tables
create_survival_comparison_table(atlas_results =BRZsel_atlas_results,location = "RI",species = "Chinook" )

# Create cumulative survival comparison tables
CHN_R1_to_LowerRing <- create_cumul_survival_comparison_table(
  atlas_results = BRZsel_atlas_results,
  location = "RI",
  species = "Chinook"
)|> filter(reach=="Release to Lower Ringold")

STH_R1_to_LowerRing <- create_cumul_survival_comparison_table(
  atlas_results = BRZsel_atlas_results,
  location = "RI",
  species = "Steelhead"
) |> filter(reach=="Release to Lower Ringold")


# look up specific detection histories across taggers
get_DH_tab_by_tagger(atlas_results_in=BRZsel_atlas_results,spp = "CHN",release = "RI")

if(!dir.exists("media/xlsx/assumption_checking")){
  dir.create("media/xlsx/assumption_checking",recursive = T)
}


get_DH_est_comp_xlsx(atlas_results_in=BRZsel_atlas_results,
  out_xlsx="media/xlsx/assumption_checking/BRZsel_atlas_results.xlsx")


all_sites_atlas_results <- scrape_atlas_results("assumption_checking/all_sites_run")
get_DH_est_comp_xlsx(atlas_results_in=all_sites_atlas_results,
  out_xlsx="media/xlsx/assumption_checking/allsites_atlas_results.xlsx")

# Plot tagger survival estimates with confidence intervals
source("R/get_tagger_surv_plot.R")
get_tagger_surv_plot(
  cjs_survival_long = BRZsel_atlas_results$cjs_survival,
  save_plot = TRUE
)

# Plot tagger cumulative survival estimates with confidence intervals
source("R/get_tagger_cumul_surv_plot.R")
get_tagger_cumul_surv_plot(
  cumul_cjs_survival = BRZsel_atlas_results$cumul_cjs_survival,
  save_plot = TRUE
)

# =========================================================================================
# PERFORM F-TESTS ON TAGGER EFFECTS BY REACH
# =========================================================================================
# Perform F-tests by reach (excludes POOLED tagger, tests homogeneity across taggers)


f_test_results_by_reach <- compute_f_tests_by_reach( BRZsel_atlas_results$cjs_survival_long |> filter(location_code=="RI_CHN"),verbose=TRUE)

f_test_results_by_reach_rnd4 <- compute_f_tests_by_reach( BRZsel_atlas_results$cjs_survival_long |> filter(location_code=="RI_CHN"),verbose=TRUE,est_digits=4)

f_test_results_by_reach
f_test_results_by_reach_rnd4

# comp_surv_est_tabs_wFtests$CHN




cat("F-Test Results by Reach:\n")
cat("Testing hypothesis: No significant difference in survival estimates across taggers\n\n")
print(f_test_results_by_reach)
cat("\n\n")
cat("Interpretation:\n")
cat("- F_statistic: test statistic for comparing tagger effects\n")
cat("- p_value: probability of observing these differences by chance if null hypothesis is true\n")
cat("- p < 0.05 suggests significant tagger effect at that reach\n")

# Extract cumulative survival data for F-tests
atlas_cumul_long <- BRZsel_atlas_results$cumul_cjs_survival

# Perform F-tests on cumulative survival by reach
f_test_results_cumul <- compute_f_tests_by_reach_cumul(atlas_cumul_long)

cat("\n\n=========================================================================================\n")
cat("F-TESTS FOR TAGGER EFFECTS - CUMULATIVE SURVIVAL\n")
cat("=========================================================================================\n\n")

print(f_test_results_cumul)

