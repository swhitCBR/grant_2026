#' Create TagPro output subsets by tagger
#'
#' Processes ATLAS files and creates subsets by tagger (A, B, C), saving each 
#' to data/clean/post_tagpro/
#'
#' Prerequisites:
#'   - Run 03_pre_tagpro_runscript.R first to generate processed TagPro files
#'   - ATLAS CSV files must exist in data/clean/post_tagpro/

if(getwd() != "c:/repos/grant_2026"){
  setwd("c:/repos/grant_2026")}

# ============================================================================
# Source functions
# ============================================================================

RI_all_sites_tmp <- read.csv("c:/repos/grant_2026/data/clean/post_tagpro/RI_all_sites_MOD_ATLAS.csv",header = F)
names(RI_all_sites_tmp) <- c("release_spp","num1","tag_code","release_time","detection_time","site_name","num2","lst_dt")

unique(RI_all_sites_tmp$site_name)
# "Crescent Bar"     "Sunland"          "Wanapum BRZ"
# # "Wanapum"          "Wanapum Tailrace"
# "Mattawa"
# "Priest BRZ"
# # "Priest"           "Priest Tailrace"  "Vernita Bridge"  
# # "White Bluffs"
# "Lower Ringold"    "Hanford" 


sites_used <- c("Crescent Bar","Sunland","Wanapum BRZ","Mattawa","Priest BRZ","Lower Ringold","Hanford")
RI_all_sites_mod <- RI_all_sites_tmp |> filter(site_name %in% sites_used)

# > nrow(RI_all_sites_mod) # 12446
# > nrow(RI_all_sites_tmp) # 23114

# G72790346
RI_all_sites_mod |> filter(tag_code=="G72790346")

write.table(RI_all_sites_mod,"c:/repos/grant_2026/data/clean/post_tagpro/RI_all_sites_MOD_ATLAS.csv",
  row.names=F,col.names=F,sep=",",quote = FALSE)

source("R/create_atlas_tagger_subsets.R")
source("R/process_all_atlas_files.R")

# ============================================================================
# Split ATLAS files up by tagger
# ============================================================================

process_all_atlas_files()



# ============================================================================
# Create file structure for storing ATLAS output from various windows
# ============================================================================

# run all the models in ATLAS and then copy and paste full html window output into corresponding.md
source("R/make_dirs_mds_for_pasting.R")
# make_dirs_mds_for_pasting(
#   base_path = "assumption_checking",
#   outer_folder = "all_sites_run",
#   level1_dirs = c("POOLED", "TAGGER A", "TAGGER B", "TAGGER C"),
#   level2_dirs = c("PR_CHN", "PR_STH", "RI_CHN", "RI_STH"),
#   level3_dirs = NULL,
#   md_files = c("Capture History Report .md", "CJS_report.md"),
#   additional_mds = list(RI_CHN = c("Cumul_surv.md"), RI_STH = c("Cumul_surv.md")))

# make_dirs_mds_for_pasting(
#   base_path = "assumption_checking",
#   outer_folder = "BRZsel_run",
#   level1_dirs = c("POOLED", "TAGGER A", "TAGGER B", "TAGGER C"),
#   level2_dirs = c("PR_CHN", "PR_STH", "RI_CHN", "RI_STH"),
#   level3_dirs = NULL,
#   md_files = c("Capture History Report .md", "CJS_report.md"),
#   additional_mds = list(RI_CHN = c("Cumul_surv.md"), RI_STH = c("Cumul_surv.md")))
