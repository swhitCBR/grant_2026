library(dplyr)
library(ggplot2)
library(gridExtra)

source("R/compute_f_tests_by_reach.R")
# sourceable compilation fie
source("analysis/01_extracting_ATLAS_rtfs_COMB.R")


STH_ATLAS_out <- readRDS("results/STH_ATLAS_out.rds")

STH_estDF_4plt <- STH_ATLAS_out$"STH_Pair_CJS_tab"
STH_estDF_4plt$fixed <- ifelse(STH_estDF_4plt$SE==0,"fixed","est")
STH_estDF_4plt$spp_repID <- factor(STH_estDF_4plt$spp_repID,
                                   levels=c("1","2","3","4","5","6","7","8","9_10","11","12","13","14","15",
                                            "16","17","18","19","20_21_22","23_24"))


CHN_ATLAS_out <- readRDS("results/CHN_ATLAS_out.rds")


CHN_estDF_4plt <- CHN_ATLAS_out$"CHN_Pair_CJS_tab"
CHN_estDF_4plt$fixed <- ifelse(CHN_estDF_4plt$SE==0,"fixed","est")
CHN_estDF_4plt$spp_repID <- factor(CHN_estDF_4plt$spp_repID,
                                   levels=c("1","2","3","4","5","6","7","8","9","10","11","12","13","14_15",
                                            "16","17","18","19","20","21","22","23","24"))

# CHN_estDF_4plt %>% filter(spp_repID=="22")

# COMB_pool_est_tb_4xl
COMB_spp_ATLAS_ests <- bind_rows(
  data.frame(species="CHN",CHN_estDF_4plt),
  data.frame(species="STH",STH_estDF_4plt))

# Extracting pooled esitmates
COMB_pool_est_tbDF <- COMB_spp_ATLAS_ests %>% group_by(species) %>% filter( new_repID=="pool" ) |>
  select(species,new_repID,spp_rel_loc,param,est,SE,fixed) |> 
  mutate(est_se=paste0(est," (",format(round(SE, 4), nsmall = 4),")"))#filter(param %in% c("surv_p","lambda")) |> 

COMB_pool_est_tb_4xl<- list(
"pool_pair_surv"=COMB_pool_est_tbDF |> 
    select(species,spp_rel_loc,param,est_se) |>
    filter(param %in% c("pair_surv_p")) |>
    tidyr::pivot_wider(names_from = param,values_from = est_se) #|>
    # rename(S_hat_rel_to_LR = surv_p)
,
  
"pool_surv_lambda"=COMB_pool_est_tbDF |> 
  select(species,spp_rel_loc,param,est_se) |>
  filter(param %in% c("surv_p","lambda")) |>
  tidyr::pivot_wider(names_from = param,values_from = est_se) |>
  rename(S_hat_rel_to_LR = surv_p),

"pool_det_LR"=COMB_pool_est_tbDF |> 
  select(species,spp_rel_loc,param,est_se) |>
  filter(param %in% c("det_p")) |>
  tidyr::pivot_wider(names_from = param,values_from = est_se) |>
  mutate(det_p=gsub(det_p, pattern = "[(]0.0000[])]", replacement = "*")) |>
  rename(p_det_LR = det_p)
)

# |>
#   tidyr::pivot_wider(names_from = param,values_from = est_se)




COMB_spp_ATLAS_ests <- bind_rows(
  data.frame(species="CHN",CHN_estDF_4plt),
  data.frame(species="STH",STH_estDF_4plt))

COMB_F_test_tbDF <- COMB_spp_ATLAS_ests %>% group_by(species) %>% filter(param=="pair_surv_p" & new_repID!="pool") %>%
  mutate(CV = SE / est,wt_tmp=1/(CV^2),invCV2_wt=wt_tmp/sum(wt_tmp)) |>
  select(-wt_tmp)


