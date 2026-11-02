#' Demo Code for QAQC Programmatic Document Generation
#' 
#' This script contains all the R code examples presented in the
#' qaqc-tables-vignette.qmd file, extracted for easy reference and execution.
#'
#' The vignette demonstrates how to programmatically construct Quarto (.qmd)
#' documents by building markdown and R code blocks as character vectors,
#' then appending them to files.

# ============================================================================
# PART 1: Core Helper Functions
# ============================================================================

# The simplest function: append_to_qmd()
# This is the foundation of the entire workflow
append_to_qmd <- function(file_path, text_lines) {
  cat(text_lines, sep = "\n", file = file_path, append = TRUE)
}

# Example usage:
# append_to_qmd("report.qmd", "# My Section")
# This appends the text "# My Section" to report.qmd

# ============================================================================
# PART 2: Building Markdown Sections
# ============================================================================

#' Create markdown header + code block for displaying a contingency table
#'
#' This function builds a vector of text lines that together form:
#' - A markdown header
#' - A code block with R code to display a table

add_qsec3 <- function(
  header_in = "Live/Dead Status vs. survival_use",
  tag_sub_nm = "RAW",
  tb_nm_in = "usable_CT_tab", 
  header_level = "###"
) {
  # Build a character vector with one element per line
  c(
    # Line 1: The markdown header
    paste(header_level, header_in),
    
    # Line 2-4: Code block opening and R code
    "```{r,echo=F,eval=T}",
    paste0(
      "knitr::kable(get_conting_tabs_by_name(tags_dat_in = tag_subsets_ls[['",
      tag_sub_nm,
      "']], tb_nm_in = '",
      tb_nm_in,
      "'))"
    ),
    "```"
  )
}

# Example: Show what add_qsec3 produces
example_lines <- c(
  "### Fish Status vs. Release Method",
  "```{r,echo=F,eval=T}",
  "knitr::kable(get_conting_tabs_by_name(tags_dat_in = tag_subsets_ls[['RAW']], tb_nm_in = 'status_method_tab'))",
  "```"
)

cat("What add_qsec3() produces:\n")
cat("─────────────────────────────────\n")
cat(example_lines, sep = "\n")
cat("\n─────────────────────────────────\n\n")

# Show structure as a table
structure_df <- data.frame(
  Element_number = 1:4,
  Element_type = c("Markdown header", "Code block open", "R code", "Code block close"),
  Content = example_lines
)
print(structure_df)

# ============================================================================
# PART 3: Element-Wise Access Function
# ============================================================================

#' Create markdown header + code block for element-wise table access
#'
#' Similar to add_qsec3(), but for accessing specific elements from lists

add_qsec3_elwise <- function(
  header_in = "Live/Dead Status vs. survival_use",
  tag_sub_nm = "RAW",
  tb_nm_in = "usable_CT_tab",
  ele_nm_in,
  header_level = "#####"
) {
  c(
    paste(header_level, header_in),
    "```{r,echo=F,eval=T}",
    paste0(
      "knitr::kable(get_conting_tabs_by_name(tags_dat_in = tag_subsets_ls[['",
      tag_sub_nm,
      "']], tb_nm_in = '",
      tb_nm_in,
      "', ele_nm_in = '",
      ele_nm_in,
      "'))"
    ),
    "```"
  )
}

# Example: Generate sections for Chinook and Steelhead
chi_section <- add_qsec3_elwise(
  header_in = "Chinook",
  tag_sub_nm = "RAW",
  tb_nm_in = "species_tables_ls",
  ele_nm_in = "CHN"
)

sth_section <- add_qsec3_elwise(
  header_in = "Steelhead",
  tag_sub_nm = "RAW",
  tb_nm_in = "species_tables_ls",
  ele_nm_in = "STH"
)

cat("\nChinook section:\n")
cat(chi_section, sep = "\n")
cat("\n\nSteelhead section:\n")
cat(sth_section, sep = "\n")

# ============================================================================
# PART 4: Master Orchestration Function (Simplified)
# ============================================================================

#' Simplified version showing the orchestration pattern
#'
#' The real get_conting_tbs_qmd_els() function follows this pattern
#' but with many more table sections and loop iterations

get_conting_tbs_qmd_els_simplified <- function(
  tab_subset_nm = "RAW", 
  qmd_file = "report.qmd"
) {
  # Step 1: Create fresh file from template or use existing
  if (!file.exists(qmd_file)) {
    # Start with template containing YAML and setup code
    template_content <- c(
      "---",
      'title: "My Report"',
      "format: docx",
      "---",
      "",
      "```{r setup, include=FALSE}",
      "library(dplyr)",
      "tag_subsets_ls <- readRDS('data/tag_subsets_ls.rds')",
      "```"
    )
    writeLines(template_content, qmd_file)
  }
  
  # Step 2: Add main section header
  append_to_qmd(qmd_file, "\n")
  append_to_qmd(qmd_file, paste0("# Summaries for tag subset: ", tab_subset_nm))
  
  # Step 3: Add contingency tables section
  append_to_qmd(qmd_file, "\n## Contingency Tables\n")
  
  # Step 4: Add multiple table sections using helper functions
  append_to_qmd(qmd_file, add_qsec3(
    header_in = "Live/Dead Status vs. Survival Use",
    tb_nm_in = "status_survival_tab",
    tag_sub_nm = tab_subset_nm
  ))
  
  append_to_qmd(qmd_file, add_qsec3(
    header_in = "Live/Dead Status vs. Tagger",
    tb_nm_in = "status_tagger_tab",
    tag_sub_nm = tab_subset_nm
  ))
  
  # Step 5: Add nested sections for multiple elements (loop-based)
  append_to_qmd(qmd_file, "\n### By Species\n")
  
  for (species in c("CHN", "STH")) {
    append_to_qmd(qmd_file, add_qsec3_elwise(
      header_in = species,
      tb_nm_in = "species_summary_list",
      ele_nm_in = species,
      tag_sub_nm = tab_subset_nm,
      header_level = "####"
    ))
  }
}

