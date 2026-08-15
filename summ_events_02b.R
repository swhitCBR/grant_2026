library(dplyr)
library(tidyr)

csv_fl_ls <- readRDS("csv_fl_ls.rds")
events_dat <- csv_fl_ls$GPUD2026_events_12Aug2026
node_dat <- csv_fl_ls$GPUD2026_nodes_12Aug2026

tags_dat_wrepID <- readRDS("tags_dat_wrepID.rds")

# events_dat |> left_join(node_dat |> select(node_code,location))

table(table(node_dat$node_code))
dup_nodesDF <- subset(node_dat,node_code %in% node_dat[duplicated(node_dat$node_code),"node_code"])

# omitting duplicate nodes
events_dat_wnodes <- events_dat |> left_join(node_dat[!duplicated(node_dat$node_code),] |> select(node_code,location))
loc_tab_nodups <- node_dat[!duplicated(node_dat$location),] |> select(river_kilometer,location) |> arrange(-river_kilometer)
events_dat_wnodes$location <- factor(events_dat_wnodes$location,levels=loc_tab_nodups$location)

events_dat_wnodes |> pivot_wider(values_from=hits,names_from=location)
events_dat_wnodes |> select(tag_code,first_computed_datetime,location) |> pivot_wider(values_from=first_computed_datetime,names_from=location)
events_dat_wnodes2 <- events_dat_wnodes |> select(tag_code,first_computed_datetime,last_computed_datetime,location) |> group_by(tag_code,location) |> 
  summarize(first_dt=min(first_computed_datetime),
            last_dt=max(last_computed_datetime))


events_dat_wnodes2a <- events_dat_wnodes2  |> 
  select(tag_code,first_dt,location) 


events_dat_wnodes3 <- events_dat_wnodes2a |>
  pivot_wider(values_from=first_dt,names_from=location)

# events_dat_wnodes3 <- events_dat_wnodes2a |> 
#   mutate(detTF=is.Date(first_dt)) |> select(-first_dt) |> 
#   pivot_wider(values_from=first_dt,names_from=location)

DH_tag_code_raw <- data.frame(events_dat_wnodes3[,1],!is.na(events_dat_wnodes3[,-c(1)]))


# tarmac_tag_tab <- readRDS("tarmac_tag_tab.rds")
# tarmac_tag_evt_tab <- DH_tag_code_raw |> filter(tag_code %in% tarmac_tag_tab$tag_code) |> left_join(tarmac_tag_tab)
# 
# saveRDS(tarmac_tag_evt_tab,"tarmac_tag_evt_tab.rds")
 DH_tag_code <- DH_tag_code_raw |> left_join(tags_dat_wrepID |> select(tag_code,repID,fish_status,spp,release_location))

DH_tag_code_summ <- DH_tag_code |> group_by(spp,release_location,repID,fish_status) |> 
  summarize(
    Crescent.Bar=sum(Crescent.Bar),
    Sunland=sum(Sunland),
    Wanapum.BRZ=sum(Wanapum.BRZ),
    Wanapum=sum(Wanapum),
    Wanapum.Tailrace=sum(Wanapum.Tailrace),
    Mattawa=sum(Mattawa),
    Priest.BRZ=sum(Priest.BRZ),
    Priest=sum(Priest),
    Priest.Tailrace=sum(Priest.Tailrace),
    Vernita.Bridge=sum(Vernita.Bridge),
    Lower.Ringold=sum(Lower.Ringold),
    White.Bluffs=sum(White.Bluffs),
    Hanford=sum(Hanford)
    ) |>
  arrange(spp,fish_status,release_location,repID)


# loc_tab_nodups

saveRDS(DH_tag_code_summ,"QAQC_tab_3.rds")



################ #
# Using raw counts to look at fish outside of the `survival_use==FALSE`
################ #

tags_dat_raw_wrepID <- readRDS("tags_dat_raw_wrepID.rds")

tarmac_tag_tab <- readRDS("tarmac_tag_tab.rds")
tarmac_tag_evt_tab <- DH_tag_code_raw |> filter(tag_code %in% tarmac_tag_tab$tag_code) #|> left_join(tarmac_tag_tab)
# as.numeric(matrix(tarmac_tag_evt_tab[,2:14]))
# as.numeric(tarmac_tag_evt_tab[,2:14])
tmp=apply(tarmac_tag_evt_tab[,2:14],2,as.numeric)
tarmac_subb_tab <- data.frame(data.frame(tag_code=tarmac_tag_evt_tab[,1]) |> left_join(tarmac_tag_tab),tmp)

