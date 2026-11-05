library(dplyr)
library(openxlsx)
library(ggplot2)
library(gridExtra)


get_POSIX_date <- function(x,tz_in="UTC"){as.POSIXct(paste(substr(x,1,10),substr(x,12,19)),tz=tz_in)}

csv_fl_ls <- readRDS("data/clean/csv_fl_ls.rds")
tag_subsets_ls <- readRDS("data/clean/tag_subsets_ls.rds")

tags_raw <- csv_fl_ls$GPUD2026_tags_17Aug2026
tags_raw$species_code <- ifelse(substr(tags_raw$species,1,1)=="1","CHN","STH")

events_raw <- csv_fl_ls$GPUD2026_events_17Aug2026
nodes_raw <- csv_fl_ls$GPUD2026_nodes_12Aug2026

# no euthanized fish subset used in TAGGER effect study
subset_name <- "tags_SURVUSE_OR_EUTH_&_ACTIVE" # BAD b/c inclusive of Euthanized


# Function to filter events and nodes by tag subset
filter_events_nodes <- function(tag_subset, events_raw, nodes_raw) {
  subset_tag_codes <- unique(tag_subset$tag_code)
  events_subset <- events_raw |> filter(tag_code %in% subset_tag_codes)
  node_codes_in_events <- unique(events_subset$node_code)
  nodes_subset <- nodes_raw |> filter(node_code %in% node_codes_in_events)
  return(list(tags = tag_subset, events = events_subset, nodes = nodes_subset))
}

# Filter events and nodes for the selected subset
subset_data <- filter_events_nodes(
  tag_subsets_ls[[subset_name]], 
  events_raw, 
  nodes_raw
)

# duplicate node_codes (i.e, multiple deployments)
subset_data[["nodes"]] %>%
  filter(node_code %in% node_code[duplicated(node_code)])

node_mtch_tbl <- subset_data[["nodes"]] %>% 
  filter(!duplicated(node_code),.by = "node_code") %>%
  select(-deploy_date)

tag_mtch_tbl <- subset_data[["tags"]] %>% 
  mutate(activation_date=get_POSIX_date(tag_activate_date),
         release_date=get_POSIX_date(tag_release_date),
         species_code=ifelse(substr(species,1,1)=="1","CHN","STH"),
         orig_repID=substr(tag_AssignedRelease,3,4) # added later, could cause issues
  ) %>%
  # filter(!duplicated(node_code),.by = "node_code") %>%
  select(release_location,species_code,tag_code,activation_date,release_date,tag_status,tag_group,orig_repID)

# event table that includes live and dead fish
eventDF_CLEAN<- subset_data[["events"]] %>%
  left_join(node_mtch_tbl) %>%
  left_join(tag_mtch_tbl) %>%
  mutate(orig_repID=substr(tag_AssignedRelease,3,4))


##################### #
# replacement table
##################### #
{
  # summary table with release size tables
  rep_pool_tab_pth <- "media/xlsx/replicate_regrouping/replicate releases and suggested replicate pooling.xlsx"
  CHN_exerpt <- readxl::read_excel(rep_pool_tab_pth,range = "B3:F27") %>% 
    mutate(across(where(is.numeric), ~ tidyr::replace_na(., 0)))
  names(CHN_exerpt)[3:5] <- c("RI_live","PR_live","PR_dead")
  
  STH_exerpt <- readxl::read_excel(rep_pool_tab_pth,range = "H3:L27") %>%
    mutate(across(where(is.numeric), ~ tidyr::replace_na(., 0)))
  names(STH_exerpt)[3:5] <- c("RI_live","PR_live","PR_dead")
  
  CHN_exerpt$"Chinook"[!is.na(CHN_exerpt$"Chinook")]
  CHN_init_ids <- CHN_pool_ids <- as.character(1:24)
  CHN_pool_ids[14:15] <- "14,15" 
  
  STH_exerpt$"Steelhead"[!is.na(STH_exerpt$"Steelhead")]
  STH_init_ids <- STH_pool_ids <- as.character(1:24)
  STH_pool_ids[9:10] <- "9,10" 
  STH_pool_ids[20:22] <- "20,21,22" 
  STH_pool_ids[23:24] <- "23,24" 
  
  repID_pool_tab_ls <- list(
    "CHN" = data.frame(species_code="CHN",orig_repID=CHN_init_ids,new_repID=CHN_pool_ids,CHN_exerpt[,3:5]),
    "STH" = data.frame(species_code="STH",orig_repID=STH_init_ids,new_repID=STH_pool_ids,STH_exerpt[,3:5]))
  
  repID_pool_tab <- do.call(rbind,repID_pool_tab_ls)
  }


