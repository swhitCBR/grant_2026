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
tags_new_repID_DF <- tag_mtch_tbl %>%
  mutate(mtch_code=paste(species_code,as.integer(orig_repID))) %>%
  left_join(repID_pool_tab %>%
              mutate(mtch_code=paste(species_code,orig_repID)) %>%
              select(mtch_code,new_repID),
            by="mtch_code") 

# ATLAS files in the same place
# COMB_REL_ATLAS_csv_raw <- read.csv("C:/repos/grant_2026/mixing plots/ATLAS_files_for_RAB_10-15-26/COMB_REL_lrg_hanf_pooled_ATLAS.csv",header = F)
COMB_REL_ATLAS_csv_raw <- read.csv("data/Nov_run/COMB_REL_lrg_hanf_pooled_ATLAS.csv",header = F)


names(COMB_REL_ATLAS_csv_raw) <- c("release_spp", "num1", "tag_code", "release_time", 
                               "detection_time", "site_name", "num2", "lst_dt")
COMB_REL_ATLAS_csv <- COMB_REL_ATLAS_csv_raw %>% 
  left_join(tags_new_repID_DF %>% select(release_location,species_code,tag_code,new_repID),by = "tag_code") %>%
  mutate(new_repID = factor(new_repID))

DH_long_DF <- COMB_REL_ATLAS_csv %>% 
  mutate(spp_repID = paste(species_code,release_location,new_repID,sep="_")) %>%
  group_by(species_code,release_location,new_repID,tag_code) %>% 
  summarize(
    DHcode=factor(paste(num2,collapse = " "),
                  levels=c("1 1","0 1","2 0","1 0","0 0")))


rel_tot_DF_CHN <- DH_long_DF %>% ungroup() %>% 
  filter(species_code=="CHN") %>% 
  group_by(release_location,species_code,DHcode,.drop = FALSE) %>% 
  summarize(tot_count=n()) 

DH_long_DF_CHN <- DH_long_DF %>% 
  # mutate(spp_repID = paste(species_code,new_repID,sep="_")) %>%
  ungroup() %>% 
  filter(species_code=="CHN") %>% 
  mutate(new_repID=factor(new_repID,levels=c("1","2","3", "4", "5", "6", "7", "8", "9","10","11","12","13","14,15","16","17","18","19","20","21","22","23","24"))) %>%
  group_by(release_location,species_code,new_repID,DHcode,.drop = FALSE) %>%
  summarize(count=n()) %>% 
  tidyr::pivot_wider(names_from = new_repID,values_from = count,names_sort = TRUE,values_fill = 0) %>% #,names_repair = "universal") %>% 
  left_join(rel_tot_DF_CHN,by = c("release_location", "species_code", "DHcode")) %>%
  mutate(tot_count = tidyr::replace_na(tot_count, 0)) %>%
  relocate(release_location,species_code,DHcode,tot_count) %>%
  arrange(release_location,species_code,DHcode)


DH_wide_DF_CHN <- DH_long_DF_CHN %>%
  ungroup() %>%
  # tot_count is a per-DHcode total, so it would repeat misleadingly across replicates
  select(-tot_count) %>%
  tidyr::pivot_longer(
    cols = -c(release_location, species_code, DHcode),
    names_to = "new_repID",
    values_to = "count"
  ) %>%
  mutate(new_repID = factor(new_repID, levels = names(DH_long_DF_CHN)[-(1:4)])) %>%
  tidyr::pivot_wider(names_from = DHcode,values_from = count,names_sort = TRUE,values_fill = 0)# %>% #,names_repair = "universal") %>% 




rel_tot_DF_STH <- DH_long_DF %>% ungroup() %>% 
  filter(species_code=="STH") %>% 
  group_by(release_location,species_code,DHcode,.drop = FALSE) %>% 
  summarize(tot_count=n()) 

DH_long_DF_STH <- DH_long_DF %>% 
  # mutate(spp_repID = paste(species_code,new_repID,sep="_")) %>%
  ungroup() %>% 
  filter(species_code=="STH") %>% 
  mutate(new_repID=factor(new_repID,levels=c("1","2","3", "4", "5", "6", "7", "8", "9,10","11","12","13","14","15","16","17","18","19","20,21,22","23,24"))) %>%
  group_by(release_location,species_code,new_repID,DHcode,.drop = FALSE) %>%
  summarize(count=n()) %>% 
  tidyr::pivot_wider(names_from = new_repID,values_from = count,names_sort = TRUE,values_fill = 0) %>% #,names_repair = "universal") %>% 
  left_join(rel_tot_DF_STH,by = c("release_location", "species_code", "DHcode")) %>%
  mutate(tot_count = tidyr::replace_na(tot_count, 0)) %>%
  relocate(release_location,species_code,DHcode,tot_count)



