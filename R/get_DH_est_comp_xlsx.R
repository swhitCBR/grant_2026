#' Export Detection History and Survival Estimates to Excel
#'
#' Creates a multi-sheet Excel workbook with detection history patterns and 
#' survival comparison tables for all species/location combinations.
#'
#' @param atlas_results_in List returned from \code{scrape_atlas_results()}
#' @param out_xlsx Character. Path to output Excel file.
#'   Defaults to "assumption_checking/Tagger_comp_tmp.xlsx"
#'
#' @return NULL (invisibly). Saves Excel file to disk.
#'
#' @details
#' Creates an Excel workbook with 4 sheets:
#' - CHN_RI: Chinook at Rock Island
#' - CHN_PR: Chinook at Priest Rapids
#' - STH_RI: Steelhead at Rock Island
#' - STH_PR: Steelhead at Priest Rapids
#'
#' Each sheet contains detection history patterns followed by survival comparison tables.
#'
#' @keywords assumption_check
#' @export
#' @examples
#' \dontrun{
#' atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")
#' get_DH_est_comp_xlsx(atlas_results, out_xlsx = "my_results.xlsx")
#' }

get_DH_est_comp_xlsx <- function(atlas_results_in,out_xlsx="assumption_checking/Tagger_comp_tmp.xlsx"){

comp_tabs <- get_tagger_comp_tables_MOD(atlas_results_in=atlas_results_in)


DH_comb_ls <- list(
  "CHN_RI"=get_DH_tab_by_tagger(atlas_results_in = atlas_results_in,spp="CHN",release="RI"),
  "CHN_PR"=get_DH_tab_by_tagger(atlas_results_in = atlas_results_in,spp="CHN",release="PR"),
  "STH_RI"=get_DH_tab_by_tagger(atlas_results_in = atlas_results_in,spp="STH",release="RI"),
  "STH_PR"=get_DH_tab_by_tagger(atlas_results_in = atlas_results_in,spp="STH",release="PR")
  )


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


# Export as Excel with separate sheets for CHN and STH
library(openxlsx)
# Create Excel workbook with two sheets
wb <- createWorkbook()
addWorksheet(wb, "CHN_RI")
writeData(wb, "CHN_RI", DH_comb_ls$CHN_RI,startRow=1,colNames = F)
writeData(wb, "CHN_RI", comp_tabs$CHN$RI,startRow=nrow(DH_comb_ls$CHN_RI)+3)
writeData(wb, "CHN_RI", CHN_R1_to_LowerRing,startRow=nrow(comp_tabs$CHN$RI) + nrow(DH_comb_ls$CHN_RI)+2+3)
+
addWorksheet(wb, "CHN_PR")
writeData(wb, "CHN_PR", DH_comb_ls$CHN_PR,startRow=1,colNames = F)
writeData(wb, "CHN_PR", comp_tabs$CHN$PR,startRow=nrow(DH_comb_ls$CHN_PR)+3)

addWorksheet(wb, "STH_RI")
writeData(wb, "STH_RI", DH_comb_ls$STH_RI,startRow=1,colNames = F)
writeData(wb, "STH_RI", comp_tabs$STH$RI,startRow=nrow(DH_comb_ls$STH_RI)+3)
writeData(wb, "STH_RI", STH_R1_to_LowerRing,startRow=nrow(comp_tabs$STH$RI) + nrow(DH_comb_ls$STH_RI)+2+3)


addWorksheet(wb, "STH_PR")
writeData(wb, "STH_PR", DH_comb_ls$STH_PR,startRow=1,colNames = F)
writeData(wb, "STH_PR", comp_tabs$STH$PR,startRow=nrow(DH_comb_ls$STH_PR)+3)

saveWorkbook(wb, out_xlsx, overwrite = TRUE)
}