library(vitality)

csv_fl_ls <- readRDS("data/clean/csv_fl_ls.rds")
taglife_rawDF <- csv_fl_ls$GPUD2026_taglife_17Aug2026

# Extract failure times by lot
lot1_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 1"]
lot2_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 2"]
lot3_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 3"]
pooled_data <- taglife_rawDF$days_difference

taglife_rawDF$tag_activate_date
taglife_rawDF$tag_failure_date

source("R/compute_km_survival_censored.R")

lot1_km_nc <- compute_km_survival(lot1_data)
lot1_fit_nc <- vitality::vitality.ku(
  time = lot1_km_nc$time,
  sdata = lot1_km_nc$survival,
  rc.data = FALSE,
  se = length(lot1_data),
  pplot = FALSE,
  silent = FALSE
)


# lot1_cens_S <- failCompare::fc_surv(time=lot1_km_cens$time,rc.value =lot1_cens_val)
lot1_S <- failCompare::fc_surv(time=lot1_km_nc$time)#,rc.value =lot1_cens_val)
fc_plot(time = lot1_km_nc$time, surv = lot1_S, hist=F, main="Lot 1")

fc_lot1_fit <- failCompare::fc_fit(time = sort(lot1_km_nc$time), model = "vitality.ku", SEs = TRUE)
plot(fc_lot1_fit) # matches ATLAS

fc_plot(time = lot1_km_nc$time, surv = lot1_S, hist=F, main="Lot 1")
lines(x=seq(0,80,0.5),failCompare::fc_pred(times=seq(0,80,0.5),model="vitality.ku",pars=lot1_fit_nc[,"params"]),col=1,lwd=3)
lines(x=seq(0,80,0.5),failCompare::fc_pred(times=seq(0,80,0.5),model="vitality.ku",pars=fc_lot1_fit$par_tab[,"params"]),col=2,lty=2,lwd=3)


n_tags_cen <- 6
# lot1_cens_val <- tail( lot1_km_nc$time,8)[1]
# lot1_cens_val <- tail( lot1_km_nc$time,1)[1]
# lot1_cens_val <- tail( lot1_km_nc$time,1)[1]+99
# lot1_cens_val <- tail( lot1_km_nc$time,15)[1]
lot1_cens_val <- tail( lot1_km_nc$time,n_tags_cen)[1]

lot1_km_cens <- compute_km_survival_censored(lot1_data,rc.cutoff = lot1_cens_val)
lot1_fit_cens <- vitality.ku(
  time = lot1_km_cens$time,
  sdata = lot1_km_cens$survival,
  rc.data = FALSE,
  se = length(lot1_data),
  pplot = FALSE,
  silent = F
)
lot1_fit_cens

# lot1_cens_S <- failCompare::fc_surv(time=lot1_km_cens$time,rc.value =lot1_cens_val)
lot1_cens_S <- failCompare::fc_surv(time=lot1_km_nc$time,rc.value =lot1_cens_val)
fc_lot1_fit <- failCompare::fc_fit(time = sort(lot1_km_nc$time), model = "vitality.ku", SEs = TRUE,rc.value=lot1_cens_val)

failCompare::fc_fit(time = sort(lot1_km_nc$time), model = "vitality.ku", SEs = TRUE,censorID=sort(lot1_km_nc$time)>60)
failCompare::fc_fit(time = sort(lot1_km_nc$time), model = "vitality.ku", SEs = TRUE,censorID=sort(lot1_km_nc$time)>70)
failCompare::fc_fit(time = sort(lot1_km_nc$time), model = "vitality.ku", SEs = TRUE,censorID=0+(sort(lot1_km_nc$time)>60))
failCompare::fc_fit(time = sort(lot1_km_nc$time), model = "vitality.ku", SEs = TRUE,censorID=0+(sort(lot1_km_nc$time)>70))


# failCompare::fc_fit(time = sort(lot1_km_nc$time), model = "weibull", SEs = TRUE,rc.value=70)
# failCompare::fc_fit(time = sort(lot1_km_nc$time), model = "weibull", SEs = TRUE,rc.value=75)


