library(dplyr)
library(ggplot2)
library(gridExtra)

# sourceable compilation fie
source("results/extractinng_ATLAS_rtfs_CHN.R")
source("results/extractinng_ATLAS_rtfs_STH.R")

# dir("analysis",pattern = ".rds")
# readRDS("")


STH_ATLAS_out <- readRDS("results/STH_ATLAS_out.rds")

STH_estDF_4plt <- STH_ATLAS_out$"STH_Pair_CJS_tab"
STH_estDF_4plt$fixed <- ifelse(STH_estDF_4plt$SE==0,"fixed","est")
STH_estDF_4plt$spp_repID <- factor(STH_estDF_4plt$spp_repID,
  levels=c("1","2","3","4","5","6","7","8","9_10","11","12","13","14","15",
           "16","17","18","19","20_21_22","23_24"))


CHN_ATLAS_out <- readRDS("results/CHN_ATLAS_out.rds")


CHN_estDF_4plt <- CHN_ATLAS_out$"CHN_Pair_CJS_tab"
CHN_estDF_4plt$fixed <- ifelse(CHN_estDF_4plt$SE==0,"fixed","est")
CHN_estDF_4plt$spp_repID <- factor(CHN_estDF_4plt$spp_repID,
                                   levels=c("1","2","3","4","5","6","7","8","9","10","11","12","13","14_15",
                                            "16","17","18","19","20","21","22","23","24"))

# CHN_estDF_4plt %>% filter(spp_repID=="22")

COMB_spp_ATLAS_ests <- bind_rows(
  data.frame(species="CHN",CHN_estDF_4plt),
  data.frame(species="STH",STH_estDF_4plt))

CHN_F_test_tbDF <- COMB_spp_ATLAS_ests %>% group_by(species) %>% filter(param=="pair_surv_p" & new_repID!="pool") %>%
  mutate(CV = SE / est,wt_tmp=1/(CV^2),invCV2_wt=wt_tmp/sum(wt_tmp)) |>
  select(-wt_tmp)


CHN_F_test_tbDF <- CHN_estDF_4plt %>% filter(param=="pair_surv_p" & new_repID!="pool") %>%
  mutate(CV = SE / est,wt_tmp=1/(CV^2),invCV2_wt=wt_tmp/sum(wt_tmp)) |>
  select(-wt_tmp)


CHN_F_test_tbDF_POOLED <- CHN_estDF_4plt %>% filter(param=="pair_surv_p" & new_repID=="pool") %>%
  mutate(CV = SE / est,wt_tmp=1/(CV^2),invCV2_wt=wt_tmp/sum(wt_tmp)) |>
  select(-wt_tmp)
CHN_F_test_tbDF_POOLED %>% select(param,est,SE,CV)


# type  wt_avg wt_avgSE   lcl   ucl
#WEIGHTED   1 rep    0.810   0.0178 0.775 0.845
# POOLED  0.7936 0.018032 

  
source("R/compute_f_tests_by_reach.R")

CHN_F_test_res_short <- compute_f_tests_by_reach(
  CHN_F_test_tbDF |>
    transmute(reach = param, tagger = repID, estimate = est, se = SE),
  verbose = FALSE)
CHN_F_test_res_short


CHN_F_test_tbDF %>% group_by(type) %>%
  summarize(wt_avg=sum(invCV2_wt*est),
            wt_avgSE=sqrt(sum((invCV2_wt^2)*SE^2)),
            lcl=wt_avg-1.96*wt_avgSE,
            ucl=wt_avg+1.96*wt_avgSE)



CHN_F_test_res <- compute_f_tests_by_reach(
  CHN_F_test_tbDF |>
    transmute(reach = param, tagger = repID, estimate = est, se = SE),
  verbose = TRUE
)


CHN_F_tst_summ_tb <- CHN_F_test_res |> select(reach,numerator,denominator,df,F_statistic,p_value)

