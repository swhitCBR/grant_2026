# ---------------------------------------------------------------------------
# run_vitality_lrt_grid(): pooled-vs-separate-groups LRT across a grid of
# fc_fit() `model` and `rc.value` arguments
# ---------------------------------------------------------------------------
# Reproduces the pooled/per-group failCompare::fc_fit() fits, the
# fc_obj_nll()-based NLL lookup (R/nll_lookup.R), the fc_lrt() comparison,
# and the fc_lrt_table() Word output from taglife/vitality_LRT.R, once per
# combination of `models` x `rc_values`.
#
# NOTE: the NLL lookup used here (fc_obj_nll(), R/nll_lookup.R) supports
# "vitality.ku" (via vit_nll_wrap()/failCompare::nll_vitality_ku()),
# "weibull" (nll_weibull()), and "weibull3" (nll_weibull3()). Passing any
# other `models` value will error inside fc_obj_nll().
#
# For "vitality.ku", fits are given explicit initial parameters (see
# default_vitality_inits() in safe_fc_fit() below) to work around
# vitality::vitality.ku()'s automatic initial-value heuristic, which fails
# (and previously surfaced as an opaque "model could not be fit"/NA NLL) for
# any dataset where fewer than ~half the individuals have failed by
# `rc.value`.
# ---------------------------------------------------------------------------

