library(dplyr)
library(ggplot2)
library(gridExtra)

# sourceable compilation fie
source("analysis/extractinng_ATLAS_rtfs_CHN.R")
source("analysis/extractinng_ATLAS_rtfs_STH.R")

# dir("analysis",pattern = ".rds")
# readRDS("")


STH_ATLAS_out <- readRDS("analysis/STH_ATLAS_out.rds")


STH_estDF_4plt <- STH_ATLAS_out$"STH_Pair_CJS_tab"
STH_estDF_4plt$fixed <- ifelse(STH_estDF_4plt$SE==0,"fixed","est")
STH_estDF_4plt$spp_repID <- factor(STH_estDF_4plt$spp_repID,
  levels=c("1","2","3","5","6","7","8","9_10","11","12","13","14","15",
           "16","17","18","19","20_21_22","23_24"))

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

 

CHN_ATLAS_out <- readRDS("analysis/CHN_ATLAS_out.rds")




CHN_estDF_4plt <- CHN_ATLAS_out$"CHN_Pair_CJS_tab"
CHN_estDF_4plt$fixed <- ifelse(CHN_estDF_4plt$SE==0,"fixed","est")
# CHN_estDF_4plt$spp_repID <- factor(CHN_estDF_4plt$spp_repID,
#                                    levels=c("1","2","3","5","6","7","8","9_10","11","12","13","14","15",
#                                             "16","17","18","19","20_21_22","23_24"))

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

CHN_estDF_4plt %>% filter(spp_repID=="22")
