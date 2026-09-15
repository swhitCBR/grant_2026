library(dplyr)
library(ggplot2) 
library(tidyr)

csv_fl_ls <- readRDS("csv_fl_ls.rds")

tags_dat_raw <- csv_fl_ls$GPUD2026_tags_12Aug2026
# events_dat <- csv_fl_ls$GPUD2026_events_12Aug2026


usable_CT_tab <- tags_dat_raw |> 
  group_by(survival_use,fish_status) |> 
  summarize(n_tags=length(unique(tag_code))) |>
  pivot_wider(names_from = survival_use,values_from = n_tags,values_fill = 0)#,
usable_CT_tab

fish_status_tagger_CT_tab <- tags_dat_raw |> 
  group_by(fish_status,tagger) |> 
  summarize(n_tags=length(unique(tag_code))) |>
  pivot_wider(names_from = fish_status,values_from = n_tags,values_fill = 0)#,
fish_status_tagger_CT_tab

unfilt_tab_ls <- list("usable_CT_tab"=usable_CT_tab,
                      "fish_status_tagger_CT_tab"=fish_status_tagger_CT_tab)

saveRDS(unfilt_tab_ls,"unfilt_tab_ls.rds")

# basic checks
# 3496 tags
# no NAs all unique
table(is.na(tags_dat_raw$tag_code))

# table(tags_dat_raw$release_location)
# table(tags_dat_raw$tag_group)
# table(tags_dat_raw$tagger)
# table(tags_dat_raw$species)
# table(tags_dat_raw$survival_use,tags_dat_raw$fish_status)


usable_CT_tab <- tags_dat_raw |>  #survival_use 
  group_by(survival_use,fish_status) |> 
  summarize(n_tags=length(unique(tag_code))) |>
  pivot_wider(names_from = survival_use,values_from = n_tags,values_fill = 0)#,

# release dates 
table(tags_dat_raw$tag_release_date)

tags_dat_raw$spp_code=substr(tags_dat_raw$species,start = 1,stop = 2)
tags_dat_raw$spp=ifelse(tags_dat_raw$spp_code=="11","CHN","STH")
tags_dat_raw$reartype=substr(tags_dat_raw$species,start = 3,stop = 3)
tags_dat_raw$rel_date=as.Date(substr(tags_dat_raw$tag_release_date,start = 1,stop = 10))
# tag_release_date
# 

tags_dat_raw$release_location <- factor(tags_dat_raw$release_location,c("Rock Island Tailrace","Priest Rapids Tailrace"))

# table(tags_dat_raw$survival_use,tags_dat_raw$fish_status)
# unique(tags_dat_raw$tag_AssignedRelease)
# table(tags_dat_raw$tag_AssignedRelease)
# table(tags_dat_raw$tag_AssignedRelease,tags_dat_raw$release_location)

tags_dat_raw_summ <- tags_dat_raw |>  
  group_by(spp,project_code,tag_group,release_location,rel_date) |>
  summarize(n_tags=length(unique(tag_code)))

################## #
# By-tagger summary
################## #
tags_dat_raw_tagger_summ <- tags_dat_raw |>  
  group_by(spp,tag_group,release_location,tagger) |>
  summarize(n_tags=length(unique(tag_code))) |> 
  pivot_wider(names_from = tagger,values_from = n_tags)|>
  arrange(release_location)

################## #
# 
# library(tidyr)
CHN_tags_dat_summ <-  tags_dat_raw_summ |> pivot_wider(values_from = n_tags,names_from=tag_group) |> filter(spp=="CHN")
CHN_RI_tags_dat_summ <- CHN_tags_dat_summ |> filter(release_location=="Rock Island Tailrace") |>  arrange(rel_date)  |> 
  mutate(repID=1:n(),code=paste(spp,project_code,release_location,rel_date,sep="_"))
CHN_PR_tags_dat_summ <- CHN_tags_dat_summ |> filter(release_location=="Priest Rapids Tailrace")|>  arrange(rel_date)  |> 
  mutate(repID=1:n(),code=paste(spp,project_code,release_location,rel_date,sep="_"))

