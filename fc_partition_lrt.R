# ---------------------------------------------------------------------------
# fc_partition_lrt.R: likelihood-ratio tests for arbitrary group poolings
# ---------------------------------------------------------------------------
# Generalizes fc_lrt() (fully pooled vs. fully separate) and the pairwise
# comparisons built on top of it to *any* way of partitioning a set of
# groups into clusters that share vitality parameters. In particular, for
# 3+ groups this lets you test "partial pooling" models -- e.g. lots 1 and 2
# share one set of (r,s,k,u) parameters while lot 3 is estimated separately
# -- and compare them against the fully-separate model, not just against
# each other in isolation (as the simple pairwise comparison does, ignoring
# the third group's data entirely).
#
# Requires fc_nll() (from fc_nll.R) for correctly-scaled NLL extraction.
# ---------------------------------------------------------------------------

#' Fit and score one candidate partition of groups
#'
#' @param groups Named list of raw failure-time vectors, one per group.
#' @param partition A list of character vectors, each naming the groups (from
#'   `names(groups)`) that share a single set of parameters under this
#'   candidate model. Every name in `names(groups)` must appear in exactly
#'   one element.
#' @param model Passed to `failCompare::fc_fit()`.
#' @param rc.value Passed to `failCompare::fc_fit()` (`NULL` = uncensored).
#' @param fits Optional named list of pre-fit `fc_obj`s for singleton groups
#'   (named by that group's name), reused instead of refitting.
#' @param nll_fun Function taking a single `fc_obj` and returning its scalar
#'   negative log-likelihood. Defaults to `fc_nll` (the `dataPrep()`-binned
#'   likelihood `vitality.ku`/`vitality.4p` actually optimize). Pass a
#'   different extractor -- e.g. a wrapper around `nll_vitality_ku()` -- to
#'   score partitions with a different likelihood.
#' @return A list with `nll` (summed, sample-size-scaled negative
#'   log-likelihood across clusters), `n_clusters`, and `fits` (the fc_obj
#'   fit to each cluster, named by the clustered group names).
#' @export
fc_partition_nll <- function(groups, partition, model = "vitality.ku",
                              rc.value = NULL, fits = NULL, nll_fun = fc_nll) {
  all_names <- unlist(partition)
  if (!setequal(all_names, names(groups)) || length(all_names) != length(names(groups))) {
    stop("`partition` must contain every name in `names(groups)` exactly once.")
  }

  cluster_fits <- lapply(partition, function(cl) {
    if (length(cl) == 1 && !is.null(fits) && cl %in% names(fits)) {
      fits[[cl]]
    } else {
      failCompare::fc_fit(time = unlist(groups[cl]), model = model, rc.value = rc.value)
    }
  })
  names(cluster_fits) <- vapply(partition, paste, character(1), collapse = " + ")

  list(
    nll = sum(vapply(cluster_fits, nll_fun, numeric(1))),
    n_clusters = length(partition),
    fits = cluster_fits
  )
}

#' Likelihood-ratio test between two nested partitions of the same groups
#'
#' `partition_restricted` must be a coarsening of `partition_unrestricted`
#' (every cluster of the unrestricted partition is a subset of some cluster
#' of the restricted one) -- e.g. restricted = `list(c("Lot 1","Lot 2"), "Lot 3")`
#' and unrestricted = `list("Lot 1", "Lot 2", "Lot 3")` tests whether lots 1
#' and 2 can validly share parameters while lot 3 stays separate.
#'
#' @inheritParams fc_partition_nll
#' @export
fc_partition_lrt <- function(groups, partition_restricted, partition_unrestricted,
                              model = "vitality.ku", rc.value = NULL, fits = NULL,
                              nll_fun = fc_nll) {
  n_par <- length(failCompare:::fc_mod_ls[[model]])
  restr   <- fc_partition_nll(groups, partition_restricted,   model, rc.value, fits, nll_fun)
  unrestr <- fc_partition_nll(groups, partition_unrestricted, model, rc.value, fits, nll_fun)

  df    <- (unrestr$n_clusters - restr$n_clusters) * n_par
  stat  <- 2 * (restr$nll - unrestr$nll)
  pval  <- pchisq(stat, df = df, lower.tail = FALSE)

  list(nll_restricted = restr$nll, nll_unrestricted = unrestr$nll,
       statistic = stat, df = df, p_value = pval,
       fits_restricted = restr$fits, fits_unrestricted = unrestr$fits)
}

