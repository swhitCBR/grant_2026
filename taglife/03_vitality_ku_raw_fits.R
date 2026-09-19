library(vitality)

csv_fl_ls <- readRDS("data/clean/csv_fl_ls.rds")
taglife_rawDF <- csv_fl_ls$GPUD2026_taglife_17Aug2026

# Extract failure times by lot
lot1_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 1"]
lot2_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 2"]
lot3_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 3"]
pooled_data <- taglife_rawDF$days_difference

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

# ============================================================================
# NON-CENSORED FITS (all data)
# ============================================================================

lot1_km_nc <- compute_km_survival(lot1_data)
lot2_km_nc <- compute_km_survival(lot2_data)
lot3_km_nc <- compute_km_survival(lot3_data)
pooled_km_nc <- compute_km_survival(pooled_data)

lot1_fit_nc <- vitality.ku(
  time = lot1_km_nc$time,
  sdata = lot1_km_nc$survival,
  rc.data = FALSE,
  se = length(lot1_data),
  pplot = FALSE,
  silent = TRUE
)

lot2_fit_nc <- vitality.ku(
  time = lot2_km_nc$time,
  sdata = lot2_km_nc$survival,
  rc.data = FALSE,
  se = length(lot2_data),
  pplot = FALSE,
  silent = TRUE
)

lot3_fit_nc <- vitality.ku(
  time = lot3_km_nc$time,
  sdata = lot3_km_nc$survival,
  rc.data = FALSE,
  se = length(lot3_data),
  pplot = FALSE,
  silent = TRUE
)

pooled_fit_nc <- vitality.ku(
  time = pooled_km_nc$time,
  sdata = pooled_km_nc$survival,
  rc.data = FALSE,
  se = length(pooled_data),
  pplot = FALSE,
  silent = TRUE
)

# ============================================================================
# CENSORED FITS (observations > 75 days censored)
# ============================================================================

lot1_km_c <- compute_km_survival_censored(lot1_data, rc.cutoff = 75)
lot2_km_c <- compute_km_survival_censored(lot2_data, rc.cutoff = 75)
lot3_km_c <- compute_km_survival_censored(lot3_data, rc.cutoff = 75)
pooled_km_c <- compute_km_survival_censored(pooled_data, rc.cutoff = 75)

lot1_fit_c <- vitality.ku(
  time = lot1_km_c$time,
  sdata = lot1_km_c$survival,
  rc.data = TRUE,
  se = length(lot1_data),
  pplot = FALSE,
  silent = TRUE
)

lot2_fit_c <- vitality.ku(
  time = lot2_km_c$time,
  sdata = lot2_km_c$survival,
  rc.data = TRUE,
  se = length(lot2_data),
  pplot = FALSE,
  silent = TRUE
)

lot3_fit_c <- vitality.ku(
  time = lot3_km_c$time,
  sdata = lot3_km_c$survival,
  rc.data = TRUE,
  se = length(lot3_data),
  pplot = FALSE,
  silent = TRUE
)

pooled_fit_c <- vitality.ku(
  time = pooled_km_c$time,
  sdata = pooled_km_c$survival,
  rc.data = TRUE,
  se = length(pooled_data),
  pplot = FALSE,
  silent = TRUE
)

# ============================================================================
# DISPLAY RESULTS AND COMPARISONS
# ============================================================================

cat("=============================================================================\n")
cat("NON-CENSORED FITS (all data, full mortality)\n")
cat("=============================================================================\n\n")

cat("Lot 1 - vitality.ku (non-censored):\n")
print(lot1_fit_nc)
cat("\nLot 2 - vitality.ku (non-censored):\n")
print(lot2_fit_nc)
cat("\nLot 3 - vitality.ku (non-censored):\n")
print(lot3_fit_nc)
cat("\nPooled - vitality.ku (non-censored):\n")
print(pooled_fit_nc)

cat("\n=============================================================================\n")
cat("CENSORED FITS (observations > 75 days censored)\n")
cat("=============================================================================\n\n")

cat("Lot 1 - vitality.ku (censored at 75 days):\n")
print(lot1_fit_c)
cat("\nLot 2 - vitality.ku (censored at 75 days):\n")
print(lot2_fit_c)
cat("\nLot 3 - vitality.ku (censored at 75 days):\n")
print(lot3_fit_c)
cat("\nPooled - vitality.ku (censored at 75 days):\n")
print(pooled_fit_c)

# Create comparison tables
cat("\n=============================================================================\n")
cat("PARAMETER ESTIMATES COMPARISON\n")
cat("=============================================================================\n\n")

comparison_nc <- data.frame(
  Parameter = c("r", "s", "k", "u"),
  Lot1_NC = lot1_fit_nc[, 1],
  Lot2_NC = lot2_fit_nc[, 1],
  Lot3_NC = lot3_fit_nc[, 1],
  Pooled_NC = pooled_fit_nc[, 1],
  Lot1_C = lot1_fit_c[, 1],
  Lot2_C = lot2_fit_c[, 1],
  Lot3_C = lot3_fit_c[, 1],
  Pooled_C = pooled_fit_c[, 1]
)

cat("Non-Censored (NC) vs. Censored at 75 days (C):\n")
print(comparison_nc)

# Calculate percent differences
cat("\n=============================================================================\n")
cat("PERCENT DIFFERENCE: Censored vs. Non-Censored (%)\n")
cat("=============================================================================\n\n")

pct_diff <- data.frame(
  Parameter = c("r", "s", "k", "u"),
  Lot1 = 100 * (lot1_fit_c[, 1] - lot1_fit_nc[, 1]) / lot1_fit_nc[, 1],
  Lot2 = 100 * (lot2_fit_c[, 1] - lot2_fit_nc[, 1]) / lot2_fit_nc[, 1],
  Lot3 = 100 * (lot3_fit_c[, 1] - lot3_fit_nc[, 1]) / lot3_fit_nc[, 1],
  Pooled = 100 * (pooled_fit_c[, 1] - pooled_fit_nc[, 1]) / pooled_fit_nc[, 1]
)

print(pct_diff)