#' Run the pooled-vs-separate-groups LRT over a grid of models/rc.value
#'
#' @param group_data_ls A named list of numeric vectors, one per group (e.g.
#'   `list("Lot 1" = lot1_data, "Lot 2" = lot2_data, "Lot 3" = lot3_data)`).
#' @param pooled_data Numeric vector of the pooled failure times (all groups
#'   combined).
#' @param models Character vector of `model` values to pass to
#'   `failCompare::fc_fit()` (e.g. `c("vitality.ku", "weibull", "weibull3")`).
#'   The NLL lookup used for the LRT (`fc_obj_nll()`, R/nll_lookup.R)
#'   supports exactly these three model families -- see Note above.
#' @param rc_values Vector of `rc.value` arguments to pass to
#'   `failCompare::fc_fit()`. Use `NA` for an uncensored fit (passed to
#'   `fc_fit()` as `rc.value = NULL`); use a numeric threshold for a
#'   right-censored fit.
#' @param out_dir Directory in which to save one `.docx` LRT table per
#'   model/rc.value combination.
#' @param plot_diagnostics If `TRUE` (default), draw the pooled-model
#'   diagnostic plot (`plot.fc_obj`) for each combination.
#' @param SEs,... Passed through to `failCompare::fc_fit()`.
#' @return Invisibly, a named list (one element per model/rc.value
#'   combination, named `"<model>_rc<value|None>"`) each containing
#'   `pooled_mod`, `group_mods`, `lrt`, and `table_path`. Any `fc_fit()` call
#'   that fails yields `NULL` in place of the corresponding model, and that
#'   combination's `lrt`/`table_path` are also `NULL` (the LRT/table step is
#'   skipped whenever a fit is missing).
#' @export
run_vitality_lrt_grid <- function(group_data_ls,
                                   pooled_data,
                                   models = "vitality.ku",
                                   rc_values = NA,
                                   out_dir = file.path("media", "docx", "taglife"),
                                   plot_diagnostics = TRUE,
                                   SEs = TRUE,
                                   ...) {

  if (!exists("fc_obj_nll")) {
    stop("run_vitality_lrt_grid(): fc_obj_nll() not found -- source R/nll_lookup.R first.")
  }
  if (!exists("fc_lrt")) {
    stop("run_vitality_lrt_grid(): fc_lrt() not found -- source R/fc_lrt.R first.")
  }
  if (!exists("fc_lrt_table")) {
    stop("run_vitality_lrt_grid(): fc_lrt_table() not found -- source fc_lrt_table.R first.")
  }

  # vitality::vitality.ku() picks its own starting parameters by finding the
  # observed time where the survival fraction first drops below 0.5
  # (indexFinder(sfract, 0.5)). When a dataset is heavily right-censored at a
  # given rc.value (fewer than ~half its individuals have failed yet), that
  # lookup fails, vitality.ku() emits a warning ("you must supply initial r s
  # k u estimates") and returns a bare -1 instead of a fit, and
  # failCompare::fc_fit_single() then errors trying to read a par_tab out of
  # that -1. failCompare::fc_fit()'s own tryCatch swallows that real error
  # and reports only the generic "vitality.ku model could not be fit" --
  # which is what looked like a problem in nll lookup, but is actually a
  # failed *fit*, upstream of any NLL calculation.
  #
  # Fix: supply explicit initial parameters for vitality.ku fits so this
  # heuristic is never invoked. `1/median(time)` approximates vitality.ku's
  # own formula (1/time-at-50%-survival) without requiring an observed
  # failure below the 0.5 survival level.
  default_vitality_inits <- function(time) c(1 / stats::median(time), 0.1, 0.01, 0.1)

  # Attempt an fc_fit() call; return NULL (with a message) instead of
  # erroring out of the whole grid if the fit fails (e.g. "<model> model
  # could not be fit").
  #
  # For "vitality.ku", only fall back to default_vitality_inits() *after* an
  # unforced attempt fails -- vitality.ku()'s automatic heuristic, when it
  # works, tends to find a better optimum than the crude 1/median(time)
  # fallback, and forcing the fallback on every fit (even ones that would
  # have succeeded anyway) was observed to occasionally land the pooled fit
  # in a worse local optimum than the separate-group fits, violating the
  # NLL_pooled >= sum(NLL_groups) inequality required for a valid LRT.
  safe_fc_fit <- function(time, model, ..., label) {
    extra <- list(...)
    try_fit <- function(args) {
      tryCatch(do.call(failCompare::fc_fit, c(list(time = time, model = model), args)),
               error = function(e) e)
    }

    fit <- try_fit(extra)

    if (inherits(fit, "error") && model == "vitality.ku" && is.null(extra$inits)) {
      message(sprintf("  %s: automatic initial values failed (%s) -- retrying with explicit inits",
                       label, conditionMessage(fit)))
      extra$inits <- default_vitality_inits(time)
      fit <- try_fit(extra)
    }

    if (inherits(fit, "error")) {
      message(sprintf("  fit failed for %s: %s", label, conditionMessage(fit)))
      return(NULL)
    }
    fit
  }

  combos <- expand.grid(model = models, rc_value = rc_values,
                         stringsAsFactors = FALSE, KEEP.OUT.ATTRS = FALSE)

  results <- vector("list", nrow(combos))

  for (i in seq_len(nrow(combos))) {
    model_i <- combos$model[i]
    rc_i    <- combos$rc_value[i]
    rc_arg  <- if (is.na(rc_i)) NULL else rc_i

    label <- paste0(model_i, "_rc", if (is.null(rc_arg)) "None" else rc_arg)
    message("Fitting: ", label)

    pooled_mod <- safe_fc_fit(pooled_data, model = model_i, rc.value = rc_arg, SEs = SEs, ...,
                               label = paste0(label, " (pooled)"))
    group_mods <- Map(function(g_data, g_name) {
      safe_fc_fit(g_data, model = model_i, rc.value = rc_arg, SEs = SEs, ...,
                  label = paste0(label, " (", g_name, ")"))
    }, group_data_ls, names(group_data_ls))

    failed <- is.null(pooled_mod) || any(vapply(group_mods, is.null, logical(1)))

    if (failed) {
      message(sprintf("  skipping LRT/table for %s -- one or more fits failed", label))
      results[[i]] <- list(model = model_i, rc_value = rc_i, pooled_mod = pooled_mod,
                            group_mods = group_mods, lrt = NULL, table_path = NULL)
      names(results)[i] <- label
      next
    }

    nll_pooled_check <- fc_obj_nll(pooled_mod)
    nll_groups_check <- sum(sapply(group_mods, fc_obj_nll))
    message(sprintf("  sum(group NLLs) < pooled NLL: %s  (%.3f vs %.3f)",
                     nll_groups_check < nll_pooled_check, nll_groups_check, nll_pooled_check))

    if (isTRUE(plot_diagnostics)) {
      plot(pooled_mod); title(paste0("pooled (", label, ")"))
    }

    lrt <- fc_lrt(pooled_mod, group_mods)

    table_path <- file.path(out_dir, paste0("lrt_table_", label, ".docx"))
    fc_lrt_table(lrt, omnibus_label = paste0("All groups (", label, ")"), path = table_path)

    results[[i]] <- list(model = model_i, rc_value = rc_i, pooled_mod = pooled_mod,
                          group_mods = group_mods, lrt = lrt, table_path = table_path)
    names(results)[i] <- label
  }

  invisible(results)
}

