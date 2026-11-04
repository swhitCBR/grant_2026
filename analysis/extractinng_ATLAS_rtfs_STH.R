
library(xml2)

dir_foc <- "analysis/replicate_level/STH"
dir_foc_rep_dirs <- file.path(dir_foc,dir(dir_foc))


pool_dir_foc <- "analysis/pooled/STH_report"

var_v <- c("COMB_REL_lrg_hanf_pooled_ATLAS_nobins_CaptHist.rtf","COMB_REL_lrg_hanf_pooled_ATLAS_nobins_Cjs.rtf","COMB_REL_lrg_hanf_pooled_ATLAS_nobins_Modeled.rtf")
pool_dir_foc_rep_dirs <- file.path(pool_dir_foc,var_v)


CaptHist_dirs_DF <- rbind(
  data.frame(dir=pool_dir_foc,fl="COMB_REL_lrg_hanf_pooled_ATLAS_nobins_CaptHist.rtf",type="pool"),
  data.frame(dir=dir_foc_rep_dirs,fl=dir(dir_foc_rep_dirs,pattern = "CaptHist"),type="rep"))

Cjs_est_dirs_DF <- rbind(
  data.frame(dir=pool_dir_foc,fl=dir(pool_dir_foc,pattern = "Cjs"),type="pool"),
  data.frame(dir=dir_foc_rep_dirs,fl=dir(dir_foc_rep_dirs,pattern = "Cjs"),type="rep"))


Modeled_est_dirs_DF <- rbind(
  data.frame(dir=pool_dir_foc,fl="COMB_REL_lrg_hanf_pooled_ATLAS_nobins_Modeled.rtf",type="pool"),
  data.frame(dir=dir_foc_rep_dirs,fl=dir(dir_foc_rep_dirs,pattern = "Modeled"),type="rep"))

file.exists("analysis/pooled/STH_report/COMB_REL_lrg_hanf_pooled_ATLAS_nobins_CaptHist.rtf")


all(
  all(CaptHist_dirs_DF$dir==Cjs_est_dirs_DF$dir),
  all(Cjs_est_dirs_DF$dir==Modeled_est_dirs_DF$dir),
  all(CaptHist_dirs_DF$dir==Modeled_est_dirs_DF$dir))

# nrow(CaptHist_dirs_DF);nrow(Cjs_est_dirs_DF);nrow(Modeled_est_dirs_DF);

