#' Generate Capture History Section for Round 3 Report
#' 
#' This script:
#' 1. Scrapes capture history tables from markdown files
#' 2. Generates markdown content with formatted tables
#' 3. Saves to capture_history_tables.md for inclusion in main report

source("scrape_markdown_tables.R")

# Scrape the data
cat("Scraping capture history data from round_3...\n\n")
scraped <- scrape_capture_history(".")

# Generate markdown
markdown_content <- format_capture_history_tables(scraped)

# Save to file
output_file <- "capture_history_tables.md"
writeLines(markdown_content, output_file)

cat("\nSaved to:", output_file, "\n")
cat("File size:", file.size(output_file), "bytes\n")
