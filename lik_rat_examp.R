# Install and load the vitality package
# install.packages("vitality")
library(vitality)

# ---------------------------------------------------------
# Step 1: Generate Mock Cumulative Survival Proportions
# ---------------------------------------------------------
set.seed(42)
time_intervals <- 1:50

surv_g1 <- sort(runif(50, 0.02, 0.98), decreasing = TRUE)
surv_g2 <- sort(runif(50, 0.05, 0.95), decreasing = TRUE)
surv_g3 <- sort(runif(50, 0.01, 0.99), decreasing = TRUE)
surv_pooled <- (surv_g1 + surv_g2 + surv_g3) / 3

# Define interval boundaries for the logLikelihood function:
# xx1 is the start of each interval, xx2 is the end.
xx1 <- c(0, time_intervals[-length(time_intervals)])
xx2 <- time_intervals

# ---------------------------------------------------------
# Step 2: Fit Models and Extract Parameters (Atomic Vectors)
# ---------------------------------------------------------
init_guess <- c(r = 0.02, s = 0.01, k = 0.01, u = 0.1)

# These return atomic vectors of length 4: c(r, s, k, u)
fit_g1_pars <- vitality.ku(time = time_intervals, sdata = surv_g1, rc.data = FALSE, init.params = init_guess, pplot = FALSE)
fit_g2_pars <- vitality.ku(time = time_intervals, sdata = surv_g2, rc.data = FALSE, init.params = init_guess, pplot = FALSE)
fit_g3_pars <- vitality.ku(time = time_intervals, sdata = surv_g3, rc.data = FALSE, init.params = init_guess, pplot = FALSE)
fit_pooled_pars <- vitality.ku(time = time_intervals, sdata = surv_pooled, rc.data = FALSE, init.params = init_guess, pplot = FALSE)

# ---------------------------------------------------------
# Step 3: Explicitly Calculate Log-Likelihoods
# ---------------------------------------------------------
# Pass estimated parameters and data arrays into logLikelihood.ku()
ll_g1 <- vitality:::logLikelihood.ku(par = fit_g1_pars, xx1 = xx1, xx2 = xx2, NNi = surv_g1)
ll_g2 <- vitality:::logLikelihood.ku(par = fit_g2_pars, xx1 = xx1, xx2 = xx2, NNi = surv_g2)
ll_g3 <- vitality:::logLikelihood.ku(par = fit_g3_pars, xx1 = xx1, xx2 = xx2, NNi = surv_g3)

loglik_alternative <- ll_g1 + ll_g2 + ll_g3
loglik_null <- vitality:::logLikelihood.ku(par = fit_pooled_pars, xx1 = xx1, xx2 = xx2, NNi = surv_pooled)

# ---------------------------------------------------------
# Step 4: Perform the Likelihood Ratio Test (LRT)
# ---------------------------------------------------------
lrt_statistic <- -2 * (loglik_null - loglik_alternative)
df_diff <- 12 - 4 
p_value <- pchisq(lrt_statistic, df = df_diff, lower.tail = FALSE)

# ---------------------------------------------------------
# Step 5: Output Results
# ---------------------------------------------------------
cat("--- Likelihood Ratio Test Results ---\n")
cat("Log-Likelihood (Pooled Model):   ", loglik_null, "\n")
cat("Log-Likelihood (Separate Models):", loglik_alternative, "\n")
cat("LRT Test Statistic (Chi-sq):     ", lrt_statistic, "\n")
cat("Degrees of Freedom:              ", df_diff, "\n")
cat("p-value:                         ", p_value, "\n\n")

if(p_value < 0.05) {
  cat("Conclusion: Reject H0. The three tag groups should be modeled separately.\n")
} else {
  cat("Conclusion: Fail to reject H0. A single pooled model is statistically sufficient.\n")
}