# all tags assigned a new replicate ID
dead_PR_releaseDF <- tag_mtch_tbl %>% 
  mutate(mtch_code=paste(species_code,as.integer(orig_repID))) %>% 
  left_join(repID_pool_tab %>% 
              mutate(mtch_code=paste(species_code,orig_repID)) %>%
              select(mtch_code,new_repID),
            by="mtch_code") %>%
  filter(tag_group=="dead_release") %>%
  group_by(release_location,species_code,release_date) %>%
  summarize(n_tags=length(unique(tag_code))) %>%
  group_by(species_code) %>%
  mutate(tot_dead=sum(n_tags),
         prop_dead_tags=n_tags/tot_dead)

rel_time_tab_repID <- eventDF_CLEAN %>%
  mutate(release_date=get_POSIX_date(release_date),
         first_computed_datetime=get_POSIX_date(first_computed_datetime),
         last_computed_datetime=get_POSIX_date(last_computed_datetime),
         mtch_code=paste(species_code,as.integer(orig_repID))) %>%
  left_join(repID_pool_tab %>%
              mutate(mtch_code=paste(species_code,orig_repID)) %>%
              select(mtch_code,new_repID),
            by="mtch_code") %>%
  mutate(det_day=as.Date(first_computed_datetime))


R1_tags_seen_below_PR <- unique(eventDF_CLEAN$tag_code[eventDF_CLEAN$tag_group=="live_release" &
                                         eventDF_CLEAN$location %in% c("Handford", "Lower Ringold")])


det_PR_live_by_day <- rel_time_tab_repID %>% 
  filter(tag_group=="live_release" & 
           location %in% c("Priest Tailrace") & 
           release_location=="Rock Island Tailrace") %>%
  group_by(species_code,det_day) %>%
  summarize(
    min_det_time=min(first_computed_datetime),
    max_det_time=max(first_computed_datetime),
    avg_det_time=mean(first_computed_datetime),
    n_tags=length(unique(tag_code))) %>%
  group_by(species_code) %>%
  mutate(tot_dead=sum(n_tags),
         prop_det_tags=n_tags/tot_dead)



det_PR_live_by_day_presumed_dead <- rel_time_tab_repID %>% 
  filter(tag_group=="live_release" & 
           location %in% c("Priest Tailrace") & 
           release_location=="Rock Island Tailrace" &
           !(tag_code %in% R1_tags_seen_below_PR)) %>%
  group_by(species_code,det_day) %>%
  summarize(
    min_det_time=min(first_computed_datetime),
    max_det_time=max(first_computed_datetime),
    avg_det_time=mean(first_computed_datetime),
    n_tags=length(unique(tag_code))) %>%
  group_by(species_code) %>%
  mutate(tot_dead=sum(n_tags),
         prop_det_tags=n_tags/tot_dead)



########################## #
# Getting ready for plots
########################## #

# dead_PR_releaseDF$category <- "dead_rel_PR"
dead_PR_releaseDF$category <- "D2 Release"
dead_PR_releaseDF$prop_tags <- dead_PR_releaseDF$prop_dead_tags
dead_PR_releaseDF$date_time <- dead_PR_releaseDF$release_date

# det_PR_live$category <- "live_det_at_PR_for_RI_rel"
det_PR_live_by_day$category <- "R1 Detection"
det_PR_live_by_day$prop_tags <- det_PR_live_by_day$prop_det_tags
det_PR_live_by_day$date_time <- det_PR_live_by_day$avg_det_time
det_PR_live_by_day$date_min <- det_PR_live_by_day$min_det_time
det_PR_live_by_day$date_max <- det_PR_live_by_day$max_det_time

