#' Function: get_conting_tbs_qmd_els
#'
#' Appends contingency tables to a Quarto report for a specified tag subset.
#' If the qmd file exists and overwrite=FALSE, content is appended. 
#' If overwrite=TRUE, the file is replaced with a fresh copy of the template.
#' 
#' @param tab_subset_nm Name of the tag subset (default: "RAW")
#' @param qmd_file Output Quarto file path (default: "QAQC/SW_QAQC_tabs_1_2.qmd")
#' @param template_path Path to the template directory (default: "QAQC/qmd_templates")
#' @param overwrite Logical, whether to overwrite existing file (default: FALSE).
#'   If TRUE, the file is replaced. If FALSE and file exists, content is appended.
#'
#' @keywords QAQC quarto
#' @export
get_conting_tbs_qmd_els <- function(tab_subset_nm="RAW", qmd_file="QAQC/SW_QAQC_tabs_1_2.qmd", template_path="QAQC/qmd_templates", overwrite=FALSE){
  
  # If overwrite is TRUE or file doesn't exist, create fresh from template
  if(overwrite || !file.exists(qmd_file)){
    unlink(qmd_file)
    file.copy(file.path(template_path, "SW_QAQC_tabs_1_2_template.qmd"), qmd_file)
  }
  # Otherwise, file exists and overwrite=FALSE, so we'll append to it

  # top matter
  append_to_qmd(qmd_file,'\n{{< pagebreak >}}\n')
  if(tab_subset_nm=="RAW"){
    append_to_qmd(qmd_file,'# Summaries for all tags in the full data set (unfiltered)')
  } else{
    append_to_qmd(qmd_file,paste0('# Summaries for all tags in the `',tab_subset_nm,'` subset'))
  }

  append_to_qmd(qmd_file,'Includes "Tarmac" and "Mortality" groups (i.e., fish dropped on the ground and that died during handing, respectively)')
  append_to_qmd(qmd_file, "\n## Contingency Tables\n")

  append_to_qmd(qmd_file, add_qsec3(header_in="Live/Dead Status vs. Survival_use",tb_nm_in="usable_CT_tab",tag_sub_nm=tab_subset_nm))
  append_to_qmd(qmd_file, add_qsec3(header_in="Live/Dead Status vs. Tagger",tb_nm_in="fish_status_tagger_CT_tab",tag_sub_nm=tab_subset_nm))

  append_to_qmd(qmd_file, add_qsec3(header_in="Release location vs. tagger",tb_nm_in="RL_tagger_CT_tab",tag_sub_nm=tab_subset_nm))
  append_to_qmd(qmd_file, add_qsec3(header_in="Release Location vs. Release Type",tb_nm_in="RL_helicopter_CT_tab",tag_sub_nm=tab_subset_nm))

  append_to_qmd(qmd_file, add_qsec3(header_in="Tag lot vs. Tagger",tb_nm_in="lot_tagger_CT_tab",tag_sub_nm=tab_subset_nm))
  append_to_qmd(qmd_file, add_qsec3(header_in="Tag lot vs. Release location",tb_nm_in="lot_RL_CT_tab",tag_sub_nm=tab_subset_nm))

  append_to_qmd(qmd_file,'\n#### Rock Island\n')
  append_to_qmd(qmd_file, add_qsec3_elwise(header_in="CHN",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "CHN.Rock Island Tailrace"))
  append_to_qmd(qmd_file, add_qsec3_elwise(header_in="STH",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "STH.Rock Island Tailrace"))
  append_to_qmd(qmd_file,'\n#### Priest Rapids\n')
  append_to_qmd(qmd_file, add_qsec3_elwise(header_in="CHN",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "CHN.Priest Rapids Tailrace"))
  append_to_qmd(qmd_file, add_qsec3_elwise(header_in="STH",tb_nm_in="lot_tagger_RL_CT_tab_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "STH.Priest Rapids Tailrace"))

  append_to_qmd(qmd_file, add_qsec3(header_in="Replicate vs. Tagger",tb_nm_in="repID_tagger_CT_tab",tag_sub_nm=tab_subset_nm))
  append_to_qmd(qmd_file, add_qsec3(header_in="Replicate vs. Release location",tb_nm_in="repID_RL_CT_tab",tag_sub_nm=tab_subset_nm))

  append_to_qmd(qmd_file, add_qsec3(header_in="Fish released by location, status, and tagger",tb_nm_in="tags_dat_raw_tagger_summ",tag_sub_nm=tab_subset_nm,header_level = "##"))
  append_to_qmd(qmd_file,'\n### Chinook\n')
  append_to_qmd(qmd_file, add_qsec3_elwise(header_in="Live fish",tb_nm_in="tags_dat_raw_tagger_relID_summ_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "CHN_live",header_level = "####"))
  append_to_qmd(qmd_file, add_qsec3_elwise(header_in="Dead fish",tb_nm_in="tags_dat_raw_tagger_relID_summ_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "CHN_dead",header_level = "####"))
  append_to_qmd(qmd_file,'\n### Steelhead\n')
  append_to_qmd(qmd_file, add_qsec3_elwise(header_in="Live fish",tb_nm_in="tags_dat_raw_tagger_relID_summ_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "STH_live",header_level = "####"))
  append_to_qmd(qmd_file, add_qsec3_elwise(header_in="Dead fish",tb_nm_in="tags_dat_raw_tagger_relID_summ_ls",tag_sub_nm=tab_subset_nm,ele_nm_in = "STH_dead",header_level = "####"))

  append_to_qmd(qmd_file,'\n{{< pagebreak >}}\n')
  
  append_to_qmd(qmd_file,'\n## Fish Released by Location, Replicate, and Status\n')
  append_to_qmd(qmd_file,'\nRock Island and Priest Rapids are abbreviated and the "_d" refers to release of "Euthanized" fish\n')
  append_to_qmd(qmd_file, add_qsec3_elwise(header_in="CHN",tb_nm_in="rel_loc_by_repID_tabs",tag_sub_nm=tab_subset_nm,ele_nm_in = "CHN",header_level = "####"))
  append_to_qmd(qmd_file, add_qsec3_elwise(header_in="STH",tb_nm_in="rel_loc_by_repID_tabs",tag_sub_nm=tab_subset_nm,ele_nm_in = "STH",header_level = "####"))

  return(NULL) 
}