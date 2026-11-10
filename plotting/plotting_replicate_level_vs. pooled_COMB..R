
library(dplyr)
library(ggplot2)

COMB_spp_ATLAS_ests_wDates <- readRDS("results/COMB_spp_ATLAS_ests_wDates.rds")

STH_estDF_4plt <- COMB_spp_ATLAS_ests_wDates %>% filter(species=="STH")
CHN_estDF_4plt <- COMB_spp_ATLAS_ests_wDates %>% filter(species=="CHN")


theme_cust <- theme(
  axis.line.x.bottom = element_line(color="black"),
  axis.line.y = element_line(color="black"),
  panel.grid.minor = element_blank(),
  panel.background = element_blank(),
  axis.title.x=element_text(color="black",face="bold",size=12,margin = margin(t = 15)),
  axis.title.y=element_text(color="black",face="bold",size=12,margin = margin(r = 15)),
  axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1,color="black"),
  axis.text.y=element_text(color="black"),
  legend.position = "none"
  )


# Distribution of individual tag release times within each replicate group and release location.
# ggplot(data = tags_new_repID_DF |>
#          semi_join(rep_level_ests_Ftests_tb_ls$COMB_spp_ATLAS_ests |>
#                      filter(type == "rep") |>
#                      distinct(species, new_repID),
#                    by = c("species_code" = "species", "new_repID")) |>
#          mutate(rep_key = paste(species_code, new_repID),
#                 rep_key = factor(rep_key, levels = rev(unique(rep_key[order(species_code, release_date)])))),
#        aes(x = release_date, y = rep_key, fill = release_location)) +
#   # identity: the two locations of a replicate are days apart, so no need to dodge them
#   geom_violin(orientation = "y", scale = "width", bw = 6 * 3600, trim = FALSE, position = "identity") +
#   facet_grid(species_code ~ ., scales = "free_y", space = "free_y") +
#   scale_y_discrete(labels = function(x) sub("^[A-Z]+ ", "", x)) +
#   labs(x = "Release date", y = "new_repID") + theme(legend.position = "bottom") + theme_cust



RI_rel_CHN_proj_surv_plt <- ggplot(data=CHN_estDF_4plt %>% filter(type=="rep" & param=="pair_surv_p"),
                               aes(y=est,ymin=est-1.96*SE,ymax=est+1.96*SE,
                                   x=reorder(new_repID , min_rel_date),
                                   group=new_repID
                               )) +
  geom_errorbar(width=0.5,position = position_dodge(width=0.8)) +
  geom_point(shape=21,position = position_dodge(width=0.8),size=3,fill="white") +
  scale_x_discrete(labels = function(x) {
    setNames(CHN_estDF_4plt$RI_rel_date_rng, CHN_estDF_4plt$new_repID)[x]
  }) +
  scale_y_continuous(limits = c(0, 1.2)) +
  scale_color_manual(values=c("black","gray")) +
  theme_bw() +# theme(plot)
  labs(y="Project Survival",x = "Rock Island Release Date(s)") +theme_cust
RI_rel_CHN_proj_surv_plt


RI_rel_STH_proj_surv_plt <- ggplot(data=STH_estDF_4plt %>% filter(type=="rep" & param=="pair_surv_p"),
                               aes(y=est,ymin=est-1.96*SE,ymax=est+1.96*SE,
                                   x=reorder(new_repID , min_rel_date),
                                   group=new_repID
                               )) +
  geom_errorbar(width=0.5,position = position_dodge(width=0.8)) +
  geom_point(shape=21,position = position_dodge(width=0.8),size=3,fill="white") +
  scale_x_discrete(labels = function(x) {
    setNames(STH_estDF_4plt$RI_rel_date_rng, STH_estDF_4plt$new_repID)[x]
  }) +
  scale_y_continuous(limits = c(0, 1.2)) +
  scale_color_manual(values=c("black","gray")) +
  theme_bw() +# theme(plot)
  labs(y="Project Survival",x = "Rock Island Release Date(s)") +theme_cust
  # theme(panel.grid.minor = element_blank()) + 
  # theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1),legend.position = "none")+ theme_cust

RI_rel_STH_proj_surv_plt


library(gridExtra)
grid.arrange(
  RI_rel_CHN_proj_surv_plt + ggtitle("CHN_paired") ,
  RI_rel_STH_proj_surv_plt + ggtitle("STH_paired") 
  )



if(!dir.exists("media/png/replicate_surv_plots")){dir.create("media/png/replicate_surv_plots",recursive = T)}

png("media/png/replicate_surv_plots/RI_rel_CHN_proj_plt.png",width=8,height=4.5,units = "in",res=600)
RI_rel_CHN_proj_surv_plt
dev.off()

png("media/png/replicate_surv_plots/RI_rel_STH_proj_plt.png",width=8,height=4.5,units = "in",res=600)
RI_rel_STH_proj_surv_plt
dev.off()




# ROCK ISLAND RELEASE CUMULATIVE SURVIVAL