ii=1
COMB_short_F_ls=COMB_long_F_ls=list()
for(ii in 1:2){
  COMB_F_test_res_short <- compute_f_tests_by_reach(
    COMB_F_test_tbDF[COMB_F_test_tbDF$species==unique(COMB_F_test_tbDF$species)[ii],] |>
      transmute(reach = param, tagger = repID, estimate = est, se = SE),
    verbose = FALSE)
  
  COMB_F_test_res_long <- compute_f_tests_by_reach(
    COMB_F_test_tbDF[COMB_F_test_tbDF$species==unique(COMB_F_test_tbDF$species)[ii],] |>
      transmute(reach = param, tagger = repID, estimate = est, se = SE),
    verbose = TRUE)

  COMB_short_F_ls[[ii]] <- data.frame(species=unique(COMB_F_test_tbDF$species)[ii],COMB_F_test_res_short,
                                      num=COMB_F_test_res_long$numerator,denom=  COMB_F_test_res_long$denominator)
  
  
  COMB_long_F_ls[[ii]] <- data.frame(species=unique(COMB_F_test_tbDF$species)[ii],COMB_F_test_res_long)
  
}


COMB_F_test_short_tb <- do.call(rbind,COMB_short_F_ls)


CHN_F_test_long <- COMB_long_F_ls[[1]] |>
  select(-numerator, -denominator, -df, -F_statistic, -p_value) |>
  tidyr::pivot_longer(
    -reach,
    names_to = c("repID", ".value"),
    names_pattern = "^(.*)_(est|se)$"
  ) |>
  filter(!is.na(est)) |>
  # verbose output stores estimates as character strings
  mutate(across(c(est, se), as.numeric)) |>
  mutate(S_barhat=mean(est),est_minus_S_barhat2=(est-S_barhat)^2,
         S_var=se^2)

STH_F_test_long <- COMB_long_F_ls[[2]] |>
  select(-numerator, -denominator, -df, -F_statistic, -p_value) |>
  tidyr::pivot_longer(
    -reach,
    names_to = c("repID", ".value"),
    names_pattern = "^(.*)_(est|se)$"
  ) |>
  filter(!is.na(est)) |>
  # verbose output stores estimates as character strings
  mutate(across(c(est, se), as.numeric)) |>
  mutate(S_barhat=mean(est),est_minus_S_barhat2=(est-S_barhat)^2,
         S_var=se^2)

# options(digits=4)

COMB_wt_avg_repID_tbDF <- COMB_F_test_tbDF %>% group_by(species,type) %>%
  summarize(wt_avg=sum(invCV2_wt*est),
            wt_avgSE=sqrt(sum((invCV2_wt^2)*SE^2)),
            lcl=wt_avg-1.96*wt_avgSE,
            ucl=wt_avg+1.96*wt_avgSE)

rep_level_ests_Ftests_tb_ls<- list(
  "COMB_spp_ATLAS_ests"=COMB_spp_ATLAS_ests,
  "COMB_pool_est_tbDF"=COMB_pool_est_tbDF,
  "COMB_F_test_tbDF"=COMB_F_test_tbDF,
  "COMB_F_test_short_tb"=COMB_F_test_short_tb,
  "CHN_F_test_long"=CHN_F_test_long,
  "STH_F_test_long"=STH_F_test_long,
  "COMB_wt_avg_repID_tbDF"=COMB_wt_avg_repID_tbDF)

saveRDS(rep_level_ests_Ftests_tb_ls,"results/rep_level_ests_Ftests_tb_ls.rds")



# rearranging pooled estimates for table 3.6
CHN_pair=COMB_pool_est_tb_4xl$"pool_pair_surv" |> filter(species=="CHN")
STH_pair=COMB_pool_est_tb_4xl$"pool_pair_surv" |> filter(species=="STH")

CHN_top=COMB_pool_est_tb_4xl$"pool_surv_lambda" |> filter(species=="CHN")
CHN_bottom=COMB_pool_est_tb_4xl$"pool_det_LR" |> filter(species=="CHN")

STH_top=COMB_pool_est_tb_4xl$"pool_surv_lambda" |> filter(species=="STH")
STH_bottom=COMB_pool_est_tb_4xl$"pool_det_LR" |> filter(species=="STH")

COMB_F_tb <- COMB_F_test_short_tb |> select(species, reach,num,denom, F_statistic, p_value) |> 
  mutate(F_stat=format(round(F_statistic, 4), nsmall = 4),
                       "P-value"=format(round(p_value, 4))) |> select(-reach,-F_statistic,-p_value)

COMB_wtavg_tb <- COMB_wt_avg_repID_tbDF |> select(species, wt_avg,wt_avgSE) |> 
  mutate(wt_avg=format(round(wt_avg, 4), nsmall = 4),
         wt_avgSE=format(round(wt_avgSE, 4))) #|> select(-reach,-F_statistic,-p_value)

