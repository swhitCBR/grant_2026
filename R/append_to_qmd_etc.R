#' Append text to a Quarto markdown file
#'
#' Appends text lines to a Quarto (.qmd) file in append mode.
#'
#' @param file_path Path to the Quarto file to append to.
#' @param text_lines Character vector of text lines to append to the file.
#'
#' @return NULL (invisibly). Modifies file at file_path.
#'
#' @keywords QAQC quarto
#' @export
#'
#' @examples
#' \dontrun{
#' append_to_qmd("report.qmd", "# New Section")
#' }
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
