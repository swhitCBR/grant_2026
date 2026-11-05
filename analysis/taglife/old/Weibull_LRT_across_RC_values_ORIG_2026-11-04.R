

library(failCompare)
library(dplyr)
library(ggplot2)


csv_fl_ls <- readRDS("data/clean/csv_fl_ls.rds")

taglife_rawDF <- csv_fl_ls$GPUD2026_taglife_17Aug2026 |> arrange(lot,days_difference)

# taglife_rawDF
# Extract failure times by lot
lot1_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 1"]
lot2_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 2"]
lot3_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 3"]
pooled_data <- taglife_rawDF$days_difference

data.frame(lot=paste("Lot",1:3),n_tags=sapply(list(lot1_data,lot2_data,lot3_data),length))

surv_vec_all_lots <- unlist(sapply(list(lot1_data,lot2_data,lot3_data),failCompare::fc_surv))
taglife_rawDF$surv <- surv_vec_all_lots 

# list of failure time
lot_data_ls <- list("Lot 1" = lot1_data, "Lot 2" = lot2_data, "Lot 3" = lot3_data)

source("R/run_mult_rc_lrt.R")

# fc_obj_nll() (R/nll_lookup.R) dispatches to nll_weibull()/nll_weibull3().
rt_results_weibull_ls <- run_mult_rc_lrt(
  group_data_ls = lot_data_ls,
  pooled_data   = pooled_data,
  models        = "weibull",
  rc_values     = 60:80,silent=T
)

sel_rt_results_weibull2_ls <- run_mult_rc_lrt(
  group_data_ls = lot_data_ls,
  pooled_data   = pooled_data,
  models        = "weibull",
  rc_count_back = 69
)


weib_mod_nc <- fc_fit(time = pooled_data,model="weibull")
weib_mod_rc1 <- fc_fit(time = pooled_data,model="weibull",rc.value = max(pooled_data))
# weib_mod_rc2 <- fc_fit(time = pooled_data,model="weibull",rc.value = sort(pooled_data)[length(pooled_data)-1])



fc_fit(time = pooled_data,model="weibull",rc.value = max(pooled_data))
fc_fit(time = pooled_data,model="weibull",censorID=c(rep(1,length(pooled_data)-1),rep(0,1)))
fc_fit(time = pooled_data,model="weibull",censorID=c(rep(TRUE,length(pooled_data)-1),rep(FALSE,1)))




mttf_fc_obj(weib_mod_nc)
mttf_fc_obj(weib_mod_rc1)
mttf_fc_obj(weib_mod_rc2)

mttf_fc_obj(fc_fit(time = pooled_data,model="weibull",rc.value = sort(pooled_data)[length(pooled_data)-20]))


mttf_fc_obj(fc_fit(time = pooled_data,model="weibull",rc.value = sort(pooled_data)[length(pooled_data)-20]))
mttf_fc_obj(fc_fit(time = pooled_data,model="weibull",censorID=c(rep(TRUE,length(pooled_data)-21),rep(FALSE,21))))

mttf_fc_obj(fc_fit(time = pooled_data,model="weibull",rc.value = sort(pooled_data)[length(pooled_data)-67]))
mttf_fc_obj(fc_fit(time = pooled_data,model="weibull",censorID=c(rep(TRUE,length(pooled_data)-68),rep(FALSE,68))))
plot(fc_fit(time = pooled_data,model="weibull",censorID=c(rep(TRUE,length(pooled_data)-68),rep(FALSE,68))))


mttf_fc_obj(fc_fit(time = pooled_data,model="weibull",rc.value = sort(pooled_data)[length(pooled_data)-7]))
mttf_fc_obj(fc_fit(time = pooled_data,model="weibull",censorID=c(rep(TRUE,length(pooled_data)-8),rep(FALSE,8))))


# sel_rt_results_weibull2_ls <- run_mult_rc_lrt(
#   group_data_ls = lot_data_ls,
#   pooled_data   = pooled_data,
#   models        = "weibull",
#   rc_values     = get_nth_to_last_sorted(pooled_data,n=69)
# )
summarize_mult_lrt_grid(rt_results_weibull_ls)

summarize_mult_lrt_grid(sel_rt_results_weibull2_ls)
