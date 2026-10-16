# ---------------------------------------------------------------------------
# fc_nll(): extract the correct negative log-likelihood from an fc_obj
# ---------------------------------------------------------------------------
# Background / rationale
# -----------------------
# failCompare::fc_fit() fits vitality.ku / vitality.4p models by calling
# vitality::vitality.ku()/vitality.4p() on the *raw, per-individual* failure
# times (`y`) and their empirical survival fractions (`y_sfrac`), e.g.:
#
#   vitality::vitality.ku(time = sort(y), sdata = y_sfrac, rc.data = rc, ...)
#
# Internally, vitality.ku() never uses the raw survival-fraction curve as the
# likelihood weights. It first runs the curve through vitality:::dataPrep(),
# which converts cumulative survival fractions into per-interval death
# fractions (`Ni <- sfract1 - sfract2`, summing to 1) -- these, not the raw
# survival fractions, are what get passed as `NNi` to
# vitality:::logLikelihood.ku()/logLikelihood.4p(). That function computes
#
#   sum(-NNi * log(survival-probability-of-interval))
#
# which -- despite the internal variable being named `loglklhd` -- is a
# NEGATIVE log-likelihood: it is exactly what vitality.ku() minimizes with
# nlminb() and reports as "minimum -loglikelihood value".
#
# fc_fit() does not store this NLL anywhere in the returned fc_obj. To get it
# back out, you must reproduce the same data preparation step (dataPrep) with
# the same time/survival-fraction/censoring info stored in the fc_obj, then
# evaluate the model's own logLikelihood.* function at the fitted parameters.
# Doing this ensures NLLs computed for a pooled fit and for fits to subgroups
# are directly comparable and additive, so that for nested models:
#
#   NLL_pooled >= NLL_group1 + NLL_group2 + ... + NLL_groupK
#
# always holds (as required for a valid likelihood-ratio test), because the
# "separate fits" model is a strict generalization of the pooled model.
#
# For flexsurv-based models (weibull, weibull3, gompertz, gamma, lognormal,
# llogis, gengamma), fc_fit() stores the maximized log-likelihood directly in
# fc_obj$mod_objs$loglik (a flexsurvreg object), so NLL = -loglik there; no
# recomputation is needed.
#
# A second, more subtle scale issue affects vitality.ku/4p specifically:
# dataPrep() normalizes `Ni` to sum to 1 *within each dataset*, regardless of
# how many individuals it contains. That is fine for optimizing a single
# model (the normalization constant doesn't affect where the minimum falls),
# but it means the raw NLL values returned by vitality.ku()/vitality.4p() for
# a small subgroup and for the full pooled sample are on *different absolute
# scales* -- summing them directly does not give a like-for-like comparison,
# and the nesting inequality (NLL_pooled >= sum of group NLLs) can appear to
# fail purely because of this normalization, not because a fit is wrong.
# Multiplying each dataset's NLL by its own sample size N converts the
# normalized (per-unit-probability-mass) NLL back into an absolute,
# additive log-likelihood scale, so that fitted subgroups and the pooled fit
# become directly comparable and summable. This is done by default below
# (`scale = TRUE`); set `scale = FALSE` to recover the raw, unscaled value
# that vitality.ku()/vitality.4p() itself reports as the
# "minimum -loglikelihood value".
#
# "kaplan-meier" fits are non-parametric and have no comparable likelihood in
# this framework, so fc_nll() errors for them.
# ---------------------------------------------------------------------------

#' Extract the negative log-likelihood implied by an `fc_obj` fit
#'
#' @param fc_obj An object of class `fc_obj`, as returned by
#'   `failCompare::fc_fit()`.
#' @param scale For `vitality.ku`/`vitality.4p` fits only: if `TRUE`
#'   (default), scale the NLL by the fit's sample size so that it is on an
#'   absolute, additive log-likelihood scale comparable across differently
#'   sized datasets (required for likelihood-ratio comparisons across groups
#'   of unequal size). If `FALSE`, return the raw, sample-size-normalized
#'   value as reported internally by vitality.ku()/vitality.4p().
#' @return A single numeric value: the negative log-likelihood at the fitted
#'   parameters, computed the same way the underlying model optimizer did.
#' @export
fc_nll <- function(fc_obj, scale = TRUE) {
  if (!inherits(fc_obj, "fc_obj")) {
    stop("fc_nll() expects an object of class 'fc_obj' (from failCompare::fc_fit()).")
  }

  mod_choice <- fc_obj$mod_choice

  if (mod_choice %in% c("vitality.ku", "vitality.4p")) {

    suffix <- sub("^vitality\\.", "", mod_choice)  # "ku" or "4p"
    loglik_fn <- getFromNamespace(paste0("logLikelihood.", suffix), "vitality")
    dataPrep  <- getFromNamespace("dataPrep", "vitality")

    time  <- fc_obj$times$time
    sdata <- fc_obj$times$surv_frac
    # fc_fit() passes rc.data = TRUE/FALSE (never "TF") when it calls
    # vitality.ku()/vitality.4p(); fc_obj$censored records which was used.
    rc.data <- isTRUE(fc_obj$censored)

    prep <- dataPrep(time = time, sdata = sdata, datatype = "CUM", rc.data = rc.data)

    params <- fc_obj$par_tab[, "params"]

    nll <- loglik_fn(par = params, xx1 = prep$x1, xx2 = prep$x2, NNi = prep$Ni)
    nll <- as.numeric(nll)
    if (scale) nll <- nll * nrow(fc_obj$times)
    return(nll)

  } else if (mod_choice == "kaplan-meier") {

    stop("fc_nll(): 'kaplan-meier' fits are non-parametric; no comparable likelihood is available.")

  } else {
    # flexsurv-backed parametric models: weibull, weibull3, gompertz, gamma,
    # lognormal, llogis, gengamma
    ll <- fc_obj$mod_objs$loglik
    if (is.null(ll)) {
      stop(sprintf("fc_nll(): could not find a log-likelihood for mod_choice = '%s'.", mod_choice))
    }
    return(-as.numeric(ll))
  }
}

#' Sum the negative log-likelihoods of several fc_obj fits
#'
#' Convenience wrapper for the "separate group models" side of a
#' likelihood-ratio comparison against a pooled fc_obj fit.
#'
#' @param ... One or more `fc_obj` objects, or a single list of them.
#' @param scale Passed to [fc_nll()]; keep at the default `TRUE` for valid
#'   likelihood-ratio comparisons.
#' @return The summed negative log-likelihood.
#' @export
fc_nll_sum <- function(..., scale = TRUE) {
  objs <- list(...)
  if (length(objs) == 1 && is.list(objs[[1]]) && !inherits(objs[[1]], "fc_obj")) {
    objs <- objs[[1]]
  }
  sum(vapply(objs, fc_nll, numeric(1), scale = scale))
}


