# ---------------------------------------------------------------------------
# run_mult_rc_lrt(): pooled-vs-separate-groups LRT across a grid of
# fc_fit() `model` and `rc.value` arguments (no docx output by default)
# ---------------------------------------------------------------------------
# Reproduces the pooled/per-group failCompare::fc_fit() fits, the
# fc_obj_nll()-based NLL lookup (R/nll_lookup.R), and the fc_lrt() comparison
# from taglife/vitality_LRT.R, once per combination of `models` x `rc_values`.
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
#'   right-censored fit. Ignored if `rc_count_back` is specified.
#' @param rc_count_back Integer (1 to length(pooled_data)) specifying the nth-to-last
#'   sorted values from `pooled_data` to use as `rc_values`. When provided,
#'   overrides `rc_values`. Example: `rc_count_back = 69` uses the last 69
#'   ordered values from `pooled_data`.
#' @param plot If `TRUE` (default), draw the pooled-model diagnostic plot
#'   (`plot.fc_obj`) for each combination.
#' @param silent If `TRUE` (default `FALSE`), suppress printed output messages.
#' @param SEs,... Passed through to `failCompare::fc_fit()`.
#' @return Invisibly, a named list (one element per model/rc.value
#'   combination, named `"<model>_rc<value|None>"`) each containing
#'   `pooled_mod`, `group_mods`, and `lrt`. Any `fc_fit()` call
#'   that fails yields `NULL` in place of the corresponding model, and that
#'   combination's `lrt` is also `NULL` (the LRT step is skipped whenever a 
#'   fit is missing).
#' @export
run_mult_rc_lrt <- function(group_data_ls,
                            pooled_data,
                            models = "vitality.ku",
                            rc_values = NA,
                            rc_count_back = NULL,
                            plot = TRUE,
                            silent = TRUE,
                            SEs = TRUE,
                            ...) {

  # if (!exists("fc_obj_nll")) {
  #   stop("run_mult_rc_lrt(): fc_obj_nll() not found -- source R/nll_lookup.R first.")
  # }
  # if (!exists("fc_lrt")) {
  #   stop("run_mult_rc_lrt(): fc_lrt() not found -- source R/fc_lrt.R first.")
  # }
  
  # Helper to conditionally print messages
  msg <- function(...) if (!silent) message(...)
  # Override rc_values with rc_count_back if provided
  rc_count_back_used <- !is.null(rc_count_back)
  if (rc_count_back_used) {
    if (rc_count_back < 1 || rc_count_back > length(pooled_data)) {
      stop("rc_count_back must be between 1 and length(pooled_data)")
    }
    rc_values <- sort(pooled_data)[(length(pooled_data) - rc_count_back + 1):length(pooled_data)]
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
      msg(sprintf("  %s: automatic initial values failed (%s) -- retrying with explicit inits",
                       label, conditionMessage(fit)))
      extra$inits <- default_vitality_inits(time)
      fit <- try_fit(extra)
    }

    if (inherits(fit, "error")) {
      msg(sprintf("  fit failed for %s: %s", label, conditionMessage(fit)))
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

    # Calculate position in rc_values for n_back display
    rc_position <- if (rc_count_back_used && !is.null(rc_arg)) {
      which(rc_values == rc_arg)[1]
    } else {
      NA
    }

    label <- paste0(model_i, "_rc", if (is.null(rc_arg)) "None" else rc_arg)
    msg("Fitting: ", label)

    pooled_mod <- safe_fc_fit(pooled_data, model = model_i, rc.value = rc_arg, SEs = SEs, ...,
                               label = paste0(label, " (pooled)"))
    group_mods <- Map(function(g_data, g_name) {
      safe_fc_fit(g_data, model = model_i, rc.value = rc_arg, SEs = SEs, ...,
                  label = paste0(label, " (", g_name, ")"))
    }, group_data_ls, names(group_data_ls))

    failed <- is.null(pooled_mod) || any(vapply(group_mods, is.null, logical(1)))

    if (failed) {
      msg(sprintf("  skipping LRT for %s -- one or more fits failed", label))
      results[[i]] <- list(model = model_i, rc_value = rc_i, n_back = rc_position,
                            pooled_mod = pooled_mod, group_mods = group_mods, lrt = NULL)
      names(results)[i] <- label
      next
    }

    nll_pooled_check <- fc_obj_nll(pooled_mod)
    nll_groups_check <- sum(sapply(group_mods, fc_obj_nll))
    msg(sprintf("  sum(group NLLs) < pooled NLL: %s  (%.3f vs %.3f)",
                     nll_groups_check < nll_pooled_check, nll_groups_check, nll_pooled_check))

    if (isTRUE(plot)) {
      # Round rc_value to tenths place for plot label
      rc_rounded <- if (is.null(rc_arg)) "None" else round(rc_arg, 1)
      title_suffix <- if (rc_count_back_used && !is.na(rc_position)) {
        paste0(" [n_back=", rc_position, "]")
      } else {
        ""
      }
      plot(pooled_mod); title(paste0("pooled (", model_i, "_rc", rc_rounded, ")", title_suffix))
    }

    lrt <- fc_lrt(pooled_mod, group_mods)

    results[[i]] <- list(model = model_i, rc_value = rc_i, n_back = rc_position,
                          pooled_mod = pooled_mod, group_mods = group_mods, lrt = lrt)
    names(results)[i] <- label
  }

  invisible(results)
}