det_PR_live_by_day_presumed_dead$category <- "R1 Detection"
# det_PR_live_by_day_presumed_dead$category <- "R1 Detection (presumed dead)"
det_PR_live_by_day_presumed_dead$prop_tags <- det_PR_live_by_day_presumed_dead$prop_det_tags
det_PR_live_by_day_presumed_dead$date_time <- det_PR_live_by_day_presumed_dead$avg_det_time
det_PR_live_by_day_presumed_dead$date_min <- det_PR_live_by_day_presumed_dead$min_det_time
det_PR_live_by_day_presumed_dead$date_max <- det_PR_live_by_day_presumed_dead$max_det_time

rel_PR_dead_det_PR_live_by_dayDF <- bind_rows(
  det_PR_live_by_day %>% select(species_code,category,date_time,prop_tags,date_min,date_max),
  dead_PR_releaseDF %>% select(species_code,category,date_time,prop_tags)
  )

rel_PR_dead_det_PR_live_by_dayDF_presumed_dead <- bind_rows(
  det_PR_live_by_day_presumed_dead %>% select(species_code,category,date_time,prop_tags,date_min,date_max),
  dead_PR_releaseDF %>% select(species_code,category,date_time,prop_tags)
)



plt_ls <- list(
  "fig_3_2a_CHN_det_vs_rel"=ggplot() + 
    geom_line(data=rel_PR_dead_det_PR_live_by_dayDF %>% filter(species_code=="CHN" & category=="R1 Detection"),aes(x=date_time,y=prop_tags*100)) + 
    geom_point(data=rel_PR_dead_det_PR_live_by_dayDF %>% filter(species_code=="CHN"),aes(x=date_time,y=prop_tags*100,fill=category,shape=category,size=category)) + 
    # facet_wrap(~species_code,ncol=1,scales="free_y") + 
    # theme_minimal() +
    theme(legend.position = "bottom") +
    scale_size_manual(values=c(1.5,2)) +
    scale_shape_manual(values=c(24,21)) +
    scale_y_continuous(breaks=seq(0,16,2)) +
    scale_fill_manual(values=c("red","blue")) +
    geom_hline(yintercept = 0,color=NA) +
    labs(y="Percent",x="Date") + 
    theme(legend.position=c(0.87,0.9),legend.title = element_blank(),
          axis.line.x.bottom = element_line(color="black"),
          axis.line.y = element_line(color="black"),
          axis.text.x=element_text(color="black"),
          axis.text.y=element_text(color="black"),
          axis.title.x=element_text(color="black",face="bold",size=12),
          axis.title.y=element_text(color="black",face="bold",size=12),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank()),
  
  "fig_3_2b_CHN_det_dead_vs_rel"=ggplot() + 
    geom_line(data=rel_PR_dead_det_PR_live_by_dayDF_presumed_dead %>% filter(species_code=="CHN" &  category=="R1 Detection"),aes(x=date_time,y=prop_tags*100)) + 
    geom_point(data=rel_PR_dead_det_PR_live_by_dayDF_presumed_dead  %>%  filter(species_code=="CHN"),aes(x=date_time,y=prop_tags*100,fill=category,shape=category,size=category)) + 
    # facet_wrap(~species_code,ncol=1,scales="free_y") + 
    # theme_minimal() +
    theme(legend.position = "bottom") +
    scale_size_manual(values=c(1.5,2)) +
    scale_shape_manual(values=c(24,21)) +
    scale_y_continuous(breaks=seq(0,16,2)) +
    scale_fill_manual(values=c("red","blue")) +
    geom_hline(yintercept = 0,color=NA) +
    labs(y="Percent",x="Date") + 
    theme(legend.position=c(0.87,0.9),legend.title = element_blank(),
          axis.line.x.bottom = element_line(color="black"),
          axis.line.y = element_line(color="black"),
          axis.text.x=element_text(color="black"),
          axis.text.y=element_text(color="black"),
          axis.title.x=element_text(color="black",face="bold",size=12),
          axis.title.y=element_text(color="black",face="bold",size=12),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank()),
  
  
  "fig_3_6a_STH_det_vs_rel"=ggplot() + 
    geom_line(data=rel_PR_dead_det_PR_live_by_dayDF %>% filter(species_code=="STH" & category=="R1 Detection"),aes(x=date_time,y=prop_tags*100)) + 
    geom_point(data=rel_PR_dead_det_PR_live_by_dayDF %>% filter(species_code=="STH"),aes(x=date_time,y=prop_tags*100,fill=category,shape=category,size=category)) + 
    # facet_wrap(~species_code,ncol=1,scales="free_y") +
    # theme_minimal() +
    theme(legend.position = "bottom") +
    scale_size_manual(values=c(1.5,2)) +
    scale_shape_manual(values=c(24,21)) +
    scale_y_continuous(breaks=seq(0,16,2)) +
    scale_fill_manual(values=c("red","blue")) +
    geom_hline(yintercept = 0,color=NA) +
    labs(y="Percent",x="Date") + 
    theme(legend.position=c(0.87,0.9),legend.title = element_blank(),
          axis.line.x.bottom = element_line(color="black"),
          axis.line.y = element_line(color="black"),
          axis.text.x=element_text(color="black"),
          axis.text.y=element_text(color="black"),
          axis.title.x=element_text(color="black",face="bold",size=12),
          axis.title.y=element_text(color="black",face="bold",size=12),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank()),
  
  "fig_3_6b_STH_det_dead_vs_rel"=ggplot() + 
    geom_line(data=rel_PR_dead_det_PR_live_by_dayDF_presumed_dead %>% filter(species_code=="STH" &  category=="R1 Detection"),aes(x=date_time,y=prop_tags*100)) + 
    geom_point(data=rel_PR_dead_det_PR_live_by_dayDF_presumed_dead  %>%  filter(species_code=="STH"),aes(x=date_time,y=prop_tags*100,fill=category,shape=category,size=category)) + 
    # facet_wrap(~species_code,ncol=1,scales="free_y") + 
    # theme_minimal() +
    theme(legend.position = "bottom") +
    scale_size_manual(values=c(1.5,2)) +
    scale_shape_manual(values=c(24,21)) +
    scale_fill_manual(values=c("red","blue")) +
    scale_y_continuous(breaks=seq(0,16,2)) +
    geom_hline(yintercept = 0,color=NA) +
    labs(y="Percent",x="Date") + 
    theme(legend.position=c(0.87,0.9),legend.title = element_blank(),
          axis.line.x.bottom = element_line(color="black"),
          axis.line.y = element_line(color="black"),
          axis.text.x=element_text(color="black"),
          axis.text.y=element_text(color="black"),
          axis.title.x=element_text(color="black",face="bold",size=12),
          axis.title.y=element_text(color="black",face="bold",size=12),
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank()
    )
)


