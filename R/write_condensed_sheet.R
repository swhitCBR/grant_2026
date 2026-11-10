#' Write a condensed sheet of stacked tables to an openxlsx workbook
#'
#' Adds one worksheet to an existing openxlsx workbook and fills it with a stack of tables,
#' each preceded by a bold title. Chinook (`chn_tbs`) goes on the left and Steelhead (`sth_tbs`)
#' on the right; supply only one of them for a single-species sheet. Used to build the
#' condensed `COMB_pool_pair_est_output.xlsx` in analysis/replicate_level_wtavg_F_test_comp.R.
#'
#' Layout and formatting:
#' - Tables are stacked top to bottom in the order of `titles`. With both species, each
#'   section starts on the same row for both, so the titles line up across the sheet; the
#'   species blocks are separated by one narrow gap column.
#' - Each table gets its column names (bold) with a thin border above and below, and a thin
#'   border below its last row.
#' - `species_header = FALSE`: every title is 14 pt bold and prefixed with the species name
#'   ("Chinook: ..."). `species_header = TRUE`: the species name appears once in row 1 (14 pt,
#'   bold, underlined), tables start on row 3, and titles are plain 12 pt bold.
#' - Column widths are set from the table contents only (capped at 45 characters), so long
#'   titles overflow into empty neighbouring cells instead of widening the columns.
#'
#' @param wb An openxlsx workbook (from `openxlsx::createWorkbook()`). It is modified in place.
#' @param sheet Name of the new worksheet; must not already exist in `wb`.
#' @param titles Character vector with one title per table.
#' @param chn_tbs List of Chinook data frames, in the same order and of the same length as
#'   `titles`. NULL (default) leaves Chinook off the sheet.
#' @param sth_tbs List of Steelhead data frames, in the same order and of the same length as
#'   `titles`. NULL (default) leaves Steelhead off the sheet. Species lists may differ in
#'   number of rows and columns but not in number of tables.
#' @param species_header Logical. See Layout and formatting above. Default FALSE.
#' @param notes Optional character vector with one entry per table (same length as `titles`):
#'   a one-line italic note written directly under that table, in the same text for every
#'   species. Use NA or "" for tables without a note. NULL (default) adds no notes.
#'
#' @return The workbook `wb`, invisibly. Save it with `openxlsx::saveWorkbook()`.
#'
#' @keywords xlsx output
#' @export
#'
#' @examples
#' \dontrun{
#' wb <- openxlsx::createWorkbook()
#'
#' # both species side by side, species named once at the top
#' write_condensed_sheet(wb, "pooled", species_header = TRUE,
#'                       titles = c("Pooled paired survival"),
#'                       chn_tbs = list(CHN_pair), sth_tbs = list(STH_pair))
#'
#' # one species per sheet
#' write_condensed_sheet(wb, "CHN_replicates",
#'                       titles = c("F-test", "Replicate-level estimates"),
#'                       chn_tbs = list(CHN_F_tb, CHN_F_test_long))
#'
#' openxlsx::saveWorkbook(wb, "media/xlsx/example.xlsx", overwrite = TRUE)
#' }
write_condensed_sheet <- function(wb, sheet, titles, chn_tbs = NULL, sth_tbs = NULL,
                                  species_header = FALSE, notes = NULL) {
  stopifnot(requireNamespace("openxlsx", quietly = TRUE))
  if (is.null(notes)) notes <- rep(NA_character_, length(titles))
  stopifnot(length(notes) == length(titles))
  has_note <- !is.na(notes) & nzchar(notes)

  title_style <- openxlsx::createStyle(fontSize = if (species_header) 12 else 14, textDecoration = "bold")
  spp_header_style <- openxlsx::createStyle(fontSize = 14, textDecoration = c("bold", "underline"))
  colname_style <- openxlsx::createStyle(textDecoration = "bold")
  border_header_style <- openxlsx::createStyle(border = "TopBottom", borderStyle = "thin")
  border_last_style <- openxlsx::createStyle(border = "Bottom", borderStyle = "thin")
  note_style <- openxlsx::createStyle(textDecoration = "italic")
  openxlsx::addWorksheet(wb, sheet)

  spp_lab <- c(CHN = "Chinook", STH = "Steelhead")
  tbs <- Filter(Negate(is.null), list(CHN = chn_tbs, STH = sth_tbs))
  tbs <- lapply(tbs, function(spp_tbs) lapply(spp_tbs, as.data.frame))
  width <- max(vapply(unlist(tbs, recursive = FALSE), ncol, integer(1)))
  # species blocks sit side by side with one gap column between them
  start_col <- setNames(1 + (seq_along(tbs) - 1) * (width + 1), names(tbs))

  # section height = title row + column-name row + data rows + optional note row + one blank row
  heights <- vapply(seq_along(titles), function(i) {
    max(vapply(tbs, function(spp_tbs) nrow(spp_tbs[[i]]), integer(1))) + 3 + has_note[i]
  }, numeric(1))
  # with a species header, tables start on row 3 (header row, then a blank row)
  start_row <- cumsum(c(if (species_header) 3 else 1, heights))[seq_along(titles)]

  col_chars <- lapply(tbs, function(.) numeric(width))
  for (spp in names(tbs)) {
    if (species_header) {
      openxlsx::writeData(wb, sheet, spp_lab[[spp]], startRow = 1, startCol = start_col[[spp]])
      openxlsx::addStyle(wb, sheet, spp_header_style, rows = 1, cols = start_col[[spp]])
    }
    for (i in seq_along(titles)) {
      tb <- tbs[[spp]][[i]]
      openxlsx::writeData(wb, sheet, if (species_header) titles[i] else paste0(spp_lab[[spp]], ": ", titles[i]),
                          startRow = start_row[i], startCol = start_col[[spp]])
      openxlsx::addStyle(wb, sheet, title_style, rows = start_row[i], cols = start_col[[spp]])
      openxlsx::writeData(wb, sheet, tb, startRow = start_row[i] + 1, startCol = start_col[[spp]],
                          headerStyle = colname_style)
      # rules: top and bottom of the column-name row, bottom of the last data row
      tb_cols <- start_col[[spp]] + seq_len(ncol(tb)) - 1
      openxlsx::addStyle(wb, sheet, border_header_style, rows = start_row[i] + 1, cols = tb_cols, stack = TRUE)
      openxlsx::addStyle(wb, sheet, border_last_style, rows = start_row[i] + 1 + nrow(tb), cols = tb_cols, stack = TRUE)
      # one-line note directly under this species' table (the text may overflow to the right)
      if (has_note[i]) {
        note_row <- start_row[i] + 2 + nrow(tb)
        openxlsx::writeData(wb, sheet, notes[i], startRow = note_row, startCol = start_col[[spp]])
        openxlsx::addStyle(wb, sheet, note_style, rows = note_row, cols = start_col[[spp]])
      }
      # column widths come from the tables only (the long header text is allowed to overflow)
      # na.rm: tables with missing cells (e.g. R2 in the TLSR reach table) would otherwise give NA widths,
      # which Excel can't read, so the whole column fails to display
      w <- pmax(nchar(names(tb)), vapply(tb, function(x) max(nchar(as.character(x)), 0, na.rm = TRUE), numeric(1)))
      col_chars[[spp]][seq_along(w)] <- pmax(col_chars[[spp]][seq_along(w)], w)
    }
    openxlsx::setColWidths(wb, sheet, cols = start_col[[spp]] + seq_len(width) - 1,
                           widths = pmin(col_chars[[spp]] + 2, 45))
  }
  if (length(tbs) == 2) openxlsx::setColWidths(wb, sheet, cols = width + 1, widths = 4)

  invisible(wb)
}
