# ---------------------------------------------------------------------------
# patch_fc_fit.R: attach $nll and $nll_n_adj to failCompare::fc_fit() output
# ---------------------------------------------------------------------------
# Extends every failCompare::fc_fit() call (including namespace-qualified
# calls, i.e. `failCompare::fc_fit(...)`) to attach two fields to the
# returned fc_obj:
#
#   $nll        The raw negative log-likelihood, as reported internally by
#               the fitted model. For vitality.ku/vitality.4p this is the
#               value vitality.ku()/vitality.4p() itself minimizes and
#               prints as "minimum -loglikelihood value" -- it is normalized
#               to sum to 1 *within this dataset* and is NOT comparable
#               across differently-sized groups. For flexsurv-backed models
#               (weibull, gompertz, etc.) it is already an absolute value
#               (-mod_objs$loglik). This is the field earlier versions of
#               this project's scripts assumed fc_fit() already provided.
#
#   $nll_n_adj  The sample-size-adjusted version (see fc_nll.R for the full
#               rationale): for vitality.ku/4p, $nll * sample size, putting
#               it on an absolute, additive log-likelihood scale so that
#               NLLs from different-sized fits can be validly summed/compared
#               (required for correct likelihood-ratio tests across groups
#               of unequal size). For flexsurv-backed models, $nll_n_adj is
#               identical to $nll (already absolute).
#
# LIMITATION: only single-model fits (class "fc_obj", e.g.
# `model = "vitality.ku"`) are extended. Multi-model fits (class "fc_list",
# e.g. `model = "all"`) are returned unmodified -- fc_select() strips
# information (mod_objs, par_tab column names) that fc_nll() needs to score
# each model, so a per-model version is not currently supported.
#
# Usage: source fc_nll.R, then this file, once per session, before calling
# failCompare::fc_fit().
# ---------------------------------------------------------------------------

if (!exists("fc_nll")) stop("Source fc_nll.R before patch_fc_fit.R (fc_nll() is required).")
if (!"failCompare" %in% loadedNamespaces()) library(failCompare)

# Capture the *unpatched* fc_fit exactly once, even if this file is sourced
# more than once in a session, so we never wrap the wrapper around itself.
if (!exists(".fc_fit_original", inherits = FALSE)) {
  .fc_fit_original <- failCompare::fc_fit
}

fc_fit_with_nll <- function(...) {
  obj <- .fc_fit_original(...)

  if (inherits(obj, "fc_obj")) {
    obj$nll       <- tryCatch(fc_nll(obj, scale = FALSE), error = function(e) NA_real_)
    obj$nll_n_adj <- tryCatch(fc_nll(obj, scale = TRUE),  error = function(e) NA_real_)
  } else if (inherits(obj, "fc_list")) {
    message("fc_fit(): multi-model fit (fc_list) returned without $nll/$nll_n_adj ",
            "-- not supported when fitting multiple models in one call.")
  }

  obj
}

assignInNamespace("fc_fit", fc_fit_with_nll, ns = "failCompare")
message("failCompare::fc_fit() patched: fc_obj results now include $nll and $nll_n_adj.")