CHN_F_test_long <- CHN_F_test_res |>
  select(-numerator, -denominator, -df, -F_statistic, -p_value) |>
  tidyr::pivot_longer(
    -reach,
    names_to = c("repID", ".value"),
    names_pattern = "^(.*)_(est|se)$"
  ) |>
  # verbose output stores estimates as character strings
  mutate(across(c(est, se), as.numeric)) |>
  mutate(S_barhat=mean(est),est_minus_S_barhat2=(est-S_barhat)^2,
         S_var=se^2)

CHN_F_test_long

# manual numerator calc
sum(CHN_F_test_long$est_minus_S_barhat2)/(length(unique(CHN_F_test_long$repID))-1)

# manual denominator calc
sum(CHN_F_test_long$S_var)/(length(unique(CHN_F_test_long$repID)))
CHN_F_tst_summ_tb

pf(CHN_F_tst_summ_tb$F_statistic, df1 = CHN_F_tst_summ_tb$df - 1, df2 = Inf, lower.tail = FALSE)
tmp <- data.frame(x = seq(0,4,0.01),prob=df(x = seq(0,4,0.01),df1 = CHN_F_tst_summ_tb$df - 1, df2 = Inf))
plot(prob~x,data=tmp,type="l")
abline(v=CHN_F_tst_summ_tb$F_statistic,col=2,lwd=2)

# View(CHN_F_test_res)


########### #
# PLOTTING  #
########### #


plt1_STH <- ggplot(data=STH_estDF_4plt %>% filter(type=="pool"),
                   aes(y=est,ymin=est-1.96*SE,ymax=est+1.96*SE,x=spp_rel_loc,
                       fill=spp_rel_loc)) +
  facet_wrap(~param,ncol=1,scales="free_x") + 
  geom_errorbar(width=0,position = position_dodge(width=0.5)) + 
  geom_point(shape=21,position = position_dodge(width=0.5),size=2.5)+
  scale_y_continuous(limits = c(0, 1.1)) + theme(legend.position = "none")


plt2_STH <- ggplot(data=STH_estDF_4plt %>% filter(type=="rep"),
                   aes(y=est,ymin=est-1.96*SE,ymax=est+1.96*SE,x=spp_repID,
                       fill=spp_rel_loc,color=fixed)) +
  facet_wrap(~param,ncol=1,scales="free_x") +
  geom_errorbar(width=0,position = position_dodge(width=0.5)) + 
  geom_point(shape=21,position = position_dodge(width=0.5),size=2.5) + 
  scale_y_continuous(limits = c(0, 1.1)) + 
  scale_color_manual(values=c("black","gray"))


grid.arrange(plt1_STH,plt2_STH,layout_matrix=matrix(c(1,2,2,2),nrow=1),top="Steelhead")


plt1_CHN <- ggplot(data=CHN_estDF_4plt %>% filter(type=="pool"),
                   aes(y=est,ymin=est-1.96*SE,ymax=est+1.96*SE,x=spp_rel_loc,
                       fill=spp_rel_loc)) +
  facet_wrap(~param,ncol=1,scales="free_x") + 
  geom_errorbar(width=0,position = position_dodge(width=0.5)) + 
  geom_point(shape=21,position = position_dodge(width=0.5),size=2.5)+
  scale_y_continuous(limits = c(0, 1.2)) + theme(legend.position = "none")


plt2_CHN <- ggplot(data=CHN_estDF_4plt %>% filter(type=="rep"),
                   aes(y=est,ymin=est-1.96*SE,ymax=est+1.96*SE,x=spp_repID,
                       fill=spp_rel_loc,color=fixed)) +
  facet_wrap(~param,ncol=1,scales="free_x") +
  geom_errorbar(width=0,position = position_dodge(width=0.5)) + 
  geom_point(shape=21,position = position_dodge(width=0.5),size=2.5) + 
  scale_y_continuous(limits = c(0, 1.2)) + 
  scale_color_manual(values=c("black","gray"))


grid.arrange(plt1_CHN,plt2_CHN,layout_matrix=matrix(c(1,2,2,2),nrow=1),top="Chinook")

