library(dplyr)
library(tidyr)

setwd("C:/repos/grant_2026/QAQC")
csv_fl_ls <- readRDS("tmp_data/csv_fl_ls.rds")
events_dat <- csv_fl_ls$GPUD2026_events_17Aug2026
node_dat <- csv_fl_ls$GPUD2026_nodes_12Aug2026

# tags_dat_ALIVE_EUTH_wrepID <- readRDS("tmp_data/tags_dat_ALIVE_EUTH_wrepID.rds")
# tags_dat_raw_wrepID <- readRDS("tmp_data/tags_dat_raw_wrepID.rds")

tag_subsets_ls <- readRDS("tmp_data/tag_subsets_ls.rds")

source("R/get_DH_tag_code_summ.R")


# tag_ALIVE_EUTH_DH_summ <- get_DH_tag_code_summ(node_dat_in = node_dat,events_dat_in = events_dat,tags_dat_wrepID_in = tags_dat_ALIVE_EUTH_wrepID)
# tag_raw_DH_summ <- get_DH_tag_code_summ(node_dat_in = node_dat,events_dat_in = events_dat,tags_dat_wrepID_in = tags_dat_raw_wrepID)

names(tag_subsets_ls)
tag_SU_EUTH_ACTIVE_DH_summ <- get_DH_tag_code_summ(node_dat_in = node_dat,events_dat_in = events_dat,tags_dat_wrepID_in = tag_subsets_ls[["tags_SURVUSE_OR_EUTH_&_ACTIVE"]])
tag_ALIVE_EUTH_DH_summ <- get_DH_tag_code_summ(node_dat_in = node_dat,events_dat_in = events_dat,tags_dat_wrepID_in = tag_subsets_ls[["tags_ALIVE_or_EUTH"]])
tag_raw_DH_summ <- get_DH_tag_code_summ(node_dat_in = node_dat,events_dat_in = events_dat,tags_dat_wrepID_in = tag_subsets_ls[["RAW"]])


tag_raw_DH_summ <- tag_raw_DH_summ |> 
  rename(rel_loc=release_location,
         status=fish_status,CBAR=Crescent.Bar,WAN=Wanapum,WAN.BRZ=Wanapum.BRZ,WAN.TR=Wanapum.Tailrace,WB=White.Bluffs,HAN=Hanford,VRBR=Vernita.Bridge,PR.TR=Priest.Tailrace,PR.BRZ=Priest.BRZ,MATT=Mattawa,SUN=Sunland,LRNG=Lower.Ringold,PR=Priest) |>
  mutate(rel_loc=ifelse(rel_loc=="Rock Island Tailrace","RI","PR"))

tag_ALIVE_EUTH_DH_summ <- tag_ALIVE_EUTH_DH_summ |> 
  rename(rel_loc=release_location,status=fish_status,CBAR=Crescent.Bar,WAN=Wanapum,WAN.BRZ=Wanapum.BRZ,WB=White.Bluffs,HAN=Hanford,VRBR=Vernita.Bridge,PR.TR=Priest.Tailrace,PR.BRZ=Priest.BRZ,MATT=Mattawa,SUN=Sunland,LRNG=Lower.Ringold,PR=Priest) |>
  mutate(rel_loc=ifelse(rel_loc=="Rock Island Tailrace","RI","PR"))


tag_SU_EUTH_ACTIVE_DH_summ <- tag_SU_EUTH_ACTIVE_DH_summ |>
  rename(rel_loc=release_location,status=fish_status,CBAR=Crescent.Bar,WAN=Wanapum,WAN.BRZ=Wanapum.BRZ,WB=White.Bluffs,HAN=Hanford,VRBR=Vernita.Bridge,PR.TR=Priest.Tailrace,PR.BRZ=Priest.BRZ,MATT=Mattawa,SUN=Sunland,LRNG=Lower.Ringold,PR=Priest) |>
  mutate(rel_loc=ifelse(rel_loc=="Rock Island Tailrace","RI","PR"))

  

# tag_ALIVE_EUTH_DH_summ <- tag_ALIVE_EUTH_DH_summ |> 
#   rename(rel_loc=release_location,status=fish_status,CBAR=Crescent.Bar,WAN=Wanapum,WAN.BRZ=Wanapum.BRZ,WB=White.Bluffs,HAN=Hanford,VRBR=Vernita.Bridge,PR.TR=Priest.Tailrace,PR.BRZ=Priest.BRZ,MATT=Mattawa,SUN=Sunland,LRNG=Lower.Ringold,PR=Priest) |>
#   mutate(rel_loc=ifelse(rel_loc=="Rock Island Tailrace","RI","PR"))

# tag_SU_EUTH_ACTIVE_DH_summ


names(tag_ALIVE_EUTH_DH_summ)

# AE_RI_summ <- tag_ALIVE_EUTH_DH_summ |> filter(rel_loc=="Rock Island Tailrace")
# AE_PR_summ <-  tag_ALIVE_EUTH_DH_summ |> filter(rel_loc=="Priest Rapids Tailrace")
# 
# raw_RI_summ <- tag_raw_DH_summ |> filter(rel_loc=="Rock Island Tailrace")
# raw_PR_summ <-  tag_raw_DH_summ |> filter(rel_loc=="Priest Rapids Tailrace")