failCompare::fc_fit(time = sort(lot1_km_nc$time), model = "vitality.ku", SEs = TRUE,rc.value=60,censorID=sort(lot1_km_nc$time)>60)



# fc_plot(time = lot1_km_nc$time, surv = lot1_S, hist=F, main="Lot 1")
par(mfrow=c(1,2))
fc_plot(time = lot1_km_nc$time, surv = lot1_S, hist=F, main="Lot 1 (not censored)")
lines(x=seq(0,80,0.5),failCompare::fc_pred(times=seq(0,80,0.5),model="vitality.ku",pars=lot1_fit_nc[,"params"]),col=1)
# lines(x=seq(0,80,0.5),failCompare::fc_pred(times=seq(0,80,0.5),model="vitality.ku",pars=lot1_fit_cens[,"params"]),col=2)
points(x = lot1_km_nc$time, y = lot1_S, hist=F, main="Lot 1 (not censored)",col=2)


# fc_plot(time = lot1_km_nc$time, surv = lot1_S, hist=F, main="Lot 1 (not censored)")
fc_plot(time = lot1_km_cens$time, surv = lot1_cens_S, hist=F,main=paste("Lot 1 (censor ",n_tags_cen,"tags",paste0("(",round(lot1_cens_val,2)),")"))#main=paste("Lot 1 (censor values after:",round(lot1_cens_val,2)))
lines(x=seq(0,80,0.5),failCompare::fc_pred(times=seq(0,80,0.5),model="vitality.ku",pars=lot1_fit_nc[,"params"]),col=1)
lines(x=seq(0,80,0.5),failCompare::fc_pred(times=seq(0,80,0.5),model="vitality.ku",pars=lot1_fit_cens[,"params"]),col=2)


# fc_plot(time = lot1_km_nc$time, surv = lot1_S, hist=F, main="Lot 1 (not censored)")

plot(x = lot1_km_nc$time, y = lot1_S, hist=F, main="Lot 1 (not censored)")





# lines(x=seq(0,80,0.5),failCompare::fc_pred(times=seq(0,80,0.5),model="vitality.ku",pars=lot1_fit_cens[,"params"]),col=3)
# lines(x=seq(0,80,0.5),failCompare::fc_pred(times=seq(0,80,0.5),model="vitality.ku",pars=lot1_fit_cens[,"params"]))# plot(lot1_fit_cens)


# lot1_cens_val <- tail( lot1_km_nc$time,9)[1]
# failCompare::fc_fit(time = sort(lot1_km_nc$time), model = "vitality.ku", SEs = TRUE,rc.value =lot1_cens_val )


failCompare::fc_fit(time = sort(lot1_km_nc$time), model = "vitality.ku", SEs = TRUE,censorID=sort(lot1_km_nc$time)>=lot1_cens_val)#,rc.value =lot1_cens_val )
failCompare::fc_fit(time = sort(lot1_km_nc$time), model = "weibull", SEs = TRUE)
aa=failCompare::fc_fit(time = sort(lot1_km_nc$time), model = "weibull", SEs = TRUE,censorID=sort(lot1_km_nc$time)<=lot1_cens_val)#,rc.value =lot1_cens_val )
plot(aa)

failCompare::fc_fit(time = sort(lot1_km_nc$time), model = "vitality.ku", SEs = TRUE,censorID=sort(lot1_km_nc$time)>=lot1_cens_val)#,rc.value =lot1_cens_val )




fc_lot1_fit

library(failCompare)
data(trout)
mort_day=trout$days
unadj_S=fc_surv(time = mort_day)
fc_plot(time = mort_day, surv = unadj_S, hist=F, main="Ignore")
cens_S=fc_surv(time = mort_day, rc.value = 30)
fc_plot(time = mort_day, surv = cens_S, hist=F, main="Properly Censored")

# Fitting models
trout_mods=fc_fit(mort_day,rc.value = 30,model="all") 
# Ranking models
trout_mods_R=fc_rank(trout_mods)

plot(trout_mods)