saveRDS(tarmac_subb_tab,"tarmac_tag_evt_tab.rds")



mort_tag_tab <- readRDS("mort_tag_tab.rds")
mort_tag_evt_tab <- DH_tag_code_raw |> filter(tag_code %in% mort_tag_tab$tag_code) #|> left_join(mort_tag_tab)
# as.numeric(matrix(mort_tag_evt_tab[,2:14]))
# as.numeric(mort_tag_evt_tab[,2:14])
tmp=apply(mort_tag_evt_tab[,2:14],2,as.numeric)
mort_subb_tab <- data.frame(data.frame(tag_code=mort_tag_evt_tab[,1]) |> left_join(mort_tag_tab),tmp)

saveRDS(mort_subb_tab,"mort_tag_evt_tab.rds")

# events_dat |> left_join(node_dat |> select(node_code,location))

table(table(node_dat$node_code))
dup_nodesDF <- subset(node_dat,node_code %in% node_dat[duplicated(node_dat$node_code),"node_code"])

# omitting duplicate nodes
events_dat_wnodes <- events_dat |> left_join(node_dat[!duplicated(node_dat$node_code),] |> select(node_code,location))
loc_tab_nodups <- node_dat[!duplicated(node_dat$location),] |> select(river_kilometer,location) |> arrange(-river_kilometer)
events_dat_wnodes$location <- factor(events_dat_wnodes$location,levels=loc_tab_nodups$location)

events_dat_wnodes |> pivot_wider(values_from=hits,names_from=location)
events_dat_wnodes |> select(tag_code,first_computed_datetime,location) |> pivot_wider(values_from=first_computed_datetime,names_from=location)
events_dat_wnodes2 <- events_dat_wnodes |> select(tag_code,first_computed_datetime,last_computed_datetime,location) |> group_by(tag_code,location) |> 
  summarize(first_dt=min(first_computed_datetime),
            last_dt=max(last_computed_datetime))


events_dat_wnodes2a <- events_dat_wnodes2  |> 
  select(tag_code,first_dt,location) 


events_dat_wnodes3 <- events_dat_wnodes2a |>
  pivot_wider(values_from=first_dt,names_from=location)

# events_dat_wnodes3 <- events_dat_wnodes2a |> 
#   mutate(detTF=is.Date(first_dt)) |> select(-first_dt) |> 
#   pivot_wider(values_from=first_dt,names_from=location)

DH_tag_code_raw <- data.frame(events_dat_wnodes3[,1],!is.na(events_dat_wnodes3[,-c(1)]))


tarmac_tag_tab <- readRDS("tarmac_tag_tab.rds")
tarmac_tag_evt_tab <- DH_tag_code_raw |> filter(tag_code %in% tarmac_tag_tab$tag_code) |> left_join(tarmac_tag_tab)

saveRDS(tarmac_tag_evt_tab,"tarmac_tag_evt_tab.rds")
DH_tag_code <- DH_tag_code_raw |> left_join(tags_dat_raw_wrepID |> select(tag_code,repID,fish_status,spp,release_location))

DH_tag_code_summ <- DH_tag_code |> group_by(spp,release_location,repID,fish_status) |> 
  summarize(
    Crescent.Bar=sum(Crescent.Bar),
    Sunland=sum(Sunland),
    Wanapum.BRZ=sum(Wanapum.BRZ),
    Wanapum=sum(Wanapum),
    Wanapum.Tailrace=sum(Wanapum.Tailrace),
    Mattawa=sum(Mattawa),
    Priest.BRZ=sum(Priest.BRZ),
    Priest=sum(Priest),
    Priest.Tailrace=sum(Priest.Tailrace),
    Vernita.Bridge=sum(Vernita.Bridge),
    Lower.Ringold=sum(Lower.Ringold),
    White.Bluffs=sum(White.Bluffs),
    Hanford=sum(Hanford)
  ) |>
  arrange(spp,fish_status,release_location,repID)


# loc_tab_nodups

saveRDS(DH_tag_code_summ,"QAQC_tab_raw_3.rds")


