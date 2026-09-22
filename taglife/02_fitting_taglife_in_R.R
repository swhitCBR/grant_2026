library(failCompare)
library(ggplot2)

csv_fl_ls <- readRDS("data/clean/csv_fl_ls.rds")
taglife_rawDF <- csv_fl_ls$GPUD2026_taglife_17Aug2026

# Fit vitality.ku model for Lot 1
lot1_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 1"]
lot1_fit <- fc_fit(time = lot1_data, model = "vitality.ku", SEs = TRUE)
plot(lot1_fit)
summary(lot1_fit)


# Fit 2-parameter Weibull model for Lot 1
lot1_weibull_fit <- fc_fit(time = lot1_data, model = "weibull", SEs = TRUE)
plot(lot1_weibull_fit)
summary(lot1_weibull_fit)

# Calculate mean failure time from Weibull parameters
# Mean = scale * Gamma(1 + 1/shape)
lot1_weibull_mft <- scale * gamma(1 + 1/shape)

# Extract Weibull parameters (shape and scale)
lot1_weibull_pars <- lot1_weibull_fit$par_tab
cat("Lot 1 - Weibull Parameters:\n")
cat("Shape (k):", round(lot1_weibull_pars[1, 1], 6), "\n")
cat("Scale (λ):", round(lot1_weibull_pars[2, 1], 6), "\n\n")

# Calculate mean failure time from Weibull parameters
# Mean = scale * Gamma(1 + 1/shape)
shape <- lot1_weibull_pars[1, 1]
scale <- lot1_weibull_pars[2, 1]
lot1_weibull_mft <- scale * gamma(1 + 1/shape)

cat("Lot 1 - Weibull Mean Failure Time:", round(lot1_weibull_mft, 4), "days\n")
cat("ATLAS reported mean:", 66.9825, "days\n")
cat("Difference:", round(abs(lot1_weibull_mft - 66.9825), 4), "days\n\n")

# Compare to vitality.ku mean (from parametric extrapolation)
cat("COMPARISON:\n")
cat("Weibull mean failure time:        ", round(lot1_weibull_mft, 4), "days\n")
cat("Vitality.ku parametric mean:      ", round(mean_trap, 4), "days\n")
cat("ATLAS reported value:             ", 66.9825, "days\n")

lot1_fit$fit_vals$est
lot1_fit$fit_vals$time
lot1_data
# 
# lot1_fit <- fc_fit(time = lot1_data, model = "weibull", SEs = TRUE)
# lot1_fit$KM_DF
# mean(lot1_fit$fit_vals$time)


lot3_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 3"]
lot3_fit <- fc_fit(time = lot3_data, model = "vitality.ku", SEs = TRUE)
plot(lot3_fit)
summary(lot3_fit)
# Extract lot1_fit parameter estimates (r, s, k, u order)
lot3_pars <- setNames(lot3_fit$par_tab[, 1], c("r", "s", "k", "u"))
# Calculate mean survival time using Lot 1 fitted parameters
lot3_mst_result <- calc_mean_survival_time_ku(lot3_pars, time_max = 100)
lot3_mst_result$mst
# lot2_pars <- setNames(lot2_fit$par_tab[, 1], c("r", "s", "k", "u"))
# lot2_mst_result <- calc_mean_survival_time_ku(lot2_pars, time_max = 100)
# lot2_mean_survival_time <- lot2_mst_result$mst


# time_v <- seq(0, 100, 0.1)
# pred_v <- failCompare::fc_pred(mod_obj = lot1_fit, time = time_v)
# mean(time_v * pred_v)

# data.frame(time_v,pred_v)

lot1_fit$par_tab
lot1_fit$mod_objs[,1]


# Load function for calculating mean survival time
source("R/calc_mean_survival_time_ku.R")

# Extract lot1_fit parameter estimates (r, s, k, u order)
lot1_pars <- setNames(lot1_fit$par_tab[, 1], c("r", "s", "k", "u"))

