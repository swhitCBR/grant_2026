
get_rel_loc_by_repID_tabs <- function(tags_dat_wrepID_in){

  tags_dat_summ2 <- tags_dat_wrepID_in |>
  group_by(spp,repID,release_location,tag_group) |>
  summarize(n_tags=length(unique(tag_code))) |>
  pivot_wider(names_from=c(release_location,tag_group),values_from = n_tags) |>
  ungroup()  |> 
  mutate(code2=paste(spp,repID))

tags_dat_summ3 <- tags_dat_summ2 |> left_join(
  rep_id_tab |> filter(release_location=="Priest Rapids Tailrace") |> rename(PR_rel_date=rel_date) |> select(PR_rel_date,code2)) |> left_join(
    rep_id_tab |> filter(release_location=="Rock Island Tailrace") |> rename(RI_rel_date=rel_date) |> select(RI_rel_date,code2))

names(tags_dat_summ3)[3:6] <- c("PRT","PRT_d","RI","RI_d")

tags_dat_summ4 <- tags_dat_summ3 |> 
  relocate(spp,repID,RI,RI_d,PRT,PRT_d) |>
  mutate(RI_rel=format(RI_rel_date,"%m-%d"),
         PR_rel=format(PR_rel_date,"%m-%d")) |>
  select(-code2,-RI_rel_date,-PR_rel_date) 

rel_loc_by_repID_ls <-list(
  "CHN"=tags_dat_summ4 |> filter(spp=="CHN"),
  "STH"=tags_dat_summ4 |> filter(spp=="STH"))

return(rel_loc_by_repID_ls)
}