SU_E_ACT_RI_summ <- tag_SU_EUTH_ACTIVE_DH_summ |> filter(rel_loc=="RI")
SU_E_ACT_PR_summ <-  tag_SU_EUTH_ACTIVE_DH_summ |> filter(rel_loc=="PR")


AE_RI_summ <- tag_ALIVE_EUTH_DH_summ |> filter(rel_loc=="RI")
AE_PR_summ <-  tag_ALIVE_EUTH_DH_summ |> filter(rel_loc=="PR")

raw_RI_summ <- tag_raw_DH_summ |> filter(rel_loc=="RI")
raw_PR_summ <-  tag_raw_DH_summ |> filter(rel_loc=="PR")


tag_DH_ls <- list(
  "SU_E_ACT_RI_summ"=SU_E_ACT_RI_summ,
  "SU_E_ACT_PR_summ"=SU_E_ACT_PR_summ,
   # "AE_RI_summ"=AE_RI_summ,
   # "AE_PR_summ"=AE_PR_summ,
   "raw_RI_summ"=raw_RI_summ,
   "raw_PR_summ"=raw_PR_summ
   )

saveRDS(tag_DH_ls,"tmp_data/tag_DH_ls.rds")
# tag_DH_ls <- readRDS(tag_DH_ls,"tmp_data/tag_DH_ls.rds")


# add_DH_qsec3_elwise <- function(header_in="Rock Island Release",spp_in="CHN",status_in="Alive", header_level="####"){
add_DH_qsec3_elwise <- function(tag_DH_ls_nm_in="raw_RI_summ",header_in,spp_in,status_in, header_level,status_is=TRUE){
  c(
    paste(header_level,header_in),
    "```{r,echo=F,eval=T}",
    # paste0("knitr::kable(get_conting_tabs_by_name(tags_dat_in = tag_subsets_ls[['",tag_sub_nm,"']],tb_nm_in = '",tb_nm_in,"',ele_nm_in = '",ele_nm_in,"'))"),
    if(status_is){
    paste0("knitr::kable(tag_DH_ls$'",tag_DH_ls_nm_in,"' |> filter(spp=='",spp_in,"' & status=='",status_in,"'))")
    } else{
      paste0("knitr::kable(tag_DH_ls$'",tag_DH_ls_nm_in,"' |> filter(spp=='",spp_in,"' & status!='",status_in,"'))")        
    }
    ,
    "```"
  )}

# add_DH_qsec3_elwise()
# raw_PR_summ