# loading tables compiled from ATLAS files
CHN_ATLAS_TLSR <- readRDS("results/CHN_ATLAS_TLSR_out.rds")
STH_ATLAS_TLSR <- readRDS("results/STH_ATLAS_TLSR_out.rds")

# extracting tag-life adjusted reach specific estimates

#
CHN_post_pooled_reach_ests_tb <- CHN_ATLAS_TLSR$"CHN_TL_Modeled_tab" |>
  filter(param %in% c("surv_p")) |>
  mutate(reachIND=LETTERS[c(1:6,6)], est_se=paste0(est," (",format(round(SE, 4), nsmall = 4),")")) |>
  tidyr::pivot_wider(names_from = rel_loc, values_from = est_se) |>
  rename(R1=RI,R2=PR) |>
  select(reach,R1,R2)


STH_post_pooled_reach_ests_tb <- STH_ATLAS_TLSR$"STH_TL_Modeled_tab" |>
  filter(param %in% c("surv_p")) |>
  mutate(reachIND=LETTERS[c(1:6,6)], est_se=paste0(est," (",format(round(SE, 4), nsmall = 4),")")) |>
  tidyr::pivot_wider(names_from = rel_loc, values_from = est_se) |>
  rename(R1=RI,R2=PR) |>
  select(reach,R1,R2)


CHN_post_pooled_cum_reach_ests_tb <- CHN_ATLAS_TLSR$"CHN_TL_ModeledCum_tab" |> #"CHN_TL_Modeled_tab" |>
  filter(rel_loc %in% c("RI")) |>
  mutate(est_se=paste0(est," (",format(round(SE, 4), nsmall = 4),")")) |>
  select(reach,est_se)

STH_post_pooled_cum_reach_ests_tb <- STH_ATLAS_TLSR$"STH_TL_ModeledCum_tab" |> #"CHN_TL_Modeled_tab" |>
  filter(rel_loc %in% c("RI")) |>
  mutate(est_se=paste0(est," (",format(round(SE, 4), nsmall = 4),")")) |>
  select(reach,est_se)





# Export as Excel with separate sheets for CHN and STH
library(openxlsx)



############################################################### #
# Original code for exporting xlsx
############################################################### #

# f# Create Excel workbook with two sheets
# out_xlsx <- "media/xlsx/COMB_pool_pair_est_outputOLD.xlsx"
# wb <- createWorkbook()
# addWorksheet(wb, "CHN_paired_pool")
# writeData(wb, "CHN_paired_pool", CHN_top,startRow=1,startCol = 2,colNames = F)
# writeData(wb, "CHN_paired_pool", CHN_bottom,startRow=nrow(CHN_top) + 2,,startCol = 2,colNames = F)
# addWorksheet(wb, "CHN_reach_pool")
# writeData(wb, "CHN_reach_pool", CHN_post_pooled_reach_ests_tb,startRow=1,startCol = 2,colNames = F)
# addWorksheet(wb, "CHN_cumul_pool")
# writeData(wb, "CHN_cumul_pool", CHN_post_pooled_cum_reach_ests_tb,startRow=1,startCol = 2,colNames = F)
# addWorksheet(wb, "STH_paired_pool")
# writeData(wb, "STH_paired_pool", STH_top,startRow=1,colNames = F)
# writeData(wb, "STH_paired_pool", STH_bottom,startRow=nrow(STH_top)+2,startCol = 2,colNames = F)
# addWorksheet(wb, "STH_reach_pool")
# writeData(wb, "STH_reach_pool", STH_post_pooled_reach_ests_tb,startRow=1,startCol = 2,colNames = F)
# addWorksheet(wb, "STH_cumul_pool")
# writeData(wb, "STH_cumul_pool", STH_post_pooled_cum_reach_ests_tb,startRow=1,startCol = 2,colNames = F)
# 
# addWorksheet(wb, "COMB_F_test_Surv")
# writeData(wb, "COMB_F_test_Surv", COMB_F_tb,startRow=1,colNames = T)
# addWorksheet(wb, "CHN_rep_ests")
# writeData(wb, "CHN_rep_ests", CHN_F_test_long,startRow=1,colNames = T)
# addWorksheet(wb, "STH_rep_ests")
# writeData(wb, "STH_rep_ests", STH_F_test_long,startRow=1,colNames = T)
# addWorksheet(wb, "COMB_wt_avg_ests")
# writeData(wb,"COMB_wt_avg_ests", COMB_wtavg_tb,startRow=1,colNames = T)
# saveWorkbook(wb, out_xlsx, overwrite = TRUE)



