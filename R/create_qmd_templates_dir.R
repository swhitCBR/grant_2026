#' Function: create_qmd_templates_dir
#'
#' Creates a directory containing both SW_QAQC_tabs template files.
#' This is a wrapper function that calls create_qmd_template() for each template.
#'
#' @param output_dir Directory where the template files should be created
#'   (default: "qmd_templates")
#' @param output_dir_docx Directory where rendered .docx files should be saved. If NULL, files are saved alongside the .qmd file (default: NULL)
#' @param overwrite Logical, whether to overwrite existing files (default: TRUE)
#'
#' @return NULL (invisibly). Creates a directory with both template files.
#'
#' @keywords QAQC quarto
#' @export
#'
#' @examples
#' create_qmd_templates_dir()
#' create_qmd_templates_dir(output_dir = "my_qmd_templates")
#' create_qmd_templates_dir(output_dir = "project/qmd", overwrite = FALSE)
#' create_qmd_templates_dir(output_dir = "QAQC/qmd_templates", output_dir_docx = "media/docx/QAQC word docs")

create_qmd_templates_dir <- function(
  output_dir = "qmd_templates",
  output_dir_docx = NULL,
  overwrite = TRUE
) {
  
  # Create the output directory and any necessary parent directories
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    cat(paste("✓ Created directory:", output_dir, "\n"))
  }
  
  # Create both templates in the directory
  cat("Creating Quarto templates...\n")
  
  create_qmd_template(
    template_name = "SW_QAQC_tabs_1_2",
    output_dir = output_dir,
    output_dir_docx = output_dir_docx,
    overwrite = overwrite
  )
  
  create_qmd_template(
    template_name = "SW_QAQC_tabs_2_2",
    output_dir = output_dir,
    output_dir_docx = output_dir_docx,
    overwrite = overwrite
  )
  
  cat("✓ All templates created successfully in:", output_dir, "\n")
  
  invisible(NULL)
}
