# Function: Compute Kaplan-Meier survival curves (no censoring)
compute_km_survival <- function(times) {
  n <- length(times)
  sorted_times <- sort(times)
  surv_frac <- (n - seq_along(sorted_times)) / n
  data.frame(time = sorted_times, survival = surv_frac)
}

# Function: Compute Kaplan-Meier survival curves with right censoring
compute_km_survival_censored <- function(times, rc.cutoff = 75) {
  n <- length(times)
  
  # Mark observations: 0 = censored (time > rc.cutoff), 1 = event (time <= rc.cutoff)
  event <- as.numeric(times <= rc.cutoff)
  
  print(event)
  # Truncate times at rc.cutoff
  times_truncated <- pmin(times, rc.cutoff)
  
  # Sort and compute survival
  sorted_idx <- order(times_truncated)
  sorted_times <- times_truncated[sorted_idx]
  sorted_events <- event[sorted_idx]
  
  # Compute Kaplan-Meier survival accounting for censoring
  km_data <- data.frame(time = sorted_times, event = sorted_events)
  km_unique <- unique(km_data)
  
  n_risk <- numeric(nrow(km_unique))
  n_event <- numeric(nrow(km_unique))
  
  for (i in seq_along(n_risk)) {
    n_risk[i] <- sum(km_unique$time[i] <= km_data$time)
    n_event[i] <- sum(km_unique$time[i] == km_data$time & km_data$event == 1)
  }
  
  # Calculate survival probability
  surv_prob <- cumprod((n_risk - n_event) / n_risk)
  
  data.frame(time = km_unique$time, survival = surv_prob)
}
