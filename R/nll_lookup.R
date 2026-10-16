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

#' NLL of a fitted three-parameter (threshold) Weibull model
#'
#' Mirrors `failCompare::nll_vitality_ku()`: computes the exact, additive
#' negative log-likelihood of `data_time`/`non_cen` at `params`, using the
#' analytic three-parameter Weibull survival function (the same formula
#' `failCompare:::fc_pred()` uses for `model = "weibull3"`) and a
#' finite-difference derivative to get the density.
#'
#' @param params Numeric vector `c(shape, thrsh, scale)`.
#' @inheritParams nll_weibull
#' @return A single numeric NLL (or a data frame if `indiv_nll = TRUE`).
#' @export
nll_weibull3 <- function(params, data_time, non_cen, indiv_nll = FALSE) {
  shape <- params[1]
  thrsh <- params[2]
  scale <- params[3]
  if (shape <= 0 || scale <= 0) return(Inf)

  surv_fn <- function(t) {
    tmp <- exp(-((t - thrsh) / scale)^shape)
    tmp[is.na(tmp)] <- 1
    tmp
  }

  St    <- surv_fn(data_time)
  dt    <- 1e-05
  St_dt <- surv_fn(data_time + dt)

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
  mttf(params = fc_obj_in$par_tab[, 1], model = fc_obj_in$mod_choice)
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