# Calculate mean survival time using Lot 1 fitted parameters
lot1_mst_result <- calc_mean_survival_time_ku(lot1_pars, time_max = 100)
lot1_mean_survival_time <- lot1_mst_result$mst

mean(lot1_mean_survival_time)
# hist(lot1_mst_result$time_seq)
# hist(lot1_mst_result$survival_probs)
# hist(lot1_mst_result$mst)


# Fit vitality.ku model for Lot 2
lot2_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 2"]
lot2_fit <- fc_fit(time = lot2_data, model = "vitality.ku", SEs = TRUE)

# Extract lot2_fit parameter estimates and calculate mean survival time
lot2_pars <- setNames(lot2_fit$par_tab[, 1], c("r", "s", "k", "u"))
lot2_mst_result <- calc_mean_survival_time_ku(lot2_pars, time_max = 100)
lot2_mean_survival_time <- lot2_mst_result$mst

cat("Lot 2 - Vitality.ku Parameter Estimates:\n")
print(lot2_pars)
cat("\nLot 2 - Mean Survival Time:", round(lot2_mean_survival_time, 4), "days\n")

cens_v <- rep(1,length(lot2_data))
cens_v <- c(rep(1,length(lot2_data)-1),0)
cens_v <- c(rep(1,length(lot2_data)-15),rep(0,15))
lot2_fit_RC1 <- fc_fit(time = sort(lot2_data), model = "vitality.ku", SEs = TRUE,censorID=cens_v)#,rc.value =60)#   sort(lot2_data)[length(lot2_data)-1])
summary(lot2_fit)
summary(lot2_fit_RC1)


tmp1 <- fc_fit(time = sort(lot2_data), model = "all", SEs = TRUE)#,rc.value =sort(lot2_data)[length(lot2_data)])
tmp2 <- fc_fit(time = sort(lot2_data), model = "all", SEs = TRUE,rc.value =sort(lot2_data)[length(lot2_data)])
# summary(tmp)
tmp1_r <- fc_rank(tmp1)
tmp2_r <- fc_rank(tmp2)


plot(tmp2)
plot(tmp2,model="vitality.ku")

failCompare::fc_select(tmp2_r, model = "vitality.ku")$par_tab-
  failCompare::fc_select(tmp1_r, model = "vitality.ku")$par_tab

# difference in censoring
tmp2_r$fit_vals$diff <-  tmp1_r$fit_vals$est-tmp2_r$fit_vals$est
data(trout)
mort_day <- trout$days
# cens_S=fc_surv(time = mort_day,
#  rc.value = 30)
trout_mods=fc_fit(mort_day,rc.value = 30,model="all")
trout_mods_R=fc_rank(trout_mods)



# Fit vitality.ku model for Lot 3
lot3_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 3"]
lot3_fit <- fc_fit(time = lot3_data, model = "vitality.ku", SEs = TRUE)

# Extract lot3_fit parameter estimates and calculate mean survival time
lot3_pars <- setNames(lot3_fit$par_tab[, 1], c("r", "s", "k", "u"))

# Method 1: Analytical integration
lot3_mst_result <- calc_mean_survival_time_ku(lot3_pars, time_max = 100)
lot3_mean_survival_time <- lot3_mst_result$mst

# Method 2: Parametric extrapolation using fc_pred
lot3_time_fine <- seq(0, 500, by = 0.1)
lot3_pred_fine <- fc_pred(lot3_fit, lot3_time_fine)
lot3_mean_trap <- sum(diff(lot3_time_fine) * (lot3_pred_fine[-1] + lot3_pred_fine[-length(lot3_pred_fine)]) / 2)

cat("\n===========================================\n")
cat("LOT 3 - VITALITY.KU MODEL COMPARISON\n")
cat("===========================================\n\n")

