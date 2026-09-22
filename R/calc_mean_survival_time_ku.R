#' Calculate Mean Survival Time from Vitality.ku Parameters
#'
#' Calculates the mean survival time (area under the survival curve) based on
#' vitality.ku model parameters (r, s, k, u). Uses the mathematical definition
#' of mean survival time as the integral of the survival function.
#'
#' @param params A named vector with elements r, s, k, and u (vitality.ku parameters)
#' @param time_max Maximum time for integration (default: 100)
#' @param n_points Number of time points for numerical integration (default: 1001)
#'   Higher values give more accurate results
#'
#' @return A list containing:
#'   - mst: Mean survival time
#'   - time_seq: Time sequence used for integration
#'   - survival_probs: Corresponding survival probabilities
#'
#' @details
#' The vitality.ku model specifies the force of mortality as:
#' \deqn{\mu(t) = r + s \cdot t + k \cdot e^{u \cdot t}}
#'
#' The survival function is:
#' \deqn{S(t) = \exp\left(-\int_0^t \mu(x) dx\right)}
#'
#' Mean survival time is calculated as:
#' \deqn{MST = \int_0^{\infty} S(t) dt}
#'
#' In practice, we integrate to a finite time_max where S(t) is negligibly small.
#'
#' @examples
#' # Define vitality.ku parameters
#' pars <- c(r = 0.02, s = 0.01, k = 0.005, u = 0.1)
#'
#' # Calculate mean survival time
#' result <- calc_mean_survival_time_ku(pars)
#' result$mst
#'
#' # With custom time range
#' result <- calc_mean_survival_time_ku(pars, time_max = 80, n_points = 2001)
#' result$mst
#'
#' @export

calc_mean_survival_time_ku <- function(params, time_max = 100, n_points = 1001) {
  
  # Validate input
  required_params <- c("r", "s", "k", "u")
  if (!all(required_params %in% names(params))) {
    missing <- setdiff(required_params, names(params))
    stop("Missing parameters: ", paste(missing, collapse = ", "))
  }
  
  r <- params["r"]
  s <- params["s"]
  k <- params["k"]
  u <- params["u"]
  
  # Create time sequence
  time_seq <- seq(0, time_max, length.out = n_points)
  
  # Calculate survival probability at each time point
  # For vitality.ku: S(t) = exp(-integral)
  # where integral = r*t + s*t^2/2 + k/u*(exp(u*t) - 1)
  integral <- r * time_seq + s * time_seq^2 / 2 + (k / u) * (exp(u * time_seq) - 1)
  survival_probs <- exp(-integral)
  
  # Calculate mean survival time using trapezoidal rule for numerical integration
  mst <- sum(diff(time_seq) * (survival_probs[-1] + survival_probs[-length(survival_probs)]) / 2)
  
  # Return results
  return(list(
    mst = mst,
    time_seq = time_seq,
    survival_probs = survival_probs
  ))
}