# ============================================================================
# PART 5: Live Demonstration
# ============================================================================

# Create a temporary file to demonstrate
temp_qmd <- file.path(tempdir(), "demo_report.qmd")

# Step 1: Create the template with YAML and setup
template_content <- c(
  "---",
  'title: "Demo QAQC Report"',
  'format:',
  '  docx:',
  '    number-sections: true',
  "---",
  "",
  "```{r setup, include=FALSE}",
  "library(dplyr)",
  "library(knitr)",
  "```"
)

writeLines(template_content, temp_qmd)
cat("✓ Step 1: Created template file\n\n")

# Step 2: Append an introduction section
append_to_qmd(temp_qmd, "\n# Introduction\n")
append_to_qmd(temp_qmd, "This report demonstrates programmatic .qmd generation.\n")

# Step 3: Add helper function for creating sections
add_qsec3_demo <- function(
  header_in = "Example Table",
  tb_nm = "my_table"
) {
  c(
    paste("###", header_in),
    "```{r, echo=FALSE}",
    paste0("# Display table: ", tb_nm),
    "```"
  )
}

# Step 4: Add a table section
append_to_qmd(temp_qmd, "\n## Summary Tables\n")
append_to_qmd(temp_qmd, add_qsec3_demo(
  header_in = "Example Table 1",
  tb_nm = "example_table"
))

cat("✓ Step 2: Appended sections\n\n")

# Step 5: Add loop-generated sections
append_to_qmd(temp_qmd, "\n### Tables by Category\n")

categories <- c("Category_A", "Category_B", "Category_C")
for (cat in categories) {
  section <- c(
    paste("####", cat),
    "```{r, echo=FALSE}",
    paste0("# Table for: ", cat),
    "```"
  )
  append_to_qmd(temp_qmd, section)
}

cat("✓ Step 3: Added loop-generated sections\n\n")

# Display the resulting .qmd file
cat("📄 Generated .qmd file contents:\n")
cat("═════════════════════════════════════════════════════════════════\n")
cat(readLines(temp_qmd), sep = "\n")
cat("\n═════════════════════════════════════════════════════════════════\n")

# ============================================================================
# PART 6: Building Your Own Dynamic Sections
# ============================================================================

#' Template: Creating a custom helper function
#'
#' If you need to create a custom section with multiple tables

create_summary_section <- function(
  section_name,
  table_names,
  tag_subset = "RAW"
) {
  # Initialize the output vector
  lines <- c()
  
  # Add section header
  lines <- c(lines, paste0("## ", section_name))
  
  # Add introduction text
  lines <- c(lines, "This section contains summary tables for the analysis.\n")
  
  # Loop over each table
  for (tbl in table_names) {
    # Create a subsection for each table
    subsection <- c(
      paste("###", tbl),
      "```{r, echo=FALSE}",
      paste0("knitr::kable(my_tables[[\"", tbl, "\"]])"),
      "```"
    )
    lines <- c(lines, subsection)
  }
  
  return(lines)
}

# Usage:
my_section <- create_summary_section(
  section_name = "Data Quality Tables",
  table_names = c("table_1", "table_2", "table_3"),
  tag_subset = "RAW"
)

cat("\nCustom section example:\n")
cat(my_section, sep = "\n")

# ============================================================================
# PART 7: Real-World QAQC Workflow Pattern
# ============================================================================

#' This shows how the actual QAQC_tables_full_set.R workflow uses these functions
#'
#' In the actual workflow, this pattern generates multiple reports from different
#' data subsets with just a few lines of code

# Define the different tag subsets to analyze
tab_subsets <- c(
  "RAW", 
  "tags_SURVUSE_OR_EUTH_&_ACTIVE", 
  "tags_ALIVE_ACTIVE_OTHER_OR_EUTH_ACTIVE_OTHER"
)

# In the actual workflow, loop through each subset and generate its section
# for (i in seq_along(tab_subsets)) {
#   subset <- tab_subsets[i]
#   # First iteration: overwrite and create fresh file
#   # Subsequent iterations: append to existing file
#   get_conting_tbs_qmd_els(
#     tab_subset_nm = subset, 
#     overwrite = (i == 1)
#   )
# }
# 
# # Render the complete .qmd file to Word
# quarto::quarto_render("QAQC/SW_QAQC_tabs_1_2.qmd")

cat("\n✓ Demo code complete!\n")
cat("See vignette for detailed explanations of each concept.\n")
