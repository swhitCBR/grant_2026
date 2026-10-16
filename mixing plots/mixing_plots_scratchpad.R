library(dplyr)
library(tidyr)

dir("C:/repos/grant_2026/data/clean/pre_tagpro")

obj_nms <- c("events","nodes","tags")
tmp_pths <- file.path("C:/repos/grant_2026/data/clean/pre_tagpro",paste0(obj_nms,".csv"))
pre_tpro_dat_ls <- lapply(tmp_pths,read.csv); names(pre_tpro_dat_ls) <- obj_nms

sapply(pre_tpro_dat_ls,head)
head(pre_tpro_dat_ls$"events")

# duplicate node_codes (i.e, multiple deployments)
pre_tpro_dat_ls[["nodes"]] %>%
  filter(node_code %in% node_code[duplicated(node_code)])

node_mtch_tbl <- pre_tpro_dat_ls[["nodes"]] %>% 
  filter(!duplicated(node_code),.by = "node_code") %>%
  select(-deploy_date)

tag_mtch_tbl <- pre_tpro_dat_ls[["tags"]] %>% 
  # filter(!duplicated(node_code),.by = "node_code") %>%
  select(release_location,species_code,tag_code,activation_date,release_date)
  

eventDF_CLEAN<- pre_tpro_dat_ls[["events"]] %>%
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
  mutate(across(where(is.numeric), ~ replace_na(., 0)))
names(CHN_exerpt)[3:5] <- c("RI_live","PR_live","PR_dead")

STH_exerpt <- readxl::read_excel(rep_pool_tab_pth,range = "H3:L27") %>%
  mutate(across(where(is.numeric), ~ replace_na(., 0)))
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


eventDF_CLEAN %>% 
  group_by(species_code,release_location,orig_repID,tag_AssignedRelease) %>% 
  summarize(n_tags=length(unique(tag_code))) %>%
  tidyr::pivot_wider(values_from = n_tags,names_from = release_location)


repl_tab_ls <- eventDF_CLEAN %>% 
  group_by(species_code,release_location,orig_repID) %>% 
  summarize(n_tags=length(unique(tag_code))) %>%
  tidyr::pivot_wider(values_from = n_tags,names_from = release_location,names_repair = "universal") %>% 
  dplyr::group_split(species_code)







rel_time_tab_repID <- eventDF_CLEAN %>% 
  mutate(release_date=as.POSIXct(strptime(release_date, "%Y-%m-%d %H:%M:%S")),
         mtch_code=paste(species_code,as.integer(orig_repID))) %>%
  left_join(repID_pool_tab %>% 
              mutate(mtch_code=paste(species_code,orig_repID)) %>%
              select(mtch_code,new_repID),
            by="mtch_code"
            )

# checking matching
repID_pool_tab$mtch_code <- paste(repID_pool_tab$species_code,repID_pool_tab$orig_repID)
rel_time_tab_repID$mtch_code <- paste(rel_time_tab_repID$species_code,as.integer(rel_time_tab_repID$orig_repID))
table(match(rel_time_tab_repID$mtch_code,repID_pool_tab$mtch_cod))

# rel_time_tab_repID <- (rel_time_tab_repID ,by="mtch_code")

library(gridExtra)
library(ggplot2)


# no variability in release times at the replicate level
rel_time_tab_orig_repID_avg <- rel_time_tab_repID %>% 
  group_by(species_code,release_location,orig_repID) %>% 
  summarize(avg_rel_det=mean(release_date),
            SD_rel_hours=sd(as.numeric(release_date)/60),
            unq_rel_dete=length(unique(release_date)),
            n_tags=length(unique(tag_code)))


min(rel_time_tab_repID$release_date)
rel_time_tab_repID$diff_to_min <- as.numeric(difftime(rel_time_tab_repID$release_date,min(rel_time_tab_repID$release_date),units="hours"))


rel_time_tab_repID_avg <- rel_time_tab_repID %>% 
  group_by(species_code,release_location,new_repID) %>% 
  summarize(avg_rel_det=mean(release_date),
            SD_rel_hours=sd(diff_to_min), # hack for calculating sd difference
            min_rel_hours=min(release_date),
            max_rel_hours=max(release_date),
            unq_rel_dete=length(unique(release_date)),
            n_tags=length(unique(tag_code)))