cat("Lot 3 - Vitality.ku Parameter Estimates:\n")
print(lot3_pars)
cat("\nMean Failure Time Estimates:\n")
cat("  Analytical integration:          ", round(lot3_mean_survival_time, 4), "days\n")
cat("  Parametric extrapolation (fc_pred):", round(lot3_mean_trap, 4), "days\n")
cat("  ATLAS reported value:            ", 57.5574, "days\n\n")

cat("Comparison:\n")
cat("  Difference (analytical vs ATLAS):      ", round(abs(lot3_mean_survival_time - 57.5574), 4), "days\n")
cat("  Difference (parametric vs ATLAS):      ", round(abs(lot3_mean_trap - 57.5574), 4), "days\n\n")

# Fit 2-parameter Weibull model for Lot 3
lot3_weibull_fit <- fc_fit(time = lot3_data, model = "weibull", SEs = TRUE)

# Extract Weibull parameters (shape and scale)
lot3_weibull_pars <- lot3_weibull_fit$par_tab
cat("Lot 3 - Weibull Parameters:\n")
cat("Shape (k):", round(lot3_weibull_pars[1, 1], 6), "\n")
cat("Scale (λ):", round(lot3_weibull_pars[2, 1], 6), "\n\n")

# Calculate mean failure time from Weibull parameters
# Mean = scale * Gamma(1 + 1/shape)
shape_lot3 <- lot3_weibull_pars[1, 1]
scale_lot3 <- lot3_weibull_pars[2, 1]
lot3_weibull_mft <- scale_lot3 * gamma(1 + 1/shape_lot3)

cat("Lot 3 - Weibull Mean Failure Time:", round(lot3_weibull_mft, 4), "days\n")
cat("ATLAS reported mean (Weibull):     ", 67.9043, "days\n")
cat("Difference:                        ", round(abs(lot3_weibull_mft - 67.9043), 4), "days\n\n")

# Fit vitality.ku model on pooled data (all lots combined)
pooled_data <- taglife_rawDF$days_difference
pooled_fit <- fc_fit(time = pooled_data, model = "vitality.ku", SEs = TRUE)

par(mfrow=c(2,2))
plot(lot1_fit);title("Lot 1")
plot(lot2_fit);title("Lot 2")
plot(lot3_fit);title("Lot 3")
plot(pooled_fit);title("Pooled")

# comparing the different lots
data.frame(
  lot_1=tail(sort(lot1_data),15),
  lot_2=tail(sort(lot2_data),15),
  lot_3=tail(sort(lot3_data),15))

# if 75 days used as the right right censoring point
#  8,14,6 (works except for 6,but 5 and 7)

# Extract parameter estimates for comparison
lot1_params <- lot1_fit$par_tab
lot2_params <- lot2_fit$par_tab
lot3_params <- lot3_fit$par_tab

# Create comparison table
comparison_df <- data.frame(
  Parameter = c("r", "s", "k", "u"),
  Lot1_Est = as.numeric(lot1_params[, 1]),
  Lot1_SE = as.numeric(lot1_params[, 2]),
  Lot2_Est = as.numeric(lot2_params[, 1]),
  Lot2_SE = as.numeric(lot2_params[, 2]),
  Lot3_Est = as.numeric(lot3_params[, 1]),
  Lot3_SE = as.numeric(lot3_params[, 2])
)

# Generate extended predictions to 100 days
time_seq <- seq(0, 100, by = 0.5)
lot1_pred <- fc_pred(lot1_fit, time_seq)
lot2_pred <- fc_pred(lot2_fit, time_seq)
lot3_pred <- fc_pred(lot3_fit, time_seq)
pooled_pred <- fc_pred(pooled_fit, time_seq)

