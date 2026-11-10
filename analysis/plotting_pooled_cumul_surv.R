
library(dplyr)
library(ggplot2)
library(gridExtra)

cum_surv_RI <- readRDS("analysis/cum_surv_RI.rds")


river_km_tab <- readRDS("analysis/river_km_tab.rds")

# one row per plotted site: where the dotted vertical lines, their labels and the axis ticks go
# river_km_tab <- distinct(cum_surv_RI, site, river_kilometer)
# 

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


# Axis is river kilometer, reversed so upstream is on the left. Each site is marked by a dotted
# vertical line labeled along the bottom of the panel.
CHN_cum_plt <- ggplot(data = cum_surv_RI %>% filter(species=="CHN"),
       aes(x = river_kilometer, y = est, ymin = est - 1.96*SE, ymax = est + 1.96*SE#,
           # fill = species, group = species
           )) +
  geom_vline(data = river_km_tab, aes(xintercept = river_kilometer), linetype = "dotted") +
  geom_text(data = river_km_tab, aes(x = river_kilometer, y = 0.48, label = site),
            inherit.aes = FALSE, angle = 90, hjust = 0, vjust = -0.4) +
  geom_line(position = position_dodge(width = 2)) +
  # no error bar on the release point (survival fixed at 1)
  geom_errorbar(data = ~ filter(.x, site != "Release"), width = 1, position = position_dodge(width = 2)) +
  geom_point(position = position_dodge(width = 2),shape=21,size=3,fill="white") +
  # facet_wrap(~species,ncol=1) +
  scale_x_reverse(breaks = river_km_tab$river_kilometer, labels = round(river_km_tab$river_kilometer)) +
  scale_y_continuous(limits = c(0.48, 1)) +
  labs(x = "River Kilometer (RKM)", y = "Cumulative Survival", color = NULL) + theme_cust



STH_cum_plt <- ggplot(data = cum_surv_RI %>% filter(species=="STH"),
       aes(x = river_kilometer, y = est, ymin = est - 1.96*SE, ymax = est + 1.96*SE#,
           # fill = species, group = species
           )) +
  geom_vline(data = river_km_tab, aes(xintercept = river_kilometer), linetype = "dotted") +
  geom_text(data = river_km_tab, aes(x = river_kilometer, y = 0.48, label = site),
            inherit.aes = FALSE, angle = 90, hjust = 0, vjust = -0.4) +
  geom_line(position = position_dodge(width = 2)) +
  # no error bar on the release point (survival fixed at 1)
  geom_errorbar(data = ~ filter(.x, site != "Release"), width = 1, position = position_dodge(width = 2)) +
  geom_point(position = position_dodge(width = 2),shape=21,size=3,fill="white") +
  # facet_wrap(~species,ncol=1) +
  scale_x_reverse(breaks = river_km_tab$river_kilometer, labels = round(river_km_tab$river_kilometer)) +
  scale_y_continuous(limits = c(0.48, 1)) +
  labs(x = "River Kilometer (RKM)", y = "Cumulative Survival", color = NULL) + theme_cust

# one species per plot, stacked; titles replace the facet strips used before the split
grid.arrange(CHN_cum_plt + ggtitle("Chinook"),
             STH_cum_plt + ggtitle("Steelhead"),
             ncol = 2)

cumul_dir <- "media/png/R1_cumul_surv_plots"
if(!dir.exists(cumul_dir)){dir.create(cumul_dir,recursive = T)}


png(file.path(cumul_dir,"R1_rel_CHN_cumul_plt.png"),width=8.5,height=5.8,units = "in",res=600)
CHN_cum_plt
dev.off()

png(file.path(cumul_dir,"R1_rel_STH_cumul_plt.png"),width=8.5,height=5.8,units = "in",res=600)
STH_cum_plt
dev.off()