# Condensed workbook: sheets "pooled" (Chinook left, Steelhead right), "CHN_replicates" and
# "STH_replicates"; each table is preceded by a bold 14 pt header.
out_xlsx_cond <- "media/xlsx/COMB_pool_pair_est_output.xlsx"

source("R/write_condensed_sheet.R")

wb_cond <- createWorkbook()

# Sheet 1: pooled estimates (paired release, then tag-life adjusted single release)
write_condensed_sheet(
  wb_cond, "pooled", species_header = TRUE,
  titles = c("Pooled taglife-adjusted paired survival",
             "Pooled taglife-adjusted survival and lambda by release",
             "Pooled detection probability, Lower Ringold",
             "TLSR reach survival",
             "TLSR cumulative survival from RI release"),
  # ungroup first: these tables are grouped by species, which select() would re-add
  chn_tbs = list(ungroup(CHN_pair) |> select(-species),
                 ungroup(CHN_top) |> select(-species), ungroup(CHN_bottom) |> select(-species),
                 CHN_post_pooled_reach_ests_tb, CHN_post_pooled_cum_reach_ests_tb),
  sth_tbs = list(ungroup(STH_pair) |> select(-species),
                 ungroup(STH_top) |> select(-species), ungroup(STH_bottom) |> select(-species),
                 STH_post_pooled_reach_ests_tb, STH_post_pooled_cum_reach_ests_tb))

# Replicate-level estimates for the parameters other than pair_surv_p: survival from each release
# (surv_p), detection (det_p) and lambda, one row per replicate. Cells are "estimate (SE)";
# parameters fixed in ATLAS (SE = 0) show "estimate *". Column names are <release>_<parameter>
# (RI = Rock Island, PR = Priest Rapids release).
rep_other_params_tb <- COMB_spp_ATLAS_ests |>
  filter(type == "rep", param != "pair_surv_p") |>
  mutate(rel_loc = if_else(grepl("^Rock Island", spp_rel_loc), "RI", "PR"),
         est_se = if_else(SE == 0, paste0(est, " *"),
                          paste0(est, " (", format(round(SE, 4), nsmall = 4), ")")),
         col = paste(rel_loc, param, sep = "_")) |>
  select(species, repID, col, est_se) |>
  tidyr::pivot_wider(names_from = col, values_from = est_se) |>
  select(species, repID, RI_surv_p, PR_surv_p, RI_det_p, RI_lambda, PR_det_p, PR_lambda)

# Sheets 2 and 3: replicate-level results, one sheet per species. F-test on top; the long
# paired survival table and then the other-parameter table go last.
rep_titles <- c("F-test for homogeneity of paired survival",
                "Weighted average of replicate estimates",
                "Replicate-level paired survival estimates",
                "Replicate-level estimates for other parameters")

# one note per table (NA = none); only the other-parameter table needs one
rep_notes <- c(NA, NA, NA, "* Parameter fixed in ATLAS (no standard error estimated).")

write_condensed_sheet(
  wb_cond, "CHN_replicates", titles = rep_titles, notes = rep_notes,
  chn_tbs = list(COMB_F_tb |> filter(species == "CHN") |> select(-species),
                 COMB_wtavg_tb |> ungroup() |> filter(species == "CHN") |> select(-species),
                 CHN_F_test_long,
                 rep_other_params_tb |> filter(species == "CHN") |> select(-species)))

write_condensed_sheet(
  wb_cond, "STH_replicates", titles = rep_titles, notes = rep_notes,
  sth_tbs = list(COMB_F_tb |> filter(species == "STH") |> select(-species),
                 COMB_wtavg_tb |> ungroup() |> filter(species == "STH") |> select(-species),
                 STH_F_test_long,
                 rep_other_params_tb |> filter(species == "STH") |> select(-species)))

saveWorkbook(wb_cond, out_xlsx_cond, overwrite = TRUE)


