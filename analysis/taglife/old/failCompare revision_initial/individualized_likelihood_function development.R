library(vitality)
source("fc_nll.R")
source("patch_fc_fit.R")

csv_fl_ls <- readRDS("data/clean/csv_fl_ls.rds")
library(dplyr)
taglife_rawDF <- csv_fl_ls$GPUD2026_taglife_17Aug2026 |> arrange(lot,days_difference)

# taglife_rawDF
# Extract failure times by lot
lot1_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 1"]
lot2_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 2"]
lot3_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 3"]
pooled_data <- taglife_rawDF$days_difference

sapply(list(lot1_data,lot2_data,lot3_data),length)

surv_vec_all_lots <- unlist(sapply(list(lot1_data,lot2_data,lot3_data),failCompare::fc_surv))
taglife_rawDF$surv <- surv_vec_all_lots 

library(ggplot2)
ggplot() + #geom_line() + 
  geom_point(data=taglife_rawDF,aes(y=surv,x=days_difference,color=lot))+
  geom_vline(xintercept = 76)

# approximately 1/4 of the detections
sort(pooled_data)[(length(pooled_data)-27):length(pooled_data)]

sort(lot1_data)[(length(lot1_data)-7):length(lot1_data)]
sort(lot2_data)[(length(lot2_data)-13):length(lot2_data)]
sort(lot3_data)[(length(lot3_data)-5):length(lot3_data)]

pool_uncen_mod <- failCompare::fc_fit(pooled_data,model="vitality.ku")
pool_uncen_mod <- failCompare::fc_fit(pooled_data,model="vitality.ku",silent=FALSE)

failCompare:::get_vitality_nll(model="vitality.ku",time = pool_uncen_mod$times$time,
                               sdata = pool_uncen_mod$times$surv_frac,rc.data=FALSE,
                               params = pool_uncen_mod$par_tab[,"params"])
pool_uncen_mod$nll
pool_uncen_mod$nll_n_adj

s_vitality_ku  <- function(t, r, s, u, k) {
  # Guard against boundary math issues at t=0
  t[t <= 0] <- 1e-8
  # Total combined variance at time t
  yy <- u^2 + s^2 * t
  tmp1 <- sqrt(1 / yy) * (1 - t * r)
  tmp2 <- sqrt(1 / yy) * (1 + t * r + 2 * u^2 * r / s^2)
  tmp3 <- 2 * r / s^2 + 2 * u^2 * r^2 / s^4

  if (tmp3 > 250) {
    # Rescale before exponentiating to avoid overflow when the true
    # exponent is too large to represent directly (matches vitality's own
    # SurvFn.ku() guard).
    q <- tmp3 / 250
    if (tmp3 > 1500) q <- tmp3 / 500
    S_comb <- (1 - (pnorm(-tmp1) + (exp(tmp3 / q) * pnorm(-tmp2)^(1 / q))^q)) * exp(-k * t)
  } else {
    S_comb <- (1 - (pnorm(-tmp1) + exp(tmp3) * pnorm(-tmp2))) * exp(-k * t)
  }
  return(S_comb)
}

nll_vitality_ku <- function(params, data_time, non_cen,indiv_nll=FALSE) {
  r <- params[1]; s <- params[2]; k <- params[3]; u <- params[4]
  
  # Parameter constraints to keep boundaries stable
  if (r <= 0 || s <= 0 || u <= 0 || k < 0) return(Inf)
  
  # Calculate continuous survival probability S(t)
  St <- s_vitality_ku(data_time, r, s, u, k)
  
  # Fast numerical derivative to find PDF f(t)
  dt <- 1e-5
  St_dt <- s_vitality_ku(data_time + dt, r, s, u, k)
  ft <- -(St_dt - St) / dt
  
  # Safety floors to avoid log(0) numeric failures
  ft <- pmax(ft, 1e-10)
  St <- pmax(St, 1e-10)

  ll <- non_cen * log(ft) + (1 - non_cen) * log(St)

  if(indiv_nll){
    indiv_DF <- data.frame(data_time,nll=-ll,non_cen)
    return(indiv_DF)
  }
  

  # Negative log-likelihood formulation, summed across ALL observations
  jll <- sum(ll)
  return(-jll)
}

