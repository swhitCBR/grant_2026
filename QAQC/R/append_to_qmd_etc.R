
#' Title
#'
#' @param file_path
#' @param text_lines
#'
#' @returns
#'
#' @export
#' @examples
append_to_qmd <- function(file_path, text_lines) {
  cat(text_lines, sep = "\n", file = file_path, append = TRUE)}

add_qsec3 <- function(header_in="Live/Dead Status vs. survival_use",tag_sub_nm="RAW",tb_nm_in="usable_CT_tab", header_level="###"){
  c(
  paste(header_level,header_in),
  "```{r,echo=F,eval=T}",
  paste0("knitr::kable(get_conting_tabs_by_name(tags_dat_in = tag_subsets_ls[['",tag_sub_nm,"']],tb_nm_in = '",tb_nm_in,"'))"),
  # paste0("get_conting_tabs_by_name(tags_dat_in = tag_subsets_ls[['",tag_sub_nm,"']],tb_nm_in = '",tb_nm_in,"')"),
  "```"
  )}

add_qsec3_elwise <- function(header_in="Live/Dead Status vs. survival_use",tag_sub_nm="RAW",tb_nm_in="usable_CT_tab",ele_nm_in, header_level="#####"){
  c(
  paste(header_level,header_in),
  "```{r,echo=F,eval=T}",
  paste0("knitr::kable(get_conting_tabs_by_name(tags_dat_in = tag_subsets_ls[['",tag_sub_nm,"']],tb_nm_in = '",tb_nm_in,"',ele_nm_in = '",ele_nm_in,"'))"),
  # paste0("get_conting_tabs_by_name(tags_dat_in = tag_subsets_ls[['",tag_sub_nm,"']],tb_nm_in = '",tb_nm_in,"')"),
  "```"
  )}

get_conting_tabs_by_name
# filter_strs <- c(
#   "tags_ALIVE_or_EUTH" = "fish_status %in% c('Alive','Euthanized')",
#   "tags_SURVUSE_AND_ALIVE_or_EUTH" = "survival_use & fish_status %in% c('Alive','Euthanized')",
#   "tags_SURVUSE_OR_ALIVE_or_EUTH" = "survival_use | fish_status %in% c('Alive','Euthanized')",
#   "tags_SURVUSE_OR_EUTH_&_ACTIVE" = "survival_use | (fish_status %in% c('Euthanized') & tag_status=='Active')",
#   "tags_ALIVE_ACTIVE_OTHER_OR_EUTH_ACTIVE_OTHER" = "(fish_status %in% c('Alive') & tag_status=='Active' & release_type=='Other') | (fish_status %in% c('EUTH') & tag_status=='Active' & release_type=='Other')"
# )
# tag_subsets_ls_test <- build_tag_subsets(tags_dat_raw_wrepID, filter_strs)



# top_matter <- c(
#   '{{< pagebreak >}}',
#   '# Summaries for all tags',
#   'Includes "Tarmac" and "Mortality" groups (i.e., fish dropped on the ground and that died during handing, respectively)')
# 
# append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'\n{{< pagebreak >}}\n')
# append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'# Summaries for all tags')
# append_to_qmd("SW_QAQC_new_summ_1_3.qmd",'Includes "Tarmac" and "Mortality" groups (i.e., fish dropped on the ground and that died during handing, respectively)')
# # append_to_qmd("SW_QAQC_new_summ_1_3.qmd",top_matter)
# append_to_qmd("SW_QAQC_new_summ_1_3.qmd", "\n## Contingency Tables\n")
# # Example: Adding an executable R code block to a Quarto file
# quarto_chunk <- c(
#   "### Live/Dead Status vs. survival_use",
#   "```{r,echo=F,eval=T}",
#   "knitr::kable(get_conting_tabs_by_name(tags_dat_in = tag_subsets_ls[['tags_SURVUSE_AND_ALIVE_or_EUTH']],tb_nm_in = 'usable_CT_tab'))",
#   "get_conting_tabs_by_name(tags_dat_in = tag_subsets_ls[['tags_SURVUSE_AND_ALIVE_or_EUTH']],tb_nm_in = 'usable_CT_tab')",
#   "```"
# )
# append_to_qmd("SW_QAQC_new_summ_1_3.qmd", quarto_chunk)

# code below adds all the contingency tables in 