#' Summarize a `run_vitality_lrt_grid()` result list as a data frame
#'
#' One row per model/rc.value combination, with columns for the `rc.value`,
#' `model`, the pooled and summed-separate-groups NLLs, the LRT chi-squared
#' statistic, its degrees of freedom, the p-value, and the pooled model's
#' MTTF (`mttf_fc_obj()`, R/nll_lookup.R) -- these columns are shared across
#' every model family and are always present. In addition, one `<param>_est`
#' / `<param>_se` pair of columns is appended per parameter of `model`
#' (looked up from `failCompare:::fc_mod_ls`), giving the pooled model's
#' fitted parameter estimates and standard errors; these columns differ
#' across model families (e.g. `r_est`/`s_est`/... for `"vitality.ku"` vs.
#' `shape_est`/`scale_est` for `"weibull"`), so when combining summaries
#' across models, subset to the shared columns first, e.g.:
#' `common <- Reduce(intersect, lapply(summary_list, names))`.
#' Combinations where any `fc_fit()` call failed (`lrt` is `NULL`) appear as
#' a row of `NA`s in every column.
#'
#' @param results A named list as returned by `run_vitality_lrt_grid()`.
#' @return A data frame with columns `label`, `model`, `rc_value`,
#'   `nll_pooled`, `nll_groups_sum`, `chi_sq`, `df`, `p_value`, `mttf`, plus
#'   one `<param>_est`/`<param>_se` pair of columns per model parameter.
#' @export
summarize_vitality_lrt_grid <- function(results) {
  rows <- lapply(names(results), function(label) {
    res        <- results[[label]]
    lrt        <- res$lrt
    pooled_mod <- res$pooled_mod

    base <- data.frame(
      label          = label,
      model          = res$model,
      rc_value       = res$rc_value,
      nll_pooled     = if (is.null(lrt)) NA_real_ else lrt$nll_pooled,
      nll_groups_sum = if (is.null(lrt)) NA_real_ else lrt$nll_groups_sum,
      chi_sq         = if (is.null(lrt)) NA_real_ else lrt$statistic,
      df             = if (is.null(lrt)) NA_integer_ else lrt$df,
      p_value        = if (is.null(lrt)) NA_real_ else lrt$p_value,
      mttf           = if (is.null(pooled_mod)) NA_real_ else mttf_fc_obj(pooled_mod),
      stringsAsFactors = FALSE
    )

    # Pooled-model parameter estimates/SEs, one pair of columns per
    # parameter. Parameter names come from failCompare's own catalog (not
    # the fit itself) so a failed fit still yields NA-filled columns of the
    # right shape/name.
    # Indexed positionally, not by rowname: failCompare's par_tab has named
    # rows for weibull/weibull3 fits but not for vitality.ku fits, so
    # rowname lookup isn't reliable across model families.
    par_names <- failCompare:::fc_mod_ls[[res$model]]
    if (!is.null(par_names)) {
      par_tab <- pooled_mod$par_tab
      est <- if (is.null(par_tab)) rep(NA_real_, length(par_names)) else par_tab[seq_along(par_names), 1]
      se  <- if (is.null(par_tab)) rep(NA_real_, length(par_names)) else par_tab[seq_along(par_names), 2]

      par_df <- as.data.frame(
        setNames(as.list(c(est, se)), c(paste0(par_names, "_est"), paste0(par_names, "_se"))),
        stringsAsFactors = FALSE
      )
      base <- cbind(base, par_df)
    }

    base
  })
  do.call(rbind, rows)
}