RI_rel_CHN_surv_plt <- ggplot(data=CHN_estDF_4plt %>% filter(type=="rep" & param=="surv_p" & spp_rel_loc  =="Rock Island Tailrace CHN" ),
                                   aes(y=est,ymin=est-1.96*SE,ymax=est+1.96*SE,
                                       x=reorder(new_repID , min_rel_date),
                                       group=new_repID
                                   )) +
  geom_errorbar(width=0.5,position = position_dodge(width=0.8)) +
  geom_point(shape=21,position = position_dodge(width=0.8),size=3,fill="white") +
  scale_x_discrete(labels = function(x) {
    setNames(CHN_estDF_4plt$RI_rel_date_rng, CHN_estDF_4plt$new_repID)[x]
  }) +
  scale_y_continuous(limits = c(0, 1.2)) +
  scale_color_manual(values=c("black","gray")) +
  theme_bw() +# theme(plot)
  labs(y="Cumulative Survival Rock Island (R1)\n to Lower Ringold",x = "Rock Island Release Date(s)") + theme_cust
  # theme(panel.grid.minor = element_blank()) + 
  # theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1),legend.position = "none") +theme_cust
RI_rel_CHN_surv_plt

RI_rel_STH_surv_plt <- ggplot(data=STH_estDF_4plt %>% filter(type=="rep" & param=="surv_p" & spp_rel_loc  =="Rock Island Tailrace STH" ),
                              aes(y=est,ymin=est-1.96*SE,ymax=est+1.96*SE,
                                  x=reorder(new_repID , min_rel_date),
                                  group=new_repID
                              )) +
  geom_errorbar(width=0.5,position = position_dodge(width=0.8)) +
  geom_point(shape=21,position = position_dodge(width=0.8),size=3,fill="white") +
  scale_x_discrete(labels = function(x) {
    setNames(STH_estDF_4plt$RI_rel_date_rng, STH_estDF_4plt$new_repID)[x]
  }) +
  scale_y_continuous(limits = c(0, 1.2)) +
  scale_color_manual(values=c("black","gray")) +
  theme_bw() +# theme(plot)
  labs(y="Cumulative Survival Rock Island (R1)\n to Lower Ringold",x = "Rock Island Release Date(s)") + theme_cust
  # theme(panel.grid.minor = element_blank()) + 
  # theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1),legend.position = "none") +theme_cust
RI_rel_STH_surv_plt


grid.arrange(
  RI_rel_CHN_surv_plt + ggtitle("CHN_paired") ,
  RI_rel_STH_surv_plt + ggtitle("STH_paired") 
)

png("media/png/replicate_surv_plots/RI_rel_CHN_cumul_plt.png",width=8,height=4.5,units = "in",res=600)
RI_rel_CHN_surv_plt
dev.off()

png("media/png/replicate_surv_plots/RI_rel_STH_cumul_plt.png",width=8,height=4.5,units = "in",res=600)
RI_rel_STH_surv_plt
dev.off()



# PRIEST RAPIDS RELEASE CUMULATIVE SURVIVAL


PR_rel_CHN_surv_plt <- ggplot(data=CHN_estDF_4plt %>% filter(type=="rep" & param=="surv_p" & spp_rel_loc  =="Priest Rapids Tailrace CHN" ),
                              aes(y=est,ymin=est-1.96*SE,ymax=est+1.96*SE,
                                  x=reorder(new_repID , min_rel_date),
                                  group=new_repID
                              )) +
  geom_errorbar(width=0.5,position = position_dodge(width=0.8)) +
  geom_point(shape=21,position = position_dodge(width=0.8),size=3,fill="white") +
  scale_x_discrete(labels = function(x) {
    setNames(CHN_estDF_4plt$PR_rel_date_rng, CHN_estDF_4plt$new_repID)[x]
  }) +
  scale_y_continuous(limits = c(0, 1.2)) +
  scale_color_manual(values=c("black","gray")) +
  theme_bw() +# theme(plot)
  labs(y="Cumulative Survival Priest Rapids (R2)\n to Lower Ringold",x = "Priest Rapids Release Date(s)") +
  theme(panel.grid.minor = element_blank()) + 
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1),legend.position = "none") +theme_cust

PR_rel_CHN_surv_plt


PR_rel_STH_surv_plt <- ggplot(data=STH_estDF_4plt %>% filter(type=="rep" & param=="surv_p" & spp_rel_loc  =="Priest Rapids Tailrace STH" ),
                              aes(y=est,ymin=est-1.96*SE,ymax=est+1.96*SE,
                                  x=reorder(new_repID , min_rel_date),
                                  group=new_repID
                              )) +
  geom_errorbar(width=0.5,position = position_dodge(width=0.8)) +
  geom_point(shape=21,position = position_dodge(width=0.8),size=3,fill="white") +
  scale_x_discrete(labels = function(x) {
    setNames(STH_estDF_4plt$PR_rel_date_rng, STH_estDF_4plt$new_repID)[x]
  }) +
  scale_y_continuous(limits = c(0, 1.2)) +
  scale_color_manual(values=c("black","gray")) +
  theme_bw() +# theme(plot)
  labs(y="Cumulative Survival Priest Rapids (R2)\n to Lower Ringold",x = "Priest Rapids Release Date(s)") +
  theme(panel.grid.minor = element_blank()) + 
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1),legend.position = "none") +theme_cust

PR_rel_STH_surv_plt




grid.arrange(
  PR_rel_CHN_surv_plt + ggtitle("CHN_paired") ,
  PR_rel_STH_surv_plt + ggtitle("STH_paired") 
)

png("media/png/replicate_surv_plots/PR_rel_CHN_cumul_plt.png",width=8,height=4.5,units = "in",res=600)
PR_rel_CHN_surv_plt
dev.off()

png("media/png/replicate_surv_plots/PR_rel_STH_cumul_plt.png",width=8,height=4.5,units = "in",res=600)
PR_rel_STH_surv_plt
dev.off()