STH_tags_dat_summ <-  tags_dat_raw_summ |> pivot_wider(values_from = n_tags,names_from=tag_group) |> filter(spp=="STH")
STH_RI_tags_dat_summ <- STH_tags_dat_summ |> filter(release_location=="Rock Island Tailrace") |> arrange(rel_date)  |> 
  mutate(repID=1:n(),code=paste(spp,project_code,release_location,rel_date,sep="_"))
STH_PR_tags_dat_summ <- STH_tags_dat_summ |> filter(release_location=="Priest Rapids Tailrace")|>  arrange(rel_date)  |> 
  mutate(repID=1:n(),code=paste(spp,project_code,release_location,rel_date,sep="_"))
# 
rep_id_tab <- bind_rows(
  CHN_RI_tags_dat_summ,CHN_PR_tags_dat_summ,
  STH_RI_tags_dat_summ,STH_PR_tags_dat_summ) |>
  mutate(code2=paste(spp,repID))|> 
  mutate(code3=paste(spp,repID,release_location))|> 
  ungroup()

# CHN_rep_summ_comb <- bind_rows(CHN_RI_tags_dat_summ,CHN_PR_tags_dat_summ) |> ungroup()# |> pivot_wider(values_from = c(live_release,dead_release) ,names_from=c(release_location)) 
  # STH_RI_tags_dat_summ,STH_PR_tags_dat_summ)

tags_dat_raw_wrepID <- tags_dat_raw |> 
  mutate(code=paste(spp,project_code,release_location,rel_date,sep="_")) |> 
  left_join(rep_id_tab |> select(repID,code),by="code")


tags_dat_wrepID <- tags_dat_raw_wrepID |> filter(survival_use)

saveRDS(tags_dat_raw_wrepID,"tags_dat_raw_wrepID.rds")
saveRDS(tags_dat_wrepID,"tags_dat_wrepID.rds")

##################### #
# filtering out 
##################### #

table(tags_dat_raw$release_type,tags_dat_raw$release_location)



tags_dat <- tags_dat_wrepID

RL_tagger_CT_tab <- tags_dat |> 
  group_by(release_location,tagger) |> 
  summarize(n_tags=length(unique(tag_code))) |>
  pivot_wider(names_from = release_location,values_from = n_tags,values_fill = 0)#,


RL_helicopter_CT_tab <- tags_dat |> 
  group_by(release_location,release_type) |> 
  summarize(n_tags=length(unique(tag_code))) |>
  pivot_wider(names_from = release_location,values_from = n_tags,values_fill = 0)#,
RL_helicopter_CT_tab

lot_tagger_CT_tab <- tags_dat |> 
  group_by(lot,tagger) |> 
  summarize(n_tags=length(unique(tag_code))) |>
  pivot_wider(names_from = lot,values_from = n_tags,values_fill = 0)#,
lot_tagger_CT_tab


lot_RL_CT_tab <- tags_dat |> 
  group_by(lot,release_location) |> 
  summarize(n_tags=length(unique(tag_code))) |>
  pivot_wider(names_from = lot,values_from = n_tags,values_fill = 0)#,
lot_RL_CT_tab

fish_status_tagger_CT_tab <- tags_dat |> 
  group_by(fish_status,tagger) |> 
  summarize(n_tags=length(unique(tag_code))) |>
  pivot_wider(names_from = fish_status,values_from = n_tags,values_fill = 0)#,
fish_status_tagger_CT_tab

repID_tagger_CT_tab <- tags_dat |> 
  group_by(repID,tagger) |> 
  summarize(n_tags=length(unique(tag_code))) |>
  pivot_wider(names_from = tagger,values_from = n_tags,values_fill = 0)#,
repID_tagger_CT_tab