# Combine data from all three lots and pooled for plotting with extended vitality.ku curves
plot_data <- rbind(
  cbind(lot1_fit$KM_DF, lot = "Lot 1", type = "KM"),
  cbind(lot2_fit$KM_DF, lot = "Lot 2", type = "KM"),
  cbind(lot3_fit$KM_DF, lot = "Lot 3", type = "KM"),
  cbind(pooled_fit$KM_DF, lot = "Pooled", type = "KM"),
  data.frame(
    model = "vitality.ku",
    time = time_seq,
    est = lot1_pred,
    lcl = NA,
    ucl = NA,
    lot = "Lot 1",
    type = "vitality.ku"
  ),
  data.frame(
    model = "vitality.ku",
    time = time_seq,
    est = lot2_pred,
    lcl = NA,
    ucl = NA,
    lot = "Lot 2",
    type = "vitality.ku"
  ),
  data.frame(
    model = "vitality.ku",
    time = time_seq,
    est = lot3_pred,
    lcl = NA,
    ucl = NA,
    lot = "Lot 3",
    type = "vitality.ku"
  ),
  data.frame(
    model = "vitality.ku",
    time = time_seq,
    est = pooled_pred,
    lcl = NA,
    ucl = NA,
    lot = "Pooled",
    type = "vitality.ku"
  )
)

# Create a function to get KM survival at a given time
get_km_surv <- function(failure_time, km_data) {
  idx <- which(km_data$time <= failure_time)
  if (length(idx) == 0) return(1)
  km_data$est[max(idx)]
}

# Create individual tag survival data points aligned with KM curve
tag_surv_data_aligned <- rbind(
  data.frame(
    time = lot1_data,
    surv = sapply(lot1_data, function(t) get_km_surv(t, lot1_fit$KM_DF)),
    lot = "Lot 1"
  ),
  data.frame(
    time = lot2_data,
    surv = sapply(lot2_data, function(t) get_km_surv(t, lot2_fit$KM_DF)),
    lot = "Lot 2"
  ),
  data.frame(
    time = lot3_data,
    surv = sapply(lot3_data, function(t) get_km_surv(t, lot3_fit$KM_DF)),
    lot = "Lot 3"
  ),
  data.frame(
    time = pooled_data,
    surv = sapply(pooled_data, function(t) get_km_surv(t, pooled_fit$KM_DF)),
    lot = "Pooled"
  )
)



# First plot: Vitality.ku model fit with individual tag data as cross-shaped points
plot_data_vit <- subset(plot_data, type == "vitality.ku")

ggplot(plot_data_vit, aes(x = time, y = est, color = lot)) +
  geom_line(linewidth = 0.8) +
  geom_point(
    data = tag_surv_data_aligned,
    aes(x = time, y = surv, color = lot),
    size = 3,
    alpha = 0.5,
    shape = 4,
    inherit.aes = FALSE
  ) +
  facet_wrap(~lot, ncol = 1) +
  labs(
    title = "Vitality.ku Model Fit with Individual Tag Data",
    x = "Days to Failure",
    y = "Survival Probability",
    color = "Model"
  ) +
  xlim(0, 85) +
  theme_minimal() +
  theme(legend.position = "bottom") +
  scale_color_manual(
    values = c("Lot 1" = "#d62728", "Lot 2" = "#d62728", "Lot 3" = "#d62728", "Pooled" = "#2ca02c")
  )

# Third plot: All four vitality.ku curves overlaid on same plot
ggplot(plot_data_vit, aes(x = time, y = est, color = lot, linetype = lot)) +
  geom_line(linewidth = 0.8) +
  labs(
    title = "Comparison of Vitality.ku Models: Lot-Specific vs. Pooled",
    x = "Days to Failure",
    y = "Survival Probability",
    color = "Model",
    linetype = "Model"
  ) +
  xlim(0, 85) +
  theme_minimal() +
  theme(legend.position = "bottom") +
  scale_color_manual(
    values = c("Lot 1" = "#d62728", "Lot 2" = "#ff7f0e", "Lot 3" = "#2ca02c", "Pooled" = "#1f77b4")
  ) +
  scale_linetype_manual(
    values = c("Lot 1" = "solid", "Lot 2" = "solid", "Lot 3" = "solid", "Pooled" = "dashed")
  )