grid.arrange(
  ggplot() + 
    geom_point(data=rel_time_tab_repID,aes(x=release_date,y=jitter(1),color=release_location)) + 
    # geom_histogram(data=rel_time_tab_repID,aes(x=release_date)) + 
    facet_grid(orig_repID~species_code,scales="free") +
    geom_vline(data = rel_time_tab_orig_repID_avg,aes(xintercept=avg_rel_det,color=release_location)),
  ggplot() + 
    geom_point(data=rel_time_tab_repID,aes(x=release_date,y=jitter(1),color=release_location)) + 
    # geom_histogram(data=rel_time_tab_repID,aes(x=release_date)) + 
    facet_grid(new_repID~species_code,scales="free") +
    geom_vline(data = rel_time_tab_repID_avg,aes(xintercept=avg_rel_det,color=release_location))
  )


# long avg (new_repID)
rel_time_tab_repID_avg_comb <- rel_time_tab_repID %>% 
  group_by(species_code,release_location,new_repID) %>% 
  summarize(avg_rel_det=mean(release_date)
  ) %>%
  tidyr::pivot_wider(values_from=c(avg_rel_det),names_from=release_location,names_repair="universal") %>%
  mutate(diff_hours=difftime(Priest.Rapids.Tailrace,Rock.Island.Tailrace,units = "hours")) %>% 
  left_join(rel_time_tab_repID_avg %>% ungroup() %>%
              filter(release_location=="Priest Rapids Tailrace") %>%
              select(species_code,new_repID,n_tags,SD_rel_hours) %>%
              rename(PR_n_tags=n_tags,PR_SD_rel_hours=SD_rel_hours)) %>%
  left_join(rel_time_tab_repID_avg %>% ungroup() %>%
              filter(release_location=="Rock Island Tailrace") %>%
              select(species_code,new_repID,n_tags,SD_rel_hours) %>%
              rename(RI_n_tags=n_tags,RI_SD_rel_hours=SD_rel_hours)) %>%
  mutate(n_tot=(RI_n_tags+PR_n_tags))


# writing excel notebook
library(openxlsx)
wb <- createWorkbook()#$#openxlsx::createWorkbook("offeset_calc_using_pooled_repIDs.xlsx")
openxlsx::addWorksheet(wb=wb,"CHN")
openxlsx::addWorksheet(wb=wb,"STH")
openxlsx::writeData(wb=wb,sheet="CHN",x=rel_time_tab_repID_avg_comb %>% filter(species_code=="CHN"))
openxlsx::writeData(wb=wb,sheet="STH",x=rel_time_tab_repID_avg_comb %>% filter(species_code=="STH"))
saveWorkbook(wb, "media/xlsx/offeset_calc_using_pooled_repIDs.xlsx", overwrite = TRUE)

# in
rel_time_tab_repID_avg_comb2 <- rel_time_tab_repID_avg_comb %>% 
  group_by(species_code) %>%
  mutate(n_tot_spp=sum(n_tot),
         n_tag_wt=n_tot/n_tot_spp) %>%
  summarize(
    naive_avg_diff=mean(diff_hours),
    wt_avg_diff=sum(n_tag_wt*as.numeric(diff_hours)))

rel_time_tab_repID_avg_comb2


# rel_time_tab_repID_avg_comb %>%  dplyr::group_split(species_code)
# rel_time_tab_repID_avg_comb %>%  group_by(species_code) %>% 
#   summarize(mean(diff_hours),sd(diff_hours),sd(diff_hours)/sqrt(length(diff_hours)-1))
# 
# grid.arrange(
#   ggplot() + geom_histogram(data=rel_time_tab_orig_repID_avg,aes(x=diff_hours)) + facet_wrap(~species_code),
#   ggplot() + geom_histogram(data=rel_time_tab_repID_avg,aes(x=diff_hours)) + facet_wrap(~species_code))
# 

# wide avg version (species)
rel_time_tab_repID_avg_w <- rel_time_tab_repID_avg %>% 
  tidyr::pivot_wider(values_from=avg_rel_dete,names_from=species_code) %>%
  mutate()



# wide version


# eventDF_CLEAN %>% 
#   group_by(species_code,release_location,orig_repID) %>% 
#   summarize(n_tags=length(unique(tag_code))) %>%
#   tidyr::pivot_wider(values_from = n_tags,names_from = release_location) %>% dplyr::group_split(species_code)
# 
# 