nll_vitality_ku( params = pool_uncen_mod$par_tab[, "params"],
                 data_time = pool_uncen_mod$times$time,
                 non_cen = pool_uncen_mod$times$non_cen)

nll_vitality_ku( params = pool_uncen_mod$par_tab[, "params"],
                 data_time = pool_uncen_mod$times$time,
                 non_cen = pool_uncen_mod$times$non_cen,indiv_nll = T)

plot(pool_uncen_mod);title("pooled (uncensored)")
# plot(pool_cen_mod);title("pooled (censored: 76 days)")

pool_uncen_nll <- pool_uncen_mod$nll

 pool_uncen_mod$nll_n_adj
# pool_cen_mod$nll

lot1_uncen_mod <- failCompare::fc_fit(lot1_data,model="vitality.ku")
lot2_uncen_mod <- failCompare::fc_fit(lot2_data,model="vitality.ku")
lot3_uncen_mod <- failCompare::fc_fit(lot3_data,model="vitality.ku")

lot1_uncen_mod$nll
lot2_uncen_mod$nll
lot3_uncen_mod$nll

lot1_uncen_mod$nll_n_adj
lot2_uncen_mod$nll_n_adj
lot3_uncen_mod$nll_n_adj

# pooled 
nll_vitality_ku( params = pool_uncen_mod$par_tab[, "params"],
                 data_time = pool_uncen_mod$times$time,
                 non_cen = pool_uncen_mod$times$non_cen)

# lot-specific
nll_vitality_ku( params = lot1_uncen_mod$par_tab[, "params"],
                 data_time = lot1_uncen_mod$times$time,
                 non_cen = lot1_uncen_mod$times$non_cen)

nll_vitality_ku( params = lot2_uncen_mod$par_tab[, "params"],
                 data_time = lot2_uncen_mod$times$time,
                 non_cen = lot2_uncen_mod$times$non_cen)

nll_vitality_ku( params = lot3_uncen_mod$par_tab[, "params"],
                 data_time = lot3_uncen_mod$times$time,
                 non_cen = lot3_uncen_mod$times$non_cen)

nll_vitality_ku( params = pool_uncen_mod$par_tab[, "params"]+c(0,0,0,0),
                 data_time = pool_uncen_mod$times$time,
                 non_cen = pool_uncen_mod$times$non_cen)

v_first_param <- seq(-0.01,0.01,0.0001)
nll_vitality_ku( params = pool_uncen_mod$par_tab[, "params"]+c(v_first_param,0,0,0),
                 data_time = pool_uncen_mod$times$time,
                 non_cen = pool_uncen_mod$times$non_cen)

test_v <- c()
for(ii in 1:length(v_first_param)){
 test_v[ii] <-  nll_vitality_ku( params = pool_uncen_mod$par_tab[, "params"]+c(v_first_param[ii],0,0,0),
                 data_time = pool_uncen_mod$times$time,
                 non_cen = pool_uncen_mod$times$non_cen)}

# slices looking a nll
plot(x=pool_uncen_mod$par_tab[1, "params"]+c(v_first_param),y=test_v,type="l")
abline(v=pool_uncen_mod$par_tab[1, "params"])
abline(v=c(pool_uncen_mod$par_tab[1, "params"]-1.96*pool_uncen_mod$par_tab[1, "std"],
          pool_uncen_mod$par_tab[1, "params"]+1.96*pool_uncen_mod$par_tab[1, "std"]),
lty=2)



lot1_uncen_mod$nll*nrow(lot1_uncen_mod$times)
lot2_uncen_mod$nll*nrow(lot2_uncen_mod$times)
lot3_uncen_mod$nll*nrow(lot3_uncen_mod$times)

c(lot1_uncen_mod$nll*nrow(lot1_uncen_mod$times),
  lot2_uncen_mod$nll*nrow(lot2_uncen_mod$times),
  lot3_uncen_mod$nll*nrow(lot3_uncen_mod$times))

c(lot1_uncen_mod$nll,
  lot2_uncen_mod$nll,
  lot3_uncen_mod$nll)