repID_RL_CT_tab <- tags_dat |> 
  group_by(repID,release_location) |> 
  summarize(n_tags=length(unique(tag_code))) |>
  pivot_wider(names_from = release_location,values_from = n_tags,values_fill = 0)#,
repID_RL_CT_tab

# continency tables

CT_tab_ls <- list(
  "RL_tagger_CT_tab"=RL_tagger_CT_tab,
  "RL_helicopter_CT_tab"=RL_helicopter_CT_tab,
  "lot_tagger_CT_tab"=lot_tagger_CT_tab,
  "lot_RL_CT_tab"=lot_RL_CT_tab,
  "fish_status_tagger_CT_tab"=fish_status_tagger_CT_tab,
  "repID_tagger_CT_tab"=repID_tagger_CT_tab,
  "repID_RL_CT_tab"=repID_RL_CT_tab
  )

# check_sums
do.call(rbind,lapply(1:length(CT_tab_ls),function(x){
  data.frame(tb=names(CT_tab_ls)[x],sum=sum(CT_tab_ls[[x]][,-c(1)]))}))

saveRDS(CT_tab_ls,"CT_tab_ls.rds")


# tags_dat_summ2 <- tags_dat_wrepID |>
#   group_by(spp,repID,release_location,tag_group) |>
#   summarize(n_tags=length(unique(tag_code))) |>
#   pivot_wider(names_from=c(release_location,tag_group),values_from = n_tags) |>
#     ungroup()  |> 
#     mutate(code2=paste(spp,repID))

tags_dat_summ2 <- tags_dat_raw_wrepID |>
  group_by(spp,repID,release_location,tag_group) |>
  summarize(n_tags=length(unique(tag_code))) |>
  pivot_wider(names_from=c(release_location,tag_group),values_from = n_tags) |>
  ungroup()  |> 
  mutate(code2=paste(spp,repID))

tags_dat_summ3 <- tags_dat_summ2 |> left_join(
  rep_id_tab |> filter(release_location=="Priest Rapids Tailrace") |> rename(PR_rel_date=rel_date) |> select(PR_rel_date,code2)) |> left_join(
    rep_id_tab |> filter(release_location=="Rock Island Tailrace") |> rename(RI_rel_date=rel_date) |> select(RI_rel_date,code2))

names(tags_dat_summ3)[3:6] <- c("PRT_d","PRT","RI_d","RI")

tags_dat_summ4 <- tags_dat_summ3 |> 
  relocate(spp,repID,RI,RI_d,PRT,PRT_d) |>
  mutate(RI_rel=format(RI_rel_date,"%m-%d"),
         PR_rel=format(PR_rel_date,"%m-%d")) |>
  select(-code2,-RI_rel_date,-PR_rel_date) 


################## #
# By-tagger summary

################## #
tags_dat_raw_tagger_summ <- tags_dat_raw |>
  group_by(spp,tag_group,release_location,tagger) |>
  summarize(n_tags=length(unique(tag_code))) |>
  pivot_wider(names_from = tagger,values_from = n_tags)|>
  arrange(release_location)

tags_dat_tagger_summ <- tags_dat |>
  group_by(spp,tag_group,release_location,tagger) |>
  summarize(n_tags=length(unique(tag_code))) |>
  pivot_wider(names_from = tagger,values_from = n_tags)|>
  arrange(release_location)

################## #


QAQC_tabs <- list("QAQC_tab1"=tags_dat_tagger_summ,
                  "QAQC_tab2"=tags_dat_summ4)

saveRDS(QAQC_tabs,"QAQC_tabs.rds")


tarmac_tag_tab <- tags_dat_raw_wrepID |> filter(fish_status=="Tarmac") |> select(species,tag_release_date,release_location,repID,tag_code)
saveRDS(tarmac_tag_tab,"tarmac_tag_tab.rds")


mort_tag_tab <- tags_dat_raw_wrepID |> filter(fish_status=="Mortality") |> select(species,tag_release_date,release_location,repID,tag_code)
saveRDS(mort_tag_tab,"mort_tag_tab.rds")


