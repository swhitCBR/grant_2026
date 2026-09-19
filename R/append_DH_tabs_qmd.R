#' Function: append_DH_tabs_qmd
#'
#' Appends detection history tables to a Quarto report using specific items from tag_DH_ls.
#' If the qmd file exists and overwrite=FALSE, content is appended.
#' If overwrite=TRUE, the file is replaced with a fresh copy of the template.
#' 
#' @param tag_subset_nm Name of the tag subset to display (default: "RAW")
#' @param tag_DH_ls_nm_RI Name of the Rock Island detection history list item (default: "raw_RI_summ")
#' @param tag_DH_ls_nm_PR Name of the Priest Rapids detection history list item (default: "raw_PR_summ")
#' @param qmd_file Output Quarto file path (default: "QAQC/SW_QAQC_tabs_2_2.qmd")
#' @param template_path Path to the template directory (default: "QAQC/qmd_templates")
#' @param overwrite Logical, whether to overwrite existing file (default: FALSE).
#'   If TRUE, the file is replaced. If FALSE and file exists, content is appended.
#'
#' @keywords QAQC quarto
#' @export
append_DH_tabs_qmd <- function(tag_subset_nm = "RAW", 
                               tag_DH_ls_nm_RI = "raw_RI_summ", 
                               tag_DH_ls_nm_PR = "raw_PR_summ",
                               qmd_file = "QAQC/SW_QAQC_tabs_2_2.qmd", 
                               template_path = "QAQC/qmd_templates", 
                               overwrite = FALSE) {
  
  # If overwrite is TRUE or file doesn't exist, create fresh from template
  if(overwrite || !file.exists(qmd_file)){
    unlink(qmd_file)
    file.copy(file.path(template_path, "SW_QAQC_tabs_2_2_template.qmd"), qmd_file)
  }
  # Otherwise, file exists and overwrite=FALSE, so we'll append to it
  
  append_to_qmd(qmd_file, "\n{{< pagebreak >}}\n")
  
  # Add section header based on tag subset
  if(tag_subset_nm == "RAW"){
    append_to_qmd(qmd_file, "# Detection Histories for All Tags in the Full Data Set (Unfiltered)")
  } else {
    append_to_qmd(qmd_file, paste0("# Detection Histories for `", tag_subset_nm, "` Subset"))
  }
  
  append_to_qmd(qmd_file, "\n## Live Fish\n")
  append_to_qmd(qmd_file, "\n### Chinook\n")
  append_to_qmd(qmd_file, add_DH_qsec3_elwise(header_in = "Rock Island Release", spp_in = "CHN", status_in = "Alive", header_level = "####", tag_DH_ls_nm_in = tag_DH_ls_nm_RI))
  append_to_qmd(qmd_file, add_DH_qsec3_elwise(header_in = "Priest Rapids Release", spp_in = "CHN", status_in = "Alive", header_level = "####", tag_DH_ls_nm_in = tag_DH_ls_nm_PR))
  # append_to_qmd(qmd_file, "{{< pagebreak >}}")
  append_to_qmd(qmd_file, "\n### Steelhead\n")
  append_to_qmd(qmd_file, add_DH_qsec3_elwise(header_in = "Rock Island Release", spp_in = "STH", status_in = "Alive", header_level = "####", tag_DH_ls_nm_in = tag_DH_ls_nm_RI))
  append_to_qmd(qmd_file, add_DH_qsec3_elwise(header_in = "Priest Rapids Release", spp_in = "STH", status_in = "Alive", header_level = "####", tag_DH_ls_nm_in = tag_DH_ls_nm_PR))
  append_to_qmd(qmd_file, "{{< pagebreak >}}")
  
  append_to_qmd(qmd_file, "\n## Dead Fish\n")
  append_to_qmd(qmd_file, "\n### Chinook\n")
  append_to_qmd(qmd_file, add_DH_qsec3_elwise(header_in = "Rock Island Release", spp_in = "CHN", status_in = "Alive", header_level = "####", status_is = FALSE, tag_DH_ls_nm_in = tag_DH_ls_nm_RI))
  append_to_qmd(qmd_file, add_DH_qsec3_elwise(header_in = "Priest Rapids Release", spp_in = "CHN", status_in = "Alive", header_level = "####", status_is = FALSE, tag_DH_ls_nm_in = tag_DH_ls_nm_PR))
  # append_to_qmd(qmd_file, "{{< pagebreak >}}")
  append_to_qmd(qmd_file, "\n### Steelhead\n")
  append_to_qmd(qmd_file, add_DH_qsec3_elwise(header_in = "Rock Island Release", spp_in = "STH", status_in = "Alive", header_level = "####", status_is = FALSE, tag_DH_ls_nm_in = tag_DH_ls_nm_RI))
  append_to_qmd(qmd_file, add_DH_qsec3_elwise(header_in = "Priest Rapids Release", spp_in = "STH", status_in = "Alive", header_level = "####", status_is = FALSE, tag_DH_ls_nm_in = tag_DH_ls_nm_PR))

  return(NULL)
}
