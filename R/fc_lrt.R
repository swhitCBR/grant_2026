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