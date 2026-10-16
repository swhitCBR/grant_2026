# ---------------------------------------------------------------------------
# fc_logrank_table(): format log-rank test result(s) as a Word-ready table
# ---------------------------------------------------------------------------
# Builds a flextable summarizing an omnibus survdiff()/fc_diff() result, plus
# optional pairwise follow-up comparisons (with a Bonferroni-adjusted
# p-value), and writes it to a .docx file -- open that file, select the
# table, copy, and paste into your report, as with fc_lrt_table().
# ---------------------------------------------------------------------------

#' Format log-rank test result(s) as a table and save to a Word document
#'
#' @param omnibus A `survdiff` object (e.g. from `failCompare::fc_diff()` or
#'   `survival::survdiff()`) testing all groups at once.
#' @param pairwise Optional named list of `survdiff` objects, one per pair of
#'   groups (names used as the "Comparison" label). If supplied, a
#'   Bonferroni-adjusted p-value column is added.
#' @param omnibus_label Label for the omnibus row. Default `"All groups"`.
#' @param path Output .docx path. Defaults to `logrank_table.docx` inside
#'   `media/docx/` (created if it doesn't already exist).
#' @return The `flextable` object (invisibly), after saving it to `path`.
#' @export
fc_logrank_table <- function(omnibus, pairwise = NULL,
                              omnibus_label = "All groups",
                              path = file.path("media", "docx", "logrank_table.docx")) {

  fmt_p <- function(p) ifelse(p < 0.001, "< 0.001", formatC(p, digits = 3, format = "f"))

  df_omnibus <- length(omnibus$n) - 1
  p_omnibus  <- 1 - pchisq(omnibus$chisq, df_omnibus)

  tab <- data.frame(
    Comparison     = omnibus_label,
    "Chi-squared"  = round(omnibus$chisq, 2),
    df             = df_omnibus,
    "p-value"      = fmt_p(p_omnibus),
    "Bonferroni p" = "",
    check.names = FALSE
  )

  if (!is.null(pairwise)) {
    df_pw <- vapply(pairwise, function(x) length(x$n) - 1, numeric(1))
    p_pw  <- vapply(pairwise, function(x) 1 - pchisq(x$chisq, length(x$n) - 1), numeric(1))
    p_pw_adj <- p.adjust(p_pw, method = "bonferroni")

    tab_pw <- data.frame(
      Comparison     = names(pairwise),
      "Chi-squared"  = round(vapply(pairwise, function(x) x$chisq, numeric(1)), 2),
      df             = df_pw,
      "p-value"      = fmt_p(p_pw),
      "Bonferroni p" = fmt_p(p_pw_adj),
      check.names = FALSE
    )
    tab <- rbind(tab, tab_pw)
  }

  print(tab, row.names = FALSE)

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  ft <- flextable::flextable(tab)
  ft <- flextable::autofit(ft)
  flextable::save_as_docx(ft, path = path)
  message("Table written to: ", normalizePath(path))

  invisible(ft)
}