c(lot1_uncen_mod$nll_n_adj,
  lot2_uncen_mod$nll_n_adj,
  lot3_uncen_mod$nll_n_adj)

data.frame(
  group="lot 1","lot 2","lot 3",
  n=c(nrow(lot1_uncen_mod$times),
  nrow(lot2_uncen_mod$times),
  nrow(lot3_uncen_mod$times)),
  nll=2*c(lot1_uncen_mod$nll_n_adj,
  lot2_uncen_mod$nll_n_adj,
  lot3_uncen_mod$nll_n_adj))


plot(pool_uncen_mod);title("pooled (uncensored)")
sep_uncen_sum_nll <- lot1_uncen_mod$nll + lot2_uncen_mod$nll + lot3_uncen_mod$nll 
sep_uncen_sum_nll < pool_uncen_nll 
lrt_uncen <- fc_lrt(pool_uncen_mod, list(lot1_uncen_mod, lot2_uncen_mod, lot3_uncen_mod))
lrt_uncen

# Pairwise LRTs: fit a pooled vitality.ku model to each pair of lots and
# compare it against that pair's two separate fits.
lot_data_ls       <- list("Lot 1" = lot1_data,      "Lot 2" = lot2_data,      "Lot 3" = lot3_data)
lot_uncen_mod_ls  <- list("Lot 1" = lot1_uncen_mod, "Lot 2" = lot2_uncen_mod, "Lot 3" = lot3_uncen_mod)
lot_pairs <- combn(names(lot_data_ls), 2, simplify = FALSE)

pairwise_lrt_uncen <- lapply(lot_pairs, function(pair) {
  pooled_pair_fit <- failCompare::fc_fit(c(lot_data_ls[[pair[1]]], lot_data_ls[[pair[2]]]), model = "vitality.ku")
  fc_lrt(pooled_pair_fit, list(lot_uncen_mod_ls[[pair[1]]], lot_uncen_mod_ls[[pair[2]]]))
})
names(pairwise_lrt_uncen) <- sapply(lot_pairs, paste, collapse = " vs ")
pairwise_lrt_uncen

source("R/fc_lrt_table.R")
fc_lrt_table(lrt_uncen, pairwise_lrt_uncen, omnibus_label = "All lots")

# Partial pooling: for each pair, "that pair shares parameters, third lot
# separate" vs. the fully pooled model -- a non-redundant complement to the
# pairwise tests above (comparing partial pooling to fully *separate*
# instead would just reproduce the pairwise statistic).
source("fc_partition_lrt.R")
scan_uncen <- fc_pooling_scan(lot_data_ls, model = "vitality.ku",
                               singleton_fits = lot_uncen_mod_ls)
scan_uncen$comparisons
fc_pooling_scan_table(scan_uncen)


pool_cen_mod <- failCompare::fc_fit(pooled_data,model="vitality.ku",rc.value = 76)

nll_vitality_ku( params = pool_cen_mod$par_tab[, "params"],
                 data_time = pool_cen_mod$times$time,
                 non_cen = pool_cen_mod$times$non_cen,indiv_nll = T)

nll_vitality_ku( params = pool_cen_mod$par_tab[, "params"],
                 data_time = ifelse(pool_cen_mod$times$time>76,76,pool_cen_mod$times$time),
                 non_cen = pool_cen_mod$times$non_cen,indiv_nll = T)

nll_vitality_ku( params = pool_cen_mod$par_tab[, "params"],
                 data_time = ifelse(pool_cen_mod$times$time>76,76,pool_cen_mod$times$time),
                 non_cen = pool_cen_mod$times$non_cen,indiv_nll = F)


nll_vitality_ku( params = pool_cen_mod$par_tab[, "params"],
                 data_time = pool_cen_mod$times$time,
                 non_cen = pool_cen_mod$times$non_cen,indiv_nll = F)

lot1_cen_mod <- failCompare::fc_fit(lot1_data,model="vitality.ku",rc.value = 76)
lot2_cen_mod <- failCompare::fc_fit(lot2_data,model="vitality.ku",rc.value = 76)
lot3_cen_mod <- failCompare::fc_fit(lot3_data,model="vitality.ku",rc.value = 76)

