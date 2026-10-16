library(failCompare)
library(dplyr)
library(ggplot2)

source("R/nll_lookup.R")
source("R/fc_lrt.R")
source("fc_lrt_table.R")
source("R/run_vitality_lrt_grid.R")

# source("fc_nll.R")
# source("patch_fc_fit.R")

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
  rc_values     = get_nth_to_last_sorted(pooled_data,n=69)
)

summarize_mult_lrt_grid(sel_rt_results_weibull2_ls)
sel_rt_results_weibull2_ls_mod <- run_vitality_lrt_grid(
  group_data_ls = lot_data_ls,
  pooled_data   = pooled_data,
  models        = "weibull",
  rc_values     = sort(pooled_data)[(length(pooled_data)-69):length(pooled_data)-67]
)










# Same grid, but fitting "weibull2" instead of "vitality.ku" --
# fc_obj_nll() (R/nll_lookup.R) dispatches to nll_weibull()/nll_weibull3().
rt_results_weibull_ls <- run_vitality_lrt_grid(
  group_data_ls = lot_data_ls,
  pooled_data   = pooled_data,
  models        = "weibull",
  rc_values     = 60:80
)


sel_rt_results_weibull2_ls <- run_vitality_lrt_grid(
  group_data_ls = lot_data_ls,
  pooled_data   = pooled_data,
  models        = "weibull",
  rc_values     = sort(pooled_data)[(length(pooled_data)-69):length(pooled_data)]
)



summarize_vitality_lrt_grid(sel_rt_results_weibull2_ls)
sel_rt_results_weibull2_ls_mod <- run_vitality_lrt_grid(
  group_data_ls = lot_data_ls,
  pooled_data   = pooled_data,
  models        = "weibull",
  rc_values     = sort(pooled_data)[(length(pooled_data)-69):length(pooled_data)-67]
)





ggplot() +
  geom_point(data=taglife_rawDF,aes(y=surv,x=days_difference,color=lot))+
  geom_vline(xintercept = 76)

# approximately 1/4 of the detections
# sort(pooled_data)[(length(pooled_data)-27):length(pooled_data)]
# sort(lot1_data)[(length(lot1_data)-7):length(lot1_data)]
# sort(lot2_data)[(length(lot2_data)-13):length(lot2_data)]
# sort(lot3_data)[(length(lot3_data)-5):length(lot3_data)]
# NLL lookup used by fc_lrt() below (see R/fc_lrt.R): specific to the
# "vitality.ku" parameterization (r, s, k, u) and the $times$non_cen
# censoring flag attached by fc_fit().
vit_nll_wrap3 <- function(df_in,model="vitality.ku",rc.value=NULL,censorID=NULL){

  fc_obj_int <- failCompare::fc_fit(time=df_in$days_difference,
    model=model,
    rc.value=rc.value,censorID=censorID)
  
    bb=tapply(df_in$"days_difference",df_in$"lot",
    function(x){
      fc_obj_int <- failCompare::fc_fit(
        time=x,
         model=model,
         rc.value=rc.value,censorID=censorID)
    })
  return(bb)

  fc_obj_int$nll_vit <- failCompare::nll_vitality_ku(
    params = fc_obj_int$par_tab[,"params"],
    data_time = fc_obj_int$times$time,
    non_cen = fc_obj_int$times$non_cen)
   data.frame(fc_obj_int$nll_vit,rc.value=ifelse(is.null(rc.value),NA,rc.value))
  
}
tmp <- vit_nll_wrap3(df_in=taglife_rawDF)
tmp
do.call(rbind,lapply(76:80, function(x){vit_nll_wrap3(df_in=taglife_rawDF,rc.value=x)}))

# list of failure time
lot_data_ls <- list("Lot 1" = lot1_data, "Lot 2" = lot2_data, "Lot 3" = lot3_data)

rt_results_vit_ls <- run_vitality_lrt_grid(
  group_data_ls = lot_data_ls,
  pooled_data   = pooled_data,
  models        = "vitality.ku",
  rc_values     = 60:80
)

rt_results_vit_ls_summary <- summarize_vitality_lrt_grid(rt_results_vit_ls)
rt_results_vit_ls_summary


# list of failure time
lot_data_ls <- list("Lot 1" = lot1_data, "Lot 2" = lot2_data, "Lot 3" = lot3_data)

# Same grid, but fitting "weibull2" instead of "vitality.ku" --
# fc_obj_nll() (R/nll_lookup.R) dispatches to nll_weibull()/nll_weibull3().
rt_results_weibull_ls <- run_vitality_lrt_grid(
  group_data_ls = lot_data_ls,
  pooled_data   = pooled_data,
  models        = "weibull",
  rc_values     = 60:80
)

sel_rt_results_weibull2_ls <- run_vitality_lrt_grid(
  group_data_ls = lot_data_ls,
  pooled_data   = pooled_data,
  models        = "weibull",
  rc_values     = sort(pooled_data)[(length(pooled_data)-69):length(pooled_data)]
)


summarize_vitality_lrt_grid(sel_rt_results_weibull2_ls)
sel_rt_results_weibull2_ls_mod <- run_vitality_lrt_grid(
  group_data_ls = lot_data_ls,
  pooled_data   = pooled_data,
  models        = "weibull",
  rc_values     = sort(pooled_data)[(length(pooled_data)-69):length(pooled_data)-67]
)

summary_ls <- list(
  summarize_vitality_lrt_grid(rt_results_vit_ls),
  summarize_vitality_lrt_grid(rt_results_weibull_ls)
  )

# Per-parameter est/se columns differ by model family (e.g. r_est/s_est/...
# vs. shape_est/scale_est) -- keep only the columns shared by all three
# (including the new `mttf` column, which is comparable across models).
shared_cols <- Reduce(intersect, lapply(summary_ls, names))
comb_summDF <- do.call(rbind, lapply(summary_ls, `[`, shared_cols))

sort(pooled_data)[(length(pooled_data)-69):length(pooled_data)]


# scale9      weibull_rc69     weibull       69   182.0985       179.7287    4.739614  4 0.31507286  84.84344
# scale10     weibull_rc70     weibull       70   248.2444       244.1104    8.267972  4 0.08224080  74.20886

# weibull2 with 68 tags removed

sort(pooled_data)[(length(pooled_data)-69):length(pooled_data)]



# rt_results_weibull3_ls <- run_vitality_lrt_grid(
#   group_data_ls = lot_data_ls,
#   pooled_data   = pooled_data,
#   models        = "weibull3",
#   rc_values     = 60:80
# )


# 76.5653



# summarize_vitality_lrt_grid(sel_rt_results_weibull2_ls_mod)