#' Scan every pairwise pooling of a set of >= 3 groups
#'
#' For each pair of groups, this reports two distinct tests:
#'  - `pairwise`: the "classic" pairwise comparison -- pool just that pair
#'    (ignoring every other group's data) vs. fitting the pair separately.
#'  - `vs_full_pool`: whether that pair, once merged, still needs the
#'    remaining group(s) kept separate -- i.e. "lots 1 & 2 share one set of
#'    parameters, lot 3 is estimated on its own" (the partial-pooling model)
#'    vs. "all groups pooled into a single model" (the fully pooled model).
#'
#' Note: comparing the partial-pooling model against the *fully separate*
#' model instead would give a statistic numerically identical to `pairwise`
#' -- because the third group's likelihood term appears unchanged on both
#' sides and cancels exactly -- so that comparison is omitted as redundant.
#' `vs_full_pool` is the comparison that actually uses the third group's
#' data to add new information beyond the plain pairwise test.
#'
#' @param groups Named list of raw failure-time vectors (length >= 3).
#' @param singleton_fits Optional named list of pre-fit `fc_obj`s for each
#'   group fit on its own, reused instead of refitting.
#' @inheritParams fc_partition_nll
#' @return A list with the fully-separate and fully-pooled NLLs, and a named
#'   list of per-pair results (each containing the `pairwise` and
#'   `vs_full_pool` LRTs).
#' @export
fc_pooling_scan <- function(groups, model = "vitality.ku", rc.value = NULL,
                             singleton_fits = NULL, nll_fun = fc_nll) {
  nm <- names(groups)
  if (length(nm) < 3) stop("fc_pooling_scan() needs at least 3 groups (use fc_lrt() for 2).")

  full_separate_partition <- as.list(nm)
  full_pool_partition <- list(nm)
  full_separate <- fc_partition_nll(groups, full_separate_partition, model, rc.value, singleton_fits, nll_fun)
  full_pool     <- fc_partition_nll(groups, full_pool_partition,     model, rc.value, singleton_fits, nll_fun)

  pairs <- combn(nm, 2, simplify = FALSE)
  comparisons <- lapply(pairs, function(pr) {
    rest <- setdiff(nm, pr)
    partial_partition <- c(list(pr), as.list(rest))

    pairwise <- fc_partition_lrt(groups[pr], list(pr), as.list(pr),
                                  model, rc.value, singleton_fits, nll_fun)

    vs_full_pool <- fc_partition_lrt(groups, full_pool_partition, partial_partition,
                                      model, rc.value, singleton_fits, nll_fun)

    list(pairwise = pairwise, vs_full_pool = vs_full_pool)
  })
  names(comparisons) <- sapply(pairs, paste, collapse = " vs ")

  list(full_separate_nll = full_separate$nll,
       full_pool_nll = full_pool$nll,
       comparisons = comparisons)
}

#' Format an fc_pooling_scan() result as a Word-ready table
#'
#' @param scan Result of `fc_pooling_scan()`.
#' @param path Output .docx path. Defaults to `pooling_scan_table.docx`
#'   inside `media/docx/`.
#' @param print If `TRUE` (default), also print the table to the console.
#' @export
fc_pooling_scan_table <- function(scan, path = file.path("media", "docx", "pooling_scan_table.docx"),
                                   print = TRUE) {
  fmt_p <- function(p) ifelse(p < 0.001, "< 0.001", formatC(p, digits = 3, format = "f"))

  rows <- lapply(names(scan$comparisons), function(pair_label) {
    cmp <- scan$comparisons[[pair_label]]
    rbind(
      data.frame(Comparison = paste0(pair_label, " (pairwise, others excluded)"),
                 "Chi-squared" = round(cmp$pairwise$statistic, 2),
                 df = cmp$pairwise$df,
                 p_raw = cmp$pairwise$p_value,
                 check.names = FALSE),
      data.frame(Comparison = paste0(pair_label, " pooled, rest separate (vs. fully pooled)"),
                 "Chi-squared" = round(cmp$vs_full_pool$statistic, 2),
                 df = cmp$vs_full_pool$df,
                 p_raw = cmp$vs_full_pool$p_value,
                 check.names = FALSE)
    )
  })
  tab <- do.call(rbind, rows)
  tab$"p-value" <- fmt_p(tab$p_raw)
  tab$p_raw <- NULL

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