DH_wide_DF_STH <- DH_long_DF_STH %>%
  ungroup() %>%
  # tot_count is a per-DHcode total, so it would repeat misleadingly across replicates
  select(-tot_count) %>%
  tidyr::pivot_longer(
    cols = -c(release_location, species_code, DHcode),
    names_to = "new_repID",
    values_to = "count"
  ) %>%
  mutate(new_repID = factor(new_repID, levels = names(DH_long_DF_STH)[-(1:4)])) %>%
  tidyr::pivot_wider(names_from = DHcode,values_from = count,names_sort = TRUE,values_fill = 0)# %>% #,names_repair = "universal") %>% 
  




# Same tables stacked on a single sheet (CHN and STH have different replicate columns, so they can't be row-bound)
wb_DH_one <- openxlsx::createWorkbook()
openxlsx::addWorksheet(wb_DH_one, "DH_counts wide")
section_title_style <- openxlsx::createStyle(fontSize = 14, textDecoration = c("bold", "underline"))
main_title_style <- openxlsx::createStyle(fontSize = 18, textDecoration = "bold",
                                          border = "bottom", borderStyle = "medium")
main_title_cols <- 1:max(ncol(DH_long_DF_CHN), ncol(DH_long_DF_STH))
chn_title_row <- 3
sth_title_row <- chn_title_row + nrow(DH_long_DF_CHN) + 3
openxlsx::writeData(wb_DH_one, "DH_counts wide", "Replicate-Level Detection History Counts", startRow = 1)
# Bottom border spans the width of the widest table
openxlsx::addStyle(wb_DH_one, "DH_counts wide", main_title_style, rows = 1, cols = main_title_cols, gridExpand = TRUE)
openxlsx::writeData(wb_DH_one, "DH_counts wide", "Chinook", startRow = chn_title_row)
openxlsx::addStyle(wb_DH_one, "DH_counts wide", section_title_style, rows = chn_title_row, cols = 1)
openxlsx::writeData(wb_DH_one, "DH_counts wide", DH_long_DF_CHN, startRow = chn_title_row + 1)
openxlsx::writeData(wb_DH_one, "DH_counts wide", "Steelhead", startRow = sth_title_row)
openxlsx::addStyle(wb_DH_one, "DH_counts wide", section_title_style, rows = sth_title_row, cols = 1)
# "replicateIDs:" labels on the same rows as the species labels
rep_label_style <- openxlsx::createStyle(fontSize = 12, textDecoration = "underline")
for (rr in c(chn_title_row, sth_title_row)) {
  openxlsx::writeData(wb_DH_one, "DH_counts wide", "replicate IDs:", startRow = rr, startCol = 5)
  openxlsx::addStyle(wb_DH_one, "DH_counts wide", rep_label_style, rows = rr, cols = 5)
}
openxlsx::writeData(wb_DH_one, "DH_counts wide", DH_long_DF_STH, startRow = sth_title_row + 1)

# Table borders: top and bottom on header row, bottom on last row
header_border_style <- openxlsx::createStyle(border = "topbottom", borderStyle = "thin")
last_row_border_style <- openxlsx::createStyle(border = "bottom", borderStyle = "thin")
tbl_specs <- list(
  list(df = DH_long_DF_CHN, header_row = chn_title_row + 1),
  list(df = DH_long_DF_STH, header_row = sth_title_row + 1)
)
for (spec in tbl_specs) {
  tbl_cols <- seq_len(ncol(spec$df))
  openxlsx::addStyle(wb_DH_one, "DH_counts wide", header_border_style,
                     rows = spec$header_row, cols = tbl_cols, gridExpand = TRUE, stack = TRUE)
  openxlsx::addStyle(wb_DH_one, "DH_counts wide", last_row_border_style,
                     rows = spec$header_row + nrow(spec$df), cols = tbl_cols, gridExpand = TRUE, stack = TRUE)
}

# Second sheet: Totals section on top, Replicate-Level section below; CHN left, STH right
long_sheet <- "DH_counts_long"
openxlsx::addWorksheet(wb_DH_one, long_sheet)

col_gap <- 2
rel_tot_CHN_out <- dplyr::ungroup(rel_tot_DF_CHN)
rel_tot_STH_out <- dplyr::ungroup(rel_tot_DF_STH)
DH_wide_CHN_out <- dplyr::ungroup(DH_wide_DF_CHN)
DH_wide_STH_out <- dplyr::ungroup(DH_wide_DF_STH)

# Sheet title in row 1, blank row 2
tot_title_row <- 3
tot_right_col <- ncol(rel_tot_CHN_out) + col_gap + 1
rep_right_col <- ncol(DH_wide_CHN_out) + col_gap + 1
long_title_cols <- 1:max(tot_right_col + ncol(rel_tot_STH_out) - 1,
                         rep_right_col + ncol(DH_wide_STH_out) - 1)
