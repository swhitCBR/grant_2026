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
# subset_name <- "tags_SURVUSE_no_EUTH"
subset_name <- "tags_SURVUSE_OR_EUTH_&_ACTIVE" # BAD b/c inclusive of Euthanized
# subset_name <- "RAW" # BAD b/c inclusive of Euthanized

sapply(tag_subsets_ls,nrow)

cat("Processing tag subset:", subset_name, "/n")
cat("Number of tags:", nrow(tag_subsets_ls[[subset_name]]), "/n")

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
  rep_pool_tab_pth <- "C:/repos/grant_2026/media/xlsx/replicate_regrouping/replicate releases and suggested replicate pooling.xlsx"
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
  mutate(release_date=get_POSIX_date(release_date),#, "%Y-%m-%d %H:%M:%S")),
         first_computed_datetime=get_POSIX_date(first_computed_datetime),#as.POSIXct(strptime(first_computed_datetime, "%Y-%m-%d %H:%M:%S")),
         last_computed_datetime=get_POSIX_date(last_computed_datetime),#as.POSIXct(strptime(last_computed_datetime, "%Y-%m-%d %H:%M:%S")),
         mtch_code=paste(species_code,as.integer(orig_repID))) %>%
  left_join(repID_pool_tab %>%
              mutate(mtch_code=paste(species_code,orig_repID)) %>%
              select(mtch_code,new_repID),
            by="mtch_code")


det_PR_live <- rel_time_tab_repID %>% 
  filter(tag_group=="live_release" & 
           location %in% c("Priest Tailrace") & 
           # location %in% c("Priest Tailrace","Lower Ringold","Hanford") & 
           release_location=="Rock Island Tailrace") %>%
  group_by(species_code,new_repID) %>%
  summarize(
    min_det_time=min(first_computed_datetime),
    max_det_time=max(first_computed_datetime),
    avg_det_time=mean(first_computed_datetime),
    n_tags=length(unique(tag_code))) %>%
  group_by(species_code) %>%
  mutate(tot_dead=sum(n_tags),
         prop_det_tags=n_tags/tot_dead)

grid.arrange(
  ggplot() + 
    geom_point(data=dead_PR_releaseDF,aes(x=release_date,y=prop_dead_tags)) +
    facet_wrap(~species_code,ncol=1,scales="free_y"),
  ggplot() + 
    geom_point(data=det_PR_live,aes(x=avg_det_time,y=prop_det_tags)) + 
    facet_wrap(~species_code,ncol=1,scales="free_y"),
  ncol=2
)

# dead_PR_releaseDF$category <- "dead_rel_PR"
dead_PR_releaseDF$category <- "Dead Released"
dead_PR_releaseDF$prop_tags <- dead_PR_releaseDF$prop_dead_tags
dead_PR_releaseDF$date_time <- dead_PR_releaseDF$release_date

# det_PR_live$category <- "live_det_at_PR_for_RI_rel"
det_PR_live$category <- "Live Detection"
det_PR_live$prop_tags <- det_PR_live$prop_det_tags
det_PR_live$date_time <- det_PR_live$avg_det_time
# det_PR_live$date_time <- det_PR_live$min_det_time
det_PR_live$date_min <- det_PR_live$min_det_time
det_PR_live$date_max <- det_PR_live$max_det_time

rel_PR_dead_det_PR_liveDF <- bind_rows(
  det_PR_live %>% select(species_code,category,date_time,prop_tags,date_min,date_max),
  dead_PR_releaseDF %>% select(species_code,category,date_time,prop_tags))

grid.arrange(
  ggplot() + 
    geom_line(data=rel_PR_dead_det_PR_liveDF %>% filter(category=="Live Detection"),aes(x=date_time,y=prop_tags,fill=category)) + 
    geom_point(data=rel_PR_dead_det_PR_liveDF,aes(x=date_time,y=prop_tags,fill=category),shape=21,size=2) + 
    # geom_errorbarh(data=rel_PR_dead_det_PR_liveDF,aes(xmin=date_min,xmax=date_max,y=prop_tags,fill=category),alpha=0.4,width = 0,linewidth = 1) + 
    facet_wrap(~species_code,ncol=1,scales="free_y") + theme_bw() +theme(legend.position = "bottom"),#+ theme(legend.position=c(0.87,0.9),legend.title = element_blank()),
  
  ggplot() + 
    geom_line(data=rel_PR_dead_det_PR_liveDF %>% filter(category=="Live Detection"),aes(x=date_time,y=prop_tags,fill=category)) + 
    geom_point(data=rel_PR_dead_det_PR_liveDF,aes(x=date_time,y=prop_tags,fill=category),shape=21,size=2) + 
    geom_errorbarh(data=rel_PR_dead_det_PR_liveDF,aes(xmin=date_min,xmax=date_max,y=prop_tags,fill=category),alpha=0.4,width = 0,linewidth = 1) + 
    facet_wrap(~species_code,ncol=1,scales="free_y") + theme_bw() +theme(legend.position = "bottom"),ncol=2)#+ theme(legend.position=c(0.87,0.9),legend.title = element_blank()),ncol=2)


# checking matching
table(match(rel_time_tab_repID$mtch_code,repID_pool_tab$mtch_cod))

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

