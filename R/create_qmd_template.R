#' Function: create_qmd_template
#'
#' Creates a Quarto markdown template from scratch by pasting predefined content.
#' Does not source existing files; content is defined within the function environment.
#'
#' @param template_name Name of the template to use. Options:
#'   - "SW_QAQC_tabs_1_2" (default): Creates SW_QAQC_tabs_1_2_template.qmd
#'   - "SW_QAQC_tabs_2_2": Creates SW_QAQC_tabs_2_2_template.qmd
#' @param output_dir Directory where the template should be written (default: "qmd_templates")
#' @param overwrite Logical, whether to overwrite existing file (default: TRUE)
#'
#' @return NULL (invisibly). Creates a file in the output directory.
#'
#' @examples
#' create_qmd_template(output_dir = "output/qmd")
#' create_qmd_template(template_name = "SW_QAQC_tabs_2_2", output_dir = "my_report")

create_qmd_template <- function(
  template_name = "SW_QAQC_tabs_1_2",
  output_dir,
  overwrite = TRUE
) {
  
  # Validate arguments
  if (missing(output_dir)) {
    stop("output_dir argument is required")
  }
  
  # Template content for SW_QAQC_tabs_1_2_template.qmd
  template_1_2_content <- c(
    "---",
    'title: "GRANT 2026; SW QA/QC Tables v3 (1/3)"',
    "format:",
    "  docx:",
    "    toc: true",
    "    reference-doc: ../media/docx/ref_doc_QAQC.docx",
    "    execute:",
    "warning: false",
    "message: false  # Highly recommended to also hide package startup messages",
    "editor: source",
    "---",
    "",
    "```{r setup, include=FALSE,warning=FALSE}",
    "knitr::opts_chunk$set(echo = F, eval=T)",
    "library(dplyr)",
    "library(tidyr)",
    "",
    "options(knitr.kable.NA = '--')",
    "",
    "# CT_ALIVE_EUTH_ls <- readRDS(\"tmp_data/CT_ALIVE_EUTH_ls.rds\")",
    "# CT_raw_ls <- readRDS(\"tmp_data/CT_raw_ls.rds\")",
    "# rel_tagger_sum_tb_ls <- readRDS(\"tmp_data/rel_tagger_sum_tb_ls.rds\")",
    "# rel_loc_by_repID_tabs <- readRDS(\"tmp_data/rel_loc_by_repID_tabs.rds\")",
    "source(\"../R/get_tagger_rel_loc_status_tb_ls.R\")",
    "source(\"../R/get_rel_loc_by_repID_tabs.R\")",
    "source(\"../R/get_conting_tabs.R\")",
    "",
    "# tag_subsets_ls <- readRDS(\"tmp_data/tag_subsets_ls.rds\")",
    "tag_subsets_ls <- readRDS(\"../data/clean/tag_subsets_ls.rds\")",
    "",
    "```"
  )
  
  # Template content for SW_QAQC_tabs_2_2_template.qmd
  template_2_2_content <- c(
    "---",
    'title: "GRANT 2026; SW QA/QC Tables v3 (2/2)"',
    "format:",
    "  docx:",
    "    toc: true",
    "    reference-doc: ../media/docx/ref_doc_w_QAQC.docx",
    "    execute:",
    "warning: false",
    "message: false  # Highly recommended to also hide package startup messages",
    "editor: source",
    "---",
    "",
    "```{r setup, include=FALSE,warning=FALSE}",
    "knitr::opts_chunk$set(echo = F, eval=T)",
    "library(dplyr)",
    "library(tidyr)",
    "",
    "options(knitr.kable.NA = '--')",
    "",
    "# # CT_ALIVE_EUTH_ls <- readRDS(\"tmp_data/CT_ALIVE_EUTH_ls.rds\")",
    "# # CT_raw_ls <- readRDS(\"tmp_data/CT_raw_ls.rds\")",
    "# # rel_tagger_sum_tb_ls <- readRDS(\"tmp_data/rel_tagger_sum_tb_ls.rds\")",
    "# # rel_loc_by_repID_tabs <- readRDS(\"tmp_data/rel_loc_by_repID_tabs.rds\")",
    "# # source(\"R/get_tagger_rel_loc_status_tb_ls.R\")",
    "# # source(\"R/get_rel_loc_by_repID_tabs.R\")",
    "# # source(\"R/get_conting_tabs.R\")",
    "",
    "# tag_subsets_ls <- readRDS(\"../data/clean/tag_subsets_ls.rds\")",
    "",
    "# # setwd(\"C:/repos/grant_2026/QAQC\")",
    "# csv_fl_ls <- readRDS(\"tmp_data/csv_fl_ls.rds\")",
    "# events_dat <- csv_fl_ls$GPUD2026_events_17Aug2026",
    "# node_dat <- csv_fl_ls$GPUD2026_nodes_12Aug2026",
    "",
    "# # tags_dat_ALIVE_EUTH_wrepID <- readRDS(\"tmp_data/tags_dat_ALIVE_EUTH_wrepID.rds\")",
    "# # tags_dat_raw_wrepID <- readRDS(\"tmp_data/tags_dat_raw_wrepID.rds\")",
    "",
    "# tag_subsets_ls <- readRDS(\"tmp_data/tag_subsets_ls.rds\")",
    "",
    "# source(\"R/get_DH_tag_code_summ.R\")",
    "",
    "# # tag_ALIVE_EUTH_DH_summ <- get_DH_tag_code_summ(node_dat_in = node_dat,events_dat_in = events_dat,tags_dat_wrepID_in = tags_dat_ALIVE_EUTH_wrepID)",
    "# # tag_raw_DH_summ <- get_DH_tag_code_summ(node_dat_in = node_dat,events_dat_in = events_dat,tags_dat_wrepID_in = tags_dat_raw_wrepID)",
    "",
    "# tag_ALIVE_EUTH_DH_summ <- get_DH_tag_code_summ(node_dat_in = node_dat,events_dat_in = events_dat,tags_dat_wrepID_in = tag_subsets_ls[[\"tags_ALIVE_or_EUTH\"]])",
    "# tag_raw_DH_summ <- get_DH_tag_code_summ(node_dat_in = node_dat,events_dat_in = events_dat,tags_dat_wrepID_in = tag_subsets_ls[[\"RAW\"]])",
    "",
    "# tag_raw_DH_summ <- tag_raw_DH_summ |>",
    "#   rename(rel_loc=release_location,",
    "#          status=fish_status,CBAR=Crescent.Bar,WAN=Wanapum,WAN.BRZ=Wanapum.BRZ,WAN.TR=Wanapum.Tailrace,WB=White.Bluffs,HAN=Hanford,VRBR=Vernita.Bridge,PR.TR=Priest.Tailrace,PR.BRZ=Priest.BRZ,MATT=Mattawa,SUN=Sunland,LRNG=Lower.Ringold,PR=Priest) |>",
    "#   mutate(rel_loc=ifelse(rel_loc==\"Rock Island Tailrace\",\"RI\",\"PR\"))",
    "# tag_ALIVE_EUTH_DH_summ <- tag_ALIVE_EUTH_DH_summ |>",
    "#   rename(rel_loc=release_location,status=fish_status,CBAR=Crescent.Bar,WAN=Wanapum,WAN.BRZ=Wanapum.BRZ,WB=White.Bluffs,HAN=Hanford,VRBR=Vernita.Bridge,PR.TR=Priest.Tailrace,PR.BRZ=Priest.BRZ,MATT=Mattawa,SUN=Sunland,LRNG=Lower.Ringold,PR=Priest) |>",
    "#   mutate(rel_loc=ifelse(rel_loc==\"Rock Island Tailrace\",\"RI\",\"PR\"))",
    "",
    "# names(tag_ALIVE_EUTH_DH_summ)",
    "",
    "# # AE_RI_summ <- tag_ALIVE_EUTH_DH_summ |> filter(rel_loc==\"Rock Island Tailrace\")",
    "# # AE_PR_summ <-  tag_ALIVE_EUTH_DH_summ |> filter(rel_loc==\"Priest Rapids Tailrace\")",
    "# #",
    "# # raw_RI_summ <- tag_raw_DH_summ |> filter(rel_loc==\"Rock Island Tailrace\")",
    "# # raw_PR_summ <-  tag_raw_DH_summ |> filter(rel_loc==\"Priest Rapids Tailrace\")",
    "",
    "# AE_RI_summ <- tag_ALIVE_EUTH_DH_summ |> filter(rel_loc==\"RI\")",
    "# AE_PR_summ <-  tag_ALIVE_EUTH_DH_summ |> filter(rel_loc==\"PR\")",
    "",
    "# raw_RI_summ <- tag_raw_DH_summ |> filter(rel_loc==\"RI\")",
    "# raw_PR_summ <-  tag_raw_DH_summ |> filter(rel_loc==\"PR\")",
    "",
    "# tag_DH_ls <- list(",
    "#    \"AE_RI_summ\"=AE_RI_summ,",
    "#    \"AE_PR_summ\"=AE_PR_summ,",
    "#    \"raw_RI_summ\"=raw_RI_summ,",
    "#    \"raw_PR_summ\"=raw_PR_summ",
    "#    )",
    "",
    "# # tag_DH_ls <- readRDS(\"tmp_data/tag_DH_ls.rds\")",
    "",
    "# Load detection history list generated by QAQC_tables.R",
    "tag_DH_ls <- readRDS(\"../data/clean/tag_DH_ls.rds\")",
    "",
    "```"
  )
  
  # Map template names to content
  template_mapping <- list(
    "SW_QAQC_tabs_1_2" = list(
      content = template_1_2_content,
      filename = "SW_QAQC_tabs_1_2_template.qmd"
    ),
    "SW_QAQC_tabs_2_2" = list(
      content = template_2_2_content,
      filename = "SW_QAQC_tabs_2_2_template.qmd"
    )
  )
  
  # Validate template name
  if (!template_name %in% names(template_mapping)) {
    valid_names <- paste(names(template_mapping), collapse = '", "')
    stop(paste0('Invalid template_name. Valid options: "', valid_names, '"'))
  }
  
  # Get template content and filename
  template_info <- template_mapping[[template_name]]
  template_content <- template_info$content
  template_filename <- template_info$filename
  
  # Create output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Create full output path
  output_path <- file.path(output_dir, template_filename)
  
  # Check if output file already exists
  if (file.exists(output_path) && !overwrite) {
    stop(paste("File already exists:", output_path, "Set overwrite=TRUE to overwrite."))
  }
  
  # Write template content to file
  writeLines(template_content, con = output_path)
  
  cat(paste("✓ Template created:", output_path, "\n"))
  
  invisible(NULL)
}
