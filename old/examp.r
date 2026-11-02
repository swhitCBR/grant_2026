#EXAMP


# Install and load the vitality package
# install.packages("vitality")
library(vitality)

# ---------------------------------------------------------
# Step 1: Create Dummy Survival Data for Three Tag Groups
# ---------------------------------------------------------
set.seed(42)
time_intervals <- 1:50

# Generate random counts of deaths occurring in each interval
group1_deaths <- rmultinom(1, size = 500, prob = diff(c(0, pbeta(time_intervals/50, 2, 5))))[,1]
group2_deaths <- rmultinom(1, size = 450, prob = diff(c(0, pbeta(time_intervals/50, 2.2, 4.8))))[,1]
group3_deaths <- rmultinom(1, size = 600, prob = diff(c(0, pbeta(time_intervals/50, 3, 4))))[,1]

# Create data frames formatted for the vitality package (requires time vector and death counts)
data_g1 <- data.frame(time = time_intervals, deaths = group1_deaths)
data_g2 <- data.frame(time = time_intervals, deaths = group2_deaths)
data_g3 <- data.frame(time = time_intervals, deaths = group3_deaths)

# Create a combined pooled dataset for the Null hypothesis
data_pooled <- data.frame(
  time = time_intervals,
  deaths = group1_deaths + group2_deaths + group3_deaths
)

# ---------------------------------------------------------
# Step 2: Fit the Unrestricted Models (3 Separate Models)
# ---------------------------------------------------------
# Note: Provide initial parameter parameter guesses: c(r, s, k, u)
init_guess <- c(r = 0.02, s = 0.01, k = 0.001, u = 0.1)

fit_g1 <- vitality.ku(time = data_g1$time, sdata = data_g1$deaths, rc.data = FALSE, init.params = init_guess)
fit_g2 <- vitality.ku(time = data_g2$time, sdata = data_g2$deaths, rc.data = FALSE, init.params = init_guess)
fit_g3 <- vitality.ku(time = data_g3$time, sdata = data_g3$deaths, rc.data = FALSE, init.params = init_guess)

# Sum the log-likelihoods of the independent models
# (Note: Extracted from the value element of the optimization list inside the return object)
loglik_alternative <- fit_g1$ll + fit_g2$ll + fit_g3$ll

# ---------------------------------------------------------
# Step 3: Fit the Restricted Model (1 Pooled Model)
# ---------------------------------------------------------
fit_pooled <- vitality.ku(time = data_pooled$time, sdata = data_pooled$deaths, rc.data = FALSE, init.params = init_guess)
loglik_null <- fit_pooled$ll

# ---------------------------------------------------------
# Step 4: Perform the Likelihood Ratio Test (LRT)
# ---------------------------------------------------------
# Calculate the Wilks' test statistic
lrt_statistic <- -2 * (loglik_null - loglik_alternative)

# 4 parameters per model. Alt model = 12 params. Null model = 4 params.
df_diff <- 12 - 4 

# Calculate the p-value using the Chi-squared distribution
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