grid.arrange(
  plt_ls[[1]] + ggtitle(names(plt_ls)[1]),
  plt_ls[[2]] + ggtitle(names(plt_ls)[2]),
  plt_ls[[3]] + ggtitle(names(plt_ls)[3]),
  plt_ls[[4]] + ggtitle(names(plt_ls)[4]),
  layout_matrix=matrix(c(1,2,3, 4), ncol = 2)
)


# dir.create("media/png/mixing_dead_plts")
for(ii in 1:length(plt_ls)){
  ggsave(plot = plt_ls[[ii]],filename = file.path("media/png/mixing_dead_plts",paste0(names(plt_ls)[[ii]],".png")),
         width = 5.5,height = 2.5,units = "in",dpi=600)
}




grid.arrange(

ggplot() + 
  geom_line(data=rel_PR_dead_det_PR_live_by_dayDF %>% filter(species_code=="CHN" & category=="R1 Detection"),aes(x=date_time,y=prop_tags*100)) + 
  geom_point(data=rel_PR_dead_det_PR_live_by_dayDF %>% filter(species_code=="CHN"),aes(x=date_time,y=prop_tags*100,fill=category,shape=category,size=category)) + 
  # facet_wrap(~species_code,ncol=1,scales="free_y") + 
  # theme_minimal() +
  theme(legend.position = "bottom") +
  scale_size_manual(values=c(2,3)) +
  scale_shape_manual(values=c(24,21)) +
  scale_y_continuous(breaks=seq(0,16,2)) +
  scale_fill_manual(values=c("red","blue")) +
  geom_hline(yintercept = 0,color=NA) +
  labs(y="Percent",x="Date") + 
  theme(legend.position=c(0.87,0.9),legend.title = element_blank(),
        axis.line.x.bottom = element_line(color="black"),
        axis.line.y = element_line(color="black"),
        axis.text.x=element_text(color="black"),
        axis.text.y=element_text(color="black"),
        axis.title.x=element_text(color="black",face="bold",size=12),
        axis.title.y=element_text(color="black",face="bold",size=12),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank()),

ggplot() + 
  geom_line(data=rel_PR_dead_det_PR_live_by_dayDF_presumed_dead %>% filter(species_code=="CHN" &  category=="R1 Detection (presumed dead)"),aes(x=date_time,y=prop_tags*100)) + 
  geom_point(data=rel_PR_dead_det_PR_live_by_dayDF_presumed_dead  %>%  filter(species_code=="CHN"),aes(x=date_time,y=prop_tags*100,fill=category,shape=category,size=category)) + 
  # facet_wrap(~species_code,ncol=1,scales="free_y") + 
  # theme_minimal() +
  theme(legend.position = "bottom") +
  scale_size_manual(values=c(2,3)) +
  scale_shape_manual(values=c(24,21)) +
  scale_y_continuous(breaks=seq(0,16,2)) +
  scale_fill_manual(values=c("red","blue")) +
  geom_hline(yintercept = 0,color=NA) +
  labs(y="Percent",x="Date") + 
  theme(legend.position=c(0.87,0.9),legend.title = element_blank(),
        axis.line.x.bottom = element_line(color="black"),
        axis.line.y = element_line(color="black"),
        axis.text.x=element_text(color="black"),
        axis.text.y=element_text(color="black"),
        axis.title.x=element_text(color="black",face="bold",size=12),
        axis.title.y=element_text(color="black",face="bold",size=12),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank()),


ggplot() + 
  geom_line(data=rel_PR_dead_det_PR_live_by_dayDF %>% filter(species_code=="STH" & category=="R1 Detection"),aes(x=date_time,y=prop_tags*100)) + 
  geom_point(data=rel_PR_dead_det_PR_live_by_dayDF %>% filter(species_code=="STH"),aes(x=date_time,y=prop_tags*100,fill=category,shape=category,size=category)) + 
  # facet_wrap(~species_code,ncol=1,scales="free_y") +
  # theme_minimal() +
  theme(legend.position = "bottom") +
  scale_size_manual(values=c(2,3)) +
  scale_shape_manual(values=c(24,21)) +
  scale_y_continuous(breaks=seq(0,16,2)) +
  scale_fill_manual(values=c("red","blue")) +
  geom_hline(yintercept = 0,color=NA) +
  labs(y="Percent",x="Date") + 
  theme(legend.position=c(0.87,0.9),legend.title = element_blank(),
        axis.line.x.bottom = element_line(color="black"),
        axis.line.y = element_line(color="black"),
        axis.text.x=element_text(color="black"),
        axis.text.y=element_text(color="black"),
        axis.title.x=element_text(color="black",face="bold",size=12),
        axis.title.y=element_text(color="black",face="bold",size=12),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank()),

ggplot() + 
  geom_line(data=rel_PR_dead_det_PR_live_by_dayDF_presumed_dead %>% filter(species_code=="STH" &  category=="R1 Detection (presumed dead)"),aes(x=date_time,y=prop_tags*100)) + 
  geom_point(data=rel_PR_dead_det_PR_live_by_dayDF_presumed_dead  %>%  filter(species_code=="STH"),aes(x=date_time,y=prop_tags*100,fill=category,shape=category,size=category)) + 
  # facet_wrap(~species_code,ncol=1,scales="free_y") + 
  # theme_minimal() +
  theme(legend.position = "bottom") +
  scale_size_manual(values=c(2,3)) +
  scale_shape_manual(values=c(24,21)) +
  scale_fill_manual(values=c("red","blue")) +
  scale_y_continuous(breaks=seq(0,16,2)) +
  geom_hline(yintercept = 0,color=NA) +
  labs(y="Percent",x="Date") + 
  theme(legend.position=c(0.87,0.9),legend.title = element_blank(),
        axis.line.x.bottom = element_line(color="black"),
        axis.line.y = element_line(color="black"),
        axis.text.x=element_text(color="black"),
        axis.text.y=element_text(color="black"),
        axis.title.x=element_text(color="black",face="bold",size=12),
        axis.title.y=element_text(color="black",face="bold",size=12),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank()
        ),
  layout_matrix=matrix(c(1,2,3, 4), ncol = 2)
  )