#' Summarize a `run_mult_rc_lrt()` result list as a data frame
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
#' @param results A named list as returned by `run_mult_rc_lrt()`.
#' @return A data frame with columns `label`, `model`, `rc_value`,
#'   `nll_pooled`, `nll_groups_sum`, `chi_sq`, `df`, `p_value`, `mttf`, plus
#'   one `<param>_est`/`<param>_se` pair of columns per model parameter.
#' @export
summarize_mult_rc_lrt <- function(results) {
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


summarize_mult_lrt_grid <- function(results) {
  rows <- lapply(names(results), function(label) {
    res        <- results[[label]]
    lrt        <- res$lrt
    pooled_mod <- res$pooled_mod
    
    base <- data.frame(
      model          = res$model,
      rc_value       = res$rc_value,
      n_back         = res$n_back,
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
  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  result
}

# Get the nth to last ordered element(s) from a vector (n between 1 and length(vec))
get_nth_to_last_sorted <- function(vec, n) {
  if (n < 1 || n > length(vec)) {
    stop("n must be between 1 and length(vec)")
  }
  sort(vec)[(length(vec) - n + 1):length(vec)]
}



# ---------------------------------------------------------------------------
# nll_weibull() / nll_weibull3() / fc_obj_nll(): NLL lookups for fc_fit()
# models, in the same style as failCompare::nll_vitality_ku()
# ---------------------------------------------------------------------------
# failCompare::nll_vitality_ku(params, data_time, non_cen) computes an exact,
# additive negative log-likelihood for a "vitality.ku" fit by: evaluating the
# fitted survival curve S(t) at each observed time, numerically
# differentiating it (finite difference, dt = 1e-5) to get the density f(t),
# and summing -log(f(t)) for uncensored observations / -log(S(t)) for
# right-censored ones. Because this sums per-individual log-likelihood terms
# directly (rather than normalizing over the dataset, as
# vitality::vitality.ku()'s internal objective does), NLLs computed this way
# are already on a comparable, additive scale across differently-sized
# datasets -- exactly what's needed for a valid likelihood-ratio test.
#
# nll_weibull() and nll_weibull3() below apply the identical recipe to the
# "weibull" and "weibull3" models fc_fit() can also produce, using their
# analytic survival functions (the same ones failCompare:::fc_pred() uses)
# in place of vitality::SurvFn.ku(). fc_obj_nll() dispatches an `fc_obj` (as
# returned by failCompare::fc_fit()) to the right one of these three
# functions based on `fc_obj$mod_choice`, pulling `data_time`/`non_cen` from
# `fc_obj$times` and the fitted parameters from `fc_obj$par_tab[, 1]` (the
# point-estimate column -- note failCompare labels this column "params" for
# vitality.ku/weibull3 fits but "est" for weibull fits, so it's addressed
# positionally rather than by name).
# ---------------------------------------------------------------------------

#' NLL of a fitted two-parameter Weibull model, given arbitrary parameters
#'
#' Mirrors `failCompare::nll_vitality_ku()`: computes the exact, additive
#' negative log-likelihood of `data_time`/`non_cen` at `params`, using the
#' analytic Weibull survival function and a finite-difference derivative to
#' get the density.
#'
#' @param params Numeric vector `c(shape, scale)`.
#' @param data_time Numeric vector of observed (possibly right-censored)
#'   failure times.
#' @param non_cen Logical (or 0/1) vector, same length as `data_time`: `TRUE`
#'   for an observed failure, `FALSE` for a right-censored observation.
#' @param indiv_nll If `TRUE`, return a data frame of per-observation NLLs
#'   instead of the summed total.
#' @return A single numeric NLL (or a data frame if `indiv_nll = TRUE`).
#' @export
nll_weibull <- function(params, data_time, non_cen, indiv_nll = FALSE) {
  shape <- params[1]
  scale <- params[2]
  if (shape <= 0 || scale <= 0) return(Inf)
  
  St    <- 1 - stats::pweibull(data_time,      shape = shape, scale = scale)
  dt    <- 1e-05
  St_dt <- 1 - stats::pweibull(data_time + dt, shape = shape, scale = scale)
  
  ft <- -(St_dt - St) / dt
  ft <- pmax(ft, 1e-10)
  St <- pmax(St, 1e-10)
  
  ll <- non_cen * log(ft) + (1 - non_cen) * log(St)
  
  if (indiv_nll) {
    return(data.frame(data_time, nll = -ll, non_cen))
  }
  -sum(ll)
}


#' Mean time to failure implied by a fitted model's parameters
#'
#' For `"weibull"`/`"weibull3"` this is the closed-form Weibull mean
#' (`scale * gamma(1 + 1/shape)`, shifted by `thrsh` for `"weibull3"`). For
#' `"vitality.ku"`, which has no closed-form mean, this numerically
#' integrates the fitted survival function (`vitality::SurvFn.ku()`) from 0
#' to `Inf` (`MTTF = integral of S(t) dt`, valid for any nonnegative failure
#' time).
#'
#' @param params Numeric vector of fitted parameters, in the same order as
#'   `failCompare:::fc_mod_ls[[model]]`.
#' @param model One of `"vitality.ku"`, `"weibull"`, `"weibull3"`.
#' @return A single numeric MTTF, in the same time units as the fitted data.
#' @export
mttf <- function(params, model) {
  switch(model,
         "weibull"  = params[2] * gamma(1 + 1 / params[1]),
         "weibull3" = params[2] + params[3] * gamma(1 + 1 / params[1]),
         "vitality.ku" = {
           surv_fn <- function(t) vitality::SurvFn.ku(xx = t, r = params[1], s = params[2], k = params[3], u = params[4])
           integrate(surv_fn, lower = 0, upper = Inf, stop.on.error = FALSE)$value
         },
         stop(sprintf("mttf(): no MTTF calculation defined for model '%s' (supported: vitality.ku, weibull, weibull3).", model))
  )
}

#' MTTF implied by a fitted `fc_obj`'s parameters
#'
#' Convenience wrapper around `mttf()` that pulls `model` and the
#' point-estimate parameters directly from an `fc_obj` (as returned by
#' `failCompare::fc_fit()`).
#'
#' @param fc_obj_in An `fc_obj`.
#' @return A single numeric MTTF.
#' @export
mttf_fc_obj <- function(fc_obj_in) {
  out <- mttf(params = fc_obj_in$par_tab[, 1], model = fc_obj_in$mod_choice)
  names(out)="mttf"
  return(out)
}

#' Dispatch an `fc_obj` fit to the right NLL lookup function
#'
#' Generalizes `vit_nll_wrap()` (which only supports `"vitality.ku"`) to also
#' cover `"weibull"` and `"weibull3"` fits, using `nll_weibull()` /
#' `nll_weibull3()` above.
#'
#' @param fc_obj_in An `fc_obj`, as returned by `failCompare::fc_fit()`.
#' @return A single numeric NLL, on the same additive scale for every
#'   supported model (comparable/summable across pooled and per-group fits).
#' @export
fc_obj_nll <- function(fc_obj_in) {
  model      <- fc_obj_in$mod_choice
  data_time  <- fc_obj_in$times$time
  non_cen    <- fc_obj_in$times$non_cen
  params     <- fc_obj_in$par_tab[, 1]  # point-estimate column ("params" or "est")
  
  switch(model,
         "vitality.ku" = failCompare::nll_vitality_ku(params = params, data_time = data_time, non_cen = non_cen),
         "weibull"     = nll_weibull(params = params, data_time = data_time, non_cen = non_cen),
         "weibull3"    = nll_weibull3(params = params, data_time = data_time, non_cen = non_cen),
         stop(sprintf("fc_obj_nll(): no NLL lookup defined for model '%s' (supported: vitality.ku, weibull, weibull3).", model))
  )
}


#' Likelihood-ratio test comparing a pooled fc_obj fit to separate-group fits
#'
#' @param pooled_obj An `fc_obj` fit to the pooled/combined data (the
#'   restricted model).
#' @param sub_obj_ls A list of `fc_obj` fits, one per group, all using the
#'   same model as `pooled_obj` (the unrestricted model).
#' @return A list with the two NLLs, the LRT chi-squared statistic, degrees
#'   of freedom, and p-value.
#' @export
fc_lrt <- function(pooled_obj, sub_obj_ls) {
  # n_par <- length(failCompare:::fc_mod_ls[[pooled_obj$mod_choice]])
  n_par <- nrow(pooled_obj$par_tab)
  # fc_obj_nll() (R/nll_lookup.R) dispatches on mod_choice, generalizing
  # vit_nll_wrap()/failCompare::nll_vitality_ku() (vitality.ku-only) to also
  # cover weibull/weibull3 fits.
  nll_pooled <- fc_obj_nll(pooled_obj)
  nll_groups <- sum(sapply(sub_obj_ls,fc_obj_nll))
  
  df <- (length(sub_obj_ls) - 1) * n_par
  stat <- 2 * (nll_pooled - nll_groups)  # NLLs: restricted minus unrestricted, no leading minus
  p_value <- pchisq(stat, df = df, lower.tail = FALSE)
  
  list(
    nll_pooled = nll_pooled,
    nll_groups_sum = nll_groups,
    statistic = stat,
    df = df,
    p_value = p_value
  )
}