DH_extract_ls <- Cjs_extract_ls <- Pair_CJS_mod_extract_ls <- list()
for(ii in 1:nrow(CaptHist_dirs_DF)){
  
  ################# #
  # CJS Estimates
  ################# #
  
  # extracting labels 
  repID_tmp <- substr(CaptHist_dirs_DF[ii,1],regexpr("STH_", CaptHist_dirs_DF[ii,1]),nchar(CaptHist_dirs_DF[ii,1]))
  spp_repID_tmp <- substr(CaptHist_dirs_DF[ii,1],regexpr("STH_", CaptHist_dirs_DF[ii,1])+4,nchar(CaptHist_dirs_DF[ii,1]))
  
  tmp1 <- file.path(CaptHist_dirs_DF[ii,1],CaptHist_dirs_DF[ii,2])

  doc1 <- read_html(tmp1)
  nodes1 <- xml_find_all(doc1, "//p")
  txt1 <- trimws(xml_text(nodes1))
  
  DH_extract <- rbind(
    data.frame(
      rel_loc_spp=txt1[2],
      DH=substr(txt1[seq(3,12,2)],1,3),
      count=txt1[seq(4,12,2)]),
    data.frame(
      rel_loc_spp=txt1[13],
      DH=substr(txt1[seq(14,23,2)],1,3),
      count=txt1[seq(15,23,2)]))
  DH_extract_ls[[ii]] <- data.frame(type=CaptHist_dirs_DF$type[ii],
                                    spp_repID=spp_repID_tmp,
                                    repID=repID_tmp,
                                    DH_extract)
  ################# #
  # CJS Estimates
  ################# #
  
  repID_tmp <- substr(Cjs_est_dirs_DF[ii,1],regexpr("STH_", Cjs_est_dirs_DF[ii,1]),nchar(Cjs_est_dirs_DF[ii,1]))
  spp_repID_tmp <- substr(Cjs_est_dirs_DF[ii,1],regexpr("STH_", Cjs_est_dirs_DF[ii,1])+4,nchar(Cjs_est_dirs_DF[ii,1]))
  
  tmp2 <- file.path(Cjs_est_dirs_DF[ii,1],Cjs_est_dirs_DF[ii,2])
  doc2 <- read_html(tmp2)
  nodes2 <- xml_find_all(doc2, "//p")
  txt2 <- trimws(xml_text(nodes2))
  attrib_tmp <- strsplit(txt2[33],split=" ")[[1]][2]
  Cjs_est_tmp <- rbind(
    data.frame(attrib=attrib_tmp,spp_rel_loc=txt2[6],param="surv_p",est=txt2[7],SE=txt2[8]),
    data.frame(attrib=attrib_tmp,spp_rel_loc=txt2[9],param="surv_p",est=txt2[10],SE=txt2[11]),
    data.frame(attrib=attrib_tmp,spp_rel_loc=txt2[19],param="det_p",est=txt2[20],SE=txt2[21]),
    data.frame(attrib=attrib_tmp,spp_rel_loc=txt2[19],param="lambda",est=txt2[22],SE=txt2[23]),
    data.frame(attrib=attrib_tmp,spp_rel_loc=txt2[24],param="det_p",est=txt2[25],SE=txt2[26]),
    data.frame(attrib=attrib_tmp,spp_rel_loc=txt2[24],param="lambda",est=txt2[27],SE=txt2[28]))
  
  Cjs_extract_ls[[ii]] <- data.frame(
    type=Cjs_est_dirs_DF$type[ii],
    spp_repID=spp_repID_tmp,
    repID=repID_tmp,
    Cjs_est_tmp)
  
  ################ #
  # Paired CJS
  ################ #
  
  tmp3 <- file.path(Modeled_est_dirs_DF[ii,1],Modeled_est_dirs_DF[ii,2])
  
  doc3 <- read_html(tmp3)
  nodes3 <- xml_find_all(doc3, "//p")
  txt3 <- trimws(xml_text(nodes3))
  attrib_tmp <- strsplit(txt3[46],split=" ")[[1]][2]
  taglife_tmp <- txt3[48]
  
  
  pair_mod_est_tmp <- rbind(
    data.frame(#taglife_info=taglife_tmp,
               # attrib=attrib_tmp,
               spp_rel_loc=txt3[9],param="pair_surv_p",est=txt3[10],SE=txt3[11]),
    data.frame(#taglife_info=taglife_tmp,
               # attrib=attrib_tmp,
               spp_rel_loc=txt3[16],param="surv_p",est=txt3[17],SE=txt3[18]),
    data.frame(#taglife_info=taglife_tmp,
               # attrib=attrib_tmp,
               spp_rel_loc=txt3[19],param="surv_p",est=txt3[20],SE=txt3[21]),
    data.frame(#taglife_info=taglife_tmp,
               # attrib=attrib_tmp,
               spp_rel_loc=txt3[29],param="det_p",est=txt3[30],SE=txt3[31]),
    data.frame(#taglife_info=taglife_tmp,
               # attrib=attrib_tmp,
               spp_rel_loc=txt3[29],param="lambda",est=txt3[32],SE=txt3[33]),
    data.frame(#taglife_info=taglife_tmp,
               # attrib=attrib_tmp,
               spp_rel_loc=txt3[34],param="det_p",est=txt3[35],SE=txt3[36]),
    data.frame(#taglife_info=taglife_tmp,
               # attrib=attrib_tmp,
               spp_rel_loc=txt3[34],param="lambda",est=txt3[37],SE=txt3[38])
  )
  
  Pair_CJS_mod_extract_ls[[ii]] <- data.frame(
    type=Modeled_est_dirs_DF$type[ii],
    # type=ifelse(Modeled_est_dirs_DF$type[ii]=="pool","pool",Modeled_est_dirs_DF$type[ii]),
    spp_repID=spp_repID_tmp,
    repID=repID_tmp,
    pair_mod_est_tmp)
  
}

STH_DH_tab <- do.call(rbind,DH_extract_ls)
STH_Cjs_tab <- do.call(rbind,Cjs_extract_ls)
STH_Pair_CJS_tab <- do.call(rbind,Pair_CJS_mod_extract_ls)


STH_Pair_CJS_tab$repID <- ifelse(STH_Pair_CJS_tab$type=="rep",STH_Pair_CJS_tab$repID,"pool")
STH_Pair_CJS_tab$spp_repID <- ifelse(STH_Pair_CJS_tab$type=="rep",STH_Pair_CJS_tab$spp_repID,"pool")
STH_Pair_CJS_tab$est= as.numeric(STH_Pair_CJS_tab$est)
STH_Pair_CJS_tab$SE= as.numeric(STH_Pair_CJS_tab$SE)

STH_ATLAS_out <- list("STH_DH_tab" = STH_DH_tab,
                      "STH_Cjs_tab" = STH_Cjs_tab,
                      "STH_Pair_CJS_tab" = STH_Pair_CJS_tab)

saveRDS(STH_ATLAS_out,"analysis/STH_ATLAS_out.rds")

# CHN_DH_tab %>% tidyr::pivot