# grid.arrange(
#   ggplot() + 
#     geom_line(data=rel_PR_dead_det_PR_live_by_dayDF %>% filter(category=="R1 Detection"),aes(x=date_time,y=prop_tags*100)) + 
#     geom_point(data=rel_PR_dead_det_PR_live_by_dayDF,aes(x=date_time,y=prop_tags*100,fill=category),shape=21,size=2) + 
#     # geom_errorbarh(data=rel_PR_dead_det_PR_liveDF,aes(xmin=date_min,xmax=date_max,y=prop_tags,fill=category),alpha=0.4,width = 0,linewidth = 1) + 
#     facet_wrap(~species_code,ncol=1,scales="free_y") + theme_bw() +theme(legend.position = "bottom")+
#     labs(y="Percent",x="Date"),#+ theme(legend.position=c(0.87,0.9),legend.title = element_blank()),
#   
#   ggplot() + 
#     geom_line(data=rel_PR_dead_det_PR_live_by_dayDF %>% filter(category=="R1 Detection"),aes(x=date_time,y=prop_tags*100)) + 
#     geom_point(data=rel_PR_dead_det_PR_live_by_dayDF,aes(x=date_time,y=prop_tags*100,fill=category),shape=21,size=2) + 
#     geom_errorbarh(data=rel_PR_dead_det_PR_live_by_dayDF,aes(xmin=date_min,xmax=date_max,y=prop_tags*100,fill=category),alpha=0.4,width = 0,linewidth = 1) + 
#     facet_wrap(~species_code,ncol=1,scales="free_y") + theme_bw() +theme(legend.position = "bottom") +
#     labs(y="Percent",x="Date"),
#   ncol=2)#,#+ theme(legend.position=c(0.87,0.9),legend.title = element_blank()),ncol=2)
# 
# 
# checking matching
# table(match(rel_time_tab_repID$mtch_code,repID_pool_tab$mtch_cod))

# no variability in release times at the replicate level
rel_time_tab_orig_repID_avg <- rel_time_tab_repID %>% 
  group_by(species_code,release_location,orig_repID) %>% 
  summarize(avg_rel_det=mean(release_date),
            SD_rel_hours=sd(as.numeric(release_date)/60),
            unq_rel_dete=length(unique(release_date)),
            n_tags=length(unique(tag_code)))


rel_time_tab_repID$diff_to_min <- as.numeric(difftime(rel_time_tab_repID$release_date,min(rel_time_tab_repID$release_date),units="hours"))


rel_time_tab_repID_avg <- rel_time_tab_repID %>% 
  group_by(species_code,release_location,new_repID) %>% 
  summarize(avg_rel_det=mean(release_date),
            SD_rel_hours=sd(diff_to_min), # hack for calculating sd difference
            min_rel_hours=min(release_date),
            max_rel_hours=max(release_date),
            unq_rel_dete=length(unique(release_date)),
            n_tags=length(unique(tag_code)))

