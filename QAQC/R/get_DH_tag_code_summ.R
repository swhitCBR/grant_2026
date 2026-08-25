

get_DH_tag_code_summ <- function (node_dat_in,events_dat_in,tags_dat_wrepID_in){
  

  table(table(node_dat_in$node_code))
  dup_nodesDF <- subset(node_dat_in,node_code %in% node_dat_in[duplicated(node_dat_in$node_code),"node_code"])
  
  # omitting duplicate nodes
  events_dat_wnodes <- events_dat_in |> left_join(node_dat_in[!duplicated(node_dat_in$node_code),] |> select(node_code,location))
  loc_tab_nodups <- node_dat_in[!duplicated(node_dat_in$location),] |> select(river_kilometer,location) |> arrange(-river_kilometer)
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
  
  DH_tag_code_raw <- data.frame(events_dat_wnodes3[,1],!is.na(events_dat_wnodes3[,-c(1)]))
  
  DH_tag_code <- DH_tag_code_raw |> left_join(tags_dat_wrepID_in |> select(tag_code,repID,fish_status,spp,release_location))
  
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
  
  return(DH_tag_code_summ)
  
}
