# ---------------------------------------------------------------------------
# fc_lrt_table(): format fc_lrt() output as a Word-ready table
# ---------------------------------------------------------------------------
# Builds a flextable summarizing an omnibus likelihood-ratio test (as
# returned by fc_lrt()), plus optional pairwise follow-up comparisons (with
# a Bonferroni-adjusted p-value), and writes it to a .docx file. Open that
# file, select the table, copy, and paste into your report -- this
# preserves it as a native Word table (not just text).
# ---------------------------------------------------------------------------

#' Format fc_lrt() result(s) as a table and save it to a Word document
#'
#' @param lrt A list as returned by `fc_lrt()` (`nll_pooled`, `nll_groups_sum`,
#'   `statistic`, `df`, `p_value`) for the omnibus (all-groups) comparison.
#' @param pairwise Optional named list of `fc_lrt()` results, one per pair of
#'   groups (names used as the "Comparison" label).
#' @param omnibus_label Label for the omnibus row. Default `"All groups"`.
#' @param path Output .docx path. Defaults to `lrt_table.docx` inside
#'   `media/docx/` (created if it doesn't already exist).
#' @param print If `TRUE` (default), also print the table to the console.
#' @return The `flextable` object (invisibly), after saving it to `path`.
#' @export
fc_lrt_table <- function(lrt, pairwise = NULL, omnibus_label = "All groups",
                          path = file.path("media", "docx", "lrt_table.docx"),
                          print = TRUE) {

  fmt_p <- function(p) ifelse(p < 0.001, "< 0.001", formatC(p, digits = 3, format = "f"))

  tab <- data.frame(
    Comparison                = omnibus_label,
    "Pooled -logLik"          = round(lrt$nll_pooled, 2),
    "Separate models -logLik" = round(lrt$nll_groups_sum, 2),
    "Chi-squared"             = round(lrt$statistic, 2),
    df                        = lrt$df,
    "p-value"                 = fmt_p(lrt$p_value),
    check.names = FALSE
  )

  if (!is.null(pairwise)) {
    tab_pw <- data.frame(
      Comparison                = names(pairwise),
      "Pooled -logLik"          = round(vapply(pairwise, function(x) x$nll_pooled, numeric(1)), 2),
      "Separate models -logLik" = round(vapply(pairwise, function(x) x$nll_groups_sum, numeric(1)), 2),
      "Chi-squared"             = round(vapply(pairwise, function(x) x$statistic, numeric(1)), 2),
      df                        = vapply(pairwise, function(x) x$df, numeric(1)),
      "p-value"                 = fmt_p(vapply(pairwise, function(x) x$p_value, numeric(1))),
      check.names = FALSE
    )
    tab <- rbind(tab, tab_pw)
  }

  if (print) {
    cat("\n")
    print(tab, row.names = FALSE)
    cat("\n")
  }

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  ft <- flextable::flextable(tab)
  ft <- flextable::autofit(ft)
  flextable::save_as_docx(ft, path = path)
  message("Table written to: ", normalizePath(path))

  invisible(ft)
}