openxlsx::writeData(wb_DH_one, long_sheet, "Detection History Grand Totals and Replicate-Level Counts", startRow = 1)
openxlsx::addStyle(wb_DH_one, long_sheet, main_title_style, rows = 1, cols = long_title_cols, gridExpand = TRUE)

# Section 1: Totals
openxlsx::writeData(wb_DH_one, long_sheet, "Totals", startRow = tot_title_row)
openxlsx::addStyle(wb_DH_one, long_sheet, section_title_style, rows = tot_title_row, cols = 1)
# Tables start two rows below each section header; the gap row holds the species labels
openxlsx::writeData(wb_DH_one, long_sheet, rel_tot_CHN_out, startRow = tot_title_row + 2, startCol = 1)
openxlsx::writeData(wb_DH_one, long_sheet, rel_tot_STH_out, startRow = tot_title_row + 2, startCol = tot_right_col)

# Section 2: Replicate-Level, two blank rows below the longer totals table
rep_title_row <- tot_title_row + 2 + max(nrow(rel_tot_CHN_out), nrow(rel_tot_STH_out)) + 3
openxlsx::writeData(wb_DH_one, long_sheet, "Replicate-Level", startRow = rep_title_row)
openxlsx::addStyle(wb_DH_one, long_sheet, section_title_style, rows = rep_title_row, cols = 1)
openxlsx::writeData(wb_DH_one, long_sheet, DH_wide_CHN_out, startRow = rep_title_row + 2, startCol = 1)
openxlsx::writeData(wb_DH_one, long_sheet, DH_wide_STH_out, startRow = rep_title_row + 2, startCol = rep_right_col)

# Borders on the 4 component tables: top/bottom on header row, bottom on last row
# plus a species label in the gap row above each table
species_label_style <- openxlsx::createStyle(fontSize = 12, textDecoration = "bold")
long_tbl_specs <- list(
  list(df = rel_tot_CHN_out,  header_row = tot_title_row + 2, start_col = 1,             label = "Chinook"),
  list(df = rel_tot_STH_out,  header_row = tot_title_row + 2, start_col = tot_right_col, label = "Steelhead"),
  list(df = DH_wide_CHN_out,  header_row = rep_title_row + 2, start_col = 1,             label = "Chinook"),
  list(df = DH_wide_STH_out,  header_row = rep_title_row + 2, start_col = rep_right_col, label = "Steelhead")
)
for (spec in long_tbl_specs) {
  openxlsx::writeData(wb_DH_one, long_sheet, spec$label, startRow = spec$header_row - 1, startCol = spec$start_col)
  openxlsx::addStyle(wb_DH_one, long_sheet, species_label_style,
                     rows = spec$header_row - 1, cols = spec$start_col)
  tbl_cols <- spec$start_col + seq_len(ncol(spec$df)) - 1
  openxlsx::addStyle(wb_DH_one, long_sheet, header_border_style,
                     rows = spec$header_row, cols = tbl_cols, gridExpand = TRUE, stack = TRUE)
  openxlsx::addStyle(wb_DH_one, long_sheet, last_row_border_style,
                     rows = spec$header_row + nrow(spec$df), cols = tbl_cols, gridExpand = TRUE, stack = TRUE)
}

# "Detection histories" label in the gap row above the first DH column ("1 1") of the replicate-level tables
dh_label_style <- openxlsx::createStyle(fontSize = 12, textDecoration = "underline")
for (spec in long_tbl_specs[3:4]) {
  dh_col <- spec$start_col + match("1 1", names(spec$df)) - 1
  openxlsx::writeData(wb_DH_one, long_sheet, "Detection histories:", startRow = spec$header_row - 1, startCol = dh_col)
  openxlsx::addStyle(wb_DH_one, long_sheet, dh_label_style, rows = spec$header_row - 1, cols = dh_col)
}

# Put DH_counts_long first
openxlsx::worksheetOrder(wb_DH_one) <- c(2, 1)

openxlsx::saveWorkbook(
  wb_DH_one,
  "media/xlsx/replicate_regrouping/SW_replicate_level_DH_counts_11_1_26.xlsx",
  overwrite = TRUE
)

################################ #
## Attributes table for Atlas
################################ #

new_rep_ID_attrib_ATLAS <- tags_new_repID_DF %>%
  select(tag_code,new_repID,species_code) %>%
  mutate(repID_code=paste(species_code,new_repID,sep="_")) %>%
  select(-species_code,-new_repID ) %>%
  # rename(repID=new_repID) %>%
  mutate(repID_code=gsub(x=repID_code,pattern=",",replacement = "_"))#,
         # repID=gsub(x=repID,pattern=",",replacement = "_"))

table(new_rep_ID_attrib_ATLAS$repID_code)

write.csv(new_rep_ID_attrib_ATLAS,"data/Nov_run/new_rep_ID_attrib_ATLAS.csv",row.names = FALSE,quote = FALSE)