source("C:/repos/grant_2026/QAQC/R/append_to_qmd_etc.R")
#' Title
#'
#' @returns
#'
#' @export
#' @examples
append_DH_tabs_qmd<- function(tab_subset_nm="RAW"){
  unlink("SW_QAQC_new_summ_2_3.qmd")
  file.copy("SW_QAQC_new_summ_2_3_template.qmd", "SW_QAQC_new_summ_2_3.qmd")
  
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n{{< pagebreak >}}\n")
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "# Detection Histories for All Tags")
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n Includes 'Tarmac' and 'Mortality' groups (i.e., fish dropped on the ground and that died during handing, respectively) \n")  
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n## Live Fish\n")
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n### Chinook\n")
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Rock Island Release",spp_in="CHN",status_in="Alive", header_level="####",tag_DH_ls_nm_in="raw_RI_summ"))
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Priest Rapids Release",spp_in="CHN",status_in="Alive", header_level="####",tag_DH_ls_nm_in="raw_PR_summ"))
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "{{< pagebreak >}}")
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n### Steelhead\n")
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Rock Island Release",spp_in="STH",status_in="Alive", header_level="####",tag_DH_ls_nm_in="raw_RI_summ"))
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Priest Rapids Release",spp_in="STH",status_in="Alive", header_level="####",tag_DH_ls_nm_in="raw_PR_summ"))
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "{{< pagebreak >}}")
  
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n## Dead Fish\n")
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n### Chinook\n")
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Rock Island Release",spp_in="CHN",status_in="Alive", header_level="####",status_is=FALSE,tag_DH_ls_nm_in="raw_RI_summ"))
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Priest Rapids Release",spp_in="CHN",status_in="Alive", header_level="####",status_is=FALSE,tag_DH_ls_nm_in="raw_PR_summ"))
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "{{< pagebreak >}}")
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n### Steelhead\n")
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Rock Island Release",spp_in="STH",status_in="Alive", header_level="####",status_is=FALSE,tag_DH_ls_nm_in="raw_RI_summ"))
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Priest Rapids Release",spp_in="STH",status_in="Alive", header_level="####",status_is=FALSE,tag_DH_ls_nm_in="raw_PR_summ"))
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "{{< pagebreak >}}")
  
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n# Detection Histories for `Alive/Euthanized`")
  # # append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n Includes 'Tarmac' and 'Mortality' groups (i.e., fish dropped on the ground and that died during handing, respectively) \n")  
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n## Live Fish\n")
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n### Chinook\n")
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Rock Island Release",spp_in="CHN",status_in="Alive", header_level="####",tag_DH_ls_nm_in="AE_RI_summ"))
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Priest Rapids Release",spp_in="CHN",status_in="Alive", header_level="####",tag_DH_ls_nm_in="AE_PR_summ"))
  # 
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "{{< pagebreak >}}")
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n### Steelhead\n")
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Rock Island Release",spp_in="STH",status_in="Alive", header_level="####",tag_DH_ls_nm_in="AE_RI_summ"))
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Priest Rapids Release",spp_in="STH",status_in="Alive", header_level="####",tag_DH_ls_nm_in="AE_PR_summ"))
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "{{< pagebreak >}}")
  # 
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n## Dead Fish\n")
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n### Chinook\n")
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Rock Island Release",spp_in="CHN",status_in="Alive", header_level="####",status_is=FALSE,tag_DH_ls_nm_in="AE_RI_summ"))
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Priest Rapids Release",spp_in="CHN",status_in="Alive", header_level="####",status_is=FALSE,tag_DH_ls_nm_in="AE_PR_summ"))
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "{{< pagebreak >}}")
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n### Steelhead\n")
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Rock Island Release",spp_in="STH",status_in="Alive", header_level="####",status_is=FALSE,tag_DH_ls_nm_in="AE_RI_summ"))
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Priest Rapids Release",spp_in="STH",status_in="Alive", header_level="####",status_is=FALSE,tag_DH_ls_nm_in="AE_PR_summ"))
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "{{< pagebreak >}}")
  
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n# Detection Histories for `tags_SURVUSE_OR_EUTH_&_ACTIVE`")
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n Includes 'Tarmac' and 'Mortality' groups (i.e., fish dropped on the ground and that died during handing, respectively) \n")  
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n## Live Fish\n")
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n### Chinook\n")
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Rock Island Release",spp_in="CHN",status_in="Alive", header_level="####",tag_DH_ls_nm_in="SU_E_ACT_RI_summ"))
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Priest Rapids Release",spp_in="CHN",status_in="Alive", header_level="####",tag_DH_ls_nm_in="SU_E_ACT_PR_summ"))
  
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "{{< pagebreak >}}")
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n### Steelhead\n")
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Rock Island Release",spp_in="STH",status_in="Alive", header_level="####",tag_DH_ls_nm_in="SU_E_ACT_RI_summ"))
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Priest Rapids Release",spp_in="STH",status_in="Alive", header_level="####",tag_DH_ls_nm_in="SU_E_ACT_PR_summ"))
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "{{< pagebreak >}}")
  
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n## Dead Fish\n")
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n### Chinook\n")
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Rock Island Release",spp_in="CHN",status_in="Alive", header_level="####",status_is=FALSE,tag_DH_ls_nm_in="SU_E_ACT_RI_summ"))
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Priest Rapids Release",spp_in="CHN",status_in="Alive", header_level="####",status_is=FALSE,tag_DH_ls_nm_in="SU_E_ACT_PR_summ"))
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "{{< pagebreak >}}")
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "\n### Steelhead\n")
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Rock Island Release",spp_in="STH",status_in="Alive", header_level="####",status_is=FALSE,tag_DH_ls_nm_in="SU_E_ACT_RI_summ"))
  append_to_qmd("SW_QAQC_new_summ_2_3.qmd",add_DH_qsec3_elwise(header_in="Priest Rapids Release",spp_in="STH",status_in="Alive", header_level="####",status_is=FALSE,tag_DH_ls_nm_in="SU_E_ACT_PR_summ"))
  # append_to_qmd("SW_QAQC_new_summ_2_3.qmd", "{{< pagebreak >}}")


  return(NULL) 
}

append_DH_tabs_qmd()



# unlink("SW_QAQC_new_summ_2_3.qmd")
# file.copy("SW_QAQC_new_summ_2_3_template.qmd", "SW_QAQC_new_summ_2_3.qmd")
# append_conting_tabs_qmd(tab_subset_nm = "RAW")
# # append_conting_tabs_qmd(tab_subset_nm = "tags_ALIVE_or_EUTH")
# append_conting_tabs_qmd(tab_subset_nm = "tags_SURVUSE_OR_EUTH_&_ACTIVE" )
# append_conting_tabs_qmd(tab_subset_nm = "tags_ALIVE_ACTIVE_OTHER_OR_EUTH_ACTIVE_OTHER" )



library(quarto)
quarto_render("SW_QAQC_new_summ_2_3.qmd")






# # saveRDS(tag_DH_ls,"tmp_data/tag_DH_ls.rds")
# 
# 
# 
# head(tag_DH_ls$raw_PR_summ)
# tail(tag_DH_ls$AE_PR_summ)
# 
# 
# head(tag_DH_ls$raw_PR_summ)
# tail(tag_DH_ls$AE_PR_summ)
